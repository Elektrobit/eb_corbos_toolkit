#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
#
# Replace the integration repository's working tree with the upstream workspace,
# preserving repository-owned metadata files. Must be run from the root of the
# integration repository checkout.
#
# Required environment:
#   WORKSPACE_ROOT  Extracted upstream workspace directory to copy in.
set -euo pipefail

if [[ ! -d "${WORKSPACE_ROOT}" ]]; then
  echo "::error::WORKSPACE_ROOT '${WORKSPACE_ROOT}' does not exist."
  exit 1
fi

# Remove all tracked and untracked content except the repository metadata and
# files that must remain in the integration repository. Add entries to this list
# when additional repository-owned content should be preserved.
preserve_paths=(
  '.git'
  '.github'
  '.gitignore'
  'CODE_OF_CONDUCT.md'
  'README.md'
)

while IFS= read -r -d '' path; do
  name="${path#./}"
  preserve=false
  for preserve_path in "${preserve_paths[@]}"; do
    if [[ "${name}" == "${preserve_path}" ]]; then
      preserve=true
      break
    fi
  done

  if [[ "${preserve}" != true ]]; then
    rm -rf -- "${path}"
  fi
done < <(find . -mindepth 1 -maxdepth 1 -print0)

# Copy the upstream workspace on top, preserving flags, mtimes, ownership.
# Ignore the "prebuilt" and "build" sub-folders.
rsync -a --exclude='prebuilt' --exclude='build' "${WORKSPACE_ROOT}/." .
