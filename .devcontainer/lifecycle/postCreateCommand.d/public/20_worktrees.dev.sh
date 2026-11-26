#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
# Create the directory for agent worktrees next to the workspace.

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/../../../lib/lib.sh"
dc_init_colors

WORKTREES_DIR="/workspace.worktrees"

$(dc_sudo) mkdir -p "${WORKTREES_DIR}"
$(dc_sudo) chown "$(id -u):$(id -g)" "${WORKTREES_DIR}"

dc_finish
