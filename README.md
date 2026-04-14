# gitmon-cli

> Zero-trace terminal chat with your [GitMon](https://gitmon.io) — POSIX shell, curl-installable, Apache 2.0.

```
_.-._
(o o)  brunobracaioli★ Lv.35 █████ 🔥13d
| O |   💬 "Hey, your test suite is on fire 🔥"
```

`gitmon chat "..."` writes the reply to your terminal **status-line bubble** instead of stdout — so conversations with your pet don't pollute your Claude Code transcript or shell history. The chat itself works in any terminal; the floating bubble renders inside Claude Code (where the statusline hook lives).

---

## ⚡ Install

### Option A — One curl command

```sh
curl -fsSL https://gitmon.io/install.sh | sh
```

Installs `~/.local/bin/gitmon` + statusline hook at `~/.claude/hooks/`. Then run `gitmon auth` to pair.

Dependencies: `curl`, `jq`. POSIX sh. Works on **Linux, macOS, and WSL**.

### Option B — Copy this prompt into Claude Code 🪄

Already running Claude Code? Paste this whole block as a message and Claude will install everything for you, end-to-end:

```
Install gitmon-cli on this machine end-to-end. Steps:

1. Run in bash: curl -fsSL https://gitmon.io/install.sh | sh
   (it auto-installs the Claude Code statusline hook because stdin is
   not a TTY — no prompt to answer)

2. Read ~/.claude/settings.json (create the file as {} if missing).
   Merge this object in at the top level, preserving any existing keys:
       {"statusLine":{"type":"command","command":"~/.claude/hooks/gitmon-statusline.sh","refreshInterval":1}}

3. Tell me to open a separate terminal and run:
       ~/.local/bin/gitmon auth
   It opens https://gitmon.io/cli/pair in my browser. I'll copy the
   one-time code from that page, paste into the terminal, press Enter.
   Wait for me to confirm I'm authed before continuing.

4. Once I confirm, run in bash:
       ~/.local/bin/gitmon chat "hi from Claude Code"
   Then point me at the floating bubble that appears in my statusline
   above the prompt — fades after ~20 seconds.
```

Same end result, no copy-paste of curl flags or JSON merging by hand.

---

## Prerequisites

1. **GitHub account** → sign in at [gitmon.io](https://gitmon.io).
2. **A hatched GitMon** — pick your egg on the site.
3. **Anthropic or OpenAI API key** configured at [gitmon.io/s/key](https://gitmon.io/s/key).

If any prerequisite is missing, the bubble itself tells you in-character (see [Soft-error UX](#soft-error-ux) below) — no stack traces, no stderr noise.

---

## Usage

```sh
gitmon auth                  # pair this machine with gitmon.io
gitmon chat "hey you"        # chat — reply lands in statusline bubble
gitmon logout                # revoke token + forget locally
gitmon status                # show config + token presence
gitmon version               # version + server reachability
gitmon help                  # this help
```

**Inside Claude Code**, prefix with `!` to skip the assistant turn entirely (zero transcript trace):

```
! gitmon chat "how's the code today" >/dev/null 2>&1
```

The reply appears in the status-line bubble beneath the prompt and fades after ~20s.

---

## How it works

1. **`gitmon auth`** opens `gitmon.io/cli/pair` in your browser. You copy a one-time code back into the terminal; the server exchanges it for a long-lived bearer token at `~/.config/gitmon/token` (chmod 600, 90-day rolling TTL).

2. **`gitmon chat "msg"`** POSTs to `gitmon.io/api/v1/cli/chat`. The server builds your GitMon's persona prompt, calls the LLM on your behalf using the API key you configured on the website, and returns a reply capped at ~200 characters.

3. The reply is written to `~/.gitmon-speech.txt`. The Claude Code statusline hook polls that file on its ≤1-second tick and floats the text above your prompt.

No background daemons. No telemetry beyond what the gitmon.io API already records. The binary is ~230 lines of POSIX shell — [read it](./bin/gitmon).

---

## Soft-error UX

Every backend outcome is rendered **in-character through the bubble**. No HTTP error codes, no stack traces:

| Situation | Bubble shows |
|---|---|
| No LLM key configured | `Sem key, só sussurro nas sombras. Configura em gitmon.io/s/key 🔑` |
| GitMon dead | `Tô morto 💀. Renasce em gitmon.io/s/rebirth` |
| GitMon still in egg | `Ainda no ovo 🥚. Commita pra me chocar!` |
| Sleeping (48h+ inactive) | `Zzz... sumiu faz dias. Bora codar de novo?` |
| Rate-limited (30/h) | `Calma — 30 chats/h. Volta em Xmin.` |
| Token expired/invalid | `Sessão expirou. Rode: gitmon auth` |
| Backend offline | `Sem sinal 🌐 — tento de novo mais tarde` |

Templates exist in **PT/EN/ES** × 8 elements (Shadow/Fire/Water/Light/Nature/Tech/Cosmic/default). Locale picked from your shell's `$LANG`.

---

## Security notes

- **Local token storage**: `~/.config/gitmon/token`, mode 600. Revoke any time via `gitmon logout` or your [dashboard settings](https://gitmon.io/s/settings).
- **Backend-proxied LLM**: Unlike the web chat and browser extension (which call OpenAI/Anthropic directly from your device), the CLI proxies through `gitmon.io` for ~1-3s per request because shell can't cleanly dispatch multi-provider HTTPS. The server holds your API key in RAM during the request — see the [Security page](https://gitmon.io/security) for the full disclosure.
- **No key in logs**: enforced by a Sentry `beforeSend` scrubber and a CI test that greps the build output.

---

## Contributing

This repo is a **build artifact** of the private GitMon codebase. PRs land via the upstream-first flow — see [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

Apache 2.0. See [LICENSE](./LICENSE).
