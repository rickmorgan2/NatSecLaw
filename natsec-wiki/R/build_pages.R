# Generate the statute pages, member pages, study units, site data, and manifests.
# Run from the project root: Rscript R/build_pages.R
# Quarto also runs this before every render (see _quarto.yml).

source("R/helpers.R")

statutes <- load_statutes()
edges    <- load_edges()
members  <- load_members()
units    <- load_units()

# validation -------------------------------------------------------------------

member_ids <- purrr::map(members, \(m) unlist(purrr::map(c(m$committees, m$initiatives, m$equities), "statutes")))
unit_ids   <- unlist(purrr::map(units, \(u) c(u$core, u$further)))
answer_txt <- unlist(purrr::map(units, \(u) purrr::map_chr(u$questions, "a")))

stopifnot(
  "duplicate statute ids"         = !anyDuplicated(statutes$id),
  "unknown domain in statutes"    = all(statutes$domain %in% names(domain_labels)),
  "unknown status in statutes"    = all(statutes$status %in% names(status_labels)),
  "missing or unknown layer"      = all(statutes$layer %in% names(layer_labels)),
  "edge points to unknown id"     = all(c(edges$from, edges$to) %in% statutes$id),
  "unknown relation in edges"     = all(edges$relation %in% names(relation_labels)),
  "[[wiki link]] to unknown id"   = all(wiki_ids(c(statutes$summary, statutes$significance, answer_txt)) %in% statutes$id),
  "member file points to unknown id" = all(unlist(member_ids) %in% statutes$id),
  "study unit points to unknown id"  = all(unit_ids %in% statutes$id),
  "duplicate unit ids"            = !anyDuplicated(purrr::map_chr(units, "id"))
)

# statutes no unit covers are allowed, but worth knowing about
uncovered <- setdiff(statutes$id, unit_ids)
if (length(uncovered)) message("Not in any study unit: ", paste(uncovered, collapse = ", "))

short_of <- stats::setNames(statutes$short, statutes$id)
sources  <- build_sources(statutes)
links    <- official_links(statutes)

# helpers for page text --------------------------------------------------------

# comma-separated links to statute pages from inside statutes/
sib_links <- function(ids) paste0("[", short_of[ids], "](", ids, ".qmd)", collapse = ", ")

# markdown table of every edge touching one statute
connections_md <- function(id) {
  out <- edges |>
    dplyr::filter(from == id) |>
    dplyr::transmute(rel = relation_labels[relation], other = to, note)
  inc <- edges |>
    dplyr::filter(to == id) |>
    dplyr::transmute(rel = relation_inverse[relation], other = from, note)
  rows <- dplyr::bind_rows(out, inc)
  if (nrow(rows) == 0) return("No connections recorded yet.")

  c(
    "| This statute | Other statute | Note |",
    "|---|---|---|",
    paste0("| ", rows$rel, " | [", short_of[rows$other], "](", rows$other, ".qmd){.subj} | ", rows$note, " |")
  )
}

# for a code-title page: every other statute in the wiki codified in that title
members_md <- function(s) {
  if (is.na(s$code_title)) return(character(0))
  m <- statutes |>
    dplyr::filter(purrr::map_lgl(usc_titles, \(x) s$code_title %in% x), id != s$id) |>
    dplyr::arrange(year)
  c(
    "## Statutes in this wiki codified here",
    "",
    "| Statute | Year | Citation | Status |",
    "|---|---|---|---|",
    paste0("| [", m$short, "](", m$id, ".qmd){.subj} | ", m$year, " | ", m$usc, " | ", m$status_label, " |"),
    ""
  )
}

# where a statute sits: layer, dependencies, code titles, study units, member lenses
position_md <- function(s) {
  builds_on  <- edges |> dplyr::filter(from == s$id, relation %in% dependency_relations) |> dplyr::pull(to) |> unique()
  built_upon <- edges |> dplyr::filter(to == s$id, relation %in% dependency_relations) |> dplyr::pull(from) |> unique()
  titles     <- s$usc_titles[[1]]
  title_pages <- intersect(paste0("title", titles, "-usc"), statutes$id)

  in_units <- purrr::keep(units, \(u) s$id %in% c(u$core, u$further))
  unit_md <- purrr::map_chr(in_units, \(u) {
    role <- if (s$id %in% u$core) "core reading" else "further reading"
    paste0("[Unit ", u$number, ": ", u$title, "](../study/units/", u$id, ".qmd) (", role, ")")
  })

  lens_md <- purrr::map_chr(members, \(m) {
    hits <- c(
      purrr::map_chr(purrr::keep(m$committees, \(x) s$id %in% x$statutes), "short"),
      purrr::map_chr(purrr::keep(m$initiatives, \(x) s$id %in% x$statutes), "short"),
      purrr::map_chr(purrr::keep(m$equities, \(x) s$id %in% x$statutes), "short")
    )
    if (!length(hits)) return(NA_character_)
    paste0("[", m$name, "](../members/", m$slug, ".qmd): ", paste(unique(hits), collapse = "; "))
  }) |>
    stats::na.omit()

  c(
    "## Where it sits",
    "",
    paste0("- **Layer.** ", s$layer_label, ". ", layer_desc[[s$layer]], " ([How the layers work](../study/index.qmd#the-authority-stack))"),
    if (length(builds_on)) paste0("- **Builds on.** ", sib_links(builds_on), "."),
    if (length(built_upon)) paste0("- **Built upon by.** ", sib_links(built_upon), "."),
    if (length(title_pages)) paste0("- **Codified in.** ", sib_links(title_pages), "."),
    paste0("- **Era.** ", s$era, " ([timeline](../study/timeline.qmd))."),
    if (length(unit_md)) paste0("- **Study.** ", paste(unit_md, collapse = "; "), "."),
    if (length(lens_md)) paste0("- **Member lenses.** ", paste(lens_md, collapse = ". "), "."),
    ""
  )
}

# source list for one statute, official links first
sources_md <- function(id) {
  src <- sources |> dplyr::filter(statute_id == id)
  paste0("- ", src$source_type, ": [", src$label, "](", src$url, ")")
}

# citation chips, each linked to its official text where one exists
cite_md <- function(s, l) {
  chip <- function(text, url) {
    if (is.na(text)) return(NULL)
    if (is.na(url)) paste0("[", text, "]{.cite}") else paste0("[", text, "](", url, "){.cite}")
  }
  c(
    if (!is.na(s$public_law)) chip(paste("Pub. L.", s$public_law), l$plaw_link %|% l$stat_link),
    chip(s$stat, l$stat_link),
    chip(s$usc, l$code_link)
  ) |>
    paste(collapse = " ")
}

`%|%` <- function(a, b) if (is.na(a)) b else a

# buttons to the official text
official_md <- function(l) {
  btns <- c(
    if (!is.na(l$enact_link)) paste0("[Enacted text: ", l$enact_label, "](", l$enact_link, "){.btn-official}"),
    if (!is.na(l$code_link)) paste0("[Current U.S. Code: ", l$code_label, "](", l$code_link, "){.btn-official}")
  )
  if (!length(btns)) return(character(0))
  c("::: {.official-links}", "**Read the law** (official GovInfo text)", "", paste(btns, collapse = " "), ":::", "")
}

# full .qmd text for one statute (s and l are one-row tibbles)
page_md <- function(s, l) {
  cites <- c(
    if (!is.na(s$public_law)) paste("Pub. L.", s$public_law),
    stats::na.omit(c(s$stat, s$usc))
  )

  front <- list(
    title      = s$title,
    year       = s$year,
    domain     = s$domain_name,
    layer      = s$layer_label,
    status     = s$status_label,
    cite       = paste(cites, collapse = "; "),
    categories = c(s$domain_name, s$status_label, s$layer_label, title_label(s$usc_titles[[1]]))
  )

  historic_note <- if (s$historic) c(
    "::: {.callout-warning .historic-banner}",
    paste0("This law is **", tolower(s$status_label), "**. It is kept for its history and its links to current law. ",
           "The site-wide switch in the top bar hides repealed and superseded laws from lists, tables, and graphs."),
    ":::",
    ""
  )

  c(
    "---",
    trimws(yaml::as.yaml(front)),
    "---",
    "",
    "<!-- Generated by R/build_pages.R from data/. Edit the YAML, not this file. -->",
    "",
    paste0("::: {.cite-bar .domain-", s$domain, "}"),
    paste0("[", s$status_label, "]{.status .status-", s$status, "} [", s$layer_label, "]{.layer-badge} ", cite_md(s, l)),
    ":::",
    "",
    historic_note,
    link_wiki(s$summary, statutes),
    "",
    official_md(l),
    "## Key provisions",
    "",
    paste0("- ", s$provisions[[1]]),
    "",
    "## Why it matters",
    "",
    link_wiki(s$significance, statutes),
    "",
    "## Current status",
    "",
    s$status_note,
    "",
    members_md(s),
    position_md(s),
    "## Connections",
    "",
    connections_md(s$id),
    "",
    paste0("[See this statute in the knowledge graph](../graph.qmd?focus=", s$id, ")"),
    "",
    "## Sources",
    "",
    sources_md(s$id),
    "",
    paste0("Tags: ", paste(s$tags[[1]], collapse = ", ")),
    ""
  )
}

# write a file only when its content changed, so Quarto can skip unchanged pages
write_if_changed <- function(lines, path) {
  if (!file.exists(path) || !identical(readLines(path, warn = FALSE), lines)) {
    writeLines(lines, path, useBytes = TRUE)
  }
}

# drop generated pages whose source was removed
prune <- function(dir, keep) {
  stale <- setdiff(list.files(dir, pattern = "\\.qmd$"), c(keep, list.files(dir, pattern = "^_")))
  invisible(file.remove(file.path(dir, stale)))
}

# statute pages ----------------------------------------------------------------

dir.create("statutes", showWarnings = FALSE)
prune("statutes", paste0(statutes$id, ".qmd"))
for (i in seq_len(nrow(statutes))) {
  write_if_changed(page_md(statutes[i, ], links[i, ]), file.path("statutes", paste0(statutes$id[i], ".qmd")))
}

# member pages: a stub per member that includes the shared lens body -----------

dir.create("members", showWarnings = FALSE)
prune("members", c(paste0(names(members), ".qmd"), "index.qmd"))
for (m in members) {
  write_if_changed(c(
    "---",
    paste0("title: \"", m$name, " (", m$district, ")\""),
    "subtitle: \"Member lens: committees, record, and district interests mapped onto the statutes.\"",
    "toc: true",
    "page-layout: full",
    "params:",
    paste0("  slug: ", m$slug),
    "---",
    "",
    "<!-- Generated by R/build_pages.R from data/members. -->",
    "",
    "{{< include _lens.qmd >}}"
  ), file.path("members", paste0(m$slug, ".qmd")))
}

# study units --------------------------------------------------------------------

dir.create("study/units", showWarnings = FALSE, recursive = TRUE)
prune("study/units", paste0(purrr::map_chr(units, "id"), ".qmd"))

reading_card <- function(id, core = TRUE) {
  s <- statutes[statutes$id == id, ]
  l <- links[links$id == id, ]
  read <- c(
    if (!is.na(l$enact_link)) paste0("[enacted text](", l$enact_link, ")"),
    if (!is.na(l$code_link)) paste0("[current code](", l$code_link, ")")
  )
  c(
    paste0("::: {.reading-card .domain-", s$domain, " data-statute=\"", id, "\"}"),
    paste0("[", s$short, "](../../statutes/", id, ".qmd) [", s$year, "]{.reading-year} ",
           "[", s$status_label, "]{.status .status-", s$status, "} [", s$layer_label, "]{.layer-badge}"),
    "",
    plain_wiki(first_sentence(s$summary), statutes),
    "",
    paste0("[Read it: ", paste(read, collapse = ", "), "]{.reading-links} ",
           if (core) paste0("<label class=\"read-check\"><input type=\"checkbox\" data-read=\"", id, "\"> I have read this</label>")),
    ":::",
    ""
  )
}

for (k in seq_along(units)) {
  u <- units[[k]]
  prev_u <- if (k > 1) units[[k - 1]]
  next_u <- if (k < length(units)) units[[k + 1]]
  nav <- c(
    "::: {.unit-nav}",
    paste(c(
      if (!is.null(prev_u)) paste0("[Previous: Unit ", prev_u$number, ". ", prev_u$title, "](", prev_u$id, ".qmd)"),
      "[All units](../index.qmd#the-units)",
      if (!is.null(next_u)) paste0("[Next: Unit ", next_u$number, ". ", next_u$title, "](", next_u$id, ".qmd)")
    ), collapse = " | "),
    ":::",
    ""
  )
  questions <- purrr::imap(u$questions, \(q, i) c(
    paste0("::: {.callout-tip collapse=\"true\" icon=\"false\"}"),
    paste0("## ", i, ". ", q$q),
    "",
    link_wiki(q$a, statutes, prefix = "../../statutes/"),
    ":::",
    ""
  )) |>
    unlist()

  write_if_changed(c(
    "---",
    paste0("title: \"Unit ", u$number, ": ", u$title, "\""),
    paste0("subtitle: \"", u$question, "\""),
    "toc: true",
    "---",
    "",
    "<!-- Generated by R/build_pages.R from data/study/units.yml. -->",
    "",
    nav,
    u$overview,
    "",
    "## What you should be able to do",
    "",
    paste0("- ", unlist(u$objectives)),
    "",
    "## Reading path",
    "",
    "Read these in order. Each card links to the wiki page and to the official text. Ticking a box saves your progress in this browser only.",
    "",
    unlist(purrr::map(u$core, reading_card)),
    if (length(u$pages)) c(
      paste0("Also read: ", paste0("[", purrr::map_chr(u$pages, "label"), "](", purrr::map_chr(u$pages, "href"), ")", collapse = "; "), "."),
      ""
    ),
    "## How they connect",
    "",
    "Core and further readings with the relationships recorded between them. Click to highlight, double-click to open.",
    "",
    "```{r}",
    "source(\"R/helpers.R\")",
    paste0("unit_ids <- c(\"", paste(c(u$core, u$further), collapse = "\", \""), "\")"),
    "mini_graph(unit_ids, load_statutes(), load_edges(), prefix = \"../../statutes/\")",
    "```",
    "",
    "```{r}",
    "#| results: asis",
    "cat(mini_graph_legend(unit_ids, load_statutes(), load_edges()))",
    "```",
    "",
    if (length(u$further)) c(
      "## Further reading",
      "",
      paste0("- ", statute_md(unlist(u$further), short_of, prefix = "../../statutes/"), ": ",
             plain_wiki(first_sentence(statutes$summary[match(unlist(u$further), statutes$id)]), statutes)),
      ""
    ),
    "## Key terms",
    "",
    unlist(purrr::map(u$terms, \(t) c(paste0("**", t$term, "**"), paste0(":   ", t$definition), ""))),
    "## Check yourself",
    "",
    "Try to answer each question before opening it.",
    "",
    questions,
    nav
  ), file.path("study/units", paste0(u$id, ".qmd")))
}

# site-wide data for the status toggle and link marking ---------------------------

dir.create("_includes", showWarnings = FALSE)
wiki_map <- purrr::set_names(
  purrr::pmap(list(statutes$status, statutes$historic, statutes$short, statutes$domain),
              \(st, h, sh, d) list(s = st, h = h, n = sh, d = d)),
  statutes$id
)
write_if_changed(c(
  "<!-- Generated by R/build_pages.R. Statute status for the site-wide toggle. -->",
  "<script>",
  paste0("window.WIKI = ", jsonlite::toJSON(wiki_map, auto_unbox = TRUE), ";"),
  "</script>"
), "_includes/wiki-data.html")

# manifests ------------------------------------------------------------------------

statutes |>
  dplyr::transmute(
    id, title, year, enacted, domain = domain_label, layer = layer_label, status = status_label,
    public_law, statutes_at_large = stat, us_code = usc,
    usc_titles = purrr::map_chr(usc_titles, \(x) paste(x, collapse = "; ")),
    wiki_page = paste0("statutes/", id, ".html")
  ) |>
  readr::write_csv("data/manifest_documents.csv", na = "")

readr::write_csv(sources, "data/manifest_sources.csv", na = "")

# every source the wiki draws on, in one file
refs     <- readr::read_csv("data/reference_sources.csv", col_types = "cccc")
research <- readr::read_csv("data/research_sources.csv", col_types = "cccc")
all_sources <- dplyr::bind_rows(
  sources |>
    dplyr::transmute(group = "Statute", context = short_of[statute_id], type = source_type, label, url),
  purrr::map(members, member_sources) |>
    purrr::list_rbind() |>
    dplyr::transmute(group = "Member lens", context = paste0(member, ": ", item), type = kind, label, url),
  refs |> dplyr::transmute(group = "Reference", context = used_for, type = type, label = name, url),
  research |> dplyr::transmute(group = "Research for this edition", context = used_for, type = type, label = name, url)
) |>
  dplyr::mutate(official = is_official(url)) |>
  dplyr::distinct(group, context, label, url, .keep_all = TRUE)
readr::write_csv(all_sources, "data/all_sources.csv", na = "")

message(
  "Built ", nrow(statutes), " statute pages, ", length(members), " member lenses, ",
  length(units), " study units, ", nrow(edges), " edges, ",
  nrow(all_sources), " source links (", sum(all_sources$official), " official)."
)
