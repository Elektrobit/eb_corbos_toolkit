# Copyright 2025 Elektrobit Automotive GmbH
# All rights reserved

case "$PRESET" in
  "fastdev-li-qemuarm64"|"fastdev-hi-qemuarm64")
    TARGET_IP=127.0.0.1
    SSH_PORT=10022
    SSH_USER=root
    SSH_PREFIX="sshpass -p linux"
    GDB_PORT=3333
    ;;
  *)
    echo "Target for preset \"$PRESET\" not supported!"
    exit -1
esac

is_ipv6_address() {
  [[ $1 =~ ^([0-9a-fA-F]{0,4}:){0,7}[0-9a-fA-F]{1,4}$ ]]
}

GDB_SERVER_INTERFACE="[::]"

# In case of an IPv6 connection towards the target,
# we must use [] around the target IP address

is_ipv6_address $TARGET_IP && GDB_TARGET_IP="[$TARGET_IP]" || GDB_TARGET_IP="$TARGET_IP"
