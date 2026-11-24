# Decisions

One entry per decision, newest at the bottom. Status is one of Accepted, Proposed, Open or Superseded. Entries D-001 to D-008 were recorded after the fact on 2026-11-24 from the 2026-11-10 session.

---

## D-001: Share the wiki as a public GitHub Pages site

- **Date:** 2026-11-10
- **Status:** Accepted. Live at https://rickmorgan2.github.io/house-knowledge/.
- **Context:** The owner's friends will not install R or run code. Options offered were a public Pages link, a private host, or a zip of the built site; the owner chose the public link.
- **Decision:** Commit the built site in `natsec-wiki/docs/`. `.github/workflows/pages.yml` uploads that folder with `upload-pages-artifact` and deploys it. No R or Quarto runs in CI. Pages source is set to "GitHub Actions".
- **Consequences:** The site and repo are public. Every content change needs a local render before the commit. The root `.gitignore` no longer ignores `docs/`.

## D-002: Version 2 lives at natsec-wiki/; version 1 is archived

- **Date:** 2026-11-10
- **Status:** Accepted.
- **Context:** The owner asked for a new version and for the current one to be archived.
- **Decision:** Move the wiki from `CO-06/natsec-wiki/` to `natsec-wiki/` at the repo root. Freeze version 1 in `archive/natsec-wiki-v1/`, with its built site, and publish it under `v1/` by copying it in `R/post_render.R`.
- **Consequences:** Version 1 is never edited. See D-008 for why the archive is now local only.

## D-003: Members are named; Crow and Jacobs lenses share one site

- **Date:** 2026-11-10
- **Status:** Accepted.
- **Context:** Version 1 identified its one member by district only. The owner asked to restore Rep. Jason Crow's name and to add a version for Rep. Sara Jacobs.
- **Decision:** Name members. Each lens is a data file (`data/members/<slug>.yml`) rendered by one shared page (`members/_lens.qmd`), plus a comparison page, inside the same site, rather than a separate site per member.
- **Consequences:** One set of statute data serves both lenses. Shared record items use the same `id` in both files. Every claim about a member needs a public source; lenses stay descriptive and say they are not affiliated with the member's office.

## D-004: Link to official sources

- **Date:** 2026-11-10
- **Status:** Accepted.
- **Context:** The owner asked that everything link to the original official source, with a page listing every source.
- **Decision:** Build links from citations in `R/helpers.R`: GovInfo for public laws, the Statutes at Large and the U.S. Code; Congress.gov for bills. Drop Cornell LII as the primary link. A Sources page lists every link and marks .gov and .mil hosts as official.
- **Consequences:** Statute entries carry citations, not URLs. Congress.gov links cannot be machine-checked (403 to scripts).

## D-005: Organize the study guide by an authority hierarchy

- **Date:** 2026-11-10
- **Status:** Accepted and implemented. The layer given to each statute is an editorial judgment the owner has not reviewed one by one.
- **Context:** The owner asked whether there is a hierarchy and how the wiki could work as a study guide for them and their friends.
- **Decision:** Three hierarchies: authority (five layers: constitution, framework, authorizing, provision, code), codification (U.S. Code titles), and time (eras). Every statute gets a `layer`. The study guide has 11 ordered units with reading paths, terms and review questions, plus flashcards, a timeline and a glossary. Progress is saved in each reader's browser.
- **Consequences:** New statutes need a `layer` and a unit. Layer definitions live in `layer_desc` in `R/helpers.R`.

## D-006: Civilian harm is its own domain and study unit

- **Date:** 2026-11-10
- **Status:** Accepted.
- **Context:** The owner asked to include civilian harm reduction.
- **Decision:** Add the `civilian-protection` domain with five statutes (Foreign Claims Act; FY2018 NDAA Sec. 1057; FY2019 Sec. 936; FY2020 Sec. 1213; 10 U.S.C. 184), Unit 11, and both members' civilian harm records.
- **Consequences:** Civilian harm is a standing priority for new content and for the watch list.

## D-007: A site-wide "Current law only" switch

- **Date:** 2026-11-10
- **Status:** Accepted.
- **Context:** The owner asked for a toggle that removes repealed or superseded laws.
- **Decision:** One switch in the navbar, remembered in the browser, hides statutes with status `repealed` or `superseded` from lists, tables, graphs and flashcards, and marks links to them with a dagger. `partly-expired` and `lapsed` stay visible.
- **Consequences:** Generated tables mark the row's subject link `{.subj}`, and other elements use `data-statute`, so the switch can find them.

## D-008: CO-06/ and archive/ are local only

- **Date:** 2026-11-10
- **Status:** Accepted. Done in d7b2464.
- **Context:** The owner asked to gitignore both folders.
- **Decision:** Gitignore `CO-06/`, `archive/` and the leftover `natsec-wiki/R/local_deploy.R`, and stop tracking them. They remain in git history.
- **Consequences:** Version 1 stays on the site because `natsec-wiki/docs/v1/` is committed. A full render on a machine without `archive/` skips the copy, so `v1/` could drop from the site.

## D-009: Keep a session log and decision record

- **Date:** 2026-11-24
- **Status:** Accepted. Not yet committed.
- **Context:** The owner brought over a `close-up-shop` skill from another project and asked for log and decision files here.
- **Decision:** `LOG.md` (newest first) and `DECISIONS.md` at the repo root, a short root `CLAUDE.md` for what's true now, and `.claude/skills/close-up-shop/` to write them at the end of a session. Wiki-specific current state stays in `natsec-wiki/CLAUDE_README.md`.
- **Consequences:** Sessions end with `/close-up-shop`. Commit messages can stay short, because the reasons go in the log.
