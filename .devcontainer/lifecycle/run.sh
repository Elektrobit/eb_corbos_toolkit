#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
# Run the lifecycle scripts of a devcontainer hook. See lifecycle/README.md.
#
# Kept compatible with bash 3.2, since the initializeCommand hook runs on the host.

set -uo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/../lib/lib.sh"
dc_init_colors

KNOWN_HOOKS="initializeCommand onCreateCommand updateContentCommand postCreateCommand postStartCommand postAttachCommand"

usage() {
  cat <<USAGE
Usage: $(basename "$0") --profile <build|dev> <hook> [ARGS...]
Run the scripts of a devcontainer lifecycle hook that belong to the delivered variants.

  --profile build   Scripts required to build images (buildcontainer and devcontainer).
  --profile dev     Everything from 'build' plus scripts for interactive devcontainer use.
                    Also runs the optional user hook (post_create_hook.sh, post_start_hook.sh).

The profile can also be provided via the DC_PROFILE environment variable.
Hooks: ${KNOWN_HOOKS}
ARGS are passed to every script of the hook; scripts ignore arguments they do not know.
USAGE
}

profile="${DC_PROFILE:-}"
hook=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      [[ $# -ge 2 ]] || { dc_error "--profile requires a value"; exit 2; }
      profile="$2"
      shift 2
      ;;
    --profile=*)
      profile="${1#--profile=}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      dc_error "Unknown option: $1"
      usage >&2
      exit 2
      ;;
    *)
      hook="$1"
      shift
      break
      ;;
  esac
done

case "${profile}" in
  build) profiles="build" ;;
  dev) profiles="build dev" ;;
  *)
    dc_error "A profile (build or dev) is required via --profile or DC_PROFILE, got: '${profile}'"
    usage >&2
    exit 2
    ;;
esac

if [[ -z "${hook}" ]] || [[ " ${KNOWN_HOOKS} " != *" ${hook} "* ]]; then
  dc_error "Missing or unknown hook: '${hook}'"
  usage >&2
  exit 2
fi

user_hook_file() {
  case "$1" in
    postCreateCommand) printf 'post_create_hook.sh' ;;
    postStartCommand) printf 'post_start_hook.sh' ;;
  esac
}

# Print "<basename>\t<path>" for every script of the hook that is present.
list_scripts() {
  local hook_dir="${SCRIPT_DIR}/${hook}.d"
  local p script
  for p in ${profiles}; do
    for script in "${hook_dir}"/*/*."${p}".sh; do
      [[ -f "${script}" ]] || continue
      printf '%s\t%s\n' "$(basename "${script}")" "${script}"
    done
  done
}

export DC_PROFILE="${profile}"
export DC_HOOK="${hook}"

failed=()
ran=0

run_script() {
  local label="$1"
  local script="$2"
  shift 2
  dc_info "==> ${DC_HOOK} [${DC_PROFILE}]: ${label}"
  ran=$((ran + 1))
  if ! bash "${script}" "$@"; then
    dc_error "Failed: ${label}"
    failed+=("${label}")
  fi
}

# Scripts of all selected profiles and variants run interleaved, ordered by their NN_ prefix.
while IFS=$'\t' read -r _ script; do
  label="${script#"${SCRIPT_DIR}/${hook}.d/"}"
  run_script "${label}" "${script}" "$@"
done < <(list_scripts | LC_ALL=C sort -t "$(printf '\t')" -k1,1 -k2,2)

if [[ "${profile}" == "dev" ]]; then
  user_hook="$(user_hook_file "${hook}")"
  if [[ -n "${user_hook}" && -f "${SCRIPT_DIR}/../${user_hook}" ]]; then
    run_script "${user_hook}" "${SCRIPT_DIR}/../${user_hook}"
  fi
fi

if (( ran == 0 )); then
  dc_info "No scripts found for ${hook} (profile ${profile}). Skipping..."
fi

if (( ${#failed[@]} > 0 )); then
  dc_error "${#failed[@]} of ${ran} ${hook} script(s) failed:"
  for label in "${failed[@]}"; do
    dc_error "  - ${label}"
  done
  exit 1
fi

dc_finish
