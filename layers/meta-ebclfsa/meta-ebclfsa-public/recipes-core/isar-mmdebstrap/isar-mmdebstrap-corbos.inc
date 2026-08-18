# Copyright 2026 Elektrobit. All rights reserved.

inherit multiarch_helper

DISTRO_BOOTSTRAP_BASE_PACKAGES:append = " util-linux"

# Gather all packages which mmdebstrap possibly needs
DISTRO_BOOTSTRAP_DEPENDS = " \
    ${DISTRO_BOOTSTRAP_BASE_PACKAGES} \
    adduser \
    base-files \
    base-passwd \
    bash \
    bsdutils \
    coreutils \
    dash \
    debconf \
    diffutils \
    dirmngr \
    dpkg \
    findutils \
    grep \
    libc-bin \
    perl \
    sed \
"

# Ensure all dependencies for the host/target architecture are fetched prior to build
DEPENDS:append = " ${@isar_multiarch_recipes('DISTRO_BOOTSTRAP_DEPENDS', 'BOOTSTRAP_DISTRO_ARCH', d)}"
do_bootstrap[deptask] += "do_deploy_deb"

# Delete the bootstrap.list file from the rootfs so only isar-apt is used in builds using this
# bootstrap tarball. Using tar --delete here causes some strange problems with the tar header later
# on, so just extract and recreate the tarball manually.
do_bootstrap:append() {
    # Do nothing if the file does not exist
    if ! tar -tf "${WORKDIR}"/rootfs.tar.zst ./etc/apt/sources.list.d/0000bootstrap.list > /dev/null; then
        return 0
    fi

    sudo rm -rf "${WORKDIR}"/remove-bootstrap-list

    # Extract original tarball
    sudo mkdir "${WORKDIR}"/remove-bootstrap-list
    sudo tar  -C "${WORKDIR}"/remove-bootstrap-list --numeric-owner \
        -xpf "${WORKDIR}"/rootfs.tar.zst

    # Remove the bootstrap apt list
    sudo rm "${WORKDIR}"/remove-bootstrap-list/etc/apt/sources.list.d/0000bootstrap.list

    # Recreate the rootfs tarball
    sudo tar -C "${WORKDIR}"/remove-bootstrap-list --zstd --numeric-owner \
        -cpf "${WORKDIR}"/rootfs.tar.zst .

    sudo rm -rf "${WORKDIR}"/remove-bootstrap-list
}
