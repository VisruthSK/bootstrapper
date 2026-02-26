test_that("bootstrapper orchestrates package creation and setup", {
  calls <- character()

  testthat::local_mocked_bindings(
    create_package = function(path, fields, private, ...) {
      calls <<- c(calls, "create_package")
      expect_identical(path, "pkg")
      expect_identical(fields, list(name = "value"))
      expect_false(private)
      expect_identical(list(...), list(open = FALSE))
      NULL
    },
    pkg_setup = function(setup_gha, setup_dependabot, setup_AGENTS) {
      calls <<- c(calls, "pkg_setup")
      expect_false(setup_gha)
      expect_false(setup_dependabot)
      expect_false(setup_AGENTS)
      NULL
    },
    .package = "bootstrapper"
  )

  expect_null(
    bootstrapper::bootstrapper(
      path = "pkg",
      fields = list(name = "value"),
      private = FALSE,
      setup_gha = FALSE,
      setup_dependabot = FALSE,
      open = FALSE
    )
  )
  expect_identical(calls, c("create_package", "pkg_setup"))
})

test_that("create_package delegates to usethis and cleans local files", {
  tmp <- tempfile("bootstrapper-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  writeLines(
    c("^.*\\.Rproj$", "^\\.Rproj\\.user$", "keep", ""),
    ".Rbuildignore"
  )
  writeLines("project", "pkg.Rproj")

  fields <- list("Authors@R" = utils::person("Jane", "Doe"))
  seen <- list()

  testthat::local_mocked_bindings(
    create_package = function(path, fields, ...) {
      seen$create <<- list(path = path, fields = fields, dots = list(...))
      NULL
    },
    use_github = function(private) {
      seen$private <<- private
      NULL
    },
    .package = "usethis"
  )

  testthat::local_mocked_bindings(
    use_license = function() {
      seen$license <<- TRUE
      NULL
    },
    .package = "bootstrapper"
  )

  expect_null(
    bootstrapper::create_package(
      path = "pkg",
      fields = fields,
      private = FALSE,
      open = FALSE
    )
  )

  expect_identical(seen$create$path, "pkg")
  expect_identical(seen$create$fields, fields)
  expect_identical(seen$create$dots, list(open = FALSE))
  expect_false(file.exists("pkg.Rproj"))
  expect_identical(readLines(".Rbuildignore", warn = FALSE), "keep")
  expect_false(seen$private)
  expect_true(isTRUE(seen$license))
})

test_that("pkg_setup runs expected top-level calls and setup sections", {
  calls <- list(
    actions = character(),
    sections = character(),
    replaced = FALSE,
    formatted = FALSE
  )

  testthat::local_mocked_bindings(
    use_testthat = function() {
      calls$actions <<- c(calls$actions, "testthat")
    },
    use_readme_md = function(open = FALSE) {
      calls$actions <<- c(calls$actions, paste0("readme:", open))
    },
    use_news_md = function(open = FALSE) {
      calls$actions <<- c(calls$actions, paste0("news:", open))
    },
    use_tidy_description = function() {
      calls$actions <<- c(calls$actions, "tidy_description")
    },
    .package = "usethis"
  )

  testthat::local_mocked_bindings(
    configure_gha = function() {
      calls$sections <<- c(calls$sections, "gha")
      NULL
    },
    configure_dependabot = function() {
      calls$sections <<- c(calls$sections, "dependabot")
      NULL
    },
    configure_agents = function() {
      calls$sections <<- c(calls$sections, "agents")
      NULL
    },
    find_replace_in_file = function(from, to, file, fixed = TRUE) {
      calls$replaced <<- TRUE
      expect_identical(from, "(development version)")
      expect_identical(to, "0.0.0.9000")
      expect_identical(file, fs::path("NEWS.md"))
      expect_true(fixed)
      NULL
    },
    try_air_jarl_format = function() {
      calls$formatted <<- TRUE
      NULL
    },
    .package = "bootstrapper"
  )

  expect_null(bootstrapper::pkg_setup())

  expect_true("testthat" %in% calls$actions)
  expect_true("readme:FALSE" %in% calls$actions)
  expect_true("news:FALSE" %in% calls$actions)
  expect_true("tidy_description" %in% calls$actions)
  expect_identical(calls$sections, c("gha", "dependabot"))
  expect_true(calls$replaced)
  expect_true(calls$formatted)
})

test_that("pkg_setup skips optional sections when disabled", {
  called <- FALSE
  formatted <- FALSE

  testthat::local_mocked_bindings(
    use_testthat = function() NULL,
    use_readme_md = function(open = FALSE) NULL,
    use_news_md = function(open = FALSE) NULL,
    use_tidy_description = function() NULL,
    .package = "usethis"
  )

  testthat::local_mocked_bindings(
    configure_gha = function() {
      called <<- TRUE
      NULL
    },
    configure_dependabot = function() {
      called <<- TRUE
      NULL
    },
    configure_agents = function() {
      called <<- TRUE
      NULL
    },
    find_replace_in_file = function(from, to, file, fixed = TRUE) NULL,
    try_air_jarl_format = function() {
      formatted <<- TRUE
      NULL
    },
    .package = "bootstrapper"
  )

  expect_null(
    bootstrapper::pkg_setup(
      setup_gha = FALSE,
      setup_dependabot = FALSE,
      setup_AGENTS = FALSE
    )
  )
  expect_false(called)
  expect_true(formatted)
})

test_that("pkg_setup runs AGENTS setup when enabled", {
  called <- FALSE

  testthat::local_mocked_bindings(
    use_testthat = function() NULL,
    use_readme_md = function(open = FALSE) NULL,
    use_news_md = function(open = FALSE) NULL,
    use_tidy_description = function() NULL,
    .package = "usethis"
  )

  testthat::local_mocked_bindings(
    configure_gha = function() NULL,
    configure_dependabot = function() NULL,
    configure_agents = function() {
      called <<- TRUE
      NULL
    },
    find_replace_in_file = function(from, to, file, fixed = TRUE) NULL,
    try_air_jarl_format = function() NULL,
    .package = "bootstrapper"
  )

  expect_null(bootstrapper::pkg_setup(setup_AGENTS = TRUE))
  expect_true(called)
})

test_that("configure_gha runs expected usethis, replacement, and air/jarl calls", {
  configure_gha <- getFromNamespace("configure_gha", "bootstrapper")
  actions <- list(
    github_actions = list(),
    replacements = character(),
    spell = FALSE,
    air = FALSE,
    writes = character()
  )

  testthat::local_mocked_bindings(
    use_github_action = function(...) {
      actions$github_actions <<- c(actions$github_actions, list(list(...)))
      NULL
    },
    use_pkgdown_github_pages = function() NULL,
    use_spell_check = function(error = FALSE) {
      actions$spell <<- error
      NULL
    },
    use_air = function() {
      actions$air <<- TRUE
      NULL
    },
    .package = "usethis"
  )

  testthat::local_mocked_bindings(
    find_replace_in_gha = function(from, to) {
      actions$replacements <<- c(
        actions$replacements,
        paste(from, to, sep = " -> ")
      )
      NULL
    },
    write_to_path = function(text, filepath) {
      actions$writes <<- c(actions$writes, filepath)
      NULL
    },
    .package = "bootstrapper"
  )

  expect_null(configure_gha())
  expect_length(actions$github_actions, 3)
  expect_identical(actions$github_actions[[1]][[1]], "check-standard")
  expect_true(isTRUE(actions$github_actions[[1]]$badge))
  expect_identical(actions$github_actions[[2]][[1]], "test-coverage")
  expect_identical(
    actions$github_actions[[3]]$url,
    "https://github.com/visruthsk/bootstrapper/blob/main/.github/workflows/format-suggest.yaml"
  )
  expect_true(actions$spell)
  expect_identical(
    actions$replacements,
    c(
      "actions/checkout@v4 -> actions/checkout@v6",
      "JamesIves/github-pages-deploy-action@v4.5.0 -> JamesIves/github-pages-deploy-action@v4"
    )
  )
  expect_true(actions$air)
  expect_setequal(
    basename(actions$writes),
    c("extensions.json", "jarl.toml")
  )
})

test_that("configure_dependabot writes dependabot config", {
  configure_dependabot <- getFromNamespace(
    "configure_dependabot",
    "bootstrapper"
  )
  captured <- list(path = NULL, text = NULL)

  testthat::local_mocked_bindings(
    write_to_path = function(text, filepath) {
      captured$path <<- filepath
      captured$text <<- text
      NULL
    },
    .package = "bootstrapper"
  )

  expect_null(configure_dependabot())
  expect_identical(captured$path, fs::path(".github", "dependabot.yml"))
  expect_true(any(grepl("^version: 2$", captured$text)))
})

test_that("pkg_setup rethrows a generic message when test setup fails", {
  readme_called <- FALSE

  testthat::local_mocked_bindings(
    use_testthat = function() stop("boom"),
    use_readme_md = function(open = FALSE) {
      readme_called <<- TRUE
      NULL
    },
    .package = "usethis"
  )

  expect_error(
    bootstrapper::pkg_setup(),
    "This doesn't appear to be a package"
  )
  expect_false(readme_called)
})

test_that("use_license warns and returns NULL in non-interactive mode", {
  messages <- character()

  testthat::local_mocked_bindings(
    is_interactive = function() FALSE,
    .package = "bootstrapper"
  )

  testthat::local_mocked_bindings(
    ui_info = function(message, ...) {
      messages <<- c(messages, message)
      NULL
    },
    ui_warn = function(message, ...) {
      messages <<- c(messages, message)
      NULL
    },
    .package = "usethis"
  )

  expect_null(bootstrapper::use_license())
  expect_true(any(grepl("Select a license", messages, fixed = TRUE)))
  expect_true(any(grepl("No license selected", messages, fixed = TRUE)))
})

test_that("file helpers create directories and replace text", {
  tmp <- tempfile("bootstrapper-helpers-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  write_to_path <- getFromNamespace("write_to_path", "bootstrapper")
  find_replace_in_file <- getFromNamespace(
    "find_replace_in_file",
    "bootstrapper"
  )
  find_replace_in_dir <- getFromNamespace("find_replace_in_dir", "bootstrapper")
  find_replace_in_gha <- getFromNamespace("find_replace_in_gha", "bootstrapper")

  write_to_path(c("alpha", "beta"), fs::path("nested", "file.txt"))
  expect_identical(
    readLines(fs::path("nested", "file.txt"), warn = FALSE),
    c("alpha", "beta")
  )

  writeLines(c("alpha", "beta"), "one.txt")
  expect_true(find_replace_in_file("alpha", "ALPHA", "one.txt"))
  expect_identical(readLines("one.txt", warn = FALSE), c("ALPHA", "beta"))
  expect_false(find_replace_in_file("gamma", "GAMMA", "one.txt"))

  dir.create("sub")
  writeLines("token", fs::path("sub", "a.yaml"))
  writeLines("token", fs::path("sub", "b.txt"))
  find_replace_in_dir("token", "TOKEN", "sub", "\\.ya?ml$")
  expect_identical(readLines(fs::path("sub", "a.yaml"), warn = FALSE), "TOKEN")
  expect_identical(readLines(fs::path("sub", "b.txt"), warn = FALSE), "token")

  dir.create(fs::path(".github", "workflows"), recursive = TRUE)
  writeLines(
    "uses: actions/checkout@v4",
    fs::path(".github", "workflows", "check.yml")
  )
  find_replace_in_gha("actions/checkout@v4", "actions/checkout@v6")
  expect_true(grepl(
    "checkout@v6",
    readLines(fs::path(".github", "workflows", "check.yml"))
  ))
})
