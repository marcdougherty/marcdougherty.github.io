---
title: MCP Servers and OAuth Credentials
tags: [ AI, MCP, Security ]
series: [ "Building with MCP" ]
---

## Intro

In the previous article in this series, we used an MCP server to store and
version frequently used prompts. Building on this, our next step is to
add MCP Tools to perform work on our behalf. Tech news is full
of stories where well-intentioned engineers gave credentials to AI agents,
which then leaked keys or destroyed work. How can we enable our agents while
managing the risk?

## Scenario

I want to track views on my articles in a Google Spreadsheet. I post in
several different places, including blog posts for work. I'd like a unified
view, but I don't like checking different Google Analytics accounts for each
URL. So, I built a tool to manage this.

I built this as an MCP tool and a CLI. However, having the agent update this
data requires giving it write access to my Google Drive and read access to
Google Analytics. Read access is mostly harmless, but I shudder to think what
might happen if my Drive keys were [leaked on moltbook](https://www.moltbook.com/post/a4a5edaa-678b-4865-b99a-8f4e8125d27b).

To manage this risk, I've added Google OAuth support as a subcommand in my
MCP server so the agent never sees the keys. Now I can run `mcp-starter
auth`, go through a quick OAuth flow, and the server writes my access token
to a configuration file. When I run `mcp-starter serve`, the MCP server
reads the token from the config to access Google services.

Next I'll walk you through the code changes.

## Implementation

### CLI Subcommands

First, I added three subcommands to the `mcp-starter` binary: 

* `serve` starts the MCP server.
* `version` prints build information (the `--version` flag previously 
    handled this).
* `auth` starts the OAuth flow.

I implemented these subcommands with [`github.com/urfave/cli/v3`](https://github.com/urfave/cli), but this
could also have been done with Cobra. The first two commands are
straightforward, and I'll discuss the `auth` command in detail below.

I also needed a configuration file, and a simple way to read and write
config. I chose [`github.com/spf14/viper`](https://github.com/spf14/viper) for this, since I don't really
know what else might get added to this config, and I wanted to keep it
flexible.

#### The `auth` command

The body of the auth command is defined in [`auth/auth.go`](https://github.com/muncus/mcp-starter/blob/main/auth/auth.go).

Client application OAuth is complex. I first tried the Out of Band (OOB)
mechanism, but Google disabled it to prevent credential interception.

Instead, I created a local HTTP server. The OAuth service sends the auth
code to this server once authentication completes. The MCP server then
exchanges this code for an access token, which we store in the
configuration.

Now our MCP server can use this access token to talk to Google services (but
only with the OAuth scopes we gave it at authentication time!). OAuth scopes
are pretty coarse, but since these credentials can only be used through our
MCP server, the risk of them being used inappropriately is minor.

---

### MCP as a Trust Boundary

Avoiding access token leaks is a good start, but MCP offers more. This
OAuth strategy separates the user and agent—the agent could even access
resources the user can't!

Beyond separation, the MCP server enforces constraints like human approval
and audit logging. Often, I want to give my agent **read-only** access to
data, but many tools and APIs lack fine-grained access control. When our
MCP server mediates all access, we can prevent write operations or limit
available actions.

Similarly, MCP servers enable centralized audit logging and approval steps.
Since the MCP server routes all access attempts, we can customize validation
and approval as needed.

Human-in-the-loop (HitL) approval would require a side-channel for
communication between the human and the MCP server, but that's certainly
doable.

Audit logging to a remote destination, like a Google Cloud project, will
ensure that an agent's actions are recorded in a central place, for review
after a suspected incident or misbehavior. These logs can provide valuable
information about additional safeguards your MCP server needs to avoid
repeating the incident.

---

## Conclusion & Next Steps

You've seen how an MCP server prevents credential exposure and creates a
defensive security posture. We've briefly covered how MCP servers provide
additional restrictions, logging, and validation to control the risks of
under-supervised agents.

In the next article, I'll detail the content tracking tools that use these
credentials.

You can explore the full code for this service in the [`mcp-starter` github
repo](http://github.com/muncus/mcp-starter), or look at the [PR that adds our
auth functionality](https://github.com/muncus/mcp-starter/pull/1) for a more
focused look.

Got questions? Drop them in the
[discussions](https://github.com/muncus/mcp-starter/discussions) section of
the repo, and I'll get back to you.
