---
title: Multi-cluster load balancing with Google Cloud
series: ["Platform Thoughts"]
tags: ["reliability", "kubernetes", "load balancing"]
---

To build a high-availability service in the cloud, we need to be able to serve from multiple independent failure domains. We can achieve this with multiple kubernetes clusters in different cloud regions, but we'll need a load balancer that can route to all of our clusters.

This article will provide an overview of 3 possible options for load balancing between kubernetes clusters on Google Cloud. Because I'm looking at this through the lens of Platform Engineering, I'll also be discussing the breakdown of responsibilities and controls between a Platform team and an Application team.

## "Plain" Load Balancing

The "plain" load balancing model is the most flexible, since it uses GCP Load Balancing primitives. You can use any of the (many\!) available options on the load balancers, since you are creating them directly.

This strategy is essentially the same as my previous post called "[Architecting for Drains](https://www.marcdougherty.com/2024/architecting-for-traffic-drains/)", where you create a Backend Service from the Network Endpoint Groups (NEGs) that Google Cloud creates for your Service in each of your clusters.

I strongly recommend using an Infrastructure as Code tool like Terraform to manage your load balancers. This is especially helpful in this case, since finding the NEG information manually in the UI is tedious and prone to error.

First, the Kubernetes Services in each cluster must be made publicly available. To achieve this, you create a `Service` and `Ingress` object like this:

```
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: LoadBalancer
  selector:
    app: my-service
  ports:
  - name: web
    port: 8080
    targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-service
 spec:
  defaultService:
    kind: Service
    name: my-service
```

Once these objects are created, Google Cloud will automatically create Regional Load balancers for each service in each cluster. Importantly, a Network Endpoint Group is created for the `Service` object, and the name of this NEG is stored in an annotation called `cloud.google.com/neg-status`. With this information about the NEG, we can now create our own load balancer, using the NEGs from each of our clusters, to form a Global service.

Creating a Public, Global Application Load Balancer creates the following objects:

- A [global forwarding rule](https://cloud.google.com/load-balancing/docs/forwarding-rule-concepts) \- which directs external traffic to a Target Proxy.
- A [Target Proxy](https://cloud.google.com/load-balancing/docs/target-proxies) \- Target Proxies tie forwarding rules to URL Maps. Target Proxies come in different types by protocol: HTTP, HTTPS, GRPC, etc.
- A [URL Map](https://cloud.google.com/load-balancing/docs/url-map-concepts) \- uses various matching rules to direct incoming requests to the appropriate backend service.
- A [Backend Service](https://cloud.google.com/load-balancing/docs/backend-service) \- contains one or more destinations that can serve incoming requests. The Backend Service describes how to connect and balance traffic for each destination (this is where our NEGs come in).
- A [Health Check](https://cloud.google.com/load-balancing/docs/health-check-concepts) \- ensures that each destination in your Backend Service is healthy and capable of serving requests. Destinations that fail health checks will not receive requests.

The [drain-demo repository](http://github.com/muncus/drain-demo) includes an example of working terraform to create this global load balancer. Specifically, [parsing the NEG information out of the annotations is covered here](https://github.com/muncus/drain-demo/blob/main/02-loadbalancer/global-lb.tf\#L17-L29).

As for the division of responsibilities, a Platform team could own the Global load balancing through terraform, while each application team is responsible for creating the relevant `Service` and `Ingress` objects in their cluster.

## Multi-Cluster Ingress

[Multi-Cluster Ingress](https://cloud.google.com/kubernetes-engine/docs/concepts/multi-cluster-ingress) (MCI) is Google's first managed multi-cluster routing product. It uses kubernetes Custom Resource Definitions (CRDs) for configuration. Like Google's other managed multi-cluster solution, MCI requires a GKE Enterprise subscription.

The two relevant CRDs for MCI are [`MultiClusterService`](https://cloud.google.com/kubernetes-engine/docs/how-to/multi-cluster-ingress\#multiclusterservice\_spec) and [`MultiClusterIngress`](https://cloud.google.com/kubernetes-engine/docs/how-to/multi-cluster-ingress\#multiclusteringress\_spec). These resources must be deployed on the GKE-Enterprise config cluster, which acts as the source of truth

`MultiClusterService` uses a label-based selector to find pods in your
clusters:

```
apiVersion: networking.gke.io/v1
kind: MultiClusterService
metadata:
  name: my-service￼
spec:
  template:
    spec:
      selector:
        app: my-app
      ports:
      - name: web
        protocol: TCP
        port: 8080￼
        targetPort: 8080
```

Once you have at least one service defined, you can make a `MultiClusterIngress` to route requests to your service:

```
apiVersion: networking.gke.io/v1
kind: MultiClusterIngress
metadata:
  name: NAME￼
  namespace: NAMESPACE￼
spec:
  template:
    spec:
      backend:
       serviceName: my-service￼
       servicePort: 8080￼
```

This example routes all requests to `my-service`, but `MultiClusterIngress` also supports various rules to route requests based on the Host header or URL path.

Because MCI is the "original" managed multi-cluster service, it supports only the "Legacy" type of Cloud Load Balancer.

As for the division of responsibility, MCI requires changes to kubernetes objects in the GKE-E Config Cluster. Because these objects form a global control plane, any changes to these objects will require involvement from the Platform / Infrastructure team.

## Multi-Cluster Gateway

Multi-Cluster Gateway (MCG) is Google Cloud's implementation of the [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) \-  a vendor-agnostic collection of kubernetes objects that can be used to configure incoming traffic. While the Gateway API (and Google's implementation) can be used to make per-cluster gateways, we'll be focusing on the multi-cluster use case.

The Gateway API consists of the following components:

- `GatewayClass` decides how different classes of Gateway are created and managed. You can think of this as a way to declare which Controller is responsible for each Class of gateway. These are [predefined by Google Cloud](https://cloud.google.com/kubernetes-engine/docs/how-to/gatewayclass-capabilities), so it is just a matter of picking the option that best suits your needs.
- `Gateway` represents the load balancer itself. Routing rules are attached to the Gateway with protocol-specific objects like `HTTPRoute`.

```
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1beta1
metadata:
  name: external-http
  namespace: default
spec:
  gatewayClassName: gke-l7-global-external-managed-mc
  listeners:
  - name: http
    protocol: HTTP
    port: 80
```

- `ServiceExport` objects indicate that the named `Service` object should be made available to other clusters. The GKE Gateway controller will create the corresponding `ServiceImport` objects in all clusters, which are used in `HTTPRoute` objects.

```
kind:ServiceExport
apiVersion: net.gke.io/v1
metadata:
  name: my-service
  namespace: default
```

- `HTTPRoute` objects contain rules for directing HTTP traffic to a backend service. In our multi-cluster routing setup, these will be `ServiceImport` references, to indicate that this service is present in multiple clusters.

```
kind: HTTPRoute
apiVersion: gateway.networking.k8s.io/v1beta1
metadata:
  name: example-route
  namespace: default
  spec:
  parentRefs:
  - kind: Gateway
    namespace: default
    name: external-http
  hostnames:
  - "example.com"
  rules:
  - backendRefs:
    - group: net.gke.io
      kind: ServiceImport
      name: my-service
      port: 8080
```

The Google Cloud tutorial for a [Multi-cluster, multi-region external gateway](https://cloud.google.com/kubernetes-engine/docs/how-to/deploying-multi-cluster-gateways\#external-gateway) provides sample objects of all of these types, and is a good illustration of how to use them.

The Kubernetes Gateway group considered the separation of responsibility as a core part of their API, and it shows. One way to split this would be to have a Platform team that owns all `Gateway` and `HTTPRoute` objects, while application teams are responsible for their `ServiceExport` objects.
The API is flexible enough to allow for some application teams to own their own `HTTPRoute`s, or even their own `Gateway`s as desired.

## Conclusions

Multi-cluster load balancing is a complex topic, and we've barely scratched the surface with an overview of 3 approaches.

- "Plain" load balancing (perhaps better called "composite load balancing"?) reuses per-cluster Network Endpoint Groups in the creation of a global load balancer. It provides flexibility but requires considerable management to set up.
- Multi-cluster Ingress, which is specific to Google Cloud, and has poor support for advanced load balancing features.
- Multi-cluster Gateway, which is an implementation of a Kubernetes API, and supports most available load balancing features.

If you need an even greater degree of control over your traffic, you may also want to consider using a [Service Mesh](https://cloud.google.com/products/service-mesh?hl=en). Service Mesh provides a great deal more than just load balancing, but for environments that want a more robust set of controls on inter-service communication, it may be the right choice.
