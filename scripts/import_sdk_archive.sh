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
FULL_DESTINATION=""

# Default values
DEF_DESTINATION=/workspace/sysroots

# Initialized variables
DESTINATION=${DEF_DESTINATION}

# Uninitialized variables
SDK_ARCHIVE=""
PURGE=""

usage()
{
  cat <<USAGE
Usage:
$EXEC_NAME -s/--sdk-archive sdk_archive.tar.gz [OPTIONS]
Tool-specific command-line options
  Option                    Help                                            Default
  -s, --sdk-archive ARCHIVE SDK archive to be imported
  -d, --destination FOLDER  Destination base folder of installed SDK        [ ${DEF_DESTINATION} ]
  -p, --purge               Purge existing SDK in destination folder

$COMMON_ARGS
USAGE
}

check_commandline_arguments() 
{
    [ -z "${SDK_ARCHIVE}" ] \
        && { echo "SDK archive mandatory, please specify via -s or --sdk-archive" ; exit 1; } \
        || true
    # Set FULL_DESTINATION based on DESTINATION and SDK_ARCHIVE
    FULL_DESTINATION=${DESTINATION}/"$(basename ${SDK_ARCHIVE} | cut -d . -f 1)"
    [[ -d ${FULL_DESTINATION}  &&  "$(ls -A ${FULL_DESTINATION})" && -z "${PURGE}" ]] \
        && { echo "-p/--purge not defined, SDK destination folder ${FULL_DESTINATION} must be either non-existing or empty" ; exit 1; } \
        || true
}

# Check commandline arguments
while [[ $# -gt 0 ]] ; do
  key="$1"
  case $key in
    -s|--sdk-archive)
    SDK_ARCHIVE=$2
    shift ; shift
    ;;
    -d|--destination)
    DESTINATION=$(realpath $2)
    shift ; shift
    ;;
    -p|--purge)
    PURGE=1
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

[ -d ${DESTINATION} ] || mkdir -p ${DESTINATION}

bold "Installing SDK archive ${SDK_ARCHIVE} to ${DESTINATION}"

# FULL_DESTINATION is set by check_commandline_arguments
[[ -d ${FULL_DESTINATION} && "${PURGE}" ]] \
  && { verbose "Cleaning existing SDK folder" ; rm -rf ${FULL_DESTINATION} ; } \
  || true

bold "Extracting archive"
tar --exclude="dev" -xzf ${SDK_ARCHIVE} -C ${DESTINATION}

bold "Relocate SDK"
verbose "Invoking SDK provided relocation script ${FULL_DESTINATION}/relocate-sdk.sh"
${FULL_DESTINATION}/relocate-sdk.sh

bold " Remove obsolete files"
rm ${FULL_DESTINATION}/README.sdk

bold "SDK import done. New SDK now available at ${FULL_DESTINATION}"
