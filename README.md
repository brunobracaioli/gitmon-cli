# gitmon-cli

Zero-trace chat with your [GitMon](https://gitmon.io) from any terminal.

`gitmon chat "..."` writes the reply to your terminal status-line bubble
instead of printing it to stdout, so conversations with your pet don't
pollute your Claude Code transcript or shell history.

## Install

```sh
curl -fsSL https://gitmon.io/install.sh | sh
```

Installs the `gitmon` binary to `~/.local/bin` and (optionally) the
Claude Code statusline hook + session hooks to `~/.claude/hooks/`.

Dependencies: `curl`, `jq`. POSIX sh. Works on Linux, macOS, and WSL.

## Prerequisites

1. A GitHub account (sign in at <https://gitmon.io>).
2. A hatched GitMon — visit the site to pick your egg.
3. An Anthropic or OpenAI API key configured in your dashboard at
   **Settings → AI Provider** (use `gitmon.io/s/key` for a shortcut).

## Usage

```sh
gitmon auth                  # pair this machine with gitmon.io
gitmon chat "hey you"        # chat (reply lands in statusline bubble)
gitmon logout                # revoke token + forget locally
gitmon status                # show config + token presence
gitmon version               # version + server reachability
```

Inside Claude Code, prefix the command with `!` to skip the assistant
turn entirely:

```
! gitmon chat "how's the code today"  >/dev/null 2>&1
```

The reply appears in the status-line bubble beneath the prompt and fades
after ~20 seconds.

## How it works

1. `gitmon auth` opens `gitmon.io/cli/pair` in your browser. You copy
   a one-time code back into your terminal; the server exchanges it for
   a long-lived bearer token saved at `~/.config/gitmon/token` (chmod 600).
2. `gitmon chat "msg"` POSTs to `gitmon.io/api/v1/cli/chat`. The server
   builds your GitMon's persona prompt, calls the LLM on your behalf
   using the API key you configured on the website, and returns a reply
   capped at ~180 characters.
3. The reply is written to `~/.gitmon-speech.txt`. If you installed the
   Claude Code statusline hook, the bubble renderer reads that file on
   its ≤1-second tick and floats the text above your prompt.

No background daemons. No telemetry beyond what the gitmon.io API
already records. The binary is ~230 lines of POSIX shell — read it.

## Security notes

- The CLI stores a bearer token locally at `~/.config/gitmon/token`
  with mode 600. Revoke it any time from your dashboard at
  <https://gitmon.io> or with `gitmon logout`.
- Unlike the web chat and browser extension, the CLI uses a
  **backend-proxied** LLM call because shell scripts can't cleanly
  dispatch multi-provider HTTPS. This means the gitmon.io server
  holds your API key in RAM for the duration of each request (~1-3s)
  in addition to storing it at rest. See our [Security page](https://gitmon.io/security)
  for details.
- The server never logs your API key. `Sentry.beforeSend` strips any
  property matching `/llm.?api.?key|api_key|apikey/i` as a defense in
  depth.

## Contributing

This repo is a **build artifact** of the private GitMon codebase. Edit
upstream, not here. See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

Apache 2.0. See [LICENSE](./LICENSE).
