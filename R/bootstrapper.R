#' Bootstrap a New R Package
#'
#' Create a package with some opinionated setup.
#'
#' @param path Path where the package should be created. Defaults to `"."`
#' @param fields Named list of `DESCRIPTION` fields passed to
#'   [usethis::create_package()]. See [usethis::use_description()]
#' @param private Whether to create the GitHub repository as private. Defaults to `TRUE`.
#' @param setup_gha Whether to configure GitHub Actions setup.
#' @param setup_dependabot Whether to write a Dependabot configuration.
#' @param setup_AGENTS Whether to write a default AGENTS file.
#' @param ... Additional arguments passed to [usethis::create_package()].
#'
#' @return Invisibly returns `NULL`.
#' @export
bootstrapper <- function(
  path = ".",
  fields,
  private = TRUE,
  setup_gha = TRUE,
  setup_dependabot = TRUE,
  setup_AGENTS = FALSE,
  ...
) {
  create_package(path, fields, private, ...)
  pkg_setup(
    setup_gha = setup_gha,
    setup_dependabot = setup_dependabot,
    setup_AGENTS = setup_AGENTS
  )
  invisible(NULL)
}

#' Create a Package and Connect GitHub
#'
#' Create a package, apply `.Rbuildignore` cleanup, prompt for a license, and
#' connect the package to GitHub.
#'
#' @inheritParams bootstrapper
#' @return Invisibly returns `NULL`.
#' @export
create_package <- function(
  path = ".",
  fields = getOption(
    "usethis.description",
    list(
      "Authors@R" = person(
        "Visruth",
        "Srimath Kandali",
        ,
        "public@visruth.com",
        role = c("aut", "cre", "cph"),
        comment = c(ORCID = "0009-0005-9097-0688")
      )
    )
  ),
  private = TRUE,
  ...
) {
  usethis::create_package(path = path, fields = fields, ...)
  unlink("*.Rproj")
  find_replace_in_file(
    "^\\^.*\\\\\\.Rproj\\$$",
    "",
    ".Rbuildignore",
    fixed = FALSE
  )
  find_replace_in_file(
    "^\\^\\\\\\.Rproj\\\\\\.user\\$$",
    "",
    ".Rbuildignore",
    fixed = FALSE
  )
  readLines(".Rbuildignore", warn = FALSE) |>
    Filter(nzchar, x = _) |>
    writeLines(".Rbuildignore")
  use_license()
  usethis::use_github(private = private)
  invisible(NULL)
}

#' Apply Opinionated Package Setup
#'
#' Run the package setup steps used by `bootstrapper`, including test
#' infrastructure, README/NEWS creation, GitHub Actions, and linting defaults.
#' Run this in the root directory of your package.
#'
#' @param setup_gha Whether to configure GitHub Actions setup.
#' @param setup_dependabot Whether to write a Dependabot configuration.
#' @param setup_AGENTS Whether to write a default AGENTS file.
#'
#' @return Invisibly returns `NULL`.
#' @export
pkg_setup <- function(
  setup_gha = TRUE,
  setup_dependabot = TRUE,
  setup_AGENTS = FALSE
) {
  tryCatch(
    usethis::use_testthat(),
    error = function(...) {
      usethis::ui_stop(
        "This doesn't appear to be a package. Ensure you are in the right directory, or run {usethis::ui_code('create_package()')} in this directory to start a R package."
      )
    }
  )
  usethis::use_readme_md(open = FALSE)
  usethis::use_news_md(open = FALSE)
  # TODO: check if this is necessary to make r cmd check pass.
  find_replace_in_file(
    "(development version)",
    "0.0.0.9000",
    fs::path("NEWS.md")
  )

  if (setup_gha) {
    setup_gha()
  }
  if (setup_dependabot) {
    setup_dependabot()
  }
  if (setup_AGENTS) {
    setup_AGENTS()
  }

  try_air_jarl_format()
  usethis::use_tidy_description()
  invisible(NULL)
}

# Helpers ---------------------------------------------------------------------

#' Try Air/Jarl Formatting
#'
#' Attempts to run `air format .` and `jarl check . --fix --allow-dirty`.
#' Errors and warnings are ignored so setup can continue if tools are unavailable.
#'
#' @return Invisibly returns a named logical vector indicating whether each
#'   check succeeded.
#' @keywords internal
#' @noRd
try_air_jarl_format <- function() {
  air <- suppressWarnings(
    tryCatch(
      {
        system2("air", c("format", "."), stdout = FALSE, stderr = FALSE)
        TRUE
      },
      error = function(...) FALSE
    )
  )
  jarl <- suppressWarnings(
    tryCatch(
      {
        system2(
          "jarl",
          c("check", ".", "--fix", "--allow-dirty"),
          stdout = FALSE,
          stderr = FALSE
        )
        TRUE
      },
      error = function(...) FALSE
    )
  )
  invisible(c(air = air, jarl = jarl))
}

#' Configure GitHub Actions Defaults
#'
#' Sets up standard GitHub Actions used by this package template and updates
#' workflow references.
#'
#' @return Invisibly returns `NULL`.
#' @keywords internal
#' @noRd
setup_gha <- function() {
  usethis::use_github_action("check-standard", badge = TRUE)
  usethis::use_github_action("test-coverage", badge = TRUE)
  usethis::use_github_action(
    url = "https://github.com/visruthsk/bootstrapper/blob/main/.github/workflows/format-suggest.yaml"
  )
  usethis::use_pkgdown_github_pages()
  usethis::use_spell_check(error = TRUE)

  find_replace_in_gha("actions/checkout@v4", "actions/checkout@v6")
  find_replace_in_gha(
    "JamesIves/github-pages-deploy-action@v4.5.0",
    "JamesIves/github-pages-deploy-action@v4"
  )

  usethis::use_air()
  copy_template_file("extensions.json", fs::path(".vscode", "extensions.json"))
  copy_template_file("jarl.toml", fs::path("tests", "jarl.toml")) # TODO: need to make GHA jarl runs respect this
}

#' Configure Dependabot Defaults
#'
#' Writes a default Dependabot configuration for GitHub Actions.
#'
#' @return Invisibly returns `NULL`.
#' @keywords internal
#' @noRd
setup_dependabot <- function() {
  copy_template_file("dependabot.yml", fs::path(".github", "dependabot.yml"))
}

#' Configure AGENTS Defaults
#'
#' Copies an opinionated, concise AGENTS.md for R package development.
#'
#' @return Invisibly returns `NULL`.
#' @keywords internal
#' @noRd
setup_agents <- function() {
  copy_template_file("AGENTS.md", "AGENTS.md")
}

#' Choose and Apply a License
#'
#' Prompts for a license choice in interactive sessions and applies the selected
#' `usethis` license helper.
#'
#' @return Invisibly returns `NULL`.
#' @export
use_license <- function() {
  license_choices <- c(
    "MIT" = "use_mit_license",
    "GPL" = "use_gpl_license",
    "GPL-3" = "use_gpl3_license",
    "LGPL" = "use_lgpl_license",
    "AGPL" = "use_agpl_license",
    "AGPL-3" = "use_agpl3_license",
    "Apache-2.0" = "use_apl2_license",
    "Apache" = "use_apache_license",
    "CC BY" = "use_ccby_license",
    "CC0" = "use_cc0_license",
    "Proprietary" = "use_proprietary_license",
    "Skip for now" = FALSE
  )
  usethis::ui_info("Select a license for this package.")
  selected_fn <- if (is_interactive()) {
    unname(
      license_choices[[utils::menu(
        choices = names(license_choices),
        title = "License"
      )]]
    )
  } else {
    FALSE
  }
  if (selected_fn) {
    switch(
      selected_fn,
      use_mit_license = usethis::use_mit_license(),
      use_gpl_license = usethis::use_gpl_license(),
      use_gpl3_license = usethis::use_gpl3_license(),
      use_lgpl_license = usethis::use_lgpl_license(),
      use_agpl_license = usethis::use_agpl_license(),
      use_agpl3_license = usethis::use_agpl3_license(),
      use_apl2_license = usethis::use_apl2_license(),
      use_apache_license = usethis::use_apache_license(),
      use_ccby_license = usethis::use_ccby_license(),
      use_cc0_license = usethis::use_cc0_license(),
      use_proprietary_license = usethis::use_proprietary_license()
    )
  } else {
    usethis::ui_warn("No license selected; leaving current license unchanged.")
  }
}
