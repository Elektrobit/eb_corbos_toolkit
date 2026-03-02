#!/usr/bin/env bash
set -euo pipefail

FULL_PATH=$(readlink -f $0)
EXEC_NAME=$(basename $FULL_PATH)
SH_DIR=${FULL_PATH%"$EXEC_NAME"}

CMD_PREFIX=""

BINFMT_ID="qemu-aarch64"
BINFMT_CFG="${SH_DIR}/binfmt-config/${BINFMT_ID}"
BINFMT_PROC="/proc/sys/fs/binfmt_misc"

function check_if_binfmt_available {
   if [ "$(ls ${BINFMT_PROC}/ | grep ${BINFMT_ID})" ]; then
      echo "true"
   else
      echo "false"
   fi
}

if [[ $EUID -ne 0 ]]; then
   CMD_PREFIX="sudo"
fi

if [ "$(uname -p)" != "aarch64" ]; then
   if [ ! "$(mount -l | grep binfmt)" ]; then
      echo "Mounting binfmt_misc to ${BINFMT_PROC}"
      $CMD_PREFIX mount binfmt_misc -t binfmt_misc ${BINFMT_PROC}
   fi

   if [ "$(check_if_binfmt_available)" == "true" ]; then
      echo "WARNING: Binfmt support for aarch64 already available!"
      echo "WARNING: Overwriting it with our own binary path. This may invalidate your host binfmt configuration."
      echo "WARNING: To revert our changes, reboot your system or run the following commands on your host after container shutdown:"
      echo "         $CMD_PREFIX update-binfmts --disable ${BINFMT_ID} && $CMD_PREFIX update-binfmts --enable ${BINFMT_ID}"
      $CMD_PREFIX update-binfmts --disable ${BINFMT_ID}
   fi

   $CMD_PREFIX update-binfmts --import ${BINFMT_CFG}

   if [ "$(check_if_binfmt_available)" == "true" ]; then
      echo "Binfmt support for aarch64 available!"
   else
      echo "Failed to setup binfmt support, aborting!"
      exit -1
   fi
else
   echo "Running natively on aarch64, skipping binfmt setup!"
fi
