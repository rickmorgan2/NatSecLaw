# Log

Work log, newest first. One `### <task>` entry per unit of work under each date. Written by `/close-up-shop`. Decisions are in `DECISIONS.md`; current state is in `CLAUDE.md` and `natsec-wiki/CLAUDE_README.md`.

---

## 2026-11-24

### Session log, decision record and close-up-shop skill (uncommitted; D-009)

**Task:** Set the repo up with a log and decision files and adapt the owner's `close-up-shop` skill from another project.

**What changed**
- `.claude/skills/close-up-shop/SKILL.md`: rewritten for this repo. Removed the other project's data checks (Comtrade manifests, DuckDB) and its branding rule. Added: read commits with `natsec-wiki/docs` excluded; the list of source-of-truth versus generated files; evidence means the render build line and whether each fact was verified; keep `natsec-wiki/CLAUDE_README.md` current (watch list, candidates, inventory); never push or render.
- New `CLAUDE.md` (root): layout, run and publish, working rules, gotchas. Points to `natsec-wiki/CLAUDE_README.md` rather than repeating it.
- New `DECISIONS.md`: D-001 to D-008 recorded after the fact from the 2026-11-10 session, plus D-009.
- New `LOG.md`: this file, with the 2026-11-10 work reconstructed below.

**Why / decisions**
- The repo had no `CLAUDE.md`, and the skill keeps one current. It is kept short; the wiki detail already lives in `CLAUDE_README.md`, which is too long to load into every session.

**Open threads**
- Commit `.claude/`, `CLAUDE.md`, `DECISIONS.md` and `LOG.md`: waiting on the owner.
- Review the layer assignments (D-005): they are editorial and have not been checked one by one.
- Jacobs lens, unverified: the bill number for the Security Sector Governance Compacts Act, and whether the Upholding Human Rights Abroad Act's Leahy vetting provision was enacted. Both say so on her page.
- Committee assignments for the 120th Congress, for both members.
- Recheck the watch list in `natsec-wiki/CLAUDE_README.md` (as of 2026-11-10); several sunsets fall in December 2026.
- Congress.gov bill links follow the standard pattern but were never fetched (403 to scripts). Spot-check by hand.
- The Pages workflow's actions target Node 20, which GitHub has deprecated; runs still pass with a warning. Bump action versions when convenient.

## 2026-11-10

### Legends for the study unit graphs (committed in fa420ec)

**Task:** Add a legend to each study unit's "How they connect" graph.

**What changed**
- `mini_graph_legend()` in `natsec-wiki/R/helpers.R` returns HTML listing only the domains (color), statuses (shape) and relationships (line) present among a unit's statutes, with a note on reading arrow direction.
- `R/build_pages.R` writes a second, `results: asis` chunk after each unit's graph. `.mini-legend` styles in `styles.scss`.
- Rendered and checked in a headless Chrome screenshot of Unit 11. All 11 unit pages carry the legend.

**Notes for picking this up**
- The legend sits in its own chunk because printing an htmlwidget from a `results: asis` chunk is unreliable.
- The main graph page has its own, separate legend in `graph.qmd`.

### Stop tracking CO-06/ and archive/ (committed in d7b2464; D-008)

**Task:** Gitignore the district briefs and the version 1 archive.

**What changed**
- Root `.gitignore` gained `CO-06/`, `archive/` and `natsec-wiki/R/local_deploy.R`; 272 files removed from tracking with `git rm --cached` (still on disk).
- Root `README.md` now lists only `natsec-wiki/` and the site link.

### Version 2 of the wiki (committed in 2b4128a and c7defe2; D-002 to D-007)

**Task:** Restore Rep. Crow's name, add a lens for Rep. Jacobs, add a current-law switch, fix the Statutes filter and the graph-to-table link, add a study-guide hierarchy and civilian harm content, link everything to official sources, and archive version 1.

**What changed**
- Moved the wiki to `natsec-wiki/`; froze version 1 in `archive/natsec-wiki-v1/` and publish it under `v1/` via `R/post_render.R`.
- Rewrote `R/helpers.R` and `R/build_pages.R`: layers, eras, official link builders, validation, generated statute pages, member lens stubs, study units, source manifests.
- New pages: `members/` (two lenses and a comparison), `study/` (overview, 11 units, flashcards, timeline, glossary), `sources.qmd`. New `assets/graph.js` and `_includes/site.html`.
- Data: a `layer` on every statute; new `08_civilian_harm.yml` (5 statutes); 10 new edges; `data/members/crow.yml` and `jacobs.yml`; `data/study/units.yml`; `data/research_sources.csv`.
- Final build: 87 statute pages, 2 member lenses, 11 study units, 167 edges, 266 source links (235 official).
- Link check: 207 of 225 URLs returned 200. The 17 that returned 403 were Congress.gov (blocks scripts) and one news site; the one 404 (Crow press-release index) was fixed.

**Why / decisions**
- The "No Matching Items" bug: Quarto splits listing categories at commas, so "Foreign aid, fragility and sanctions" became two categories. Categories now use `domain_short`, which has no commas.
- The graph and the "Every connection" table were not linked at all. The table is now filtered from the graph's selection through a DataTables search function.

**What failed**
- vis.js hierarchical layout for the "Authority layers" view was unreadable; replaced with a hand-built band layout in `assets/graph.js`.
- Looking up the vis network on the widget object crashed the controller. It lives at `document.getElementById("graph" + el.id).chart`.
- `quarto preview --no-render` re-ran the pre-render build on every request; `serve` uses `servr::httd` on `docs/` instead.
- Sentence cuts at "U.S." and "U.N." in card blurbs; `first_sentence()` now skips abbreviations and requires 90 characters.

### Local runner and GitHub Pages publishing (committed in 2b4128a and c7defe2; D-001)

**Task:** One script to run the wiki locally, and a way to share it with people who won't run code.

**What changed**
- `natsec-wiki/R/deploy.R`: modes `preview`, `render`, `serve`, `zip`. It finds Quarto (PATH, `QUARTO_PATH`, the `quarto` package, RStudio and Positron bundles), requires Quarto 1.4 or later, and installs missing packages.
- `.github/workflows/pages.yml` publishes `natsec-wiki/docs`.

**What failed**
- `shQuote()` on the Quarto path breaks `system2()` on Windows; it now quotes only on other systems.
- The first Pages run failed at `configure-pages` ("Get Pages site failed ... Not Found") because the push came before Pages was set to "GitHub Actions". A manual re-run after the setting was changed succeeded.
