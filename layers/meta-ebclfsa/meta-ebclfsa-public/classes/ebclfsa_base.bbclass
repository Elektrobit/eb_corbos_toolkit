# Copyright 2026 Elektrobit. All rights reserved.

inherit image

# Do not run localepurge
ROOTFS_INSTALL_COMMAND_BEFORE_EXPORT:remove = "image_install_localepurge_download"
ROOTFS_INSTALL_COMMAND:remove = "image_install_localepurge_install"

# Disable sshd-regen-keys check as this relies on systemd
ROOTFS_POSTPROCESS_COMMAND:remove = "image_postprocess_sshd_key_regen"

# Disable systemd-related functions
ROOTFS_POSTPROCESS_COMMAND:remove = "image_postprocess_disable_systemd_firstboot"
ROOTFS_POSTPROCESS_COMMAND:remove = "image_postprocess_machine_id"

# Remove additional packages that were required during bootstrapping/installation
UNWANTED_PKGS ??= ""
do_rootfs_postprocess[vardeps] += "UNWANTED_PKGS"

remove_unwanted_pkgs() {
    if [ -n "${UNWANTED_PKGS}" ]; then
        sudo dpkg --root "${IMAGE_ROOTFS}" --purge --force-depends \
            ${UNWANTED_PKGS}
    fi
}

ROOTFS_POSTPROCESS_COMMAND:append = " remove_unwanted_pkgs"
