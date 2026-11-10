# CLAUDE_README: U.S. National Security Legislation Wiki (version 2)

Paste or attach this file at the start of a Claude session to work on this project. It describes what the project is, how the data is structured, and the rules to follow when extending it.

## What this project is

A Quarto website, rendered with R, hosted locally or on GitHub Pages, that works as a wiki, study guide, and knowledge graph of U.S. national security statutes and the foreign policy laws they connect to. It has these parts:

- A wiki: one page per statute, each linked to its official text on GovInfo.
- A study guide: an authority stack (every statute placed in a layer), eleven ordered units with reading paths, key terms, and review questions, plus flashcards, a timeline, and a glossary.
- A knowledge graph: typed, directed relationships between statutes, drawn with visNetwork, with domain focus, a layered view, and a table that follows the selection.
- Member lenses: Rep. Jason Crow (CO-06) and Rep. Sara Jacobs (CA-51), each mapping committees, record, and district interests onto the statutes, plus a comparison page.
- A Sources page listing every source, with official government sources marked.
- A site-wide "Current law only" switch that hides repealed and superseded laws.

Version 1 (one anonymized member lens, Cornell links) is archived in `../archive/natsec-wiki-v1/` and published under `v1/`. Do not edit the archive.

The owner is a data scientist with a PhD in political science and a background in conflict and stability analysis. The site is also used as a study guide by the owner's friends, who are not specialists. Write statute content for an expert reader; write study guide prose so a motivated non-specialist can follow it.

## Architecture

All content is data. Pages are generated.

```
data/statutes/*.yml         content, one entry per statute (source of truth)
data/edges.csv              graph edges (source of truth)
data/members/*.yml          one member lens per file (source of truth)
data/study/units.yml        study units (source of truth)
data/reference_sources.csv  general sources
data/research_sources.csv   sources consulted for the current edition
R/helpers.R                 loaders, vocabularies, layers, eras, colors, official link builders, mini_graph()
R/build_pages.R             validates data; writes statutes/*.qmd, members/<slug>.qmd, study/units/*.qmd,
                            _includes/wiki-data.html, and the manifest and source CSVs
R/post_render.R             copies ../archive/natsec-wiki-v1/docs into docs/v1 after a full render
R/deploy.R                  local runner: Rscript R/deploy.R [preview|render|serve|zip]
assets/graph.js             controller for the main graph (inlined by graph.qmd)
_includes/site.html         site-wide JS: current-law switch, historic link marks, reading progress
statutes/*.qmd              GENERATED, never edit
members/<slug>.qmd          GENERATED stubs that include members/_lens.qmd with params$slug
study/units/*.qmd           GENERATED from units.yml
data/manifest_*.csv, data/all_sources.csv   GENERATED
index.qmd graph.qmd title10-title50.qmd sources.qmd manifest.qmd about.qmd   top-level pages
study/index.qmd flashcards.qmd timeline.qmd glossary.qmd                     study pages
members/index.qmd members/_lens.qmd                                          member pages
docs/                       GENERATED site; committed, because GitHub Pages serves it
styles.scss                 theme; domain colors must match R/helpers.R
_quarto.yml                 project config; execute-dir is the project root, so every page can source R/helpers.R
```

To change content, edit YAML or CSV and render. To change behavior, edit the R, qmd, or JS files.

## Statute entry schema

```yaml
- id: wpr-1973                 # lowercase, hyphens, usually shortname-year; never change once set
  title: War Powers Resolution # full official or common title
  short: War Powers Resolution # graph label, about 25 characters or fewer
  year: 1973                   # year enacted (integer)
  enacted: "1973-11-07"        # optional ISO date, quoted
  domain: war-powers           # one of the domain keys below
  layer: framework             # one of the layer keys below
  public_law: "93-148"         # optional, "congress-number", quoted
  stat: "87 Stat. 555"         # optional Statutes at Large cite; first page of the law where possible
  usc: "50 U.S.C. 1541-1550"   # optional U.S. Code cite as displayed
  usc_path: "50/1541"          # optional, title/section for the GovInfo U.S. Code link
  usc_titles: [10]             # optional, extra U.S. Code titles not visible in the usc cite
  status: in-force             # one of the status keys below
  status_note: >-              # one to three sentences on current legal status
    ...
  summary: >-                  # two to four sentences: what the law does. The first ~90 characters
    ...                        # become the card and tooltip text, so lead with substance.
  provisions:                  # three to six items, each a double-quoted string
    - "Sec. 3: ..."
  significance: >-             # why it matters and how it connects; use [[id]] links here
    ...
  tags: [war powers, reporting]
  sources:                     # optional; official (.gov) sources first where they exist
    - label: "Publisher, 'Title' (date)"
      url: "https://..."
```

Every statute needs at least one of `public_law`, `stat`, `usc`, or `usc_path` so that it gets an official link, or else official sources under `sources`.

## Layers

`layer` places a statute in the authority stack. The keys are editorial judgments, documented in `layer_desc` in `R/helpers.R`:

| key | meaning |
|---|---|
| `constitution` | The constitutional clauses. |
| `framework` | Standing laws that create institutions or general procedures other laws plug into (NSA 1947, WPR, NEA, IEEPA, FISA, FAA, AECA). |
| `authorizing` | Laws aimed at a particular conflict, country, program, or problem, usually working through a framework statute (AUMFs, country sanctions acts, program statutes, the NDAA). |
| `provision` | Single sections that grant a narrow authority, impose a condition, or require a report (127e, 2808, Leahy, the civilian harm sections). |
| `code` | The four U.S. Code title overview pages. |

## Official links

`R/helpers.R` builds them from citations; do not hand-write these URLs in statute entries.

- Public law text: `https://www.govinfo.gov/link/plaw/{congress}/public/{number}`, 104th Congress onward.
- Statutes at Large: `https://www.govinfo.gov/link/statute/{volume}/{page}`. GovInfo covers every volume from 1789. Volumes with a letter (70A) or hyphenated pages fall back to the volume page.
- U.S. Code: `https://www.govinfo.gov/link/uscode/{title}/{section}?link-type=html`, from `usc_path` or else the first plain cite in `usc`. A bare title goes to the title's contents.
- Bills on member pages: `bill: {congress: 118, type: hr, number: 6517}` in an initiative builds a Congress.gov link. Types: hr, s, hres, sres, hjres, sjres, hconres, sconres.

Any URL on a .gov or .mil host counts as official on the Sources page. Congress.gov and uscode.house.gov refuse scripted requests, so automated link checks report 403 or 404 for them; check those by hand.

## Member lenses

Each file in `data/members/` has `slug`, `name`, `short`, `district`, `seat`, `party`, `as_of`, `background`, `profile_sources`, then `committees`, `initiatives`, and `equities` (district interests), and a `gaps` list. Every item has an `id`, a `short` label for the graph, a `statutes` list of wiki IDs, and a `source` with `label` and `url`. Committees also carry `name`, `role`, `jurisdiction`, and `code_titles`; initiatives carry `title`, `date`, `kind`, `summary`, and optionally `bill`. The build fails if a listed statute ID does not exist. Record items shared by both members use the same `id` in both files, which is how the comparison page finds them.

Rules:

1. Every claim about a member needs a public source in the same item. Prefer the member's official House site, Congress.gov, GovInfo, and the House Clerk; then established news outlets.
2. Describe, do not evaluate. No praise, criticism, or prediction. Use neutral wording for contested events and attribute characterizations to whoever made them, in quotation marks.
3. Do not invent bill numbers, vote counts, cosponsors, or outcomes. Verify bill numbers against GovInfo BILLSTATUS data (`https://www.govinfo.gov/bulkdata/BILLSTATUS/{congress}/{type}/BILLSTATUS-{congress}{type}{number}.xml`). If something was not verified, say so in the summary.
4. Search for current committee assignments and recent legislation before editing; these change with each Congress. Assignments for the 120th Congress were not yet announced on November 10, 2026.
5. Keep the notice that each lens is independent and not affiliated with the member's office.
6. Members are named in version 2 (the owner reversed the version 1 rule on November 10, 2026).

## Study units

Each unit in `data/study/units.yml` has `id`, `number`, `title`, `question`, `overview`, `objectives`, `core` (the reading path, in order), `further`, optional `pages` (extra links, `href` relative to `study/units/`), `terms` (`term`, `definition`), and `questions` (`q`, `a`; answers may use `[[id]]` links). Answers must be supported by the linked statute entries. The build lists any statute not in a unit; every statute should be in at least one.

## Hosting

`_quarto.yml` renders to `docs/`. The repo-root workflow `.github/workflows/pages.yml` publishes `natsec-wiki/docs` (Source: GitHub Actions). The update cycle is: edit data, `Rscript R/deploy.R render`, commit including `docs/`, push. A Pages site is public.

## Controlled vocabularies

Domain keys: `war-powers`, `intelligence`, `aid-sanctions`, `defense-arms`, `foreign-policy`, `civilian-protection`, `foundations`.

Status keys: `in-force`, `partly-expired`, `lapsed`, `repealed`, `superseded`. The "Current law only" switch hides `repealed` and `superseded`.

Edge relations, read as "from RELATION to":

| relation | meaning |
|---|---|
| `amends` | from changed the text of to |
| `repeals` | from repealed to |
| `succeeds` | from took over the role of to |
| `relies_on` | from operates through authority in to |
| `constrains` | from limits how to may be used |
| `enacted_in` | from was passed as part of to |
| `related` | thematic or historical link, drawn undirected |

`amends`, `relies_on`, `enacted_in`, and `succeeds` are dependencies: they build each page's "Builds on" and "Built upon by" lists.

Adding a domain, status, layer, or relation means editing the vectors at the top of `R/helpers.R` (domain labels, `domain_short` with no commas, colors), the `$domains` map and color variables in `styles.scss`, `DOMAIN_ORDER` in `assets/graph.js`, and the tables in `about.qmd`.

## Edges file

`data/edges.csv` has four columns: `from,to,relation,note`. The note is one sentence explaining the link, quoted. Both IDs must exist. Prefer the most specific relation; use `related` only when there is no legal dependency. Every statute should have at least one edge. Do not add edges from a statute to its code-title page; title membership is derived from the `usc` cite.

## Wiki links and generated markup

Inside `summary`, `significance`, and unit answers, write `[[id]]` to link to another statute using its short name, or `[[id|custom text]]` to set the link text.

In generated tables and lists, a statute link marked `{.subj}` names the row's subject; the current-law switch hides that row when the statute is repealed or superseded. Elements with `data-statute="<id>"` are hidden the same way. Graphs built with `mini_graph()` or with `onRender(window.wikiWatchGraph)` hide historic nodes.

## Rules for accuracy

1. Never invent a citation, section number, date, or URL. If unsure, leave the optional field out and say so.
2. For anything that may have changed (sunsets, reauthorizations, repeals, court rulings, pending bills, program cuts), search for current status before writing, and record the source under `sources`.
3. State uncertainty in `status_note` in plain terms and end with "Check current status." when the law is in flux.
4. Stay descriptive and neutral. Report what critics and supporters argue without taking a side.
5. Summaries are original prose. Do not paste statutory or article text.
6. Title 50 was renumbered in 2013. Use current section numbers.
7. Check provisions against the GovInfo U.S. Code text where possible; the source credit at the end of each section gives the public law, section, and Statutes at Large page.

## Writing style for entries

Plain declarative sentences. Lead with what the law does. No headings or markdown inside YAML strings other than wiki links. Avoid double quotes inside provision strings; use single quotes.

## Code conventions

The owner's R skill is high. Use the native pipe, namespace-qualified calls (`dplyr::mutate`), and concise line comments. Do not use en or em dashes as section breaks in code. Keep code simple.

## Typical requests and how to handle them

- "Add statute X": return a YAML entry (with `layer`) for the right domain file, new rows for `edges.csv`, and the unit it belongs in. Check that every ID you reference exists in the inventory below.
- "Update the status of X": search first, then return the revised `status`, `status_note`, and `sources`.
- "Add a relationship": return the CSV row with a one-sentence note.
- "Add a member": create `data/members/<slug>.yml`, add the member to the navbar menu in `_quarto.yml`, and render.
- "Add a new page type or view": edit or add a `.qmd`; load data with `source("R/helpers.R")`, `load_statutes()`, `load_edges()`, `load_members()`, `load_units()`.

## Watch list as of November 10, 2026

These entries were in flux at last review and should be rechecked first:

- `fisa-amendments-2008`, `risaa-2024`, `fisa-1978`: Section 702 lapsed in June 2026; no reauthorization found.
- `ndaa-annual`: FY2027 act pending; House passed H.R. 8800, Senate had not acted.
- `cisa-2015`: running on short extensions into December 2026.
- `dpa-1950`: sunset September 30, 2026; later extension not confirmed.
- `iran-sanctions-1996`: sunset December 31, 2026.
- `gfa-2019`: reauthorization bills H.R. 3005 and S. 2678 not enacted.
- `farra-1998`, `millennium-challenge-2003`: agency status after 2025 changes.
- `alien-enemies-1798`: the 2025 invocation remains legally unresolved after the Fifth Circuit dismissed the lead case as moot in August 2026.
- `selective-service-1948`: registration changes proposed in recent defense bills; not verified.
- `wpr-1973`: outcomes of the 2026 Venezuela and Iran war powers resolutions were not verified.
- `civcas-policy-2018`, `cp-coe-2022`: civilian harm staffing cuts and the compliance dispute with the Inspector General; a Defense review of DoDI 3000.17 was due by December 2026.
- `data/members/crow.yml`: committee assignments for the 120th Congress; outcome of the July 22, 2026 House vote on the Iran resolution; sponsor role on the Space National Guard bill; bill numbers for the 2026 war powers resolutions.
- `data/members/jacobs.yml`: committee assignments for the 120th Congress; bill number for the Security Sector Governance Compacts Act; whether the Upholding Human Rights Abroad Act's Leahy vetting provision was enacted.
- `reserve-mobilization`: Trump v. Illinois (December 2025) was an emergency-docket ruling on Sec. 12406; litigation may continue.

## Candidates not yet included

Electronic Communications Privacy Act; Intelligence Identities Protection Act; Protect America Act; 10 U.S.C. 130f (sensitive military operations notice); the irregular warfare authority that began as Section 1202 of the FY2018 NDAA; Title 32 Section 502(f); Nuclear Non-Proliferation Act of 1978; BUILD Act (DFC); PEPFAR; Foreign Sovereign Immunities Act and JASTA; Neutrality Acts of the 1930s; Non-Detention Act; Militia Act of 1795; Mutual Security Act of 1954; Arms Control and Disarmament Act; Titles 6 and 18 overview pages; Trade Act of 1974; CISADA; Sergei Magnitsky Act of 2012; Hong Kong and Uyghur human rights acts; Taiwan Enhanced Resilience Act; CISA Act of 2018; North Korea and Venezuela sanctions statutes; Foreign Assistance Act Sec. 620I (humanitarian aid conditions on security assistance); African Growth and Opportunity Act.

## Current inventory

Use these IDs exactly.

### War powers and use of force (`war-powers`)

| id | title | year | layer | status | code titles |
|---|---|---|---|---|---|
| `insurrection-1807` | Insurrection Act | 1807 | framework | in-force | 10 |
| `posse-comitatus-1878` | Posse Comitatus Act | 1878 | framework | in-force | 10, 18 |
| `unpa-1945` | United Nations Participation Act of 1945 | 1945 | framework | in-force | 22 |
| `reserve-mobilization` | Reserve and National Guard Mobilization Authorities | 1952 | framework | in-force | 10 |
| `tonkin-1964` | Gulf of Tonkin Resolution | 1964 | authorizing | repealed |  |
| `case-zablocki-1972` | Case-Zablocki Act | 1972 | provision | in-force | 1 |
| `wpr-1973` | War Powers Resolution | 1973 | framework | in-force | 50 |
| `nea-1976` | National Emergencies Act | 1976 | framework | in-force | 50 |
| `sec2808-milcon-1982` | Emergency Military Construction Authority (10 U.S.C. 2808) | 1982 | provision | in-force | 10 |
| `sec284-counterdrug-1990` | Defense Support for Counterdrug Activities (10 U.S.C. 284) | 1990 | provision | in-force | 10 |
| `aumf-gulf-1991` | Authorization for Use of Military Force Against Iraq Resolution (1991) | 1991 | authorizing | repealed | 50 |
| `aumf-2001` | Authorization for Use of Military Force (2001) | 2001 | authorizing | in-force | 50 |
| `aumf-iraq-2002` | Authorization for Use of Military Force Against Iraq Resolution of 2002 | 2002 | authorizing | repealed | 50 |
| `sec127e-2004` | Support of Special Operations to Combat Terrorism (10 U.S.C. 127e) | 2004 | provision | in-force | 10 |
| `dta-2005` | Detainee Treatment Act of 2005 | 2005 | provision | in-force | 10, 42 |
| `mil-commissions-2006` | Military Commissions Act of 2006 | 2006 | authorizing | in-force | 10 |
| `sec394-cyber-2018` | Military Cyber Operations Authority (10 U.S.C. 394-395) | 2018 | provision | in-force | 10 |

### Intelligence and surveillance (`intelligence`)

| id | title | year | layer | status | code titles |
|---|---|---|---|---|---|
| `espionage-1917` | Espionage Act of 1917 | 1917 | framework | in-force | 18 |
| `nsa-1947` | National Security Act of 1947 | 1947 | framework | in-force | 50 |
| `cia-act-1949` | Central Intelligence Agency Act of 1949 | 1949 | framework | in-force | 50 |
| `hughes-ryan-1974` | Hughes-Ryan Amendment | 1974 | provision | superseded | 22 |
| `fisa-1978` | Foreign Intelligence Surveillance Act of 1978 | 1978 | framework | partly-expired | 50 |
| `cipa-1980` | Classified Information Procedures Act | 1980 | framework | in-force | 18 |
| `intel-oversight-1980` | Intelligence Oversight Act of 1980 | 1980 | framework | in-force | 50 |
| `patriot-2001` | USA PATRIOT Act | 2001 | authorizing | partly-expired | 18, 31, 50 |
| `hsa-2002` | Homeland Security Act of 2002 | 2002 | framework | in-force | 6 |
| `irtpa-2004` | Intelligence Reform and Terrorism Prevention Act of 2004 | 2004 | framework | in-force | 50 |
| `fisa-amendments-2008` | FISA Amendments Act of 2008 | 2008 | authorizing | lapsed | 50 |
| `cisa-2015` | Cybersecurity Information Sharing Act of 2015 | 2015 | authorizing | partly-expired | 6 |
| `usa-freedom-2015` | USA FREEDOM Act of 2015 | 2015 | authorizing | partly-expired | 50 |
| `risaa-2024` | Reforming Intelligence and Securing America Act | 2024 | authorizing | lapsed | 50 |

### Foreign aid, fragility and sanctions (`aid-sanctions`)

| id | title | year | layer | status | code titles |
|---|---|---|---|---|---|
| `twea-1917` | Trading with the Enemy Act of 1917 | 1917 | framework | in-force | 50 |
| `mutual-security-1951` | Mutual Security Act of 1951 | 1951 | authorizing | superseded |  |
| `faa-1961` | Foreign Assistance Act of 1961 | 1961 | framework | in-force | 22 |
| `ieepa-1977` | International Emergency Economic Powers Act | 1977 | framework | in-force | 50 |
| `helms-burton-1996` | Cuban Liberty and Democratic Solidarity (LIBERTAD) Act of 1996 | 1996 | authorizing | in-force | 22 |
| `iran-sanctions-1996` | Iran Sanctions Act of 1996 | 1996 | authorizing | in-force | 50 |
| `leahy-laws` | Leahy Laws | 1997 | provision | in-force | 10, 22 |
| `farra-1998` | Foreign Affairs Reform and Restructuring Act of 1998 | 1998 | framework | in-force | 22 |
| `millennium-challenge-2003` | Millennium Challenge Act of 2003 | 2004 | authorizing | in-force | 22 |
| `inara-2015` | Iran Nuclear Agreement Review Act of 2015 | 2015 | authorizing | in-force | 42 |
| `glomag-2016` | Global Magnitsky Human Rights Accountability Act | 2016 | authorizing | in-force | 22 |
| `caatsa-2017` | Countering America's Adversaries Through Sanctions Act | 2017 | authorizing | in-force | 22 |
| `wps-2017` | Women, Peace, and Security Act of 2017 | 2017 | authorizing | in-force | 22 |
| `caesar-2019` | Caesar Syria Civilian Protection Act of 2019 | 2019 | authorizing | repealed | 22 |
| `wiesel-2018` | Elie Wiesel Genocide and Atrocities Prevention Act of 2018 | 2019 | authorizing | in-force | 22 |
| `gfa-2019` | Global Fragility Act of 2019 | 2019 | authorizing | partly-expired | 22 |

### Defense organization and arms transfers (`defense-arms`)

| id | title | year | layer | status | code titles |
|---|---|---|---|---|---|
| `lend-lease-1941` | Lend-Lease Act | 1941 | authorizing | superseded |  |
| `selective-service-1948` | Military Selective Service Act | 1948 | framework | partly-expired | 50 |
| `nsa-amendments-1949` | National Security Act Amendments of 1949 | 1949 | framework | in-force | 10 |
| `dpa-1950` | Defense Production Act of 1950 | 1950 | framework | partly-expired | 50 |
| `ucmj-1950` | Uniform Code of Military Justice | 1950 | framework | in-force | 10 |
| `aea-1954` | Atomic Energy Act of 1954 | 1954 | framework | in-force | 42 |
| `dod-reorg-1958` | Department of Defense Reorganization Act of 1958 | 1958 | framework | in-force | 10 |
| `ndaa-annual` | National Defense Authorization Act (annual series) | 1961 | authorizing | in-force | 10, 50 |
| `aeca-1976` | Arms Export Control Act | 1976 | framework | in-force | 22 |
| `symington-glenn` | Symington and Glenn Amendments | 1976 | provision | in-force | 22 |
| `tra-1979` | Taiwan Relations Act | 1979 | authorizing | in-force | 22 |
| `goldwater-nichols-1986` | Goldwater-Nichols Department of Defense Reorganization Act of 1986 | 1986 | framework | in-force | 10 |
| `nunn-cohen-1986` | Nunn-Cohen Amendment | 1986 | framework | in-force | 10 |
| `nunn-lugar-1991` | Soviet Nuclear Threat Reduction Act of 1991 (Nunn-Lugar) | 1991 | authorizing | in-force | 22, 50 |
| `seccoop-2016` | Security Cooperation Reform (FY2017 NDAA, Title 10 Chapter 16) | 2016 | framework | in-force | 10 |
| `ecra-2018` | Export Control Reform Act of 2018 | 2018 | framework | in-force | 50 |
| `firrma-2018` | Foreign Investment Risk Review Modernization Act of 2018 | 2018 | framework | in-force | 50 |

### Related foreign policy (`foreign-policy`)

| id | title | year | layer | status | code titles |
|---|---|---|---|---|---|
| `fara-1938` | Foreign Agents Registration Act of 1938 | 1938 | framework | in-force | 22 |
| `smith-mundt-1948` | U.S. Information and Educational Exchange Act of 1948 (Smith-Mundt) | 1948 | framework | in-force | 22 |
| `state-basic-1956` | State Department Basic Authorities Act of 1956 | 1956 | framework | in-force | 22 |
| `sec232-1962` | Trade Expansion Act of 1962, Section 232 | 1962 | provision | in-force | 19 |
| `fsa-1980` | Foreign Service Act of 1980 | 1980 | framework | in-force | 22 |
| `aedpa-1996` | Antiterrorism and Effective Death Penalty Act of 1996 | 1996 | authorizing | in-force | 8, 18 |

### Civilian harm and protection (`civilian-protection`)

| id | title | year | layer | status | code titles |
|---|---|---|---|---|---|
| `foreign-claims-1942` | Foreign Claims Act | 1942 | provision | in-force | 10 |
| `civcas-report-2017` | Annual Report on Civilian Casualties (FY2018 NDAA Sec. 1057) | 2017 | provision | in-force | 10 |
| `civcas-policy-2018` | Civilian Casualty Policy (FY2019 NDAA Sec. 936) | 2018 | provision | in-force | 10 |
| `ex-gratia-2019` | Ex Gratia Payments for Civilian Harm (FY2020 NDAA Sec. 1213) | 2019 | provision | in-force | 10 |
| `cp-coe-2022` | Civilian Protection Center of Excellence (10 U.S.C. 184) | 2022 | provision | in-force | 10 |

### Constitutional and code foundations (`foundations`)

| id | title | year | layer | status | code titles |
|---|---|---|---|---|---|
| `constitution-war-powers` | U.S. Constitution: War and Foreign Affairs Powers | 1788 | constitution | in-force |  |
| `militia-acts-1792` | Militia Acts of 1792 | 1792 | framework | superseded | 10 |
| `neutrality-1794` | Neutrality Act of 1794 | 1794 | framework | in-force | 18 |
| `alien-enemies-1798` | Alien Enemies Act of 1798 | 1798 | framework | in-force | 50 |
| `logan-1799` | Logan Act | 1799 | provision | in-force | 18 |
| `declarations-of-war` | Declarations of War (1812-1942) | 1812 | authorizing | in-force |  |
| `dick-act-1903` | Militia Act of 1903 (Dick Act) | 1903 | framework | superseded | 32 |
| `national-defense-act-1916` | National Defense Act of 1916 | 1916 | framework | superseded | 10, 32 |
| `title22-usc` | Title 22, U.S. Code: Foreign Relations and Intercourse | 1926 | code | in-force | 22 |
| `title50-usc` | Title 50, U.S. Code: War and National Defense | 1926 | code | in-force | 50 |
| `title10-usc` | Title 10, U.S. Code: Armed Forces | 1956 | code | in-force | 10 |
| `title32-usc` | Title 32, U.S. Code: National Guard | 1956 | code | in-force | 32 |

Totals: 87 statutes, 167 edges.
