---
title: Testing changes to Renovate configs
---

I get a bit nervous whenever I touch `renovate.json` files, because I did not
know how to test the effects of my changes. Well, this week I spent some quality
time with Renovate and while the results are not perfect, they're a lot better
than what I had before!

If you're not familiar with [Renovate](https://docs.renovatebot.com/), it is a
convenient way to keep your dependencies up to date. It understands dependencies
in many language ecosystems, and supports a variety of ways to run and configure
Renovate.

## TL;DR

Testing is still a bit tedious, because Renovate has a lot of functionality, and
the output does not conveniently sum up what renovate would do. But the
information *is* there, you just have to know where to look.

First, the command I'm using:

```
LOG_LEVEL=debug \
RENOVATE_CONFIG_FILE=.github/renovate.json \
npx renovate --platform=local \
    --require-config=ignored
```

- `LOG_LEVEL=debug` ensures we get plenty of output about decisions renovate is
  making. we need this flag to see what packages would be updated.
- `RENOVATE_CONFIG_FILE=...` - specifies a local path to a renovate
  configuration to use for this run.
    - note: if you omit `--require-config=ignored`, this config will be
      **merged** with the one from this repository, which can cause unexpected
      results.
- `npx renovate` - uses npx to run renovate. will prompt you to install renovate
  if not already present.
- `--platform=local` - Renovate's [local platform]() works on the current
  directory only, and does not require a remote git repo
- `--require-config=ignored` - tells renovate to ignore any configuration found
  in the repository.

## How I test

In a git checkout of a repository, check out a point in time where I know I
expect some renovate changes - for example, the commit just before your latest
renovate PR was merged.

From here, I modify the `renovate.json` file to reflect my changes.

To ensure the config is well-formed, you can run `npx -p renovate
renovate-config-validator`, which does some syntactic validation.

Then I run renovate, and interpret the results
```
LOG_LEVEL=debug RENOVATE_CONFIG_FILE=.github/renovate.json npx renovate --platform=local --require-config=ignored
```

## Interpreting renovate's debug output

The output from renovate's debug logs is verbose. There are a few things I look
for in the logs.

#### "flattened updates found"

This line summarizes the packages renovate has found updates for. This helps you
ensure your datasources are configure correctly, and that updated packages are
found. As of this writing, the line looks like this:

```
DEBUG: 5 flattened updates found: opentelemetry-sdk, opentelemetry-instrumentation-flask, opentelemetry-instrumentation-jinja2, opentelemetry-instrumentation-requests (repository=local)
```

This tells me that my datasources are configured correctly, because these are
the updates I am expecting. The specific issue this helped me identify is that
the `opentelemetry-instrumentation` packages were considered 'unstable' because
they were versioned as `0.41b0`, which is pre-release by [pep440 versioning
rules](https://peps.python.org/pep-0440/#pre-releases). Adding a renovate
packageRule with `"ignoreUnstable": false` made the instrumentation packages
appear in this list.

#### "packageFiles with updates"

Following this line is a large json object containing information about the
files renovate would edit, and the updates that were found. This object is
large, so I've omitted most of it, and only included the bits I look for:

```
"config": {
 "pip-compile": [
   {
     "deps": [
       {
         "depName": "opentelemetry-sdk",
         "datasource": "pypi",
         "currentVersion": "1.18.0",
         "updates": [
           {
             "bucket": "non-major",
             "newVersion": "1.20.0",
             "releaseTimestamp": "2023-09-04T19:01:22.000Z",
             "updateType": "minor",
             "branchName": "renovate/opentelemetry"
           }
         ],
        // more fields omitted.
       },
       // More dependencies omitted
    ],
    "packageFile": "requirements.in"
   }
 ]
}
```

- **packageFile**: the file in the repository that declares the dependencies.
  This is the file renovate would edit.

The rest of these fields will appear for each depencency renovate finds:

- **depName**: what renovate calls this package.
- **currentVersion**: the version currently listed in the packageFile
- **updates[0].newVersion**: the version renovate will upgrade you to.
- **updates[0].branchName**: the branch that this change will go into. This
  helps you identify if your package grouping rules are working as expected.

This is not the most concise summary of renovate's intended changes, but it has
certainly helped me feel more confident in making `renovate.json` changes.

For a more complete test, it is recommended that you fork an existing repo, and
let renovate run on that fork. For me, this would have required downgrading some
packages so that renovate would have updates to do. That seemed a little tedious
for my current use case, but maybe there will be a part 2
:grinning_face_with_sweat:.
