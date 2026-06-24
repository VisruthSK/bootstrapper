# Configure Touchstone

Write a modified Touchstone GHA to benchmark PRs. You still need to
write an appropriate `script.R` for the actual benchmarks. This version
of the touchstone commenting GHA updates a single comment instead of
making multiple. Optionally also adds the touchstone plots in a
dropdown–these plots are stored on a new branch.

## Usage

``` r
setup_touchstone(plots = FALSE)
```

## Arguments

- plots:

  Whether to use the workflow which writes touchstone plots (and needs
  more permissions).

## Value

Invisibly returns `NULL`.
