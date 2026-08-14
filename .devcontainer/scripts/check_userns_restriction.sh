#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
#
# Detect the Ubuntu 23.10+ AppArmor restriction of unprivileged user
# namespaces and guide the user to fix it.
# This host-side check is non-fatal so it can never prevent container startup.
#
# Since Ubuntu 23.10 Canonical restricts the creation of unprivileged user
# namespaces via AppArmor. BitBake relies on user namespaces (e.g. to disable
# network access for a task by writing to /proc/self/uid_map). When the
# restriction is active this fails with:
#
#   PermissionError: [Errno 1] Operation not permitted   (writing uid_map)
#
# and the affected BitBake task aborts. The fix is a small AppArmor profile
# that grants the "userns" permission to the BitBake executable.
#
# This script is meant to run on the *host* (AppArmor is a host-kernel feature),
# which is why it is invoked from initialize.sh, the only devcontainer
# lifecycle script that runs on the host before the container starts.
#
# It is intentionally non-fatal: it never aborts container startup. When it
# cannot fix the problem automatically it prints clear manual instructions.
#
# Usage: check_userns_restriction.sh [--yes] [--quiet]
#   --yes    Apply the fix without asking for confirmation (implies sudo use).
#   --quiet  Suppress the "everything is fine" / "not applicable" messages.
#
# Environment overrides (mainly for testing):
#   USERNS_SYSCTL_FILE     sysctl proc file to inspect
#                          (default: /proc/sys/kernel/apparmor_restrict_unprivileged_userns)
#   USERNS_APPARMOR_PROFILE  AppArmor profile file to create
#                          (default: /etc/apparmor.d/bitbake)
#   USERNS_ASSUME_YES=1    same as --yes

# Note: no "set -e" here on purpose. This script must never abort the caller
# (initialize.sh) and thereby prevent the container from starting.
set -uo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/../lib/lib.sh"
dc_init_colors

USERNS_SYSCTL_FILE="${USERNS_SYSCTL_FILE:-/proc/sys/kernel/apparmor_restrict_unprivileged_userns}"
USERNS_APPARMOR_PROFILE="${USERNS_APPARMOR_PROFILE:-/etc/apparmor.d/bitbake}"

ASSUME_YES="${USERNS_ASSUME_YES:-}"
QUIET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes|-y) ASSUME_YES=1 ;;
    --quiet|-q) QUIET=1 ;;
    *) echo "check_userns_restriction: ignoring unknown argument '$1'" >&2 ;;
  esac
  shift
done

# The AppArmor profile that allows BitBake to create user namespaces.
# The path glob matches the BitBake executable regardless of where the
# workspace is checked out or mounted (host or container).
print_profile() {
  cat <<'PROFILE'
abi <abi/4.0>,
include <tunables/global>
profile bitbake /**/bitbake/bin/bitbake flags=(unconfined) {
  userns,
}
PROFILE
}

print_manual_instructions() {
  cat <<EOF
${C_BOLD}To fix this, run the following commands on your host and then restart:${C_RESET}

  sudo tee ${USERNS_APPARMOR_PROFILE} > /dev/null <<'EOP'
$(print_profile)
EOP
  sudo apparmor_parser -r ${USERNS_APPARMOR_PROFILE}

Alternatively, disabling the restriction system-wide also works but is less
targeted:

  sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0

See the "Troubleshooting" section of the user manual for details.
EOF
}

apply_fix() {
  if ! command -v apparmor_parser > /dev/null 2>&1; then
    dc_error "Cannot apply fix automatically: 'apparmor_parser' not found."
    print_manual_instructions
    return 1
  fi

  dc_info "Writing AppArmor profile to ${USERNS_APPARMOR_PROFILE} ..."
  if ! print_profile | $(dc_sudo) tee "${USERNS_APPARMOR_PROFILE}" > /dev/null; then
    dc_error "Failed to write ${USERNS_APPARMOR_PROFILE}."
    print_manual_instructions
    return 1
  fi

  dc_info "Loading AppArmor profile ..."
  if ! $(dc_sudo) apparmor_parser -r "${USERNS_APPARMOR_PROFILE}"; then
    dc_error "Failed to load the AppArmor profile."
    print_manual_instructions
    return 1
  fi

  dc_success "AppArmor profile for BitBake installed and loaded successfully."
  return 0
}

main() {
  # AppArmor and this restriction only exist on Linux hosts.
  if [[ "$(uname -s)" != "Linux" ]]; then
    dc_info "Not a Linux host, skipping user namespace restriction check."
    return 0
  fi

  # If the sysctl knob is absent or not active, there is nothing to do.
  if [[ ! -r "${USERNS_SYSCTL_FILE}" ]]; then
    dc_info "AppArmor user namespace restriction not present on this host."
    return 0
  fi

  local value
  value="$(cat "${USERNS_SYSCTL_FILE}" 2>/dev/null || echo 0)"
  if [[ "${value}" != "1" ]]; then
    dc_info "AppArmor user namespace restriction is not active."
    return 0
  fi

  # Restriction is active. Is the fix already in place?
  if [[ -f "${USERNS_APPARMOR_PROFILE}" ]]; then
    dc_info "AppArmor user namespace restriction is active, but a BitBake profile" \
         "already exists at ${USERNS_APPARMOR_PROFILE}. Nothing to do."
    return 0
  fi

  # Problem detected and not yet fixed: make it impossible to miss.
  echo ""
  dc_banner "WARNING: Unprivileged user namespaces are restricted" "${C_YELLOW}${C_BOLD}"
  echo "This host (Ubuntu 23.10+ or similar) restricts unprivileged user"
  echo "namespaces via AppArmor. BitBake needs them and will otherwise fail with:"
  echo ""
  echo "    PermissionError: [Errno 1] Operation not permitted"
  echo ""

  # Decide whether we may apply the fix automatically.
  local do_fix=""
  if [[ -n "${ASSUME_YES}" ]]; then
    do_fix=1
  elif [[ -t 0 ]]; then
    local answer=""
    read -r -p "Apply the recommended AppArmor fix now (requires sudo)? [y/N] " answer
    case "${answer}" in
      [yY]|[yY][eE][sS]) do_fix=1 ;;
      *) do_fix="" ;;
    esac
  fi

  if [[ -n "${do_fix}" ]]; then
    apply_fix || true
  else
    print_manual_instructions
  fi

  # Always succeed: never block container startup.
  return 0
}

main "$@"
