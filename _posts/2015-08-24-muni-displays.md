---
title:  "Muni Displays"
---

San Francisco's [Muni](http://sfmta.com) trains are not well known for their ability to be on time. Recent [sfmta data](https://www.sfmta.com/about-sfmta/reports/performance-metrics/percentage-time-performance) shows a ~60% on-time rate (where "on-time" includes arriving anywhere between 1 minute before to 4 minutes after the intended time). Fortunately, they provide real-time arrival estimates with the [Next Bus](http://nextbus.com) service. While the [QuickMuni](https://play.google.com/store/apps/details?id=com.worldofbilly.quickmuni) app does a great job of displaying this on my phone, I wanted to build a more "ambient" display, to help me decide when to leave in the morning.

#### Revision 1

My first attempt at a muni display was an Arduino with 3 big LEDs, laid out as a stoplight. A python script parsed train arrival times, and sent them to the arduino, which then lit the corresponding lights: Green for >10 minutes, Yellow for 7-10, Red for 6-7. (These times were chosen based on how long it took for me to walk to the train).

The most obvious drawback here was the need for a computer to run the python script. I was eventually able to get the script running on a wireless access point with DD-WRT, but the package was still rather awkward.

![rev 1 photo](images/muni-v1.jpg "The first working prototype")

Around this time, [Quick Muni](https://play.google.com/store/apps/details?id=com.worldofbilly.quickmuni) came out, so I had a quick phone-based way to check trains, and I lost interest for a while.

#### Revision 2

Some time later, I bought a [Particle Photon](http://particle.io) (formerly known as the Spark Core). Small, and wifi-enabled, it was perfect for a tiny train display.

Instead of a stoplight, I found a small servo, and got the Photon using it very quickly thanks to their builtin `Servo` library. Original Proof-of-concept pushed the train times to the device through the Particle Cloud api, but I wanted the device to be a bit more self-sufficient.

![rev2 photo](images/muni2-back.jpg "Wiring photo of muni 2.0")

To that end, I put together a web server with some configuration that maps the Particle device name (which the device can fetch from the Particle cloud api) to a set of nextbus query parameters. The device requests `/times/scrapple_ferret` (for instance), and the server returns the number of minutes until the next estimated arrival at the stop at which `scrapple_ferret` is configured.

The servo, however, makes a slight noise when it moves, and I found that having it run all night was not ideal. I added a button to activate the device for ~30m, and a pair of LED headlights that turn on when the device activates, and gradually dim as the device turns off.

All that remained was to paint up a display face, vaguely resembling the from of an SF Muni train, and hang it on the wall!

![final enclosure](images/muni2-final.jpg "Finished enclosure, on wall")

The code for this project is available from [github.com/muncus/muni-display](https://github.com/muncus/muni-display).
