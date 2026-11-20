---
name: flowmux-live-verify
description: Verify a Flowmux runtime or UI change in a running, isolated Flowmux instance, or build and launch one for the user to look at. Use in the flowmux repository after changing GUI, pane, tab, terminal, browser, IPC, session or agent-runtime behavior, and whenever asked to build and run Flowmux. Not needed for documentation or logic fully covered by unit tests.
---

<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Flowmux live verification

`AGENTS.md` requires that a runtime or UI fix is reproduced in a running
Flowmux before it is reported as done. This skill is the procedure.

## The one hard rule

The user is usually working inside Flowmux while you run. Never close,
restart or signal that instance, and never stop a process by name
(`pkill flowmux`, `killall`). Stop only the PID you started, through the
script below.

## Procedure

Run from the flowmux repository root.

1. Build what you changed: `cargo build --workspace`.
2. Start an isolated instance:

   ```sh
   /path/to/flowmux-live-verify/scripts/fm-isolated.sh start
   ```

   The script sits in `scripts/` next to this file. It prints `ROOT`, `PID` and `SOCKET`. State, config, cache and the runtime
   directory live under `ROOT` in `/tmp`; the caller's `FLOWMUX_*` and agent
   identity variables are not inherited. Pass another binary as the second
   argument to check an installed bundle or a release build.
3. Drive it through its own socket only:

   ```sh
   FLOWMUX_SOCKET_PATH=$SOCKET target/debug/flowmuxctl --json tree
   ```

   The socket answers before the first workspace exists. Poll `tree` until
   the workspace you need is present instead of sleeping.
4. Reproduce the same scenario that failed, in the same order, and check the
   state the user would see: `tree`, `read-screen`, `agents`, browser
   `snapshot`, or a screenshot. A passing unit test is not this check.
5. For agent-runtime changes check both directions: the status must not
   report completion early, and must not stay on working after the turn ends.
6. Stop it: `fm-isolated.sh stop "$ROOT"`. `ROOT` is kept, including
   `gui.log`, as evidence; remove it when the result has been reported.

When the user wants to look at the build themselves, leave the instance
running, report `ROOT` and `PID`, and stop it once they are done.

## Tests that need the same isolation

For `cargo test` targets or scripts that start their own GUI:

```sh
eval "$(fm-isolated.sh env)"   # exports the isolated paths, sets FM_ISOLATED_ROOT
```

On macOS, GTK tests that need AppKit must use the native main-thread harness
(`cargo test -p flowmux --test macos_native --features native-smoke`).

## Reporting

State what was reproduced, what was observed, and where the evidence is. If
live verification was not possible, name the exact blocker instead of
reporting the fix as verified.
