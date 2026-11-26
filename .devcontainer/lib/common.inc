# Copyright 2026 Elektrobit. All rights reserved.

# Common devcontainer variables
# CREDENTIALS_NETRC can be overridden, e.g. in CI where the .netrc lives in the home directory.
CREDENTIALS_NETRC="${CREDENTIALS_NETRC:-$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")/credentials.netrc}"
