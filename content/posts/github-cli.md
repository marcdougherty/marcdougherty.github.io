---
title: More Github CLI Tips
tags: [ gh, cli ]
---

Last year, I started working in a number of public Github repositories, and
learned to use the [`gh` Github CLI](//cli.github.com). I wrote an article about
[using the github cli with multiple
repos](https://dev.to/muncus/using-the-github-cli-with-multiple-repos-38k), but
given how much my workflow has changed, I think its time for an update.

### Picking a random teammate

Sometimes, I need to pick a human to be responsible for something (usually
a PR review). When there is no obvious choice (for example, someone who already
knows the context of the PR), I caught myself relying on the same team members
repeatedly. While this is not a big issue, I wanted a more "fair" way to pick a
random assignee.

To do that, I first needed a quick way to list the members in a github team.
Teams are typically referred to with a `@my-org-name/my-team-name` syntax - but
the [API call to list team
members](https://docs.github.com/en/rest/teams/members#list-team-members) needs
the individual parts, rather than the whole string. [Bash string
manipulation](https://tldp.org/LDP/abs/html/string-manipulation.html) to the
rescue! The following alias uses the `%%` and `##` operators to remove the
substring from the back or front of a string, respectively. This allows us to
get either the org name or team name from the full string. We also use `jq` to
print just the login of each member.

The alias should be added to the `aliases` section of your `gh` config file. On
linux machines, that is `~/.config/gh/config.yml`

```
    members: >
      ! gh api orgs/${1%%/*}/teams/${1##*/}/members |
        jq -r ".[].login"
```

With this alias, I can run `gh members my-org/my-team | shuf -n 1` to pick a
random member of this team.

### Coping with long-running status checks

Some PRs run exhaustive tests as PR Checks, and these can take a while. As
either an author or reviewer, I want to know when the Checks are done, so I can
properly review the change.

To achieve this, I use the following `gh` alias:
```
   # pop up a notification when the checks are complete for a given PR.
    lmk: >
      ! ( gh pr checks $1 --watch > /dev/null ;
          notify-send "GH PR Checks done" \
            $(gh pr view $1 --json  url --jq ".url")
        ) &
```

For the Mac users, you'll need to replace the `notify-send` command with
something like the following, after installing [`terminal-notifier`](https://github.com/julienXX/terminal-notifier):

```
terminal-notifier -title "PR Ready: $1" -message "PR checks done" \
  -contentImage https://github.githubassets.com/images/modules/logos_page/Octocat.png \
  -open $(gh pr view $1 --json  url --jq ".url")
```

In either case, this will produce a little desktop notification when the PR
checks are completed. To use, just give it a PR number, branch, or full URL
(just like with `gh pr view`).

### Maintainer / Reviewer SLOs

One of the responsibilities of a repository maintainer (or reviewer) is
ensuring contributors get timely follow-up on their contributions. I have a
few different reviewer roles, and each of them has different review
expectations. To help me keep them straight, I've written a small `gh`
extension:

{{< github repo="muncus/gh-slocheck" >}}

In brief, the extension allows me to search open PRs, and sorts them with the
oldest ones first, highlighting any that are older than a specified age. Most of
this can be done without an extension command, but I wanted to also include
status indicators for Status Checks, Review status, and Mergeability. Github
provides this information through the API, and the tool just wraps them up in
convenient output.

With this tool, I can now define aliases for reviews assigned to me, and also
for each of my reviewer and maintainer roles.

* Reviews I'm actively involved in:
    `gh slocheck -s "involves:@me is:open review:required" --limit 20`
* Reviews where I'm explicitly requested:
    `gh slocheck -s "user-review-requested:@me is:open"`
* Reviews that are looking for a Golang-samples reviewer:
    `gh slocheck -s "team-review-requested:googlecloudplatform/go-samples-reviewers is:open draft:false status:success" --limit 20 -w 36h`
    * This explicitly checks that the PR is *ready for review*, with passing
      status checks, and non-draft status. It also has a shorter warning period
      than the rest, since this repo has more strict review expectations.

I like to prefix all these aliases with `slo:`, so I can see everything that
needs my input with a few short commands.

### Benefits

This gives me a full view of my github review responsibilities with a few short
commands, and helps me stay on top of PRs that need my attention.

Moving to a gh-extension simplifies my aliases considerably, and gives me more
flexibility in the output format and sort order.
