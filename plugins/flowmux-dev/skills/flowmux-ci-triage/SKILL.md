---
name: flowmux-ci-triage
description: Run the Flowmux local test gate, watch GitHub Actions runs for the flowmux repository, and work a CI failure back to its cause and fix. Use when asked to check CI, when a pushed commit fails CI, before pushing a non-trivial change, or when a test is flaky or slow.
---

<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Flowmux CI triage

## Local gate

```sh
bash scripts/test-ci.sh macos            # on macOS
bash scripts/test-ci.sh linux            # on Linux
bash scripts/test-ci.sh <os> extended    # required for agent-runtime changes
```

Run the whole gate by default. A third argument selects one group; use it to
re-check a group that failed, not to skip the rest. The valid group names
change often, so read them from the `case` block at the top of
`scripts/test-ci.sh` rather than from memory.

The gate isolates its own state. Output goes to `target/ci/<os>/run.log`, the
last line reports `CI_GATE_EXIT=`, and a failing run keeps its files under
`target/ci/<os>/failure-*`. On Linux, when launched from a coding agent, run
the gate in its own systemd user service as described in
`.github/CONTRIBUTING.md`.

## Watching a run

```sh
gh run list --branch "$(git branch --show-current)" --limit 5
gh run watch RUN_ID --exit-status          # run in the background
gh run view RUN_ID --json jobs --jq '.jobs[] | [.name, .conclusion] | @tsv'
gh run view RUN_ID --log-failed
gh run download RUN_ID --pattern '*-test-evidence-*'
```

The Tests workflow runs on pull requests and on pushes to `main`; a push to
`main` that only touches `README.md` or `docs/` (other than `docs/legal/`)
does not start it. A branch without a pull request needs a manual run:

```sh
gh workflow run test.yml --ref BRANCH -f platform=all   # or linux, macos
```

## Working a failure

1. Read the failed job's log and evidence artifact before forming a theory.
2. Find the range: the last green run's `headSha` to the failing one, then
   `git log GREEN..RED --oneline`. Identify the commit, not just the test.
3. Reproduce with the same group locally. If it only fails in CI, say so and
   use the evidence artifact; do not guess.
4. Decide which it is, and say so in the commit:
   - product regression: fix the product, keep the test;
   - test defect: fix the test;
   - runner or dependency problem: fix the workflow.
5. Push, watch the new run, and report its real result. A run that is still
   in progress is not a pass.

## Fixing tests

CI runners are slow. Defaults, unless the user decides otherwise:

- Wait for the condition the test depends on; do not add or lengthen a fixed
  delay, and do not raise a phase budget as the first response.
- Keep fixtures small. Do not make a test pass by sending more data or
  running longer.
- If a test's timing cannot be made deterministic, replace it with a narrower
  deterministic check, or remove it when a broader test already covers the
  behavior. Name the covering test in the commit message.
- Before adding a GUI test, check that no broader test already exercises the
  path, reuse `Harness` from `scripts/test-ssh-workspace-gui.py`, and register
  the script in a group in `scripts/test-ci.sh`.
- The groups run in parallel to keep the whole run short. A fix should not
  make any one group noticeably longer.

Make one commit per cause. Push only when the user asked for it.
