# CLAUDE.md

What's true now about this repo. History is in `LOG.md`; decisions are in `DECISIONS.md`.

## Layout

| Path | What it is |
|---|---|
| `natsec-wiki/` | The national security legislation wiki and study guide (version 2). Quarto site built with R. |
| `natsec-wiki/CLAUDE_README.md` | Wiki schema, vocabularies, accuracy rules, watch list and statute inventory. **Read it before editing wiki data.** |
| `natsec-wiki/docs/` | The generated site. Committed, because GitHub Pages publishes it. Never edit by hand. |
| `.github/workflows/pages.yml` | Publishes `natsec-wiki/docs` to https://rickmorgan2.github.io/house-knowledge/ on any push that changes it (D-001). |
| `LOG.md`, `DECISIONS.md` | Session log (newest first) and decision record. Written by the `close-up-shop` skill. |
| `.claude/skills/close-up-shop/` | End-of-session skill: `/close-up-shop`. |
| `CO-06/`, `archive/` | Local only, gitignored (D-008). `archive/natsec-wiki-v1/` is version 1, frozen; do not edit. |

## Run and publish

From `natsec-wiki/`:

- `Rscript R/deploy.R` previews; `render` builds `docs/`; `serve` serves `docs/` at http://localhost:4321; `zip` writes a shareable zip.
- To publish: render, commit including `docs/`, push. The workflow does the rest. No R runs in CI.

## Working rules

- Commit or push only when the owner asks.
- Edit the sources of truth (`data/`, `R/`, `assets/`, `_includes/`, the top-level `.qmd` files), never the generated `statutes/`, `study/units/`, `members/<slug>.qmd` or `docs/`.
- Never put the owner's email or other personal details in requests to outside services.
- End a work session with `/close-up-shop`.

## Gotchas

- On Windows, stop `serve` before `render`: the server locks `docs/` and the render fails with os error 32.
- `R/post_render.R` copies `../archive/natsec-wiki-v1/docs` into `docs/v1` on a full render. On a machine without `archive/` it skips the copy, so `v1/` could drop off the published site. Check `docs/v1/` before committing a render made elsewhere.
- Congress.gov and uscode.house.gov refuse scripted requests (403); check those links by hand.
- `gh` is not installed. Read Actions run status from the public API: `curl -s "https://api.github.com/repos/rickmorgan2/house-knowledge/actions/runs?per_page=3"`.
