#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
# Install target hostnames and SSH configurations in the container.

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/../lib/lib.sh"
dc_init_colors

SETUP_TARGETS_DIR="$(dc_devcontainer_root)/setup_targets.d"
HOSTS_DIR="${SETUP_TARGETS_DIR}/hosts"
SSH_CONFIG_DIR="${SETUP_TARGETS_DIR}/ssh_config"

dc_info "Setting up target-specific configurations"

for VARIANT in "${HOSTS_DIR}"/*; do
   [[ -f "${VARIANT}" ]] || continue
   dc_info "Setting up static hostnames from ${VARIANT}"
   $(dc_sudo) tee -a /etc/hosts < "${VARIANT}" > /dev/null
done

for VARIANT in "${SSH_CONFIG_DIR}"/*; do
   [[ -f "${VARIANT}" ]] || continue
   dc_info "Setting up ssh configs from ${VARIANT}"
   $(dc_sudo) cp "${VARIANT}" /etc/ssh/ssh_config.d/
done

dc_finish
