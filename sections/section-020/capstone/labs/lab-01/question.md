# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Remote registries

## Scenario

A colleague started on a Docker Hub cache for the build system and stopped halfway. Harbor has a registry endpoint named `dockerhub` and a project named `dockerhub-proxy`. The build system reads its base images from the ConfigMap `ci-pull-config` in the namespace `workstation`, key `images`, one image per line, and every line still points at `docker.io`.

The build system must keep using exactly the same three images: `alpine:3.22`, `busybox:1.37` and `nginx:1.27-alpine`, all Docker Hub official images.

## Your task

1. Find out why the endpoint and the project cannot work as a Docker Hub cache.
2. Make Harbor cache Docker Hub in a **public** proxy cache project named `hub`.
3. Change `ci-pull-config` so that every image is pulled through `hub` from `harbor.localtest.me:8443`.
4. Leave no registry endpoint in Harbor that cannot be reached.

## Constraints

- The three images and their tags must not change.
- Do not push images into Harbor yourself.
- Keep `ci-pull-config` in the same format: the key `images`, one full image reference per line.

## Done when

- Every registry endpoint in Harbor passes Harbor's connection test.
- `hub` is a public proxy cache project that uses an endpoint with the provider Docker Hub.
- `ci-pull-config` lists `harbor.localtest.me:8443/hub/library/alpine:3.22`, `harbor.localtest.me:8443/hub/library/busybox:1.37` and `harbor.localtest.me:8443/hub/library/nginx:1.27-alpine`, and nothing that points at `docker.io`.
- Every image in `ci-pull-config` can be pulled through Harbor.
