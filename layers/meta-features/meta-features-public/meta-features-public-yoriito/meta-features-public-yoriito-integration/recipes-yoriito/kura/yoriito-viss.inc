# Copyright 2026 Elektrobit. All rights reserved.

SRC_URI += "https://github.com/yoriito/yoriito-viss/archive/refs/tags/v${PV}.tar.gz;downloadfilename=yoriito-viss-${PV}.tar.gz;name=viss;subdir=kura-${PV}/external/yoriito-viss;striplevel=1"
SRC_URI[viss.sha256sum] = "6c1ae04d2046e0cce7ecfc8180ef522773e5a3c0c472ce5fa30eed9d66f0b3c2"
