# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Remote registries

## Scenario

The build machines of one team pull `alpine:3.22` from Docker Hub and have started to hit its pull limit. The team wants a cache in Harbor that only its own build machines can use. The cache must not be open to everyone, and the build machines must not sign in with a person's account or with the administrator account.

Harbor already has a registry endpoint named `docker-hub` with the provider Docker Hub. No proxy cache project and no robot account exist yet.

## Your task

In Harbor:

1. Create a **private** proxy cache project named `hub-private` that uses the endpoint `docker-hub`.
2. Pull `alpine:3.22` through `hub-private`, so that Harbor keeps a copy of it.
3. Create a project robot account named `puller` in `hub-private` that can only pull repositories in that project.

## Constraints

- Do not push any image into `hub-private`; Harbor must fetch it from Docker Hub.
- Do not change or delete the endpoint `docker-hub`.
- Pull only what the task needs: each pull through the cache counts against Docker Hub's limit.
- The robot account must be enabled when you finish.

## Done when

- `hub-private` is a private proxy cache project that uses the endpoint `docker-hub`.
- The project holds the repository `library/alpine` with at least one cached artifact.
- The project robot account `robot$hub-private+puller` exists, is enabled, and has the permission to pull repositories and no other permission.
