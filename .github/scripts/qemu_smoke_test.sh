#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
#
# Smoke test: boot the freshly built "fastdev" image in QEMU inside the
# devcontainer, wait for SSH availability, power it down cleanly and confirm the
# shutdown message appears in the QEMU log.
#
# Usage: qemu_smoke_test.sh --workspace-root <DIR> --run-script <PATH>
set -euo pipefail

workspace_root=""
run_script=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace-root) workspace_root="$2"; shift 2 ;;
    --run-script)     run_script="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "${workspace_root}" ]]; then
  echo "ERROR: Required argument --workspace-root is not set." >&2
  exit 1
fi

if [[ -z "${run_script}" ]]; then
  echo "ERROR: Required argument --run-script is not set." >&2
  exit 1
fi

cd "${workspace_root}"

# Run the dev container in detached mode and keep it running.
export EXTRA_DOCKER_OPTIONS="-d --log-driver local"
LOG_FILE=$(mktemp -t ebcl_run_devcontainer-XXXXXX.log 2>/dev/null) ||
  LOG_FILE="/tmp/ebcl_run_devcontainer.log"

echo "Starting devcontainer in the background" >&2
DEV_CONTAINER_ID=$("${run_script}" -d -- bash -c "sleep infinity" 2>&1 | tee "${LOG_FILE}" | grep -oE '^[0-9a-f]{64}$')
if [[ -z "${DEV_CONTAINER_ID}" ]]; then
  echo "ERROR: Failed to start devcontainer. Log output:" >&2
  cat "${LOG_FILE}" >&2
  exit 1
fi

echo "DEV_CONTAINER_ID=${DEV_CONTAINER_ID}"
sleep 10

devcontainer_exec() {
  docker exec "${DEV_CONTAINER_ID}" "$@"
}

echo "Running fastdev in qemu in background, logging to qemu.log" >&2
devcontainer_exec bash -c "./scripts/qemu.sh -t fastdev < /dev/null > qemu.log 2>&1 &" >&2
devcontainer_exec bash -c \
  "log=/workspace/qemu.log; source /workspace/scripts/includes/common/common.inc; wait_for_ssh fastdev-qemuarm64 70 1" >&2

echo "Terminating fastdev" >&2
devcontainer_exec ssh fastdev-qemuarm64 crinit-ctl poweroff >&2 || true

echo "Waiting for fastdev to power down" >&2
max_tries=20
msg="Power down"
log="${workspace_root}/qemu.log"

for i in $(seq 1 "${max_tries}"); do
  if grep -q "${msg}" "${log}" 2>/dev/null; then
    echo "Waiting for \"${msg}\" message in ${log} succeeded" >&2
    rm -f "${log}"
    # remove files created during devcontainer run
    rm -f "${workspace_root}/.devcontainer/timezone.env"
    rm -f "${workspace_root}/.devcontainer/credentials.netrc"
    exit 0
  fi
  echo "Waiting for \"${msg}\" message in ${log} ... (${i}/${max_tries})" >&2
  sleep 1
done

echo "ERROR: Waiting for \"${msg}\" message in ${log} timed out!" >&2
cat "${log}" >&2
exit 1
