# Building a Write-Only Social Media Agent with Remote MCP
*August 13, 2026*


> [!TIP]
> TL;DR: By pairing an AI agent with Buffer's remote Model Context Protocol (MCP) server (`https://mcp.buffer.com/mcp`), I created a "write-only" workflow that lets me draft, refine, and queue social media posts without ever setting foot in "The Feed."

As a Developer Relations Engineer, I need to maintain an active presence on social media. Social media platforms reward you if you maintain a streak of regular posting (and can bury your content if you don't play their game). But social media also wants you to stick around and scroll through ads and irrelevant content to get to the good stuff.

To avoid getting distracted by the feed, I figured and agent could help by queueing some posts. This would allow me to keep my posts consistent, without having to consume The Feed.

## The Mental Model: Write-Only Social Media

When I do have thoughts to share, I often get distracted by The Feed, which is usually the first thing you see on any social media site. Next thing you know, it's been 15 minutes and I've lost the thought I went there to post :thumbsdown:.

So I set out to create a "write-only" architecture to interact with social media platforms safely:

{{< mermaid >}}
flowchart TB
    A[Thought or Idea] --> B[AI Agent]
    B -->|HTTP SSE/Stream| C[Buffer Remote MCP Server]
    C -->|Creates Draft| D[Buffer Draft Queue]
    D -->|Manual refinement| E[Post Queue]
    E -->|Scheduled release| F[Social Media Sites]
{{< /mermaid >}}

To make this pattern work, I rely on [Buffer](https://buffer.com), which offers several key capabilities for this workflow:

Buffer Free Tier
: Supports up to 3 social channels without a paid subscription.

Post Scheduling
: Automatically queues and publishes drafts on a predefined cadence.

Comment Handling
: Manages follow-ups and replies without requiring full site navigation.

Remote MCP Server
: A hosted HTTP MCP endpoint (`https://mcp.buffer.com/mcp`) that exposes Buffer tools directly to any MCP-compatible client.

## Connecting directly to Buffer's Remote MCP Server

Instead of using MCP's stdio transport, Buffer provides a direct remote HTTP
MCP endpoint. You can generate an API Key under [Buffer Settings >
API](https://publish.buffer.com/settings/api) and configure your MCP client to
connect directly:

```json
{
  "mcpServers": {
    "buffer": {
      "url": "https://mcp.buffer.com/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_API_KEY"
      }
    }
  }
}
```

Once I configured my agent with this remote server and instructed it strictly to create **drafts** (never auto-publish immediately), I could iterate on social media copy directly with my agent.

Then I periodically go through the list of draft posts in Buffer, refine them,
and add a few to the queue. Buffer will then post them on the configured
schedule, and the Buffer app notifies me when my queue is empty so I can publish
a few more drafts!

As a bonus, I spend very little time in the Buffer UI itself (which does try to
constantly upsell me on their own AI features), and more importantly, I spend
less time looking at social media sites.

> [!CAUTION]
> I found that when asking for analysis, the buffer MCP server was providing me
> mock data that was "skinned" to look vaguely like mine. This only seemed to
> happen with the `list_posts` tool. Its not clear to me if this was a temporary
> issue, or a systemic one, so be on the lookout for "plausible but mock" data.

## Standalone Agent

I'm thinking a lot about shared agents as a way to package capabilities, rather than using a more API-centric approach like MCP. So, naturally, I decided to build a standalone agent to handle the details of posting.

With ADK Go, and the auth helpers from my experimental [AgentHost framework](http://github.com/googledevrelexplorations/agenthost), setting up remote MCP tooling is pretty straightforward:

```golang
// import "github.com/GoogleDevRelExplorations/agenthost/auth"
client, err := auth.NewClient("buffer")
if err != nil {
    return nil, fmt.Errorf("failed to get auth client: %v", err)
}
mcpToolset, err := mcptoolset.New(mcptoolset.Config{
    Transport: &mcp.StreamableClientTransport{
        Endpoint:   "https://mcp.buffer.com/mcp",
        HTTPClient: client,
    },
})
agent := llmagent.New(llmagent.Config{
    //other stuff omitted
    Toolsets: []tool.Toolset{
        mcpToolset,
    }
})
```

This agent how has access to all the Buffer MCP tools! :tada:

Buffer's MCP service relies on an `Authorization` header with your API key as
the bearer token. The `auth.NewClient()` call creates a client that will
automatically inject this header in outgoing requests. This can also be done by
manually adding the header to a standard `http.Client` if you prefer.

## What's Next?

As useful as agents are in the **creation** of social media content, I think
they have much more potential as an incoming filter -- surfacing only the posts
that are likely to be interesting to me.

This obviously runs afoul of social media business models, so the "consumer
side" tools are not broadly available. But I think with enough steering, an
agent could navigate a social media site by URLs alone.

I'm still exploring here, but I'm hoping that agents can help us combat some of
the [dark patterns](https://en.wikipedia.org/wiki/Dark_pattern) that certain
types of sites are prone to (particularly news and social media).

Have you experimented with agents on social media? What type of tasks are they
doing for you, or what would you like them to do?

