# Checks on the built site in docs/, run by `Rscript R/deploy.R check` after a render.
#   1. Every relative link and src points to a file that exists.
#   2. If the chromote package and Chrome are available, key pages emulated on a
#      390px-wide phone neither overflow the screen nor throw JavaScript errors.
# Stops with a list of problems if any check fails.

# relative href and src targets in one page that do not resolve to a file
broken_links <- function(file) {
  x <- paste(readLines(file, warn = FALSE), collapse = "\n")
  refs <- regmatches(x, gregexpr('(href|src)="[^"]*"', x))[[1]]
  refs <- sub('^(href|src)="', "", sub('"$', "", refs))
  # skip external links, anchors, data URIs, and fragments of JavaScript string building
  refs <- refs[!grepl("^(https?:|mailto:|#|javascript:|data:|//)", refs) & !grepl("['+ ]", refs)]
  refs <- unique(sub("[?#].*$", "", refs))
  refs <- refs[nzchar(refs)]
  refs[!file.exists(file.path(dirname(file), refs))]
}

check_links <- function(docs) {
  pages <- list.files(docs, pattern = "\\.html$", recursive = TRUE, full.names = TRUE)
  pages <- pages[!grepl("/v1/", pages)]
  bad <- purrr::map(pages, broken_links)
  names(bad) <- sub(paste0("^", docs, "/"), "", pages)
  bad <- purrr::compact(bad)
  message("Links: ", length(pages), " pages checked, ", length(bad), " with broken internal links.")
  purrr::imap_chr(bad, \(t, p) paste0(p, ": ", paste(t, collapse = ", ")))
}

check_phone <- function(docs, pages) {
  if (!requireNamespace("chromote", quietly = TRUE)) {
    message("Phone check skipped: install the chromote package to run it.")
    return(character(0))
  }
  b <- tryCatch(chromote::ChromoteSession$new(), error = function(e) NULL)
  if (is.null(b)) {
    message("Phone check skipped: Chrome could not be started.")
    return(character(0))
  }
  on.exit(b$close(), add = TRUE)
  b$Emulation$setDeviceMetricsOverride(width = 390, height = 844, deviceScaleFactor = 1, mobile = TRUE)
  errors <- character(0)
  b$Runtime$enable()
  b$Runtime$exceptionThrown(callback_ = function(m) {
    errors <<- c(errors, m$exceptionDetails$exception$description %||% m$exceptionDetails$text)
  })
  problems <- character(0)
  for (p in pages) {
    n0 <- length(errors)
    url <- paste0("file:///", normalizePath(file.path(docs, p), winslash = "/"))
    b$Page$navigate(url, wait_ = TRUE)
    Sys.sleep(3)
    # this call also lets chromote deliver any error events from the page
    width <- b$Runtime$evaluate("document.documentElement.scrollWidth")$result$value
    if (width > 391) problems <- c(problems, paste0(p, ": page is ", width, "px wide on a 390px phone"))
    if (length(errors) > n0) problems <- c(problems, paste0(p, ": JavaScript error: ", errors[(n0 + 1):length(errors)]))
  }
  message("Phone: ", length(pages), " pages checked at 390px, ", length(problems), " problems.")
  problems
}

check_site <- function(root) {
  docs <- file.path(root, "docs")
  if (!file.exists(file.path(docs, "index.html"))) stop("docs/ is empty. Render first.", call. = FALSE)
  phone_pages <- c("index.html", "graph.html", "statutes/wpr-1973.html", "statutes/fmf.html",
                   "cases/youngstown-1952.html", "study/index.html", "study/units/purse.html",
                   "study/flashcards.html", "whos-who.html", "sources.html")
  phone_pages <- phone_pages[file.exists(file.path(docs, phone_pages))]
  problems <- c(check_links(docs), check_phone(docs, phone_pages))
  if (length(problems)) {
    stop("Site check failed:\n  ", paste(utils::head(problems, 40), collapse = "\n  "), call. = FALSE)
  }
  message("Site check passed.")
}
