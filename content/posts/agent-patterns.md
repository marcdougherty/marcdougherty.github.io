---
title: AI Agent Patterns
tags: [ AI, thinking, ACoS ]
series: ["Agentic Chief of Staff"]
---

I've seen a lot of different uses of AI Agents in the last year, both in my own
experimentation, and from colleagues. I've been thinking about the usage
patterns I'm noticing lately, and what kinds of patterns might emerge as AI
agent use continues to evolve.

## Generalist

This one happens slowly - you start giving the agent some instructions, and the
tools and skills just keep piling up. Before you know it, you've got a
mega-agent that has skills for everything. This might work fine for many of us,
as long as the skills and workflows don't create conflicts or uncertainty for
the agent.

## Specialists

The Specialists pattern is like the opposite of the Generalist - agents focused
on a single type of task. You might have a dedicated "persona" that writes
documentation, and one that writes code or tests.

This is essentially what Claude and Antigravity do when they create temporary
sub-agents, but in those cases the human has no control over what context is
given to the subagent.

The challenge with this pattern often becomes the coordination overhead. Today,
these agents often end up run in a `screen` or `tmux` session, with the human
doing some guidance and coordination. I'm starting to see multi-agent
orchestrators come up (e.g.
[Scion](https://googlecloudplatform.github.io/scion/overview/)) but most involve
some very particular setup, and I'm not sure the work patterns are mature enough
yet for this to take hold. I do think there's likely some progress to come here
in the future.

## Challenges with these patterns

Agent configuration is highly personalized, and so far the industry has
struggled to find the best way to share agent capabilities. We've been through a
few different methods already (`AGENTS.md`, MCP, Skills), but none have quite
nailed the right granularity of capability sharing. This means that for now,
we're still duplicating a lot of work, and even shared Agent Skills often end up
being customized by each user.

I think there's a lot of value in the personalization of agent behavior - after
all, we each have our own patterns and workflows. Successful collaboration with
an agent (or a human!) requires us to be aware of each other's patterns. The
agent configuration methods available today don't differentiate between the
knowledge needed to perform a task, and the knowledge of the user's preferences.

Orchestration of agents is still a bit awkward. For both of these patterns, its
not uncommon to have multiple sessions, working on different parts of the
codebase in different git worktrees. The human is responsible for directing and
coordinating between the different agents, should their work overlap in any way
(i.e. merge conflicts).

This got me thinking - what might a system look like that separates agent
capabilities from the user's preferences?

## Chief of Staff

I'm exploring the idea of an agent to act as my Chief of Staff - they understand
my personal preferences, and coordinate with other agents on my behalf.

This structure lets me customize one agent with my personal preferences, and let
that agent steer the work of other agents before it gets back to me.

As an example, suppose I have two agents - a CoS and an agent that writes social
media content. The CoS is responsible for ensuring the social media content
accurately reflects my style and voice (and can provide that guidance to the
social media agent in the prompt). This leaves the social media agent only
concerned with the creation of social media posts. Because none of the social
media agent's behaviors are pre-customized for my preferences, this agent can be
reused by others, either by running their own copy of the agent, or as a hosted
service!

{{< mermaid >}}
stateDiagram-v2
  direction LR

  user : User
  cos: Chief of staff agent
  user --> cos

  a1: Social Media agent
  a2: Other Agent

  cos --> a1
  a1 --> cos

  cos --> a2
  a2 --> cos
{{< /mermaid >}}

### Implementing the CoS pattern

First, I want to admit I have not yet successfully build this pattern. But I
have a functional (though rather janky) proof of concept for the non-chief
agents.

While you could run a CoS pattern with only local agents, that is only the first
step -- like using Docker Compose instead of Kubernetes.

I am surprised that nearly all the challenge I've encountered are around
building agents for multi-user deployment (that is, not the CoS itself, but the
sub-agents). Hosted agents seem to be fairly rare, and the tools and patterns
for building them are far less established than the "personal agent" pattern.

Hosted agents face some challenges that local agents do not -- specifically,
user/agent authentication, and safe management of delegated credentials.

My current approach uses the Agent-to-agent protocol (A2A), which provides some
great mental models for inter-agent workflows, but the spec completely sidesteps
authentication, and I've been unable to find good examples of non-trivial
authentication. Agent Identity, for agent-to-agent auth, is more complex than
user auth, because we need to decide how agent identity is established, and how
to transmith that identity securely.

Delegated Credentials are user credentials that we give to an agent system to do
work on a user's behalf. For example, access tokens from a 3-legged OAuth
exchange. Credentials must be stored safely, and should never be provided
directly to the agent, because agents can leak or otherwise misuse auth tokens.
We will need to build a method for tools to safely access delegated credentials
for the authenticated user.

As mentioned above, I have a mostly-functional prototype for this, and I hope to
share more of that soon. Stay tuned for the next article in this series! :tv:


