# Copyright 2025 Elektrobit Automotive GmbH
# All rights reserved

# Include EBcLfsA specific Settings
include("$ENV{TOOLCHAIN_BASE}/common/base.cmake")

set(GCC_COMPILER_VERSION "13" CACHE STRING "GCC Compiler version")
set(GNU_MACHINE "${CMAKE_SYSTEM_PROCESSOR}-linux-gnu" CACHE STRING "GNU compiler triple")

set(CMAKE_C_COMPILER "${CMAKE_SYSROOT}/usr/bin/${GNU_MACHINE}-gcc-13.bin")
set(CMAKE_CXX_COMPILER "${CMAKE_SYSROOT}/usr/bin/${GNU_MACHINE}-g++-13.bin")
