---
date: 2024-04-05
title: Architecting for Traffic Drains
---

"Drain" is a term commonly used to describe moving customer traffic away from a
problem. Drains are a [generic
mitigation](https://www.oreilly.com/content/generic-mitigations/), which allows
you to use it even before you understand the cause of the problem!

But to take advantage of drains, your services must be architected to support
them. The details will vary depending on the service, but common requirements
include:

- *Independent* serving locations (multiple zones/regions)
- Any Request may be served from any available region
- A frontend load balancer with adjustable backends


## Example Architecture

There are many ways to achieve a drainable service, and this article will use
the following architecture.

{{< mermaid >}}

flowchart TB
    lb(Global Load Balancer)
    subgraph Cl-A [GKE Cluster A]
        direction TB
        svcA("k8s Service") --> 
        depA("k8s Deployment") -->
        podA("k8s Pod")
    end
    subgraph Cl-B [GKE Cluster B]
        direction TB
        svcB("k8s Service") --> 
        depB("k8s Deployment") -->
        podB("k8s Pod")
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

The provided terraform parses out the relevant information from the Service
objects in both clusters, and populates a single Backend Service using both
Network Endpoint Groups.

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

Now that we have our loadbalancer using the `whereami` service in both clusters,
we can drain one!

Each instance of the service is listed in its own `backend` stanza in the
[Backend Service
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
