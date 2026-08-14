#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
#
# Collect the release assets (toolkit archive, user manual, prebuilt per-target
# images, SDK sysroots and SSH keys) into a single directory and export its path
# to GITHUB_ENV.
#
# Required environment:
#   TMP_WORK_DIR    Temporary working directory for staging assets.
#   ARCHIVE_PATH    Path to the downloaded toolkit archive.
#   MANUAL_PDF      Path to the user manual PDF.
#   MANUAL_HTML_DIR Directory holding the HTML user manual.
#   PREBUILT_DIR    Directory holding the per-target prebuilt artifacts.
#   GITHUB_ENV      Path to the environment file for downstream steps.
set -euo pipefail

assets_dir="${TMP_WORK_DIR}/release-assets"
mkdir -p "${assets_dir}"

mv "${ARCHIVE_PATH}" "${assets_dir}/eb_corbos_toolkit.tar.gz"
cp "${MANUAL_PDF}" "${assets_dir}/user_manual.pdf"
tar -czf "${assets_dir}/user_manual_html.tar.gz" -C "${MANUAL_HTML_DIR}" .

# Per-target assets: one image archive (named after its .wic file), the SDK
# sysroot tarball and the SSH target key for every target directory.
for target_dir in "${PREBUILT_DIR}"/*/; do
  [[ -d "${target_dir}" ]] || continue

  image_dir="${target_dir}image"
  if [[ -d "${image_dir}" ]]; then
    wic_file="$(find "${image_dir}" -maxdepth 1 -name '*.wic' -print -quit)"
    if [[ -z "${wic_file}" ]]; then
      echo "::error::No .wic file found in ${image_dir}."
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

echo "RELEASE_ASSETS_DIR=${assets_dir}" >> "${GITHUB_ENV}"
