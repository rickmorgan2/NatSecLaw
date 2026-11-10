# CLAUDE_README: U.S. National Security Legislation Wiki

Paste or attach this file at the start of a Claude session to work on this project. It describes what the project is, how the data is structured, and the rules to follow when extending it.

## What this project is

A Quarto website, rendered with R, hosted locally or on GitHub Pages, that works as a wiki and knowledge graph of U.S. national security statutes and the foreign policy laws they connect to. It has three parts:

- A wiki: one page per statute.
- A knowledge graph: typed, directed relationships between statutes, drawn with visNetwork.
- A manifest: every statute with its citations, and every source link.
- A member lens: one member of Congress's committees, record, and district interests mapped onto the statutes. This copy is tailored to the member for Colorado's 6th District, referred to only as CO-06.

The owner is a data scientist with a PhD in political science and a background in conflict and stability analysis. Write for an expert reader. Do not explain basic civics.

## Architecture

All content is data. Pages are generated.

```
data/statutes/*.yml         content, one entry per statute (source of truth)
data/edges.csv              graph edges (source of truth)
data/reference_sources.csv  general sources for the manifest
R/helpers.R                 loaders, vocabularies, colors, citation URL builders
R/build_pages.R             validates data, writes statutes/*.qmd and manifest CSVs
R/deploy.R                  local runner: Rscript R/deploy.R [preview|render|serve|zip]
statutes/*.qmd              GENERATED, never edit
data/manifest_*.csv         GENERATED, never edit
index.qmd graph.qmd manifest.qmd about.qmd   top-level pages
title10-title50.qmd         hand-written explainer; its two tables are generated from the data
data/member.yml             the member the wiki is tailored to (source of truth for member.qmd)
member.qmd                  Member lens page and graph, generated from data/member.yml
docs/                       GENERATED site; committed, because GitHub Pages serves it
styles.scss                 theme
_quarto.yml                 project config; pre-render runs R/build_pages.R
```

To change content, edit YAML or the edges CSV and give the owner the changed entries. To change behavior, edit the R or qmd files.

## Statute entry schema

```yaml
- id: wpr-1973                 # lowercase, hyphens, usually shortname-year; never change once set
  title: War Powers Resolution # full official or common title
  short: War Powers Resolution # graph label, about 25 characters or fewer
  year: 1973                   # year enacted (integer)
  enacted: "1973-11-07"        # optional ISO date, quoted
  domain: war-powers           # one of the five domain keys below
  public_law: "93-148"         # optional, "congress-number", quoted
  stat: "87 Stat. 555"         # optional Statutes at Large cite
  usc: "50 U.S.C. 1541-1550"   # optional U.S. Code cite as displayed
  usc_path: "50/1541"          # optional, title/section for the Cornell LII link
  usc_titles: [10]             # optional, extra U.S. Code titles not visible in the usc cite
  status: in-force             # one of the five status keys below
  status_note: >-              # one to three sentences on current legal status
    ...
  summary: >-                  # two to four sentences: what the law does
    ...
  provisions:                  # three to six items, each a double-quoted string
    - "Sec. 3: ..."
  significance: >-             # why it matters and how it connects; use [[id]] links here
    ...
  tags: [war powers, reporting]
  sources:                     # optional secondary or status sources
    - label: "Publisher, 'Title' (date)"
      url: "https://..."
```

Optional fields can be omitted. Every statute needs at least one of `public_law`, `stat`, or `usc_path` so that it gets a primary link.

## U.S. Code titles

Each statute carries a derived list of U.S. Code titles. `code_titles()` in `R/helpers.R` parses every "NN U.S.C." in the `usc` field and adds anything listed under `usc_titles`. The titles become listing categories ("U.S. Code Title 10"), a column in the manifest, an option in the graph's filter menu, and the two tables on the Title 10 and Title 50 page. When adding a statute that is codified in a title its `usc` cite does not show, set `usc_titles`.

Some entries are single code provisions (for example `sec127e-2004`, `sec394-cyber-2018`). For these the ID is `sec` + section + topic or year, the title names the provision with its cite in parentheses, and `year` is the year the authority was first enacted.

## Foundations and code-title pages

The `foundations` domain holds the Constitution's war and foreign affairs clauses, founding-era statutes, the acts that created the National Guard, and four pages that describe whole U.S. Code titles (`title10-usc`, `title22-usc`, `title32-usc`, `title50-usc`). A code-title page sets `code_title: 10` (the title number). The build script then adds a generated table of every other statute in the wiki codified in that title, so do not list member statutes by hand or add an edge from each member to the title page. Entries without a codified cite, such as the Constitution page, must list at least one link under `sources`.

## Member lens

`data/member.yml` has a profile block, then three lists: `committees`, `initiatives`, and `equities` (district interests). Every item has an `id`, a `short` label for the graph, a `statutes` list of wiki IDs, and a `source` with `label` and `url`. Committees also carry `role`, `jurisdiction`, and `code_titles`; initiatives carry `date`, `kind`, and `summary`. A final `gaps` list names parts of the record the wiki does not cover. The build fails if a listed statute ID does not exist.

Rules for this file:

1. Every claim about the member needs a public source in the same item. Prefer the member's official site, Congress.gov, and established news outlets.
2. Describe, do not evaluate. No praise, criticism, or prediction. Use neutral wording for contested events and attribute characterizations to whoever made them.
3. Do not invent bill numbers, vote counts, cosponsors, or outcomes. If something was not verified, say so in the summary.
4. Search for current committee assignments and recent legislation before editing; these change with each Congress. Assignments for the 120th Congress were not yet announced on November 10, 2026.
5. Keep the notice that the page is independent and not affiliated with the member's office.
6. The site is public, so the member is identified by district only. Do not write the member's name in page text, source labels, IDs, file names, or commit messages. Use "CO-06", "the member", or "CO-06 House office". Source URLs may contain the name; that is accepted so the sourcing stays checkable.

## Hosting

`_quarto.yml` renders to `docs/`. The wiki lives in `CO-06/natsec-wiki/` of the `house-knowledge` repo, so the repo-root workflow `.github/workflows/pages.yml` publishes that `docs/` folder to GitHub Pages (Source: GitHub Actions). The update cycle is: edit data, `Rscript R/deploy.R render`, commit including `docs/`, push. A Pages site is public.

## Controlled vocabularies

Domain keys: `war-powers`, `intelligence`, `aid-sanctions`, `defense-arms`, `foreign-policy`, `foundations`.

Status keys: `in-force`, `partly-expired`, `lapsed`, `repealed`, `superseded`.

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

Adding a domain, status, or relation means editing the vectors at the top of `R/helpers.R` (including `domain_short`, used in the graph menu), the color variables in `styles.scss`, and the tables in `about.qmd`.

## Edges file

`data/edges.csv` has four columns: `from,to,relation,note`. The note is one sentence explaining the link, quoted. Both IDs must exist. Prefer the most specific relation; use `related` only when there is no legal dependency. Every statute should have at least one edge.

## Wiki links

Inside `summary` and `significance`, write `[[id]]` to link to another statute using its short name, or `[[id|custom text]]` to set the link text. Include the article in the prose, for example `the [[faa-1961]]`.

## How links to primary sources are built

`R/helpers.R` builds them from citations; do not hand-write these URLs.

- Public law text: `https://www.govinfo.gov/link/plaw/{congress}/public/{number}`, only for the 104th Congress onward.
- Statutes at Large: `https://www.govinfo.gov/link/statute/{volume}/{page}`, only for volume 65 onward and only when there is no public law link. The page must be the first page of the law.
- U.S. Code: `https://www.law.cornell.edu/uscode/text/{usc_path}`.

## Rules for accuracy

1. Never invent a citation, section number, date, or URL. If unsure, leave the optional field out and say so.
2. For anything that may have changed (sunsets, reauthorizations, repeals, court rulings, pending bills), search for current status before writing, and record the source under `sources`.
3. State uncertainty in `status_note` in plain terms and end with "Check current status." when the law is in flux.
4. Stay descriptive and neutral. Report what critics and supporters argue without taking a side.
5. Summaries are original prose. Do not paste statutory or article text.
6. Title 50 was renumbered in 2013. Use current section numbers.

## Writing style for entries

Plain declarative sentences. Lead with what the law does. No headings or markdown inside YAML strings other than wiki links. Avoid double quotes inside provision strings; use single quotes.

## Code conventions

The owner's R skill is high. Use the native pipe, namespace-qualified calls (`dplyr::mutate`), and concise line comments. Do not use en or em dashes as section breaks in code. Keep code simple. Provide R code only when asked. Deliver files in the chat; do not write to his machine.

## Typical requests and how to handle them

- "Add statute X": return a YAML entry for the right domain file plus new rows for `edges.csv`. Check that every ID you reference exists in the inventory below.
- "Update the status of X": search first, then return the revised `status`, `status_note`, and `sources`.
- "Add a relationship": return the CSV row with a one-sentence note.
- "Add a new page type or view": edit or add a `.qmd`; load data with `source("R/helpers.R")`, `load_statutes()`, `load_edges()`.

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
- `data/member.yml`: committee assignments for the 120th Congress; outcome of the July 22, 2026 House vote on the Iran resolution; sponsor role on the Space National Guard bill; bill numbers throughout.
- `reserve-mobilization`: Trump v. Illinois (December 2025) was an emergency-docket ruling on Sec. 12406; litigation may continue.

## Candidates not yet included

Electronic Communications Privacy Act; Intelligence Identities Protection Act; Protect America Act; 10 U.S.C. 130f (sensitive military operations notice); the irregular warfare authority that began as Section 1202 of the FY2018 NDAA; Title 32 Section 502(f); Nuclear Non-Proliferation Act of 1978; BUILD Act (DFC); PEPFAR; Foreign Sovereign Immunities Act and JASTA; Neutrality Acts of the 1930s; Non-Detention Act; Militia Act of 1795; Mutual Security Act of 1954; Arms Control and Disarmament Act; Titles 6 and 18 overview pages; Trade Act of 1974; CISADA; Sergei Magnitsky Act of 2012; Hong Kong and Uyghur human rights acts; Taiwan Enhanced Resilience Act; CISA Act of 2018; North Korea and Venezuela sanctions statutes.

## Current inventory

Use these IDs exactly.


### War powers and use of force (`war-powers`) 

| id | title | year | status | code titles |
|---|---|---|---|---|
| `insurrection-1807` | Insurrection Act | 1807 | in-force | 10 |
| `posse-comitatus-1878` | Posse Comitatus Act | 1878 | in-force | 10, 18 |
| `unpa-1945` | United Nations Participation Act of 1945 | 1945 | in-force | 22 |
| `reserve-mobilization` | Reserve and National Guard Mobilization Authorities | 1952 | in-force | 10 |
| `tonkin-1964` | Gulf of Tonkin Resolution | 1964 | repealed |  |
| `case-zablocki-1972` | Case-Zablocki Act | 1972 | in-force | 1 |
| `wpr-1973` | War Powers Resolution | 1973 | in-force | 50 |
| `nea-1976` | National Emergencies Act | 1976 | in-force | 50 |
| `sec2808-milcon-1982` | Emergency Military Construction Authority (10 U.S.C. 2808) | 1982 | in-force | 10 |
| `sec284-counterdrug-1990` | Defense Support for Counterdrug Activities (10 U.S.C. 284) | 1990 | in-force | 10 |
| `aumf-gulf-1991` | Authorization for Use of Military Force Against Iraq Resolution (1991) | 1991 | repealed | 50 |
| `aumf-2001` | Authorization for Use of Military Force (2001) | 2001 | in-force | 50 |
| `aumf-iraq-2002` | Authorization for Use of Military Force Against Iraq Resolution of 2002 | 2002 | repealed | 50 |
| `sec127e-2004` | Support of Special Operations to Combat Terrorism (10 U.S.C. 127e) | 2004 | in-force | 10 |
| `dta-2005` | Detainee Treatment Act of 2005 | 2005 | in-force | 10, 42 |
| `mil-commissions-2006` | Military Commissions Act of 2006 | 2006 | in-force | 10 |
| `sec394-cyber-2018` | Military Cyber Operations Authority (10 U.S.C. 394-395) | 2018 | in-force | 10 |

### Intelligence and surveillance (`intelligence`) 

| id | title | year | status | code titles |
|---|---|---|---|---|
| `espionage-1917` | Espionage Act of 1917 | 1917 | in-force | 18 |
| `nsa-1947` | National Security Act of 1947 | 1947 | in-force | 50 |
| `cia-act-1949` | Central Intelligence Agency Act of 1949 | 1949 | in-force | 50 |
| `hughes-ryan-1974` | Hughes-Ryan Amendment | 1974 | superseded | 22 |
| `fisa-1978` | Foreign Intelligence Surveillance Act of 1978 | 1978 | partly-expired | 50 |
| `cipa-1980` | Classified Information Procedures Act | 1980 | in-force | 18 |
| `intel-oversight-1980` | Intelligence Oversight Act of 1980 | 1980 | in-force | 50 |
| `patriot-2001` | USA PATRIOT Act | 2001 | partly-expired | 18, 31, 50 |
| `hsa-2002` | Homeland Security Act of 2002 | 2002 | in-force | 6 |
| `irtpa-2004` | Intelligence Reform and Terrorism Prevention Act of 2004 | 2004 | in-force | 50 |
| `fisa-amendments-2008` | FISA Amendments Act of 2008 | 2008 | lapsed | 50 |
| `cisa-2015` | Cybersecurity Information Sharing Act of 2015 | 2015 | partly-expired | 6 |
| `usa-freedom-2015` | USA FREEDOM Act of 2015 | 2015 | partly-expired | 50 |
| `risaa-2024` | Reforming Intelligence and Securing America Act | 2024 | lapsed | 50 |

### Foreign aid, fragility and sanctions (`aid-sanctions`) 

| id | title | year | status | code titles |
|---|---|---|---|---|
| `twea-1917` | Trading with the Enemy Act of 1917 | 1917 | in-force | 50 |
| `mutual-security-1951` | Mutual Security Act of 1951 | 1951 | superseded |  |
| `faa-1961` | Foreign Assistance Act of 1961 | 1961 | in-force | 22 |
| `ieepa-1977` | International Emergency Economic Powers Act | 1977 | in-force | 50 |
| `helms-burton-1996` | Cuban Liberty and Democratic Solidarity (LIBERTAD) Act of 1996 | 1996 | in-force | 22 |
| `iran-sanctions-1996` | Iran Sanctions Act of 1996 | 1996 | in-force | 50 |
| `leahy-laws` | Leahy Laws | 1997 | in-force | 10, 22 |
| `farra-1998` | Foreign Affairs Reform and Restructuring Act of 1998 | 1998 | in-force | 22 |
| `millennium-challenge-2003` | Millennium Challenge Act of 2003 | 2004 | in-force | 22 |
| `inara-2015` | Iran Nuclear Agreement Review Act of 2015 | 2015 | in-force | 42 |
| `glomag-2016` | Global Magnitsky Human Rights Accountability Act | 2016 | in-force | 22 |
| `caatsa-2017` | Countering America's Adversaries Through Sanctions Act | 2017 | in-force | 22 |
| `wps-2017` | Women, Peace, and Security Act of 2017 | 2017 | in-force | 22 |
| `caesar-2019` | Caesar Syria Civilian Protection Act of 2019 | 2019 | repealed | 22 |
| `wiesel-2018` | Elie Wiesel Genocide and Atrocities Prevention Act of 2018 | 2019 | in-force | 22 |
| `gfa-2019` | Global Fragility Act of 2019 | 2019 | partly-expired | 22 |

### Defense organization and arms transfers (`defense-arms`) 

| id | title | year | status | code titles |
|---|---|---|---|---|
| `lend-lease-1941` | Lend-Lease Act | 1941 | superseded |  |
| `selective-service-1948` | Military Selective Service Act | 1948 | partly-expired | 50 |
| `nsa-amendments-1949` | National Security Act Amendments of 1949 | 1949 | in-force | 10 |
| `dpa-1950` | Defense Production Act of 1950 | 1950 | partly-expired | 50 |
| `ucmj-1950` | Uniform Code of Military Justice | 1950 | in-force | 10 |
| `aea-1954` | Atomic Energy Act of 1954 | 1954 | in-force | 42 |
| `dod-reorg-1958` | Department of Defense Reorganization Act of 1958 | 1958 | in-force | 10 |
| `ndaa-annual` | National Defense Authorization Act (annual series) | 1961 | in-force | 10, 50 |
| `aeca-1976` | Arms Export Control Act | 1976 | in-force | 22 |
| `symington-glenn` | Symington and Glenn Amendments | 1976 | in-force | 22 |
| `tra-1979` | Taiwan Relations Act | 1979 | in-force | 22 |
| `goldwater-nichols-1986` | Goldwater-Nichols Department of Defense Reorganization Act of 1986 | 1986 | in-force | 10 |
| `nunn-cohen-1986` | Nunn-Cohen Amendment | 1986 | in-force | 10 |
| `nunn-lugar-1991` | Soviet Nuclear Threat Reduction Act of 1991 (Nunn-Lugar) | 1991 | in-force | 22, 50 |
| `seccoop-2016` | Security Cooperation Reform (FY2017 NDAA, Title 10 Chapter 16) | 2016 | in-force | 10 |
| `ecra-2018` | Export Control Reform Act of 2018 | 2018 | in-force | 50 |
| `firrma-2018` | Foreign Investment Risk Review Modernization Act of 2018 | 2018 | in-force | 50 |

### Related foreign policy (`foreign-policy`) 

| id | title | year | status | code titles |
|---|---|---|---|---|
| `fara-1938` | Foreign Agents Registration Act of 1938 | 1938 | in-force | 22 |
| `smith-mundt-1948` | U.S. Information and Educational Exchange Act of 1948 (Smith-Mundt) | 1948 | in-force | 22 |
| `state-basic-1956` | State Department Basic Authorities Act of 1956 | 1956 | in-force | 22 |
| `sec232-1962` | Trade Expansion Act of 1962, Section 232 | 1962 | in-force | 19 |
| `fsa-1980` | Foreign Service Act of 1980 | 1980 | in-force | 22 |
| `aedpa-1996` | Antiterrorism and Effective Death Penalty Act of 1996 | 1996 | in-force | 8, 18 |

### Constitutional and code foundations (`foundations`) 

| id | title | year | status | code titles |
|---|---|---|---|---|
| `constitution-war-powers` | U.S. Constitution: War and Foreign Affairs Powers | 1788 | in-force |  |
| `militia-acts-1792` | Militia Acts of 1792 | 1792 | superseded | 10 |
| `neutrality-1794` | Neutrality Act of 1794 | 1794 | in-force | 18 |
| `alien-enemies-1798` | Alien Enemies Act of 1798 | 1798 | in-force | 50 |
| `logan-1799` | Logan Act | 1799 | in-force | 18 |
| `declarations-of-war` | Declarations of War (1812-1942) | 1812 | in-force |  |
| `dick-act-1903` | Militia Act of 1903 (Dick Act) | 1903 | superseded | 32 |
| `national-defense-act-1916` | National Defense Act of 1916 | 1916 | superseded | 10, 32 |
| `title22-usc` | Title 22, U.S. Code: Foreign Relations and Intercourse | 1926 | in-force | 22 |
| `title50-usc` | Title 50, U.S. Code: War and National Defense | 1926 | in-force | 50 |
| `title10-usc` | Title 10, U.S. Code: Armed Forces | 1956 | in-force | 10 |
| `title32-usc` | Title 32, U.S. Code: National Guard | 1956 | in-force | 32 |

Totals: 82 statutes, 157 edges.
