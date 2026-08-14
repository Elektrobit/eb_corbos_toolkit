#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
#
# Download the upstream toolkit archive, extract it into a temporary directory
# and print the resulting paths as KEY=VALUE lines on stdout.
#
# Usage: download_archive.sh --url <URL> --token <TOKEN>
set -euo pipefail

url=""
token=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)   url="$2"; shift 2 ;;
    --token) token="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "${url}" ]]; then
  echo "ERROR: Required argument --url is not set." >&2
  exit 1
fi

if [[ -z "${token}" ]]; then
  echo "ERROR: Required argument --token is not set." >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
archive_path="${tmp_dir}/eb_corbos_toolkit.tar.gz"
extract_root="${tmp_dir}/extracted"

mkdir -p "${extract_root}"

echo "Starting upstream delivery archive download (this may take a while for large files)..." >&2
echo "Download target: ${archive_path}" >&2

curl \
  --fail \
  --progress-bar \
  --show-error \
  --location \
  --retry 3 \
  --retry-delay 5 \
  --retry-all-errors \
  --header "Authorization: Bearer ${token}" \
  --output "${archive_path}" \
  --url "${url}"

archive_size_bytes="$(wc -c < "${archive_path}")"
archive_size_mib="$(awk "BEGIN { printf \"%.2f\", ${archive_size_bytes}/1024/1024 }")"
echo "Download complete: ${archive_size_bytes} bytes (${archive_size_mib} MiB)." >&2

echo "Starting upstream delivery archive extraction into ${extract_root}..." >&2

tar -xzf "${archive_path}" -C "${extract_root}"

echo "Extraction complete." >&2

toolkit_root="${extract_root}/eb_corbos_toolkit"
workspace_root="${toolkit_root}/workspace"
devcontainer_archive="${toolkit_root}/containers/devcontainer-trixie-ebclfsa-amd64.docker-archive.zst"
buildcontainer_archive="${toolkit_root}/containers/buildcontainer-trixie-ebclfsa-amd64.docker-archive.zst"
run_script="${workspace_root}/scripts/run.sh"
bitbake_execution_fixer="${workspace_root}/.devcontainer/scripts/check_userns_restriction.sh"
manual_pdf="${toolkit_root}/doc/user_manual.pdf"
manual_html_dir="${toolkit_root}/doc/html"
prebuilt_dir="${workspace_root}/prebuilt"

echo "Validating extracted layout..." >&2
for f in "${devcontainer_archive}" "${buildcontainer_archive}" "${run_script}" "${bitbake_execution_fixer}" "${manual_pdf}"; do
  if [[ ! -f "${f}" ]]; then
    echo "ERROR: Expected file not found in extracted upstream delivery archive: ${f}" >&2
    exit 1
  fi
done
for d in "${manual_html_dir}" "${prebuilt_dir}"; do
  if [[ ! -d "${d}" ]]; then
    echo "ERROR: Expected directory not found in extracted upstream delivery archive: ${d}" >&2
    exit 1
  fi
done
echo "Extracted layout looks good." >&2

cat << EOF
TMP_WORK_DIR=${tmp_dir}
EXTRACT_ROOT=${extract_root}
ARCHIVE_PATH=${archive_path}
WORKSPACE_ROOT=${workspace_root}
DEVCONTAINER_ARCHIVE=${devcontainer_archive}
BUILDCONTAINER_ARCHIVE=${buildcontainer_archive}
DEVCONTAINER_IMAGE=ghcr.io/elektrobit/eb-corbos-toolkit-devcontainer-amd64
BUILDCONTAINER_IMAGE=ghcr.io/elektrobit/eb-corbos-toolkit-buildcontainer-amd64
RUN_SCRIPT=${run_script}
BITBAKE_EXECUTION_FIXER=${bitbake_execution_fixer}
MANUAL_PDF=${manual_pdf}
MANUAL_HTML_DIR=${manual_html_dir}
PREBUILT_DIR=${prebuilt_dir}
EOF
