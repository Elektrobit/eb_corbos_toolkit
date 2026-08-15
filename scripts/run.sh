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
DEF_CONTAINER_ENGINE="docker"
DEF_BUILD_CONTAINER="ghcr.io/elektrobit/eb-corbos-toolkit-buildcontainer-amd64:v13"
DEF_DEV_CONTAINER="ghcr.io/elektrobit/eb-corbos-toolkit-devcontainer-amd64:v13"
DEF_CONTAINER_USER="developer"
DEF_WORKSPACE_DIR=$(realpath ${SH_DIR}/..)

# Initialized variables
CONTAINER_ENGINE="${DEF_CONTAINER_ENGINE}"
CONTAINER_USER="${DEF_CONTAINER_USER}"
WORKSPACE_DIR="${DEF_WORKSPACE_DIR}"

# Uninitialized variables
CONTAINER_NAME=""
USE_DEVCONTAINER=""
EXTRA_DOCKER_OPTIONS="${EXTRA_DOCKER_OPTIONS:-}"
CONTAINER_CMD=""

usage()
{
  cat <<USAGE
Usage:
$EXEC_NAME [OPTIONS] -- <COMMAND> [ARGS...]
Run a build or development container with the required mounts and options.

Tool-specific command-line options
  Option                         Help                                         Default
  -e/--engine <ENGINE>           Container engine                             [ $DEF_CONTAINER_ENGINE ]
  -d/--devcontainer              Use the development container variant
  -n/--name <IMAGE>              Container image name (overrides -d)
  -u/--user <USER>               Container user                               [ $DEF_CONTAINER_USER ]
  -w/--workspace <DIR>           Workspace directory to mount                 [ $DEF_WORKSPACE_DIR ]
  -x/--extra-options <OPTS>      Extra options passed to container engine run

$COMMON_ARGS

Environment variables
  EXTRA_DOCKER_OPTIONS           Extra options passed to container engine run (same as -x)
USAGE
}

check_dependencies()
{
    if ! command -v "${CONTAINER_ENGINE}" > /dev/null 2>&1; then
        echo "Required tool '${CONTAINER_ENGINE}' not found in PATH"
        exit 1
    fi
}

check_commandline_arguments()
{
    [ -z "${CONTAINER_CMD}" ] \
        && { echo "Command is mandatory, please specify after --" ; exit 1; } \
        || true
    [ -d "${WORKSPACE_DIR}" ] \
        || { echo "Workspace directory ${WORKSPACE_DIR} does not exist" ; exit 1; }
}

resolve_container_name()
{
    if [[ -n "${CONTAINER_NAME}" ]]; then
        verbose "Using explicit container name: ${CONTAINER_NAME}"
        return
    fi

    if [[ -n "${USE_DEVCONTAINER}" ]]; then
        CONTAINER_NAME="${DEF_DEV_CONTAINER}"
    else
        CONTAINER_NAME="${DEF_BUILD_CONTAINER}"
    fi
    verbose "Resolved container name: ${CONTAINER_NAME}"
}

resolve_hostname()
{
    if [[ "${CONTAINER_NAME}" == *devcontainer* ]]; then
        echo "--hostname ebcl-dev-container"
    else
        echo "--hostname ebcl-build-container"
    fi
}

build_mounts()
{
    local mounts=""
    [ -d "$(realpath ~/.ssh/ 2>/dev/null)" ]      && mounts="$mounts -v $(realpath ~/.ssh/):/home/${CONTAINER_USER}/.ssh"
    [ -d "$(realpath ~/.gnupg/ 2>/dev/null)" ]    && mounts="$mounts -v $(realpath ~/.gnupg/):/home/${CONTAINER_USER}/.gnupg"
    [ -f "$(realpath ~/.gitconfig 2>/dev/null)" ] && mounts="$mounts -v $(realpath ~/.gitconfig):/home/${CONTAINER_USER}/.gitconfig"
    [ -n "${SSH_AUTH_SOCK:-}" ] && [ -S "$(realpath ${SSH_AUTH_SOCK} 2>/dev/null)" ] \
        && mounts="$mounts -v $(realpath ${SSH_AUTH_SOCK}):/var/run/ssh-agent.socket"
    mounts="${mounts} -v ${WORKSPACE_DIR}:/workspace"
    mounts="${mounts} -v ${WORKSPACE_DIR}/.devcontainer/credentials.netrc:/home/developer/.netrc:ro"
    echo "${mounts}"
}

build_environment_vars()
{
    # Unfortunately, BitBake requires NETRC_FILE in any case - even if the .netrc file is located in the default location.
    # Keep all variables on a single line: the result is embedded into an eval'd command string,
    # where an embedded newline would be interpreted as a command separator.
    echo "-e SSH_AUTH_SOCK=/var/run/ssh-agent.socket -e NETRC_FILE=/home/developer/.netrc"
}

build_uid_rewrite_cmd()
{
    # If no group already owns the host GID, re-target the existing container
    # group to that GID. groupmod is used instead of groupadd because the
    # group name already exists in the image; groupadd would fail with
    # "group already exists" and abort the whole '&&' chain.
    echo "if ! getent group $(id -g) > /dev/null; then \
        groupmod -g $(id -g) ${CONTAINER_USER}; \
      fi && \
      usermod -u $(id -u) ${CONTAINER_USER} && \
      usermod -g $(id -g) ${CONTAINER_USER}"
}

run_container()
{
    local mounts
    local env_vars
    local hostname
    local rewrite_uid
    local interactive=""
    local docker_cmd
    # DevContainer lifecycle scripts, must be executed to ensure correct setup of the container environment
    local initialize=".devcontainer/scripts/initialize.sh"
    local setup_binfmt_support="/workspace/.devcontainer/scripts/setup_binfmt_support.sh"
    local setup_targets="/workspace/.devcontainer/scripts/setup_targets.sh"
    local setup_credentials="/workspace/.devcontainer/scripts/setup_credentials.sh"

    resolve_container_name
    mounts=$(build_mounts)
    env_vars=$(build_environment_vars)
    hostname=$(resolve_hostname)
    rewrite_uid=$(build_uid_rewrite_cmd)

    # Run interactive if started from tty
    [ -t 0 ] && interactive="-it"

    verbose "Container engine: ${CONTAINER_ENGINE}"
    verbose "Container image:  ${CONTAINER_NAME}"
    verbose "Workspace:        ${WORKSPACE_DIR}"
    verbose "User:             ${CONTAINER_USER}"
    verbose "Command:          ${CONTAINER_CMD}"

    # The initialize script is the only one that is run on the host, before container start
    if [ -f "${WORKSPACE_DIR}/${initialize}" ]; then
        verbose "Running container initialization script: ${initialize}"
        bash "${WORKSPACE_DIR}/${initialize}"
    fi

    # Assemble the full container engine command so it can be echoed/logged verbatim
    docker_cmd="${CONTAINER_ENGINE} run --init --privileged ${interactive} \
      --workdir /workspace \
      ${mounts} \
      ${env_vars} \
      ${hostname} \
      ${EXTRA_DOCKER_OPTIONS} \
      ${CONTAINER_NAME} \
      bash -c \
        \"${rewrite_uid} && \
        ${setup_binfmt_support} && \
        runuser -u ${CONTAINER_USER} ${setup_credentials} && \
        ${setup_targets} && \
        runuser -u ${CONTAINER_USER} -- ${CONTAINER_CMD}\""

    # In non-interactive mode, print the exact command that will be executed
    [ -z "${interactive}" ] && echo "Executing container command: ${docker_cmd}"
    eval "${docker_cmd}"
}

# Check commandline arguments
while [[ $# -gt 0 ]] ; do
    key="$1"
    case $key in
    -e|--engine)
    CONTAINER_ENGINE=$2
    shift ; shift
    ;;
    -d|--devcontainer)
    USE_DEVCONTAINER=1
    shift
    ;;
    -n|--name)
    CONTAINER_NAME=$2
    shift ; shift
    ;;
    -u|--user)
    CONTAINER_USER=$2
    shift ; shift
    ;;
    -w|--workspace)
    WORKSPACE_DIR=$2
    shift ; shift
    ;;
    -x|--extra-options)
    EXTRA_DOCKER_OPTIONS=$2
    shift ; shift
    ;;
    --)
    shift
    CONTAINER_CMD=${@@Q}
    break
    ;;
    *)
    COMMON_ARGS_CHECK_LIST="${COMMON_ARGS_CHECK_LIST} $key"
    shift
    ;;
    esac
done

# Check if leftover args belong to common arguments
check_common_args ${COMMON_ARGS_CHECK_LIST}

check_dependencies
check_commandline_arguments
run_container
