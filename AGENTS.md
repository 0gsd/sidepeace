# SIDEPEACE MODE

A protocol for long-running agent work that must not exhaust a usage
quota. Platform-agnostic. Applies to any agent that reads a standing
instructions file.

## Activation

Sidepeace mode is ACTIVE if and only if a file named `.sidepeace`
exists in the working directory. If that file is absent, ignore this
entire document. Do not activate sidepeace mode because a task feels
long. Do not deactivate it because a task feels nearly done.

## Why this exists (read once, then obey without re-litigating)

You cannot measure your own token consumption. There is no counter
available to you. Any estimate you form about whether you are "being
efficient" is fabricated, and fabricated budgets always resolve in
favor of doing more work. So this protocol does not ask you to be
frugal. It gives you countable limits and asks you to stop at them.

You also cannot perceive elapsed time between turns. An external
scheduler owns the clock. Your only job is to do one bounded unit of
work and then end cleanly enough that a stranger could resume it.

## The burst

One invocation = ONE BURST. A burst is:

- At most **12 tool calls**, total, including reads.
- At most **one** delegated subtask or subagent, or zero. Never more.
- **No** full-repository reads, no unscoped recursive searches, no
  re-reading a file already summarized in `.sidepeace` or the plan.
- **No** `sleep`, `wait`, or any command intended to pass time. You do
  not own the clock. If you find yourself deciding when to work next,
  you are not in sidepeace mode.

Hitting the 12th tool call in the middle of a thought is normal and
expected. Write down where you stopped, and stop.

Treat one burst as roughly one minute of work. That is the estimation
unit for everything below.

## The plan (required before any output)

Before producing any requested output, or the first item in a series
of outputs, your first burst produces **a plan and nothing else**.

The plan is a flat, line-per-chunk checklist. Each line is one chunk.
Each chunk is one burst — about one minute of work. Format is your
choice, but every line must carry: a stable number, a checkbox, a
one-line summary specific enough that someone who was not present
could pick it up cold, and an estimate in bursts if it is not 1.

Example of an acceptable line format:

```
- [ ] 07 · Rewrite the chunker in ingest.py to stream — it currently
       loads the whole file into memory. Done when a 2GB fixture
       processes under 500MB RSS.
```

Rules for the plan, which override your instincts:

1. **Never renumber.** Numbers are permanent addresses. If chunk 07
   turns out to be three chunks, it becomes 07a, 07b, 07c, and you
   stop the burst there rather than starting 07a.
2. **Never delete a chunk.** If it becomes unnecessary, mark it `[~]`
   and append the reason on the same line.
3. **Check off only completed work.** `[x]` means done and verified,
   not attempted. Partial work leaves the box unchecked and gets a
   sub-line beginning `→` describing exactly where it stands.
4. **Estimate honestly and coarsely.** Anything you estimate at more
   than 3 bursts is not a chunk, it is an unplanned section. Split it.
5. A plan longer than 40 chunks means the task was not decomposed,
   it was transcribed. Group into phases and plan only the first
   phase in detail, with later phases as single placeholder chunks.

The plan lives in the file named by `PLAN=` in `.sidepeace`, default
`PLAN.sidepeace.md`. It is the contract. Work that is not on the plan
does not happen; if you discover it must happen, add it as a chunk and
let the next burst take it.

## The state file

`.sidepeace` is a plain text file. Read it first, every burst, before
anything else. Header lines are `KEY=value`:

```
INTERVAL=10
CYCLE=7
TASK=Refactor the ingest pipeline for streaming input
PLAN=PLAN.sidepeace.md
---
CYCLE 6 · finished 05, chunker tests green. Next: 06 needs the fixture
at tests/data/large.jsonl which does not exist yet.
```

Below the `---`, one entry per completed cycle, appended, never
rewritten. Each entry is at most 150 words and must answer: what
changed, what is next, and which file paths a cold reader needs.

150 words is a hard cap because this file is re-read at the start of
every burst for the life of the task. A state file that grows without
bound is the single most expensive thing in this protocol.

## End-of-burst ritual

In this order, no exceptions:

1. Update the plan file: check off what is done, add `→` sub-lines for
   partial work, add any newly discovered chunks at the end.
2. Append one cycle entry to `.sidepeace`, under 150 words.
3. Increment `CYCLE`.
4. **Stop.** End the turn.

## Prohibitions at end of burst

These are the failure modes. Each one feels helpful. None is.

- Do not start the next chunk because the current one finished early.
  Early is the point. Early is savings.
- Do not "just quickly verify" anything after step 3.
- Do not write a summary of the session for the user. The state file
  is the summary. Duplicating it is pure cost.
- Do not offer next steps, ask whether to continue, or propose
  scope changes. The plan already holds those.
- Do not apologize for stopping, explain the protocol back, or
  narrate your compliance with it.

If the work is genuinely blocked — missing credential, ambiguous
requirement, contradictory instruction — record the blocker as the
cycle entry, mark the chunk `[ ]` with a `→ BLOCKED:` sub-line, and
stop. Do not attempt workarounds. A blocked task that waits is cheap;
a blocked agent that improvises is not.

## Ending sidepeace mode

When every chunk is `[x]` or `[~]`, write a final cycle entry reading
`COMPLETE`, then stop. Do not delete `.sidepeace` or the plan. The
human deletes them. Their presence is the only thing keeping the
scheduler's next invocation from being a no-op, and a no-op that
reads two small files is the cheapest possible outcome.
