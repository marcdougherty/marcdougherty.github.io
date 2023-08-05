---
title: Understanding GCP's Loadbalancer models
---

I recently spent some time with [external application
loadbalancers](https://cloud.google.com/load-balancing/docs/https) in GCP, and I
found the data model pretty difficult to work with. What follows is an attempt
to better explain these concepts, practicing some of the advice from [Docs for
Developers](http://docsfordevelopers.com), which I've been reading.

# Overview

External Application Loadbalancers are represented in the API by a series of
related configuration objects. There is no single "Loadbalancer" object, so it
is important to ensure the relevant objects all reference each other.

Described below are *some* of the objects involved in a Global External
Application Loadbalancer, as I encountered them. The GCP docs describe *many*
other types of LB configuration that may better fit your use case.

- URL Map -
  ([:light_bulb:](https://cloud.google.com/load-balancing/docs/url-map-concepts),
  [:open_book:](https://cloud.google.com/compute/docs/reference/rest/v1/urlMaps))
  : responsible for routing incoming HTTP requests to the correct backend based
  on host and url.
- Backend Service -
  ([:open_book:](https://cloud.google.com/compute/docs/reference/rest/v1/backendServices)):
  tells the loadbalancer how to connect to your backend, but **does not contain
  the list of backends!**
- Network Endpoint Group (NEG)
  ([:open_book:](https://cloud.google.com/load-balancing/docs/negs/): contains
  the list of backends. Note that there are several types, for different types
  of backends (e.g. zonal VMs, serverless, etc)
- Backend Bucket
  ([:open_book:](https://cloud.google.com/compute/docs/reference/rest/v1/backendBuckets)):
  similar to a NEG, but used when serving from a Cloud Storage bucket.

## URL Map

URL Maps map incoming HTTP urls to Backend Services, through  `hostRules`,
`pathMatchers` and `pathRules`. They also contain the default backend service,
to which requests will be send if they do not match any rules (or if no rules
exist).

Host Rules match only on the Hostname of incoming HTTP requests. They control
which Path Matcher the request is sent to next.

Path Matchers contain Path Rules, which map url "globs", to a specific backend
service.

## backend service

Backend services contain a bunch of configuration for how the Load Balancer
should connect to the service that is actually serving the request.

The backend service object contains a list of `backends`. the `group` field of
a backed refers to either a Compute Instance Group (not discussed here), or a
Network Endpoint Group. These references use urls that start with
`https://googleapis.com` - these URLs can be used directly with `gcloud`
commands, so there's no need to parse them for their individual path components.

## network endpoint group (NEG)

Important object with a terrible name :facepalm:

These list your actual backends. There is support for several different types,
from fully-managed Serverless NEGs, to Internet NEGs (which are just host:port
or ip:port endpoints).

The format varies depending on what kind of NEG you need, so be sure to check
the [Backend
docs](https://cloud.google.com/load-balancing/docs/backend-service#backends).

## Backend Bucket

Sort of a special kind of NEG, this serves static content from a Cloud Storage
bucket. The "backend Bucket" object, like the Backend Service, contains
meta-information about how to serve your content, and contains only a link to
the actual gcs bucket (in the `bucketName` field).

# Recap

This probably deserves a diagram:

{{<mermaid>}}
erDiagram
    URL-Map }|--|| Backend_Service : "pathMatcher.defaultService"
    Backend_Service ||--o{ NEGs : "backend[].group"
    NEGs ||--o{ "various backend services" : "points to"
{{</mermaid>}}

I hope this little tour through the jungle of LB products has been helpful. I
hope I find this article again the next time i have to touch one of these!
