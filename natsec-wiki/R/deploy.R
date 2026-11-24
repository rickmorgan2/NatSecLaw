# Build and run the wiki locally.
#
# From a terminal, anywhere inside the repo:
#   Rscript R/deploy.R            install missing packages, render, preview with live reload
#   Rscript R/deploy.R render     render the site into docs/ and stop
#   Rscript R/deploy.R serve      serve the existing docs/ as static files, no rebuild
#   Rscript R/deploy.R zip        render, then write natsec-wiki-site.zip for offline sharing
#   Rscript R/deploy.R check      render, then test every internal link and, with chromote,
#                                 key pages on a phone-sized screen (see R/check_site.R)
#
# From RStudio or Positron: source the file (runs preview), or set the mode first,
#   options(deploy.mode = "render"); source("R/deploy.R")
#
# Settings: env var QUARTO_PATH points at a specific quarto binary; option deploy.port
# or env var WIKI_PORT sets the preview port (default 4321).

mode <- c(commandArgs(trailingOnly = TRUE), getOption("deploy.mode", "preview"))[1]
modes <- c("preview", "render", "serve", "zip", "check")
if (!mode %in% modes) stop("Unknown mode '", mode, "'. Use one of: ", paste(modes, collapse = ", "), call. = FALSE)

port <- getOption("deploy.port", Sys.getenv("WIKI_PORT", "4321"))

# locate the project root (the folder holding _quarto.yml) from the script or working dir
script_dir <- function() {
  f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
  if (length(f)) return(dirname(normalizePath(f)))
  for (fr in rev(sys.frames())) if (!is.null(fr$ofile)) return(dirname(normalizePath(fr$ofile)))
  getwd()
}

find_root <- function(start) {
  for (dir in unique(c(start, getwd()))) {
    repeat {
      if (file.exists(file.path(dir, "_quarto.yml"))) return(normalizePath(dir))
      parent <- dirname(dir)
      if (parent == dir) break
      dir <- parent
    }
  }
  stop("No _quarto.yml found. Run this from inside the natsec-wiki folder.", call. = FALSE)
}

root <- find_root(script_dir())

# Quarto: PATH first, then standalone installs, then the copies bundled with RStudio and Positron
find_quarto <- function() {
  local <- Sys.getenv("LOCALAPPDATA")
  candidates <- c(
    Sys.getenv("QUARTO_PATH"),
    Sys.which("quarto"),
    if (requireNamespace("quarto", quietly = TRUE)) tryCatch(quarto::quarto_path(), error = function(e) NULL),
    "C:/Program Files/Quarto/bin/quarto.exe",
    file.path(local, "Programs/Quarto/bin/quarto.exe"),
    "C:/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe",
    "C:/Program Files/Positron/resources/app/quarto/bin/quarto.exe",
    file.path(local, "Programs/Positron/resources/app/quarto/bin/quarto.exe"),
    "/Applications/quarto/bin/quarto",
    "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto",
    "/Applications/Positron.app/Contents/Resources/app/quarto/bin/quarto",
    "/usr/local/bin/quarto",
    "/opt/quarto/bin/quarto"
  )
  hit <- candidates[nzchar(candidates) & file.exists(candidates)][1]
  if (is.na(hit)) stop("Quarto not found. Install it from https://quarto.org/docs/get-started/ or set QUARTO_PATH.", call. = FALSE)
  normalizePath(hit)
}

quarto_bin <- find_quarto()
# system2 quotes the command itself on Windows but not elsewhere
quarto_cmd <- if (.Platform$OS.type == "windows") quarto_bin else shQuote(quarto_bin)

quarto_version <- system2(quarto_cmd, "--version", stdout = TRUE) |> trimws()
if (numeric_version(quarto_version) < "1.4") stop("Quarto ", quarto_version, " found; 1.4 or later is required.", call. = FALSE)
message("Quarto ", quarto_version, " at ", quarto_bin)

# run quarto from the project root, restoring the caller's working directory afterwards
run_quarto <- function(...) {
  args <- c(...)
  old <- setwd(root)
  on.exit(setwd(old))
  status <- system2(quarto_cmd, args)
  if (status != 0) stop("quarto ", paste(args, collapse = " "), " failed with exit code ", status, call. = FALSE)
  invisible(status)
}

# render modes need the packages that build_pages.R and the pages use; serve only needs servr
pkgs <- switch(mode,
  serve = "servr",
  zip   = c("yaml", "dplyr", "purrr", "readr", "stringr", "tibble", "knitr", "rmarkdown", "DT", "visNetwork", "zip"),
  check = c("yaml", "dplyr", "purrr", "readr", "stringr", "tibble", "knitr", "rmarkdown", "DT", "visNetwork"),
  c("yaml", "dplyr", "purrr", "readr", "stringr", "tibble", "knitr", "rmarkdown", "DT", "visNetwork")
)
missing <- setdiff(pkgs, rownames(utils::installed.packages()))
if (length(missing)) {
  message("Installing: ", paste(missing, collapse = ", "))
  utils::install.packages(missing, repos = "https://cloud.r-project.org")
}
# make Quarto's pre-render step use this R, which has the packages
Sys.setenv(QUARTO_R = R.home("bin"))

switch(mode,
  preview = {
    message("Preview at http://localhost:", port, "  (Ctrl+C to stop)")
    run_quarto("preview", "--port", port)
  },
  render = {
    run_quarto("render")
    message("Site built in ", file.path(root, "docs"))
  },
  serve = {
    # plain static server: quarto preview would re-run build_pages.R on every request
    if (!file.exists(file.path(root, "docs", "index.html"))) stop("docs/ is empty. Run the render mode first.", call. = FALSE)
    message("Serving docs/ at http://localhost:", port, "  (Ctrl+C to stop)")
    servr::httd(file.path(root, "docs"), port = as.integer(port), browser = interactive(), daemon = FALSE)
  },
  check = {
    run_quarto("render")
    source(file.path(root, "R", "check_site.R"))
    check_site(root)
  },
  zip = {
    run_quarto("render")
    zipfile <- file.path(root, "natsec-wiki-site.zip")
    unlink(zipfile)
    zip::zip(zipfile, files = "docs", root = root)
    message("Wrote ", zipfile, ". Recipients unzip it and open docs/index.html; full-text search needs a server, everything else works offline.")
  }
)
