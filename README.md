# flowmux-plugins

Development plugins for working on [Flowmux](https://github.com/flowmux-ai/flowmux).
These are for contributors and their coding agents. The skills that ship with
the Flowmux application live in the flowmux repository, not here.

## Plugins

### flowmux-dev

| Skill | Use |
|---|---|
| `flowmux-live-verify` | Check a runtime or UI change in an isolated Flowmux instance, without touching the one in use |
| `flowmux-ci-triage` | Run the local gate, watch GitHub Actions, and work a CI failure back to its cause |
| `flowmux-release` | Bump the version, write release notes, and confirm the published artifacts |

## Install

Claude Code:

```
/plugin marketplace add flowmux-ai/flowmux-plugins
/plugin install flowmux-dev@flowmux-plugins
```

Codex:

```sh
git clone https://github.com/flowmux-ai/flowmux-plugins
flowmux-plugins/scripts/install-codex.sh
```

The script links each skill into `~/.codex/skills`, so `git pull` updates them.

## Layout

```
.claude-plugin/marketplace.json     marketplace listing
plugins/flowmux-dev/
  .claude-plugin/plugin.json        plugin manifest
  skills/<skill>/SKILL.md           one directory per skill
scripts/install-codex.sh            Codex installer
```

Skills describe procedures and carry scripts. Project rules stay in the
flowmux repository's `CLAUDE.md`, `AGENTS.md` and `CONTRIBUTING.md`; link to
them instead of copying.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
