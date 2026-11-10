# U.S. National Security Legislation Wiki

A Quarto website: one wiki page per statute, an interactive knowledge graph of how the statutes relate, and a manifest of every document and source link.

## Run it locally

Requirements: [Quarto](https://quarto.org) 1.4 or later, R 4.1 or later, and these packages:

```r
install.packages(c("yaml", "dplyr", "purrr", "readr", "stringr", "tibble", "knitr", "rmarkdown", "DT", "visNetwork"))
```

From the project folder:

```bash
quarto preview    # builds the site and serves it at a local address with live reload
quarto render     # builds the static site into docs/
```

A prebuilt copy is already in `docs/`. To browse it without rebuilding, serve that folder (full-text search needs a local server and will not work from a `file://` address):

```r
servr::httd("docs")
```

The site makes no network requests, so it works offline. Links to primary sources need a connection.

## Host it on GitHub Pages

The site is static, so GitHub Pages can serve it for free. The project renders into `docs/`, which Pages can publish directly, so no build runs on GitHub and it needs no R setup there.

1. Create a new repository on github.com (no README, no .gitignore).
2. Put this folder under version control and push it. With GitHub Desktop: File, Add Local Repository, choose this folder, then Publish. From a terminal:

   ```bash
   git init
   git add .
   git commit -m "Initial site"
   git branch -M main
   git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
   git push -u origin main
   ```

3. On github.com open the repository's Settings, then Pages. Under "Build and deployment" choose "Deploy from a branch", branch `main`, folder `/docs`, and save.
4. After a minute or two the site is live at `https://YOUR-USERNAME.github.io/YOUR-REPO/`.

To update the site: edit files in `data/`, run `quarto render`, then commit and push. The `docs/` folder must be committed, because it is what Pages serves.

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
