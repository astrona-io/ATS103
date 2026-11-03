# Proxy Cache With Other Upstream Registries

Docker Hub is the most common upstream, and it is not the only one. A proxy cache project can use any endpoint whose provider Harbor supports for caching. This part covers the other upstreams and the differences that matter.

## Which providers can be cached

Harbor's documentation lists the providers that a proxy cache project can use: Docker Hub, another Harbor, Amazon ECR, Azure ACR, Google GCR, Quay, GitHub GHCR and JFrog Artifactory. Plain registries that use the provider `docker-registry` are not on that list. Check the project creation form: the endpoint list in it shows only the endpoints that can be used.

## Differences that matter

| Upstream | What to remember |
| --- | --- |
| Docker Hub | The `library/` namespace for official images, and the anonymous pull limit |
| Another Harbor | A robot account in the source project is the best credential |
| GHCR, Quay | Names include the owner or organisation |
| Cloud registries | Credentials often expire, so the endpoint needs a plan for renewal |

An upstream credential that expires is the main operating cost of caching a cloud registry. When the credential stops working, cached images still pull, and new ones fail. The symptom matches the one in the troubleshooting part of the second module.

## One cache per upstream

A project has one endpoint, so a team with three upstreams creates three cache projects. A common layout names each project after its upstream, for example `dockerhub`, `ghcr` and `quay`, so the image path tells readers where the image came from: `harbor.example.com/dockerhub/library/alpine:3.22`.

## Look at the projects

List the projects and their endpoints. The helpers are the ones from the earlier parts:

<!-- astrona:playground:renew -->

```sh
harbor_api GET '/projects?page_size=100' | ws jq '.[] | {name, registry_id}'
```

A project with a `registry_id` is a proxy cache, and the id points at the endpoint it uses. A project with no `registry_id` is a normal project.

## Common pitfalls

> [!WARNING]
> - **Choosing a provider that cannot be cached.** The project form will not list the endpoint.
> - **One cache for several upstreams.** A project has exactly one endpoint.
> - **Unmonitored expiring credentials.** The cache works until a new image is needed.
