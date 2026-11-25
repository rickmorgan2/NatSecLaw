# CLAUDE.md

What's true now about this repo. History is in `LOG.md`; decisions are in `DECISIONS.md`.

## Layout

| Path | What it is |
|---|---|
| `natsec-wiki/` | The national security legislation wiki and study guide (version 2). Quarto site built with R. |
| `natsec-wiki/CLAUDE_README.md` | Wiki schema, vocabularies, accuracy rules, watch list and statute inventory. **Read it before editing wiki data.** |
| `natsec-wiki/docs/` | The generated site. Committed, because GitHub Pages publishes it. Never edit by hand. |
| `.github/workflows/pages.yml` | Publishes `natsec-wiki/docs` to https://rickmorgan2.github.io/NatSecLaw/ on any push that changes it (D-001). |
| `LOG.md`, `DECISIONS.md` | Session log (newest first) and decision record. Written by the `close-up-shop` skill. |
| `.claude/skills/close-up-shop/` | End-of-session skill: `/close-up-shop`. |
| `natsec-wiki/parked/members/` | The Crow and Jacobs member lenses, off the site for now (D-017); its README says how to restore them. |
| `CO-06/`, `archive/` | Local only, gitignored (D-008). `archive/natsec-wiki-v1/` is version 1, frozen; do not edit. |

## Run and publish

From `natsec-wiki/`:

- `Rscript R/deploy.R` previews; `render` builds `docs/`; `check` renders and then tests every internal link and, with chromote, key pages at phone width; `serve` serves `docs/` at http://localhost:4321; `zip` writes a shareable zip.
- To publish: `check`, commit including `docs/`, push. The workflow does the rest. No R runs in CI.

## Working rules

- Commit or push only when the owner asks.
- Edit the sources of truth (`data/`, `R/`, `assets/`, `_includes/`, the top-level `.qmd` files), never the generated `statutes/`, `cases/`, `study/units/` or `docs/`.
- Never put the owner's email or other personal details in requests to outside services.
- End a work session with `/close-up-shop`.

## Gotchas

- On Windows, stop `serve` before `render`: the server locks `docs/` and the render fails with os error 32.
- A full render clears `docs/` before rebuilding it, so a render that fails partway leaves `docs/` incomplete. Commit only after `check` passes.
- `R/post_render.R` copies `../archive/natsec-wiki-v1/docs` into `docs/v1` on a full render. On a machine without `archive/` it skips the copy, so `v1/` could drop off the published site. Check `docs/v1/` before committing a render made elsewhere.
- Congress.gov, uscode.house.gov, gao.gov, loc.gov, and several agency sites refuse scripted requests (403); check those links by hand. GovInfo answers scripts and hosts the U.S. Code, the Statutes at Large, public laws, and the bound U.S. Reports, so verify against it.
- On Windows, `Rscript -e` breaks when the code contains `|`; put test code in a file.
- To test on a phone, use chromote device emulation, as the `check` mode does; desktop Chrome's window can't be made narrower than about 500px.
- A publish run can fail at `deploy-pages` with "No artifacts named github-pages"; re-run it from the Actions tab.
- `gh` is not installed. Read Actions run status from the public API: `curl -s "https://api.github.com/repos/rickmorgan2/NatSecLaw/actions/runs?per_page=3"`.
