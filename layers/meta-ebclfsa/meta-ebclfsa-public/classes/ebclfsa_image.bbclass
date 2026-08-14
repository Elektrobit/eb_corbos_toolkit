# Copyright 2026 Elektrobit. All rights reserved.

inherit ebclfsa_base
inherit multiarch_helper

IMAGE_PREINSTALL = ""
SDK_INSTALL += "cmake patchelf"
SDK_FORMATS = "tar.gz"

# Set $ORIGIN-relative rpaths for toolchain ELF binaries so the SDK
# library lookups work without absolute path relocation.
ROOTFS_POSTPROCESS_COMMAND:append:class-sdk = " sdk_set_origin_rpaths"
sdk_set_origin_rpaths() {
    cat > ${WORKDIR}/sdk_set_origin_rpaths.sh << 'ORIGIN_RPATHS_EOF'
#!/bin/bash
set -e

MULTIARCH=$(dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null || echo "x86_64-linux-gnu")

SEARCH_DIRS=""
for d in /usr/bin /usr/sbin /usr/lib/gcc* /usr/libexec/gcc* /usr/lib/llvm*/bin; do
    [ -d "$d" ] && SEARCH_DIRS="$SEARCH_DIRS $d"
done

[ -z "$SEARCH_DIRS" ] && exit 0

for binary in $(find $SEARCH_DIRS -executable -type f -exec file {} \; | grep ELF | awk -F ':' '{ print $1 }'); do
    bindir=$(dirname "$binary")
    relpath=$(realpath -m --relative-to="$bindir" /usr)

    origin_rpath="\$ORIGIN/$relpath/lib:\$ORIGIN/$relpath/lib/$MULTIARCH"

    # Preserve any existing $ORIGIN entries (e.g. LLVM private libs)
    existing_rpath=$(patchelf --print-rpath "$binary" 2>/dev/null || true)
    origin_entries=$(echo "$existing_rpath" | tr ':' '\n' | grep '^\$ORIGIN' | tr '\n' ':' | sed 's/:$//')
    if [ -n "$origin_entries" ]; then
        origin_rpath="$origin_entries:$origin_rpath"
    fi

    # Deduplicate entries preserving order
    origin_rpath=$(echo "$origin_rpath" | tr ':' '\n' | awk '!seen[$0]++' | tr '\n' ':' | sed 's/:$//')

    patchelf --set-rpath "$origin_rpath" --force-rpath "$binary" 2>/dev/null || true
done
ORIGIN_RPATHS_EOF
    chmod +x ${WORKDIR}/sdk_set_origin_rpaths.sh
    sudo install -m 0755 ${WORKDIR}/sdk_set_origin_rpaths.sh ${ROOTFSDIR}/tmp/sdk_set_origin_rpaths.sh
    sudo chroot ${ROOTFSDIR} /tmp/sdk_set_origin_rpaths.sh
    sudo rm -f ${ROOTFSDIR}/tmp/sdk_set_origin_rpaths.sh
}

IMAGER_BUILD_DEPS:append = " ${@isar_multiarch_recipes('IMAGER_INSTALL', 'HOST_ARCH', d)}"
SDKDEPENDS:append = " ${@isar_multiarch_recipes('SDK_PREINSTALL', 'ROOTFS_ARCH:class-sdk', d)}"
SDKDEPENDS:append = " ${@isar_multiarch_recipes('SDK_TOOLCHAIN', 'ROOTFS_ARCH:class-sdk', d)}"
# New versions of ISAR automatically try to generate an initrd as part of the build process; disable this
ROOTFS_FEATURES:remove = "generate-initrd"
ROOTFS_INSTALL_COMMAND:remove = "rootfs_restore_initrd_tooling"

# Remove the deb-src line as we don't currently support this
rootfs_configure_isar_apt:append() {
    sudo sed -i '/^deb-src .*/d' ${ROOTFSDIR}/etc/apt/sources.list.d/isar-apt.list
}

# Set default users
USERS += "root"
USER_root[password] ??= "linux"
USER_root[flags] += "clear-text-password"

COMPATIBLE_MACHINE = "^ebcl-qemu(arm64|amd64)$"

# Bootloader handling. Set to 1 to install the packages listed in EBCL_BOOTLOADER_PACKAGES
EBCL_BOOTLOADER ??= "0"
EBCL_BOOTLOADER_PACKAGES ??= ""

IMAGE_INSTALL:append = " \
    ${@ d.getVar('EBCL_BOOTLOADER_PACKAGES') if bb.utils.to_boolean(d.getVar('EBCL_BOOTLOADER')) else '' } \
"

# SSH target access: generate or use a provided SSH keypair for root access
# Set EBCL_SSH_TARGET_ACCESS to "0" to force disable, or "1" to force enable
# By default ("auto"), keys are generated only if openssh-server or dropbear is in IMAGE_INSTALL
# Set EBCL_SSH_AUTHORIZED_PUBKEY to a pubkey file path to skip generation
EBCL_SSH_TARGET_ACCESS ??= "auto"
EBCL_SSH_TARGET_ACCESS:class-sdk = "0"
EBCL_SSH_AUTHORIZED_PUBKEY ??= ""
EBCL_SSH_SERVER_PACKAGES ??= "openssh-server dropbear"
do_rootfs_install[vardeps] += "EBCL_SSH_TARGET_ACCESS EBCL_SSH_AUTHORIZED_PUBKEY EBCL_SSH_SERVER_PACKAGES"

install_ssh_target_pubkey() {
    SSH_KEY_DIR="${WORKDIR}/ssh-target-keys"
    mkdir -p "${SSH_KEY_DIR}"

    if [ -n "${EBCL_SSH_AUTHORIZED_PUBKEY}" ]; then
        if [ ! -f "${EBCL_SSH_AUTHORIZED_PUBKEY}" ]; then
            bbfatal "EBCL_SSH_AUTHORIZED_PUBKEY is set to '${EBCL_SSH_AUTHORIZED_PUBKEY}' but the file does not exist."
        fi
        cp "${EBCL_SSH_AUTHORIZED_PUBKEY}" "${SSH_KEY_DIR}/target_key.pub"
    else
        rm -f "${SSH_KEY_DIR}/target_key" "${SSH_KEY_DIR}/target_key.pub"
        ssh-keygen -t ed25519 -f "${SSH_KEY_DIR}/target_key" -N "" \
            -C "${IMAGE_FULLNAME}"
        install -m 0600 "${SSH_KEY_DIR}/target_key" \
            "${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}-ssh-target-key"
        bbwarn "${PN}: A development SSH keypair was generated." \
               "The private key is deployed to ${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}-ssh-target-key." \
               "Do NOT use in production images." \
               "NOTE: this means that by default, only YOU have access to that image."
    fi

    sudo mkdir -p "${IMAGE_ROOTFS}/root/.ssh"
    sudo chmod 0700 "${IMAGE_ROOTFS}/root/.ssh"
    sudo cp "${SSH_KEY_DIR}/target_key.pub" \
        "${IMAGE_ROOTFS}/root/.ssh/authorized_keys"
    sudo chmod 0600 "${IMAGE_ROOTFS}/root/.ssh/authorized_keys"
}

EBCL_DEVICE_TREE ??= ""
EBCL_COPY_DEVICE_TREE ??= "${EBCL_BOOTLOADER}"
copy_device_tree() {
    if ! [ -e "${IMAGE_ROOTFS}"/lib/firmware/*/device-tree/"${EBCL_DEVICE_TREE}" ]; then
        bbfatal "Device tree not found in rootfs: ${EBCL_DEVICE_TREE}"
    fi

    sudo install -Dm0644 "${IMAGE_ROOTFS}"/lib/firmware/*/device-tree/"${EBCL_DEVICE_TREE}" \
        "${IMAGE_ROOTFS}"/boot/fdt.dtb
}

def ebcl_ssh_target_access_enabled(d):
    mode = (d.getVar('EBCL_SSH_TARGET_ACCESS') or 'auto').strip()
    if mode == '1':
        return True
    if mode == '0':
        return False
    # auto: detect SSH server packages in IMAGE_INSTALL
    image_install = (d.getVar('IMAGE_INSTALL') or '')
    ssh_pkgs = (d.getVar('EBCL_SSH_SERVER_PACKAGES') or '').split()
    return any(pkg in image_install.split() for pkg in ssh_pkgs)

ROOTFS_POSTPROCESS_COMMAND:append = " \
    ${@ 'copy_device_tree' if len(d.getVar('EBCL_DEVICE_TREE') or '') > 0 and bb.utils.to_boolean(d.getVar('EBCL_COPY_DEVICE_TREE')) else ''} \
    ${@ 'install_ssh_target_pubkey' if ebcl_ssh_target_access_enabled(d) else ''} \
"
