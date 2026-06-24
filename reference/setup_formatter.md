# Configure Formatter Defaults

Sets up Air and/or Jarl formatting defaults. Optionally format the
repository once.

## Usage

``` r
setup_formatter(air = TRUE, jarl = TRUE, format = TRUE, gha = TRUE)
```

## Arguments

- air:

  Whether to configure Air formatting.

- jarl:

  Whether to configure Jarl linting.

- format:

  Whether to format the repository after configuring tools.

- gha:

  Whether to create the appropriate GHA for automatic formatting on PRs.

## Value

Invisibly returns `NULL`.
