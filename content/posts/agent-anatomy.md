---
title: AI Agent anatomy -- my mental model
tags: ["AI", "agents", "thinking"]
publishDate: 2026-06-23
---

AI agents seem to be everywhere these days, but I've found fairly little
discussion about the mental models that help us build agents. This post
discusses the mental model I use to think about agentic systems, and how this
model allows me to think critically about agentic systems.

## Agent Anatomy

The first real definition I heard for an Agent came from [Simon
Willison](https://simonwillison.net/2025/Sep/18/agents/):

> An LLM agent runs tools in a loop to achieve a goal.

More recently, as developers started building more into their own agents, the
term "harness" emerged, generally defined as "anything that's not the LLM".

For myself, I like to think of the harness as a UI, and what I'm calling the
Face.

{{< mermaid >}}
architecture-beta

    group agent(cloud)[Agent]
    group harness(server)[Harness] in agent
    service UI(internet)[UI] in harness
    service face(disk)[Face] in harness
    service model(database)[Model] in agent

    UI:R --> L:face
    face:R --> L:model

{{< /mermaid >}}

### The UI

Whether in a web browser, a terminal, or a standalone application, the User
Interface is the bit you interact with. Certain capabilities of the UI require
that the model know about them (for example, the [Antigravity CLI's "artifact
review" flow](https://antigravity.google/docs/artifacts).) but mostly this is
about how the tools are presented.

The UI is how these tools get integrated into your workflow, and workflow is a
highly personal choice. Decoupling the UI from the rest of the system allows
the system to fit into many different workflows, rather than requiring that
everyone use the same UI in order to make use of the agent.

I'll note that most AI tool producers appear to be deliberately bundling their
UI with their agent functionality today. During these volatile times of
experimentation, this helps try out new ideas, because the UI can innovate
faster when the same company controls both parts. However, as the APIs and
protocols around agents mature, we will likely see less coupling here.

There are a few notable projects that are **only** focused on UI for agents. For
terminal UIs you have [`opencode`](https://opencode.ai/) and
[`crush`](http://github.com/charmbracelet/crush). HuggingFace has a [chat
ui](https://github.com/huggingface/chat-ui) that is model agnostic.

### The Face

This is the term I use to describe the system instructions and tools that an
agent is given. This includes MCP servers and skills that are available to the
agent, and anything else that influences the behavior of the model.

In contrast to the UI, this layer contains a lot of shareable, reusable logic.
Teams facing similar problem spaces often share Agent Skills, MCP servers, or
small CLI utilities to help their agents work more effectively.

There's a lot of experimentation taking place here too - agent skills emerged
from Anthropic's experiments to reduce the context impact of MCP tools. Several
package managers have sprung up to help skills users install and manage their
various skills.

### The Model

The model is the LLM behind these other layers. It is probably the most
commoditized piece of the puzzle, with users often switching between models to
make optimal use of token quotas.

As inference token costs continue to rise, I expect we'll see these large
frontier models replaced with smaller, more specialized models wherever
possible, to reduce costs while minimizing the impact on quality.

The interface of a model is reasonably well standardized, as most use something
like the [OpenAI API](https://developers.openai.com/api/docs), or a similar
model for compatability. In fact, [OpenRouter](https://openrouter.ai/) can put
an OpenAI-compatible API layer on top of a wide variety of models.

### Recap

For now, I'm finding this framing helps me separate my personal preferences
about UI from the building of reusable capabilities for myself and others.

By building small pieces that can fit into any workflow, I hope to encourage
experimentation, and maximize reuse. As the technology landscape shifts, I
believe this mental model can adapt to keep up with advances in agent tools,
and whatever happens with the AI model landscape 😅.

