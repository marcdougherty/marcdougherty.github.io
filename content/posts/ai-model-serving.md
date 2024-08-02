---
title: AI model serving layers
date: 2024-08-01
series: ["AI productionization"]
---

When it comes to AI, most of the discussion focuses on the model itself, but
there's an important decision that many organizations are overlooking - the
choice of their AI model serving layer.

You can think of the model itself as a big bundle of data - many models are
distributed as a compressed archive of files. To make the model useful, you need
a way to query it - which is where model serving layers come in.

While AI technology is still rapidly evolving, the APIs published by
[OpenAI](https://platform.openai.com/docs/api-reference/introduction) are
becoming broadly used by other model serving layers. Specifically the [OpenAI
completion](https://platform.openai.com/docs/guides/completions) and [chat
completion](https://platform.openai.com/docs/guides/chat-completions) APIs -
with chat completion being the preferred method.

vLLM is a popular serving tookit that provides an OpenAI compatible server built
into its [`vllm serve`
command](https://docs.vllm.ai/en/latest/serving/openai_compatible_server.html),
and as a [Docker
container](https://docs.vllm.ai/en/latest/serving/deploying_with_docker.html).

:hugs: [HuggingFace](http://huggingface.co) offers their [Text Generation
Inference
API](https://huggingface.co/docs/text-generation-inference/main/en/index#) (TGI)
as another competing API, with an open source [API
implementation](https://github.com/huggingface/text-generation-inference) that's
capable of serving most modern models. It supports chat-style interaction
through its [Messages
API](https://huggingface.co/docs/text-generation-inference/main/en/messages_api#messages-api)
for OpenAI-compatible chat completion.

The rest of this article discusses the similarities and differences of vLLM
and TGI. The topics discussed here would apply equally to any AI model serving
layer.

## why is the model serving layer important?

The model serving layer determines how users can interact with your model, like
what kinds of inputs are accepted and how they need to be presented. There are a
bunch of different options for client libraries:

- OpenAI's client libraries work on any OpenAI-compatible model server
- HuggingFace's TGI client (`hugginface-hub`) work for any
TGI-compatible server
- Some hosted models (like Google's Gemini) have their own API and
associated client library
- There are also frameworks like [langchain](langchain.com) that
have support for many different LLM backends.

Because this technology is evolving rapidly, I recommend choosing either the
OpenAI client (which has emerged as industry standard) or one of the multi-API
frameworks like langchain. This choice insulates you from changes in the
underlying APIs, and allow you to move between models (and model hosting
platforms!) with minimal updates to your codebase.

While the client interface aspect may seem straightforward, there are some other
effects that are less apparent.

## Telemetry

Telemetry from the model serving layer determines how much *visibility* you have
into the behavior of your model serving. Common telemetry signals include logs,
monitoring metrics and distributed traces.

Both vLLM and TGI provide metrics and tracing with
[OpenTelemetry](http://opentelemetry.org), which is the industry standard. The
specific metrics and tracing data varies between the two.

I recommend serving the same model with both and exploring available monitoring
and trace data.

Logging is less standardized than metrics and tracing, but usually falls into
the broad categories of "structured" or "unstructured". Structured logs are
commonly JSON objects, which logging backends can parse to make logs highly
searchable. Unstructured logs are treated as plain text, which may be more
difficult to search for specific strings.

When logging from a cloud provider, be mindful of how your hosting platform
interprets your logs.  As an example, Google's Cloud Logging service attempts to
parse structured logs, if they are in the correct format, to set metadata fields
like log level (which it calls 'severity'). Properly parsed log metadata makes
it easier to find errors when your service is misbehaving.


## Operability and tuning

Most model serving layers provide comparable options for use of hardware
GPU/TPUs, quantizers, LoRA adapters, and batching. While exact support for
hardware and model serving may vary slightly between model servers, they are
unlikely to be a factor in your model server choice.

One notable difference is the server-side protection configuration available in
TGI. While most clients allow the user to set query parameters, TGI has the
ability to set **maximums** for many of these parameters, like input tokens, top
N, total input length, etc. These options are described in the [TGI Options
documentation](https://huggingface.co/docs/text-generation-inference/main/en/basic_tutorials/launcher#maxconcurrentrequests)

These options ensure consistent treatment of all clients, and can help avoid a
["noisy neighbor"
problem](https://learn.microsoft.com/en-us/azure/architecture/antipatterns/noisy-neighbor/noisy-neighbor)
when a model service has many clients.

`MAX_CONCURRENT_REQUESTS` is particularly useful, as it allows busy models to
fail requests when overloaded - allowing the client to retry the request on
another instance, rather than waiting a long time for their request to be
processed by a busy instance.

I hope to see similar options appear in other frameworks soon. In the meantime,
I recommend choosing TGI as your model serving layer as it gives maximum control
over how the model service behaves in production.

As an added bonus, TGI also includes a [benchmark
tool](https://github.com/huggingface/text-generation-inference/tree/main/benchmark),
so you can test out various settings before deploying them to production!

## Recap

Model serving is an important consideration, and can have strong effects on how
your model behaves in production, and how well you can inspect the model's
behavior.
