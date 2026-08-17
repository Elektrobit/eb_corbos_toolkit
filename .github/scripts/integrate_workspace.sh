#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
#
# Replace the integration repository's working tree with the upstream workspace,
# preserving repository-owned metadata files. Must be run from the root of the
# integration repository checkout.
#
# Usage: integrate_workspace.sh --workspace-root <DIR>
set -euo pipefail

workspace_root=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace-root) workspace_root="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "${workspace_root}" ]]; then
  echo "ERROR: Required argument --workspace-root is not set." >&2
  exit 1
fi

if [[ ! -d "${workspace_root}" ]]; then
  echo "ERROR: Workspace root '${workspace_root}' does not exist." >&2
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
# Ignore the "prebuilt" and "build" sub-folders as well as everything that is
# preserved in the integration repository.
rsync_excludes=(--exclude='prebuilt' --exclude='build')
for preserve_path in "${preserve_paths[@]}"; do
  rsync_excludes+=(--exclude="/${preserve_path}")
done

rsync -a "${rsync_excludes[@]}" "${workspace_root}/." .
