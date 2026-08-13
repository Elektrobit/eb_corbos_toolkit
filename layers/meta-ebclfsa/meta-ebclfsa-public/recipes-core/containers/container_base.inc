# Copyright 2026 Elektrobit. All rights reserved.

inherit ebclfsa_devcontainer

# Just a placeholder, the container name shall contain the real registry path (could also be ghcr.io)
CONTAINER_IMAGE_NAME = "ghcr.io/elektrobit/eb-corbos-toolkit-devcontainer-amd64:RFI_EBLINUX-30057--"
CONTAINER_IMAGE_TAG = "local"
CONTAINER_IMAGE_CMD = "/bin/bash"

# Common set of packages, required to build a target image with kas.
IMAGE_INSTALL = " \
    apt-utils \
    arch-test  \
    base-files \
    base-passwd \
    bash \
    binfmt-support \
    bubblewrap \
    buildcontainer-config \
    ca-certificates \
    checkpolicy \
    coreutils \
    cpio \
    cryptsetup \
    curl \
    diffutils \
    file \
    findutils \
    git \
    git-lfs \
    hostname \
    init \
    iproute2 \
    kas \
    kmod \
    libpam-runtime \
    locales \
    mmdebstrap \
    mount \
    openssh-client \
    policycoreutils \
    python3 \
    python3-jinja2 \
    python3-cairo \
    qemu-user-static \
    quilt \
    reprepro \
    rsync \
    sbuild \
    schroot \
    sed \
    skopeo \
    sudo \
    umoci \
    wget \
"
