#!/usr/bin/env bash
# Copyright 2026 Elektrobit. All rights reserved.
# Create the kas-specific Git configuration used inside the container.

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/../lib/lib.sh"
dc_init_colors

DEST="/workspace/.devcontainer/kas.gitconfig"

# Only copy if the destination does not exist
if [ -f "$DEST" ]; then
    dc_info "KAS-specific Git config already exists at $DEST, skipping."
    dc_finish
    exit 0
fi

SRC="/home/developer/.gitconfig"

if [ ! -f "$SRC" ]; then
    dc_warn "No $SRC found, skipping."
    dc_finish
    exit 0
fi

cp "$SRC" "$DEST"

# Remove GPG commit signing settings that are incompatible with kas
git config --file "$DEST" --unset commit.gpgsign 2>/dev/null || true
git config --file "$DEST" --unset tag.gpgsign 2>/dev/null || true
git config --file "$DEST" --unset user.signingkey 2>/dev/null || true
git config --file "$DEST" --unset gpg.program 2>/dev/null || true
git config --file "$DEST" --unset gpg.format 2>/dev/null || true
git config --file "$DEST" --remove-section gpg 2>/dev/null || true
git config --file "$DEST" --remove-section gpg.ssh 2>/dev/null || true
git config --file "$DEST" --remove-section gpg.x509 2>/dev/null || true

dc_success "Copied $SRC to $DEST (GPG signing settings removed)."
dc_finish
