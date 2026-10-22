# Copyright 2026 Elektrobit. All rights reserved.

inherit dpkg_rebuild
require recipes-net/iptables/iptables_1.8.11-2.src.inc

# Add additional build dependencies for enabled nfsynproxy
DEPENDS:append = " libpcap-dev"

# Tests need kernel nftables support, unavailable under qemu-user cross-build
DEB_BUILD_PROFILES += "nocheck"

SRC_URI += "file://0001-Add-custom-version-tag.patch"
SRC_URI += "file://0002-Enable-nfsynproxy.patch"

S = "${WORKDIR}/iptables-1.8.11"
