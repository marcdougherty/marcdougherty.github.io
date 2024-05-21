---
title: Three flavors of Terraform iteration
tags: [ terraform, platform ]
---

I was writing a Terraform module to create a Google Cloud Load Balancer with an
arbitrary set of GKE services as backends. To achieve this, I needed to learn
about 3 different methods of iteration that are supported in Terraform, when to
use each of them. If you'd like to better understand the many flavors of
iteration available in Terraform, this article can help!


## A bit of background

My goal with this terraform module is to turn a list of
[`kubernetes_service`](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service)
objects into a
[`google_compute_backend_service`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service).
This requires a few intermediate objects, and some json parsing in the
terraform. If you're curious about the outcome of this work, you can check out
the [Reliable App
Platforms](github.com/googlecloudplatform/reliable-app-platforms) github
repository.

While I did _eventually_ find the information I needed in the Terraform docs
(each of which is linked below), I felt there was little comparison between the
different types and when to use each of them, so I put together this brief
introduction.

These three flavors of iteration all have their uses - choosing the right one
depends on the circumstances. I have used all three of these methods, sometimes
in the same piece of Terraform. Let's get started!

## Resources: `for_each`

If you've done much with Terraform before, you've probably encountered the
`for_each` style of iteration. `For_each` is supported by all resources, and is
a useful way to create a resource for each item in a list.

For example, to create `kubernetes_service` data objects from a list of
kubernetes service names, you can do this:

```
data "kubernetes_service" "services" {
  for_each = toset(["one", "two", "three"])
  metadata {
    name = each.value
  }
}

# you can now refer to these services individually:
# data.kubernetes_service.services["three"]
```

This type of iteration is great if you need to turn a list into a set of
resources (for example, make a set of Cloud Storage buckets from a list of
names). The terraform docs cover the [details of
for_each](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each).

If you're **not** creating resources, you should consider one of the other
methods, like a `for` expression.


## Lists: `for` expressions and splat expressions

[For
Expressions](https://developer.hashicorp.com/terraform/language/expressions/for)
are commonly used to filter items from a list, or change the shape of your
data.

For example, suppose you have a list of regional Cloud Storage Buckets like
this:

```
buckets = [
  { name = "bucket1", region = "US-EAST4" },
  { name = "bucket2", region = "EUROPE-WEST3" },
]
```

You would rather have this as a map indexed by region, so your application uses
the closest regional bucket. This can be done like so:

```
buckets_by_region = { for b in buckets: b.region => b }
# buckets_by_region["US-EAST4"].name == "bucket1"
```

Or perhaps you want to select only the buckets located in Europe:

```
european_buckets = [ for b in buckets: b if startswith(b.region, "EUROPE") ]
```

If you want the list of regions in which there is a bucket, you could use a For
expression:

```
regions_with_buckets = [ for b in buckets : b.region ]
```

Or use the alternative syntax for this, which is called a [Splat
Expression](https://developer.hashicorp.com/terraform/language/expressions/splat):

```
regions_with_buckets = buckets[*].region
```

'For' and 'Splat' expressions are great for data manipulation like filtering,
and creating maps from an unordered list. They are also great for getting data
in the right "shape" for one of the other iteration flavors.


## Repeated blocks: `dynamic` blocks

The last type of iteration is useful for tricky scenarios where you need to
repeat an inner block. I came across this with the [`backend`
block](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service#backend)
of a `google_compute_backend_service`. I wanted to produce a section like this:

```
resource "google_compute_backend_service" "my_service" {
  # other fields omitted for brevity
  backend { group = "group1" }
  backend { group = "group2" }
}
```

Because the repeated block here is not the resource itself, we cannot use a
`for_each` to repeat it. To repeat an inner block, we need a new type of
iteration, which Terraform calls [`dynamic`
blocks](https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks).
These are a variant of `for_each`, but instead of creating resources, they
create blocks.

```
resource "google_compute_backend_service" "my_service" {
  dynamic "backend" {
    for_each = ["group1", "group2" ]
    iterator = "thing"
    content {
      group = thing
    }
  }
}
```

The above will create one `backend` block for each item in `var.backends`. The
`iterator` argument can be used to name the temporary object in each iteration.

This method is really helpful when you need to repeat a block **inside** a
resource (rather than the resource itself).

## Bonus: iteration helpers with `terraform_data` objects

While I was doing all this iteration, I tried to use local variables in a
Terraform `locals` block. Unfortunately, local variables do not allow
`for_each` expressions, so I needed another solution.

In the past, I've used
[`null_resource`](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource)
for this, but as of Terraform 1.4, the
[`terraform_data`](https://developer.hashicorp.com/terraform/language/resources/terraform-data)
resource type is preferred.

Because I'm only using this as an iteration-safe `locals` block, I avoided the
use of `triggers_replace`, and just used the `input` argument to hold my
per-loop local variables.

```
resource "terraform_data" "iter-helpers" {
  for_each = var.backends
  input = {
    svc_port = tostring(each.value.service_obj.spec.0.port.0.port)
  }
}
```

To use the `terraform_data` objects, you can reference the `output` attribute:

```
resource "some_resource" "list_of_things" {
  # iterate through our list of helpers
  for_each = terraform_data.iter-helpers
  # and select the svc_port attribute
  port = each.value.output.svc_port
}
```

This gives me a "fake" resource that I can iterate over with any of the above
iteration flavors.

## Conclusion

I hope this quick introduction helped you understand the differences between
`for_each`, for/splat expressions, and dynamic blocks, so you can choose the
right flavor of iteration next time you're working with terraform.

If you're interested in Platform Engineering (sometimes with Terraform), you
can [follow me on Medium](medium.com/@muncus), or check out the [Google Cloud
Community publication](https://medium.com/google-cloud) for a broader range of
topics.

