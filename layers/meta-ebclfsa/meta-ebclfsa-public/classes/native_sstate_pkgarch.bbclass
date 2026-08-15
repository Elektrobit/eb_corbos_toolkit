# Copyright 2026 Elektrobit. All rights reserved.

# Fix sstate cache misses for -native recipes caused by an inconsistent
# SSTATE_PKGARCH.
#
# ISAR's sstate.bbclass sets the sstate arch for native variants with:
#     d.setVar('SSTATE_PKGARCH', d.getVar('BUILD_ARCH', False))
# BUILD_ARCH is not resolved yet when that anonymous function runs, so
# SSTATE_PKGARCH ends up unset in the -native recipe's datastore. As a result:
#   * the sstate object is *stored* with an empty arch field, e.g.
#         sstate:<pn>-native:amd64-isar:<pv>:r0::10:<hash>_dpkg_build.tar.zst
#   * sstate_checkhashes *looks it up* by re-expanding the (unbaked)
#     ${SSTATE_PKGARCH} token against the global datastore, where it resolves to
#     ${PACKAGE_ARCH} = the machine arch (e.g. arm64), i.e.
#         sstate:<pn>-native:amd64-isar:<pv>:r0:arm64:10:<hash>_dpkg_build.tar.zst
#
# The stored and looked-up names never match, so every -native recipe is
# rebuilt on every run instead of being restored from local or mirror sstate
# (target/arm64 recipes are unaffected because their SSTATE_PKGARCH is the
# machine arch in both contexts).
#
# Give BUILD_ARCH a parse-time default so it is already set when
# sstate.bbclass's anonymous function reads it, yielding a non-empty
# SSTATE_PKGARCH.
#
# IMPORTANT: sstate.bbclass reads BUILD_ARCH with expand=False, so
# SSTATE_PKGARCH holds the *literal* token "${HOST_ARCH}", not an expanded
# value. That is exactly what makes the fix work: HOST_ARCH is set globally
# and immediately (':=') in isar's base.bbclass, so the token expands to the
# same value in the recipe datastore (where the object is stored) and in the
# global datastore (where sstate_checkhashes looks it up). Do not "simplify"
# this to an expanded value - the two contexts would diverge again.
#
# Weak assignment so any real BUILD_ARCH (e.g. from crossvars.bbclass) wins.
BUILD_ARCH ?= "${HOST_ARCH}"
