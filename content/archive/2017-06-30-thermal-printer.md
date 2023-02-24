---
title:  "Thermal Receipt printer experiments"
---

I did not really *need* a thermal receipt printer, but i bought one anyway.
Then i tried to make it useful.

[Code on github](https://github.com/muncus/todo-printer)

### The Basics

First, i followed the excellent [tutorial from
Adafruit](https://learn.adafruit.com/mini-thermal-receipt-printer/overview)(where
i bought the printer). It covers all the initial setup stuff very well, and got
me to a working printer that outputs simple text, with some basic text styling
features (and other stuff like barcodes i did not expect to use).

### Printer Drivers

A printer is fun, but I don't typically have a monitor connected to my raspberry
pi, so printing things was infrequent, as I had to ssh into the pi, and run a
script.

I found another excellent adafruit tutorial that described the setup process for
a [network-connected thermal printer](
https://learn.adafruit.com/networked-thermal-printer-using-cups-and-raspberry-pi/connect-and-configure-printer).

This let me sent more complex content to the printer, and print from other
computers. This setup is great for printing out a grocery list before heading
off to the grocery store. It uses the thermal printer just like any other
printer.

I ran into some interesting paper sizing troubles here, where pages
were printed in the aspect ratio of a 8.5x11in page, but only 2in wide.

### Print the list, on demand.

Being able to print the grocery list, or my todo list, is good, but still
involves using a regular computer to print out the list. The next idea was to
set up physical buttons that would cause the pi itself to fetch the list, and
print it.

I keep a few different lists on [todoist](http://todoist.com), which has a
decent api, and a python client library. Python is perfect, since the Pi also
has a python-based library for reading the GPIO pins (where we can attach the
buttons). With some small refactoring of the `gpio_listener.py` script from the
above example, it will listen for multiple buttons, and launch the todoist
script to print any number of pre-configured lists.

Be aware that the search strings "supported" by the todoist api are not the same
as the searches done through the search box. Many search features are for paying
customers only. There is a [todoist help
article on Filters](https://support.todoist.com/hc/en-us/articles/205248842-Filters) that
explains available filters, but only some of them appear to work correctly for
me (not a paying customer). Notably, the `no date`, `today`, and `overdue`
filters dont appear to work. :frowning:

I was still able to build a reasonable set [priority
searches](https://github.com/muncus/todo-printer/blob/master/config.yml) that
work well enough for me.

### Aside: packaging

My process so far has been to develop on my laptop, and copy files over to the
Pi for testing. This workflow gets a little tedious, and means i'm constantly
overwriting files with new copies, from a machine which cannot run most of this
code (the pi's GPIO libraries are not available for my laptop).

To ease this tedium, and allow for easier rollbacks, I decided to put the
todo-printer files into a quick-and-dirty debian package, so i'd only need to
copy a single file over to the pi, and could install/uninstall as needed.
My process for doing that will be covered in a separate post about
[quick-and-dirty debian packaging]().

### Enclosure

The last step of the project is to build a suitably attractive case for the pi
and printer. I settled on a cube ~4.5" in all dimensions. This size allows
plenty of room for the printer, and a set of 4 small pushbuttons on the top
surface.
