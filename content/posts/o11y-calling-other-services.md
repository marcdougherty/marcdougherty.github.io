---
title: Day 2 Observability - calls to other services
tags:
    - observability
    - o11y
---

This post assumes you're already familiar with
[OpenTelemetry](http://opentelemetry.io), and are already collecting some
observability data.

Whether you've chosen automatic instrumentation, or manual, you're now
collecting telemetry data from your code. Congratulations :tada:

But what about all the *other* code you're using? When your service makes a
database query, or fetches weather data, you're using someone else's code. These
other services may have their own production problems - can you separate issues
in your code from issues in a dependency with your current observability
signals?

If you're not sure, read on! We'll cover creating metrics and traces around your
existing calls to other services over HTTP or GRPC. The samples below are in Go,
but similar tactics should work in most languages.

Before you start instrumenting these calls yourself, consider searching the
[OTel
Registry](https://opentelemetry.io/ecosystem/registry/) for existing
instrumentation libraries. For example, Postgres database users could adopt the
[`pgotel` library](https://github.com/go-pg/pg/tree/v10/extra/pgotel), which
will auto-magically provide instrumentation for existing `go-pg` code.

## Wrapping HTTP clients

Most of the APIs you're calling are likely HTTP-based. Some of these services
may provide a client library, some users may choose to create their own client
library, and still others will choose to use a simple HTTP client. No matter
which category you're in, this approach can help you get better telemetry
(provided your language supports interfaces or something equivalent).

Let's assume you're using a client library to fetch pictures of cats, called a
`CatClient`. You can create an instrumented version of this library using Go's
[embedding](https://gobyexample.com/struct-embedding).

To begin, we'll define a type for our `OTelCatClient`:

```
type OTelCatClient struct {
    CatClient
}
```

Now we'll need to "wrap" the `CatClient` method calls to include our
instrumentation.  For a method like `CatClient.GetRandomCat`, we can add a trace
span as described in the [OTel guide to Manual
Instrumentation](https://opentelemetry.io/docs/instrumentation/go/manual/):

```
func (c *OTelCatClient) GetRandomCat(c context.Context) Cat {
    ctx, span := c.tracer.Start(c, "get-random-cat")
    defer span.End()
    return c.CatClient.GetRandomCat(ctx)
}
```
The same can be done to add Metrics as desired, to track the number of calls, or
errors.

We can now use `OTelCatClient` the same way we would use a regular `CatClient`,
and the instrumented client will produce a trace span for any calls to
`GetRandomCat`.

If you produce your own client libraries, you can add instrumentation directly
to your libraries with the [OpenTelemetry
API](https://opentelemetry.io/docs/reference/specification/overview/#api). By
default, OpenTelemetry libraries use a no-op implementation which has a minimal
effect on performance and does not record any data. When the [OpenTelemetry
SDK](https://opentelemetry.io/docs/reference/specification/overview/#sdk) is
configured by the consumer of your client libraries, all your beautiful
telemetry will be available, sent to the destination of their choosing.

## GRPC Interceptors

For calls made over GRPC (which includes most of Google's Client Libraries), you
can get telemetry by using one of the GRPC Interceptors provided by the
[`otelgrpc` instrumentation
library](https://pkg.go.dev/go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc).

GRPC Interceptors provide "hooks" in the GRPC handling process, as a way to
implement logging, authorization, and other types of "middleware" tasks. The
Interceptor concept is present in all supported GRPC languages, though I find it
is not well described. This [guide to gRPC and
Interceptors](https://edgehog.blog/a-guide-to-grpc-and-interceptors-265c306d3773)
is a nice summary of the concept.

To make use of the interceptor, it must be plumbed down into the GRPC `Dial()`
call as an option. If you're creating GRPC connections yourself, this is
straightforward. For Google API Clients, it looks a bit like this:

```
import (
  iam "cloud.google.com/go/iam/apiv2"
  "go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"
  "google.golang.org/api/option"
  "google.golang.org/grpc"
)
  policyclient, _ := iam.NewPoliciesClient(r.Context(),
    option.WithGRPCDialOption(
      grpc.WithUnaryInterceptor(
        otelgrpc.UnaryClientInterceptor())))
```

Note that for Streaming APIs, there's also an
`otelgrpc.StreamingClientInterceptor`.

This Policy Client will now record OpenTelemetry spans for each of its GRPC
calls, and report them to whichever backend OTel has been configured to use.
These spans include labels such as the method it called, and what the returned
status code. With this telemetry at your fingertips, it becomes easier to
identify when your dependent services are experiencing latency or instability.

## Recap

We've discussed a few ways to add instrumentation when calling another service
via custom clients, or GRPC.

If you create your own libraries, you can add native instrumentation (so your
*customers* get better telemetry!) using the OTel [guide to Instrumenting
libraries](https://opentelemetry.io/docs/concepts/instrumenting-library/).

Happy Instrumenting! :telescope:
