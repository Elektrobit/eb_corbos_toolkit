# Copyright 2026 Elektrobit. All rights reserved.

SRC_URI += "https://github.com/yoriito/yoriito-viss/archive/refs/tags/v${PV}.tar.gz;downloadfilename=yoriito-viss-${PV}.tar.gz;name=viss;subdir=kura-${PV}/external/yoriito-viss;striplevel=1"
SRC_URI[viss.sha256sum] = "21bc919a599e530838f74063fcdca4be167934bc01f45e63699f948d8a31973b"
