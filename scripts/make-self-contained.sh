#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
#
# Makes an SDK tree relocatable without patching any ELF headers.
#
# For every host executable shipped by the SDK (the same set of directories
# `relocate-sdk.sh` / the ebclfsa `patch_cmds` operate on), this script:
#   1. renames "$binary" to "$binary.real"
#   2. drops a small shell wrapper at "$binary" that explicitly invokes the
#      SDK's own loader (ld-linux) with an explicit --library-path, so the
#      binary works no matter where the SDK tree is unpacked, without ever
#      rewriting the ELF interpreter/rpath of "$binary.real".
#
# This is idempotent: binaries that are already wrappers (plain text, not
# ELF) are skipped, so running the script twice on the same tree is a no-op
# the second time.
set -euo pipefail

usage() {
    echo "Usage: $0 <sdk-root>" >&2
    exit 1
}

[ $# -eq 1 ] || usage

sdk_root=$(cd "$1" && pwd)
arch=$(uname -m)

loader="$sdk_root/usr/lib/$arch-linux-gnu/ld-linux-x86-64.so.2"
if [ ! -x "$loader" ]; then
    echo "error: SDK loader not found at $loader" >&2
    exit 1
fi

# Same search roots as relocate-sdk.sh / _EBCLFSA_RELOCATE_CMDS, filtered to
# the ones that actually exist so an unmatched glob doesn't reach `find`.
search_dirs=()
for pattern in "$sdk_root"/usr/bin "$sdk_root"/usr/sbin \
    "$sdk_root"/usr/lib/gcc* "$sdk_root"/usr/libexec/gcc* \
    "$sdk_root"/usr/lib/llvm*/bin; do
    [ -d "$pattern" ] && search_dirs+=("$pattern")
done

is_elf() {
    local magic
    magic=$(head -c4 "$1" 2>/dev/null | od -An -tx1 | tr -d ' \n')
    [ "$magic" = "7f454c46" ]
}

count=0
# Snapshot the file list up front: renaming files while `find` is still
# walking the tree would let it re-discover freshly created "*.real" files
# as if they were new binaries, and wrap them a second time.
mapfile -d '' -t binaries < <(find "${search_dirs[@]}" -type f -perm -u+x -print0 2>/dev/null)
for binary in "${binaries[@]}"; do
    # A ".real" binary is the already-renamed original from a previous run;
    # never re-wrap it (that would shadow it behind a second wrapper).
    case "$binary" in
    *.real) continue ;;
    esac

    # Shared libraries can be executable files too, but must remain ELF
    # libraries because tools such as GCC load them directly as plugins.
    case "$(basename "$binary")" in
    *.so|*.so.*) continue ;;
    esac
    is_elf "$binary" || continue

    dir=$(dirname "$binary")
    name=$(basename "$binary")
    real="$dir/$name.real"

    [ -e "$real" ] && continue

    # Relative path from the wrapper's own directory back to sdk_root, so the
    # wrapper keeps working wherever the whole tree gets moved/extracted to.
    rel_to_root=$(realpath --relative-to="$dir" "$sdk_root")

    mv "$binary" "$real"
    cat >"$binary" <<EOF
#!/bin/sh
here=\$(dirname "\$(readlink -f "\$0")")
sdk=\$here/$rel_to_root
exec "\$sdk/usr/lib/$arch-linux-gnu/ld-linux-x86-64.so.2" \\
    --argv0 "\$0" \\
    --library-path "\$sdk/usr/lib/$arch-linux-gnu:\$sdk/lib/$arch-linux-gnu" \\
    "\$here/$name.real" "\$@"
EOF
    chmod +x "$binary"
    count=$((count + 1))
done

echo "wrapped $count binaries under $sdk_root"
