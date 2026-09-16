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