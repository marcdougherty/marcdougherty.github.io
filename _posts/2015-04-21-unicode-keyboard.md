---
layout: stock
title:  "Unicode (emoji) keyboard"
---

## {{ page.title }}

Emoji keyboards on mobile devices have been in widespread use for a while, but
I sometimes find myself using a computer, and have a hard time remembering the
unicode identifiers for a nice cup of tea (1f375 - 🍵 ) or a suitable warning
character (2620 - ☠ ). So I decided to make a supplemental Unicode keyboard.

![unicode keyboard](/images/unicodekeyboard.jpg)

#### Code

The code can be found on Github: [http://github.com/muncus/unicode-keyboard](
http://github.com/muncus/unicode-keyboard). User-servicable parts are in
`config.h`.

Since the key sequence for entering a unicode character varies by operating
system, the current implementation only supports Linux, though there are notes
in the code for how support for other OSes could be implemented.

#### Build

I had a [Teensy 2.0](https://www.pjrc.com/store/teensy.html) handy, for which
there are several good examples of emulating a USB keyboard. Any old button will
do, but I wanted that good old keyboard feel, so i bought a Cherry MX switch
sampler from [WASD
keyboards](http://www.wasdkeyboards.com/index.php/products/sampler-kit/wasd-6-key-cherry-mx-switch-tester.html)
and some spare switches, just in case.

Wired one side of the switches all to ground, the other side to the first 6 data
pins on the Teensy.

Once that was done, all that was left was to add the symbols to the keys.
Knowing i'd probably want to change these frequently, i chose to print out the
symbols, and just tape them to the keycaps with clear scotch tape. Done!

