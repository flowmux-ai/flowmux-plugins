---
name: flowmux-release
description: Prepare and publish a Flowmux release - choose the version, bump the workspace version, write the English and Korean release notes, and confirm the published artifacts. Use in the flowmux repository when asked to release, bump the version, or write release notes.
---

<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Flowmux release

Pushing a version bump to `main` publishes a release. The Version Tag
workflow sees the new `[workspace.package].version` in `Cargo.toml`, creates
the `vX.Y.Z` tag and dispatches the Release workflow. Do not create or push
the tag by hand.

## Before the bump

- Work on `main` with a clean tree.
- The Tests workflow must be green for the commit being released
  (`gh run list --branch main --workflow test.yml --limit 3`).
- List what changed: `git log vPREV..HEAD --oneline`.

## Choosing the version

Patch for fixes and small improvements; minor when the release adds a
user-visible feature. If the user did not name a version, recommend one with
the reason and let them confirm.

## Steps

1. Set `version` under `[workspace.package]` in `Cargo.toml`.
2. Run `cargo check` so `Cargo.lock` picks up the new workspace version.
3. Write `docs/releases/X.Y.Z.md` and `docs/releases/X.Y.Z.ko.md`. Copy the
   structure of the previous release's pair: SPDX comment, title, a one-line
   summary and "changes since vPREV", a link to the other language, sections
   grouped by area, and the changelog and source links at the end. Describe
   what a user notices, not the commits. The Release workflow uses the English
   file as the release body; without it the body is generated from commits.
4. Commit exactly those four files:
   `chore(release): bump version to X.Y.Z`. A release with a headline feature
   may use `chore(release): publish X.Y.Z with <highlight>`.
5. Confirm with the user, then push `main`.

## After the push

```sh
gh run list --workflow version-tag.yml --limit 1
gh run list --workflow release.yml --limit 1
gh run watch RUN_ID --exit-status
gh release view vX.Y.Z --json assets --jq '.assets[].name'
```

The release must contain the Linux tarball and `.deb`, the macOS `.dmg`, and
a `.sha256` file for each. The Release workflow runs the test suites again;
if it fails, fix the cause on `main` and re-dispatch it against the existing
tag with `gh workflow run release.yml --ref vX.Y.Z -f tag=vX.Y.Z`. Report the
release as published only after the assets are listed.
