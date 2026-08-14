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

# Treat the manual input URL as sensitive operational data.
echo "::add-mask::${ARTIFACT_URL}"
echo "::add-mask::${ARTIFACTORY_TOKEN}"

tmp_dir="$(mktemp -d)"
archive_path="${tmp_dir}/eb_corbos_toolkit.tar.gz"
extract_root="${tmp_dir}/extracted"

mkdir -p "${extract_root}"

echo "Starting archive download (this may take a while for large files)..."
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

echo "Starting archive extraction into ${extract_root}..."

tar -xzf "${archive_path}" -C "${extract_root}"

echo "Extraction complete."

# Prepare environment variables for subsequent steps.
cat >> "${GITHUB_ENV}" << EOF
TMP_WORK_DIR=${tmp_dir}
EXTRACT_ROOT=${extract_root}
ARCHIVE_PATH=${archive_path}
WORKSPACE_ROOT=${extract_root}/eb_corbos_toolkit/workspace
DEVCONTAINER_ARCHIVE=${extract_root}/eb_corbos_toolkit/containers/devcontainer-trixie-ebclfsa-amd64.docker-archive.zst
BUILDCONTAINER_ARCHIVE=${extract_root}/eb_corbos_toolkit/containers/buildcontainer-trixie-ebclfsa-amd64.docker-archive.zst
DEVCONTAINER_IMAGE=ghcr.io/elektrobit/eb-corbos-toolkit-devcontainer-amd64
BUILDCONTAINER_IMAGE=ghcr.io/elektrobit/eb-corbos-toolkit-buildcontainer-amd64
RUN_SCRIPT=${extract_root}/eb_corbos_toolkit/workspace/scripts/run.sh
BITBAKE_EXECUTION_FIXER=${extract_root}/eb_corbos_toolkit/workspace/.devcontainer/scripts/check_userns_restriction.sh
EOF
