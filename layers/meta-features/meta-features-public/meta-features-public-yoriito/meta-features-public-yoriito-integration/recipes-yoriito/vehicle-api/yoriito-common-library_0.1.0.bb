# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "The common library for Yoriito Vehicle API"
DESCRIPTION = "Provides the common library for Yoriito Signal/Access API"
AUTHOR = "Yoriito"
HOMEPAGE = "https://github.com/yoriito/vehicle-api"
BUGTRACKER = "None"
SECTION = "libs"
DEPENDS = "\
    cmake \
    libdlt-dev \
    libprotobuf-dev \
    protobuf-compiler \
    protobuf-compiler-grpc \
    libgrpc++-dev \
"

require yoriito-vehicle-api.inc

# Debian packaging files, fetched as local files and placed into ${S}/debian
# so that ISAR can build the package from source via dpkg-buildpackage.
SRC_URI += " \
    file://debian/changelog;subdir=vehicle-api-${PV} \
    file://debian/control;subdir=vehicle-api-${PV} \
    file://debian/copyright;subdir=vehicle-api-${PV} \
    file://debian/rules;subdir=vehicle-api-${PV} \
    file://debian/source/format;subdir=vehicle-api-${PV} \
    file://debian/yoriito-common-library.alternatives;subdir=vehicle-api-${PV} \
    file://debian/yoriito-common-library.preinst;subdir=vehicle-api-${PV} \
    file://debian/yoriito-common-library.postrm;subdir=vehicle-api-${PV} \
"

S = "${WORKDIR}/vehicle-api-${PV}"

inherit dpkg

RDEPENDS:${PN} = " \
    libgrpc++1.51 \
    ldconfig-yoriito \
"
