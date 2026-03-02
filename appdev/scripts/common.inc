# Copyright 2025 Elektrobit Automotive GmbH
# All rights reserved

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
