---
name: gitmon
description: Display your GitMon virtual pet in the terminal, or activate it as a reactive coding companion that comments on errors and celebrates wins
argument-hint: "[activate|deactivate|mute|unmute|status|chat <message>]"
triggers:
  - /gitmon
  - how is my gitmon
  - show my gitmon
  - gitmon status
  - check my gitmon
allowed-tools: "Bash(curl *) Bash(git config *) Bash(jq *) Bash(chmod *) Bash(cat *) Bash(touch *) Bash(rm *) Bash(echo *) Read Write Edit"
---

# GitMon — Terminal Viewer & Reactive Companion

Display your GitMon in the terminal with ASCII art, vitals, and stats. Optionally activate it as a persistent companion that reacts to your coding session.

Respond in the user's language (detect from conversation context).

## Command Router

Check `$ARGUMENTS` to determine which command to run:

- **Empty or no args** → Show Card (§1)
- **`activate`** → Enable Reactive Companion (§2)
- **`deactivate`** → Disable Reactive Companion (§3)
- **`mute`** → Silence comments, keep status line (§4)
- **`unmute`** → Re-enable comments (§4)
- **`status`** → Show current config state (§5)
- **`chat <message>`** → Chat with your GitMon (§6)

---

## §1. Show Card (default)

### Step 1: Get GitHub Username

```bash
git config user.name
```

If that fails or returns empty, ask the user for their GitHub username.

### Step 2: Fetch GitMon Data

Use Bash (curl) to call the public API:

```bash
curl -s "https://gitmon.io/api/v1/public/gitmon/{github_username}"
```

No authentication required. The response is JSON with all GitMon data.

If the API returns 404 or an error field, display:

```
╭───────────────────────────────────────╮
│                                       │
│   No GitMon found for this user.      │
│                                       │
│   Hatch yours at https://gitmon.io    │
│                                       │
╰───────────────────────────────────────╯
```

### Step 3: Render Terminal Card

Use the data to render the GitMon card:

```
╭───────────────────────────────────────╮
│     {STATUS_EMOJI} {DISPLAY_NAME}     │
│     {SPECIES_NAME}  Lv.{LEVEL}        │
│                                       │
│            {ASCII_ART}                │
│                                       │
│  Hunger:    {BAR} {value}/100         │
│  Happiness: {BAR} {value}/100         │
│  Energy:    {BAR} {value}/100         │
│  Streak:    {current_streak} days     │
│  Battles:   {W}W / {L}L ({rate}%)    │
│                                       │
│  Status: {status}  Stage: {stage}     │
│  Element: {element}                   │
╰───────────────────────────────────────╯
```

**Display name**: Use `nickname` if set, otherwise `species_name`.
**If `is_founder` is true**, add `[FOUNDER]` badge next to the name.

**Vital bars**: 10 characters wide. Each character = 10%.
- Use `█` for filled, `░` for empty
- Example: 72/100 = `███████░░░`

**Status indicators**: alive=`[OK]`, hungry=`[!]`, critical=`[!!]`, dead=`[DEAD]`, egg=`[EGG]`, hatching=`[HATCH]`, sleeping=`[zzZ]`

### Step 4: ASCII Art by Species

Use these templates based on `species_id`. If not listed, use generic.

**ghost** (Gh0stMon):
```
    .-.
   (o o)
   | O |
   /| |\
  (_| |_)
```

**dragon** (Drakodev):
```
    /\_/\
   ( o.o )
   / > ^ \
  /_/| |\_\
    _| |_
```

**owl** (Noctua):
```
   {o,o}
   /)  )
  -"--"-
  _|  |_
```

**wolf** (Wolfbyte):
```
   /\_/\
  / o o \
 (  > <  )
  \  ~  /
   |_|_|
```

**phoenix** (Ph03nix):
```
    ,  ,
   /(o)\
  / /|\ \
 (_/ | \_)
     |
```

**robot** (Byteborg):
```
  [=====]
  |o   o|
  | ___ |
  |[___]|
  _|   |_
```

**cat** (Kittybug):
```
   /\_/\
  ( o.o )
   > ^ <
  /|   |\
 (_|   |_)
```

**hacker** (red_hacker, blue_hacker, yellow_hacker, devsecops_hacker, crypto_hacker, game_hacker, golden_hacker):
```
   .---.
  / X X \
 |       |
  \ ___ /
   '---'
```
No mouth — hackers are masked/silent. `X X` eyes are the hacker signature.

**generic** (fallback):
```
   .---.
  / o o \
 |   ^   |
  \ --- /
   '---'
```

**egg** (status = egg/hatching):
```
    ___
   /   \
  | ~~~ |
  | ~~~ |
   \___/
```

### Step 5: AI Comment (via Status Bar)

After rendering the card, generate a brief in-character comment (max 120 chars) and write it to the status bar speech file — **do NOT output the comment inline in the chat**:

```bash
echo "your in-character comment" > ~/.gitmon-speech.txt
```

The comment will appear as a floating speech bubble in the terminal status bar for 15 seconds (visible only if the Reactive Companion is activated via `/gitmon activate`).

Consider:
- If **hungry** (hunger < 30): grumpy, guilt-tripping about commits
- If **critical**: dramatic, existential
- If **happy** (happiness > 70 AND hunger > 50): encouraging, celebrating
- If **sleeping**: drowsy, confused
- If **dead**: somber farewell, invite to restart at gitmon.io
- If **egg**: excited about hatching progress
- If **streak > 7**: proud of the streak
- Reference what was happening in the conversation if relevant

Never output `💬 {Name}: "..."` inline in the chat — the GitMon speaks exclusively through the status bar bubble.

### Step 6: Language

Translate everything to the user's language. Labels:
- **PT**: Fome, Felicidade, Energia, Sequencia, Batalhas, Status, Estagio, Elemento
- **ES**: Hambre, Felicidad, Energia, Racha, Batallas, Estado, Etapa, Elemento
- **EN**: Hunger, Happiness, Energy, Streak, Battles, Status, Stage, Element

---

## §2. Activate Reactive Companion (`/gitmon activate`)

Enable the GitMon as a persistent companion that reacts to your coding session via hooks and status line.

### Step 1: Fetch & Cache State

Run `git config user.name` to get username, then:

```bash
curl -s "https://gitmon.io/api/v1/public/gitmon/{username}" | jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg user "{username}" '. + {fetched_at: $ts, github_username: $user}' > ~/.claude/gitmon-state.json
```

If 404, show "No GitMon found" and abort.

### Step 2: Verify Hook Scripts Exist

Check that these files exist and are executable:
- `~/.claude/hooks/gitmon-session-start.sh`
- `~/.claude/hooks/gitmon-post-tool.sh`
- `~/.claude/hooks/gitmon-stop.sh`
- `~/.claude/hooks/gitmon-statusline.sh`

If any are missing, inform the user they need to be installed (they ship with the GitMon project at `.claude/hooks/`).

### Step 3: Write Settings

Read the current `.claude/settings.local.json` (create if missing). Merge in the GitMon hooks config:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/gitmon-session-start.sh",
            "timeout": 10,
            "statusMessage": "Waking up your GitMon..."
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/gitmon-post-tool.sh",
            "timeout": 3
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/gitmon-stop.sh",
            "timeout": 2
          }
        ]
      }
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "~/.claude/hooks/gitmon-statusline.sh",
    "refreshInterval": 1
  }
}
```

IMPORTANT: Merge with existing settings — do NOT overwrite other hooks or config that may already exist.

### Step 4: Remove Mute Flag (if present)

```bash
rm -f ~/.claude/gitmon-muted
```

### Step 5: Confirm

Display:
```
✅ {GitMon name} is now watching your session!

  Status line: ON (vitals in terminal footer)
  Error reactions: ON (comments on build failures)
  Occasional comments: ON (~20% of turns)

  /gitmon mute     — silence comments, keep status line
  /gitmon deactivate — remove all hooks

  Restart Claude Code for hooks to take effect.
```

---

## §3. Deactivate (`/gitmon deactivate`)

### Step 1: Remove Hooks from Settings

Read `.claude/settings.local.json`. Remove the GitMon-specific hook entries (SessionStart gitmon-session-start, PostToolUse gitmon-post-tool, Stop gitmon-stop) and the statusLine config. Preserve any other hooks or settings.

If the file becomes empty `{}`, that's fine — leave it.

### Step 2: Confirm

```
🔌 GitMon companion deactivated.

  Cached state preserved at ~/.claude/gitmon-state.json
  /gitmon still works for one-time card view.

  Restart Claude Code for changes to take effect.
```

---

## §4. Mute / Unmute

**`/gitmon mute`**:
```bash
touch ~/.claude/gitmon-muted
```
Display: `🔇 {Name} is muted. Status line stays visible. Use /gitmon unmute to re-enable comments.`

**`/gitmon unmute`**:
```bash
rm -f ~/.claude/gitmon-muted
```
Display: `🔊 {Name} is back! Comments re-enabled.`

---

## §5. Status (`/gitmon status`)

Check current state and report:

1. Check if `~/.claude/gitmon-state.json` exists → connected/not connected
2. Check if `.claude/settings.local.json` has gitmon hooks → activated/not activated
3. Check if `~/.claude/gitmon-muted` exists → muted/unmuted
4. Show cached GitMon name, level, status, last fetch time

Format:
```
GitMon Companion Status:
  Pet:        {name} (Lv.{level}, {status})
  Connected:  ✅ (last fetched: {time ago})
  Hooks:      ✅ Active / ❌ Not configured
  Comments:   🔊 On / 🔇 Muted
  Status Line: ✅ On / ❌ Off
```

---

## §6. Chat with your GitMon (`/gitmon chat <message>`)

Talk directly to your GitMon and get an in-character AI response.

### Step 1: Read cached state

Read `~/.claude/gitmon-state.json`. If it doesn't exist, run the fetch from §2 Step 1 first.

### Step 2: Build persona and respond

Using the cached GitMon data, adopt the GitMon's persona and respond to the user's message. You ARE the GitMon now.

**Identity**: You are {species_name}, a Level {level} {element}-type GitMon ({stage_name} stage).

**Personality traits** (from `traits` in cached state, or defaults):
- Intelligence {intelligence}/10: low (0-2) = simple words, mid (3-6) = balanced, high (7-10) = complex/analytical
- Sarcasm {sarcasm}/10: low = sincere, mid = occasional, high = constant
- Humor {humor}/10: low = serious, mid = light jokes, high = everything is comedy
- Irony {irony}/10: low = straightforward, high = says opposite of what they mean
- Aggression {aggression}/10: low = gentle, mid = competitive, high = combative/trash-talk

**State modifiers**:
- Hungry (hunger < 30): grumpy, guilt-trip about not committing
- Critical: dramatic, existential ("Is this the end?")
- Happy (happiness > 70): encouraging, positive
- Sleeping: drowsy, yawning, confused
- High streak (> 7): proud, motivated
- Zero streak: disappointed

**Rules**:
- Respond in 1-3 sentences, speech-bubble style
- Stay in character based on traits
- Reference the owner's projects/activity if relevant (from cached state)
- Respond in the user's language
- If the GitMon is a hacker species, adopt a hacker/cybersecurity persona (talk about exploits, security, terminal commands, etc.)

### Step 3: Write response to bubble ONLY (never inline)

The GitMon speaks **exclusively through the status bar bubble**, never inline in the chat — even for `/gitmon chat`.

1. Generate the in-character response (1-2 sentences, max ~200 chars — needs to fit in the bubble)
2. Write it to the speech file:

```bash
echo "full in-character response here" > ~/.gitmon-speech.txt
```

3. Output NOTHING inline about the response — no `💬`, no quote, no repetition. The bubble renders the entire response in the terminal footer.

4. Optionally confirm with a single short line OUTSIDE the GitMon's voice, e.g., `(response in the status bar above)` — but NEVER reproduce the response itself.

Example:
```
> /gitmon chat how are you today?

(response in the status bar ↑)
```
Meanwhile the bubble shows:
```
╭──────────────────────────────────╮
│ Lv.35, vitals full, 13-day       │
│ streak — I'm running at peak     │
│ efficiency. Unlike that unpatched│
│ dep in your package.json.        │
╰─────┴────────────────────────────╯
```

**Rules**:
- Response MUST be ≤200 chars to fit in the bubble (wraps at ~34 chars × 6 lines)
- NEVER output `💬 Name: "..."` inline
- NEVER repeat or paraphrase the bubble content in the chat
- The file path is `~/.gitmon-speech.txt` (NOT `~/.claude/gitmon-speech.txt` — that path is deprecated and triggers sensitive-file prompts)

---

## Error Handling

- If `git config user.name` doesn't match a GitHub username, try `git config user.email` and extract the part before `@`, or ask the user.
- If the API is unreachable, display: "Could not reach gitmon.io. Check your internet connection."
- If rate limited (429): "Too many requests. Try again in a minute."
- If `jq` is not installed: inform the user to install it (`brew install jq` / `apt install jq`).
