# Copyright 2025 Elektrobit Automotive GmbH
# All rights reserved

DESCRIPTION = "Hello World application"
MAINTAINER = "Hello World maintainer"

inherit dpkg
require common_appdev.inc

# BitBake recipe dependencies
DEPENDS:append = "cmake"

# Build dependencies for the debian/control file
DEBIAN_BUILD_DEPENDS:append = "cmake"
