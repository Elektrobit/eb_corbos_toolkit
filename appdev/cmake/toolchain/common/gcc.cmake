# Copyright 2025 Elektrobit. All rights reserved.

# Include EBcLfsA specific Settings
include("$ENV{TOOLCHAIN_BASE}/common/base.cmake")

set(GNU_MACHINE "${CMAKE_SYSTEM_PROCESSOR}-linux-gnu" CACHE STRING "GNU compiler triple")

# Use the unversioned cross-compiler names so the toolchain works across
# distributions with different default GCC versions (e.g. gcc-13 on Ubuntu,
# gcc-14 on Debian trixie).
set(CMAKE_C_COMPILER "${CMAKE_SYSROOT}/usr/bin/${GNU_MACHINE}-gcc")
set(CMAKE_CXX_COMPILER "${CMAKE_SYSROOT}/usr/bin/${GNU_MACHINE}-g++")
