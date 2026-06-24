#' Bootstrap a New R Package
#'
#' Create a package with some opinionated setup.
#'
#' @param fields Named list of `DESCRIPTION` fields passed to
#'   [usethis::create_package()]. See [usethis::use_description()]
#' @param setup_gha Whether to configure GitHub Actions setup.
#' @param setup_dependabot Whether to write a Dependabot configuration.
#' @param setup_AGENTS Whether to write a default AGENTS file.
#' @param setup_precommit Whether to write a Bash pre-commit hook.
#' @param setup_air Whether to configure Air formatting.
#' @param setup_jarl Whether to configure Jarl linting.
#'
#' @return Invisibly returns `NULL`.
#' @export
bootstrapper <- function(
  fields = getOption("usethis.description"),
  setup_gha = TRUE,
  setup_air = TRUE,
  setup_jarl = TRUE,
  setup_dependabot = TRUE,
  setup_AGENTS = FALSE,
  setup_precommit = TRUE
) {
  create_package(fields)
  pkg_setup(
    setup_gha = setup_gha,
    setup_dependabot = setup_dependabot,
    setup_AGENTS = setup_AGENTS,
    setup_precommit = setup_precommit,
    setup_air = setup_air,
    setup_jarl = setup_jarl
  )
  invisible(NULL)
}

#' Opinionated Package Setup
#'
#' Run the package setup steps used by `bootstrapper`, including test
#' infrastructure, README/NEWS creation, GitHub Actions, and linting defaults.
#' Run this in the root directory of your package.
#'
#' @param setup_gha Whether to configure GitHub Actions setup.
#' @param setup_dependabot Whether to write a Dependabot configuration.
#' @param setup_AGENTS Whether to write a default AGENTS file.
#' @param setup_precommit Whether to write a Bash pre-commit hook.
#' @param setup_air Whether to configure Air formatting.
#' @param setup_jarl Whether to configure Jarl linting.
#'
#' @return Invisibly returns `NULL`.
#' @export
pkg_setup <- function(
  setup_gha = TRUE,
  setup_dependabot = TRUE,
  setup_AGENTS = FALSE,
  setup_precommit = TRUE,
  setup_air = TRUE,
  setup_jarl = TRUE
) {
  tryCatch(
    usethis::use_testthat(),
    error = function(...) {
      cli::cli_abort(
        "This doesn't appear to be a package. Ensure you are in the right directory, or run {.code create_package()} in this directory to start an R package."
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

  # flags
  if (setup_gha) {
    setup_gha()
  }
  if (setup_dependabot) {
    setup_dependabot()
  }
  if (setup_AGENTS) {
    setup_agents()
  }
  if (setup_precommit) {
    setup_precommit()
  }
  setup_formatter(setup_air, setup_jarl)

  # cleanup
  usethis::use_tidy_description()
  cleanup_buildignore()
  spelling::update_wordlist(confirm = FALSE)

  invisible(NULL)
}

#' Configure Formatter Defaults
#'
#' Sets up Air and/or Jarl formatting defaults. Optionally
#' format the repository once.
#'
#' @param air Whether to configure Air formatting.
#' @param jarl Whether to configure Jarl linting.
#' @param format Whether to format the repository after configuring tools.
#'
#' @return Invisibly returns `NULL`.
#' @export
setup_formatter <- function(air = TRUE, jarl = TRUE, format = TRUE) {
  if (air) {
    usethis::use_air()
    copy_template_file(
      "extensions.json",
      fs::path(".vscode", "extensions.json")
    )
    if (format) {
      silent_system2("air", c("format", "."))
    }
  }
  if (jarl) {
    copy_template_file("jarl.toml", "jarl.toml")
    usethis::use_build_ignore("jarl.toml")
    if (format) {
      silent_system2("jarl", c("check", ".", "--fix", "--allow-dirty"))
    }
  }

  if (air && jarl) {
    usethis::use_github_action(
      url = "https://github.com/visruthsk/bootstrapper/blob/main/.github/workflows/format-suggest.yaml"
    )
  } else if (air) {
    copy_template_file(
      "air.yaml",
      fs::path(".github", "workflows", "format-suggest.yaml")
    )
  } else if (jarl) {
    copy_template_file(
      "jarl.yaml",
      fs::path(".github", "workflows", "format-suggest.yaml")
    )
  }

  invisible(NULL)
}

# Helpers ---------------------------------------------------------------------

#' Create a Package and Connect GitHub
#'
#' Create a package in root, prompts for a license, cleans
#' up build ignore file.
#'
#' @inheritParams bootstrapper
#' @return Invisibly returns `NULL`.
#' @export
create_package <- function(fields = getOption("usethis.description")) {
  usethis::create_package(path = ".", fields = fields)
  use_license()
  cleanup_buildignore()
  invisible(NULL)
}

#' Configure GitHub Actions Defaults
#'
#' Sets up standard GitHub Actions used by this package template and updates
#' workflow references. DOES NOT setup formatting, that is owned by [setup_formatter()].
#'
#' @return Invisibly returns `NULL`.
#' @export
setup_gha <- function() {
  usethis::use_github_action("check-standard", badge = TRUE)
  usethis::use_github_action("test-coverage")
  # swap from codecov tokens to OICD
  find_replace_in_file(
    "token: ${{ secrets.CODECOV_TOKEN }}",
    "use_oidc: true",
    fs::path(".github", "workflows", "test-coverage.yaml")
  )
  find_replace_in_file(
    "permissions: read-all",
    "permissions:\n  contents: read\n  id-token: write",
    fs::path(".github", "workflows", "test-coverage.yaml")
  )
  usethis::use_pkgdown_github_pages()
  usethis::use_spell_check(error = TRUE)

  find_replace_in_gha("actions/checkout@v4", "actions/checkout@v7")
  find_replace_in_gha(
    "actions/upload-artifact@v4",
    "actions/upload-artifact@v7"
  )
  find_replace_in_gha(
    "JamesIves/github-pages-deploy-action@v4.5.0",
    "JamesIves/github-pages-deploy-action@v4"
  )
}

#' Configure Dependabot Defaults
#'
#' Writes a default Dependabot configuration for GitHub Actions.
#'
#' @return Invisibly returns `NULL`.
#' @export
setup_dependabot <- function() {
  copy_template_file("dependabot.yml", fs::path(".github", "dependabot.yml"))
}

#' Configure AGENTS Defaults
#'
#' Copies an opinionated, concise AGENTS.md for R package development.
#'
#' @return Invisibly returns `NULL`.
#' @export
setup_agents <- function() {
  copy_template_file("AGENTS.md", "AGENTS.md")
  usethis::use_build_ignore("AGENTS.md")
}

#' Configure Pre-Commit Hook
#'
#' Writes a Bash pre-commit hook that runs format and lint checks.
#'
#' @return Invisibly returns `NULL`.
#' @export
setup_precommit <- function() {
  copy_template_file("pre-commit", fs::path(".git", "hooks", "pre-commit"))
  Sys.chmod(fs::path(".git", "hooks", "pre-commit"), mode = "0755")
  invisible(NULL)
}

#' Remove empty lines
#'
#' Drops empty lines in `.Rbuildignore`.
#'
#' @return Invisibly returns `NULL`.
#' @keywords internal
#' @noRd
cleanup_buildignore <- function() {
  if (!file.exists(".Rbuildignore")) {
    return(invisible(NULL))
  }
  readLines(".Rbuildignore", warn = FALSE) |>
    Filter(nzchar, x = _) |>
    writeLines(".Rbuildignore")
  invisible(NULL)
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
  cli::cli_inform("Select a license for this package.")
  selected_fn <- if (
    isTRUE(getOption("bootstrapper.interactive", interactive()))
  ) {
    unname(
      license_choices[[utils::menu(
        choices = names(license_choices),
        title = "License"
      )]]
    )
  } else {
    FALSE
  }
  if (!isFALSE(selected_fn)) {
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
    cli::cli_warn("No license selected; leaving current license unchanged.")
  }
}
