# Copyright 2026 Elektrobit. All rights reserved.

# Common EBcLfSA image configuration shared across image types.
#
# This include provides the common system packages, EBcLfSA configuration
# packages, and apt options shared by LIVM and fastdev images.

# Use Crinit and Elos as foundation
# Both, crinit and elos get included as runtime dependency
IMAGE_INSTALL:append = " \
    crinit-ctl \
    crinit-sysv \
    elos-coredump \
    elos-plugin-backend-dlt \
    elos-plugin-backend-dummy \
    elos-plugin-backend-fetchapi \
    elos-plugin-backend-json \
    elos-plugin-backend-sql \
    elos-plugin-client-dummy \
    elos-plugin-client-tcp \
    elos-plugin-client-unix \
    elos-plugin-scanner-kmsg \
    elos-plugin-scanner-oomkiller \
    elos-plugin-scanner-shmem \
    elos-plugin-scanner-syslog \
"

# Common system packages
IMAGE_INSTALL:append = " \
    adduser \
    apt-utils \
    base-passwd \
    bash \
    bsdutils \
    ca-certificates \
    coreutils \
    diffutils \
    dmsetup \
    dpkg \
    e2fsprogs \
    file \
    findutils \
    gawk \
    gnupg \
    grep \
    hostname \
    iproute2 \
    iputils-ping \
    locales \
    login \
    mount \
    nano \
    ncurses-base \
    netbase \
    netifd \
    openssh-server \
    rsync \
    strace \
    sed \
    sudo \
    ucf \
    udhcpc \
"

# Common EBcLfSA configuration packages
IMAGE_INSTALL:append = " \
    ebclfsa-base-crinit-common \
    ebclfsa-base-crinit-setmachineid \
    ebclfsa-base-crinit-sshd \
    ebclfsa-base-elos-config \
    ebclfsa-base-machine-id \
    ebclfsa-base-sshd-root \
    ebclfsa-base-sudo-admin \
"

# Override pre-defined config files (like fstab)
ROOTFS_APT_ARGS:append = " -o Dpkg::Options::=--force-confnew"
