# Copyright 2025 Elektrobit. All rights reserved.

DESCRIPTION = "Hello World application"
MAINTAINER = "Hello World maintainer"

inherit dpkg

# BitBake recipe dependencies
DEPENDS:append = " \
    cmake \
    ebclfsa-cmake \
"

SRC_URI = " \
    file:///workspace/examples/appdev/apps/hello-world/ \
    file://rules \
"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    cp ${WORKDIR}/workspace/examples/appdev/apps/hello-world/hello.c ${S}
    cp ${WORKDIR}/workspace/examples/appdev/apps/hello-world/CMakeLists.txt ${S}
    cp ${WORKDIR}/workspace/examples/appdev/apps/hello-world/hello.crinit.template ${S}
    deb_debianize
}

# Build dependencies for the debian/control file
DEBIAN_BUILD_DEPENDS:append = " , \
    cmake, \
    ebclfsa-cmake, \
"
