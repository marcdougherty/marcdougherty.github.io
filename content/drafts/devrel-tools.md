---
title: My DevRel Toolkit
---

The following is a loose collection of notes about my work practices as a
Developer Relations Engineer.

## Content on a Schedule

Producing content is a big part of DevRel, and viewers (and algorithms) prefer
a consistent cadence. But since DevRel content requires creativity, it doesn't
always come on a schedule. So, here are some methods I use to keep a steady
queue flowing.

### Buffer

[buffer.com](http://buffer.com) allows me to setup all of my social media
channels, and queue up posts. I generally aim for one post per week on each
channel, with my posting windows on different days.

I aim to keep at least a few posts in the queue, and the buffer app on my phone
alerts me when the queue is empty.

### Blog

To run this blog, I use [hugo](http://gohugo.io), hosted on [github
pages](http://github.com/pages). I use github actions to trigger a hugo site
rebuild whenever I push to the `main` branch, and on a schedule.

The scheduled rebuild (which runs daily in the morning), allows me to
future-date blog posts by adding a `publishDate` to the frontmatter. Hugo
ignores future-dated posts, so I run a daily re-build so any posts dated "today"
will be published.
