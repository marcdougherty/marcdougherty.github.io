# Quick tip: easy terminal demo gifs with `vhs` :vhs:
*October 22, 2026*


I build commandline tools pretty often, but I never liked making screenshots.
Sometimes they're blurry due to zooming, or I change my interface or output
format, and now my screenshot is out of date.

If you struggle with this too, let me introduce
[`vhs`](https://github.com/charmbracelet/vhs).

<!-- more -->

`vhs` (named for the VHS video cartridge format) turns a simple scripting
language into animated gifs. Want to see how it works? Let's *rewind* and start
from the beginning!

#### Install `vhs`

`vhs` is available in many installer formats, including:
- Brew: `brew install vhs`
- Go: `go install github.com/charmbracelet/vhs@latest`

> [!IMPORTANT]
> You'll need `ttyd` and `ffmpeg`, as `vhs` uses them to make the gifs.

#### Writing your first `vhs` tape

The vhs language is simple, and can be viewed with `vhs manual`. Here are the
most vital bits:

- `Type "things go here"` : sends keystrokes to the virtual terminal.
- `Enter` : sends an enter key.
- `Sleep <time>` : waits (giving your viewer time to read)
- `Hide` / `Show` : allows you to `Type` things but not show them in the output
- Arrow keys: `Left` `Right` `Up` `Down`.

With just this tiny subset, you can make pretty elaborate demonstrations of
terminal tools and applications.

For a more complete example (that's almost entirely just the above items), you
can see the [demo.tape for
a2term](https://github.com/muncus/a2term/blob/main/demo.tape).

#### Run the tape:

Not much to say here. just `vhs demo.tape`.

Once the tool is done, you should get a smooth gif like this:

![a2term demo gif](/images/a2term-demo.gif)

Creating the tape file is a bit of upfront work. You can use an LLM to create
them (agents do a pretty good job, IMO). But there's also an easier way: `vhs
record`.

Record mode will generate a tape file for you, based on your actions.
Note that it will output the tapefile to stdout, so you may want to run `vhs
record > myfile.tape`

> [!WARNING]
> vhs' default shell is bash. so if you're using bash, it may **look** like the
> `vhs record` command hasn't done anything. I recommend specifying a
> the shell with `--shell` to ensure you dont forget you're recording a tape
> file!

Once you exit the subshell `vhs` spawned, you can check out your new tape file
and make any necessary changes.

If you **really** want these images to be automatic, you could create a Github
Actions workflow to run the vhs files and submit the changes -- be careful
though, that might cause an infite loop of re-generation!

(consider an on-demand workflow that only triggers on `workflow_dispatch`, then
you can run it with the push of a button!)

While writing this, I learned that `vhs` can also take screenshots! So If you
want static screenshots, you can add `Screenshot homepage.png` to your tape
file, and it will *also* output a still image, in addition to your animated gif.

Happy recording, and "be kind, rewind"! :rofl: :clapper:

