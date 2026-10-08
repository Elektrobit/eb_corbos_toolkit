# Copyright 2026 Elektrobit. All rights reserved.

inherit ebclfsa_devcontainer

# Just a placeholder, the container name shall contain the real registry path (could also be ghcr.io)
CONTAINER_IMAGE_NAME = "ghcr.io/elektrobit/eb-corbos-toolkit-devcontainer-amd64:RFI_EBLINUX-30185-fixes-before-release-v2-${PN}-${DISTRO_ARCH}"
CONTAINER_IMAGE_TAG = "local"
CONTAINER_IMAGE_CMD = "/bin/bash"

# Common set of packages, required to build a target image with kas.
IMAGE_INSTALL = " \
    apt-utils \
    arch-test  \
    base-files \
    base-passwd \
    bash \
    binfmt-support \
    bmaptool \
    bubblewrap \
    buildcontainer-config \
    ca-certificates \
    checkpolicy \
    coreutils \
    cpio \
    cryptsetup \
    curl \
    diffutils \
    file \
    findutils \
    git \
    git-lfs \
    hostname \
    init \
    iproute2 \
    jq \
    kas \
    kmod \
    libpam-runtime \
    locales \
    mmdebstrap \
    mount \
    openssh-client \
    policycoreutils \
    python3 \
    python3-jinja2 \
    python3-cairo \
    qemu-user-static \
    quilt \
    reprepro \
    rsync \
    sbuild \
    schroot \
    sed \
    skopeo \
    sudo \
    umoci \
    wget \
"

# Ensure reproducible builds
ROOTFS_POSTPROCESS_COMMAND:append = " set_fixed_machine_id sort_gitconfig remove_dpkg_status_old regenerate_ca_certificates sort_apt_extended_states"
set_fixed_machine_id() {
    sudo sh -c "echo '00000000000000000000000000000000' > ${IMAGE_ROOTFS}/etc/machine-id"
}
sort_gitconfig() {
    if [ -f ${IMAGE_ROOTFS}/etc/gitconfig ]; then
        sudo git config -f ${IMAGE_ROOTFS}/etc/gitconfig -l | sort > ${WORKDIR}/gitconfig_sorted
        sudo rm -f ${IMAGE_ROOTFS}/etc/gitconfig
        while IFS='=' read -r key value; do
            sudo git config -f ${IMAGE_ROOTFS}/etc/gitconfig "$key" "$value"
        done < ${WORKDIR}/gitconfig_sorted
        rm -f ${WORKDIR}/gitconfig_sorted
    fi
}
remove_dpkg_status_old() {
    sudo rm -f ${IMAGE_ROOTFS}/var/lib/dpkg/status-old
}
regenerate_ca_certificates() {
    sudo -E chroot ${IMAGE_ROOTFS} env LC_ALL=C update-ca-certificates --fresh
}
sort_apt_extended_states() {
    if [ -f ${IMAGE_ROOTFS}/var/lib/apt/extended_states ]; then
        sudo python3 -c "
import sys
with open(sys.argv[1]) as f:
    content = f.read()
blocks = [b.strip() for b in content.split('\n\n') if b.strip()]
blocks.sort()
with open(sys.argv[1], 'w') as f:
    f.write('\n\n'.join(blocks) + '\n\n')
" ${IMAGE_ROOTFS}/var/lib/apt/extended_states
    fi
}
