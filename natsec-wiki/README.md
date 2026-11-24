# U.S. National Security Legislation Wiki (version 2)

A Quarto website and study guide for congressional staff and interns: one wiki page per statute and per Supreme Court case, a twelve-unit curriculum, an interactive knowledge graph, a Who's who page, and a Sources page listing everything the wiki draws on. Every statute and case links to its official text.

Version 1 is archived unchanged in `../archive/natsec-wiki-v1/` and published under `v1/`.

## Run it locally

Requirements: R 4.1 or later and [Quarto](https://quarto.org) 1.4 or later. The copy of Quarto bundled with RStudio or Positron is enough; it does not need to be on your PATH. `R/deploy.R` finds Quarto and installs any missing R packages.

From this folder:

```bash
Rscript R/deploy.R          # render, then serve at http://localhost:4321 with live reload
Rscript R/deploy.R render   # build the static site into docs/
Rscript R/deploy.R serve    # serve the existing docs/ as static files, no rebuild
Rscript R/deploy.R zip      # render, then write natsec-wiki-site.zip for offline sharing
```

From RStudio or Positron, `source("R/deploy.R")` runs the preview; set `options(deploy.mode = "render")` first for another mode. Set `QUARTO_PATH` to force a specific Quarto binary, or `WIKI_PORT` to change the port.

Stop `serve` before running `render`: on Windows the server holds `docs/` open and Quarto cannot replace it.

Full-text search needs a server, so it does not work when `docs/index.html` is opened straight from disk (for example from the zip). Everything else does. The site makes no network requests, so it works offline; links to official sources need a connection.

## Host it on GitHub Pages

The workflow `.github/workflows/pages.yml` at the repo root publishes `natsec-wiki/docs`. No R runs on GitHub; it publishes the `docs/` you built locally, including `docs/v1`.

One-time setup: on github.com open the repository's Settings, then Pages, and under "Build and deployment" set Source to "GitHub Actions". The site is then live at `https://rickmorgan2.github.io/house-knowledge/`. Pages on a private repository needs a paid GitHub plan; on a free account the repository must be public.

To update the site: edit files in `data/`, run `Rscript R/deploy.R render`, then commit (including `docs/`) and push. The workflow runs on any push to `main` that changes `docs/`, and can also be started by hand from the Actions tab.

A GitHub Pages site is public even when it is built from a private repository, unless the account is on an Enterprise plan with private Pages. Keep the "independent reference" notices in place.

## How it is organized

| Path | What it is |
|---|---|
| `data/statutes/*.yml` | All statute content, one entry per statute, in files grouped by domain. Each entry has a `layer`. |
| `data/edges.csv` | The knowledge graph. One row per relationship. |
| `data/study/units.yml` | The study guide's units. |
| `data/reference_sources.csv`, `data/research_sources.csv` | General references, and sources consulted for this edition. |
| `R/helpers.R` | Data loading, vocabularies, layers, eras, colors, official link builders. |
| `R/build_pages.R` | Validates the data, writes the statute, member, and unit pages, the site data, and the manifests. Quarto runs it before every render. |
| `R/post_render.R` | Copies the archived version 1 into `docs/v1` after a full render. |
| `R/deploy.R` | Local runner: finds Quarto, installs packages, then previews, renders, serves, or zips the site. |
| `assets/graph.js` | The knowledge graph's controls (domain focus, layered view, linked table). |
| `_includes/site.html` | Site-wide script: the "Current law only" switch, historic link marks, study progress. |
| `statutes/*.qmd`, `cases/*.qmd`, `study/units/*.qmd` | Generated pages. Do not edit by hand. |
| `parked/members/` | The Crow and Jacobs member lenses, off the site for now (D-017); see its README to restore them. |
| `study/index.qmd`, `study/flashcards.qmd`, `study/timeline.qmd`, `study/glossary.qmd` | Study guide pages. |
| `index.qmd`, `graph.qmd`, `title10-title50.qmd`, `sources.qmd`, `manifest.qmd`, `about.qmd` | Top-level pages. |
| `docs/` | Generated site. Commit it; GitHub Pages serves it. |
| `styles.scss` | Theme. Domain colors here must match `R/helpers.R`. |
| `CLAUDE_README.md` | Context file for working on the project in a Claude session. |

## Add or change a statute

1. Copy an existing entry in `data/statutes/` and edit it, including `layer`.
2. Add rows to `data/edges.csv`.
3. Add the statute to a unit in `data/study/units.yml`.
4. Run `Rscript R/deploy.R`. The build stops with a named error if an ID, domain, layer, status, relationship, or `[[wiki link]]` is not recognized.

## Accuracy

Summaries were drafted with Claude and reviewed on November 10, 2026. Recent status changes were checked against current reporting. The civilian harm entries were checked against the GovInfo text of the U.S. Code and bill numbers against GovInfo bill status records. Other citations and section numbers were not each checked against the primary text. Every source link was requested on November 10, 2026: GovInfo, House, and other links resolved; Congress.gov refuses automated requests, so its links follow its documented URL pattern but were not fetched. Verify before citing. Not legal advice.
