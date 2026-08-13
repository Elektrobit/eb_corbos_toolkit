# Copyright 2026 Elektrobit. All rights reserved.

DESCRIPTION = "Minimalistic build container"
LICENSE = "CLOSED"

# This container only provides the capability to build images with kas and bitbake.
# All other functionality is stripped.

require container_base.inc

# Strip unnecessary systemd.
# The content of this container shall not be changed during its lifecycle.
UNWANTED_PKGS:append = " \
    systemd \
    systemd-dev \
"
