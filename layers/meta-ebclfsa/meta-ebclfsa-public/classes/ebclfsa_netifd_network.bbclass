# Copyright 2026 Elektrobit. All rights reserved.

# Common class for netifd UCI network configuration recipes.
# Generates /etc/config/network from a template.
# Always creates a br0 bridge for consistent upstream interface naming.
#
# Required variables:
#   NETIFD_IPADDR       - IP address with CIDR prefix (e.g. "192.168.7.2/24")
#   NETIFD_GATEWAY      - Gateway address (e.g. "192.168.7.1")
#
# Optional variables:
#   NETIFD_DNS          - Space-separated list of DNS servers (default: "8.8.8.8")
#   NETIFD_BRIDGE_PORTS - Space-separated list of bridge ports (default: "eth0")
#   NETIFD_MAIN_DEVICE  - Bridge device name (default: "br0")

LICENSE = "CLOSED"

inherit dpkg-raw
# nooelint: oelint.vars.bbvars.INHERIT::Variable - file moved in external layer
INHERIT += "template"

MAINTAINER = "Elektrobit <info@elektrobit.com>"

NETIFD_IPADDR ?= ""
NETIFD_GATEWAY ?= ""
NETIFD_DNS ?= "8.8.8.8"
NETIFD_BRIDGE_PORTS ?= "eth0"
NETIFD_MAIN_DEVICE ?= "br0"

# Generate multi-line entries for bridge ports and DNS
# chr(10) avoids BitBake escaping literal '\n' in inline Python
NETIFD_BRIDGE_PORTS_LIST = "${@chr(10).join('    list ports  ' + p for p in d.getVar('NETIFD_BRIDGE_PORTS').split())}"
NETIFD_DNS_LIST = "${@chr(10).join('    list dns        ' + s for s in d.getVar('NETIFD_DNS').split())}"

FILESEXTRAPATHS:prepend := "${LAYERDIR_meta-ebclfsa-public}/common/ebclfsa_netifd_network:"

SRC_URI = " \
    file://network.tmpl \
"

TEMPLATE_FILES = " \
    network.tmpl \
"

TEMPLATE_VARS = " \
    NETIFD_IPADDR \
    NETIFD_GATEWAY \
    NETIFD_MAIN_DEVICE \
    NETIFD_BRIDGE_PORTS_LIST \
    NETIFD_DNS_LIST \
"

DEBIAN_RULES_REQUIRES_ROOT = "no"

do_install() {
    install -Dm0644 ${WORKDIR}/network -t ${D}/etc/config
}
