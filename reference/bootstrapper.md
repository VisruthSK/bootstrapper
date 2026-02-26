# Bootstrap a New R Package

Create a package with some opinionated setup.

## Usage

``` r
bootstrapper(
  path = ".",
  fields,
  private = TRUE,
  setup_gha = TRUE,
  setup_dependabot = TRUE,
  setup_AGENTS = FALSE,
  ...
)
```

## Arguments

- path:

  Path where the package should be created. Defaults to `"."`

- fields:

  Named list of `DESCRIPTION` fields passed to
  [`usethis::create_package()`](https://usethis.r-lib.org/reference/create_package.html).
  See
  [`usethis::use_description()`](https://usethis.r-lib.org/reference/use_description.html)

- private:

  Whether to create the GitHub repository as private. Defaults to
  `TRUE`.

- setup_gha:

  Whether to configure GitHub Actions setup.

- setup_dependabot:

  Whether to write a Dependabot configuration.

- setup_AGENTS:

  Whether to write a default AGENTS file.

- ...:

  Additional arguments passed to
  [`usethis::create_package()`](https://usethis.r-lib.org/reference/create_package.html).

## Value

Invisibly returns `NULL`.
