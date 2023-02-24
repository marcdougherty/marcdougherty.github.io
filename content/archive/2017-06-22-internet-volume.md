---
layout: stock
title:  "Internet Volume Control"
---

The Internet can be a very distracting place sometimes. There are so many sites
(particularly social media) that demand our attention, and let us mindlessly
scroll through photos and status updates, when we really want to be doing
something else.

In an effort to aid my own concentration, I build a proof-of-concept Internet
Volume Control that helps filter out some of the distraction.

All my work is up on
[github.com/muncus/internet-volume](http://github.com/muncus/internet-volume)
and the background / origin story is below.

### Inspiration and Design

While i was thinking about this, i considered several possible approaches to
filtering out "noisy" internet content. A "captive portal" like public wifi,
that would have specific rules. A "transparent proxy" that would rewrite
content (sort of like an ad-blocker). These all had different drawbacks,
particularly when it comes to HTTPS content.

Then I realized that there's a service *under* the rest of the internet's noisy
content: DNS! Before an app or a web browser can do anything, it needs to talk
to DNS to find the "address" for the noisy service (e.g. facebook.com). By
intercepting these calls, it is relatively easy to prevent users from accessing
these sites. It is not foolproof (anyone willing to edit their DHCP-received
nameservers can get around it). But it seemed good enough for my purposes.

So, using some handy Ruby libraries, I put together a simple DNS server that
checks the "internet volume" (more on that later) and either returns the
upstream response (from Google's public DNS server), or returns an error of
`NXDOMAIN`, which indicates the name cannot be resolved.

#### Internet Volume

Now that i'd built the guts of the volume control, I needed a way to set the
volume. Obviously, this was going to be a big dial of some kind, but how would
it connect to the rest of the system?

I'd built a few standalone internet-connected things before, and this is just
one more. The wifi-connected dial (well, potentiometer plus wifi-connected
microcontroller) reports the current "position" as a number from 0 - 10. This
number is sent to [adafruit.io](http://io.adafruit.com), but could use any other
IoT pubsub service.

Some updates to the DNS server to read (and cache!) this value, and i'm ready
for distraction-free wifi browsing!

### Future work

I'd like to add a proper captive portal "login" page which describes the
project, so users are not caught by surprise when i dial down the volume.
