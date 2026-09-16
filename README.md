# sidepeace

A simple harness-agnostic pacing protocol background work, 
so a task that would drain a 5-hour quota in forty minutes 
instead runs across days without hitting a wall.

Two pieces:

- **`AGENTS.md`** — the protocol. Countable limits, a resumable
  line-by-line plan, and a hard stop at the end of every "burst," which
is the unit of work per X minutes the agent is allowed to do. 
- **an external scheduler** — cron or launchd, which owns the clock
  and fires one burst every N minutes.

Everything an agent cannot do reliably (measure its own consumption, 
perceive time, wait) lives outside the model.

Everything it can do reliably (count to twelve, tick a checkbox,
stop) lives in the rules file.

## Install

Per-project instead of global: drop `AGENTS.md` in the repo root.
All three read it there, which is the whole point of the filename.

Global: run from the repo root. 

Save as `install.sh`, `chmod +x install.sh`, then `./install.sh`.

```bash
#!/usr/bin/env bash
set -euo pipefail

# sidepeace installer — additive, idempotent, marker-delimited.
# Usage: ./install.sh [--uninstall]

SRC="AGENTS.md"
BEGIN="<!-- BEGIN SIDEPEACE -->"
END="<!-- END SIDEPEACE -->"
MODE="${1:-install}"

[ -f "$SRC" ] || { echo "no $SRC here — run from the repo root"; exit 1; }

strip() {  # remove any existing sidepeace block from $1, in place
  awk -v b="$BEGIN" -v e="$END" '
    $0==b {s=1} s && $0==e {s=0; next} !s {print}
  ' "$1" > "$1.sp.tmp" && mv "$1.sp.tmp" "$1"
}

upsert() {
  local t="$1"
  mkdir -p "$(dirname "$t")"
  [ -f "$t" ] || : > "$t"
  strip "$t"
  { printf '\n%s\n' "$BEGIN"; cat "$SRC"; printf '%s\n' "$END"; } >> "$t"
  echo "  rules  → $t"
}

command_body() {
cat <<'BODY'
Read `.sidepeace` in the working directory.

If it does not exist, create it with INTERVAL set to the first
argument (default 10), CYCLE=0, PLAN=PLAN.sidepeace.md, and TASK set
to the rest of the arguments. Then run cycle 0: produce the plan and
nothing else.

If it does exist, ignore all arguments and run the next cycle of the
TASK already recorded there.

Follow the SIDEPEACE MODE protocol in your standing instructions
exactly. Twelve tool calls, then the end-of-burst ritual, then stop.
BODY
}

write_cmd() {  # $1 = path, $2 = optional frontmatter
  local t="$1"
  mkdir -p "$(dirname "$t")"
  if [ -n "${2:-}" ]; then printf '%s\n' "$2" > "$t"; else : > "$t"; fi
  command_body >> "$t"
  echo "  cmd    → $t"
}

CLAUDE_FM='---
description: Start or advance a sidepeace background task
argument-hint: [interval-minutes] [task description]
allowed-tools: Read, Write, Edit, Bash(date:*), Bash(cat:*)
---'

if [ "$MODE" = "--uninstall" ]; then
  for f in ~/.claude/CLAUDE.md ~/.codex/AGENTS.md ~/.gemini/GEMINI.md; do
    [ -f "$f" ] && strip "$f" && echo "  cleaned → $f"
  done
  rm -f ~/.claude/commands/sidepeace.md \
        ~/.codex/prompts/sidepeace.md \
        ~/.gemini/antigravity/global_workflows/sidepeace.md
  echo "done."
  exit 0
fi

echo "claude code:"
upsert     ~/.claude/CLAUDE.md
write_cmd  ~/.claude/commands/sidepeace.md "$CLAUDE_FM"

echo "codex:"
upsert     ~/.codex/AGENTS.md
write_cmd  ~/.codex/prompts/sidepeace.md

echo "antigravity:"
upsert     ~/.gemini/GEMINI.md
write_cmd  ~/.gemini/antigravity/global_workflows/sidepeace.md

echo
echo "done. restart any running agent sessions to pick up new rules."
```

The script is non-destructive: it inserts a marker-delimited 
block into each target file, replacing any previous sidepeace 
block, and leaves everything else in the file alone.

## Where it goes

| Platform | Standing instructions | Slash command |
|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/commands/sidepeace.md` |
| Codex | `~/.codex/AGENTS.md` | `~/.codex/prompts/sidepeace.md` |
| Antigravity | `~/.gemini/GEMINI.md` | `~/.gemini/antigravity/global_workflows/sidepeace.md` |

## Use

```
/sidepeace 10 refactor the ingest pipeline for streaming input
```

First invocation writes `.sidepeace` and produces the plan. Every
invocation after that does one chunk. Then hand the clock over:

```cron
*/10 * * * * cd ~/proj && claude -p "/sidepeace" >> ~/proj/.sidepeace.log 2>&1
```

On macOS, launchd with a `StartInterval` of `600` is better — cron
does not fire jobs missed during sleep, and a laptop that closes for
two hours will silently skip twelve bursts.

To pause: `mv .sidepeace .sidepeace.off`. The next scheduled run
becomes a cheap no-op. To resume: move it back.

## Caveats worth knowing before you (the person or agent reading this) trust(s) it

**Appending to `~/.gemini/GEMINI.md` affects Gemini CLI too** — both
Antigravity and the CLI are hardcoded to that path. The installer
appends inside markers rather than overwriting, so nothing of yours
is lost, but the sidepeace rules become visible to both tools.
Antigravity also reads `~/.gemini/AGENTS.md` if you would rather keep
them separate; change the target in the script.

**Antigravity caps each rules file at 12,000 characters.** `AGENTS.md`
here is about 6,000, so there is room for roughly one more block
before things start silently falling off the end.

**Codex reads `AGENTS.override.md` first if it exists**, and uses only
the first non-empty file at that level. If you have an override file,
the installer's target will never load. Point it there instead.

**Never let the agent run `sleep` to pace itself.** Beyond it being
the wrong architecture, agent bash tools carry timeouts in the
minutes, and reported real-world ceilings are sometimes far shorter
than the documented maximum. Long in-session naps get killed
mid-nap, and you get a burst at an unpredictable time.

**The 12-tool-call budget is arbitrary and probably wrong for you.**
It is the right *kind* of number — countable, verifiable after the
fact by reading the transcript — which a percentage of a quota is
not. Tune it by watching where bursts actually land.

[Claudish retained for comfort purposes]

## License

"Do what thou wilt shall be the whole of the license."
