---
title:  "Big Red Button"
layout: post
---

I was working on a particularly challenging service turndown, which
involved handholding some user migrations. During the waiting periods, it
occurred to me that turning off the service by simply typing the right command
lacked a certain *gravity*.

So I grabbed a [Bluefruit EZ-key](http://www.adafruit.com/products/1535)
(12-key programmable bluetooth keyboard), a big red arcade button, and a 9-volt
battery. Using the [adafruit intro
docs](https://learn.adafruit.com/introducing-bluefruit-ez-key-diy-bluetooth-hid-keyboard),
it was simple to get the button working. But it still wasnt _quite_ right.

It wasn't until i found a fancy cardboard box at the local variety store that
things really came together. A few tasteful stamps invited the pushing of the
big red button.

![push the button!](https://lh4.googleusercontent.com/-hitPdHcQJgw/VTngEO0gasI/AAAAAAAADmo/Mtyxca6ZlNk/w979-h551-no/IMG_20150422_164349.jpg)

I also wrote a quick [script for
pairing](https://raw.githubusercontent.com/muncus/dotfiles/master/bin/ezkey.sh),
since the pairing instructions for linux were a little cumbersome.
(unfortunately, there's a lot of `sudo` in there...).

Now i'm fully prepared for the next dramatic launch (or turndown)!
