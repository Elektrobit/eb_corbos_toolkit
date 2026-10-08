# Copyright 2026 Elektrobit. All rights reserved.

# Rebuild a kernel from its Debian source package (.dsc + .tar.gz).
#
# Usage in a recipe:
#   inherit kernel-dsc-rebuild
#   require recipes-kernel/linux-ebclfsa/linux-ebclfsa-<VARIANT>_<version>.src.inc
#   S = "${WORKDIR}/<unpacked-source-directory>"
#
# Optionally add patches via SRC_URI:
#   SRC_URI += "file://my-change.patch"

inherit dpkg_rebuild

def get_kernel_config_fragments(d):
    import os

    fragments = []
    for uri in (d.getVar("SRC_URI") or "").split():
        _, _, local, _, _, parm = bb.fetch.decodeurl(uri)
        if parm.get("apply") == "no":
            continue
        if os.path.splitext(os.path.basename(local))[1] == ".cfg":
            fragments.append(local)
    return " ".join(fragments)

def get_kernel_config_fragments_shell(d):
    return " ".join("debian/fragments/" + fragment
                    for fragment in get_kernel_config_fragments(d).split())

# linux-libc-dev sits deep in the toolchain chain (build-essential -> libc6-dev
# -> linux-libc-dev), so providing it from the kernel recipe creates a loop.
PROVIDES:remove = "linux-libc-dev linux-libc-dev-${DISTRO_ARCH}-cross"

# Enable the Debian build profiles that select which binary packages to produce
DEB_BUILD_PROFILES += "pkg.${BPN}.kernel pkg.${BPN}.cross pkg.${BPN}.nolibcdev"

# Runtime dependency not tracked in the .src.inc but required by linux-image-*
RDEPENDS:${PN} += "linux-base"

# Stage user-provided kernel configuration fragments where the Debian kernel
# build expects them, while preserving fragments from the source package.
do_prepare_build:append() {
    config_fragments="${@get_kernel_config_fragments_shell(d)}"
    if [ -n "${config_fragments}" ]; then
        if [ ! -f ${S}/debian/isar/configure ]; then
            bbwarn "${PN}: .cfg fragment(s) in SRC_URI will not be applied because the source package is not ISAR-based"
        else
            for frag in ${@get_kernel_config_fragments(d)}; do
                basedir=$(dirname ${frag})
                mkdir -p ${S}/debian/fragments/${basedir}
                cp ${WORKDIR}/${frag} ${S}/debian/fragments/${basedir}/
            done

            # Add the user-provided fragments to the Debian kernel configure command.
            if ! grep -q "dpkg_kernel_rebuild_fragments" ${S}/debian/isar/configure; then
                awk -v fragments="${config_fragments}" '
                    /^[[:space:]]*\.\/scripts\/kconfig\/merge_config\.sh/ {
                        in_merge = 1
                        print "        # dpkg_kernel_rebuild_fragments: " fragments
                    }
                    in_merge && $0 !~ /\\[[:space:]]*$/ {
                        sub(/[[:space:]]*$/, " " fragments)
                        in_merge = 0
                    }
                    { print }
                ' ${S}/debian/isar/configure > ${S}/debian/isar/configure.tmp
                mv ${S}/debian/isar/configure.tmp ${S}/debian/isar/configure
            fi
        fi
    fi
}
