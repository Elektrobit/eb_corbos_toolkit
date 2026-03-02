#!/bin/bash -eu
# Copyright 2025 Elektrobit Automotive GmbH
# All rights reserved

MACHINE="virt,virtualization=true,gic-version=3"
CPU="cortex-a53"
SMP="4"
MEM="2G"
TARGET="${1:-fastdev}"
DEPLOY_DIR="${DEPLOY_DIR:-build/tmp/deploy/images/ebcl-qemuarm64}"
INITRD=""
DISTRO="ebclfsa"
declare -a KERNEL_ARGS
NETWORK_ARGS="-device virtio-net-device,netdev=net0 -netdev user,id=net0,net=192.168.7.0/24,dhcpstart=192.168.7.2,dns=192.168.7.3,host=192.168.7.5"

if ! command -v qemu-system-aarch64 > /dev/null; then
    echo "Please install qemu-system-aarch64"
    exit 1
fi

case "${TARGET}" in
    fastdev)
    KERNEL_ARGS=("-append" "root=/dev/vda1 sdk_enable lisa_syscall_whitelist=2026 rw sharedmem.enable_sharedmem=0 init=/usr/bin/ebclfsa-cflinit")
    DISTRO="ebclfsa"
    # Forward SSH and GDB ports
    NETWORK_ARGS="${NETWORK_ARGS},hostfwd=tcp::10022-:22,hostfwd=tcp::3333-:3333"
    ;;
    *)
    echo "Usage: $(basename ${0}) [fastdev]"
    echo "Starts fastdev by default."
    exit 1
    ;;
esac

DISK_ARGS="-device virtio-blk-device,drive=vd0 -drive if=none,format=raw,file=${DEPLOY_DIR}/${TARGET}-ubuntu-${DISTRO}-ebcl-qemuarm64.wic,id=vd0"

if [ -z "${KERNEL:-}" ]; then
    KERNEL="${DEPLOY_DIR}/${TARGET}-ubuntu-${DISTRO}-ebcl-qemuarm64-vmlinux"
fi

echo "Booting ${TARGET}..."

exec qemu-system-aarch64 -m "${MEM}" -machine "${MACHINE}" -cpu "${CPU}" \
    -smp "${SMP}" -kernel "${KERNEL}" ${INITRD} "${KERNEL_ARGS[@]}" ${DISK_ARGS} \
    ${NETWORK_ARGS} -nographic
