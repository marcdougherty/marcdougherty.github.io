---
title: Managing prompts with a personal MCP server
tags: [ AI, MCP ]
---

The term "prompt engineering" makes it sound complex, but like many developers
using AI today, I'm frequently revising my prompts to improve the outcomes. But,
it is easy to lose track of which prompt works best when the prompt is stored in
a `GEMINI.md` or `CLAUDE.md` or `AGENTS.md` file in a project
directory. By storing my prompts in an MCP server, I can simplify the
setup and management overhead, putting the "engineering" back in "prompt
engineering".

## Why MCP?

Let's get this one out of the way early - with so many ways to configure AI
tools, why did I choose MCP?

In a word: **flexibility**. MCP is one of the few established
standards that is available in nearly all AI tools, and this allows me to try
out whatever model/framework/agent/IDE is hot today, without spending time
re-configuring, copying, or symlinking things together.

## Personalized prompts

AI tooling can do a good job as a first-pass reviewer of prose content,
given the right instructions. Without instruction, AI tools tend to produce
bland, flavorless text. To maintain my own coherent voice while using AI
reviewers requires giving somewhat detailed guidance - a great use case for a
reusable prompt.

The "plan, then execute" workflow, sometimes called "spec driven development"
is another case for verbose prompts. I like to keep plan files in their own
directory, with tidy markdown checkboxes for each item. This allows me to edit
the plan or implement a feature without confusing the AI assistance. Rather
than retrain my squishy human brain to work more like the AI, I guide the AI to
read the plan, and update each step as needed. The details here take some
rather specific instruction, but I believe the work pays off in improved
collaboration.

##  My own MCP server

I built a basic skeleton of an MCP server in a few lines of Go, to store these types of personalized, reusable prompts.

{{< github repo="muncus/mcp-starter" showThumbnail=false >}}

The rest of this post explains how I use this system.

## Stored prompts

Consider the "style check" use case mentioned above. I want to provide specific
guidance for the style and voice of prose content for, say, a blog. It will
definitely be used on all blog content, but might also get used outside of that
context, like for social media posts, or other formats. So, lets stick it in
our MCP server.

The format of stored prompts is pretty simple - there's a yaml frontmatter
block at the top, and prompt content below. A self-contained example would look
like this:

```
---
name: review-punctuation
description: ensures personal style of punctuation is correct and consistent.
---
Review the provided content, ensuring that puncutation is correct, and oxford commas are used consistently throughout.
```

All I have to do is drop this into the `prompts` folder as a markdown file, and
run `go build .`. The resulting binary includes all my prompts, and does not
read them from the filesystem (thanks, [`embed`](http://pkg.go.dev/embed)!),
making it simple to use on my local machine, or share with other developers, or
even use in CI/CD pipelines!

## Using prompts

Once you've configured your AI tools to use the MCP server, you can give instructions like:

- "use the stylecheck prompt to review new-article.md"
- "use the review-punctuation prompt on the new-article.md file, and fix any incorrect punctuation"

That's it. And the prompts are only used when they are requested, so they're
not eating up valuable context tokens.

## Identifying versions and keeping current

If I want to verify that i'm using the latest versions of my prompts, I can run `mcp-starter --version`, which will output the git commit hash, and whether or not my contents were modified.

To update my local MCP server, I can easily do so with `go install github.com/muncus/mcp-starter@latest`.

## Summary

My approach is still constantly evolving, and I find it simpler to store my
prompts in an MCP server than scattered around my local disk. Using specific
prompts also helps keep my results personalized to the ways I like to work, and
to streamline multi-step workflows into a single request. Detailed prompt
instructions also help me preserve my own style, and avoid getting "smoothed
out" into the generic style of so much AI slop.
