# Copyright 2026 Elektrobit. All rights reserved.

CARGO_REGISTRY_MIRROR ?= ""
# The variable CARGO_REGISTRIES_CI_MIRROR_TOKEN follows the pattern CARGO_REGISTRIES_<REGISTRY-NAME>_TOKEN, with the registry name being defined below as "ci-mirror". This way, the token is associated with the configured mirror.
SBUILD_PASSTHROUGH_ADDITIONS:append = " CARGO_REGISTRIES_CI_MIRROR_TOKEN"

do_prepare_build:append() {
    cargo_config="${S}/debian/cargo_home/config.toml"
    rm -f "$cargo_config"

    if [ -n "${CARGO_REGISTRY_MIRROR}" ]; then
        install -D -m0644 /dev/null "$cargo_config"
        printf '%s\n' \
            '[source.crates-io]' \
            'replace-with = "ci-mirror"' \
            '[registries.ci-mirror]' \
            "index = \"${CARGO_REGISTRY_MIRROR}\"" \
            'credential-provider = "cargo:token"' \
            > "$cargo_config"
    fi
}
