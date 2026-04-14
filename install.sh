#!/usr/bin/env sh
# =====================================================================
# gitmon-cli installer (Spec 29 §8).
#
#   curl -fsSL https://gitmon.io/install.sh | sh
#
# Installs the `gitmon` binary to ~/.local/bin. Optionally installs
# Claude Code hooks + skill to ~/.claude/ (prompts interactively).
# =====================================================================

set -eu

REPO_RAW="${GITMON_CLI_REPO:-https://raw.githubusercontent.com/brunobracaioli/gitmon-cli/main}"
BIN_URL="$REPO_RAW/bin/gitmon"
HOOKS_BASE="$REPO_RAW/hooks"
SKILL_URL="$REPO_RAW/claude-skill/gitmon/SKILL.md"

INSTALL_DIR="${GITMON_INSTALL_DIR:-$HOME/.local/bin}"
CLAUDE_HOOKS_DIR="$HOME/.claude/hooks"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills/gitmon"

# -----------------------------------------------------------------
# Sanity checks
# -----------------------------------------------------------------

for dep in curl; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    printf 'install: missing dependency "%s". Install it first.\n' "$dep" >&2
    exit 127
  fi
done

case "$(uname -s)" in
  Linux*|Darwin*) ;;
  *)
    printf 'install: unsupported OS "%s". Use WSL on Windows.\n' "$(uname -s)" >&2
    exit 1
    ;;
esac

mkdir -p "$INSTALL_DIR"

# -----------------------------------------------------------------
# Install binary
# -----------------------------------------------------------------

printf 'Downloading gitmon binary...\n'
curl -fsSL "$BIN_URL" -o "$INSTALL_DIR/gitmon"
chmod +x "$INSTALL_DIR/gitmon"
printf '✓ Installed %s\n' "$INSTALL_DIR/gitmon"

case ":$PATH:" in
  *:"$INSTALL_DIR":*) ;;
  *)
    printf '\n⚠  %s is not in your PATH.\n' "$INSTALL_DIR"
    printf '   Add this to your shell profile (~/.bashrc, ~/.zshrc, etc):\n'
    printf '     export PATH="%s:$PATH"\n\n' "$INSTALL_DIR"
    ;;
esac

# -----------------------------------------------------------------
# Optional: Claude Code integration
# -----------------------------------------------------------------

printf '\nInstall Claude Code integration (statusline hook for the bubble)? [Y/n] '
read answer
case "$answer" in
  n|N|no|NO) INSTALL_CLAUDE=0 ;;
  *) INSTALL_CLAUDE=1 ;;
esac

if [ "$INSTALL_CLAUDE" = "1" ]; then
  mkdir -p "$CLAUDE_HOOKS_DIR"
  for hook in gitmon-statusline gitmon-session-start gitmon-post-tool gitmon-stop; do
    target="$CLAUDE_HOOKS_DIR/$hook.sh"
    if [ -f "$target" ]; then
      printf '  skipped %s (already exists)\n' "$target"
    else
      curl -fsSL "$HOOKS_BASE/$hook.sh" -o "$target"
      chmod +x "$target"
      printf '  ✓ %s\n' "$target"
    fi
  done

  printf '\nTo activate the statusline, add this to ~/.claude/settings.json:\n'
  cat <<EOF
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/hooks/gitmon-statusline.sh",
    "refreshInterval": 1
  }
}
EOF
  printf '\n(or run: /gitmon activate — inside Claude Code)\n'
fi

# -----------------------------------------------------------------
# Done
# -----------------------------------------------------------------

cat <<'EOF'

═══════════════════════════════════════════════════
  gitmon-cli installed.

  Next steps:
    1. gitmon auth           — pair with gitmon.io
    2. ! gitmon chat "hi"    — inside Claude Code (zero trace)
       OR
       gitmon chat "hi"      — any terminal

  No GitMon yet? Hatch one at https://gitmon.io
═══════════════════════════════════════════════════
EOF
