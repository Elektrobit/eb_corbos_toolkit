# Copyright 2025 Elektrobit. All rights reserved.

set(CMAKE_SYSTEM_PROCESSOR aarch64)

include("$ENV{TOOLCHAIN_BASE}/features/musl-clang.cmake")
include("$ENV{TOOLCHAIN_BASE}/features/ebclfsa.cmake")
