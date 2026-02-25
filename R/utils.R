write_to_path <- function(text, filepath) {
  fs::dir_create(fs::path_dir(filepath), recurse = TRUE)
  writeLines(text, filepath)
}

find_replace_in_file <- function(from, to, file, fixed = TRUE) {
  x <- readLines(file, warn = FALSE)
  if (any(grepl(from, x, fixed = fixed))) {
    writeLines(gsub(from, to, x, fixed = fixed), file)
    TRUE
  } else {
    FALSE
  }
}

find_replace_in_dir <- function(from, to, path, pattern) {
  for (f in list.files(
    path,
    recursive = TRUE,
    full.names = TRUE,
    pattern = pattern
  )) {
    find_replace_in_file(from, to, f)
  }
}

find_replace_in_gha <- function(from, to) {
  find_replace_in_dir(
    from = from,
    to = to,
    path = ".github/workflows",
    pattern = "\\.ya?ml$"
  )
}
