#!/bin/bash
# GitMon Reactive Companion — SessionStart hook
# Fetches fresh GitMon state from the public API and injects persona
# into Claude Code's context on every new session.

set -euo pipefail

STATE_FILE="$HOME/.claude/gitmon-state.json"
MUTE_FILE="$HOME/.claude/gitmon-muted"

# Read username from git config
USERNAME=$(git config user.name 2>/dev/null || echo "")
if [ -z "$USERNAME" ]; then
  exit 0
fi

# Fetch GitMon data from public API (5s timeout)
RESPONSE=$(curl -s --max-time 5 "https://gitmon.io/api/v1/public/gitmon/$USERNAME" 2>/dev/null || echo "")

# If fetch failed or 404, exit silently
if [ -z "$RESPONSE" ] || echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
  exit 0
fi

# Add metadata and save to cache
echo "$RESPONSE" | jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg user "$USERNAME" \
  '. + {fetched_at: $ts, github_username: $user}' > "$STATE_FILE"

# Extract fields for persona
name=$(jq -r '.nickname // .species_name' "$STATE_FILE")
species=$(jq -r '.species_name' "$STATE_FILE")
level=$(jq -r '.level' "$STATE_FILE")
element=$(jq -r '.element' "$STATE_FILE")
status=$(jq -r '.status' "$STATE_FILE")
hunger=$(jq -r '.hunger' "$STATE_FILE")
happiness=$(jq -r '.happiness' "$STATE_FILE")
streak=$(jq -r '.current_streak' "$STATE_FILE")
stage=$(jq -r '.stage_name' "$STATE_FILE")

# Traits (use defaults if not in response)
t_int=$(jq -r '.traits.intelligence // 4' "$STATE_FILE")
t_sar=$(jq -r '.traits.sarcasm // 2' "$STATE_FILE")
t_hum=$(jq -r '.traits.humor // 4' "$STATE_FILE")
t_iro=$(jq -r '.traits.irony // 2' "$STATE_FILE")
t_agg=$(jq -r '.traits.aggression // 2' "$STATE_FILE")

# Don't inject persona if dead
if [ "$status" = "dead" ]; then
  exit 0
fi

# Check mute — still inject persona but add mute note
mute_note=""
if [ -f "$MUTE_FILE" ]; then
  mute_note=" MUTED: Do NOT generate any GitMon speech bubbles this session."
fi

# Build persona context
PERSONA="GITMON COMPANION ACTIVE: You are accompanied by $name, a Level $level $species ($stage, $element-type GitMon). Personality traits: intelligence $t_int/10, sarcasm $t_sar/10, humor $t_hum/10, irony $t_iro/10, aggression $t_agg/10. Current state: $status, hunger $hunger/100, happiness $happiness/100, streak $streak days. CRITICAL RENDERING RULE: Your GitMon companion reacts EXCLUSIVELY through the terminal status bar (the persistent footer below the chat). You must NEVER output inline speech bubbles, 💬 messages, in-character GitMon quotes, or any narration FROM the GitMon in your chat responses. The GitMon speaks only via the status bar, not via you. If you want the GitMon to react, write its line to the speech file using Bash: echo 'short quip' > ~/.gitmon-speech.txt (max 120 chars, trait-appropriate — high sarcasm = dry, high humor = pun, high aggression = trash-talk). Then continue your response normally WITHOUT any 💬 text. Respond in the same language the user is using.$mute_note"

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "$PERSONA"
  }
}
EOF
