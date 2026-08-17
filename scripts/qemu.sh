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
QEMU_SH_INCLUDES=$(realpath ${SH_DIR}/includes/qemu)
SUPPORTED_TARGETS=()
CONFIGURE_CMD=""

# Default values
DEF_MACHINE="virt,virtualization=true,gic-version=3"
DEF_CPU="cortex-a53"
DEF_SMP="4"
DEF_MEM="2G"
DEF_DEPLOY_DIR="/workspace/build/tmp/deploy/images/ebcl-qemuarm64"
DEF_DISTRO="ebclfsa"
DEF_DISPLAY_MODE="nographic"

# Initialized variables
MACHINE="${DEF_MACHINE}"
CPU="${DEF_CPU}"
SMP="${DEF_SMP}"
MEM="${DEF_MEM}"
DEPLOY_DIR="${DEF_DEPLOY_DIR}"
DISTRO="${DEF_DISTRO}"

# Uninitialized variables
TARGET=""
DISPLAY_MODE="${DEF_DISPLAY_MODE}"

# Qemu variables
NETWORK_ARGS="-device virtio-net-device,netdev=net0 -netdev user,id=net0,net=192.168.7.0/24,dhcpstart=192.168.7.2,host=192.168.7.1"
INITRD=""
KERNEL=""
declare -g -a KERNEL_ARGS

# Source delivery-specific configuration if available
for VARIANT in "${QEMU_SH_INCLUDES}"/*; do
    verbose "Loading QEMU configuration from ${VARIANT}"
    source "${VARIANT}"
done

usage()
{
  cat <<USAGE
Usage:
$EXEC_NAME -t/--target <TARGET> [OPTIONS]
Tool-specific command-line options
  Option                    Help                                            Default
  -t/--target <TARGET>      Target to boot (${SUPPORTED_TARGETS[*]})
  -m/--machine <MACHINE>    QEMU machine type                               [ $DEF_MACHINE ]
  -c/--cpu <CPU>            QEMU CPU model                                  [ $DEF_CPU ]
  -s/--smp <SMP>            Number of CPUs                                  [ $DEF_SMP ]
  --mem <MEM>               Memory size                                     [ $DEF_MEM ]
  -d/--deploy-dir <DIR>     Deploy directory                                [ $DEF_DEPLOY_DIR ]
  --display <MODE>          Display mode: nographic, vnc, gtk, sdl, none    [ $DEF_DISPLAY_MODE ]

$COMMON_ARGS
USAGE
}

check_commandline_arguments()
{
    [ -z "${TARGET}" ] \
        && { echo "Target is mandatory, please specify via -t or --target" ; exit 1; } \
        || true
}

configure_target()
{
    verbose "${CONFIGURE_CMD}"
    eval "${CONFIGURE_CMD}"

    DISK_ARGS="-device virtio-blk-device,drive=vd0 -drive if=none,format=raw,file=${DEPLOY_DIR}/${TARGET}-trixie-${DISTRO}-ebcl-qemuarm64.wic,id=vd0"

}

boot_qemu()
{
    bold "Booting ${TARGET}..."
    verbose "  MACHINE=${MACHINE}"
    verbose "  CPU=${CPU}"
    verbose "  SMP=${SMP}"
    verbose "  MEM=${MEM}"
    verbose "  KERNEL=${KERNEL}"
    verbose "  KERNEL_ARGS=${KERNEL_ARGS[*]:-}"
    verbose "  DISK_ARGS=${DISK_ARGS}"
    verbose "  NETWORK_ARGS=${NETWORK_ARGS}"
    verbose "  EXTRA_ARGS=${EXTRA_ARGS:-}"

    local display_args
    local graphics_args=""
    case "${DISPLAY_MODE}" in
        nographic)  display_args="-nographic" ;;
        vnc)        display_args="-display vnc=:0 -serial mon:stdio"
                    graphics_args="${GRAPHICS_ARGS:-}" ;;
        gtk)        display_args="-display gtk -serial mon:stdio"
                    graphics_args="${GRAPHICS_ARGS:-}" ;;
        sdl)        display_args="-display sdl -serial mon:stdio"
                    graphics_args="${GRAPHICS_ARGS:-}" ;;
        none)       display_args="-display none -serial mon:stdio" ;;
        *)          echo "Unknown display mode: ${DISPLAY_MODE}"; exit 1 ;;
    esac
    verbose "  DISPLAY_MODE=${DISPLAY_MODE}"
    verbose "  GRAPHICS_ARGS=${graphics_args}"

    local qemu_cmd="${QEMU_CMD:-qemu-system-aarch64}"
    exec ${qemu_cmd} -m "${MEM}" -machine "${MACHINE}" -cpu "${CPU}" \
        -smp "${SMP}" -kernel "${KERNEL}" ${INITRD} "${KERNEL_ARGS[@]}" ${DISK_ARGS} \
        ${NETWORK_ARGS} ${EXTRA_ARGS:-} ${graphics_args} ${display_args}
}

# Check commandline arguments
while [[ $# -gt 0 ]] ; do
    key="$1"
    case $key in
    -t|--target)
    if (printf '%s\n' "${SUPPORTED_TARGETS[@]}" | grep -xq "$2"); then
        TARGET=$2
    else
        echo "Target $2 not supported!"
        echo "Supported targets are: "
        printf '   %s\n' "${SUPPORTED_TARGETS[@]}"
        exit 1
    fi
    shift ; shift
    ;;
    -m|--machine)
    MACHINE=$2
    shift ; shift
    ;;
    -c|--cpu)
    CPU=$2
    shift ; shift
    ;;
    -s|--smp)
    SMP=$2
    shift ; shift
    ;;
    --mem)
    MEM=$2
    shift ; shift
    ;;
    -d|--deploy-dir)
    DEPLOY_DIR=$2
    shift ; shift
    ;;
    --display)
    DISPLAY_MODE=$2
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

check_commandline_arguments
configure_target
boot_qemu
