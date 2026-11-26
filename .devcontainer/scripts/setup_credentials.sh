#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
# Configure and validate credentials for the devcontainer.
#
# This script is a standalone tool: users run it manually to (re-)enter credentials, so it keeps a
# stable path. It is also run by the lifecycle hook script
# lifecycle/postStartCommand.d/public/30_credentials.build.sh (and thereby by scripts/run.sh and CI),
# which only forwards its arguments here. See lifecycle/README.md.
#
# Usage: setup_credentials.sh [--check]
#   (no option)  Run all setup_credentials.d plugins; they may ask for missing credentials.
#   --check      Only validate; never prompts. Prints instructions if credentials are missing.
#
# The credentials file defaults to credentials.netrc in the devcontainer directory and can be
# overridden with the CREDENTIALS_NETRC environment variable (see lib/common.inc).

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/../lib/lib.sh"
source "${SCRIPT_DIR}/../lib/common.inc"
dc_init_colors

check_only=false
if [[ "${1:-}" == "--check" ]]; then
    check_only=true
fi

dc_info "Setting up credentials if necessary..."

credentials_file="${CREDENTIALS_NETRC}"
if $check_only && [[ ! -f "$credentials_file" ]]; then
    dc_error "Error: credentials file does not exist: $credentials_file"
    exit 1
fi

setup_dir="$(dc_devcontainer_root)/setup_credentials.d"
missing_credentials=false

if $check_only; then
    if ! dc_run_plugins "$setup_dir" --check "$credentials_file"; then
        missing_credentials=true
    else
        missing_credentials=false
    fi
else
    if ! dc_run_plugins "$setup_dir" "$credentials_file"; then
        dc_error "Credential setup failed (a plugin returned an error; are you running without a terminal?)."
        exit 1
    fi
fi

if $missing_credentials; then
    dc_banner "Some credentials are not configured."
    dc_info "Run this command in a terminal to set them up:"
    dc_info ""
    dc_info "  bash .devcontainer/scripts/setup_credentials.sh"
    dc_info ""
else
    dc_success "All credentials are properly configured."
fi

dc_finish
