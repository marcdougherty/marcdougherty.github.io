---
title: Building blocks of a Developer Platform
series: ["Platform Engineering Thoughts"]
---

I have read a lot of articles about Platform Engineering recently, and many of
them talk about platforms as a completely new way for your developers to work.
In fact, many of those articles are trying to sell you their platform!

In this series, I'll be exploring how you can create a platform starting from
the tools and processes that your team is already using.

I'll be writing with a focus on software development teams working in a Cloud
environment, but most of this applies to other environments and teams, though
some interpretation may be necessary.

This article will discuss some of key features of a Platform that I believe are
important, based on my years of experience as a Google SRE, and a contributor
to the [Reliable App Platforms
repository](http://github.com/googlecloudplatform/reliable-app-platforms) (RAP)
which illustrates what a minimum viable platform might look like.

Each of these features has some key benefits that help your organization be
more efficient, and align with the [goals of Platform
Engineering](https://humanitec.com/platform-engineering\#what-platform-engineering-is-used-for).
These features can be implemented in many different ways, so I'll be discussing
them in abstract. Possible implementations are mentioned briefly in each
section.

## Library of reusable components

Modern cloud infrastructure has an absolutely massive number of configuration
options. While these options allow the product to serve a variety of use cases,
it can be overwhelming for each developer team to understand how to achieve
their specific goal.

Creating a library of reusable components allows us to capture successful
patterns and promote their use. These components should model a specific use
case like "global http load balancer" or "replicated sql database".  For
example, we might have a component that models a set of replicated multi-region
databases, given nothing more than a name and a list of regions. This component
creates an abstraction layer that encodes the configuration of a common
pattern, which eases cognitive load for the developer teams and keeps the
organization's database configurations more consistent\!

Reusable components also allow us to adapt to changes in cloud products and/or
organization policy. For example, we may decide that any multi-region database
should also have weekly backups. We can configure the backups once, in the
component definition, and apply it to all the affected databases.

It is important to note some situations where I do not recommend a reusable
component. Some teams have drastically different needs that are not common in
the organization \- for such teams it is unlikely that a component will be
reused and is probably not worth the investment. I also recommend avoiding
components that are too general, and can serve different needs (for example, a
generic "database" component) \- such components often require exposing so much
of the underlying configuration that they do not lower the cognitive load on
developer teams.

**Implementations**
In the RAP repo, we chose Terraform to model our components, and created
components for "global http frontend to kubernetes services" and "CI/CD
pipeline in CloudBuild using Github webhooks". Our applications consume these
components as Terraform modules, so any changes to the components will be
reflected in the next application rollout.

## Service Catalog

RAP's use of Terraform allows applications to pick up changes made to our
reusable components \- but what if there's an urgent change that our Platform
team needs to push out? How would we find all affected services? That's where a
Service Catalog comes in.

A service catalog keeps track of metadata about applications and services in
your organization. This usually includes the location of the source code, and
the teams responsible for the service. It may also include related links, like
an on-call emergency contact, a service health dashboard, or a place to file
bugs about the service.

With a Service Catalog, the platform team can "push" reusable component updates
out to any service that uses that component. The details of discovering which
services are using a component will depend on the implementation of both the
service catalog and the component library.

**Implementations**
For small organizations, their Service Catalog may be searching their Github
Organization, or an internal set of documentation. Larger organizations may opt
for something more automation-friendly like a YAML file. Organizations with
many services may wish to use [Backstage.io](http://Backstage.io), which
provides an API to query their Service Catalog.

## Infrastructure Catalog and Configuration

While a Service Catalog keeps track of services, we need a similar mechanism
for reusable shared infrastructure. This may be part of an organization's
Service Catalog or Component Library, depending on the chosen implementation,
but I feel it is worth its own discussion since the needs are slightly
different.

Many organizations have shared resources that multiple applications rely upon.
Resources like this may include shared Kubernetes clusters, the locations of
critical data, or shared frontend load balancers. This mechanism can also be
used to share the location of secrets that are stored in a secret manager.

Publishing this information in a machine-readable format will help teams adapt
as your organization grows. Perhaps a major database moves to a different
region \- any team that runs a data-intensive workload will likely want to move
as well to avoid an expensive cross-region network bill.

**Implementations**
As noted above, this feature can be implemented as part of the Component
Library or Service Catalog. It could be as simple as a structured data file in
a known location, or as complex as a custom API.

## Recap

These are some features of a platform that can improve the lives of both your
platform team, as well as your app development teams.

- Reusable components guide app developers toward "known good patterns", and
    provide a centralized point of control for organizational best practices
- A Service Catalog ensures that the platform team knows about all their users
and can avoid unexpected surprises when updating platform components.
- An Infrastructure Catalog ensures that shared infrastructure is discoverable,
    and allows the platform team to add/change infrastructure in a way that is
    clear and visible to app teams.

What other platform features do you find valuable, or wish you had?
