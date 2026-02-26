run_workflow_fixture <- function(setup_AGENTS = TRUE) {
  tmp <- tempfile("bootstrapper-workflow-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  pkg <- "demoPkg"
  fields <- list("Package" = pkg)
  state <- new.env(parent = emptyenv())
  state$github_private <- NULL
  state$action_calls <- list()

  testthat::local_mocked_bindings(
    create_package = function(path, fields, ...) {
      expect_identical(path, pkg)
      expect_identical(fields, list("Package" = pkg))
      expect_identical(list(...), list(open = FALSE))

      fs::dir_create(path)
      setwd(path)
      writeLines(
        c("^.*\\.Rproj$", "^\\.Rproj\\.user$", "README\\.Rmd"),
        ".Rbuildignore"
      )
      writeLines(c("Package: demoPkg", "Version: 0.0.0.9000"), "DESCRIPTION")
      writeLines("project", "demoPkg.Rproj")
      fs::dir_create(fs::path(".git", "hooks"))
      NULL
    },
    use_github = function(private) {
      state$github_private <- private
      writeLines(
        c(
          "[remote \"origin\"]",
          "\turl = git@github.com:example/demoPkg.git"
        ),
        fs::path(".git", "config")
      )
      NULL
    },
    use_testthat = function() {
      fs::dir_create(fs::path("tests", "testthat"))
      writeLines(
        "testthat::test_check(\"demoPkg\")",
        fs::path("tests", "testthat.R")
      )
      NULL
    },
    use_readme_md = function(open = FALSE) {
      expect_false(open)
      writeLines("# demoPkg", "README.md")
      NULL
    },
    use_news_md = function(open = FALSE) {
      expect_false(open)
      writeLines("demoPkg (development version)", "NEWS.md")
      NULL
    },
    use_github_action = function(...) {
      args <- list(...)
      state$action_calls <- c(state$action_calls, list(args))
      fs::dir_create(fs::path(".github", "workflows"))

      if (!is.null(args$url)) {
        writeLines(
          c(
            "name: format-suggest",
            "steps:",
            "  - uses: actions/checkout@v4"
          ),
          fs::path(".github", "workflows", "format-suggest.yaml")
        )
        return(invisible(NULL))
      }

      if (identical(args[[1]], "check-standard")) {
        writeLines(
          c(
            "name: check",
            "steps:",
            "  - uses: actions/checkout@v4",
            "  - uses: actions/upload-artifact@v4",
            "  - uses: JamesIves/github-pages-deploy-action@v4.5.0"
          ),
          fs::path(".github", "workflows", "check-standard.yaml")
        )
        return(invisible(NULL))
      }

      if (identical(args[[1]], "test-coverage")) {
        writeLines(
          c(
            "name: coverage",
            "permissions: read-all",
            "steps:",
            "  - token: ${{ secrets.CODECOV_TOKEN }}"
          ),
          fs::path(".github", "workflows", "test-coverage.yaml")
        )
        return(invisible(NULL))
      }

      NULL
    },
    use_pkgdown_github_pages = function() NULL,
    use_spell_check = function(error = FALSE) {
      expect_true(error)
      NULL
    },
    use_air = function() {
      writeLines("[format]", "air.toml")
      NULL
    },
    use_tidy_description = function() NULL,
    use_build_ignore = function(path, ...) {
      writeLines(
        c(readLines(".Rbuildignore", warn = FALSE), path),
        ".Rbuildignore"
      )
      NULL
    },
    .package = "usethis"
  )

  testthat::local_mocked_bindings(
    use_license = function() {
      writeLines("MIT License", "LICENSE.md")
      NULL
    },
    try_air_jarl_format = function() {
      invisible(c(air = TRUE, jarl = TRUE))
    },
    .package = "bootstrapper"
  )

  expect_null(
    bootstrapper::bootstrapper(
      path = pkg,
      fields = fields,
      private = TRUE,
      setup_AGENTS = setup_AGENTS,
      open = FALSE
    )
  )

  list(
    pkg_path = fs::path(tmp, pkg),
    github_private = state$github_private,
    action_calls = state$action_calls
  )
}

file_in_pkg <- function(fixture, ...) {
  fs::path(fixture$pkg_path, ...)
}

snapshot_workflow_files <- function(fixture, files) {
  for (f in files) {
    expect_true(file.exists(file_in_pkg(fixture, f)), info = f)
    expect_snapshot_file(
      file_in_pkg(fixture, f),
      compare = testthat::compare_file_text,
      name = paste0(
        "workflow-",
        gsub("[^A-Za-z0-9_-]", "-", f)
      )
    )
  }
}

test_that("workflow step: create_package creates git-backed package skeleton", {
  fixture <- run_workflow_fixture()

  expect_true(isTRUE(fixture$github_private))
  expect_false(file.exists(file_in_pkg(fixture, "demoPkg.Rproj")))

  old <- setwd(fixture$pkg_path)
  on.exit(setwd(old), add = TRUE)
  expect_snapshot(sort(list.files(
    ".",
    recursive = TRUE,
    all.files = TRUE,
    no.. = TRUE
  )))

  snapshot_workflow_files(
    fixture,
    c("DESCRIPTION", "LICENSE.md", ".Rbuildignore", ".git/config")
  )
})

test_that("workflow step: pkg_setup creates core package files", {
  fixture <- run_workflow_fixture()

  snapshot_workflow_files(
    fixture,
    c("README.md", "NEWS.md", "tests/testthat.R")
  )
})

test_that("workflow step: setup_gha writes and rewrites workflow files", {
  fixture <- run_workflow_fixture()

  expect_length(fixture$action_calls, 3)
  expect_identical(fixture$action_calls[[1]][[1]], "check-standard")
  expect_identical(fixture$action_calls[[2]][[1]], "test-coverage")
  expect_identical(
    fixture$action_calls[[3]]$url,
    "https://github.com/visruthsk/bootstrapper/blob/main/.github/workflows/format-suggest.yaml"
  )

  snapshot_workflow_files(
    fixture,
    c(
      ".github/workflows/check-standard.yaml",
      ".github/workflows/test-coverage.yaml",
      ".github/workflows/format-suggest.yaml"
    )
  )
})

test_that("workflow step: setup templates are copied to expected locations", {
  fixture <- run_workflow_fixture(setup_AGENTS = TRUE)

  snapshot_workflow_files(
    fixture,
    c(
      ".github/dependabot.yml",
      "AGENTS.md",
      "tests/jarl.toml",
      ".vscode/extensions.json",
      ".git/hooks/pre-commit"
    )
  )
})
