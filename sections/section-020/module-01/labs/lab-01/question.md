# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Remote registries

## Scenario

The build machines pull `alpine:3.22` from Docker Hub dozens of times a day and have started to hit Docker Hub's pull limit. The team wants every base image to come through Harbor instead, starting with `alpine`.

Harbor runs at `https://harbor.localtest.me:8443` and can reach the internet. It has no registry endpoint for Docker Hub and no proxy cache project yet.

## Your task

In Harbor:

1. Create a registry endpoint for Docker Hub, with the provider for Docker Hub, and make sure Harbor can reach it.
2. Create a **public** proxy cache project named `dockerhub-proxy` that uses that endpoint.
3. Pull `alpine:3.22` through `dockerhub-proxy`, so that Harbor keeps a copy of it.

## Constraints

- Do not push any image into `dockerhub-proxy`; Harbor must fetch it from Docker Hub.
- Pull only what the task needs: each pull through the cache counts against Docker Hub's limit.

## Done when

- A registry endpoint with the provider Docker Hub exists, and Harbor's connection test to it succeeds.
- `dockerhub-proxy` is a public proxy cache project that uses that endpoint.
- The project holds the repository `library/alpine` with at least one cached image. Harbor adds the tag `3.22` to the cached index later, so do not wait for the tag.
