#!/bin/bash
# GitMon Reactive Companion — Multi-line status line (Buddy-style)
# Renders ASCII sprite + floating speech bubble in the terminal footer.
# Bubble fades and disappears after 15s. Falls back to 1-line on narrow/short terminals.

STATE_FILE="$HOME/.claude/gitmon-state.json"
SPEECH_FILE="$HOME/.gitmon-speech.txt"
# Migrate legacy location if present (one-time)
[ -f "$HOME/.claude/gitmon-speech.txt" ] && [ ! -f "$SPEECH_FILE" ] && mv "$HOME/.claude/gitmon-speech.txt" "$SPEECH_FILE" 2>/dev/null

if [ ! -f "$STATE_FILE" ]; then
  echo "GitMon: not connected · /gitmon activate"
  exit 0
fi

name=$(jq -r '.nickname // .species_name' "$STATE_FILE")
level=$(jq -r '.level' "$STATE_FILE")
hunger=$(jq -r '.hunger // 0' "$STATE_FILE")
streak=$(jq -r '.current_streak // 0' "$STATE_FILE")
status=$(jq -r '.status' "$STATE_FILE")
species=$(jq -r '.species_id' "$STATE_FILE")
is_founder=$(jq -r '.is_founder // false' "$STATE_FILE")
element=$(jq -r '.element // "normal"' "$STATE_FILE")

# --- ANSI colors ---
R="\033[0m"; D="\033[38;5;240m"; DD="\033[38;5;236m"; W="\033[38;5;255m"
DIM1="\033[38;5;250m"; DIM2="\033[38;5;245m"; DIM3="\033[38;5;240m"
Y="\033[38;5;220m"; G="\033[38;5;34m"; YB="\033[38;5;220m"; RD="\033[38;5;196m"

# Element color
case "$element" in
  Shadow|shadow)     EC="\033[38;5;141m" ;;
  Fire|fire)         EC="\033[38;5;203m" ;;
  Wisdom|wisdom)     EC="\033[38;5;75m"  ;;
  Water|water)       EC="\033[38;5;39m"  ;;
  Electric|electric) EC="\033[38;5;226m" ;;
  Nature|nature)     EC="\033[38;5;78m"  ;;
  Metal|metal)       EC="\033[38;5;249m" ;;
  *)                 EC="\033[38;5;252m" ;;
esac

# Hacker check
is_hacker=false
case "$species" in
  red_hacker|blue_hacker|yellow_hacker|devsecops_hacker|crypto_hacker|game_hacker|golden_hacker)
    is_hacker=true ;;
esac

# Eyes animation
now=$(date +%s)
frame=$((now % 4))
if [ "$status" = "dead" ]; then eyes="(x x)"
elif [ "$status" = "sleeping" ]; then eyes="(- -)z"
elif [ "$status" = "egg" ] || [ "$status" = "hatching" ]; then eyes="(~~~)"
elif [ "$is_hacker" = "true" ]; then eyes="(X X)"
else
  case "$species" in
    owl)    if [ $frame -lt 2 ]; then eyes="{o,o}"; else eyes="{-,-}"; fi ;;
    dragon) if [ $frame -lt 2 ]; then eyes="(o.o)"; else eyes="(^.^)"; fi ;;
    cat)    if [ $frame -lt 2 ]; then eyes="(o.o)"; else eyes="(-.-)"; fi ;;
    *)      if [ $frame -lt 2 ]; then eyes="(o o)"; else eyes="(- -)"; fi ;;
  esac
fi

# Hunger bar (5 chars)
filled=$((hunger / 20))
bar=""
for ((i=0; i<5; i++)); do
  if [ $i -lt $filled ]; then
    if [ "$hunger" -gt 60 ]; then bar+="${G}█${R}"
    elif [ "$hunger" -gt 30 ]; then bar+="${YB}█${R}"
    else bar+="${RD}█${R}"; fi
  else bar+="${D}░${R}"; fi
done

# Founder badge
founder=""; [ "$is_founder" = "true" ] && founder="${Y}★${R}"

# Status suffix
si=""
case "$status" in
  hungry)   si=" ${YB}!${R}" ;;
  critical) si=" ${RD}!!${R}" ;;
  dead)     si=" ${D}DEAD${R}" ;;
esac

# --- Terminal dimensions ---
cols=$(tput cols 2>/dev/null || echo 80)
lines=$(tput lines 2>/dev/null || echo 30)

# --- Speech bubble state ---
speech_text=""
speech_age=0
speech_color="$W"
if [ -f "$SPEECH_FILE" ]; then
  speech_mod=$(stat -c %Y "$SPEECH_FILE" 2>/dev/null || stat -f %m "$SPEECH_FILE" 2>/dev/null || echo 0)
  speech_age=$(( now - speech_mod ))
  if [ "$speech_age" -lt 20 ]; then
    speech_text=$(tr '\n\r' '  ' < "$SPEECH_FILE" | cut -c1-250 | sed -e 's/  */ /g' -e 's/^ *//' -e 's/ *$//')
    if [ "$speech_age" -lt 12 ]; then
      speech_color="$W"
    elif [ "$speech_age" -lt 16 ]; then
      speech_color="$DIM2"
    else
      speech_color="$DIM3"
    fi
  else
    rm -f "$SPEECH_FILE" 2>/dev/null
  fi
fi

# --- Compact fallback (narrow or short terminal) ---
if [ "$cols" -lt 60 ] || [ "$lines" -lt 20 ]; then
  compact_speech=""
  if [ -n "$speech_text" ]; then
    short=$(echo "$speech_text" | cut -c1-30)
    compact_speech="  ${speech_color}💬 \"${short}\"${R}"
  fi
  echo -e "${EC}${eyes}${R} ${W}${name}${R}${founder} ${D}Lv.${level}${R} ${bar} ${D}🔥${streak}d${R}${si}${compact_speech}"
  exit 0
fi

# --- Sprite (3 lines, species-specific) ---
# Line 1 = top, Line 2 = eyes/body (anchor for vitals), Line 3 = bottom
case "$species" in
  ghost|*ghost*|neon_phantom|phantom)
    s1="  (.-.)"
    s2="  ${EC}${eyes}${R}"
    s3="  | O |"
    ;;
  dragon|drakodev)
    s1="   /\\_/\\"
    s2="   ${EC}${eyes}${R}"
    s3="  / > ^ \\"
    ;;
  owl|noctua)
    s1="   ,_,"
    s2="  ${EC}${eyes}${R}"
    s3="  -\"^\"-"
    ;;
  wolf|wolfbyte)
    s1="  /\\_/\\"
    s2="  ${EC}${eyes}${R}"
    s3=" \\  ~  /"
    ;;
  phoenix|ph03nix)
    s1="  , ^ ,"
    s2="  ${EC}${eyes}${R}"
    s3=" / /|\\ \\"
    ;;
  robot|byteborg)
    s1="  [=====]"
    s2="   ${EC}${eyes}${R}"
    s3="  |[___]|"
    ;;
  cat|kittybug)
    s1="   /\\_/\\"
    s2="   ${EC}${eyes}${R}"
    s3="   > ^ <"
    ;;
  red_hacker|blue_hacker|yellow_hacker|devsecops_hacker|crypto_hacker|game_hacker|golden_hacker)
    s1="   .---."
    s2="   ${EC}${eyes}${R}"
    s3="   '---'"
    ;;
  *)
    if [ "$status" = "egg" ] || [ "$status" = "hatching" ]; then
      s1="    ___"
      s2="   ${EC}/~~~\\${R}"
      s3="    \\_/"
    else
      s1="   .---."
      s2="   ${EC}${eyes}${R}"
      s3="   '---'"
    fi
    ;;
esac

# --- Speech bubble rendering ---
# Word-wrap speech_text into lines of ~max_bubble_width chars.
render_bubble() {
  local text="$1"
  local max_w=34
  [ "$cols" -lt 80 ] && max_w=24

  # Word-wrap
  local words line_buf lines_arr=()
  line_buf=""
  for word in $text; do
    if [ -z "$line_buf" ]; then
      line_buf="$word"
    elif [ $(( ${#line_buf} + 1 + ${#word} )) -le $max_w ]; then
      line_buf="$line_buf $word"
    else
      lines_arr+=("$line_buf")
      line_buf="$word"
    fi
  done
  [ -n "$line_buf" ] && lines_arr+=("$line_buf")

  # Cap at 6 lines (enough for ~200 chars of speech)
  if [ ${#lines_arr[@]} -gt 6 ]; then
    lines_arr=("${lines_arr[@]:0:6}")
    local last_idx=5
    local last="${lines_arr[$last_idx]}"
    if [ ${#last} -gt $(( max_w - 3 )) ]; then
      last="${last:0:$(( max_w - 3 ))}..."
    else
      last="${last}..."
    fi
    lines_arr[$last_idx]="$last"
  fi

  # Compute inner width
  local inner_w=0
  for l in "${lines_arr[@]}"; do
    [ ${#l} -gt $inner_w ] && inner_w=${#l}
  done
  inner_w=$(( inner_w + 2 ))  # padding

  # Indent bubble so its stem hovers above the sprite's body column (~col 6)
  local indent="                "

  # Top border
  local top="╭"
  local bot="╰"
  for ((i=0; i<inner_w; i++)); do top="${top}─"; done
  top="${top}╮"
  # Bottom border with stem at col 6 (0-indexed position 4 inside bubble)
  local stem_pos=5
  [ $stem_pos -ge $inner_w ] && stem_pos=$(( inner_w / 2 ))
  for ((i=0; i<inner_w; i++)); do
    if [ $i -eq $stem_pos ]; then
      bot="${bot}┴"
    else
      bot="${bot}─"
    fi
  done
  bot="${bot}╯"

  # Emit lines
  echo -e "${indent}${speech_color}${top}${R}"
  for l in "${lines_arr[@]}"; do
    # Pad content to inner_w-2 (accounting for 1-char side padding)
    local content="$l"
    local pad=$(( inner_w - 2 - ${#content} ))
    local spaces=""
    for ((i=0; i<pad; i++)); do spaces="${spaces} "; done
    echo -e "${indent}${speech_color}│ ${content}${spaces} │${R}"
  done
  echo -e "${indent}${speech_color}${bot}${R}"
  # Stem dangle line (one │ hanging down)
  local stem_indent="${indent}"
  for ((i=0; i<stem_pos+1; i++)); do stem_indent="${stem_indent} "; done
  echo -e "${stem_indent}${speech_color}│${R}"
}

# --- Compose output ---
vitals="${W}${name}${R}${founder} ${D}Lv.${level}${R} ${bar} ${D}🔥${streak}d${R}${si}"

if [ -n "$speech_text" ]; then
  render_bubble "$speech_text"
fi
echo -e "${s1}"
echo -e "${s2}  ${vitals}"
echo -e "${s3}"
