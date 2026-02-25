bootrapper <- function(
  path = ".",
  author = person(
    "Visruth",
    "Srimath Kandali",
    ,
    "public@visruth.com",
    role = c("aut", "cre", "cph"),
    comment = c(ORCID = "0009-0005-9097-0688")
  ),
  private = TRUE
) {
  create_package(path, author, private)
  pkg_setup()
  invisible(NULL)
}

pkg_setup <- function() {
  # TODO: check if this is R package
  usethis::use_readme_md(open = FALSE)
  usethis::use_testthat()
  usethis::use_news_md(open = FALSE)

  # GitHub Actions setup
  usethis::use_github_action("check-standard", badge = TRUE)
  usethis::use_github_action("test-coverage", badge = TRUE)
  usethis::use_github_action(
    url = "https://github.com/visruthsk/bootstrapper/blob/main/.github/workflows/format-suggest.yaml"
  )
  usethis::use_pkgdown_github_pages()
  usethis::use_spell_check(error = TRUE)

  # Dependabot
  c(
    "version: 2",
    "updates:",
    "  - package-ecosystem: \"github-actions\"",
    "    directory: \"/\"",
    "    schedule:",
    "      interval: \"weekly\""
  ) |> # TODO: move file to inst?
    write_to_path(fs::path(".github", "dependabot.yml"))

  # Air and Jarl configs
  usethis::use_air()
  c(
    "{",
    '    "recommendations": [',
    '        "Posit.air-vscode",',
    '        "etiennebacher.jarl-vscode"',
    "    ]",
    "}"
  ) |>
    write_to_path(fs::path(".vscode", "extensions.json"))
  c(
    "[lint]",
    "extend-select = [\"TESTTHAT\"]"
  ) |>
    write_to_path(fs::path("tests", "jarl.toml")) # TODO: need to make GHA jarl runs respect this

  # Cleanup
  find_replace_in_gha("actions/checkout@v4", "actions/checkout@v6")
  find_replace_in_gha(
    "JamesIves/github-pages-deploy-action@v4.5.0",
    "JamesIves/github-pages-deploy-action@v4"
  )
  usethis::use_tidy_description()
  invisible(NULL)
}

create_package <- function(
  path = ".",
  author = person(
    "Visruth",
    "Srimath Kandali",
    ,
    "public@visruth.com",
    role = c("aut", "cre", "cph"),
    comment = c(ORCID = "0009-0005-9097-0688")
  ),
  private = TRUE
) {
  usethis::create_package(path = path, fields = list("Authors@R" = author))
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
  # TODO: CLI message select a license; make sure you declare import using usethis useimportfrom
  usethis::use_github(private = private)
  invisible(NULL)
}
