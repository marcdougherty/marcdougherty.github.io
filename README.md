## muncus.github.io / marcdougherty.com

A personal website, created with Hugo (gohugo.io)

For local preview with drafts: `hugo serve -D`

For deployment, just push to `main` branch.
Deployment is handled by Github Actions workflow in `.github/workflows/gh-pages.yml`

# Republishing Notes:

- To republish an article on medium, use the [import a
  story](//medium.com/p/import) tool, and past in a URL.

- To republish on Dev (dev.to): paste your markdown content into the input box
  (after removing any hugo-specific shortcodes!!). Be sure to set
  `canonical_url` in the UI under "post options" (the little hexagon). This can
  also be set in the frontmatter when posting via the api.

# TODO:

- improve republishing experience.
