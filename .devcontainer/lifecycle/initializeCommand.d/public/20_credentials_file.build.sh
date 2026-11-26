#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
# Ensure the credentials file exists (runs on the host before container start).

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "${SCRIPT_DIR}/../../../lib/lib.sh"
source "${SCRIPT_DIR}/../../../lib/common.inc"
dc_init_colors

# The container does not start at all without the file, since it is bind-mounted.
if [ ! -f "${CREDENTIALS_NETRC}" ]; then
  dc_info "Creating empty credentials file at ${CREDENTIALS_NETRC} with permissions 600"
  touch "${CREDENTIALS_NETRC}"
  chmod 600 "${CREDENTIALS_NETRC}"
fi

dc_finish
