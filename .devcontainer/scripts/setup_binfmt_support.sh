#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
# Configure host binfmt support for aarch64 containers.

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/../lib/lib.sh"
dc_init_colors

BINFMT_ID="qemu-aarch64"
BINFMT_CFG="$(dc_devcontainer_root)/binfmt-config/${BINFMT_ID}"
BINFMT_PROC="/proc/sys/fs/binfmt_misc"

function check_if_binfmt_available {
   if [ "$(ls ${BINFMT_PROC}/ | grep ${BINFMT_ID})" ]; then
      echo "true"
   else
      echo "false"
   fi
}

if [ "$(uname -p)" != "aarch64" ]; then
   if [ ! "$(mount -l | grep binfmt)" ]; then
      dc_info "Mounting binfmt_misc to ${BINFMT_PROC}"
      $(dc_sudo) mount binfmt_misc -t binfmt_misc "${BINFMT_PROC}"
   fi

   if [ "$(check_if_binfmt_available)" == "true" ]; then
      dc_warn "Binfmt support for aarch64 already available!"
      dc_warn "Overwriting it with our own binary path. This may invalidate your host binfmt configuration."
      dc_warn "To revert our changes, reboot your system or run the following commands on your host after container shutdown:"
      dc_warn "         $(dc_sudo) update-binfmts --disable ${BINFMT_ID} && $(dc_sudo) update-binfmts --enable ${BINFMT_ID}"
      $(dc_sudo) update-binfmts --disable "${BINFMT_ID}"
   fi

   $(dc_sudo) update-binfmts --import "${BINFMT_CFG}"

   if [ "$(check_if_binfmt_available)" == "true" ]; then
      dc_success "Binfmt support for aarch64 available!"
   else
      dc_error "Failed to setup binfmt support, aborting!"
      exit 1
   fi
else
   dc_info "Running natively on aarch64, skipping binfmt setup!"
fi

dc_finish
