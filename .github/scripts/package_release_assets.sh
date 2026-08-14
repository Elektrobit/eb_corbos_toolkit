#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
#
# Collect the release assets (toolkit archive, user manual, prebuilt per-target
# images, SDK sysroots and SSH keys) into a single directory and print its path
# as a KEY=VALUE line on stdout.
#
# Usage: package_release_assets.sh --tmp-work-dir <DIR> --archive-path <FILE> \
#          --manual-pdf <FILE> --manual-html-dir <DIR> --prebuilt-dir <DIR>
set -euo pipefail

tmp_work_dir=""
archive_path=""
manual_pdf=""
manual_html_dir=""
prebuilt_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tmp-work-dir)   tmp_work_dir="$2"; shift 2 ;;
    --archive-path)   archive_path="$2"; shift 2 ;;
    --manual-pdf)     manual_pdf="$2"; shift 2 ;;
    --manual-html-dir) manual_html_dir="$2"; shift 2 ;;
    --prebuilt-dir)   prebuilt_dir="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

for arg_name in tmp_work_dir archive_path manual_pdf manual_html_dir prebuilt_dir; do
  if [[ -z "${!arg_name}" ]]; then
    echo "ERROR: Required argument --${arg_name//_/-} is not set." >&2
    exit 1
  fi
done

assets_dir="${tmp_work_dir}/release-assets"
mkdir -p "${assets_dir}"

mv "${archive_path}" "${assets_dir}/eb_corbos_toolkit.tar.gz"
cp "${manual_pdf}" "${assets_dir}/user_manual.pdf"
tar -czf "${assets_dir}/user_manual_html.tar.gz" -C "${manual_html_dir}" .

# Per-target assets: one image archive (named after its .wic file), the SDK
# sysroot tarball and the SSH target key for every target directory.
for target_dir in "${prebuilt_dir}"/*/; do
  [[ -d "${target_dir}" ]] || continue

  image_dir="${target_dir}image"
  if [[ -d "${image_dir}" ]]; then
    wic_file="$(find "${image_dir}" -maxdepth 1 -name '*.wic' -print -quit)"
    if [[ -z "${wic_file}" ]]; then
      echo "ERROR: No .wic file found in ${image_dir}." >&2
      exit 1
    fi
    image_base="$(basename "${wic_file}" .wic)"
    tar -czf "${assets_dir}/${image_base}.tar.gz" -C "${image_dir}" .
  fi

  sdk_dir="${target_dir}sysroot"
  if [[ -d "${sdk_dir}" ]]; then
    find "${sdk_dir}" -maxdepth 1 -type f -exec cp {} "${assets_dir}/" \;
  fi

  key_dir="${target_dir}ssh_keys"
  if [[ -d "${key_dir}" ]]; then
    find "${key_dir}" -maxdepth 1 -type f -exec cp {} "${assets_dir}/" \;
  fi
done

echo "RELEASE_ASSETS_DIR=${assets_dir}"
