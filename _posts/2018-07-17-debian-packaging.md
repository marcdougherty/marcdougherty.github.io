---
title:  Building Debian packages for my own use.
---

I've been a debian/ubuntu user for **years**, but had always been intimidated by
the packaging process (because i tried to read the [New Maintainer's
Guide](https://www.debian.org/doc/manuals/maint-guide/)).
I decided to give it a shot recently, because I was building experimental
software for the raspberry pi, and grew tired for `scp` and `rsync`.

> Note: The advice below does not abide by the debian packaging policy.

Vincent Bernat's [Pragmatic Debian
Packaging](https://vincent.bernat.im/en/blog/2016-pragmatic-debian-packaging)
is a great place to get started. Unfortunately, I only found it near the end of
my efforts.

### So... why?

I had been tinkering with several different raspberry-pi-based projects, and I
found copying around whole directories from my computer (where I do most of the
coding) to the pi was becoming tedious. I was also looking for a clean and
simple way to cleanly remove a project if I later decided it was no longer
needed.

I had looked into a few other 'installation methods', like shell scripts, and
tarballs, etc. But none of them seemed to be quite simple enough to set up.

"Simple?" you say, "you picked *debian packages* because you wanted simple?!"

Well, no. It was not simple, but it does teach me more about debian packages,
which is sure to be beneficial down the line.

### Before we start

There is a great deal of tooling built around debian packaging, but if we start
with the robots, there will be cleanup work to do later.

1. set the environment variables `DEBEMAIL` to your email address, and
   `DEBFULLNAME` to your full (first + last) name. These are used in the
   autogenerated steps to come, and its easier to set them now than to fix the
   generated output.
1. (Optional) put the following in `~/.devscripts`, which is read by many debian
   tools:

   ```bash
   # Do not require directories to conform to packagename-version standard.
   DEVSCRIPTS_CHECK_DIRNAME_LEVEL=0
   # dont rename the directory when the version number changes.
   DEBCHANGE_PRESERVE=no
   # Dont sign packages. I just build them for me, so signing is pointless.
   DEBUILD_DPKG_BUILDPACKAGE_OPTS="-uc -us"
   ```

### Generate boilerplate: `dh_make`

I started by creating a basic debian package with `dh_make --native`. This gives
me a "native" debian package, meaning that there is no separate source tarball
to worry about. For my use case, i felt this was best, as it avoids the
intermediate step of tarring up my files. This approach can be found in an
[appendix of the debian maintainer docs](https://www.debian.org/doc/manuals/maint-guide/advanced.en.html#native-dh-make)

` dh_make --native --packagename=$pkgname_$version`

Where `$pkgname` is the name of the package you're building, and `$version` is
some arbitrary version number.

See [docs on source/format](https://www.debian.org/doc/manuals/maint-guide/dother.en.html#sourcef)
for more information about native vs non-native packages.

This command will generate a `debian/` directory, with lots of files in it.
Anything that ends in `.ex` is an example, and can safely be deleted if you
wish.

### Customize the boilerplate for your needs

The most important two files generated are `debian/control` and `debian/rules`.

#### `debian/control`

The control file is metadata about your package. there are several placeholders
in there, like `Description` and `Section` which should be filled in.

`Build-Deps` is a bit harder, and should include packages needed to build the
package. `Depends` should list packages required for your package to function.
I often guess at the right packages, and test by running a package build.

#### `debian/rules`

This is actually a Makefile, with rules for building your package. Thanks to
debhelper (`dh` and friends), this file is typically short in my experience.
There's a variety of helper utils for specific purposes (for example,
`dh-golang` helps build packages written in Go, and is discussed below).

### Trials and Errors: `debuild`

`debuild` is the main tool for building packages. now that we've customized some
of the debian build files, its time to give it a shot. It probably wont work,
but it **will** tell us what needs to be fixed. The `lintian` tool makes helpful
suggestions that are probably worth fixing, and points out placeholders that
need to be filled in.

The build process assumes that there's a toplevel Makefile, though if you are
packaging a simple collection of files, this is not necessary. See the section
below on [Install and Configuration](#install-and-conffile).

Eventually, you should end up with a functional debian package in the **parent**
directory of your package. If that's all you needed, you're done!


## Helpers, and other considerations

### Install and Conffile

For packages that do not require compilation, or are platform-agnostic (e.g.
python scripts), a Makefile feels a bit overwhelming. There's a simpler
approach: `debian/install`. this file describes how files from the package build
directory should be installed by the package.

For example, a directory with files `a`, `b`, and `c` might choose to install
into different directories like this:

```
a /usr/bin/
b /usr/sbin/
c /etc/
```

That file `c` looks like a configuration file, and we dont want to overwrite
with the package version when we upgrade. `debian/conffiles` provides a
mechanism for this. Just include the path to the *installed* configuration file
(i.e. `etc/c`) in here, and dpkg will treat it as a configuration file.

### Helper: `dh-golang`

The debian go team has a [golang packaging
guide](https://go-team.pages.debian.net/packaging.html) for full details, but
here's the short version:

* install `dh-golang`, which is a deb helper for making go packages.
* in `debian/rules` set `DH_GOPKG` to the name of your go package (what you'd
  usually `go get`)
* in `debian/rules`, add the following options to the `dh` invocation:
  `--buildsystem=golang --with=golang`
* run `debuild` again, and hopefully get a go package!

For binary-only packages, set `DH_GOLANG_BUILDPKG` in `rules`, pointing to only
the packages that are binaries (which are all under `cmd`, right?)

### Helper: `dh-systemd`

If you are creating services to run at startup, say on a raspberry pi, you'll
likely want to include some systemd configuration. There are some docs for
[dh-systemd](https://wiki.debian.org/Teams/pkg-systemd/Packaging).

For debhelper versions >= 10, systemd is activated by default, according to the
above.

add a systemd file as `debian/packagename.systemd`, and it will be included in
the deb package.
