#!/usr/bin/env bash
# Copyright 2025 Elektrobit Automotive GmbH
# All rights reserved

# Minimalistic script to run a build/dev container with the required mounts and options

# Determine script/workspace location
FULL_PATH=$(readlink -f "$0")
EXEC_NAME=$(basename "$FULL_PATH")
SH_DIR=${FULL_PATH%"$EXEC_NAME"}

# Container engine and name can be specified via ENV variables
CONTAINER_ENGINE="${CONTAINER_ENGINE:-docker}"
# If CONTAINER_NAME is not set, USE_DEVCONTAINER is evaluated. If it is set,
# the devcontainer variant is used, otherwise it defaults to the buildcontainer
# variant.
# Setting CONTAINER_NAME explicitly, results in ignoring the value of USE_DEVCONTAINER.
# Instead, the provided value of CONTAINER_NAME is used.
DEV_CONTAINER_NAME="artifactory.elektrobit.com/eb_corbos_linux-snapshots-docker/ebcl-sdk/devcontainer-amd64:main"
BUILD_CONTAINER_NAME="artifactory.elektrobit.com/eb_corbos_linux-snapshots-docker/ebcl-sdk/buildcontainer-amd64:main"
if [[ -z "${CONTAINER_NAME}" ]]; then
    if [[ -z "${USE_DEVCONTAINER}" ]]; then 
        CONTAINER_NAME=$BUILD_CONTAINER_NAME
        # host name for container
        NAME="--hostname ebcl-build-container"
    else
        CONTAINER_NAME=$DEV_CONTAINER_NAME
        # host name for container
        NAME="--hostname ebcl-dev-container"
    fi
fi

# Run interactive if started from tty
if [ -t 0 ]; then
INTERACTIVE="-it"
else
INTERACTIVE=""
fi
# Default container user
USER="developer"

# Mounts required for kas
MOUNTS=""
[ -d "$(realpath ~/.ssh/)" ]          && MOUNTS="$MOUNTS -v $(realpath ~/.ssh/):/home/${USER}/.ssh"
[ -d "$(realpath ~/.gnupg/)" ]        && MOUNTS="$MOUNTS -v $(realpath ~/.gnupg/):/home/${USER}/.gnupg"
[ -f "$(realpath ~/.gitconfig)" ]     && MOUNTS="$MOUNTS -v $(realpath ~/.gitconfig):/home/${USER}/.gitconfig"
# Pass SSH agent socket if available (for accessing private git repos)
[ -S "$(realpath ${SSH_AUTH_SOCK})" ] && MOUNTS="$MOUNTS -v $(realpath ${SSH_AUTH_SOCK}):/var/run/ssh-agent.socket"

# Setup environment variables
ENVIRONMENT_VARS=""
ENVIRONMENT_VARS="$ENVIRONMENT_VARS -e SSH_AUTH_SOCK=/var/run/ssh-agent.socket"

# Workspace mount
cd "$SH_DIR"
MOUNTS=" ${MOUNTS} -v .:/workspace"

# Container needs to run with special privileges/caps (required by isar)
PRIVILEGES="--privileged"

# Container needs to run with --init to handle process reaping
# (otherwise some tests fail, e.g. "ut-smoketest-zombie_handling" of ebcl-userland-utils)
INIT="--init"

# Directly drop to the mounted workspace
WORKDIR="--workdir /workspace"

# Change UID/GID of the developer user to match UID/GID of calling user to avoid file permission problems
REWRITE_UID="if ! getent group $(id -g) > /dev/null; then groupadd -g $(id -g) ${USER}; fi && usermod -u $(id -u) ${USER} > /dev/null && usermod -g $(id -g) ${USER} > /dev/null"

# Enable binfmt
ENABLE_BINFMT="/workspace/.devcontainer/setup_binfmt_support.sh"

# Escape command from argv
CMD=${@@Q}

${CONTAINER_ENGINE} run ${INIT} ${INTERACTIVE} ${MOUNTS} ${ENVIRONMENT_VARS} ${PRIVILEGES} ${WORKDIR} ${NAME} ${EXTRA_DOCKER_OPTIONS} ${CONTAINER_NAME} bash -c \
    "${REWRITE_UID} && ${ENABLE_BINFMT} && runuser -u ${USER} -- ${CMD}"
