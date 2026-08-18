# Copyright 2026 Elektrobit. All rights reserved.

SUPPORTED_TARGETS+=(fastdev)
SUPPORTED_TARGETS+=(myfastdev)

CONFIGURE_CMD=`cat <<EOF
${CONFIGURE_CMD}
    case "\\\${TARGET}" in
        fastdev|myfastdev)
        # Kernel location
        KERNEL="\\\${DEPLOY_DIR}/\\\${TARGET}-trixie-\\\${DISTRO}-ebcl-qemuarm64-vmlinux"
        # Kernel arguments
        KERNEL_ARGS=("-append" "root=/dev/vda1 sdk_enable lisa_syscall_whitelist=2026 rw sharedmem.enable_sharedmem=0 init=/usr/bin/ebclfsa-cflinit")
        # Forward SSH and GDB ports
        NETWORK_ARGS="\\\${NETWORK_ARGS},hostfwd=tcp::10022-:22,hostfwd=tcp::3333-:3333"
        # Graphics: virtio-gpu + input devices (only used when --display is not nographic)
        # virtio-tablet-pci provides absolute positioning (fixes dual-cursor in VNC)
        GRAPHICS_ARGS="-device virtio-gpu-pci -device virtio-keyboard-pci -device virtio-tablet-pci"
        ;;
    esac
EOF
`
