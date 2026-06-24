# Opinionated Package Setup

Run the package setup steps used by `bootstrapper`, including test
infrastructure, README/NEWS creation, GitHub Actions, and linting
defaults. Run this in the root directory of your package.

## Usage

``` r
pkg_setup(
  setup_gha = TRUE,
  setup_dependabot = TRUE,
  setup_AGENTS = FALSE,
  setup_precommit = TRUE,
  setup_touchstone = FALSE,
  setup_touchstone_plots = FALSE,
  setup_air = TRUE,
  setup_jarl = TRUE
)
```

## Arguments

- setup_gha:

  Whether to configure GitHub Actions setup.

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

- setup_air:

  Whether to configure Air formatting.

- setup_jarl:

  Whether to configure Jarl linting.

## Value

Invisibly returns `NULL`.
