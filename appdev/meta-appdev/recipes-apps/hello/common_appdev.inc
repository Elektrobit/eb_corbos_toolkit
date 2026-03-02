# Copyright 2025 Elektrobit Automotive GmbH
# All rights reserved

SRC_URI = " \
    file:///workspace/appdev/ \
    file://rules \
"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    deb_debianize
}

# We resolve all symlink, such that the source package contains
# everything of the linked cmake folder. Additionally, we remove
# the build folder (which might exist) to create clean source packages
prepare_app_source(){
    mkdir -p ${WORKDIR}/${P}
    cp -Lr ${WORKDIR}/workspace/appdev/apps/${PN}/* ${WORKDIR}/${P}
    rm -rf ${WORKDIR}/${P}/build
}

do_unpack:append() {
    bb.build.exec_func('prepare_app_source', d)
}

DEBIAN_DEPENDS = "\${misc:Depends}"

DEBIAN_RULES_REQUIRES_ROOT = "no"
