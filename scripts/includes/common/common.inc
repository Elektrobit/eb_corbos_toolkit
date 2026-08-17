# Copyright 2025 Elektrobit. All rights reserved.

VERBOSE=""

COMMON_ARGS=`cat <<EOF
General command-line options
  Option                   Help
  -v, --verbose            Verbose logging
  -h, --help               Print this message
EOF
`

COMMON_ARGS_CHECK_LIST=""

bold()
{
    echo -en "\033[1m"
    echo -en "$@"
    echo -en "\033[0m\n"
}

verbose()
{
    [ -z "${VERBOSE}" ] || echo "$@"
}

check_common_args()
{
    while [[ $# -gt 0 ]] ; do
        key="$1"
        case $key in
            -v|--verbose)
            VERBOSE=1
            shift
            ;;
            -h|--help)
            usage
            exit
            ;;
            *)
            echo "Argument $key unknown, ignoring."
            shift
            ;;
        esac
    done
}

wait_for_ssh() {
    local host="$1"
    local max_tries="$2"
    local probe_delay="$3"
    for i in $(seq 1 "$max_tries"); do
        if ssh "${host}" echo ok 2>&1; then
            echo "SSH connection to ${host} succeeded"
            return 0
        fi
        echo "Waiting for ssh connection to ${host}... ($i/$max_tries)"
        sleep ${probe_delay}
    done
    cat "${log}"
    echo "Error: Waiting for ssh connection to ${host} timed out!"
    exit 1
}
