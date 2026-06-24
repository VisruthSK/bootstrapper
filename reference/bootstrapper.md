# Bootstrap a New R Package

Create a package with some opinionated setup.

## Usage

``` r
bootstrapper(
  fields = getOption("usethis.description"),
  setup_gha = TRUE,
  setup_air = TRUE,
  setup_jarl = TRUE,
  setup_dependabot = TRUE,
  setup_AGENTS = FALSE,
  setup_precommit = TRUE,
  setup_touchstone = FALSE,
  setup_touchstone_plots = FALSE
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

- setup_air:

  Whether to configure Air formatting.

- setup_jarl:

  Whether to configure Jarl linting.

- setup_dependabot:

  Whether to write a Dependabot configuration.

- setup_AGENTS:

  Whether to write a default AGENTS file.

- setup_precommit:

  Whether to write a Bash pre-commit hook.

- setup_touchstone:

  Whether to setup Touchstone benchmarking.

- setup_touchstone_plots:

  Whether to use the Touchstone comment workflow that publishes
  benchmark plots to a separate branch. Only used when
  `setup_touchstone = TRUE`.

## Value

Invisibly returns `NULL`.
