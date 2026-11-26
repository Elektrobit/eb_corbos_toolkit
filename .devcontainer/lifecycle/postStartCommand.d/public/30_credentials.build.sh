#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
# Set up or check (with --check) the credentials. Arguments are passed on.
#
# Thin wrapper: the logic lives in scripts/setup_credentials.sh, which users also run manually
# (e.g. to re-enter credentials) and therefore keeps its path.

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

exec bash "${SCRIPT_DIR}/../../../scripts/setup_credentials.sh" "$@"
