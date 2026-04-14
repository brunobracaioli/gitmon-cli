# Contributing to gitmon-cli

Thanks for wanting to help!

## This repo is a build artifact

`gitmon-cli` is generated from the private GitMon codebase by
`scripts/extract-cli.sh`. Edits made directly to this repo are
**overwritten** on the next upstream sync — so please do not PR
against this repo without reading the flow below.

## How to land a change

1. Open an issue here describing the change.
2. If it's accepted, either (a) we port it upstream and re-sync
   (recommended for small patches), or (b) you open a PR here and we
   port your commit upstream before merging anything.
3. Once the change ships upstream, the next sync brings it into this
   repo with your commit attributed via `Co-Authored-By`.

## Scope

This repo hosts:

- `bin/gitmon` — POSIX shell binary.
- `install.sh` — the curl-installable bootstrap script.
- `hooks/` — Claude Code hooks for the status-line bubble renderer.
- `claude-skill/gitmon/SKILL.md` — the `/gitmon` slash-command skill.

Out of scope:

- Server-side changes to `gitmon.io` (handled in the private repo).
- New LLM providers (requires server-side support first).
- Rewriting the binary in Node/Go/Rust (a future roadmap item — please
  open an issue to discuss before starting).

## Style

- POSIX `sh` only — no bash-isms in `bin/gitmon` or `install.sh`.
- `shellcheck -s sh` must pass clean.
- No new dependencies beyond `curl` and `jq`.
