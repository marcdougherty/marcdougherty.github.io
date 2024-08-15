---
title: "AI Client libraries and their eccentricities"
date: 2024-08-15
series: ["AI productionization"]
---

As discussed earlier in this series, there are several factors that affect how
client libraries communicate with your AI Model service.

In this article, I'll be demonstrating using some of the popular client
libraries to connect to models served in 3 different ways, to demonstrate the
usability and flexibility of these client libraries. For this comparison, I'll
be using python since it is the most common choice in LLM user communities.

This is by no means a complete accounting of client libraries, but a quick
overview to get you started on the right path.


{{< alert "wand-magic-sparkles" >}}
TL;DR: I suggest Langchain for maximum flexibility. OpenAI client is a great
choice (though less great if you're hosting the model on Vertex AI as
configuration and debugging are difficult.)
{{< /alert >}}

## Criteria

The library evaluation will focus on the following criteria.

API usability
: a subjective measure of the libraries usablility. Does it provide a good API
: surface? Does it produce useful errors when things go wrong? etc.

Model Flexibility
: Can the library be used to access Models using both the Chat and Completions
: API? Does it work for Instruction-tuned models? How much change is needed
: to use a different model?

## Model services

To evaluate flexibilty, we'll be using 3 different model services:

Gemini 1.5 Flash
: Google's hosted offering.

Gemma 2 on Vertex AI
: Google's Gemma is an Open Model, which can be deployed to their Vertex AI
: platform through the AI Model Garden. This service is deployed on GPUs, and
: served with [Huggingface's TGI](https://huggingface.co/docs/text-generation-inference/en/index).

Gemma 2 on GKE
: Gemma models can also be hosted on Kubernetes. This service is also deployed
: on GPUs, with TGI.

## Libraries

Each of the code snippets below has been validated to work at the time of this
writing - but AI is a rapidly evolving space, so some changes may be necessary.

### OpenAI Client

[OpenAI's Client libraries](https://github.com/openai/openai-python) are
probably the first thought of anyone who's already working with AI client
libraries. They are something of the industry default, since OpenAI's APIs are
widely copied in other AI model serving tools like vLLM and TGI.

For long-running processes, it is necessary to refresh the google credentials
that the OpenAI client uses - it is not done automatically. Use this [sample on
credential
refreshing](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/call-vertex-using-openai-library#refresh_your_credentials) to implement this ability.

#### OpenAI and Gemini

```
import google.auth
import google.auth.transport
import google.auth.transport.requests
from openai import OpenAI
import vertexai

creds, project = google.auth.default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
auth_req = google.auth.transport.requests.Request()
creds.refresh(auth_req)

LOCATION="us-central1"
PROJECT_ID=project
vertexai.init(project=project, location=LOCATION)
client = OpenAI(
    base_url = f'https://{LOCATION}-aiplatform.googleapis.com/v1beta1/projects/{PROJECT_ID}/locations/{LOCATION}/endpoints/openapi',
    api_key = creds.token)

r = client.chat.completions.create(
    model="google/gemini-1.5-flash",
    messages=[{"role": "user", "content": "tell me a frog fact"}],
)
print(r.choices[0].message.content)
```
#### OpenAI and Vertex AI

{{< alert icon="fire" >}}
I was not able to get this working with either OpenAI or cURL with [Google's
OpenAI Client documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/call-vertex-using-openai-library#call_a_self-deployed_model_with_the_chat_completions_api)

I consistenly received 400 errors, with either 'PRECONDITION_FAILED' or
'INVALID_REQUEST'. no other information was available.
{{< /alert >}}

```
    import google.auth
    import google.auth.transport
    import google.auth.transport.requests
    from openai import OpenAI
    import vertexai
    from openai.types.chat import ChatCompletion

    creds, project = google.auth.default()
    auth_req = google.auth.transport.requests.Request()
    creds.refresh(auth_req)

    LOCATION="us-central1"
    PROJECT_ID=project
    ENDPOINT="my-endpoint-number"
    vertexai.init(project=project, location=LOCATION)

    client = OpenAI(
        base_url = f'https://{LOCATION}-aiplatform.googleapis.com/v1beta1/projects/{PROJECT_ID}/locations/{LOCATION}/endpoints/{ENDPOINT}/',
        api_key = creds.token)

    r = client.chat.completions.create(
        model="tgi",
        messages=[{"role": "user", "content": "tell me a frog fact"}],
    )
    print(r)
```

#### OpenAI and GKE

This looks a lot like the Gemini sample, but notably simpler because we are not
doing any authentication and have a simpler base URL.

```
from openai import OpenAI

client = OpenAI(
    base_url = 'http://localhost:8080/v1',
    api_key = "unused")

r = client.chat.completions.create(
    model="unused",
    messages=[{"role": "user", "content": "tell me a frog fact"}],
)
print(r.choices[0].message.content)
```

#### Results

* Usability: :orange_circle:

    The OpenAI client is flexible, and can be used to talk to any
    OpenAI-compatible model server (which is nearly all of them!).

    However, using this library with Google's offerings does not seem like a top
    priority for either party - there are clearly some sharp edges.

* Flexibility: :red_circle:

    This is another case where I want to grade the library and the service
    separately. The client is basically just a well-wrapped HTTP client, and is
    adequately flexible. (especially when enabling debug logs, `httpx` provides
    solid debugging info.)

    Google's Vertex AI service provides terse, generic errors with insufficient
    information to understand what the problem is. I found that there were often
    no server-side log messages to aid my debugging either. :cry:

* Overall: :red_circle:

    I was hoping for better compatability in Google's services, given the
    popularity of the OpenAI APIs in all major model serving tools. The layer of
    Vertex AI appears to be creating more problems than it is solving here.

### Vertex AI

The Vertex AI client library is the Google-published SDK for communicating with
Google's hosted Gemini models, and user-deployed models that are hosted on the
Vertex AI platform.

As discussed in this [prior article about
Gemini](https://medium.com/@muncus/which-gemini-ai-is-right-for-you-b03e625eff0b),
Vertex AI client libraries actually have 2 different pieces - I'll be referring
to them this way:

- `aiplatform`: the `google.cloud.aiplatform` python package. This
    auto-generated library uses a resource-based approach to call the underlying
    API.
- `vertexai`: the `vertexai` python package, which is a handwritten SDK built on
    top of the `aiplatform` package, providing an improved developer experience
    but lacking some features.

#### Vertex and Gemini

This is the flagship case for this library, and the one that `vertexai`
was created for. The code is quite straightforward and requires minimal
configuration.

```
from vertexai.generative_models import GenerativeModel
llm = GenerativeModel("gemini-1.5-flash")
r = llm.generate_content("tell me a fact about frogs")
print(r.text)
```

#### Vertex and Vertex (Vertex Squared)

Here's where things get awkward - the `GenerativeModel` classes that work with
Gemini do not work for user-deployed models in Vertex AI. For these, we'll need
to use the `aiplatform` library.

```
project="MY_PROJECT"
location="us-central1"
# use `gcloud ai endpoints list --region us-central1` to see endpoint ids
endpoint_id="NNNNNNNN"

import google.cloud.aiplatform_v1beta1 as aipb
client = aipb.PredictionServiceClient(client_options={
      'api_endpoint': location + "-aiplatform.googlapis.com" })

endpoint = str.format("projects/{project}/locations/{location}/endpoints/{endpoint}",
        project=project,
        location=location,
        endpoint=endpoint_id)

r = client.predict(
      endpoint=endpoint,
      instances=[{'inputs': prompt}])

print(r.predictions)
```

Certainly not as tidy as the Gemini version, but not too bad once you understand
the use of Endpoint resources, and the PredictionClient.

The `instances` parameter is a bit tricky here, and varies based on how your
model was deployed. The instances key (`'inputs'` above) must be set differently
for models served by Huggingface's TGI vs OpenAI-compatible model serving like
vLLM. TGI uses 'inputs', but OpenAI-compatible servers will use 'prompt'.

This choice is poorly exposed in the Model Garden, so you'll likely need to
inspect the Model (**NOT** the Endpoint, but the model behind it) using `gcloud
ai models describe $DEPLOYED_MODEL_NAME --region $REGION`. The `imageUri` field
in the output is the serving container your model is using.

#### Vertex and GKE

The Vertex AI client libraries are only useful for talking to Models hosted by
Google's Vertex AI service, so they're not usable for models hosted in your own
Kubernetes cluster. :sad:

#### Results

* Usability: :orange_circle:

    `vertexai` deserves a :green_circle:, but the need to *also* understand
    `aiplatform` API surface downgrades this to orange.

* Flexibility: :red_circle:

    Two different APIs for talking to google-hosted vs user-hosted models is
    awkward and would require a full rewrite to switch, or building one's own
    abstraction layer.

* Overall: :red_circle:

    These APIs appear to prioritize google's own models, with little
    consideration for user-hosted use cases. If the `vertexai` experience worked
    for user-hosted models, this would be **much** better.

### Langchain

[Langchain](http://langchain.com) is a framework that lets the same client API
be used to talk to multiple AI models on a collection of platforms. The goal of
langchain is to allow for a similar developer experience across all leading AI
models and platforms.

Finding the correct model class object can be a bit tricky, but once you have
that, the usage of those objects is consistent across the framework (as you'll
see below).

#### Langchain and Gemini

```
from langchain_google_vertexai import ChatVertexAI
llm = ChatVertexAI(model_name="gemini-1.5-flash")
r = llm.invoke("tell me a frog fact")
print(r.content)
```

The above is an example of basic Gemini usage, and is a good place to start.
More flexiblility can be achieved using Prompt templates and chains:

```
from langchain_google_vertexai import ChatVertexAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.messages import HumanMessage, AIMessage
llm = ChatVertexAI(model_name="gemini-1.5-flash")
pt = ChatPromptTemplate.from_messages([
    ("system", "you are a helpful assistant who likes amphibians"),
    ("human", "{input}")
])
chain = pt | llm
r = chain.invoke("tell me a frog fact")
print(r.content)
```

This example shows the use of Chat Prompt Templates to add some system-level
instruction for how the model should behave. The argument passed to `invoke()`
is inserted in the Prompt Template placeholder `{input}` since there is only
one. When using multiple placeholders, `invoke()` requires a mapping.

Prompt templates can also be used to reformat input for Instruction-tuned models
like Gemma.

The use of chains and prompt templates applies to all langchain examples, though
for brevity I will only demonstrate it here.

#### Langchain and Vertex AI

```
llm = VertexAIModelGarden(project=projectid,
                          location = location,
                          endpoint_id=endpointid,
                          prompt_arg="inputs")
r = llm.invoke(prompt)
```

As with other Endpoint usage, the `endpointid` above is the integer identifier
of the endpoint (not the name). IDs can be seen with the `gcloud ai endpoints
list` command.

Chat Prompt template usage is indentical to the previous example.

#### Langchain and GKE

The most challenging part of this was finding the proper LLM class to use for a
"generic" LLM endpoint. Since I'm using TGI to serve my model, and I know that
TGI is OpenAI-compatible, I used the OpenAI module with a custom base URL.

This example uses a localhost URL because I was using kubernetes port forwarding
to access the service. Production use cases should use a different approach
(like cluster-level DNS).

```
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.messages import HumanMessage, AIMessage

llm = ChatOpenAI(
    openai_api_key="unused", # this key is required.
    base_url="http://localhost:8080/v1/"
)
r = llm.invoke("tell me a frog fact")
print(r.content)
```

#### Results

* Usability: :orange_circle:

    The advanced langchain concepts (e.g. Prompt Templates, chains) take some
    significant learning to understand. The errors from prompts and chains can
    be difficult to debug - things like "expected str", but the stacktrace is
    deep in the langchain code, and its not clear how the user would fix it.

* Flexibility: :green_circle:

    Langchain delivers on the goal to keep the query experience pretty uniform
    across models and providers. There are still some bumps in the road around
    the exact shape of arguments to `invoke()`, especially with
    instruction-tuned models, but those are industry-wide issues,
    not specific to langchain.

* Overall: :orange_circle:

    The cryptic error stacktraces are the biggest contributor to an orange
    rating here. The cognitive load of learning about prompt templates and
    output chains are also a factor, though relatively minor.

## Conclusions

As I went through these evaluations, I tried to separate commentary on the model
hosting platform from the client library. Both aspects have an effect on the
developer experience, and evaluating them separately was not always possible.

At this point, I would choose Langchain over other client libraries, as it
provides the most insulation from the rapid change in the underlying
technologies. The next time there is a major shift in AI technology, I would
expect a fairly simple transition as a langchain user - other client
libraries will likely have more work to do.

If I was planning to use providers that were comitted to OpenAI-compatability,
the OpenAI client library would be a solid choice. Google's compatability here
is OK, but the debugging experience is pretty opaque.

I hope this helps you pick the right client library for your AI-calling needs!
