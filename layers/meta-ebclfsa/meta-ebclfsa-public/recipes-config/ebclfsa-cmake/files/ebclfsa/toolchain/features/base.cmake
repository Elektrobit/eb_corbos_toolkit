# Copyright 2025 Elektrobit. All rights reserved.

set(CMAKE_SYSTEM_NAME Linux)

# See https://cmake.org/cmake/help/latest/module/GNUInstallDirs.html#special-cases
set(CMAKE_INSTALL_PREFIX "/" CACHE STRING "Install prefix" FORCE)

set(CMAKE_FIND_ROOT_PATH "${CMAKE_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(ENV{PKG_CONFIG_DIR} "")
set(ENV{PKG_CONFIG_LIBDIR} "${CMAKE_FIND_ROOT_PATH}/usr/lib/aarch64-linux-gnu/pkgconfig/:${CMAKE_FIND_ROOT_PATH}/usr/share/pkgconfig")
set(ENV{PKG_CONFIG_SYSROOT_DIR} ${CMAKE_FIND_ROOT_PATH})

if(DEFINED TARGET_HOST)
    file(WRITE "${CMAKE_BINARY_DIR}/.target_host" "${TARGET_HOST}")
endif()
