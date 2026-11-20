#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Link this repository's skills into Codex, which has no plugin marketplace
# for them. Re-run after adding a skill; edits to existing skills need no re-run.
set -euo pipefail
source_dir="$(cd "$(dirname "$0")/.." && pwd)/plugins/flowmux-dev/skills"
target="${CODEX_HOME:-$HOME/.codex}/skills"
mkdir -p "$target"
for skill in "$source_dir"/*/; do
    name=$(basename "$skill")
    if [[ -e $target/$name && ! -L $target/$name ]]; then
        echo "skipped $name: $target/$name exists and is not a link" >&2
        continue
    fi
    ln -sfn "${skill%/}" "$target/$name"
    echo "linked $name"
done
