---
title: Jam-O-Matic
---

Inspired by the Amazon Dash-style [esp8266 IoT
button](http://github.com/garthvh/esp8266button), I built a button my distant
family could use to request a refill of my home-made jam (though it could be
used for anything). To keep with the theme, i built the whole thing to fit in a
standard 8oz jam jar.

![photo of finished button](/images/jamomatic.jpg)

Unlike the inspiration, this button should be able to live for months in the
pantry without power, so it needed a power switch. After designing a P-channel
mosfet circuit to handle this, i came across the [adafruit
powerswitch](https://www.adafruit.com/products/1400) which is pretty much
exactly what i needed. Throw a micro-lipo battery charge circuit in there and
*BOOM* - button that turns on the ESP chip, and allow it to turn itself off.

![photo of innards](/images/jamomatic-guts.jpg)

The powerswitch means that there is no longer a "button press" from the ESP
perspective, but the [IFTTT](http://ifttt.com) event should fire as soon as it
gets connected to the wifi network. Minor code changes were needed to make that
happen, and then assert the pin connected to the powerswitch's p-fet gate (to
power off the device). All code is available on
[github/muncus/jamomatic](http://github.com/muncus/jamomatic).

After configuring a couple of IFTTT recipes, a press of the button results in
~20 seconds of powered-on time for the device, and a
[pushbullet](http://pushbullet.com) notification being sent to my phone.

I'm currently playing around with a small thermal printer to print out a
physical receipt for the jam order, so they are harder to ignore. :)

