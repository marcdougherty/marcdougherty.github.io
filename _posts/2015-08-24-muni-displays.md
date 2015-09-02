---
title:  "Muni Displays"
layout: stock
published: false
---

San Francisco's [Muni](http://sfmta.com) trains are some of the most unreliable I've ever used. Fortunately, they provide real-time arrival estimates with the [Next Bus](http://nextbus.com) service. While the QuickMuni app does a great job of displaying this on my phone, I wanted to build a more "ambient" display for this, to help me decide when to leave in the morning.

#### Revision 1

My first attempt at a muni display was an Arduino with 3 big LEDs, laid out as a stoplight. A python script parsed train arrival times, and sent them to the arduino, which then lit the corresponding lights: Green for >10 minutes, Yellow for 7-10, Red for 6-7. (These times reflected how urgently I should leave, and how fast I should walk).

The most obvious drawback here was the need for a computer to run the python script. I was eventually able to get the script running on a wireless access point with DD-WRT, but the package was still rather awkward.

![rev 1 photo](images/muni-v1.jpg)

Around this time, [Quick Muni](https://play.google.com/store/apps/details?id=com.worldofbilly.quickmuni) came out, so I had a quick phone-based way to check trains, and I lost interest for a while.

#### Revision 2

Some time later, I bought a [Particle Photon](http://particle.io) (known as a Spark Core at the time). Small, and wifi-enabled, it was perfect for a tiny train display.

Instead of a stoplight, I found a small servo, and got the Photon using it very quickly thanks to their builtin `Servo` library. Original Proof-of-concept pushed the train times to the device through the Particle Cloud api, but that was later replaced by a simple HTTP client on the device polling a nextbus proxy. All that's left now is to finish the enclosure, and hang it on the wall!

![TODO: put photo of v2 here]()

Github has the [code for v2](TODO).
