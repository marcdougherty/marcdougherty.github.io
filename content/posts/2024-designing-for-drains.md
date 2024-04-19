---
date: 2024-04-05
title: Architecting for Traffic Drains
---

Distributed systems are capable of fast change and adaptation, and highly
tolerant of constrained failures.  This is often achieved by building systems
that can exclude failing components from the larger system, but this capability
is not automatic. Many large systems use load balancers to "route around a
problem" by removing failed components. This process is often called "draining".

Drains are a [generic
mitigation](https://www.oreilly.com/content/generic-mitigations/), which means
you can use them even if you don't understand the cause of the problem (yet)!

But to take advantage of drains, your services must be architected to support
them. The details will vary depending on the service, but common requirements
include:

Serving locations in separate [failure domains](https://en.wikipedia.org/wiki/Failure_domain)
: Often achieved by using multiple zones/regions from your cloud provider, this
  ensures outages in one location do not affect others.

Requests may be served from any available location
: If a whole region is unavailable, the requests may go to a neighboring region.
  Any data needed to serve the request should be present in multiple regions.

A frontend load balancer with configurable backends
: To perform drains, we need to change the available backends in the load
  balancer. Most load balancers support this, but some managed load balancers
  may not allow you to customize the set of backends.


## Example Architecture

There are many ways to achieve a drainable service, and this article will use
the following architecture.

{{< mermaid >}}

flowchart TB
    lb(Global Load Balancer)
    subgraph RegionX ["Region X"]
    subgraph Cl-A ["GKE Cluster A"]
        direction TB
        svcA("k8s Service") --> 
        depA("k8s Deployment") -->
        podA("k8s Pod")
    end
    end
    subgraph RegionY ["Region Y"]
    subgraph Cl-B ["GKE Cluster B"]
        direction TB
        svcB("k8s Service") --> 
        depB("k8s Deployment") -->
        podB("k8s Pod")
    end
    end

    lb --> Cl-A
    lb --> Cl-B

{{< /mermaid >}}

Components:

- Global frontend load balancer
- 2 Regional GKE clusters
- The `whereami` example service from
    [GoogleCloudPlatform/kubernetes-engine-samples](https://github.com/GoogleCloudPlatform/kubernetes-engine-samples/tree/main/quickstarts/whereami)
    - (using google's [publicly available container](http://us-docker.pkg.dev/google-samples/containers/gke/whereami))

This example is modeled in Terraform in the
[drain-demo github repository](http://github.com/muncus/drain-demo) in three
steps. If you're not yet familiar with Terraform, you can take a look at some of
the [gcp terraform
tutorials](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started).

### Prepare your clusters

The first step is to create the 2 regional GKE clusters to host our backend
service. This is done as a separate step to prevent terraform errors when using
the `kubernetes` terraform provider on non-existant clusters.

To create the clusters, run the following commands from the [`00-setup-clusters`
directory](https://github.com/muncus/drain-demo/tree/main/00-setup-clusters):

```
terraform init
terraform apply --var project=${your_project_id}
```

This will create 2 GKE clusters, called `drain-demo-1-a` and `drain-demo-1-b`.
These names are important in subsequent steps.

### Deploy your workload

Next, we deploy our backend service to both clusters. We're using terraform for
this step as well, so these commands will look familiar. This time from the
[01-deploy-workload](https://github.com/muncus/drain-demo/tree/main/01-deploy-workload)
directory:

```
terraform init
terraform apply --var project=${your_project_id}
```

These steps create a kubernetes Deployment of our `whereami` service, as well as
associated Service and Ingress objects.

At this point, we have two separate, independent deployments of our `whereami`
service, one in each cluster.

TODO: identify if we need the ingress objects.

### Create your load balancer

The last piece of the puzzle is to create our load balancer. Load balancers in
Google Cloud are made up of several related objects - the most interesting for
our case is the Backend Service (terraform calls this a
`google_compute_backend_service`).

For this example, we populate the Backend Service with the Network Endpoint
Groups that are automatically created from the kubernetes Service objects. This
information is available as annotations on the kubernetes objects. You can view
these annotations directly with `kubectl get service whereami` - they are
encoded as a json object under the key `cloud.google.com/neg-status`.

The provided terraform [parses out the relevant
information](https://github.com/muncus/drain-demo/blob/main/02-loadbalancer/global-lb.tf#L22-L24)
from the Service objects in both clusters, and populates a single Backend
Service using both Network Endpoint Groups.

To deploy the load balancer, run the following commands from the
[`02-loadbalancer`
directory](https://github.com/muncus/drain-demo/tree/main/02-loadbalancer):

```
terraform init
terraform apply --var project=${your_project_id}
```

We now have a global load balancer pointing to both of our independent
deployments. The loadbalancer address can be found in the terraform output:
`terraform output loadbalancer_url`.

To verify the expected behavior, you can use a web browser to view your
loadbalancer. Repeated requests should show some results serviced from each of
our GKE clusters.

If you have the `curl` and `jq` tools installed, you could also run a command
like the following to show which cluster served each request:

```
while true; do curl --silent ${loadbalancer_url} | jq .cluster_name ; sleep 0.2 ; done
```

## Performing a traffic drain

Our shiny new global load balancer is working great! Until late one night, when
we get paged because the site is serving errors! :warning: :pager:

A quick look at our monitoring dashboards show errors are *only* coming from
Cluster A. We could spend our time investigating exactly what makes Cluster A
different, but with complex distributed systems that can take a lot of
investigation - meanwhile our users are getting errors. To restore service as
quickly as possible, we can drain Cluster A, go back to sleep, and debug in the
morning once we've had coffee :coffee:.

To perform a drain, we'll need to edit the `backend` stanzas in our load
balancer's [Backend Service
object](https://github.com/muncus/drain-demo/blob/main/02-loadbalancer/global-lb.tf#L57-L68)

```
  // NOTE: zero is not a valid max_rate. You must remove the block to drain.
  backend {
    group          = data.google_compute_network_endpoint_group.neg-A.self_link
    balancing_mode = "RATE"
    max_rate_per_endpoint = 100
  }
  backend {
    group                 = data.google_compute_network_endpoint_group.neg-B.self_link
    balancing_mode        = "RATE"
    max_rate_per_endpoint = 100
  }
```

With these stanzas, we can control the balance of traffic between our clusters,
and even drain all traffic by removing (or commenting out) the `backend` stanza
for that cluster.

Try commenting out the first block, and re-applying the loadbalancer terraform.
Once the `terraform apply` has completed, you will see that cluster B is serving
*all* incoming requests! :tada:

## Conclusions

This example illustrated how traffic drains can be used to eliminate the user
impact of a problem, without needing to solve the problem first.

When used in a production incident, drains can quickly eliminate the user-facing
impact of an incident, while preserving the misbehaving service for
further investigation.

This example uses the Network Endpoint Groups (NEGs) that Google Cloud creates
automatically for GKE `Service` objects, to route traffic to the correct
kubernetes pods.

Happy Draining!
