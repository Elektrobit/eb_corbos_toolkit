#!/usr/bin/env bash
# Copyright 2025 Elektrobit. All rights reserved.

set -e

# Determine script location
FULL_PATH=$(readlink -f $0)
EXEC_NAME=$(basename $FULL_PATH)
SH_DIR=${FULL_PATH%"$EXEC_NAME"}

# Source common.inc to get common variables and functions
source ${SH_DIR}/includes/common/common.inc

# Default values
DEF_PORT=8000
DEF_ROOT="/workspace/prebuilt/"

# Initialized variables
PORT=${DEF_PORT}
ROOT=${DEF_ROOT}

usage()
{
  cat <<USAGE
Usage:
$EXEC_NAME [OPTIONS]
Tool-specific command-line options
  Option                    Help                                            Default
  -r/--root <FOLDER>        Root directory to serve                         [ $DEF_ROOT ]
  -p/--port <PORT>          Port to serve on                                [ $DEF_PORT ]
$COMMON_ARGS
USAGE
}

check_commandline_arguments()
{
    [ -d "${ROOT}" ] \
        && ROOT=$(realpath "${ROOT}") \
        || { echo "Root directory '${ROOT}' does not exist" ; exit 1; }

    [[ "${PORT}" =~ ^[0-9]+$ ]] \
        || { echo "Port '${PORT}' is not a valid number" ; exit 1; }

    [ "${PORT}" -ge 1 ] && [ "${PORT}" -le 65535 ] \
        || { echo "Port '${PORT}' is out of valid range (1-65535)" ; exit 1; }
}

parse_args()
{
    while [[ $# -gt 0 ]] ; do
        key="$1"
        case $key in
            -r|--root)
            ROOT=$2
            shift 2
            ;;
            -p|--port)
            PORT=$2
            shift 2
            ;;
            *)
            COMMON_ARGS_CHECK_LIST="${COMMON_ARGS_CHECK_LIST} $key"
            shift
            ;;
        esac
    done
}

parse_args "$@"
check_common_args ${COMMON_ARGS_CHECK_LIST}
check_commandline_arguments

verbose "Serving '${ROOT}' on port ${PORT}"

cd "${ROOT}"
python3 -m http.server "${PORT}"
