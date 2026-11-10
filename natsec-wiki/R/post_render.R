# Copy the archived first version of the site into docs/v1 so it is published
# alongside this one. Quarto runs this after every render (see _quarto.yml).

archive <- file.path("..", "archive", "natsec-wiki-v1", "docs")

# a partial render sets QUARTO_PROJECT_RENDER_ALL to empty; only copy on full renders
if (dir.exists(archive) && nzchar(Sys.getenv("QUARTO_PROJECT_RENDER_ALL"))) {
  target <- file.path("docs", "v1")
  unlink(target, recursive = TRUE)
  dir.create(target, recursive = TRUE)
  ok <- file.copy(list.files(archive, full.names = TRUE), target, recursive = TRUE)
  message("Copied version 1 into docs/v1 (", sum(ok), " top-level items).")
}
