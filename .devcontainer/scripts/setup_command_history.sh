#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
# Configure persistent bash history for the devcontainer.

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/../lib/lib.sh"
dc_init_colors

USERID=$(id -u)
GROUPID=$(id -g)
COMMANDHISTORY_DIR="/commandhistory"
BASH_HISTORY_FILE="${COMMANDHISTORY_DIR}/.bash_history"
SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=${BASH_HISTORY_FILE}"
BASHRC_FILE="${HOME}/.bashrc"

# Ensure the directory exists and set permissions
$(dc_sudo) mkdir -p "${COMMANDHISTORY_DIR}"
$(dc_sudo) chown "${USERID}:${GROUPID}" "${COMMANDHISTORY_DIR}"
$(dc_sudo) chmod 755 "${COMMANDHISTORY_DIR}"

# Create .bash_history file if it doesn't exist and set permissions
if [[ ! -f "${BASH_HISTORY_FILE}" ]]; then
    touch "${BASH_HISTORY_FILE}"
    $(dc_sudo) chown "${USERID}:${GROUPID}" "${BASH_HISTORY_FILE}"
    $(dc_sudo) chmod 600 "${BASH_HISTORY_FILE}"
fi

# Add snippet to .bashrc if not already present
grep -qF -- "${SNIPPET}" "${BASHRC_FILE}" || echo "${SNIPPET}" >> "${BASHRC_FILE}"

dc_finish
