# bootstrapper

The goal of bootstrapper is to …

## Installation

You can install the development version of bootstrapper like so:

``` r
# FILL THIS IN! HOW CAN PEOPLE INSTALL YOUR DEV PACKAGE?
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(bootstrapper)
## basic example code
```

## IMPLEMENT THIS WORKFLOW:

``` r
usethis::create_package(".")
# publish repo to GitHub
usethis::use_readme_md()
unlink("*.Rproj")
usethis::use_testthat()

# GitHub Actions Setup
usethis::use_github_action("check-standard", badge = TRUE)
usethis::use_github_action("test-coverage", badge = TRUE)
usethis::use_github_action(
  url = "https://github.com/visruthsk/bootstrapper/blob/main/.github/workflows/format-suggest.yaml"
)
usethis::use_pkgdown_github_pages()
c(
  "version: 2",
  "updates:",
  "  - package-ecosystem: \"github-actions\"",
  "    directory: \"/\"",
  "    schedule:",
  "      interval: \"weekly\""
) |>
  write_to_path(fs::path(".github", "dependabot.yml"))

find_replace_in_dir("actions/checkout@v4", "actions/checkout@v6")
find_replace_in_dir(
  "JamesIves/github-pages-deploy-action@v4.5.0",
  "JamesIves/github-pages-deploy-action@v4"
)

usethis::use_tidy_description()
# pick a license
```
