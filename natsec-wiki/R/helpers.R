# Shared helpers for R/build_pages.R and the Quarto pages.
# All paths are relative to the project root.

# controlled vocabularies ------------------------------------------------------

domain_labels <- c(
  "war-powers"          = "War powers and use of force",
  "intelligence"        = "Intelligence and surveillance",
  "aid-sanctions"       = "Foreign aid, fragility and sanctions",
  "defense-arms"        = "Defense organization and arms transfers",
  "foreign-policy"      = "Related foreign policy",
  "civilian-protection" = "Civilian harm and protection",
  "purse"               = "Appropriations and the power of the purse",
  "foundations"         = "Constitutional and code foundations"
)

# short names for menus, chips, and listing categories. Quarto joins an item's
# categories with commas, so these must never contain one.
domain_short <- c(
  "war-powers"          = "War powers",
  "intelligence"        = "Intelligence",
  "aid-sanctions"       = "Aid and sanctions",
  "defense-arms"        = "Defense and arms",
  "foreign-policy"      = "Foreign policy",
  "civilian-protection" = "Civilian harm",
  "purse"               = "Power of the purse",
  "foundations"         = "Foundations"
)

domain_colors <- c(
  "war-powers"          = "#b5403a",
  "intelligence"        = "#3b5b92",
  "aid-sanctions"       = "#2e7d6b",
  "defense-arms"        = "#b07a1e",
  "foreign-policy"      = "#6b4c8a",
  "civilian-protection" = "#a23b72",
  "purse"               = "#5f7d2b",
  "foundations"         = "#44505f"
)

status_labels <- c(
  "in-force"       = "In force",
  "partly-expired" = "Partly expired",
  "lapsed"         = "Lapsed",
  "repealed"       = "Repealed",
  "superseded"     = "Superseded"
)

# statuses the site-wide toggle hides
historic_status <- c("repealed", "superseded")

# authority layers: where a law sits between the Constitution and a single code section
layer_labels <- c(
  constitution = "Constitution",
  framework    = "Framework statute",
  authorizing  = "Specific authorization",
  provision    = "Targeted provision",
  code         = "Code title overview"
)

layer_desc <- c(
  constitution = "The grants and limits every statute below draws on: Congress's war, money, and military powers in Article I and the President's command and foreign affairs powers in Article II.",
  framework    = "Standing laws that create institutions or general procedures other laws and executive actions plug into, such as the National Security Act, the War Powers Resolution, IEEPA, and FISA.",
  authorizing  = "Laws aimed at a particular conflict, country, program, or problem. Most work through a framework statute: an AUMF through the War Powers Resolution, a sanctions act through IEEPA.",
  provision    = "Single sections that grant a narrow authority, impose a condition, or require a report, often enacted in a defense authorization. Small in text, often decisive in practice.",
  code         = "Not a layer of authority but the shelf where enacted law is filed by subject. Titles 10 and 32 are themselves enacted law; Titles 22 and 50 are compilations."
)

# vertical position in the graph's layered view; code titles sit at the bottom as the filing system
layer_level <- c(constitution = 0, framework = 1, authorizing = 2, provision = 3, code = 4)

# eras for the timeline
era_breaks <- tibble::tribble(
  ~era,                                   ~from, ~to,
  "Founding and the early republic",       1787, 1860,
  "Civil War to the First World War",      1861, 1918,
  "Interwar years and the Second World War", 1919, 1945,
  "Building the national security state",  1946, 1963,
  "Vietnam, Watergate, and reassertion",   1964, 1980,
  "End of the Cold War",                   1981, 2000,
  "After September 11",                    2001, 2010,
  "Sanctions, cyber, and great powers",    2011, 2100
)

era_of <- function(year) {
  idx <- findInterval(year, era_breaks$from)
  era_breaks$era[pmax(idx, 1)]
}

# relation read from the "from" side and from the "to" side
relation_labels <- c(
  amends = "amends", repeals = "repeals", succeeds = "succeeds",
  relies_on = "relies on", constrains = "constrains",
  enacted_in = "enacted in", part_of = "part of", funded_by = "funded through",
  related = "related to",
  # court cases to the statutes they decided; built from data/cases.yml, not edges.csv
  ruled_on = "ruled on"
)

relation_inverse <- c(
  amends = "amended by", repeals = "repealed by", succeeds = "succeeded by",
  relies_on = "relied on by", constrains = "constrained by",
  enacted_in = "vehicle for", part_of = "includes", funded_by = "funds",
  related = "related to", ruled_on = "decided in"
)

relation_colors <- c(
  amends = "#3b5b92", repeals = "#b5403a", succeeds = "#b07a1e",
  relies_on = "#2e7d6b", constrains = "#6b4c8a",
  enacted_in = "#5c6670", part_of = "#8a6d3b", funded_by = "#5f7d2b",
  related = "#b4bac1", ruled_on = "#1b2a41"
)

# relations that express dependence of one law on another, used for "builds on"
dependency_relations <- c("relies_on", "amends", "enacted_in", "succeeds", "part_of", "funded_by")

# relations allowed in data/edges.csv (court case links come from data/cases.yml)
edge_relations <- setdiff(names(relation_labels), "ruled_on")

# date of the last full review; a statute without its own `checked` date was checked then
wiki_reviewed <- "2026-11-10"

# "2026-11-10" as "November 10, 2026"
long_date <- function(x) {
  d <- as.Date(x)
  dplyr::if_else(is.na(d), NA_character_,
                 paste0(month.name[as.integer(format(d, "%m"))], " ", as.integer(format(d, "%d")), ", ", format(d, "%Y")))
}

# field helpers ----------------------------------------------------------------

# pull an optional scalar field from a list of records
chr_field <- function(recs, field) {
  purrr::map_chr(recs, \(x) if (is.null(x[[field]])) NA_character_ else as.character(x[[field]]))
}

# pull an optional list field (character vector or list of records)
list_field <- function(recs, field) {
  purrr::map(recs, \(x) if (is.null(x[[field]])) list() else x[[field]])
}

# U.S. Code title numbers for one statute, e.g. "22 U.S.C. 2378d; 10 U.S.C. 362" gives 10, 22
code_titles <- function(cite, extra) {
  parsed <- stringr::str_match_all(dplyr::coalesce(cite, ""), "(\\d+) U\\.S\\.C\\.")[[1]][, 2]
  sort(unique(as.integer(c(parsed, unlist(extra)))))
}

# category label for a code title
title_label <- function(n) if (length(n)) paste("U.S. Code Title", n) else character(0)

# opening of a text for cards and tooltips: whole sentences, at least `min_chars`
# long. A period ends a sentence only when a capital letter follows and the word
# before it is not an abbreviation such as "U.S.", "U.N.", or "Pub. L."
first_sentence <- function(x, min_chars = 90) {
  abbrev <- "^(?:[A-Z](?:\\.[A-Z])*|Pub|Sec|Secs|Stat|No|Nos|Gen|St|Mr|Ms|Dr|Jr|Sr|Inc|Co|v|vs|Rep|Sen|Div|Ch|Res)$"
  purrr::map_chr(x, \(s) {
    if (is.na(s)) return(NA_character_)
    s <- gsub("\\s+", " ", trimws(s))
    ends <- gregexpr("[.!?](?= [A-Z\"'])", s, perl = TRUE)[[1]]
    for (e in ends[ends > 0]) {
      word <- sub(".*[ (]", "", substr(s, 1, e - 1))
      if (!grepl(abbrev, word, perl = TRUE) && e >= min_chars) return(substr(s, 1, e))
    }
    s
  })
}

# display names for every id a [[wiki link]] can point to: statutes, then court cases
wiki_labels <- function(statutes) {
  cases <- load_cases()
  c(stats::setNames(statutes$short, statutes$id), stats::setNames(cases$short, cases$id))
}

# strip [[wiki links]] down to their display text
plain_wiki <- function(text, statutes) {
  lookup <- wiki_labels(statutes)
  stringr::str_replace_all(text, wiki_pattern, \(m) {
    parts <- stringr::str_match(m, wiki_pattern)
    dplyr::coalesce(parts[, 3], unname(lookup[parts[, 2]]))
  })
}

# loaders ----------------------------------------------------------------------

# read every YAML file in data/statutes into one tibble
load_statutes <- function(dir = "data/statutes") {
  recs <- list.files(dir, pattern = "\\.ya?ml$", full.names = TRUE) |>
    purrr::map(yaml::read_yaml) |>
    purrr::list_flatten()

  tibble::tibble(
    id           = chr_field(recs, "id"),
    title        = chr_field(recs, "title"),
    short        = chr_field(recs, "short"),
    year         = as.integer(chr_field(recs, "year")),
    enacted      = chr_field(recs, "enacted"),
    domain       = chr_field(recs, "domain"),
    layer        = chr_field(recs, "layer"),
    public_law   = chr_field(recs, "public_law"),
    stat         = chr_field(recs, "stat"),
    usc          = chr_field(recs, "usc"),
    usc_path     = chr_field(recs, "usc_path"),
    # set only on pages that describe a whole U.S. Code title
    code_title   = as.integer(chr_field(recs, "code_title")),
    status       = chr_field(recs, "status"),
    status_note  = chr_field(recs, "status_note"),
    summary      = chr_field(recs, "summary"),
    significance = chr_field(recs, "significance"),
    provisions   = purrr::map(list_field(recs, "provisions"), as.character),
    tags         = purrr::map(list_field(recs, "tags"), as.character),
    sources      = list_field(recs, "sources"),
    # programs: account, appropriations act, administering agency, committees
    funding      = list_field(recs, "funding"),
    checked      = dplyr::coalesce(chr_field(recs, "checked"), wiki_reviewed),
    # U.S. Code titles: parsed from the usc cite, plus any listed under usc_titles
    usc_titles   = purrr::map2(usc, list_field(recs, "usc_titles"), code_titles)
  ) |>
    dplyr::mutate(
      domain_label = unname(domain_labels[domain]),
      domain_name  = unname(domain_short[domain]),
      status_label = unname(status_labels[status]),
      layer_label  = unname(layer_labels[layer]),
      historic     = status %in% historic_status,
      era          = era_of(year)
    ) |>
    dplyr::arrange(year, title)
}

load_edges <- function(path = "data/edges.csv") {
  readr::read_csv(path, col_types = "cccc")
}

# every member lens, named by slug
load_members <- function(dir = "data/members") {
  files <- list.files(dir, pattern = "\\.ya?ml$", full.names = TRUE)
  members <- purrr::map(files, yaml::read_yaml)
  stats::setNames(members, purrr::map_chr(members, "slug"))
}

# study units in curriculum order
load_units <- function(path = "data/study/units.yml") {
  units <- yaml::read_yaml(path)
  units[order(purrr::map_int(units, "number"))]
}

# court cases, one row each; `statutes` holds the statutes each case decided
load_cases <- function(path = "data/cases.yml") {
  recs <- if (file.exists(path)) yaml::read_yaml(path) else list()
  tibble::tibble(
    id           = chr_field(recs, "id"),
    name         = chr_field(recs, "name"),
    short        = chr_field(recs, "short"),
    citation     = chr_field(recs, "citation"),
    year         = as.integer(chr_field(recs, "year")),
    decided      = chr_field(recs, "decided"),
    vote         = chr_field(recs, "vote"),
    domain       = chr_field(recs, "domain"),
    question     = chr_field(recs, "question"),
    holding      = chr_field(recs, "holding"),
    significance = chr_field(recs, "significance"),
    response     = chr_field(recs, "response"),
    standing     = chr_field(recs, "standing"),
    opinion      = chr_field(recs, "opinion"),
    wikipedia    = chr_field(recs, "wikipedia"),
    statutes     = list_field(recs, "statutes"),
    sources      = list_field(recs, "sources"),
    tags         = purrr::map(list_field(recs, "tags"), as.character)
  ) |>
    dplyr::mutate(
      domain_label = unname(domain_labels[domain]),
      domain_name  = unname(domain_short[domain]),
      era          = era_of(year),
      # official text: the bound U.S. Reports on GovInfo, else the listed slip opinion
      opinion_url  = dplyr::coalesce(usreports_url(citation), opinion)
    ) |>
    dplyr::arrange(year, name)
}

# agencies, offices, committees, and courts for the Who's who page
load_institutions <- function(path = "data/institutions.yml") {
  if (!file.exists(path)) return(list())
  yaml::read_yaml(path)
}

# links to official sources ------------------------------------------------------

# GovInfo public law link; the link service covers the 104th Congress onward
plaw_url <- function(public_law) {
  parts <- stringr::str_split_fixed(dplyr::coalesce(public_law, ""), "-", 2)
  congress <- suppressWarnings(as.integer(parts[, 1]))
  dplyr::if_else(
    !is.na(congress) & congress >= 104,
    paste0("https://www.govinfo.gov/link/plaw/", congress, "/public/", parts[, 2]),
    NA_character_
  )
}

# GovInfo Statutes at Large link. GovInfo holds every volume from 1789; the link
# service needs a numeric volume and the law's first page, so cites like
# "70A Stat. 1" or "112 Stat. 2681-761" fall back to the volume's page.
stat_url <- function(stat) {
  m <- stringr::str_match(dplyr::coalesce(stat, ""), "^(\\d+A?) Stat\\. ([0-9-]+)")
  vol <- m[, 2]
  page <- m[, 3]
  dplyr::case_when(
    is.na(vol) ~ NA_character_,
    grepl("^\\d+$", vol) & grepl("^\\d+$", page) ~ paste0("https://www.govinfo.gov/link/statute/", vol, "/", page),
    .default = paste0("https://www.govinfo.gov/app/details/STATUTE-", vol)
  )
}

# title and section for the codified text: usc_path when given, else the first plain cite
usc_target <- function(usc, usc_path) {
  parsed <- stringr::str_match(dplyr::coalesce(usc, ""), "^(\\d+) U\\.S\\.C\\. (\\d+[a-z0-9-]*)")
  from_cite <- dplyr::if_else(is.na(parsed[, 1]), NA_character_, paste0(parsed[, 2], "/", parsed[, 3]))
  dplyr::coalesce(usc_path, from_cite)
}

# GovInfo U.S. Code link (GPO's official edition); a bare title goes to the title's contents
usc_url <- function(target) {
  dplyr::case_when(
    is.na(target) ~ NA_character_,
    grepl("^\\d+$", target) ~ paste0("https://www.govinfo.gov/app/collection/uscode/2024/title", target),
    .default = paste0("https://www.govinfo.gov/link/uscode/", target, "?link-type=html")
  )
}

# Congress.gov page for a bill or resolution, e.g. bill_url(117, "hr", 7625)
bill_url <- function(congress, type, number) {
  suffix <- dplyr::case_when(
    congress %% 100 %in% 11:13 ~ "th",
    congress %% 10 == 1 ~ "st",
    congress %% 10 == 2 ~ "nd",
    congress %% 10 == 3 ~ "rd",
    .default = "th"
  )
  kind <- c(
    hr = "house-bill", s = "senate-bill", hres = "house-resolution", sres = "senate-resolution",
    hjres = "house-joint-resolution", sjres = "senate-joint-resolution",
    hconres = "house-concurrent-resolution", sconres = "senate-concurrent-resolution"
  )
  paste0("https://www.congress.gov/bill/", congress, suffix, "-congress/", kind[[tolower(type)]], "/", number)
}

bill_label <- function(type, number) {
  prefix <- c(hr = "H.R.", s = "S.", hres = "H.Res.", sres = "S.Res.", hjres = "H.J.Res.",
              sjres = "S.J.Res.", hconres = "H.Con.Res.", sconres = "S.Con.Res.")
  paste(prefix[[tolower(type)]], number)
}

# GovInfo PDF of a decision in the bound United States Reports, from a cite like "343 U.S. 579"
usreports_url <- function(citation) {
  m <- stringr::str_match(dplyr::coalesce(citation, ""), "^(\\d+) U\\.S\\. (\\d+)$")
  dplyr::if_else(is.na(m[, 1]), NA_character_,
                 paste0("https://www.govinfo.gov/content/pkg/USREPORTS-", m[, 2], "/pdf/USREPORTS-", m[, 2], "-", m[, 3], ".pdf"))
}

# a URL is official when it is served by a federal government domain
is_official <- function(url) {
  host <- stringr::str_match(url, "^https?://([^/]+)")[, 2]
  !is.na(host) & grepl("\\.(gov|mil)$", host)
}

# official links for one statute row: enacted text first, then the current code
official_links <- function(statutes) {
  statutes |>
    dplyr::mutate(
      plaw_link  = plaw_url(public_law),
      stat_link  = stat_url(stat),
      enact_link = dplyr::coalesce(plaw_link, stat_link),
      enact_label = dplyr::case_when(
        !is.na(plaw_link) ~ paste("Pub. L.", public_law),
        !is.na(stat_link) ~ stat,
        .default = NA_character_
      ),
      code_target = dplyr::if_else(grepl("^formerly", dplyr::coalesce(usc, "")), NA_character_, usc_target(usc, usc_path)),
      code_link   = usc_url(code_target),
      code_label  = dplyr::if_else(is.na(code_link), NA_character_,
                                   dplyr::coalesce(usc, paste0("Title ", code_target, ", U.S. Code")))
    )
}

# one row per source link: official links derived from citations, then the listed extras
build_sources <- function(statutes) {
  links <- official_links(statutes)

  primary_long <- dplyr::bind_rows(
    links |> dplyr::transmute(statute_id = id, source_type = "Enacted text (GovInfo, official)",
                              label = enact_label, url = enact_link),
    links |> dplyr::transmute(statute_id = id, source_type = "Current U.S. Code (GovInfo, official)",
                              label = code_label, url = code_link)
  ) |>
    dplyr::filter(!is.na(url))

  # sources listed by hand in the YAML
  extra <- purrr::map2(statutes$id, statutes$sources, \(id, src) {
    tibble::tibble(
      statute_id  = id,
      source_type = "Listed source",
      label       = purrr::map_chr(src, "label"),
      url         = purrr::map_chr(src, "url")
    )
  }) |>
    purrr::list_rbind()

  dplyr::bind_rows(primary_long, extra) |>
    dplyr::mutate(
      official = is_official(url),
      source_type = dplyr::if_else(source_type == "Listed source",
                                   dplyr::if_else(official, "Official government source", "Secondary or status source"),
                                   source_type)
    ) |>
    dplyr::arrange(statute_id, dplyr::desc(official), source_type)
}

# every source a member lens cites, one row per link
member_sources <- function(m) {
  item_rows <- function(items, kind) {
    purrr::map(items, \(x) {
      rows <- tibble::tibble(member = m$name, kind = kind, item = x$title %||% x$name,
                             label = x$source$label, url = x$source$url)
      if (!is.null(x$bill)) {
        rows <- dplyr::bind_rows(rows, tibble::tibble(
          member = m$name, kind = kind, item = x$title %||% x$name,
          label = paste0("Congress.gov, ", bill_label(x$bill$type, x$bill$number), " (", x$bill$congress, "th Congress)"),
          url = bill_url(x$bill$congress, x$bill$type, x$bill$number)
        ))
      }
      rows
    }) |>
      purrr::list_rbind()
  }
  dplyr::bind_rows(
    purrr::map(m$profile_sources, \(s) tibble::tibble(member = m$name, kind = "Profile", item = "Profile",
                                                      label = s$label, url = s$url)) |> purrr::list_rbind(),
    item_rows(m$committees, "Committee"),
    item_rows(m$initiatives, "Record"),
    item_rows(m$equities, "District interest")
  ) |>
    dplyr::mutate(official = is_official(url))
}

# wiki links -------------------------------------------------------------------

# turn [[id]] or [[id|display text]] into markdown links to statute pages
wiki_pattern <- "\\[\\[([a-z0-9-]+)(?:\\|([^\\]]+))?\\]\\]"

# `prefix` is the path from the current page to the statutes folder; court cases
# sit beside it in cases/
link_wiki <- function(text, statutes, prefix = "") {
  lookup <- wiki_labels(statutes)
  case_prefix <- if (prefix == "") "../cases/" else sub("statutes/$", "cases/", prefix)
  stringr::str_replace_all(text, wiki_pattern, \(m) {
    parts <- stringr::str_match(m, wiki_pattern)
    label <- dplyr::coalesce(parts[, 3], unname(lookup[parts[, 2]]))
    dir <- dplyr::if_else(parts[, 2] %in% statutes$id, prefix, case_prefix)
    paste0("[", label, "](", dir, parts[, 2], ".qmd)")
  })
}

# ids referenced by wiki links anywhere in a character vector
wiki_ids <- function(text) {
  stringr::str_match_all(stats::na.omit(text), wiki_pattern) |>
    purrr::map(\(m) m[, 2]) |>
    unlist() |>
    unique()
}

# markdown link to a statute page from a page at `prefix` depth, marked so the
# site-wide toggle can hide the row or item it heads
statute_md <- function(id, short_of, prefix = "statutes/", subject = TRUE) {
  cls <- if (subject) "{.subj}" else ""
  paste0("[", short_of[id], "](", prefix, id, ".qmd)", cls)
}

# graphs -----------------------------------------------------------------------

# a small network of a set of statutes and the edges among them, for unit and lens pages
# HTML legend for a mini_graph: only the domains, statuses and relationships
# that actually appear among these ids. Print it from a results: asis chunk.
mini_graph_legend <- function(ids, statutes, edges) {
  s <- statutes[statutes$id %in% ids, ]
  rel <- unique(edges$relation[edges$from %in% ids & edges$to %in% ids])
  rel <- names(relation_labels)[names(relation_labels) %in% rel]
  doms <- names(domain_labels)[names(domain_labels) %in% s$domain]
  item <- function(inner, label) {
    paste0("<span class=\"legend-item\">", inner, label, "</span>")
  }
  rows <- c(
    paste0("<div><strong>Domain (color)</strong>",
           paste0(item(paste0("<span class=\"swatch\" style=\"background:", domain_colors[doms], "\"></span>"),
                       domain_short[doms]), collapse = " "),
           "</div>"),
    paste0("<div><strong>Status (shape)</strong>",
           if (any(!s$historic)) item("<span class=\"shape shape-dot\"></span>", "In force or partly lapsed"),
           if (any(s$historic)) item("<span class=\"shape shape-triangle\"></span>", "Repealed or superseded"),
           "</div>"),
    if (length(rel)) paste0(
      "<div><strong>Relationship (line)</strong>",
      paste0(item(paste0("<span class=\"line\" style=\"border-color:", relation_colors[rel],
                         ";border-top-style:", ifelse(rel == "related", "dashed", "solid"), "\"></span>"),
                  ifelse(rel == "related", relation_labels[rel], paste0(relation_labels[rel], " &rarr;"))),
             collapse = " "),
      "</div>")
  )
  paste0("<div class=\"graph-legend mini-legend\">\n", paste(rows, collapse = "\n"),
         "\n<p class=\"legend-note\">Read an arrow as a sentence: the law at the tail amends, relies on ",
         "(and so on) the law at the head. Select a line for the details.</p>\n</div>\n")
}

mini_graph <- function(ids, statutes, edges, prefix = "../statutes/", height = "460px") {
  short_of <- stats::setNames(statutes$short, statutes$id)
  nodes <- statutes |>
    dplyr::filter(id %in% ids) |>
    dplyr::transmute(
      id, label = short, color = unname(domain_colors[domain]),
      shape = dplyr::if_else(historic, "triangleDown", "dot"),
      historic,
      title = paste0("<b>", title, "</b><br>", year, " | ", status_label, " | ", layer_label,
                     "<br><i>Double-click to open</i>"),
      url = paste0(prefix, id, ".html")
    )
  e <- edges |>
    dplyr::filter(from %in% ids, to %in% ids) |>
    dplyr::transmute(
      from, to,
      arrows = dplyr::if_else(relation == "related", "", "to"),
      dashes = relation == "related",
      color = unname(relation_colors[relation]),
      title = paste0(short_of[from], " <b>", relation_labels[relation], "</b> ", short_of[to], "<br>", note)
    )
  visNetwork::visNetwork(nodes, e, width = "100%", height = height) |>
    visNetwork::visNodes(size = 16, font = list(size = 18, color = "#1b2a41", strokeWidth = 4, strokeColor = "#ffffff")) |>
    visNetwork::visEdges(width = 1.6, smooth = list(type = "continuous")) |>
    visNetwork::visOptions(highlightNearest = list(enabled = TRUE, degree = 1)) |>
    visNetwork::visPhysics(solver = "forceAtlas2Based", forceAtlas2Based = list(gravitationalConstant = -80),
                           stabilization = list(iterations = 300)) |>
    visNetwork::visLayout(randomSeed = 7) |>
    visNetwork::visInteraction(tooltipDelay = 120) |>
    visNetwork::visEvents(doubleClick = "function(p) {
      if (p.nodes.length) { window.location.href = this.body.data.nodes.get(p.nodes[0]).url; }
    }") |>
    # hide repealed and superseded nodes when the site-wide toggle is on
    htmlwidgets::onRender("function(el) { if (window.wikiWatchGraph) window.wikiWatchGraph(el); }")
}
