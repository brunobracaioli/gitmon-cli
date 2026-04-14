#!/bin/bash
# GitMon Reactive Companion — Stop hook (occasional commentary via status bar)
# ~20% chance: writes speech bubble to status line. Does NOT instruct Claude to output inline text.

set -uo pipefail

STATE_FILE="$HOME/.claude/gitmon-state.json"
MUTE_FILE="$HOME/.claude/gitmon-muted"
SPEECH_FILE="$HOME/.gitmon-speech.txt"

if [ -f "$MUTE_FILE" ] || [ ! -f "$STATE_FILE" ]; then exit 0; fi

# 20% probability
now=$(date +%s)
if [ $((now % 5)) -ne 0 ]; then exit 0; fi

name=$(jq -r '.nickname // .species_name' "$STATE_FILE")
hunger=$(jq -r '.hunger' "$STATE_FILE")
happiness=$(jq -r '.happiness' "$STATE_FILE")
streak=$(jq -r '.current_streak // 0' "$STATE_FILE")
status=$(jq -r '.status' "$STATE_FILE")
species=$(jq -r '.species_id' "$STATE_FILE")
t_sar=$(jq -r '.traits.sarcasm // 2' "$STATE_FILE")
t_hum=$(jq -r '.traits.humor // 4' "$STATE_FILE")

if [ "$status" = "dead" ] || [ "$status" = "egg" ] || [ "$status" = "hatching" ]; then exit 0; fi

# Hacker check
is_hacker=false
case "$species" in
  red_hacker|blue_hacker|yellow_hacker|devsecops_hacker|crypto_hacker|game_hacker|golden_hacker)
    is_hacker=true ;;
esac

# Pick expanded phrase pool based on state
if [ "$hunger" -lt 30 ]; then
  if [ "$is_hacker" = "true" ]; then
    PHRASES=(
      "Low fuel. Commit something."
      "Hungry. Deploy snacks."
      "Running on empty..."
      "Feed the machine."
      "Battery: critical."
      "Resource starvation."
      "Commit = calories."
      "OOM killer incoming."
      "Send food, not bugs."
      "Cache miss: lunch."
    )
  else
    PHRASES=(
      "I'm hungry..."
      "Feed me commits!"
      "So empty..."
      "Need food..."
      "Tummy rumbling."
      "Commits = snacks."
      "Starving here!"
      "Where's lunch?"
      "Feed me, please."
      "Empty belly..."
    )
  fi
elif [ "$streak" -gt 7 ]; then
  if [ "$is_hacker" = "true" ]; then
    PHRASES=(
      "${streak}d streak. Solid."
      "Systems nominal."
      "Uptime: ${streak} days."
      "Clean record."
      "Green across the board."
      "${streak}d no breaches."
      "Consistent. Respectable."
      "Streak stable."
      "Production grade."
      "No regressions. ${streak}d."
    )
  elif [ "$t_sar" -gt 6 ]; then
    PHRASES=(
      "${streak} days? Shocking."
      "Impressive, I suppose."
      "${streak}d. Don't get cocky."
      "Keep it up. Or don't."
      "Ten gold stars."
      "Wow, consistency."
      "${streak}d. Try harder."
      "A streak. Fancy."
      "Marginally impressed."
      "${streak}d. Meh."
    )
  else
    PHRASES=(
      "${streak} day streak!"
      "On fire!"
      "Keep going!"
      "Unstoppable!"
      "${streak}d! 🔥"
      "Never stop!"
      "Streak king."
      "Legendary."
      "${streak} days strong."
      "Pure momentum."
    )
  fi
elif [ "$happiness" -gt 80 ]; then
  if [ "$is_hacker" = "true" ]; then
    PHRASES=(
      "All green."
      "No vulnerabilities."
      "Secure perimeter."
      "Systems optimal."
      "Zero threats detected."
      "Pipelines clean."
      "Perfect build."
      "Firewall up. Mood up."
      "Green dashboard."
      "Patched and happy."
    )
  elif [ "$t_hum" -gt 6 ]; then
    PHRASES=(
      "Vibing hard."
      "Happy little bytes."
      "Dancing in the RAM."
      "All smiles, no frowns."
      "Serotonin: max."
      "Life's good, bug-free."
      "Joy.exe running."
      "Mood: adorable."
      "Happy noises."
      "Big smile energy."
    )
  else
    PHRASES=(
      "Feeling great!"
      "Happy!"
      "Life is good!"
      "Vibing!"
      "All is well."
      "Peaceful day."
      "Content."
      "Pure joy."
      "Loving this."
      "Best mood."
    )
  fi
elif [ "$status" = "sleeping" ]; then
  PHRASES=(
    "zzZ..."
    "..."
    "*yawn*"
    "still sleeping..."
    "sshh..."
    "dreaming of commits..."
    "5 more minutes..."
    "*snore*"
    "eyes heavy..."
    "zzz..."
  )
else
  if [ "$is_hacker" = "true" ]; then
    PHRASES=(
      "Scanning..."
      "Monitoring..."
      "On standby."
      "Watching the logs."
      "Idle process."
      "Listening for syscalls."
      "Packets flowing."
      "Quiet on the wire."
      "Sniffing the net."
      "Waiting. Watching."
    )
  elif [ "$t_sar" -gt 6 ]; then
    PHRASES=(
      "Still watching."
      "Riveting work."
      "What a show."
      "Carry on."
      "I'm invested."
      "Noted."
      "Interesting approach."
      "Oh, is that so."
      "Do go on."
      "Fascinating."
    )
  else
    PHRASES=(
      "Watching you code..."
      "Hmm..."
      "Interesting..."
      "Still here!"
      "Working hard?"
      "Keep it up."
      "Nice work."
      "Steady progress."
      "I see you."
      "Good stuff."
    )
  fi
fi

idx=$(( RANDOM % ${#PHRASES[@]} ))
echo "${PHRASES[$idx]}" > "$SPEECH_FILE"

# Stop hooks do NOT accept hookSpecificOutput.additionalContext per Claude Code schema.
# The speech file write above is sufficient — the status bar picks it up on next poll.
exit 0
