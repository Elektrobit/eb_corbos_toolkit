# Copyright 2026 Elektrobit. All rights reserved.

SUMMARY = "Network configuration files for EBcLfSA fastdev images"

inherit ebclfsa_netifd_network

NETIFD_IPADDR = "192.168.7.2/24"
NETIFD_GATEWAY = "192.168.7.1"
NETIFD_BRIDGE_PORTS = "eth0"
