#!/bin/bash
# GitMon Reactive Companion — PostToolUse hook (Bash errors)
# On error: writes speech bubble to status line. Does NOT instruct Claude to output inline text.

set -uo pipefail

STATE_FILE="$HOME/.claude/gitmon-state.json"
MUTE_FILE="$HOME/.claude/gitmon-muted"
SPEECH_FILE="$HOME/.gitmon-speech.txt"

if [ -f "$MUTE_FILE" ] || [ ! -f "$STATE_FILE" ]; then exit 0; fi

input=$(cat)
exit_code=$(echo "$input" | jq -r '.tool_result.exit_code // .tool_use.output.exit_code // 0' 2>/dev/null)

if [ "$exit_code" = "0" ] || [ "$exit_code" = "null" ] || [ -z "$exit_code" ]; then exit 0; fi

name=$(jq -r '.nickname // .species_name' "$STATE_FILE")
hunger=$(jq -r '.hunger' "$STATE_FILE")
status=$(jq -r '.status' "$STATE_FILE")
happiness=$(jq -r '.happiness' "$STATE_FILE")
species=$(jq -r '.species_id' "$STATE_FILE")
t_sar=$(jq -r '.traits.sarcasm // 2' "$STATE_FILE")
t_hum=$(jq -r '.traits.humor // 4' "$STATE_FILE")
t_agg=$(jq -r '.traits.aggression // 2' "$STATE_FILE")

if [ "$status" = "dead" ]; then exit 0; fi

# Hacker check
is_hacker=false
case "$species" in
  red_hacker|blue_hacker|yellow_hacker|devsecops_hacker|crypto_hacker|game_hacker|golden_hacker)
    is_hacker=true ;;
esac

# Trait-weighted phrase pool selection
if [ "$is_hacker" = "true" ]; then
  PHRASES=(
    "Segfault detected."
    "Patch your code."
    "Vulnerability found."
    "Error in the matrix."
    "Debug mode: ON"
    "That's not a feature."
    "Stack overflow incoming."
    "Check your logs."
    "Kernel panic imminent."
    "Exception unhandled."
    "Null pointer. Again."
    "CVE your own code."
    "Race condition detected."
    "Memory leak, rookie."
    "Compile, then ship."
    "Exit code $exit_code. Typical."
    "Core dumped. Nice."
    "Logs, now."
    "Broken pipeline."
    "Permission denied? Skill issue."
  )
elif [ "$t_sar" -gt 6 ]; then
  PHRASES=(
    "Oh, brilliant."
    "Ten out of ten, no notes."
    "Shocking outcome."
    "Truly masterful work."
    "Wow. Just wow."
    "Chef's kiss. Broken."
    "Exactly as planned, right?"
    "Did you test this?"
    "Surely not your fault."
    "Working as... designed?"
    "Exit $exit_code. Classic."
    "Peak engineering."
    "Another win for the ages."
    "Ship it anyway."
    "A learning opportunity."
    "The compiler disagrees."
    "Bold of you to run that."
    "Oh honey, no."
    "Riveting."
    "That went well."
  )
elif [ "$t_hum" -gt 6 ]; then
  PHRASES=(
    "Oopsie daisy!"
    "Ctrl+Z won't save you."
    "The bug's bugging me."
    "Error: coffee not found."
    "404: success missing."
    "Skill issue, bestie."
    "Bonk! Bug detected."
    "Time for a snack?"
    "Have you tried yelling?"
    "It's a feature now."
    "Stack trace go brrr."
    "Whoopsie!"
    "Error.exe has crashed."
    "That was spicy."
    "Press F to pay respects."
    "Oof. Big oof."
    "Broken like my heart."
    "Error aesthetic."
    "Gremlins in the code."
    "Yeet the code, try again."
  )
elif [ "$t_agg" -gt 6 ]; then
  PHRASES=(
    "FIX IT. NOW."
    "Unacceptable."
    "Do better."
    "That's embarrassing."
    "Run it again, scrub."
    "Git gud."
    "Weak code. Weak result."
    "I expected more."
    "Skill issue."
    "Level up or log off."
    "Amateur hour."
    "Rookie mistake."
    "Push through it."
    "Stop losing, start fixing."
    "Try harder."
    "Code like you mean it."
    "Debug or die."
    "Exit $exit_code? Pathetic."
    "Grind through it."
    "Get back up."
  )
else
  PHRASES=(
    "Ouch!"
    "Try again..."
    "Bug found!"
    "That didn't work..."
    "Hmm, error!"
    "Not great..."
    "Fix it!"
    "Broken build!"
    "Whoops."
    "Something's off."
    "Error spotted."
    "Let's debug."
    "Almost!"
    "Close, but no."
    "Error $exit_code."
    "Rebuild?"
    "Check the logs."
    "Keep going!"
    "One more try."
    "You got this."
  )
fi

idx=$(( RANDOM % ${#PHRASES[@]} ))
echo "${PHRASES[$idx]}" > "$SPEECH_FILE"

# Inject context for Claude — explicitly suppress inline speech
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "GITMON_STATUS_BAR_REACTION: $name reacted to the error (exit $exit_code) in the terminal status bar. The reaction is already visible there. You MUST NOT output any inline 💬 text, GitMon quote, or in-character commentary in your response. Continue helping the user normally."
  }
}
EOF
