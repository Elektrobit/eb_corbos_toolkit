#!/usr/bin/env bash
# Copyright 2025 Elektrobit. All rights reserved.

set -e

# Determine script location
FULL_PATH=$(readlink -f $0)
EXEC_NAME=$(basename $FULL_PATH)
SH_DIR=${FULL_PATH%"$EXEC_NAME"}

# Source common.inc to get common variables and functions
source ${SH_DIR}/includes/common/common.inc

# Internal helper variables
SUPPORTED_CMDS=(deploy run start_debug attach_debug stop_debug)
CHECK_CONNECTION="0"
APP_DEPLOY="0"
APP_RUN="0"
APP_START_DEBUG="0"
APP_ATTACH_DEBUG="0"
APP_STOP_DEBUG="0"

# Default values
DEF_PROBE_ATTEMPTS=5
DEF_PROBE_DELAYS=2

# Initialized variables
PROBE_ATTEMPTS=${DEF_PROBE_ATTEMPTS}
PROBE_DELAYS=${DEF_PROBE_DELAYS}

# Uninitialized variables
CMD=""
APP_BUILD_DIR=""
TARGET_HOST=""
APP_BIN=""

usage()
{
  cat <<USAGE
Usage:
$EXEC_NAME -c/--cmd <CMD> -a/--app <FOLDER> -t/--target <ADDRESS>
Tool-specific command-line options
  Option                    Help                                            Default
  -c/--cmd <CMD>            Command to be executed
  -a/--app <FOLDER>         Application build folder
  -t/--target <ADDRESS>     Target host address overwrite
  -b/--bin <APP_BIN>        Application binary path on target
  -pa/--probe-attempts <NR> Number of probe attempts for ip connections     [ $DEF_PROBE_ATTEMPTS ]
  -pd/--probe-delay <SEC>   Probe polling delay in seconds                  [ $DEF_PROBE_DELAYS ]

$COMMON_ARGS
USAGE
}

check_commandline_arguments()
{
    [ -z "${CMD}" ] \
        && { echo "Command is mandatory, please specify via -c or --cmd" ; exit 1; } \
        || true
    [ -z "${APP_BUILD_DIR}" ] \
        && { echo "Application build folder is mandatory, please specify via -a or --app" ; exit 1; } \
        || true
    [ -z "${TARGET_HOST}" ] \
        && { echo "Target host address is mandatory, either place it in ${APP_BUILD_DIR}/.target_host or specify via -t or --target" ; exit 1; } \
        || true
    [[ "${CMD}" == "run"  &&  -z "${APP_BIN}" ]] \
        && { echo "Please specify application binary path on target via -b/--bin" ; exit 1; } \
        || true
    [[ "${CMD}" == "attach_debug"  &&  -z "${APP_BIN}" ]] \
        && { echo "Please specify application binary path on target via -b/--bin" ; exit 1; } \
        || true
    [ -d $APP_INSTALL_DIR ] \
        && true \
        || { echo "Application install directory not available at $APP_INSTALL, please build application first." ; exit 1; }
}

derive_gdb_port()
{
    _APP_BUILD_DIR=$1
    # Expect a line with "target extended-remote HOST:PORT in .gdbinit file"
    _GDB_PORT=$(cat $_APP_BUILD_DIR/.gdbinit | grep "target extended-remote" | rev | cut -d : -f1 | rev)
    if [[ -z "${_GDB_PORT}" ]]; then
        echo "Failed to derive GDB port from .gdbinit file at ${_APP_BUILD_DIR}/.gdbinit"
        exit 1
    fi
    echo "${_GDB_PORT}"
}

check_gdb_connection()
{
    _APP_BUILD_DIR=$1
    _PROBE_ATTEMPTS=$2
    _PROBE_DELAY_S=$3
    _ATTEMPTS=0
    while [[ ${_ATTEMPTS} -lt ${_PROBE_ATTEMPTS} ]]; do
        # Check if gdbserver is already up and running. We simply re-use the connection settings
        # which have been stored in $_APP_BUILD_DIR/.gdbinit.
        _GDBINIT_CMD=$(cat $_APP_BUILD_DIR/.gdbinit | grep "target extended-remote")
        if gdb-multiarch --eval-command="$_GDBINIT_CMD" --batch &> /dev/null; then
            verbose "GDB connection established."
            break
        else
            verbose "GDB probe $((_ATTEMPTS + 1)) failed. Retrying..."
            _ATTEMPTS=$((_ATTEMPTS+1))
            sleep $_PROBE_DELAY_S
        fi
    done
    if [[ ${_ATTEMPTS} -eq ${_PROBE_ATTEMPTS} ]]; then
        bold "Failed to establish GDB connection after ${_PROBE_ATTEMPS} attempts"
        exit 1
    fi
}

check_ssh_connection()
{
    _SSH_HOST="$1"
    _SSH_PROBE_ATTEMPTS="$2"
    _SSH_PROBE_DELAY_S="$3"

    if [[ ${_SSH_PROBE_ATTEMPTS} -gt 0 ]]; then
        verbose "Probing SSH connection to ${_SSH_HOST}..."
        wait_for_ssh "${_SSH_HOST}" "${_SSH_PROBE_ATTEMPTS}" "${_SSH_PROBE_DELAY_S}"
    fi
}

app_deploy()
{
    _SSH_HOST=$1
    _APP_INSTALL=$2

    rsync -rlptdv -e "ssh" --exclude */include/* --exclude *.h --exclude *.debug $_APP_INSTALL/* ${_SSH_HOST}:/
}

app_run()
{
    _SSH_HOST=$1
    _APP_BIN=$2
    # Start application, hangs until ctr-c or application termination
    ssh -t ${_SSH_HOST} $_APP_BIN || true
    # Cleanup, try to kill application process
    ssh ${_SSH_HOST} killall $_APP_BIN || true
}

app_start_debug()
{
    _SSH_HOST=$1
    _APP_BUILD_DIR=$2
    _PROBE_ATTEMPTS=$3
    _PROBE_DELAY_S=$4
    # Get _GDB_PORT from .gdbinit file
    _GDB_PORT=$(derive_gdb_port "$_APP_BUILD_DIR")
    # Start gdbserver on target
    ssh ${_SSH_HOST} "gdbserver --multi [::]:$_GDB_PORT >/dev/null 2>/tmp/gdb.err & "
    # Check if the gdbserver instance is running on the target
    check_gdb_connection "$_APP_BUILD_DIR" "$_PROBE_ATTEMPTS" "$_PROBE_DELAY_S"
}

app_attach_debug()
{
    _SSH_HOST=$1
    _APP_BUILD_DIR=$2
    _APP_BIN=$3
    _PROBE_ATTEMPTS=$4
    _PROBE_DELAY_S=$5
    # Get _GDB_PORT from .gdbinit file
    _GDB_PORT=$(derive_gdb_port "$_APP_BUILD_DIR")
    # Determine PID on target
    _BIN_NAME=$(basename $_APP_BIN)
    _PID=$(ssh ${_SSH_HOST} pgrep $_BIN_NAME)
    if [[ $(echo $_PID | wc -w) -gt 1 ]] ; then
        echo "Multiple PIDs for binary $_APP_BIN available, please select the correct PID from the following list:"
        for i in $(echo $_PID); do
            echo "  $i";
        done
        read -p "PID: " _PID
    fi
    # Start gdbserver on target
    ssh ${_SSH_HOST} "gdbserver --attach [::]:$_GDB_PORT $_PID >/dev/null 2>/tmp/gdb.err & "
    # Check if the gdbserver instance is running on the target
    check_gdb_connection "$_APP_BUILD_DIR" "$_PROBE_ATTEMPTS" "$_PROBE_DELAY_S"
}

app_stop_debug()
{
    _SSH_HOST=$1
    ssh ${_SSH_HOST} killall gdbserver || true
}

run_task()
{
    MSG=$1
    shift
    CHECK_VAR=$1
    shift
    TASK=$1
    shift
    if [[ "${CHECK_VAR}" == "1" ]] ; then
        bold "${MSG}"
        CMD=${TASK}
        # Construct full command.
        # Prevent argument splitting with " "
        while [[ $# -gt 0 ]] ; do
            CMD="${CMD} \"$1\""
            shift
        done
        eval ${CMD}
    fi
}

# Check commandline arguments
while [[ $# -gt 0 ]] ; do
    key="$1"
    case $key in
    -c|--cmd)
    if (printf '%s\n' "${SUPPORTED_CMDS[@]}" | grep -xq $2); then
        CMD=$2
    else
        echo "Command $2 not supported!"
        echo "Supported commands variants are: "
        printf '   %s\n' "${SUPPORTED_CMDS[@]}"
        exit -1
    fi
    shift ; shift
    ;;
    -a|--app)
    APP_BUILD_DIR=$(realpath $2)
    shift ; shift
    ;;
    -t|--target)
    TARGET_HOST=$2
    shift ; shift
    ;;
    -b|--bin)
    APP_BIN=$2
    shift ; shift
    ;;
    -pa|--probe-attempts)
    PROBE_ATTEMPTS=$2
    shift ; shift
    ;;
    -pd|--probe-delay)
    PROBE_DELAY_S=$2
    shift ; shift
    ;;
    *)
    COMMON_ARGS_CHECK_LIST="${COMMON_ARGS_CHECK_LIST} $key"
    shift
    ;;
    esac
done

# Check if leftover args belong to common arguments
check_common_args ${COMMON_ARGS_CHECK_LIST}

bold "Determine deployment target"
if [ -z "${TARGET_HOST}" ]; then
    if [ -f "${APP_BUILD_DIR}/.target_host" ]; then
        TARGET_HOST=$(cat ${APP_BUILD_DIR}/.target_host)
        verbose "Target host read from ${APP_BUILD_DIR}/.target_host: ${TARGET_HOST}"
    fi
else
    verbose "Overwrite flag for target host set, ignoring ${APP_BUILD_DIR}/.target_host if existing."
fi

APP_INSTALL_DIR=$APP_BUILD_DIR/install

check_commandline_arguments

bold "Determine required tasks to be executed for command: ${CMD}"
case $CMD in
    deploy)
    CHECK_CONNECTION="1"
    APP_DEPLOY="1"
    ;;
    run)
    CHECK_CONNECTION="1"
    APP_DEPLOY="1"
    APP_RUN="1"
    ;;
    start_debug)
    CHECK_CONNECTION="1"
    APP_DEPLOY="1"
    APP_START_DEBUG="1"
    ;;
    attach_debug)
    CHECK_CONNECTION="1"
    APP_ATTACH_DEBUG="1"
    ;;
    stop_debug)
    CHECK_CONNECTION="1"
    APP_STOP_DEBUG="1"
    ;;
    *)
    bold "Unknown command, exiting."
    exit 1
    ;;
esac

verbose "  CHECK_CONNECTION=${CHECK_CONNECTION}"
verbose "  APP_DEPLOY=${APP_DEPLOY}"
verbose "  APP_RUN=${APP_RUN}"
verbose "  APP_START_DEBUG=${APP_START_DEBUG}"
verbose "  APP_ATTACH_DEBUG=${APP_ATTACH_DEBUG}"
verbose "  APP_STOP_DEBUG=${APP_STOP_DEBUG}"

run_task "Perform connection check" \
         ${CHECK_CONNECTION} \
         check_ssh_connection "$TARGET_HOST" "$PROBE_ATTEMPTS" "$PROBE_DELAYS"

run_task "Deploy application" \
         ${APP_DEPLOY} \
         app_deploy "$TARGET_HOST" "$APP_INSTALL_DIR"

run_task "Run application on target" \
         ${APP_RUN} \
         app_run "$TARGET_HOST" "$APP_BIN"

run_task "Start gdbserver on target" \
         ${APP_START_DEBUG} \
         app_start_debug "$TARGET_HOST" "$APP_BUILD_DIR" "$PROBE_ATTEMPTS" "$PROBE_DELAYS"

run_task "Attach gdbserver on target to PID of binary $APP_BIN" \
         ${APP_ATTACH_DEBUG} \
         app_attach_debug "$TARGET_HOST" "$APP_BUILD_DIR" "$APP_BIN" "$PROBE_ATTEMPTS" "$PROBE_DELAYS"

run_task "Stop gdbserver on target" \
         ${APP_STOP_DEBUG} \
         app_stop_debug "$TARGET_HOST"
