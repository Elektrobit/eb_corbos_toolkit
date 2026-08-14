# Copyright 2026 Elektrobit. All rights reserved.

DESCRIPTION = "Generate SSH host keys for openssh-server on first boot using crinit"
LICENSE = "CLOSED"

inherit dpkg-raw
MAINTAINER = "Elektrobit <info@elektrobit.com>"

SRC_URI = " \
    file://ebclfsa-openssh-server-host-keys.crinit \
    file://ebclfsa-openssh-server-host-keys.sh \
"

do_install() {
    # Create empty files
    install -dm0755 ${D}/etc/ssh
    touch ${D}/etc/ssh/ssh_host_rsa_key \
        ${D}/etc/ssh/ssh_host_ecdsa_key \
        ${D}/etc/ssh/ssh_host_ed25519_key
    chmod 0600 ${D}/etc/ssh/ssh_host_*_key

    # Add crinit unit file
    install -Dm0644 -t ${D}/etc/crinit/crinit.d \
        ${WORKDIR}/ebclfsa-openssh-server-host-keys.crinit

    # Add helper script
    install -Dm0755 -t ${D}/usr/sbin \
        ${WORKDIR}/ebclfsa-openssh-server-host-keys.sh
}

DEBIAN_RULES_REQUIRES_ROOT = "no"

DEBIAN_DEPENDS = " \
    \${misc:Depends}, \
    crinit, \
    openssh-server, \
"

# Remove the key files in /etc/ssh from conffiles so that they are installed
# during the unpack step, rather than during package configuration. Otherwise,
# openssh will generate host keys as its configuration step is run before this
# package's due to the package dependency.

# nooelint: oelint.tabs.notabs - need tabs for the correct Makefile syntax
do_prepare_build:append() {
    cat << EOF >> ${S}/debian/rules

override_dh_installdeb:
	dh_installdeb
	sed -i '/\/etc\/ssh\/ssh_host_.*_key/d' debian/${BPN}/DEBIAN/conffiles
EOF
}
