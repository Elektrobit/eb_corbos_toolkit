#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
# Shared functions for devcontainer lifecycle and setup scripts.

[[ -n "${_DEVCONTAINER_LIB_SH:-}" ]] && return 0
_DEVCONTAINER_LIB_SH=1

dc_script_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[1]}")" && pwd
}

dc_devcontainer_root() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd
}

dc_init_colors() {
  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_BOLD="$(printf '\033[1m')"
    C_RED="$(printf '\033[31m')"
    C_YELLOW="$(printf '\033[33m')"
    C_GREEN="$(printf '\033[32m')"
    C_RESET="$(printf '\033[0m')"
  else
    C_BOLD="" C_RED="" C_YELLOW="" C_GREEN="" C_RESET=""
  fi
}

dc_info() {
  [[ -n "${QUIET:-}" ]] || printf '%s\n' "$*"
}

dc_warn() {
  printf '%b%s%b\n' "${C_YELLOW:-}" "$*" "${C_RESET:-}" >&2
}

dc_error() {
  printf '%b%s%b\n' "${C_RED:-}" "$*" "${C_RESET:-}" >&2
}

dc_success() {
  printf '%b%s%s%b\n' "${C_BOLD:-}" "${C_GREEN:-}" "$*" "${C_RESET:-}"
}

dc_sudo() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf 'sudo'
  fi
}

dc_banner() {
  local title="${1:-}"
  local color="${2:-${C_YELLOW:-}}"
  local line="============================================================"

  printf '\n%b%s%b\n' "$color" "$line" "${C_RESET:-}"
  printf '%b  %s%b\n' "$color" "$title" "${C_RESET:-}"
  printf '%b%s%b\n\n' "$color" "$line" "${C_RESET:-}"
}

dc_run_plugins() {
  local plugin_dir="$1"
  shift
  local status=0
  local had_nullglob=0
  local plugin
  local plugins=()

  shopt -q nullglob && had_nullglob=1
  shopt -s nullglob
  [[ -d "$plugin_dir" ]] && plugins=("$plugin_dir"/*.sh)
  (( had_nullglob )) || shopt -u nullglob

  if (( ${#plugins[@]} == 0 )); then
    dc_info "No setup files found in ${plugin_dir}. Skipping..."
    return 0
  fi

  for plugin in "${plugins[@]}"; do
    if ! bash "$plugin" "$@"; then
      status=1
    fi
  done
  return "$status"
}

dc_finish() {
  printf 'Finished execution of %s!\n' "$0"
}
