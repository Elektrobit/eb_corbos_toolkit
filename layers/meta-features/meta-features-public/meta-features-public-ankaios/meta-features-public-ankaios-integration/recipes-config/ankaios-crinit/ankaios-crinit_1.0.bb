# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "crinit configuration files for Ankaios"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "Elektrobit <info@elektrobit.com>"

DEPENDS:append = " \
    ank-server \
    ank-agent \
"

DEBIAN_DEPENDS:append = " , ${@ ', '.join(d.getVar('DEPENDS').split()) }"
# Needed to overwrite /etc/ankaios/state.yaml shipped by ank-server.
DEBIAN_REPLACES = "ank-server"

SRC_URI = " \
    file://ank-server.crinit \
    file://ank-agent.crinit \
    file://state.yaml \
"

do_install(){
    install -Dm0644 ${WORKDIR}/ank-server.crinit ${D}/etc/crinit/crinit.d/ank-server.crinit
    install -Dm0644 ${WORKDIR}/ank-agent.crinit ${D}/etc/crinit/crinit.d/ank-agent.crinit
    # Override Ankaios default empty startup manifest.
    install -Dm0644 ${WORKDIR}/state.yaml ${D}/etc/ankaios/state.yaml
}

DEBIAN_RULES_REQUIRES_ROOT = "no"
