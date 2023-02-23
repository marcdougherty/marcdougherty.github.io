---
title: Handy Yaml Tricks!
published: true
tags: yaml
date: 2023-02-08
---

(This content was originally published at https://dev.to/muncus/handy-yaml-tricks-415p)

In the past few years, YAML (http://yaml.org) has become an essential part of software, particularly for infrastructure-as-code tools. Yaml at the heart of [kubernetes](http://kubernetes.io) configuration, kubernetes-inspired APIs like [Google's config connector](https://cloud.google.com/config-connector/docs/concepts/resources), and a number of workflow systems like [Google Cloud Workflows](https://cloud.google.com/workflows) and [Github Actions](http://github.com/features/actions).

In its simplest forms, Yaml is quite human-readable, but over time many of these configurations become more complex, and the documentation of these formats is not always as complete or searchable as we might like. Included below are some small tips that may help you make the most of your Yaml configurations.

### IDE assistance with JSON Schemas!

Do you struggle to remember the names of fields in your Yaml objects? I sure do!

Most modern editors and IDEs support the [Language Server Protocol](https://microsoft.github.io/language-server-protocol/), which powers the code completion, validation, and tooltip features. Combined with a [Yaml Language Server](https://github.com/redhat-developer/yaml-language-server), we can get rich completion for Yaml files!

Installation varies depending on the editor, but I found installation with VSCode to be pretty straightforward.

For many common yaml files, the correct schema can be inferred from the file name, and looked up automatically with [SchemaStore](schemastore.org).  SchemaStore hosts a wide collection of JSON Schemas, which can be used to validate Yaml. SchemaStore is backed by the [SchemaStore Github Repository](https://github.com/schemastore/schemastore/), and contributions of additional JSON Schemas are welcome!

Schema detection can also be configured manually in your editor if auto-detection is inaccurate.

Setting up the Yaml Language Server takes a bit of work, but if you regularly work with complex Yaml objects, you'll be glad you took the time to set it up!

### Better Multiline Strings with `>` and `|`

Sometimes, with workflow configuration like `cloudbuild.yaml` and Github Actions, we write long commandlines that are not very readable in an IDE.

The Yaml spec has what they call [literal style](https://yaml.org/spec/1.2.2/#literal-style) (`|`) and [folded style](https://yaml.org/spec/1.2.2/#813-folded-style) (`>`) to help with this.

Literal Style preserves newlines in the string, so it can be used to run multiple commands as a single step. For example, installing python dependencies and running the relevant tests can be done like this:

```yaml
      - name: Run tests
        run: |
          pip install -r requirements.txt
          pytest -v .
```

**Note**: In some situations, this may mask failures in the earlier commands if the last command exits successfully.

Folding Style "condenses" whitespace in the string, replacing spaces and/or newlines with a single space as describe in the [spec section on line folding](https://yaml.org/spec/1.2.2/#line-folding). In short, it lets us insert newlines in a string to make it more readable.

Consider this very long line from a github actions workflow that calls the github API with `curl`:

```yaml
     - name: Get current repo settings
       run: curl -o repository.json https://api.github.com/repos/${{ github.repository}} -H "Authorization: Bearer ${{ github.token }}"

```

Rewritten with Folding Style, it looks like this instead:

```yaml
     - name: Get current repo settings
       run: >
          curl -o repository.json
          https://api.github.com/repos/${{ github.repository}}
          -H "Authorization: Bearer ${{ github.token }}"
```

For long lines, this can make them easier to read, and easier to edit and review.

These tips have helped me write more maintainable Yaml files, and I hope they help you, too!

