# bootstrapper

The goal of bootstrapper is to quickly setup a modern R package with
appropriate actions and assorted setup. Mostly for my own usage, pretty
opinionated.

## Installation

You can install the development version of bootstrapper like so:

``` r
# FILL THIS IN! HOW CAN PEOPLE INSTALL YOUR DEV PACKAGE?
pak::pak("VisruthSK/bootstrapper")
```

## Usage

The package is optimized for my usage by default, so calling the main
function bare is not advised unless you are me.

``` r
bootstrapper:bootstrapper()
```

The main thing to set is the fields option, where you should put your
own name, email, etc. instead.

``` r
bootstrapper:bootstrapper(
  fields = list(
    "Authors@R" = person(
      "Visruth",
      "Srimath Kandali",
      ,
      "public@visruth.com",
      role = c("aut", "cre", "cph"),
      comment = c(ORCID = "0009-0005-9097-0688")
    )
  )
)
```

There are some flags you can set to flip on/off certain features like
publishing the repository as private/public on GitHub, copying over some
GitHub Actions, using Dependabot for GHA, an `AGENTS.md` file, and a
precommit hook for `air` and `jarl` formatting.
