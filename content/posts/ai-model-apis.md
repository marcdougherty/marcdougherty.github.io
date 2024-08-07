---
title: "AI Model APIs"
date: 2024-08-06
series: ["AI Productionization"]
---

As noted in the previous post about [AI Model Serving layers]({{% ref
"posts/ai-model-serving.md" %}}), your serving layer determines which APIs are
presented, and which client libraries you can use.

In this article, I'll cover the most common AI APIs and where you are likely to
encounter them.

## Common APIs

These APIs are in widespread use for AI model serving. Most AI Model serving
layers will support both of these APIs. Chat-style completions are increasingly
popular, so if you are working with newer models, you should start there.

### OpenAI Chat Completions API

[API Reference](https://platform.openai.com/docs/api-reference/chat)

This is the most common API, and is used by most recent models at the time of
this writing.

This API uses a series of messages to model a chat. There are 3 common roles
in the chat interface.

- **user**: represents the messages sent by the human interacting with the AI
- **ai**: unsurprisingly, this role represents the AI's response
- **system**: context and messages designed to steer the AI toward a particular
    type of response. These are intended for use as grounding and context for
    the later chat messages.

As an example, consider the following set of messages:

```
"messages": [
      {
        "role": "system",
        "content": "You are a helpful assistant who likes frogs."
      },
      {
        "role": "user",
        "content": "tell me a fact about frogs"
      }
    ]
```

This API neatly maps to the way AI is often used in a chat bot, and allows for
multi-turn prompting and user followup.

### OpenAI Completions (Legacy) API

[API Reference](https://platform.openai.com/docs/api-reference/completions/create)

This was OpenAI's initial API, focused on taking a plain text prompt, and
returning a set of possible responses.

This is considered Legacy by OpenAI, though many models may still provide this
API. This API is good for one-shot prompts, but may be unwieldy for longer
prompts or multi-turn prompting.

{{< alert icon="fire" >}}

HuggingFace's Text Generation Inference (TGI) API is not fully compatible with
Completions. Clients may require minor code adjustment when switching between
these two interfaces.

The request body key for [user input with TGI is
`inputs`](https://huggingface.github.io/text-generation-inference/#/Text%20Generation%20Inference/generate),
while [OpenAI's interface uses
`prompt`](https://platform.openai.com/docs/api-reference/completions/create).

{{< /alert >}}

## Related Complications

In addition to the APIs described above, there are a few additional factors to
consider when deciding how to communicate with your model.

### Gemma: Instruction Tuning

[Docs](https://ai.google.dev/gemma/docs/formatting)

Google's Gemma models use a prompting syntax called 'instruction tuning', which
uses angle-bracketed tags to denote the start and end of the "turn". This is a
method to indicate when the user is done and the model should respond. Visually,
it has a similar look to the Chat interface describe above.

This style of prompt looks like this:

```
<start_of_turn>user
tell me facts about turtles.<end_of_turn>
<start_of_turn>model
```

So far, i've only seen this used in Google's Gemma and Gemma2 models, usually
with the explicit "-it" suffix when found on [Huggingface](http://huggingface.co)

Instruction Tuning is an expectation of the underling model, which still
requires a Serving API. Instruction tuning is usually hosted behind a
Completions API surface, where a single large prompt is expected.

### Google Vertex AI

Vertex AI can be used to host your own models, and provides an API that is
consistent with the general "feel" of Google's other APIs.

A Vertex AI-hosted model still requires its own Model Serving Layer, so you can
think of the Vertex AI API as an envelope, encapsulating requests for the
underlying Model Serving API.

In fact, if you look closely at Vertex AI model objects, you can see the details
of how they are passing requests to the Model Serving container underneath:

```
gcloud ai models list --region us-central1 --format json
```

The above command will show the `containerSpec` that describes how to run your
chosen Model Serving Layer, as well as the url paths on that container to use
for health checks (`healthRoute`) and content generation (`predictRoute`).

## Recap and Next Steps

The Chat and Completion APIs are used by the majority of AI model serving tools.
Understanding these APIs will help you choose the right client for talking to
your model.

I'll discuss some available clients and their configuration in the next
installment of this series.
