---
title: "Vim and Arduino"
---

> TL;DR - I made a vim [compiler plugin for arduino](https://github.com/muncus/dotfiles/blob/master/.vim/after/compiler/arduino.vim)
> that parses errors into the quickfix list, and learned a bunch about the
> quickfix list and compiler plugins.

I've been working on several small arduino projects lately (mostly the series of
bluetooth projects posted earlier). While I find the arduino toolchain easy to
use, I've never enjoyed using the editor, or having to use the mouse to click
the `Verify` and `Upload` buttons.

#### Existing vim-arduino integration

A bit of googling brought to my attention that the `arduino` tool can also be
used as a commandline tool as of version 1.15, and has a [man
page](https://github.com/arduino/Arduino/blob/master/build/shared/manpage.adoc).
Much of the desired vim integration exists already, in the
[github/stevearc/vim-arduino](https://github.com/stevearc/vim-arduino/) plugin,
but the one thing I was still missing was the quickfix list of errors.

#### A small discussion of vim variables

This sent me down the rabbithole of reading vim's help about quickfix, and
several other related topics (`setqflist`, `QuickfixCmdPost`, `errorformat`,
`efm-entries`, etc). The first lesson is one of maintainability, as there are
many `errorformat` strings on github, but most of them are just there as one
long string, with commas, like the default one in this vim session:

```
errorformat=%*[^"]"%f"%*\D%l: %m,"%f"%*\D%l: %m,%-G%f:%l: (Each undeclared identifier is reported only once,%-G%f:%l: for each function it appears in.),%-GIn file included from %f:%l:%c:,%-GIn file included from %f:%l:%c\,,%-GIn file included from %f:%l:%c,%-GIn file included from %f:%l,%-G%*[ ]from %f:%l:%c,%-G%*[ ]from %f:%l:,%-G%*[ ]from %f:%l\,,%-G%*[ ]from %f:%l,%f:%l:%c:%m,%f(%l):%m,%f:%l:%m,"%f"\, line %l%*\D%c%*[^ ]%m,%D%*\a[%*\d]: Entering directory%*[`']%f',%X%*\a[%*\d]: Leaving directory %*[`']%f',%D%*\a: Entering directory%*[`']%f',%X%*\a: Leaving directory %*[`']%f',%DMaking %*\a in %f,%f|%l| %m'
```

The first little vim trick is that the option `errorformat` (and all other
options, actually), can be set as variables by prepending `&`. The following two
lines do the same thing:

```
filetype=markdown
let &filetype=markdown
```

Why would we choose the second syntax? I learned from the vim help for
`efm-entries` that there are multiple ways to change the value of long strings
like errorformat. We can build them up from smaller strings by appending, by
using `.=` instead of `=`. According to efm-entries, `+=` and `-=` can be used
to add and remove entries in `errorformat`.

#### Setting `errorformat`

The format of errors is tricky here because the arduino toolchain actually
pre-processes the arduino sketch files into a standard C++ file before building,
so the resulting error messages do not always contain a filename. Sample output:

```
Picked up JAVA_TOOL_OPTIONS: 
Loading configuration...
Initializing packages...
Preparing boards...
Verifying...
sketch_file:32: error: 'asdf' does not name a type
 asdf
 ^
/path/to/sketch_file.ino: In function 'void setupCandleService()':
sketch_file:59: error: 'candleService' was not declared in this scope
   candleService.begin();
   ^
exit status 1
```

Ignoring the "standard" output lines is easy enough with the errorformat
specifier `%-G`, which ignores the lines that match it. (e.g.
`%-GInitializing packages...`).

The next tricky bit was that the two errors above only show one **full** file
path, and it is for the **second** error. Here I considered fetching the
existing quickfix list in a `QuickfixCmdPost`, and "fixing" the files to be
opened, but after spending some time on this solution, it occurred to me that
the most likely outcome was that the error was in the current buffer.

#### Putting it all together

To get the right compiler options set, I created my own vim compiler plugin, for
arduino. Since the existing plugin from stevearc/vim-arduino sets up make, I
used that. The only real settings here are for the `errorformat` parsing (the
top bit is all boilerplate for vim compiler plugins, and copied from the help
docs). Here is the [custom arduino compiler
plugin](https://github.com/muncus/dotfiles/blob/master/.vim/after/compiler/arduino.vim),
and to make it work automatically, I set the compiler in the [filetype plugin
for
arduino](https://github.com/muncus/dotfiles/blob/master/.vim/after/ftplugin/arduino.vim).

Now when I open an arduino sketch file in vim, I can verify the build, and get
decent quickfix integration as well!
