# Copyright 2025 Elektrobit Automotive GmbH
# All rights reserved

# Toplevel toolchain file for fastdev-hi-qemuarm64

set(CMAKE_SYSTEM_PROCESSOR aarch64)

include("$ENV{TOOLCHAIN_BASE}/common/musl-clang.cmake")
include("$ENV{TOOLCHAIN_BASE}/common/ebclfsa.cmake")
