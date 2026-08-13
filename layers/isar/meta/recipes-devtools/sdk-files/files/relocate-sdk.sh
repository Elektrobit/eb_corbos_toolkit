#!/bin/sh
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2020-2023
#
# SPDX-License-Identifier: MIT

sdkroot=$(realpath $(dirname $0))
arch=$(uname -m)

new_sdkroot=$sdkroot

case "$1" in
--help|-h)
	echo "Usage: $0 [--restore-chroot|-r]"
	exit 0
	;;
--restore-chroot|-r)
	new_sdkroot=/
	;;
esac

if [ -z $(which patchelf 2>/dev/null) ]; then
	echo "Please install 'patchelf' package first."
	exit 1
fi

echo -n "Adjusting path of SDK to '${new_sdkroot}'... "

sdk_rpath="${new_sdkroot}/usr/lib:${new_sdkroot}/usr/lib/${arch}-linux-gnu"

for binary in $(find ${sdkroot}/usr/bin ${sdkroot}/usr/sbin \
	${sdkroot}/usr/lib/gcc* ${sdkroot}/usr/libexec/gcc* \
	${sdkroot}/usr/lib/llvm*/bin \
	-executable -type f -exec file {} \; | grep ELF | awk -F ':' '{ print $1 }'); do
	interpreter=$(patchelf --print-interpreter ${binary} 2>/dev/null)
	oldpath=${interpreter%/lib*/ld-linux*}
	interpreter=${interpreter#${oldpath}}
	if [ -n "${interpreter}" ]; then
		# Preserve any $ORIGIN-relative rpath entries (e.g. used by
		# clang/lld to locate their private shared libraries) and
		# append the SDK library paths.
		existing_rpath=$(patchelf --print-rpath ${binary} 2>/dev/null)
		origin_entries=$(echo "${existing_rpath}" | tr ':' '\n' | \
			grep '^\$ORIGIN' | tr '\n' ':' | sed 's/:$//')
		if [ -n "${origin_entries}" ]; then
			new_rpath="${origin_entries}:${sdk_rpath}"
		else
			new_rpath="${sdk_rpath}"
		fi
		# Use the correct order according to https://github.com/NixOS/patchelf/issues/524
		# It seems that the order of --set-rpath and --set-interpreter matters, at least for some binaries.
		# If --set-rpath is used after --set-interpreter, the interpreter path is reset to the old one.
		# This is likely a bug in patchelf, but we work around it by always using --set-rpath first.
		patchelf --set-rpath ${new_rpath} \
			--force-rpath \
			$binary 2>/dev/null
		patchelf --set-interpreter ${new_sdkroot}${interpreter} \
			$binary 2>/dev/null
	fi
done

sed -i 's|^GCC_SYSROOT=.*|GCC_SYSROOT="'"${new_sdkroot}"'"|' \
    ${sdkroot}/usr/bin/gcc-sysroot-wrapper.sh

echo "done"
