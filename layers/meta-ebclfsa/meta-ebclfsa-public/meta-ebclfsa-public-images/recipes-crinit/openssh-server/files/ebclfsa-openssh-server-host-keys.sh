#!/bin/sh -eu
# Copyright 2026 Elektrobit. All rights reserved.

# Generate SSH host keys if they have not already been generated. This is based
# off the postinst script from the openssh-server package.

create_key() {
    msg="$1"
    shift
    file="$1"
    shift

    if [ ! -f "${file}.pub" ] ; then
        printf %s "${msg}"
        rm -f "${file}"
        ssh-keygen -q -f "${file}" -N '' "$@"
        echo
        if command -v restorecon >/dev/null 2>&1; then
            restorecon "${file}" "${file}.pub"
        fi
        ssh-keygen -l -f "${file}.pub"
    fi
}

create_key "Creating SSH2 RSA key; this may take some time ..." \
    /etc/ssh/ssh_host_rsa_key -t rsa
create_key "Creating SSH2 ECDSA key; this may take some time ..." \
    /etc/ssh/ssh_host_ecdsa_key -t ecdsa
create_key "Creating SSH2 ED25519 key; this may take some time ..." \
    /etc/ssh/ssh_host_ed25519_key -t ed25519
