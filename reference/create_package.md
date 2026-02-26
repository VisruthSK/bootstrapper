# Create a Package and Connect GitHub

Create a package in root, prompts for a license, cleans up build ignore
file.

## Usage

``` r
create_package(fields = getOption("usethis.description"), ...)
```

## Arguments

- fields:

  Named list of `DESCRIPTION` fields passed to
  [`usethis::create_package()`](https://usethis.r-lib.org/reference/create_package.html).
  See
  [`usethis::use_description()`](https://usethis.r-lib.org/reference/use_description.html)

- ...:

  Additional arguments passed to
  [`usethis::create_package()`](https://usethis.r-lib.org/reference/create_package.html).

## Value

Invisibly returns `NULL`.
