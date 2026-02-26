#' Write Text to a Path
#'
#' Creates parent directories as needed, then writes `text` to `filepath`.
#'
#' @param text Character vector to write.
#' @param filepath Destination file path.
#'
#' @return Invisibly returns `NULL`.
#' @keywords internal
#' @noRd
write_to_path <- function(text, filepath) {
  fs::dir_create(fs::path_dir(filepath))
  writeLines(text, filepath)
}

#' Find and Replace in a File
#'
#' Replaces matching text in a single file.
#'
#' @param from Pattern to replace.
#' @param to Replacement text.
#' @param file File path to modify.
#' @param fixed Logical; if `TRUE`, use fixed matching. If `FALSE`, treat
#'   `from` as a regular expression.
#'
#' @return Invisibly returns `TRUE` if any replacement was made, otherwise
#'   invisibly returns `FALSE`.
#' @keywords internal
#' @noRd
find_replace_in_file <- function(from, to, file, fixed = TRUE) {
  x <- readLines(file, warn = FALSE)
  if (any(grepl(from, x, fixed = fixed))) {
    writeLines(gsub(from, to, x, fixed = fixed), file)
    invisible(TRUE)
  } else {
    invisible(FALSE)
  }
}

#' Find and Replace Across Files in a Directory
#'
#' Applies `find_replace_in_file()` to all files in `path` matching `pattern`.
#'
#' @param from Pattern to replace.
#' @param to Replacement text.
#' @param path Directory to search recursively.
#' @param pattern File name pattern passed to [base::list.files()].
#'
#' @return Invisibly returns `NULL`.
#' @keywords internal
#' @noRd
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

#' Find and Replace in GitHub Workflow Files
#'
#' Convenience wrapper around `find_replace_in_dir()` for
#' GHA workflow files--used to update some steps.
#'
#' @param from Pattern to replace.
#' @param to Replacement text.
#'
#' @return Invisibly returns `NULL`.
#' @keywords internal
#' @noRd
find_replace_in_gha <- function(from, to) {
  find_replace_in_dir(
    from = from,
    to = to,
    path = ".github/workflows",
    pattern = "\\.ya?ml$"
  )
}
