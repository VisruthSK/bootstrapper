# Apply Opinionated Package Setup

Run the package setup steps used by `bootstrapper`, including test
infrastructure, README/NEWS creation, GitHub Actions, and linting
defaults. Run this in the root directory of your package.

## Usage

``` r
pkg_setup(
  setup_gha = TRUE,
  setup_dependabot = TRUE,
  setup_AGENTS = FALSE,
  setup_precommit = TRUE
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

## Value

Invisibly returns `NULL`.
