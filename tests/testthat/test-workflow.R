run_workflow_fixture <- function(
  setup_AGENTS = TRUE,
  setup_touchstone = FALSE,
  setup_touchstone_plots = FALSE
) {
  tmp <- tempfile("bootstrapper-workflow-")
  dir.create(tmp)
  pkg <- "demoPkg"
  pkg_path <- fs::path(tmp, pkg)
  dir.create(pkg_path)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)
  setwd(pkg_path)

  fields <- list("Package" = pkg)
  state <- new.env(parent = emptyenv())
  state$action_calls <- list()

  local_mocked_bindings(
    create_package = function(path, fields, ...) {
      expect_identical(path, ".")
      expect_identical(fields, list("Package" = pkg))

      writeLines(
        c("^.*\\.Rproj$", "^\\.Rproj\\.user$", "README\\.Rmd"),
        ".Rbuildignore"
      )
      writeLines(c("Package: demoPkg", "Version: 0.0.0.9000"), "DESCRIPTION")
      writeLines("project", "demoPkg.Rproj")
      fs::dir_create(fs::path(".git", "hooks"))
      NULL
    },
    use_testthat = function() {
      fs::dir_create(fs::path("tests", "testthat"))
      writeLines(
        "test_check(\"demoPkg\")",
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
            "  - uses: actions/checkout@v7"
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

  local_mocked_bindings(
    use_license = function() {
      writeLines("MIT License", "LICENSE.md")
      NULL
    },
    .package = "bootstrapper"
  )

  local_mocked_bindings(
    update_wordlist = function(confirm = FALSE) {
      expect_false(confirm)
      NULL
    },
    .package = "spelling"
  )

  expect_null(
    bootstrapper::bootstrapper(
      fields = fields,
      setup_AGENTS = setup_AGENTS,
      setup_touchstone = setup_touchstone,
      setup_touchstone_plots = setup_touchstone_plots
    )
  )

  list(
    pkg_path = pkg_path,
    action_calls = state$action_calls
  )
}

file_in_pkg <- function(fixture, ...) {
  fs::path(fixture$pkg_path, ...)
}

snapshot_name_from_path <- function(path) {
  name <- gsub("[/\\\\]+", "-", path)
  name <- sub("^\\.+", "dot-", name)
  name <- gsub("[^A-Za-z0-9._-]", "-", name)

  if (nzchar(fs::path_ext(path))) {
    name
  } else {
    paste0(name, ".txt")
  }
}

snapshot_workflow_files <- function(fixture, files) {
  for (f in files) {
    expect_true(file.exists(file_in_pkg(fixture, f)), info = f)
    expect_snapshot_file(
      file_in_pkg(fixture, f),
      compare = compare_file_text,
      name = snapshot_name_from_path(f)
    )
  }
}

test_that("workflow step: create_package creates git-backed package skeleton", {
  fixture <- run_workflow_fixture()

  expect_true(file.exists(file_in_pkg(fixture, "demoPkg.Rproj")))

  old <- setwd(fixture$pkg_path)
  on.exit(setwd(old), add = TRUE)
  files <- sort(list.files(
    ".",
    recursive = TRUE,
    all.files = TRUE,
    no.. = TRUE
  ))
  expect_snapshot(files[!grepl("^\\.git/", files)])

  snapshot_workflow_files(
    fixture,
    c("DESCRIPTION", "LICENSE.md", ".Rbuildignore")
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

  expect_length(fixture$action_calls, 2)
  expect_identical(fixture$action_calls[[1]][[1]], "check-standard")
  expect_true(isTRUE(fixture$action_calls[[1]]$badge))
  expect_identical(fixture$action_calls[[2]][[1]], "test-coverage")

  snapshot_workflow_files(
    fixture,
    c(
      ".github/workflows/check-standard.yaml",
      ".github/workflows/test-coverage.yaml",
      ".github/workflows/format-suggest.yaml"
    )
  )
})

test_that("workflow step: setup_touchstone writes minimal touchstone files by default", {
  skip_if_not_installed("touchstone")
  fixture <- run_workflow_fixture(setup_touchstone = TRUE)

  snapshot_workflow_files(
    fixture,
    c(
      ".github/workflows/touchstone-comment.yaml",
      ".github/workflows/touchstone-receive.yaml",
      "touchstone/.gitignore",
      "touchstone/config.json",
      "touchstone/footer.R",
      "touchstone/header.R",
      "touchstone/script.R"
    )
  )

  comment_workflow <- paste(
    readLines(
      file_in_pkg(fixture, ".github", "workflows", "touchstone-comment.yaml"),
      warn = FALSE
    ),
    collapse = "\n"
  )

  expect_match(comment_workflow, "actions: read", fixed = TRUE)
  expect_match(comment_workflow, "pull-requests: write", fixed = TRUE)
  expect_match(comment_workflow, "path: ./pr/info.txt", fixed = TRUE)
  expect_match(comment_workflow, "skip_unchanged: true", fixed = TRUE)

  expect_no_match(comment_workflow, "contents: write", fixed = TRUE)
  expect_no_match(comment_workflow, "actions/checkout", fixed = TRUE)
  expect_no_match(comment_workflow, "visual-benchmarks", fixed = TRUE)
  expect_no_match(comment_workflow, "touchstone-plots", fixed = TRUE)
  expect_no_match(comment_workflow, "github-pages-deploy-action", fixed = TRUE)
  expect_no_match(comment_workflow, "path: ./comment.txt", fixed = TRUE)
})

test_that("workflow step: setup_touchstone can write plots comment workflow", {
  skip_if_not_installed("touchstone")

  fixture <- run_workflow_fixture(
    setup_touchstone = TRUE,
    setup_touchstone_plots = TRUE
  )

  comment_workflow <- paste(
    readLines(
      file_in_pkg(fixture, ".github", "workflows", "touchstone-comment.yaml"),
      warn = FALSE
    ),
    collapse = "\n"
  )

  expect_match(comment_workflow, "actions: read", fixed = TRUE)
  expect_match(comment_workflow, "contents: write", fixed = TRUE)
  expect_match(comment_workflow, "pull-requests: write", fixed = TRUE)

  expect_match(comment_workflow, "actions/checkout", fixed = TRUE)
  expect_match(comment_workflow, "visual-benchmarks", fixed = TRUE)
  expect_match(comment_workflow, "touchstone-plots", fixed = TRUE)
  expect_match(comment_workflow, "github-pages-deploy-action", fixed = TRUE)
  expect_match(comment_workflow, "path: ./comment.txt", fixed = TRUE)
  expect_match(comment_workflow, "skip_unchanged: true", fixed = TRUE)
})

test_that("workflow step: setup_touchstone writes usable Touchstone config", {
  skip_if_not_installed("touchstone")
  skip_if_not_installed("jsonlite")

  fixture <- run_workflow_fixture(setup_touchstone = TRUE)

  config_path <- file_in_pkg(fixture, "touchstone", "config.json")
  workflow_path <- file_in_pkg(
    fixture,
    ".github",
    "workflows",
    "touchstone-receive.yaml"
  )

  config_json <- paste(readLines(config_path, warn = FALSE), collapse = "\n")
  expect_true(jsonlite::validate(config_json))

  config <- jsonlite::fromJSON(config_json)

  expect_setequal(names(config), c("os", "r", "rspm"))
  expect_identical(config$os, "ubuntu-24.04")
  expect_identical(config$r, "4.5.3")
  expect_identical(
    config$rspm,
    "https://packagemanager.posit.co/cran/__linux__/noble/latest"
  )

  receive_workflow <- paste(
    readLines(workflow_path, warn = FALSE),
    collapse = "\n"
  )

  expect_match(
    receive_workflow,
    "runs-on: ${{ matrix.config.os }}",
    fixed = TRUE
  )
  expect_match(
    receive_workflow,
    "RSPM: ${{ matrix.config.rspm }}",
    fixed = TRUE
  )
  expect_match(
    receive_workflow,
    "r-version: ${{ matrix.config.r }}",
    fixed = TRUE
  )
})

test_that("workflow step: setup templates are copied to expected locations", {
  fixture <- run_workflow_fixture(setup_AGENTS = TRUE)

  snapshot_workflow_files(
    fixture,
    c(
      ".github/dependabot.yml",
      "AGENTS.md",
      "jarl.toml",
      ".vscode/extensions.json"
    )
  )
  expect_true(file.exists(file_in_pkg(fixture, ".git", "hooks", "pre-commit")))
})
