---
title: Home
layout: stock
---

I'm Marc. I work in software, and have a wide range of hobbies, from embedded systems (like [Arduino](http://arduino.cc) and the [Particle Core](http://particle.io)) to sailing, and hand-tool woodworking.


### Blog Posts

{% for post in site.posts %}
#### [{{ post.title }}]({{ post.url }})
  {{ post.excerpt }}


{% endfor %}

I can be found on [github](http://github.com/muncus), [twitter](http://twitter.com/muncus),
and elsewhere.

