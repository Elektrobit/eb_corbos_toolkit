#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.

set -e

# Determine script location
FULL_PATH=$(readlink -f $0)
EXEC_NAME=$(basename $FULL_PATH)
SH_DIR=${FULL_PATH%"$EXEC_NAME"}

# Source common.inc to get common variables and functions
source ${SH_DIR}/includes/common/common.inc

# Default values
DEF_DEVICE="/dev/mmcblk0"
DEF_COMPARE="yes"

# Initialized variables
DEVICE="${DEF_DEVICE}"
COMPARE="${DEF_COMPARE}"

# Uninitialized variables
IMAGE=""
BMAP=""
USE_BMAP="no"

usage()
{
  cat <<USAGE
Usage:
$EXEC_NAME -i/--image <IMAGE> [OPTIONS]
Flash an image file to an SD card (or other block device).

Tool-specific command-line options
  Option                    Help                                            Default
  -i/--image <IMAGE>        Path to the wic/image file to flash (required)
  -d/--device <DEVICE>      Target block device                             [ $DEF_DEVICE ]
  -n/--no-compare           Skip verifying the written image against source  [ compare: $DEF_COMPARE ]

$COMMON_ARGS

If 'bmaptool' is installed and a '<IMAGE>.bmap' file exists next to the image,
it is used to flash only mapped blocks (verification is done by bmaptool).

Example:
  $EXEC_NAME -i fastdev-trixie-ebclfsa-rpi4b.wic -d /dev/mmcblk0
USAGE
}

check_dependencies()
{
    local missing=()
    for tool in dd pv wc sudo blockdev numfmt cmp lsblk umount findmnt; do
        if ! command -v "${tool}" > /dev/null 2>&1; then
            missing+=("${tool}")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: missing required tool(s): ${missing[*]}"
        exit 1
    fi
}

check_commandline_arguments()
{
    [ -z "${IMAGE}" ] \
        && { echo "Error: no image file specified." ; usage ; exit 1; } \
        || true
    [ -f "${IMAGE}" ] \
        || { echo "Error: image file '${IMAGE}' does not exist or is not a regular file." ; exit 1; }
    [ -b "${DEVICE}" ] \
        || { echo "Error: target device '${DEVICE}' does not exist or is not a block device." ; exit 1; }
}

human_size()
{
    numfmt --to=iec --suffix=B "$1"
}

check_image_fits()
{
    IMAGE_SIZE="$(wc -c < "${IMAGE}")"
    DEVICE_SIZE="$(sudo blockdev --getsize64 "${DEVICE}")"

    if [[ "${IMAGE_SIZE}" -gt "${DEVICE_SIZE}" ]]; then
        echo "Error: image ($(human_size "${IMAGE_SIZE}")) is larger than target device '${DEVICE}' ($(human_size "${DEVICE_SIZE}"))."
        exit 1
    fi
}

check_bmap()
{
    BMAP="${IMAGE}.bmap"
    if command -v bmaptool > /dev/null 2>&1 && [[ -f "${BMAP}" ]]; then
        USE_BMAP="yes"
        echo "Using bmaptool with block map '${BMAP}'."
    fi
}

confirm_flash()
{
    echo "About to flash:"
    echo "  Input  (image) : ${IMAGE} ($(human_size "${IMAGE_SIZE}"))"
    echo "  Output (device): ${DEVICE} ($(human_size "${DEVICE_SIZE}"))"
    echo
    echo "WARNING: ALL DATA ON ${DEVICE} WILL BE DESTROYED!"
    read -r -p "Proceed? [y/N] " answer
    case "${answer}" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "Aborted."; exit 0 ;;
    esac
}

unmount_device()
{
    # bmaptool opens the device with O_EXCL, so the device and any mounted
    # partition must be free; dd benefits from this too to avoid a stale mount.
    local dev
    for dev in $(lsblk -nro PATH "${DEVICE}"); do
        if mountpoint -q "${dev}" 2>/dev/null || findmnt -nrS "${dev}" > /dev/null 2>&1; then
            echo "Unmounting ${dev}..."
            sudo umount "${dev}" 2>/dev/null || sudo umount -l "${dev}"
        fi
    done
    # Let udev finish any re-scan that could keep the device busy
    sudo udevadm settle 2>/dev/null || true
}

device_busy_hint()
{
    cat >&2 <<HINT

Error: could not get exclusive access to '${DEVICE}' (device is busy).
This script tried to unmount it, but if you are running inside a container the
host's mounts are not visible here, so they cannot be unmounted from within.

If '${DEVICE}' is mounted on the host (e.g. auto-mounted after inserting the
card), unmount it there before flashing, for example on the host run:

  for p in ${DEVICE}*; do sudo umount "\$p" 2>/dev/null; done

Then re-run this script.
HINT
}

flash_image()
{
    local rc=0
    if [[ "${USE_BMAP}" == "yes" ]]; then
        bold "Flashing ${IMAGE} to ${DEVICE} using bmaptool..."
        sudo bmaptool copy --bmap "${BMAP}" "${IMAGE}" "${DEVICE}" || rc=$?
    else
        bold "Flashing ${IMAGE} to ${DEVICE} using dd..."
        { dd if="${IMAGE}" | pv -s "${IMAGE_SIZE}" | \
            sudo dd of="${DEVICE}" bs=4M iflag=fullblock oflag=direct conv=fsync; } || rc=$?
    fi
    if [[ ${rc} -ne 0 ]]; then
        device_busy_hint
        exit "${rc}"
    fi
    echo "Done."
}

compare_image()
{
    bold "Verifying ${DEVICE} against ${IMAGE}..."
    # Drop caches so the device is read back from hardware, not from memory
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1 || true
    # Compare only the first IMAGE_SIZE bytes, since the device is usually larger
    if pv -s "${IMAGE_SIZE}" "${IMAGE}" | \
        sudo cmp -s -n "${IMAGE_SIZE}" - "${DEVICE}"; then
        echo "Verification succeeded: ${DEVICE} matches ${IMAGE}."
    else
        echo "Error: verification failed, ${DEVICE} does not match ${IMAGE}."
        exit 1
    fi
}

# Check commandline arguments
while [[ $# -gt 0 ]] ; do
    key="$1"
    case $key in
    -i|--image)
    IMAGE=$2
    shift ; shift
    ;;
    -d|--device)
    DEVICE=$2
    shift ; shift
    ;;
    -n|--no-compare)
    COMPARE="no"
    shift
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
check_dependencies
check_image_fits
check_bmap
confirm_flash
unmount_device
flash_image

# bmaptool verifies the written data itself, so only compare on the dd path
if [[ "${COMPARE}" == "yes" && "${USE_BMAP}" != "yes" ]]; then
    compare_image
fi
