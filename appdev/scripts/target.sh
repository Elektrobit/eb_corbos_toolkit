#!/usr/bin/env bash
# Copyright 2025 Elektrobit Automotive GmbH
# All rights reserved

set -e

# Determine script location
FULL_PATH=$(readlink -f $0)
EXEC_NAME=$(basename $FULL_PATH)
SH_DIR=${FULL_PATH%"$EXEC_NAME"}

# Source common.inc to get common variables and functions
source ${SH_DIR}/common.inc

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
APP=""
PRESET=""
APP_BIN=""

usage()
{
  cat <<USAGE
Usage:
$EXEC_NAME -c/--cmd <CMD> -a/--app <FOLDER> -p/--preset <PRESET>
Tool-specific command-line options
  Option                    Help                                            Default
  -c/--cmd <CMD>            Command to be executed
  -a/--app <FOLDER>         Application base folder
  -p/--preset <PRESET>      Application preset
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
    [ -z "${APP}" ] \
        && { echo "Application folder is mandatory, please specify via -a or --app" ; exit 1; } \
        || true
    [ -z "${PRESET}" ] \
        && { echo "Application preset is mandatory, please specify via -p or --preset" ; exit 1; } \
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

create_gdbinit_file()
{
    _APP_BUILD_DIR=$1
    _GDB_TARGET=$2
    _GDB_PORT=$3
    touch $_APP_BUILD_DIR/.gdbinit
    echo "target extended-remote $_GDB_TARGET:$_GDB_PORT" > $_APP_BUILD_DIR/.gdbinit
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
        _GDBINIT_CMD=$(cat $_APP_BUILD_DIR/.gdbinit)
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
    _SSH_PREFIX="$1"
    _SSH_PORT="$2"
    _SSH_USER="$3"
    _SSH_TARGET="$4"
    _SSH_PROBE_ATTEMPTS="$5"
    _SSH_PROBE_DELAY_S="$6"
    _SSH_PROBE_OPTS="-o ConnectTimeout=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    _KNOWN_HOSTS=/home/$(whoami)/.ssh/known_hosts

    _SSH_CMD="$_SSH_PREFIX ssh"
    _SSH_COMMON_PARM="-p $_SSH_PORT $SSH_USER@$_SSH_TARGET true"

    # check if known_hosts exist, if not, create a  new one
    [ -f ${_KNOWN_HOSTS} ] || { touch ${_KNOWN_HOSTS} ; chmod 600 ${_KNOWN_HOSTS} ; }

    # probe ssh connection
    if [[ ${_SSH_PROBE_ATTEMPTS} -gt 0 ]]; then
        _ATTEMPTS=0
        verbose "Probing SSH connection..."
        while [[ ${_ATTEMPTS} -lt ${_SSH_PROBE_ATTEMPTS} ]]; do
            if $_SSH_CMD $_SSH_PROBE_OPTS $_SSH_COMMON_PARM &> /dev/null; then
                verbose "SSH connection established."
                break
            else
                verbose "SSH probe $((_ATTEMPTS + 1)) failed. Retrying..."
                _ATTEMPTS=$((_ATTEMPTS+1))
                sleep $_SSH_PROBE_DELAY_S
            fi
        done
        if [[ ${_ATTEMPTS} -eq ${_SSH_PROBE_ATTEMPTS} ]]; then
            bold "Failed to establish SSH connection after ${_SSH_PROBE_ATTEMPTS} attempts"
            exit 1
        fi
    fi

    # For any port other than 22, we need to use [] for the hostname/IP
    $_SSH_CMD $_SSH_COMMON_PARM || { \
        [ "$_SSH_PORT" != "$_SSH_WELL_KNOWN" ] && _SSH_TARGET="[$_SSH_TARGET]:$_SSH_PORT" ; \
        verbose "SSH key not found or outdated, performing update!" ; \
        ssh-keygen -f "$_KNOWN_HOSTS" -R "$_SSH_TARGET"; \
        $_SSH_CMD -o StrictHostKeyChecking=accept-new $_SSH_COMMON_PARM; \
    }
}

app_deploy()
{
    _SSH_PREFIX=$1
    _SSH_PORT=$2
    _SSH_USER=$3
    _SSH_TARGET=$4
    _APP_INSTALL=$5

    eval $_SSH_PREFIX rsync -rlptdv -e \"ssh -p $_SSH_PORT\" --exclude */include/* --exclude *.h --exclude *.debug $_APP_INSTALL/* $_SSH_USER@[$_SSH_TARGET]:/
}

app_run()
{
    _SSH_PREFIX=$1
    _SSH_PORT=$2
    _SSH_USER=$3
    _SSH_TARGET=$4
    _APP_BIN=$5
    # Start application, hangs until ctr-c or application termination
    eval $_SSH_PREFIX ssh -t -p $_SSH_PORT $_SSH_USER@$_SSH_TARGET $_APP_BIN || true
    # Cleanup, try to kill application process
    eval $_SSH_PREFIX ssh -p $_SSH_PORT $_SSH_USER@$_SSH_TARGET killall $_APP_BIN  || true
}

app_start_debug()
{
    _SSH_PREFIX=$1
    _SSH_PORT=$2
    _SSH_USER=$3
    _SSH_TARGET=$4
    _APP_BUILD_DIR=$5
    _GDB_TARGET=$6
    _GDB_PORT=$7
    _PROBE_ATTEMPTS=$8
    _PROBE_DELAY_S=$9
    # Set target address in .gdbinit file
    create_gdbinit_file "$_APP_BUILD_DIR" "$_GDB_TARGET" "$_GDB_PORT"
    # Start gdbserver on target
    eval $_SSH_PREFIX ssh -p $_SSH_PORT $_SSH_USER@$_SSH_TARGET "gdbserver --multi [::]:$_GDB_PORT >/dev/null 2>/tmp/gdb.err & "
    # Check if the gdbserver instance is running on the target 
    check_gdb_connection "$_APP_BUILD_DIR" "$_PROBE_ATTEMPTS" "$_PROBE_DELAY_S"
}

app_attach_debug()
{
    _SSH_PREFIX=$1
    _SSH_PORT=$2
    _SSH_USER=$3
    _SSH_TARGET=$4
    _APP_BUILD_DIR=$5
    _APP_BIN=$6
    _GDB_TARGET=$7
    _GDB_PORT=$8
    _PROBE_ATTEMPTS=$9
    _PROBE_DELAY_S=$10
    # Set target address in .gdbinit file
    create_gdbinit_file "$_APP_BUILD_DIR" "$_GDB_TARGET" "$_GDB_PORT"
    # Determine PID on target
    _BIN_NAME=$(basename $_APP_BIN)
    _PID=$(eval $_SSH_PREFIX ssh -p $_SSH_PORT $_SSH_USER@$_SSH_TARGET pgrep $_BIN_NAME)
    if [[ $(echo $_PID | wc -w) -gt 1 ]] ; then
        echo "Multiple PIDs for binary $_APP_BIN available, please select the correct PID from the following list:"
        for i in $(echo $_PID); do 
            echo "  $i";
        done
        read -p "PID: " _PID
    fi
    # Start gdbserver on target
    eval $_SSH_PREFIX ssh -p $_SSH_PORT $_SSH_USER@$_SSH_TARGET "gdbserver --attach [::]:$_GDB_PORT $_PID >/dev/null 2>/tmp/gdb.err & "
    # Check if the gdbserver instance is running on the target
    check_gdb_connection "$_APP_BUILD_DIR" "$_PROBE_ATTEMPTS" "$_PROBE_DELAY_S"
}

app_stop_debug()
{
    _SSH_PREFIX=$1
    _SSH_PORT=$2
    _SSH_USER=$3
    _SSH_TARGET=$4
    $_SSH_PREFIX ssh -p $_SSH_PORT $_SSH_USER@$_SSH_TARGET killall gdbserver || true
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
    APP=$(realpath $2)
    shift ; shift
    ;;
    -p|--preset)
    PRESET=$2
    shift ; shift
    ;;
    -b|--bin)
    APP_BIN=$2
    shift ; shift
    ;;  
    -pa|--probe-attempts)
    PROBE_ATTEMPTS=$2
    shift | shift
    ;;
    -pd|--probe-delay)
    PROBE_DELAYS=$2
    shift | shift
    ;;
    *)
    COMMON_ARGS_CHECK_LIST="${COMMON_ARGS_CHECK_LIST} $key"
    shift
    ;;
    esac
done

# Check if leftover args belong to common arguments
check_common_args ${COMMON_ARGS_CHECK_LIST}

APP_BUILD_DIR=$APP/build/$PRESET
APP_INSTALL_DIR=$APP_BUILD_DIR/install

check_commandline_arguments

bold "Derive deployment target"
source ${SH_DIR}/deployment_targets.inc
verbose "  TARGET_IP=${TARGET_IP}"
verbose "  SSH_PORT=${SSH_PORT}"
verbose "  SSH_USER=${SSH_USER}"
verbose "  SSH_PREFIX=${SSH_PREFIX}"
verbose "  GDB_PORT=${GDB_PORT}"
verbose "  GDB_TARGET_IP=${GDB_TARGET_IP}"

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

run_task "Perform connection check" \
         ${CHECK_CONNECTION} \
         check_ssh_connection "$SSH_PREFIX" "$SSH_PORT" "$SSH_USER" "$TARGET_IP" "$PROBE_ATTEMPTS" "$PROBE_DELAYS"

run_task "Deploy application" \
         ${APP_DEPLOY} \
         app_deploy "$SSH_PREFIX" "$SSH_PORT" "$SSH_USER" "$TARGET_IP" "$APP_INSTALL_DIR"

run_task "Run application on target" \
         ${APP_RUN} \
         app_run "$SSH_PREFIX" "$SSH_PORT" "$SSH_USER" "$TARGET_IP" "$APP_BIN"

run_task "Start gdbserver on target" \
         ${APP_START_DEBUG} \
         app_start_debug "$SSH_PREFIX" "$SSH_PORT" "$SSH_USER" "$TARGET_IP" "$APP_BUILD_DIR" "$GDB_TARGET_IP" "$GDB_PORT" "$PROBE_ATTEMPTS" "$PROBE_DELAYS"

run_task "Attach gdbserver on target to PID of binary $APP_BIN" \
         ${APP_ATTACH_DEBUG} \
         app_attach_debug "$SSH_PREFIX" "$SSH_PORT" "$SSH_USER" "$TARGET_IP" "$APP_BUILD_DIR" "$APP_BIN" "$GDB_TARGET_IP" "$GDB_PORT" "$PROBE_ATTEMPTS" "$PROBE_DELAYS"

run_task "Stop gdbserver on target" \
         ${APP_STOP_DEBUG} \
         app_stop_debug "$SSH_PREFIX" "$SSH_PORT" "$SSH_USER" "$TARGET_IP"
