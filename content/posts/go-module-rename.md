---
title: "Tip: renaming Go modules"
tags: ["quicktip", "go"]
---

I've been working on some experimental code lately, and part of the experiment
has been where and how to host it. Because Go modules use the hosting location
as the import path, this means i've been renaming my modules quite a bit.

<!--more-->

> [!CAUTION]
> Renaming modules once they are published is a bad practice and you
> should avoid it at all costs. But this is experimental code so ... :shrug:

## manual renames

There are essentially two steps to renaming a module.

1. Change how the module defines its own name (in `go.mod`)
1. Change inter-module imports to use this new name

The first step involves editing `go.mod` and changing the `module` directive.
You could do this with your editor, but Go provides a simpler way:

```
go mod edit -module ${newmodulename}
```
This command will update the `module` directive in the current module.

Next up, we need to update all of our imports. This one does not have a handy
go-specific tool, but it is essentially a global search-and-replace. `sed` is a
classic tool for this type of work.

```
find . -name '*.go' | xargs sed -i ''  -e "s^${oldmodule}^${newmodule}^g"
```
This is finding all go files, and passing them to sed.
- `-i ''` says edit each file independently, and don't make backup files.
- the `s` substitution uses carets (`^`) because the traditional separator (`/`)
    is common in go module names, and an alternate separator lets us avoid
    heavily escaping our module paths. `sed` works with a variety of separators.

This two-step process is fairly straightforward, but involves a bunch of tedious
fill-in-the-blanks work. You could write a script to do this, but I chose a
different path.

## taskfile

For small automation tasks, I like to use [taskfile.dev](http://taskfile.dev) --
its a bit like `make` but with yaml syntax and a lot less baggage. Here's how I
structured my task for renaming Go modules:

```
  go:modrename:
    desc: "rename the current go module"
    dir: "{{.USER_WORKING_DIR}}"
    vars:
      CURRENT_MODULE:
        sh: go mod edit -json | jq -r '.Module.Path'
      OLDMODULE: '{{ .OLDMODULE | default .CURRENT_MODULE}}'
    cmds:
      # First, show an error if the required arg is missing.
      - '{{if .CLI_ARGS}}true{{else}}echo "must specify new module path."; false{{end}}'
      - go mod edit -module {{.CLI_ARGS}}
      - find . -name '*.go' | xargs sed -i ''  -e "s^{{.OLDMODULE}}^{{.CLI_ARGS}}^g"
```

I'm using a global Taskfile.yaml, in my home directory, so I can run this
command from anywhere like this:

```
task -g go:modrename -- github.com/mynew/modulepath
```
(the `-g` tells Task to look in my home directory for the global task file,
rather than the current directory).

The use of 2 variables (`OLDMODULE` and `CURRENT_MODULE`) lets me fix a rename
that went wrong, but `go.mod` was already updated correctly. I can specify the
old module name manually like so:

```
# rename imports github.com/oldmodule/mistake ==> github.com/mynew/modulepath
OLDMODULE=github.com/oldmodule/mistake task -g go:modrename -- github.com/mynew/modulepath
```

This gives me a quick, repeatable way to rename modules, making it easier for me
to use a forked module. And helps me to rename it back before I send a PR
(hopefully)!
