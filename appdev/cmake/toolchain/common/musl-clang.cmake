# Copyright 2025 Elektrobit Automotive GmbH
# All rights reserved

# Include EBcLfsA specific Settings
include("$ENV{TOOLCHAIN_BASE}/common/base.cmake")

set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CLANG_TARGET_TRIPLE "${CMAKE_SYSTEM_PROCESSOR}-linux-gnu")

set(CLANG_BINDIR "${CMAKE_SYSROOT}/usr/lib/llvm-20/bin")
set(CLANG_INCLUDEDIR "${CMAKE_SYSROOT}/usr/lib/llvm-20/lib/clang/20/include")
set(LISA_LIBC_PREFIX "${CMAKE_SYSROOT}/opt/lisa-libc")
set(LIBCXX_INCLUDE_DIR "${CMAKE_SYSROOT}/opt/lisa-libcxx/include")
set(LIBCLANG_RT "${CMAKE_SYSROOT}/usr/lib/llvm-20/lib/clang/20/lib/linux/libclang_rt.builtins-aarch64.a")
set(LISA_LIBC_LIB "${CMAKE_SYSROOT}/opt/lisa-libc/lib/aarch64-linux-gnu")
set(LIBCXX_LIB "${CMAKE_SYSROOT}/opt/lisa-libcxx/lib")


set(CMAKE_C_COMPILER "${CLANG_BINDIR}/clang")
set(CMAKE_CXX_COMPILER "${CLANG_BINDIR}/clang++")

set(CMAKE_EXE_LINKER_FLAGS_INIT "-nostdlib")

set(CMAKE_C_STANDARD_LIBRARIES_INIT " \
    ${LIBCLANG_RT} \
    ${LISA_LIBC_LIB}/crt1.o \
    ${LISA_LIBC_LIB}/libc.a \
")

set(CMAKE_CXX_STANDARD_LIBRARIES_INIT " \
    ${LIBCXX_LIB}/libc++.a \
    ${LIBCXX_LIB}/libc++abi.a \
    ${CMAKE_C_STANDARD_LIBRARIES_INIT} \
")

set(COMMON_COMPILER_FLAGS " \
    --target=${CLANG_TARGET_TRIPLE} \
    -nostdinc \
")

set(COMMON_LINKER_FLAGS " \
    --start-no-unused-arguments \
    -fuse-ld=lld \
    --ld-path=${CLANG_BINDIR}/ld.lld \
    -nodefaultlibs \
    -nostartfiles \
    --end-no-unused-arguments \
    -isystem ${LISA_LIBC_PREFIX}/include \
    -isystem ${CLANG_INCLUDEDIR} \
")

set(CMAKE_C_FLAGS " \
    ${COMMON_LINKER_FLAGS} \
    ${COMMON_COMPILER_FLAGS} \
")

set(CMAKE_CXX_FLAGS " \
    ${COMMON_LINKER_FLAGS} \
    -fno-exceptions \
    -fno-rtti \
    -cxx-isystem ${LIBCXX_INCLUDE_DIR}/c++/v1 \
    -cxx-isystem ${LISA_LIBC_PREFIX}/include \
    -cxx-isystem ${CLANG_INCLUDEDIR} \
    ${COMMON_COMPILER_FLAGS} \
")
