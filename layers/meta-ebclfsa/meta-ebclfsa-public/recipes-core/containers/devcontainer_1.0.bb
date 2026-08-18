# Copyright 2026 Elektrobit. All rights reserved.

DESCRIPTION = "Development container"
LICENSE = "CLOSED"

# This container acts as the main entrypoint and tool collection during development.
# It builds on top of the minimalistic buildcontainer. Beside the capability for
# image building, it also allows to export toolchains and integrates other useful
# tools.

require container_base.inc

# Additional packages which are required for development activies such as linting tools,
# simple console editors, our reposync tool, ...
# In contrast to the buildcontainer, a properly configured apt environment is available,
# allowing additional tools to be installed during the container lifecycle. Be aware this
# is only for testing and development. To make those additional tools persistently
# available as part of the container, you need to append them to the IMAGE_INSTALL list
# below.
IMAGE_INSTALL:append = " \
    apt-repo-config \
    cmake \
    ebcl-reposync \
    gdb-multiarch \
    iputils-ping \
    less \
    nano \
    ncurses-base \
    ncurses-bin \
    oelint-adv \
    opengrep \
    patchelf \
    procps \
    python3-pip \
    qemu-system-arm \
    sshpass \
    tmux \
    vim \
    pv \
"
