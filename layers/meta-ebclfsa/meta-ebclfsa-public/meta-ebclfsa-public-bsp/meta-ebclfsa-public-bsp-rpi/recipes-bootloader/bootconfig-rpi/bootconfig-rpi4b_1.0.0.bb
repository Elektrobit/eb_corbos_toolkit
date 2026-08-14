#
# Copyright 2026 Elektrobit. All rights reserved.

DESCRIPTION = "Boot configuration for the Raspberry Pi 4B platform"
MAINTAINER = "Elektrobit <info@elektrobit.com>"

SRC_URI = "file://config.txt \
           file://cmdline.txt.tmpl"

inherit dpkg-raw

COMPATIBLE_MACHINE = "^(rpi4b)$"

TEMPLATE_VARS = "MACHINE_SERIAL BAUDRATE_TTY EBCLFSA_LIVM_DEV"
TEMPLATE_FILES = "cmdline.txt.tmpl"

PN = "bootconfig-${MACHINE}"

do_install() {
    install -v -d ${D}/boot/
    install -v -m 644 ${WORKDIR}/config.txt ${D}/boot/
    install -v -m 644 ${WORKDIR}/cmdline.txt ${D}/boot/
}
