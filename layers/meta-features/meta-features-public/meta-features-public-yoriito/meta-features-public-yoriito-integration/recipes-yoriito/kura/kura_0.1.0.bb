# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "Yoriito VISS Server impl: Kura"
DESCRIPTION = "Yoriito VISS Server - The reference implementation for Yoriito VISS"
AUTHOR = "Yoriito"
HOMEPAGE = "https://github.com/yoriito/kura.git"
BUGTRACKER = "None"
SECTION = "base"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e23fadd6ceef8c618fc1c65191d846fa"
PROVIDES += "virtual/yoriito-viss-server"
DEPENDS = "\
    cmake \
    cargo \
    rustc \
    libstd-rust-dev \
    pkg-config \
    libprotobuf-dev \
    protobuf-compiler \
    protobuf-compiler-grpc \
    libgrpc++-dev \
"

inherit dpkg
inherit rust_mirror

require kura.inc
require yoriito-viss.inc

# Debian packaging files, fetched as local files and placed into ${S}/debian
# so that ISAR can build the package from source via dpkg-buildpackage.
#
# The kura crate's build.rs resolves protobuf definitions relative to the crate
# directory (../proto and ../external/yoriito-viss/proto), so the whole upstream
# repository has to be part of the Debian source package. ${S} therefore points
# at the repository root (not the kura/ subdirectory) and debian/ lives there;
# debian/rules builds and installs from the kura/ subdirectory.
SRC_URI += " \
    file://debian/changelog;subdir=kura-${PV} \
    file://debian/control;subdir=kura-${PV} \
    file://debian/copyright;subdir=kura-${PV} \
    file://debian/rules;subdir=kura-${PV} \
    file://debian/source/format;subdir=kura-${PV} \
    file://debian/kura.crinit;subdir=kura-${PV} \
"

S = "${WORKDIR}/kura-${PV}"

# The Rust/cargo build fetches crates from crates.io at
# build time. ISAR runs each task in its own isolated network namespace by
# default, so cargo would fail with a network error inside dpkg-buildpackage.
# Grant network access to the dpkg build (the ISAR equivalent of the OE
# `do_compile[network] = "1"`, since the compile now happens in do_dpkg_build).
#
# Alternative (reproducible, offline): vendor the crates ahead of time with
# `cargo vendor`, ship the vendor/ dir + .cargo/config.toml via SRC_URI, and
# build with `cargo build --release --offline` in debian/rules. That keeps the
# build hermetic but requires maintaining the vendored sources.
do_dpkg_build[network] = "1"

RDEPENDS:${PN} += " libgrpc++1.51"
RPROVIDES:${PN} += "yoriito-viss-server"
