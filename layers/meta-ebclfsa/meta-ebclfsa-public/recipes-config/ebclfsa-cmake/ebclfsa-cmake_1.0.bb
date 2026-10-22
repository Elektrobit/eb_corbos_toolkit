# Copyright 2026 Elektrobit. All rights reserved.

DESCRIPTION = "Install EBcLfSA cmake base presets and toolchain files"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "Elektrobit <info@elektrobit.com>"

DPKG_ARCH = "all"

SRC_URI = " \
    file://ebclfsa \
"

do_install(){
    install -d "${D}/usr/share/cmake/ebclfsa"
    cd "${WORKDIR}/ebclfsa"
    find . -type d -exec install -d "${D}/usr/share/cmake/ebclfsa/{}" \;
    find . -type f -exec install -Dm0644 "{}" "${D}/usr/share/cmake/ebclfsa/{}" \;
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
