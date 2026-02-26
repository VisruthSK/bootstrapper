# Create a Package and Connect GitHub

Create a package, apply `.Rbuildignore` cleanup, prompt for a license,
and connect the package to GitHub.

## Usage

``` r
create_package(
  path = ".",
  fields = getOption("usethis.description"),
  private = TRUE,
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

- ...:

  Additional arguments passed to
  [`usethis::create_package()`](https://usethis.r-lib.org/reference/create_package.html).

## Value

Invisibly returns `NULL`.
