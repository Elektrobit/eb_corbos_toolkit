#!/bin/sh
#
# This software is a part of Isar.
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

# Prefer the patchelf shipped inside the SDK itself. It lives inside the
# tree that is about to be rewritten by the loop below, so operate on a
# copy instead of the original, and run that copy directly: it must keep
# using its own (unmodified) interpreter, since - like every other SDK
# host tool binary - it relies on the host's libc.so.6 until this script
# has run, and forcing it through a different loader would reintroduce
# the interpreter/libc.so.6 mismatch this script fixes for every other
# binary.
sdk_patchelf=${sdkroot}/usr/bin/patchelf
if [ -x "${sdk_patchelf}" ]; then
	patchelf_tmpdir=$(mktemp -d)
	cp "${sdk_patchelf}" "${patchelf_tmpdir}/patchelf"
	trap 'rm -rf "${patchelf_tmpdir}"' EXIT
	patchelf() {
		"${patchelf_tmpdir}/patchelf" "$@"
	}
elif [ -z "$(which patchelf 2>/dev/null)" ]; then
	echo "Please install 'patchelf' package first."
	exit 1
fi

echo -n "Adjusting path of SDK to '${new_sdkroot}'... "

sdk_rpath="${new_sdkroot}/usr/lib:${new_sdkroot}/usr/lib/${arch}-linux-gnu"

# Make the SDK's own libc.so.6 visible on the rpath again. It is hidden by
# default (moved into this subdirectory during the SDK build) so unmodified
# binaries fall back to the host's libc.so.6, matching their untouched host
# loader.
sdk_libc_dir="${sdkroot}/usr/lib/${arch}-linux-gnu"
if [ -f "${sdk_libc_dir}/sdk-libc/libc.so.6" ] && [ ! -e "${sdk_libc_dir}/libc.so.6" ]; then
	ln -s sdk-libc/libc.so.6 "${sdk_libc_dir}/libc.so.6"
fi

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
