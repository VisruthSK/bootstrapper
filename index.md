# bootstrapper

The goal of `bootstrapper` is to quickly setup a modern R package with
appropriate actions and assorted setup. The package is more opinionated
than `usethis`, and conforms to some practices which I believe are good.
`bootstrapper` exposes a few helpers which may be useful for existing
packages to use to adopt certain policies, such as using `air` or
`touchstone`.

## Installation

You can install the latest release of `bootstrapper` from the
multiverse:

``` r

install.packages(
  "bootstrapper",
  repos = c("https://community.r-multiverse.org", getOption("repos"))
)
```

You can install the development version like so:

``` r

pak::pak("VisruthSK/bootstrapper")
```

## Usage

You should call the main function in a directory which is already
tracked by git and already has GitHub as a remote.

``` r

bootstrapper::bootstrapper()
```

The main thing to set is the fields option, where you should put your
own name, email, etc. instead.

``` r

bootstrapper::bootstrapper(
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
