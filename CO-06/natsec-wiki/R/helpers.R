# Shared helpers for R/build_pages.R and the Quarto pages.
# All paths are relative to the project root.

# controlled vocabularies
domain_labels <- c(
  "war-powers"     = "War powers and use of force",
  "intelligence"   = "Intelligence and surveillance",
  "aid-sanctions"  = "Foreign aid, fragility and sanctions",
  "defense-arms"   = "Defense organization and arms transfers",
  "foreign-policy" = "Related foreign policy",
  "foundations"    = "Constitutional and code foundations"
)

domain_colors <- c(
  "war-powers"     = "#b5403a",
  "intelligence"   = "#3b5b92",
  "aid-sanctions"  = "#2e7d6b",
  "defense-arms"   = "#b07a1e",
  "foreign-policy" = "#6b4c8a",
  "foundations"    = "#44505f"
)

# short domain names for menus (no commas, so they can be combined in one filter)
domain_short <- c(
  "war-powers"     = "War powers",
  "intelligence"   = "Intelligence",
  "aid-sanctions"  = "Aid and sanctions",
  "defense-arms"   = "Defense and arms",
  "foreign-policy" = "Foreign policy",
  "foundations"    = "Foundations"
)

status_labels <- c(
  "in-force"       = "In force",
  "partly-expired" = "Partly expired",
  "lapsed"         = "Lapsed",
  "repealed"       = "Repealed",
  "superseded"     = "Superseded"
)

# relation read from the "from" side and from the "to" side
relation_labels <- c(
  amends = "amends", repeals = "repeals", succeeds = "succeeds",
  relies_on = "relies on", constrains = "constrains",
  enacted_in = "enacted in", related = "related to"
)

relation_inverse <- c(
  amends = "amended by", repeals = "repealed by", succeeds = "succeeded by",
  relies_on = "relied on by", constrains = "constrained by",
  enacted_in = "vehicle for", related = "related to"
)

relation_colors <- c(
  amends = "#3b5b92", repeals = "#b5403a", succeeds = "#b07a1e",
  relies_on = "#2e7d6b", constrains = "#6b4c8a",
  enacted_in = "#5c6670", related = "#b4bac1"
)

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
title_label <- function(n) paste("U.S. Code Title", n)

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
    # U.S. Code titles: parsed from the usc cite, plus any listed under usc_titles
    usc_titles   = purrr::map2(usc, list_field(recs, "usc_titles"), code_titles)
  ) |>
    dplyr::mutate(
      domain_label = unname(domain_labels[domain]),
      status_label = unname(status_labels[status])
    ) |>
    dplyr::arrange(year, title)
}

load_edges <- function(path = "data/edges.csv") {
  readr::read_csv(path, col_types = "cccc")
}

# GovInfo public law link; the link service covers the 104th Congress onward
plaw_url <- function(public_law) {
  parts <- stringr::str_split_fixed(public_law, "-", 2)
  congress <- suppressWarnings(as.integer(parts[, 1]))
  dplyr::if_else(
    !is.na(congress) & congress >= 104,
    paste0("https://www.govinfo.gov/link/plaw/", congress, "/public/", parts[, 2]),
    NA_character_
  )
}

# GovInfo Statutes at Large link; the link service covers volume 65 onward
stat_url <- function(stat) {
  m <- stringr::str_match(stat, "^(\\d+) Stat\\. (\\d+)")
  vol <- suppressWarnings(as.integer(m[, 2]))
  dplyr::if_else(
    !is.na(vol) & vol >= 65,
    paste0("https://www.govinfo.gov/link/statute/", vol, "/", m[, 3]),
    NA_character_
  )
}

# Cornell LII link to the codified text
usc_url <- function(usc_path) {
  dplyr::if_else(
    !is.na(usc_path),
    paste0("https://www.law.cornell.edu/uscode/text/", usc_path),
    NA_character_
  )
}

# one row per source link: primary links derived from citations, then listed extras
build_sources <- function(statutes) {
  primary <- statutes |>
    dplyr::mutate(
      plaw_link = plaw_url(public_law),
      # use the Statutes at Large link only when no public law link exists
      stat_link = dplyr::if_else(is.na(plaw_link), stat_url(stat), NA_character_),
      usc_link  = usc_url(usc_path)
    )

  primary_long <- dplyr::bind_rows(
    primary |> dplyr::transmute(statute_id = id, source_type = "Public law text (GovInfo)",
                                label = paste("Pub. L.", public_law), url = plaw_link),
    primary |> dplyr::transmute(statute_id = id, source_type = "Statutes at Large (GovInfo)",
                                label = stat, url = stat_link),
    primary |> dplyr::transmute(statute_id = id, source_type = "U.S. Code (Cornell LII)",
                                label = usc, url = usc_link)
  ) |>
    dplyr::filter(!is.na(url))

  # sources listed by hand in the YAML
  extra <- purrr::map2(statutes$id, statutes$sources, \(id, src) {
    tibble::tibble(
      statute_id  = id,
      source_type = "Secondary or status source",
      label       = purrr::map_chr(src, "label"),
      url         = purrr::map_chr(src, "url")
    )
  }) |>
    purrr::list_rbind()

  dplyr::bind_rows(primary_long, extra) |>
    dplyr::arrange(statute_id, source_type)
}

# turn [[id]] or [[id|display text]] into markdown links to statute pages
wiki_pattern <- "\\[\\[([a-z0-9-]+)(?:\\|([^\\]]+))?\\]\\]"

link_wiki <- function(text, statutes) {
  lookup <- stats::setNames(statutes$short, statutes$id)
  stringr::str_replace_all(text, wiki_pattern, \(m) {
    parts <- stringr::str_match(m, wiki_pattern)
    label <- dplyr::coalesce(parts[, 3], unname(lookup[parts[, 2]]))
    paste0("[", label, "](", parts[, 2], ".qmd)")
  })
}

# ids referenced by wiki links anywhere in a character vector
wiki_ids <- function(text) {
  stringr::str_match_all(text, wiki_pattern) |>
    purrr::map(\(m) m[, 2]) |>
    unlist() |>
    unique()
}
