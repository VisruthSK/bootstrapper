test_that("bootstrapper orchestrates package creation and setup", {
  calls <- character()

  testthat::local_mocked_bindings(
    create_package = function(fields) {
      calls <<- c(calls, "create_package")
      expect_identical(fields, list(name = "value"))
      NULL
    },
    pkg_setup = function(
      setup_gha,
      setup_dependabot,
      setup_AGENTS,
      setup_precommit,
      setup_air,
      setup_jarl
    ) {
      calls <<- c(calls, "pkg_setup")
      expect_false(setup_gha)
      expect_false(setup_dependabot)
      expect_false(setup_AGENTS)
      expect_false(setup_precommit)
      expect_false(setup_air)
      expect_false(setup_jarl)
      NULL
    },
    .package = "bootstrapper"
  )

  expect_null(
    bootstrapper::bootstrapper(
      fields = list(name = "value"),
      setup_gha = FALSE,
      setup_dependabot = FALSE,
      setup_precommit = FALSE,
      setup_air = FALSE,
      setup_jarl = FALSE
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
    create_package = function(path, fields) {
      seen$create <<- list(path = path, fields = fields)
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
    bootstrapper::create_package(fields = fields)
  )

  expect_identical(seen$create$path, ".")
  expect_identical(seen$create$fields, fields)
  expect_true(file.exists("pkg.Rproj"))
  expect_identical(
    readLines(".Rbuildignore", warn = FALSE),
    c("^.*\\.Rproj$", "^\\.Rproj\\.user$", "keep")
  )
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
    setup_gha = function() {
      calls$sections <<- c(calls$sections, "gha")
      NULL
    },
    setup_dependabot = function() {
      calls$sections <<- c(calls$sections, "dependabot")
      NULL
    },
    setup_agents = function() {
      calls$sections <<- c(calls$sections, "agents")
      NULL
    },
    setup_precommit = function() {
      calls$sections <<- c(calls$sections, "precommit")
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
    setup_formatter = function(air, jarl) {
      calls$formatted <<- c(air = air, jarl = jarl)
      NULL
    },
    .package = "bootstrapper"
  )

  testthat::local_mocked_bindings(
    update_wordlist = function(confirm = FALSE) {
      expect_false(confirm)
      NULL
    },
    .package = "spelling"
  )

  expect_null(bootstrapper::pkg_setup())

  expect_true("testthat" %in% calls$actions)
  expect_true("readme:FALSE" %in% calls$actions)
  expect_true("news:FALSE" %in% calls$actions)
  expect_true("tidy_description" %in% calls$actions)
  expect_identical(calls$sections, c("gha", "dependabot", "precommit"))
  expect_true(calls$replaced)
  expect_identical(calls$formatted, c(air = TRUE, jarl = TRUE))
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
    setup_gha = function() {
      called <<- TRUE
      NULL
    },
    setup_dependabot = function() {
      called <<- TRUE
      NULL
    },
    setup_agents = function() {
      called <<- TRUE
      NULL
    },
    setup_precommit = function() {
      called <<- TRUE
      NULL
    },
    find_replace_in_file = function(from, to, file, fixed = TRUE) NULL,
    setup_formatter = function(air, jarl) {
      formatted <<- all(c(air, jarl))
      NULL
    },
    .package = "bootstrapper"
  )

  testthat::local_mocked_bindings(
    update_wordlist = function(confirm = FALSE) {
      expect_false(confirm)
      NULL
    },
    .package = "spelling"
  )

  expect_null(
    bootstrapper::pkg_setup(
      setup_gha = FALSE,
      setup_dependabot = FALSE,
      setup_AGENTS = FALSE,
      setup_precommit = FALSE
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
    setup_gha = function() NULL,
    setup_dependabot = function() NULL,
    setup_agents = function() {
      called <<- TRUE
      NULL
    },
    find_replace_in_file = function(from, to, file, fixed = TRUE) NULL,
    setup_precommit = function() NULL,
    setup_formatter = function(air, jarl) NULL,
    .package = "bootstrapper"
  )

  testthat::local_mocked_bindings(
    update_wordlist = function(confirm = FALSE) {
      expect_false(confirm)
      NULL
    },
    .package = "spelling"
  )

  expect_null(bootstrapper::pkg_setup(
    setup_AGENTS = TRUE,
    setup_precommit = FALSE
  ))
  expect_true(called)
})

test_that("setup_gha runs expected usethis, replacement, and template calls", {
  setup_gha <- getFromNamespace("setup_gha", "bootstrapper")
  actions <- list(
    github_actions = list(),
    replacements = character(),
    workflow_replacements = character(),
    spell = FALSE,
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
    find_replace_in_file = function(from, to, file, fixed = TRUE) {
      actions$workflow_replacements <<- c(
        actions$workflow_replacements,
        paste(from, to, file, fixed, sep = " -> ")
      )
      NULL
    },
    .package = "bootstrapper"
  )

  expect_null(setup_gha())
  expect_length(actions$github_actions, 2)
  expect_identical(actions$github_actions[[1]][[1]], "check-standard")
  expect_true(isTRUE(actions$github_actions[[1]]$badge))
  expect_identical(actions$github_actions[[2]][[1]], "test-coverage")
  expect_true(actions$spell)
  expect_identical(
    actions$replacements,
    c(
      "actions/checkout@v4 -> actions/checkout@v7",
      "actions/upload-artifact@v4 -> actions/upload-artifact@v7",
      "JamesIves/github-pages-deploy-action@v4.5.0 -> JamesIves/github-pages-deploy-action@v4"
    )
  )
  expect_identical(
    actions$workflow_replacements,
    c(
      paste(
        "token: ${{ secrets.CODECOV_TOKEN }}",
        "use_oidc: true",
        fs::path(".github", "workflows", "test-coverage.yaml"),
        "TRUE",
        sep = " -> "
      ),
      paste(
        "permissions: read-all",
        "permissions:\n  contents: read\n  id-token: write",
        fs::path(".github", "workflows", "test-coverage.yaml"),
        "TRUE",
        sep = " -> "
      )
    )
  )
})

test_that("setup_dependabot copies dependabot template", {
  setup_dependabot <- getFromNamespace(
    "setup_dependabot",
    "bootstrapper"
  )
  captured <- list(template_file = NULL, destination = NULL)

  testthat::local_mocked_bindings(
    copy_template_file = function(template_file, destination) {
      captured$template_file <<- template_file
      captured$destination <<- destination
      NULL
    },
    .package = "bootstrapper"
  )

  expect_null(setup_dependabot())
  expect_identical(captured$template_file, "dependabot.yml")
  expect_identical(captured$destination, fs::path(".github", "dependabot.yml"))
})

test_that("setup_agents copies AGENTS template", {
  setup_agents <- getFromNamespace("setup_agents", "bootstrapper")
  captured <- list(
    template_file = NULL,
    destination = NULL,
    build_ignore = NULL
  )

  testthat::local_mocked_bindings(
    copy_template_file = function(template_file, destination) {
      captured$template_file <<- template_file
      captured$destination <<- destination
      NULL
    },
    .package = "bootstrapper"
  )

  testthat::local_mocked_bindings(
    use_build_ignore = function(path, ...) {
      captured$build_ignore <<- path
      NULL
    },
    .package = "usethis"
  )

  expect_null(setup_agents())
  expect_identical(captured$template_file, "AGENTS.md")
  expect_identical(captured$destination, "AGENTS.md")
  expect_identical(captured$build_ignore, "AGENTS.md")
})

test_that("setup_precommit writes a bash hook and marks it executable", {
  setup_precommit <- getFromNamespace("setup_precommit", "bootstrapper")
  captured <- list(template_file = NULL, destination = NULL, chmod = NULL)

  testthat::local_mocked_bindings(
    copy_template_file = function(template_file, destination) {
      captured$template_file <<- template_file
      captured$destination <<- destination
      NULL
    },
    .package = "bootstrapper"
  )

  testthat::local_mocked_bindings(
    Sys.chmod = function(paths, mode = "0777", use_umask = TRUE) {
      captured$chmod <<- list(paths = paths, mode = mode)
      TRUE
    },
    .package = "base"
  )

  expect_null(setup_precommit())
  expect_identical(captured$template_file, "pre-commit")
  expect_identical(
    captured$destination,
    fs::path(".git", "hooks", "pre-commit")
  )
  expect_identical(
    captured$chmod$paths,
    fs::path(".git", "hooks", "pre-commit")
  )
  expect_identical(captured$chmod$mode, "0755")
})

test_that("cleanup_buildignore removes empty lines", {
  tmp <- tempfile("bootstrapper-buildignore-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  cleanup_buildignore <- getFromNamespace(
    "cleanup_buildignore",
    "bootstrapper"
  )

  writeLines(
    c("^.*\\.Rproj$", "^\\.Rproj\\.user$", "keep-this", ""),
    ".Rbuildignore"
  )

  expect_null(cleanup_buildignore())
  expect_identical(
    readLines(".Rbuildignore", warn = FALSE),
    c("^.*\\.Rproj$", "^\\.Rproj\\.user$", "keep-this")
  )
})

test_that("cleanup_buildignore keeps unrelated entries", {
  tmp <- tempfile("bootstrapper-buildignore-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  cleanup_buildignore <- getFromNamespace(
    "cleanup_buildignore",
    "bootstrapper"
  )

  writeLines(c("foo", "bar", ""), ".Rbuildignore")

  expect_null(cleanup_buildignore())
  expect_identical(readLines(".Rbuildignore", warn = FALSE), c("foo", "bar"))
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

  withr::local_options(list(bootstrapper.interactive = FALSE))

  testthat::local_mocked_bindings(
    cli_inform = function(message, ...) {
      messages <<- c(messages, message)
      NULL
    },
    cli_warn = function(message, ...) {
      messages <<- c(messages, message)
      NULL
    },
    .package = "cli"
  )

  expect_null(bootstrapper::use_license())
  expect_true(any(grepl("Select a license", messages, fixed = TRUE)))
  expect_true(any(grepl("No license selected", messages, fixed = TRUE)))
})

test_that("use_license applies selected license in interactive mode", {
  used_mit <- FALSE
  warned <- FALSE

  withr::local_options(list(bootstrapper.interactive = TRUE))

  testthat::local_mocked_bindings(
    menu = function(choices, title = NULL, graphics = FALSE) {
      expect_identical(title, "License")
      expect_true("MIT" %in% choices)
      1L
    },
    .package = "utils"
  )

  testthat::local_mocked_bindings(
    cli_inform = function(message, ...) NULL,
    cli_warn = function(message, ...) {
      warned <<- TRUE
      NULL
    },
    .package = "cli"
  )

  testthat::local_mocked_bindings(
    use_mit_license = function(...) {
      used_mit <<- TRUE
      NULL
    },
    .package = "usethis"
  )

  expect_null(bootstrapper::use_license())
  expect_true(used_mit)
  expect_false(warned)
})

test_that("use_license dispatches all remaining license helpers", {
  called <- character()
  current_label <- NULL
  label_to_fn <- c(
    "GPL" = "use_gpl_license",
    "GPL-3" = "use_gpl3_license",
    "LGPL" = "use_lgpl_license",
    "AGPL" = "use_agpl_license",
    "AGPL-3" = "use_agpl3_license",
    "Apache-2.0" = "use_apl2_license",
    "Apache" = "use_apache_license",
    "CC BY" = "use_ccby_license",
    "CC0" = "use_cc0_license",
    "Proprietary" = "use_proprietary_license"
  )

  withr::local_options(list(bootstrapper.interactive = TRUE))

  testthat::local_mocked_bindings(
    menu = function(choices, title = NULL, graphics = FALSE) {
      match(current_label, choices)
    },
    .package = "utils"
  )

  testthat::local_mocked_bindings(
    cli_inform = function(message, ...) NULL,
    cli_warn = function(message, ...) NULL,
    .package = "cli"
  )

  testthat::local_mocked_bindings(
    use_mit_license = function(...) {
      called <<- c(called, "use_mit_license")
      NULL
    },
    use_gpl_license = function(...) {
      called <<- c(called, "use_gpl_license")
      NULL
    },
    use_gpl3_license = function(...) {
      called <<- c(called, "use_gpl3_license")
      NULL
    },
    use_lgpl_license = function(...) {
      called <<- c(called, "use_lgpl_license")
      NULL
    },
    use_agpl_license = function(...) {
      called <<- c(called, "use_agpl_license")
      NULL
    },
    use_agpl3_license = function(...) {
      called <<- c(called, "use_agpl3_license")
      NULL
    },
    use_apl2_license = function(...) {
      called <<- c(called, "use_apl2_license")
      NULL
    },
    use_apache_license = function(...) {
      called <<- c(called, "use_apache_license")
      NULL
    },
    use_ccby_license = function(...) {
      called <<- c(called, "use_ccby_license")
      NULL
    },
    use_cc0_license = function(...) {
      called <<- c(called, "use_cc0_license")
      NULL
    },
    use_proprietary_license = function(...) {
      called <<- c(called, "use_proprietary_license")
      NULL
    },
    .package = "usethis"
  )

  for (label in names(label_to_fn)) {
    current_label <- label
    called <- character()

    expect_null(bootstrapper::use_license())
    expect_identical(called, unname(label_to_fn[[label]]))
  }
})

test_that("copy_template_file creates parent directories and copies content", {
  tmp <- tempfile("bootstrapper-template-copy-")
  dir.create(tmp)
  old <- setwd(tmp)
  on.exit(setwd(old), add = TRUE)

  copy_template_file <- getFromNamespace("copy_template_file", "bootstrapper")
  destination <- fs::path("nested", ".github", "dependabot.yml")

  expect_false(file.exists(destination))
  expect_null(copy_template_file("dependabot.yml", destination))
  expect_true(file.exists(destination))
  writeLines("stale", destination)
  expect_null(copy_template_file("dependabot.yml", destination))
  expect_identical(
    readLines(destination, warn = FALSE),
    readLines(
      fs::path_package("bootstrapper", "templates", "dependabot.yml"),
      warn = FALSE
    )
  )
})

test_that("setup_formatter configures air and jarl together", {
  calls <- character()

  testthat::local_mocked_bindings(
    use_air = function() {
      calls <<- c(calls, "use_air")
      NULL
    },
    use_github_action = function(url) {
      calls <<- c(calls, paste("use_github_action", url))
      NULL
    },
    use_build_ignore = function(path, ...) {
      calls <<- c(calls, paste("build_ignore", path))
      NULL
    },
    .package = "usethis"
  )

  testthat::local_mocked_bindings(
    copy_template_file = function(template_file, destination) {
      calls <<- c(calls, paste("copy", template_file, destination))
      NULL
    },
    silent_system2 = function(command, args = character(), ...) {
      calls <<- c(calls, paste(command, paste(args, collapse = " ")))
      TRUE
    },
    .package = "bootstrapper"
  )

  expect_null(bootstrapper::setup_formatter())
  expect_identical(
    calls,
    c(
      "use_air",
      paste("copy", "extensions.json", fs::path(".vscode", "extensions.json")),
      "air format .",
      "copy jarl.toml jarl.toml",
      "build_ignore jarl.toml",
      "jarl check . --fix --allow-dirty",
      "use_github_action https://github.com/visruthsk/bootstrapper/blob/main/.github/workflows/format-suggest.yaml"
    )
  )
})

test_that("setup_formatter configures jarl without air", {
  calls <- character()

  testthat::local_mocked_bindings(
    use_build_ignore = function(path, ...) {
      calls <<- c(calls, paste("build_ignore", path))
      NULL
    },
    .package = "usethis"
  )

  testthat::local_mocked_bindings(
    copy_template_file = function(template_file, destination) {
      calls <<- c(calls, paste("copy", template_file, destination))
      NULL
    },
    silent_system2 = function(command, args = character(), ...) {
      calls <<- c(calls, paste(command, paste(args, collapse = " ")))
      TRUE
    },
    .package = "bootstrapper"
  )

  expect_null(bootstrapper::setup_formatter(air = FALSE, jarl = TRUE))
  expect_identical(
    calls,
    c(
      "copy jarl.toml jarl.toml",
      "build_ignore jarl.toml",
      "jarl check . --fix --allow-dirty",
      paste(
        "copy",
        "jarl.yaml",
        fs::path(".github", "workflows", "format-suggest.yaml")
      )
    )
  )
})

test_that("setup_formatter configures air without jarl", {
  calls <- character()

  testthat::local_mocked_bindings(
    use_air = function() {
      calls <<- c(calls, "use_air")
      NULL
    },
    .package = "usethis"
  )

  testthat::local_mocked_bindings(
    copy_template_file = function(template_file, destination) {
      calls <<- c(calls, paste("copy", template_file, destination))
      NULL
    },
    silent_system2 = function(command, args = character(), ...) {
      calls <<- c(calls, paste(command, paste(args, collapse = " ")))
      TRUE
    },
    .package = "bootstrapper"
  )

  expect_null(bootstrapper::setup_formatter(air = TRUE, jarl = FALSE))
  expect_identical(
    calls,
    c(
      "use_air",
      paste("copy", "extensions.json", fs::path(".vscode", "extensions.json")),
      "air format .",
      paste(
        "copy",
        "air.yaml",
        fs::path(".github", "workflows", "format-suggest.yaml")
      )
    )
  )
})

test_that("setup_formatter can skip format commands", {
  calls <- character()

  testthat::local_mocked_bindings(
    use_air = function() {
      calls <<- c(calls, "use_air")
      NULL
    },
    use_github_action = function(url) {
      calls <<- c(calls, paste("use_github_action", url))
      NULL
    },
    use_build_ignore = function(path, ...) {
      calls <<- c(calls, paste("build_ignore", path))
      NULL
    },
    .package = "usethis"
  )

  testthat::local_mocked_bindings(
    copy_template_file = function(template_file, destination) {
      calls <<- c(calls, paste("copy", template_file, destination))
      NULL
    },
    silent_system2 = function(...) {
      calls <<- c(calls, "format")
      TRUE
    },
    .package = "bootstrapper"
  )

  expect_null(bootstrapper::setup_formatter(format = FALSE))
  expect_identical(
    calls,
    c(
      "use_air",
      paste("copy", "extensions.json", fs::path(".vscode", "extensions.json")),
      "copy jarl.toml jarl.toml",
      "build_ignore jarl.toml",
      "use_github_action https://github.com/visruthsk/bootstrapper/blob/main/.github/workflows/format-suggest.yaml"
    )
  )
})

test_that("setup_formatter does nothing when both formatters are disabled", {
  called <- FALSE

  testthat::local_mocked_bindings(
    use_air = function() {
      called <<- TRUE
      NULL
    },
    use_github_action = function(...) {
      called <<- TRUE
      NULL
    },
    .package = "usethis"
  )

  testthat::local_mocked_bindings(
    copy_template_file = function(...) {
      called <<- TRUE
      NULL
    },
    silent_system2 = function(...) {
      called <<- TRUE
      TRUE
    },
    .package = "bootstrapper"
  )

  expect_null(bootstrapper::setup_formatter(air = FALSE, jarl = FALSE))
  expect_false(called)
})

test_that("silent_system2 runs requested command and returns status", {
  silent_system2 <- getFromNamespace("silent_system2", "bootstrapper")
  commands <- character()

  testthat::local_mocked_bindings(
    system2 = function(command, args, stdout = FALSE, stderr = FALSE, ...) {
      commands <<- c(commands, paste(command, paste(args, collapse = " ")))
      0L
    },
    .package = "base"
  )

  status <- silent_system2("air", c("format", "."))

  expect_identical(commands, "air format .")
  expect_true(status)
})

test_that("silent_system2 marks failed commands as FALSE", {
  silent_system2 <- getFromNamespace("silent_system2", "bootstrapper")

  testthat::local_mocked_bindings(
    system2 = function(command, args, stdout = FALSE, stderr = FALSE, ...) {
      stop("tool missing")
    },
    .package = "base"
  )

  status <- silent_system2("air", c("format", "."))
  expect_false(status)
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

  writeLines(c("abc123", "abc999"), "regex.txt")
  expect_true(find_replace_in_file(
    "^abc[0-9]+$",
    "ID",
    "regex.txt",
    fixed = FALSE
  ))
  expect_identical(readLines("regex.txt", warn = FALSE), c("ID", "ID"))

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
  find_replace_in_gha("actions/checkout@v4", "actions/checkout@v7")
  expect_match(
    readLines(fs::path(".github", "workflows", "check.yml")),
    "checkout@v7"
  )
})
