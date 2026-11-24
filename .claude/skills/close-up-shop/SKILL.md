---
name: close-up-shop
description: Session wrap-up for this repo (house-knowledge: the U.S. national security legislation wiki and study guide in natsec-wiki/). Use at the end of a work session, or before compacting, to write a durable record of the most recent work. Triggers on "close up shop", "let's close up shop", "/close-up-shop", "write a session summary", "session notes", "update the log", or similar. Summarizes work since the last LOG.md entry (not the whole session), adds a dated entry at the top of LOG.md, and updates DECISIONS.md, CLAUDE.md and natsec-wiki/CLAUDE_README.md if the session changed what they describe. Never commits or pushes.
---

# Close up shop

Purpose: leave a durable, accurate record of the work just done, so the next
session can start from the files rather than from `/compact`.

This skill writes only to these tracked files:

- `LOG.md` (repo root): dated work log, **newest first**. Each `## YYYY-MM-DD`
  heading holds one `### <task>` entry per unit of work. This is where the
  session record goes.
- `DECISIONS.md` (repo root): one `D-0xx` entry per decision, newest at the
  bottom, each with a status (Accepted / Proposed / Open / Superseded).
- `CLAUDE.md` (repo root): what's true now about the repo: layout, how to run
  and publish, working rules, gotchas. Short. Edited in place, never appended
  to as a history.
- `natsec-wiki/CLAUDE_README.md`: what's true now about the wiki: data schema,
  vocabularies, accuracy rules, the **watch list**, candidates not yet
  included, and the **current inventory** of statute IDs with totals. Edited
  in place.

The session record never goes in `natsec-wiki/docs/` (the generated site),
`archive/` or `CO-06/` (both local only and gitignored, D-008).

## Scope: summarize since the last LOG entry, not the whole session

1. Read the top of `LOG.md`. The newest entry is the first `###` under the
   first `##` date heading. Note its date, its title (which says whether the
   work was committed and which D-IDs it touched), and its **Open threads**.
2. Establish what happened since then. The owner commits and pushes
   themselves, usually with short messages ("tweaking"), and Claude commits
   only when asked. So the commit messages rarely explain anything; this log
   is where the why lives. Check both:
   - `git log --oneline --since="<entry date>"` for commits since. Commits
     usually bundle the rebuilt site, so read them with the generated files
     left out:
     `git show --stat <sha> -- . ':!natsec-wiki/docs'`.
   - `git status --short` and
     `git diff --stat -- . ':!natsec-wiki/docs'` for uncommitted work. Read
     the full diff where it matters. Untracked files show only in
     `git status`; read the new ones.
   - The real changes are in the sources of truth: `natsec-wiki/data/`
     (statutes YAML, `edges.csv`, `members/*.yml`, `study/units.yml`, source
     CSVs), `natsec-wiki/R/`, `assets/`, `_includes/`, the top-level `.qmd`
     pages, `styles.scss`, `_quarto.yml`, and `.github/workflows/`. Files under
     `natsec-wiki/statutes/`, `natsec-wiki/study/units/`,
     `natsec-wiki/members/<slug>.qmd`, `data/manifest_*.csv`,
     `data/all_sources.csv` and `docs/` are generated; describe the source
     change, not the regenerated output.
   - Combine this with the conversation. Prefer the files to memory: the
     session may already have been compacted, and the diff is ground truth.
3. If the newest entry is today's and covers the same task, update that entry
   in place. Do not add a near-duplicate. Otherwise write a new entry.

## Write the LOG entry

Put it directly under today's `## YYYY-MM-DD` heading, above any entries
already there. If today has no heading yet, add one at the top, just below the
`---` that follows the file header.

```
### <Task name> (<uncommitted | committed in abc1234>; D-0xx, D-0yy)

**Task:** one line: what this unit of work was aimed at.

**What changed**
- Concrete changes: files, functions, data entries, pages.

**Why / decisions**
- ...

**What failed**
- ...

**Open threads**
- ...

**Notes for picking this up**
- ...
```

- **What changed:** name the key files, functions and statute or member IDs.
  Give the numbers: the build line that `Rscript R/deploy.R render` prints
  ("Built N statute pages, N member lenses, N study units, N edges, N source
  links (N official)"), statutes and edges added, link-check results. For
  every fact added to the wiki or a member lens, say whether it was verified
  and against what (GovInfo text, BILLSTATUS, the member's House site). The
  owner wants evidence, not adjectives.
- **Why / decisions:** the reasons behind non-obvious choices, and the
  constraints and trade-offs that shaped them. Keep what was *decided* apart
  from what was only *suggested or explored*. Do not promote a suggestion the
  owner reacted well to into a decision. Point to the D-ID wherever one
  applies.
- **What failed:** each approach tried and rejected, with its reason, so a
  later session doesn't explore the same dead end again. Never skip it when
  there were dead ends.
- **Open threads:** the complete list of what's unfinished. Carry forward
  every thread from the previous entry's Open threads that is still open, drop
  the ones this session closed, and add new ones. Include unverified facts
  left in the wiki, anything waiting on the owner (review, commit, push, a
  GitHub setting), and whether the local server is still running. Watch-list
  items for statute status live in `CLAUDE_README.md`; refer to that list
  rather than copying it. The newest entry's list should be all a fresh
  session needs to know what's pending.
- **Notes for picking this up:** non-obvious gotchas that fit nowhere else.
- Leave out any section with nothing to say, except **Open threads**.

Match the existing entries: short bullets, tables for numbers, plain words.
Members are named (D-003); describe their record neutrally, as the wiki does.
Never include the owner's email address or other personal details.

## What not to capture

The test: reading only the code, the data and the commit messages, would a
stranger understand this? If yes, skip it. If no, capture it. Specifically
skip:

- Changes self-evident from the diff.
- Decisions already documented in code comments, `CLAUDE_README.md` or
  DECISIONS.md. Reference them by ID instead.
- Standard patterns that need no explanation.

Prefer accuracy to completeness. If something is uncertain, say so rather
than invent detail.

## Update DECISIONS.md

- When the owner explicitly agreed to something new, add an entry at the
  bottom with the next free ID and the usual fields: **Date**, **Status**,
  **Context**, **Decision**, **Consequences**.
- When something was recommended but not agreed, record it as **Proposed**.
- When the session carried out, changed or replaced an existing decision,
  edit that entry's **Status** line. Examples: "Implemented in `R/x.R`, not yet
  committed"; "Superseded by D-0xx".

## Update CLAUDE.md and CLAUDE_README.md

Edit in place, and only where the session changed something they describe as
current. History stays in LOG.md.

- `CLAUDE.md`: a path, how to run or publish, a working rule, or a gotcha
  every session needs.
- `natsec-wiki/CLAUDE_README.md`:
  - schema, vocabulary, layer or relation changes;
  - the **watch list**: update its "as of" date and items when a status was
    rechecked, and add new laws in flux;
  - **candidates not yet included**: remove any that were added;
  - **current inventory**: when statutes were added, removed, retitled or
    moved, rebuild the tables and the totals line from `load_statutes()` and
    `load_edges()` rather than by hand.

## Before writing

Show the owner the drafted LOG entry and any DECISIONS.md, CLAUDE.md or
CLAUDE_README.md edits for a quick review, and apply their changes. You
remember more of the session than they want to reconstruct, so they should be
editing a draft, not rebuilding it.

## After writing

Report the LOG entry's heading, the D-IDs added or updated, and any CLAUDE.md
or CLAUDE_README.md lines changed. Do not commit or push: leave everything in
the working tree for the owner. Do not render the site. Do not run `/compact`;
leave that to the owner.
