---
title:  "Bluetooth Part 1"
---

I've recently become interested in bluetooth, specifically web-bluetooth, which
is newly enabled in most chrome/firefox/opera browsers. It allows a web app
(javascript) to interact with bluetooth devices near the web browser. Combine
this with [eddystone beacons]() and the bluetooth device is advertising a URL
that links a user directly to an app to interact with the device.

## Hardware and software

To play with bluetooth, the first thing I needed was a bluetooth radio. Some
simple beacon stuff can be done with the [beacon toy
app](https://play.google.com/store/apps/details?id=com.uriio), I wanted to use a
microcontroller, suitable for embedding into projects, as this was my eventual
goal. There are plenty of good options on this front:

* [micro:bit](https://www.sparkfun.com/products/14208)
* [Adafruit nRF51](https://www.adafruit.com/product/2267)
* [Adafruit nRF52](https://www.adafruit.com/product/3406)
* [Sparkfun ESP32 Thing](https://www.sparkfun.com/products/13907)
* many more.

I went for the Adafruit nRF52, only because that was the first one that caught
my eye. the micro:bit has several other onboard sensors, and is cheaper, so I
may switch to that platform eventually.

To program the nRF52, i'm using the arduino toolchain, but since i'm a vim user,
i'm editing primarily with vim, and only using the arduino IDE parts for the
compilation. (I later switched to using the [vim-arduino
plugin](https://github.com/stevearc/vim-arduino), but i'll talk about that setup
separately).

There are also some mobile apps that are helpful here, notably [nRF
Connect](https://play.google.com/store/apps/details?id=no.nordicsemi.android.mcp),
which is produced by Nordic Semiconductor, a major manufacturer of bluetooth
chips. It has a variety of modes, and companion apps that i found indispensible
for debugging and testing these examples.

## First steps: [Eddystone Beacon](https://github.com/muncus/bluetooth-projects/tree/master/eddystone_url)

My first goal was to just get an Eddystone beacon broadcasting, to direct an
interested user to a web page. The
[code](https://github.com/muncus/bluetooth-projects/tree/master/eddystone_url)
is nearly verbatim from the adafruit nRF52 example. it is important to note that
the Eddystone protocol only allocates **17 bytes** for the encoded URL. No error
message is emitted when using a url that is too long.
The best practice for avoiding problems here is to use a url shortener like
[goo.gl](http://goo.gl). This has the added benefit of letting you change the
beacon's destination without having to update the beacon device.

## Next: Playbulb [candle emulation](https://github.com/muncus/bluetooth-projects/tree/master/playbulb_candle)

At this point, i'm more familiar with arduino/C++ than with javascript, so I
opted to create a device that an existing webapp could interact with. I stumbled
on the [playbulb candle
codelab](https://codelabs.developers.google.com/codelabs/candle-bluetooth),
which interacts with a fairly simple custom bluetooth device.

Based on the javascript code, I discovered the protocol used to set the name,
color and light effect on the playbulb candle devices. These are handled by
individual Characteristics inside of a Bluetooth GATT service. Armed with this
knowledge, i created [a sketch](https://github.com/muncus/bluetooth-projects/tree/master/playbulb_candle)
that implemented enough of the service to interact with the app.

The webapp has some rough edges, notably that if web-bluetooth is not enabled,
there is no error message displayed (though there is one printed to the
javascript console if you open chrome's developer tools). The same is true if
you access the page over http, rather than https. (https is required for all
web-bluetooth functionality, in accordance with the spec).

The big takeaway from this example is that i've now implemented entirely custom
BLE services on the device, with read-only and read-write characteristics. These
can serve as the basis for any custom services I build later.

## Nordic Uart Service: not-exactly-standard, [but close enough](https://github.com/muncus/bluetooth-projects/tree/master/terminal_echo/).

> Chronologically, this project was the second one i built, not the third. but
> logically it makes more sense here.

In my research about bluetooth LE services, i kept seeing references to the
Nordic Uart Service (NUS). This is a service common to many of the chips from
Nordic Semiconductor, that emulates a standard bluetooth [UART connection over
BLE](https://devzone.nordicsemi.com/documentation/nrf51/6.0.0/s110/html/a00066.html).

While the nRF52 i'm using is made by Nordic, it does not have built-in support
for this service, so I decided to build a simple Echo service on the NUS
protocol. A later addition can interpret commands delivered over this link, to
perform actions. See the [terminal
echo](https://github.com/muncus/bluetooth-projects/terminal_echo) sketch for the
details here. I was now able to use nRF Connect mobile app to connect to the
device over NUS, and send/receive text.

Wondering how to apply this to a web-bluetooth app, i came across a [web
bluetooth terminal](https://github.com/1oginov/Web-Bluetooth-Terminal) app that
had a similar behavior, but was built using only a single service and
characteristic, where NUS uses two characteristics in the same service (one for
Transmit, and one for Receive). With some refactoring of the main javascript
file, I was eventually able to produce a terminal app that's compatible with
NUS, and could use it to connect and interact with my bluetooth echo device,
which would dutifully reply with whatever it was sent. (as long as it was in
chunks smaller than 20 bytes, which is the max write size for a ble
characteristic). The original terminal had some buffering to work around this,
but with my limited javascript experience, i decided to remove it, as it
complicated the parsing of ble packets.

### What's next?

Well, now that i've mastered beacons, created custom services and
characteristics, and exchanged simple text commands over BLE, its time to build
something **bigger**! Maybe Zork over ble, or multi-player bluetooth
hungry-hungry-hippos. I'm not sure exactly what's next, but stay tuned to find
out!
