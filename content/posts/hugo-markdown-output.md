---
title: "Serving Markdown from Hugo for better AI legibility"
tags: ["AI", "quicktip", "meta"]
---

When I write an article, I typically post about it on social media, so people
can read it. Eventually I started using AI to draft these social posts, so I
didn't feel like I was repeating myself all the time. The problem was, the AI
would not really read the article -- or worse, write an opaque python script to
try parsing it with BeautifulSoup.:sigh:

So here's how I added Markdown as an available format to my
[Hugo](http://gohugo.io) site, and you can too!

<!-- more -->

To make Hugo posts more readily readable by AI agents, you can output them in
Markdown - which preserves enough of the content structure, with minimal
complication.

You can see how I enabled it for this site with [this commit](), but it's even
simpler than that commit! Hugo by default includes the Markdown media type!

So that means all you really need to do is edit the `[outputs]` section, and
make a few more layout partials.

For `[outputs]`, you'll need to add `markdown` to the list of output formats for
any page type you're using. My config has the following:

```toml
[outputs]
  home = ["HTML", "RSS", "JSON", "markdown"]
  page = ["HTML", "RSS", "JSON", "markdown"]
  section = ["HTML", "RSS", "JSON", "markdown"]
  taxonomy = ["HTML", "RSS", "JSON", "markdown"]
```

Once that's done, you'll need to add layout partials, to "decorate" your
markdown content, and handle indexes and collections.

File: `layouts/_default/index.md`

```markdown
{{ with .Title }}# {{ . }}{{ end }}
{{ with .Site.Params.description }}
> {{ . }}
{{ end }}
{{ .RawContent }}
{{ if .Site.Menus.main }}## Pages
{{ range .Site.Menus.main }}
- [{{ .Name }}]({{ .URL }}/index.md)
{{ end }}{{ end }}
```

File: `layouts/_default/section.md`

```markdown
{{ with .Title }}# {{ . }}{{ end }}
{{ with .Description }}
> {{ . }}
{{ end }}
{{ .RawContent }}
{{ if .Pages }}## Pages
{{ range .Pages }}{{ if not .Draft }}
- [{{ .Title }}]({{ .Permalink }}index.md){{ with .Description }}: {{ . }}{{ end }}
{{ end }}{{ end }}{{ end }}
```

File: `layouts/_default/single.md`

```markdown
{{ with .Title }}# {{ . }}{{ end }}
{{ with .Date }}*{{ .Format "January 2, 2006" }}*{{ end }}

{{ .RawContent }}
```

While having all 3 makes the site pretty usable in markdown mode, I'd say the
most important for me is `single.md`, which displays an individual page.

With these changes, I can now tell an agent "go read this URL and write a short
pithy social post about it for LinkedIn".

It will read the article, see the alternate format tag in the header, and
request the markdown version! The quality of these first-draft posts has
improved greatly since the :robot: started reading the article content!
