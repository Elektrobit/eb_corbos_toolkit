#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
#
# Download the upstream toolkit archive referenced by the workflow_dispatch
# inputs, extract it into a temporary directory and export the resulting paths
# to GITHUB_ENV for subsequent steps.
#
# Required environment:
#   GITHUB_EVENT_PATH  Path to the event payload holding the dispatch inputs.
#   GITHUB_ENV         Path to the environment file for downstream steps.
set -euo pipefail

ARTIFACT_URL="$(jq -r '.inputs.artifact_url // empty' "${GITHUB_EVENT_PATH}")"
ARTIFACTORY_TOKEN="$(jq -r '.inputs.artifactory_token // empty' "${GITHUB_EVENT_PATH}")"

if [[ -z "${ARTIFACTORY_TOKEN}" ]]; then
  echo "::error::Required workflow input artifactory_token is not set."
  exit 1
fi

if [[ -z "${ARTIFACT_URL}" ]]; then
  echo "::error::Required workflow input artifact_url is not set."
  exit 1
fi

# Treat the manual input URL and token as sensitive operational data.
echo "::add-mask::${ARTIFACT_URL}"
echo "::add-mask::${ARTIFACTORY_TOKEN}"

tmp_dir="$(mktemp -d)"
archive_path="${tmp_dir}/eb_corbos_toolkit.tar.gz"
extract_root="${tmp_dir}/extracted"

mkdir -p "${extract_root}"

echo "Starting upstream delivery archive download (this may take a while for large files)..."
echo "Download target: ${archive_path}"

curl \
  --fail \
  --progress-bar \
  --show-error \
  --location \
  --retry 3 \
  --retry-delay 5 \
  --retry-all-errors \
  --header "Authorization: Bearer ${ARTIFACTORY_TOKEN}" \
  --output "${archive_path}" \
  --url "${ARTIFACT_URL}"

archive_size_bytes="$(wc -c < "${archive_path}")"
archive_size_mib="$(awk "BEGIN { printf \"%.2f\", ${archive_size_bytes}/1024/1024 }")"
echo "Download complete: ${archive_size_bytes} bytes (${archive_size_mib} MiB)."

echo "Starting upstream delivery archive extraction into ${extract_root}..."

tar -xzf "${archive_path}" -C "${extract_root}"

echo "Extraction complete."

toolkit_root="${extract_root}/eb_corbos_toolkit"
workspace_root="${toolkit_root}/workspace"
devcontainer_archive="${toolkit_root}/containers/devcontainer-trixie-ebclfsa-amd64.docker-archive.zst"
buildcontainer_archive="${toolkit_root}/containers/buildcontainer-trixie-ebclfsa-amd64.docker-archive.zst"
run_script="${workspace_root}/scripts/run.sh"
bitbake_execution_fixer="${workspace_root}/.devcontainer/scripts/check_userns_restriction.sh"
manual_pdf="${toolkit_root}/doc/user_manual.pdf"
manual_html_dir="${toolkit_root}/doc/html"
prebuilt_dir="${workspace_root}/prebuilt"

echo "Validating extracted layout..."
for f in "${devcontainer_archive}" "${buildcontainer_archive}" "${run_script}" "${bitbake_execution_fixer}" "${manual_pdf}"; do
  if [[ ! -f "${f}" ]]; then
    echo "::error::Expected file not found in extracted upstream delivery archive: ${f}"
    exit 1
  fi
done
for d in "${manual_html_dir}" "${prebuilt_dir}"; do
  if [[ ! -d "${d}" ]]; then
    echo "::error::Expected directory not found in extracted upstream delivery archive: ${d}"
    exit 1
  fi
done
echo "Extracted layout looks good."

# Prepare environment variables for subsequent steps.
cat >> "${GITHUB_ENV}" << EOF
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
