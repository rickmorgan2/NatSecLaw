# Log

Work log, newest first. One `### <task>` entry per unit of work under each date. Written by `/close-up-shop`. Decisions are in `DECISIONS.md`; current state is in `CLAUDE.md` and `natsec-wiki/CLAUDE_README.md`.

---

## 2026-11-24

### Hill audience, power of the purse, programs, court cases, Who's who, study tools (committed in 8f9d9dd; D-010 to D-016)

**Task:** Retarget the wiki to congressional staff, members, and interns, and add appropriations, security assistance programs, Supreme Court cases, a Who's who page, and study and quality tools. Case studies were declined for now (D-016).

**What changed**
- Data:
  - `data/statutes/09_purse.yml`, new domain `purse`, 8 entries: `defense-approps-annual`, `sfops-approps-annual`, `sec8005-transfer`, `sec7008-coup`, `case-church-1973`, `boland-1982`, `impoundment-1974`, `antideficiency`.
  - `data/statutes/10_programs.yml`, 7 entries with a new `funding` field: `fms`, `fmf`, `imet`, `pko-551`, `pda-506`, `eda-516`, `usai-2016`.
  - 35 new edges, using the new relations `part_of` and `funded_by`.
  - `data/cases.yml`: 12 Supreme Court cases, each with a Wikipedia link (owner's request).
  - `data/institutions.yml`: 28 Who's who entries. An FFRDC entry was added, then dropped at the owner's request.
  - `units.yml`:
    - new Unit 4, "The power of the purse"; old units 4 to 11 are now 5 to 12;
    - programs added to the assistance and arms transfer units;
    - case readings in 5 units;
    - 13 new key terms;
    - 31 Issues for Congress across all 12 units.
  - Member lenses: Jacobs's House Foreign Affairs seat gains `fmf`, `imet`, `pko-551` and `sec7008-coup`. Crow's Armed Services seat gains `usai-2016`, and his No Funds for Iran War Act item gains `defense-approps-annual` and `case-church-1973`.
- Code:
  - `R/helpers.R`: case and Who's who loaders, `usreports_url()`, wiki links that resolve to cases, a `checked` date defaulting to `wiki_reviewed` (2026-11-10).
  - `R/build_pages.R`: funding, "In the courts", "Who's involved", and "Last checked" sections on statute pages; generated `cases/*.qmd` and `cases/index.qmd`; Issues for Congress on unit pages; new validation checks.
  - Graph (`graph.qmd`, `assets/graph.js`): cases drawn as diamonds, with a Court cases switch and their own band in the layers view.
  - Flashcards: case cards and 5-box spaced review (localStorage `wiki-box-<id>`; old `wiki-card-<id>` marks start in box 2).
  - Timeline: includes cases.
  - New files: `whos-who.qmd`, and `R/check_site.R` behind `Rscript R/deploy.R check`.
  - Styles: print layout.
  - Navbar: Court cases, plus a Reference menu.
- Tone rewrite (D-010): the home page, the study guide overview ("Studying as a group" became "Using this guide in an office", with units mapped to committees), and the About page.
- Build: "Built 102 statute pages, 12 case pages, 28 who's who entries, 2 member lenses, 12 study units, 202 edges, 370 source links (327 official)."
- Check: 141 pages, 0 broken internal links; 11 pages at 390px, 0 problems. A separate scan of 16 pages at 390 and 1280px found no JavaScript errors.

| New fact | Verified against |
|---|---|
| Program sections, Antideficiency Act, Impoundment Control Act | GovInfo U.S. Code text and source credits |
| Sec. 8005 ($6B cap), Sec. 7008 text, FY2026 act titles, IMET/FMF/PKO accounts | Pub. L. 119-75 on GovInfo |
| FY2027 continuing resolution through December 11, 2026 | Pub. L. 119-103 on GovInfo |
| Ukraine initiative extended to 2029 | Pub. L. 119-60, Sec. 1243, on GovInfo |
| Case-Church (87 Stat. 129), Boland II (98 Stat. 1935), series anchors (63 Stat. 987; 75 Stat. 717) | Statutes at Large PDFs on GovInfo |
| 12 case citations and holdings; quoted passages | U.S. Reports PDFs on GovInfo; Learning Resources slip opinion on supremecourt.gov |
| Niger coup determination (2023), 2025 rescissions, Learning Resources aftermath | Web search: VOA editorial, Supreme Court docket 25A269, GAO WatchBlog, news |
| 16 U.S. Code sections cited in Who's who; 12 Wikipedia URLs | Fetched; headings and titles match |

**Why / decisions**
- D-010 to D-016 record the owner's choices. D-014 was amended when FFRDCs were dropped.
- Programs enter through their authorizing sections (D-011), so the funding field ties them to an appropriations series without tracking dollars.
- The appropriations series are anchored to their first acts: 1949 for Defense, 1961 for foreign assistance. Sec. 7008 and Sec. 8005 are dated 2026, the act verified, because their first enactment wasn't found.
- Trump v. Hawaii was left out: it turns on the immigration act, which isn't in the wiki.
- "Issues for Congress" was Claude's framing of the approved "discussion prompts" for a Hill audience.

**What failed**
- The Library of Congress U.S. Reports pages and supremecourt.gov (with a plain user agent) block scripts. GovInfo's USREPORTS PDFs work, and supremecourt.gov answers a full browser user agent.
- whitehouse.gov/nsc/ and a State Department bureau path returned 404, so those Who's who entries cite the creating U.S. Code section instead.
- Three first-draft errors were caught by reading the opinions:
  - Youngstown's Defense Production Act point is in the majority opinion, not Jackson's concurrence.
  - The "first time" claims in Boumediene and Zivotofsky come from the dissents.
- The publish run for 8f9d9dd failed at `deploy-pages` ("No artifacts named github-pages"). A manual re-run succeeded.

**Open threads**
- Review the 31 Issues for Congress for balance (owner).
- Unverified in the wiki:
  - Boland I is cited by public law only (97-377); its section is not verified.
  - First enactment of Sec. 7008 and Sec. 8005.
  - The account that funds the Ukraine initiative; the FY2026 Defense act doesn't name it.
  - Who's who role text, written from reference knowledge.
- Review the layer assignments (D-005), which are editorial.
- Jacobs lens: the Security Sector Governance Compacts Act bill number, and whether the Upholding Human Rights Abroad Act's Leahy provision was enacted.
- Committee assignments for the 120th Congress, for both members.
- Watch list in `natsec-wiki/CLAUDE_README.md` (November 10 list plus the November 24 additions). The FY2027 continuing resolution expires December 11, 2026.
- Congress.gov and CRS links were never fetched (403 to scripts); spot-check by hand.
- Pages workflow: the actions target the deprecated Node 20, and one deploy failed transiently. Bump action versions if it recurs.
- The local server is not running.

**Notes for picking this up**
- For ad hoc phone testing, use chromote device emulation (`Emulation.setDeviceMetricsOverride`, `mobile = TRUE`). Desktop Chrome's window can't go below about 500px.
- `pdftotext` is available for reading Statutes at Large PDFs from the GovInfo statute link service.

### Dead graph links, phone layout, plain-language note (committed in 58a71ce)

**Task:** Fix a dead link on every statute page, make the site work on phones including the graph, and rewrite the Title 10/50 page's "Limits of this page" in plain language.

**What changed**
- All 87 statute pages linked `../graph.qmd?focus=<id>`, which 404s. `R/build_pages.R` now writes `graph.html`.
- Phone layout:
  - a short title in the top bar;
  - wide tables scroll inside their own box (`wrapTables()` in `_includes/site.html`);
  - columns hidden on phones in the statute list and the units table;
  - flashcards: a 2×2 button grid and swipe;
  - "hover" and "click" wording changed to work on touch screens.
- Graph:
  - the canvas sizes itself to the phone;
  - details open in a panel that slides up from the bottom;
  - selecting a line explains the link;
  - a full-screen button on the canvas;
  - the layers view uses 3 columns and fits to width on phones;
  - the connections table shows one sentence-style Connection column on phones, with the note in a tappable row (DT Responsive);
  - `net.fit` is patched so the graph refits only when the width changes, not when a phone's address bar shows or hides.
- Desktop fix: the Authority layers view resizes its container instead of spilling over the legend.
- Unit and member graphs show an "Open its page" caption under the graph.
- Title 10/50 page: "Limits of this page" became "Before you rely on this".
- Result: 14 pages at 390px with no overflow, and no JavaScript errors at 390 or 1280px.

**What failed**
- Desktop headless Chrome at `--window-size=390` gave misleading screenshots; phone emulation is required.
- DT Responsive at first dropped the Relationship column on phones; replaced with a single Connection column.

### Session log, decision record and close-up-shop skill (committed in 5b76350; D-009)

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
