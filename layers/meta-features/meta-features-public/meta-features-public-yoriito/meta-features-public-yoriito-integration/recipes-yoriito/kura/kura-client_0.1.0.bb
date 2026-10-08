# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "Yoriito VISS Server Client impl: Yoriito VISS Producer/Consumer API"
DESCRIPTION = "Provides the client library for Yoriito VISS Server"
HOMEPAGE = "https://github.com/yoriito/kura.git"
BUGTRACKER = "None"
SECTION = "libs"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e23fadd6ceef8c618fc1c65191d846fa"
PROVIDES += "virtual/yoriito-viss-client"
DEPENDS = "\
    cmake \
    libprotobuf-dev \
    protobuf-compiler \
    protobuf-compiler-grpc \
    libgrpc++-dev \
    yoriito-common-library \
    cargo \
    rustc \
    pkg-config \
"

require kura.inc
require yoriito-viss.inc

# Debian packaging files, fetched as local files and placed into ${S}/debian
# so that ISAR can build the package from source via dpkg-buildpackage.
#
# The client CMake build resolves the VISS protobuf definitions relative to the
# client/cc source dir (../../../external/yoriito-viss/proto), so the whole
# upstream repository has to be part of the Debian source package. ${S}
# therefore points at the repository root (not client/cc) and debian/ lives
# there; debian/rules builds the client/cc subdirectory via --sourcedirectory.
SRC_URI += " \
    file://debian/changelog;subdir=kura-${PV} \
    file://debian/control;subdir=kura-${PV} \
    file://debian/copyright;subdir=kura-${PV} \
    file://debian/rules;subdir=kura-${PV} \
    file://debian/source/format;subdir=kura-${PV} \
    file://0001-cmake-discover-protobuf-grpc-via-pkg-config.patch \
"

S = "${WORKDIR}/kura-${PV}"

inherit dpkg

# The client build compiles a Rust component with cargo, which fetches crates
# from crates.io at build time. Grant the dpkg build network access (see the
# equivalent note in kura_git.bb).
do_dpkg_build[network] = "1"

RDEPENDS:${PN} += " \
    ldconfig-yoriito \
    libgrpc++1.51 \
"
RPROVIDES:${PN} += "yoriito-viss-client"
