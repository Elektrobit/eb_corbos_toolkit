# Copyright 2026 Elektrobit. All rights reserved.

# Convert dpkg names to bitbake recipe targets depending on the architecture
# of the build environment:
# - for HOST_ARCH, append -native to packages with :<hostarch> and without : specifier
#                  strip :<targetarch>
#                  warn for :<unknown>
# - for DISTRO_ARCH, strip :<targetarch> and keep without : specifier
#                    warn if :<hostarch> or :<unknown>
def isar_multiarch_recipes(var, destarch_var, d):
    packages = (d.getVar(var) or '').split()
    recipes = []
    destarch = d.getVar(destarch_var)
    hostarch = d.getVar('HOST_ARCH')
    distroarch = d.getVar('DISTRO_ARCH')

    for item in packages:
        pkg, _, arch = item.partition(":")
        if destarch == distroarch:
            if arch == '' or arch == distroarch:
                recipes.append(pkg)
            else:
                bb.warn("Package with unexpected architecture: %s" % item)
        elif destarch == hostarch:
            if arch == '' or arch == hostarch:
                recipes.append(pkg + "-native")
            elif arch == distroarch:
                recipes.append(pkg)
            else:
                bb.warn("Package with unexpected architecture: %s" % item)
        else:
            bb.fatal("Incompatible arch setting")

    return ' '.join(recipes)
