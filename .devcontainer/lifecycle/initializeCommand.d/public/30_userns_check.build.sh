#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
# Detect the Ubuntu 23.10+ AppArmor restriction of unprivileged user namespaces
# (runs on the host before container start), which breaks BitBake.
#
# Thin wrapper: the logic lives in scripts/check_userns_restriction.sh, which is also a standalone
# tool referenced by the User's Manual and therefore keeps its path.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# Never let this abort container startup.
bash "${SCRIPT_DIR}/../../../scripts/check_userns_restriction.sh" || true
