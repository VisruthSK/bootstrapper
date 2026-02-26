test_that("bootstrapper end-to-end workflow creates expected repo files", {
  tmp <- tempfile("bootstrapper-workflow-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  pkg <- "demoPkg"
  fields <- list("Package" = pkg)
  github_private <- NULL
  action_calls <- list()

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
      github_private <<- private
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
      action_calls <<- c(action_calls, list(args))
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
      setup_AGENTS = TRUE,
      open = FALSE
    )
  )

  expect_identical(basename(getwd()), pkg)
  expect_true(isTRUE(github_private))
  expect_length(action_calls, 3)
  expect_false(file.exists("demoPkg.Rproj"))

  expected_files <- c(
    "DESCRIPTION",
    "README.md",
    "NEWS.md",
    "LICENSE.md",
    fs::path("tests", "testthat.R"),
    fs::path("tests", "jarl.toml"),
    fs::path(".vscode", "extensions.json"),
    fs::path(".github", "dependabot.yml"),
    fs::path(".github", "workflows", "check-standard.yaml"),
    fs::path(".github", "workflows", "test-coverage.yaml"),
    fs::path(".github", "workflows", "format-suggest.yaml"),
    "AGENTS.md",
    fs::path(".git", "config"),
    fs::path(".git", "hooks", "pre-commit")
  )
  for (f in expected_files) {
    expect_true(file.exists(f), info = f)
  }

  rbuildignore <- readLines(".Rbuildignore", warn = FALSE)
  expect_false(any(grepl("\\.Rproj", rbuildignore)))
  expect_true("AGENTS.md" %in% rbuildignore)

  news <- readLines("NEWS.md", warn = FALSE)
  expect_true(any(grepl("0.0.0.9000", news, fixed = TRUE)))

  check_standard <- readLines(
    fs::path(".github", "workflows", "check-standard.yaml"),
    warn = FALSE
  )
  expect_true(any(grepl("actions/checkout@v6", check_standard, fixed = TRUE)))
  expect_true(any(grepl(
    "actions/upload-artifact@v6",
    check_standard,
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "JamesIves/github-pages-deploy-action@v4",
    check_standard,
    fixed = TRUE
  )))

  coverage <- readLines(
    fs::path(".github", "workflows", "test-coverage.yaml"),
    warn = FALSE
  )
  expect_true(any(grepl("use_oidc: true", coverage, fixed = TRUE)))
  expect_true(any(grepl("id-token: write", coverage, fixed = TRUE)))
  expect_false(any(grepl("CODECOV_TOKEN", coverage, fixed = TRUE)))

  expect_identical(
    readLines(fs::path(".github", "dependabot.yml"), warn = FALSE),
    readLines(
      fs::path_package("bootstrapper", "templates", "dependabot.yml"),
      warn = FALSE
    )
  )
  expect_identical(
    readLines("AGENTS.md", warn = FALSE),
    readLines(
      fs::path_package("bootstrapper", "templates", "AGENTS.md"),
      warn = FALSE
    )
  )
  expect_identical(
    readLines(fs::path("tests", "jarl.toml"), warn = FALSE),
    readLines(
      fs::path_package("bootstrapper", "templates", "jarl.toml"),
      warn = FALSE
    )
  )
  expect_identical(
    readLines(fs::path(".vscode", "extensions.json"), warn = FALSE),
    readLines(
      fs::path_package("bootstrapper", "templates", "extensions.json"),
      warn = FALSE
    )
  )
  expect_identical(
    readLines(fs::path(".git", "hooks", "pre-commit"), warn = FALSE),
    readLines(
      fs::path_package("bootstrapper", "templates", "pre-commit"),
      warn = FALSE
    )
  )
})
