---
date: 2024-04-09
title: Terraform and GKE Annotations
---

Terraform and Kubernetes are both declarative systems, but there can be
some rough edges when these two systems interact. Kubernetes - specifically
Google Kubernetes Engine (GKE) makes extensive use of annotations to store
additional information about GKE resources.

I encountered this when working on an [article about traffic drains](https://www.marcdougherty.com/2024/architecting-for-traffic-drains/), and
you can see it for yourself on Service objects. By default, GKE clusters
contain several services that show this - for example, you can inspect the
annotations on the built-in `default-http-backend` service:

`kubectl get service -n kube-system default-http-backend -o yaml`

Under `metadata` you'll see a block like this:

```
  annotations:
    cloud.google.com/neg: '{"ingress":true}'
    components.gke.io/component-name: l7-lb-controller-combined
    components.gke.io/component-version: 1.23.5-gke.0
    components.gke.io/layer: addon
```

While not usually an issue for built-in resources, annotations for
Terraform-managed resources can create a couple different types of issue.
Continuous Delivery systems may delete the unexpected annotations, causing the
GKE infrastructure to re-create them, resulting in a lot of busywork for the
automation :robot:.

Another type of annotation-related problem occurs with GKE Autopilot, which
uses annotations to store scaling and load information. Constantly deleting this
information reduces Autopilot's ability to assess your long-term needs, and may
result in suboptimal scaling behavior.

## Part 1: Ignoring annotations / labels

Terraform does have a couple of ways to ignore these troublesome annotations:
one that works per-object and uses the `lifecycle` stanza, and the second works
for all objects managed by the Kubernetes provider. The [Kubernetes provider
docs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#ignore-kubernetes-annotations-and-labels)
cover both solutions, but this article only covers the provider-level approach.

The `ignore_annotations` and `ignore_labels` options allow for the global
ignoring of any annotation or label that matches one of the regular expressions
provided. For example, to ignore all of the GKE Autopilot annotations, you could
declare your provider like this:

```
provider "kubernetes" {
    ignore_annotations = [
        "^autopilot\\.gke\\.io\\/.*",
    ]
}
```

This works great when writing new terraform, and don't have an existing
terraform state file. If you add this to **existing** Terraform, you'll see that
it still reports diffs :facepalm:. This configuration prevents these labels from
being part of the stored terraform state - if you already have offending
annotations in your terraform state, you'll need to continue to part 2.

## Part 2: Selective editing of TF state

If you've already got annotations in your terraform state, you'll need to
"forget" those resources, and re-import them with the ignores in place. This
solution was [initially shared on a TF
issue](https://github.com/hashicorp/terraform-provider-kubernetes/issues/1773#issuecomment-1184198160)
about these ignore options.

Before getting started, make sure you have a backup of your current TF state
file. If anything goes wrong, you can use this backup to recover.

1. Ensure there are no active diffs besides the annotations, with `terraform
   plan`.
1. List known objects from the terraform state: `terraform state list` to find
   the relevant resource names for deletion.
1. Delete each resource from the state file with `terraform state rm
   ${TF_RESOURCE}`
1. Re-import the resource with `terraform import ${TF_RESOURCE} ${K8S_OBJECT}`
1. Finally, re-run `terraform plan` to verify that the resource imported
   correctly and does **not** show diffs for the ignored annotations.

That's it! You've successfully removed those pesky annotations from your
Terraform state file! :tada:

## Recommended ignores

In addition to the autopilot example above, I've also run into problems with a
few other Google-specific annotations. I'll be configuring my GKE Kubernetes
providers with the following set of ignores from now on:

```
    ignore_annotations = [
        "cloud\\.google\\.com\\/neg",
        "cloud\\.google\\.com\\/neg-status",
        "^autopilot\\.gke\\.io\\/.*",
    ]
```

Hopefully this will prevent any poor interactions between GKE and Terraform.
:crossed_fingers:
