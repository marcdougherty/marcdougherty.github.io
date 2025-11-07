---
title: Go dependencies and API diffs
---

Maintaining up-to-date dependencies in a large Go codebase is relatively simple
**most** of the time - there are still a few situations that I find challenging.
Notably, when a package does not comply with [semantic
versioning](http://semver.org) and makes API changes in minor versions.

Thanks to the Go communities focus on compatability, this does not usually
affect too many dependencies. Aside from the occasional mistake, two widely used
projects routinely disobey semantic versioning conventions - Kubernetes and
OpenTelemetry.

I understand that these projects have bigger coordination challenges than most,
and I do respect the choices they have made. But I have my own perspective as a
maintainer. :smile:

## Updates and API differences

Go's built-in tooling for identifying updates is pretty great: `go list -m -u
all`
will show you all the dependencies that have a new version.

But this list, for lax maintainers like myself, can sometimes get surprisingly
large. Then Github's Dependabot sends me a massive PR that updates dozens of
dependencies at once, but some tests have started failing! Rather than block
*all* updates on the broken tests, I'd love a way to separate the "low risk"
updates from the higher risk updates.

That's where the [`golang.org/x/exp/apidiff`](http://golang.org/x/exp/apidiff)
package comes in. In essence, this package analyses the exported symbols in two
packages and determines if they are "compatible" (see [apidiff's definition of
compatible](https://pkg.go.dev/golang.org/x/exp/apidiff#section-readme) for
details). While this may not be a perfect heuristic, it is certainly more
information than I had before!

Using API diff, the following process can be performed for each updated
dependency:

1. Load the current and "new" version of a dependency
    - (load from the modcache, or populate it if needed)
1. use `apidiff` to determine the differences in exported symbols
1. Check the `apidiff.Report` for Incompatible differences
    - no incompatible differences means its a low risk update
    - any incompatible differences makes it a high risk update

## The prototype

With the above process in mind, I set out to build a prototype tool that would
do this for me. I would not consider this a "production grade" solution, or
even a "supported" solution - its more of a proof-of-concept. (it does some
awkward things like rummaging around in your `$GOMODCACHE` and running `go
download` to fetch updated dependencies.

{{< github repo="muncus/go-depdiffs" showThumbnail=false >}}

Now I can run `go-depdiffs --risk low` to see all the easy updates, or
`go-depdiffs --risk high -v` to see the API differences in the higher risk
updates.

See the README in the repo for more examples of output and usage.

## Next steps and future work

### Loading

Loading these modules from the modcache mostly works, but could certainly be
improved. For example, `package.Load()` from a file path works, but the [error
handling is
awkward](https://github.com/muncus/go-depdiffs/blob/main/main.go#L73-L80)
because the [package
driver](https://pkg.go.dev/golang.org/x/tools/go/packages#hdr-The_driver_protocol)
gives me errors back as a string. :gasp:

### False positives
There is a high degree of false positives with this approach - notably,
sometimes a symbol changes that my code does not use. One example of this is the
constant `google.golang.org/grpc.Version`, which changes on each release.

In the future, dependency diffs could analyze the calling codebase, to see if
the incompatible symbols are used. This mirrors the approach used in the
`govulncheck` tool, that checks if your code calls any of the exploitable
functions for a known vulnerability.

This information could then be used to lower the assessed risk of a particular
update if none of the incompatible symbols are referenced.

### Pluggable risk assessment

With some significant refactoring of the prototype, I could see a few different
risk assessment styles, selectable from the commandline.

## Conclusions

Overall, this prototype has been a good learning exercise. I'm also willing to
use this tool to take a "first pass" to break down massive, unwieldy pull
requests from `dependabot`.


