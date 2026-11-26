#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
# Pass the host time zone to the container (runs on the host before container start).

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "${SCRIPT_DIR}/../../../lib/lib.sh"
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

create_timezone_env_file
dc_finish
