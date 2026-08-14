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

# Initialized variables
DEVICE="${DEF_DEVICE}"

# Uninitialized variables
IMAGE=""

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

$COMMON_ARGS

Example:
  $EXEC_NAME -i fastdev-trixie-ebclfsa-rpi4b.wic -d /dev/mmcblk0
USAGE
}

check_dependencies()
{
    local missing=()
    for tool in dd pv wc sudo blockdev numfmt; do
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

flash_image()
{
    bold "Flashing ${IMAGE} to ${DEVICE}..."
    dd if="${IMAGE}" | pv -s "${IMAGE_SIZE}" | \
        sudo dd of="${DEVICE}" bs=4M iflag=fullblock oflag=direct conv=fsync
    echo "Done."
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
confirm_flash
flash_image
