#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
#
# Smoke test: boot the freshly built "fastdev" image in QEMU inside the
# devcontainer, wait for SSH availability, power it down cleanly and confirm the
# shutdown message appears in the QEMU log.
#
# Required environment:
#   WORKSPACE_ROOT  Extracted upstream workspace directory.
#   RUN_SCRIPT      Path to the workspace run.sh helper.
#   GITHUB_ENV      Path to the environment file for downstream steps.
set -euo pipefail

cd "${WORKSPACE_ROOT}"

# Run the dev container in detached mode and keep it running.
export EXTRA_DOCKER_OPTIONS="-d --log-driver local"
LOG_FILE=$(mktemp -t ebcl_run_devcontainer-XXXXXX.log 2>/dev/null) ||
  LOG_FILE="/tmp/ebcl_run_devcontainer.log"

echo "Starting devcontainer in the background"
DEV_CONTAINER_ID=$("${RUN_SCRIPT}" -d -- bash -c "sleep infinity" 2>&1 | tee "${LOG_FILE}" | grep -oE '^[0-9a-f]{64}$')
if [[ -z "${DEV_CONTAINER_ID}" ]]; then
  echo "::error::Failed to start devcontainer. Log output:"
  cat "${LOG_FILE}"
  exit 1
fi

# Expose the container ID so the always() cleanup step can tear it down.
echo "DEV_CONTAINER_ID=${DEV_CONTAINER_ID}" >> "${GITHUB_ENV}"
sleep 10

devcontainer_exec() {
  docker exec "${DEV_CONTAINER_ID}" "$@"
}

echo "Running fastdev in qemu in background, logging to qemu.log"
devcontainer_exec bash -c "./scripts/qemu.sh -t fastdev < /dev/null > qemu.log 2>&1 &"
devcontainer_exec bash -c \
  "log=/workspace/qemu.log; source /workspace/scripts/includes/common/common.inc; wait_for_ssh fastdev-qemuarm64 70 1"

echo "Terminating fastdev"
devcontainer_exec ssh fastdev-qemuarm64 crinit-ctl poweroff || true

echo "Waiting for fastdev to power down"
max_tries=20
msg="Power down"
log="${WORKSPACE_ROOT}/qemu.log"

for i in $(seq 1 "${max_tries}"); do
  if grep -q "${msg}" "${log}" 2>/dev/null; then
    echo "Waiting for \"${msg}\" message in ${log} succeeded"
    rm -f "${log}"
    exit 0
  fi
  echo "Waiting for \"${msg}\" message in ${log} ... (${i}/${max_tries})"
  sleep 1
done

echo "Error: Waiting for \"${msg}\" message in ${log} timed out!"
cat "${log}"
exit 1
