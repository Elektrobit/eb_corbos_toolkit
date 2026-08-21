#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
# Prepare host-side devcontainer environment files before startup.

set -euo pipefail

###################################################################
# This script is executed before the devcontainer container starts.
###################################################################

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "${SCRIPT_DIR}/../lib/lib.sh"
source "${SCRIPT_DIR}/../lib/common.inc"
dc_init_colors

create_timezone_env_file() {
  local TZ
  local TIMEZONE_FILE
  local ENV_FILE
  TIMEZONE_FILE=/etc/timezone
  ENV_FILE="$(dc_devcontainer_root)/timezone.env"
  if [[ -f "${TIMEZONE_FILE}" ]]
  then
    TZ="$(head -1 /etc/timezone)"
    dc_info "Time zone in the container: TZ=${TZ}"
    echo TZ="${TZ}" > "${ENV_FILE}"
  else
    dc_info "${TIMEZONE_FILE} not found on host, using default time zone in container."
    touch "${ENV_FILE}"
  fi
}


ensure_credentials_file() {
  # Ensure that a credentials file exists and has the correct permissions.
  # Otherwise, the container will not start at all.
  if [ ! -f "${CREDENTIALS_NETRC}" ]; then
    dc_info "Creating empty credentials file at ${CREDENTIALS_NETRC} with permissions 600"
    touch "${CREDENTIALS_NETRC}"
    chmod 600 "${CREDENTIALS_NETRC}"
  fi
}

check_userns_restriction() {
  # Detect the Ubuntu 23.10+ AppArmor restriction of unprivileged user
  # namespaces, which breaks BitBake. Never let this abort container startup.
  bash "${SCRIPT_DIR}/check_userns_restriction.sh" || true
}


create_timezone_env_file
ensure_credentials_file
check_userns_restriction
dc_finish
