# Copyright 2025 Elektrobit. All rights reserved.

DESCRIPTION = "Hello World application"
MAINTAINER = "Hello World maintainer"

inherit dpkg

SRC_URI = " \
    file:///workspace/appdev/apps/hello-world/ \
    file:///workspace/appdev/cmake/toolchain \
    file://rules \
"

# Copy source and CMake toolchain files from fetched directories.
prepare_app_source(){
    cp ${WORKDIR}/workspace/appdev/apps/hello-world/hello.c ${S}
    cp ${WORKDIR}/workspace/appdev/apps/hello-world/CMakeLists.txt ${S}
    cp ${WORKDIR}/workspace/appdev/apps/hello-world/hello.crinit.template ${S}
    cp -r ${WORKDIR}/workspace/appdev/cmake ${S}
}

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    prepare_app_source
    deb_debianize
}

# BitBake recipe dependencies
DEPENDS:append = "cmake"

# Build dependencies for the debian/control file
DEBIAN_BUILD_DEPENDS:append = "cmake"
