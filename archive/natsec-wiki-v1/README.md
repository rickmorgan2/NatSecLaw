# U.S. National Security Legislation Wiki

A Quarto website: one wiki page per statute, an interactive knowledge graph of how the statutes relate, and a manifest of every document and source link.

## Run it locally

Requirements: R 4.1 or later and [Quarto](https://quarto.org) 1.4 or later. The copy of Quarto bundled with RStudio or Positron is enough; it does not need to be on your PATH. `R/deploy.R` finds Quarto and installs any missing R packages.

From the project folder:

```bash
Rscript R/deploy.R          # render, then serve at http://localhost:4321 with live reload
Rscript R/deploy.R render   # build the static site into docs/
Rscript R/deploy.R serve    # serve the existing docs/ without rebuilding
Rscript R/deploy.R zip      # render, then write natsec-wiki-site.zip for offline sharing
```

From RStudio or Positron, `source("R/deploy.R")` runs the preview; set `options(deploy.mode = "render")` first for another mode. Set `QUARTO_PATH` to force a specific Quarto binary, or `WIKI_PORT` to change the port.

Full-text search needs a server, so it does not work when `docs/index.html` is opened straight from disk (for example from the zip). Everything else does.

The site makes no network requests, so it works offline. Links to primary sources need a connection.

## Host it on GitHub Pages

The site is static, so GitHub Pages can serve it for free, and readers need nothing but a browser. The wiki sits in a subfolder of the `house-knowledge` repo, so Pages cannot serve it directly. Instead, the workflow `.github/workflows/pages.yml` at the repo root publishes `CO-06/natsec-wiki/docs`. No R runs on GitHub; it publishes the `docs/` you built locally.

One-time setup: on github.com open the repository's Settings, then Pages, and under "Build and deployment" set Source to "GitHub Actions". The site is then live at `https://rickmorgan2.github.io/house-knowledge/`. Pages on a private repository needs a paid GitHub plan; on a free account the repository must be public.

To update the site: edit files in `data/`, run `Rscript R/deploy.R render`, then commit (including `docs/`) and push. The workflow runs on any push to `main` that changes `docs/`, and can also be started by hand from the Actions tab.

Before publishing, note that a GitHub Pages site is public even when it is built from a private repository, unless the account is on an Enterprise plan with private Pages. Anyone with the address can read it, so check citations first and keep the "independent reference" notices in place.

## Tailor it to a member

`member.qmd` (the "Member lens" page) is generated from `data/member.yml`: committees, initiatives, and district interests, each listing the statute IDs it touches. Edit that file to update the lens or to point the wiki at a different member.

## How it is organized

| Path | What it is |
|---|---|
| `data/statutes/*.yml` | All wiki content. One entry per statute, in files grouped by domain, plus one for Title 10 operational authorities and one for foundations. |
| `data/edges.csv` | The knowledge graph. One row per relationship. |
| `data/reference_sources.csv` | General reference sources shown in the manifest. |
| `data/member.yml` | The member the wiki is tailored to. Drives the Member lens page. |
| `R/helpers.R` | Data loading, vocabularies, colors, citation link builders. |
| `R/build_pages.R` | Validates the data, writes `statutes/*.qmd` and the manifest CSVs. Quarto runs it before every render. |
| `R/deploy.R` | Local runner: finds Quarto, installs packages, then previews, renders, serves, or zips the site. |
| `statutes/*.qmd` | Generated pages. Do not edit by hand. |
| `index.qmd`, `graph.qmd`, `title10-title50.qmd`, `member.qmd`, `manifest.qmd`, `about.qmd` | Top-level pages. |
| `docs/` | Generated site. Commit it; GitHub Pages serves it. |
| `styles.scss` | Theme. Domain colors here must match `R/helpers.R`. |
| `CLAUDE_README.md` | Context file for working on the project in a Claude session. |

## Add or change a statute

1. Copy an existing entry in `data/statutes/` and edit it.
2. Add rows to `data/edges.csv`.
3. Run `quarto preview`. The build stops with a named error if an ID, domain, status, relationship, or `[[wiki link]]` is not recognized.

## Accuracy

Summaries were drafted with Claude and reviewed on November 10, 2026. Recent status changes were checked against current reporting. Citations and section numbers were not each checked against the primary text, and the generated GovInfo and Cornell links were not individually tested. Verify before citing. Not legal advice.
