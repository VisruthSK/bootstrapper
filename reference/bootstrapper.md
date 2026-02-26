# Bootstrap a New R Package

Create a package with some opinionated setup.

## Usage

``` r
bootstrapper(
  fields = getOption("usethis.description", list(`Authors@R` = person("Visruth",
    "Srimath Kandali", , "public@visruth.com", role = c("aut", "cre", "cph"), comment =
    c(ORCID = "0009-0005-9097-0688")))),
  setup_gha = TRUE,
  setup_dependabot = TRUE,
  setup_AGENTS = FALSE,
  setup_precommit = TRUE,
  ...
)
```

## Arguments

- fields:

  Named list of `DESCRIPTION` fields passed to
  [`usethis::create_package()`](https://usethis.r-lib.org/reference/create_package.html).
  See
  [`usethis::use_description()`](https://usethis.r-lib.org/reference/use_description.html)

- setup_gha:

  Whether to configure GitHub Actions setup.

- setup_dependabot:

  Whether to write a Dependabot configuration.

- setup_AGENTS:

  Whether to write a default AGENTS file.

- setup_precommit:

  Whether to write a Bash pre-commit hook.

- ...:

  Additional arguments passed to
  [`usethis::create_package()`](https://usethis.r-lib.org/reference/create_package.html).

## Value

Invisibly returns `NULL`.
