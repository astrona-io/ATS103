# Summary

A proxy cache project puts Harbor between your clients and a public registry. This module built one in front of Docker Hub, pulled through it, and looked at how it behaves over time.

## What you learned

Pulling straight from Docker Hub runs into its pull limit for anonymous users, sends the same layers across the internet again and again, and stops when Docker Hub is unavailable. A proxy cache project solves all three: clients pull from Harbor, and Harbor pulls each image from the upstream registry once and keeps a copy. On every later pull, Harbor serves the copy when the upstream is unchanged or unreachable, fetches again when the upstream changed, and serves nothing when the image was deleted upstream. For Docker Hub, the checks are `HEAD` requests that do not count against the limit.

A proxy cache needs a registry endpoint with the provider of the upstream registry, `docker-hub` for Docker Hub, and a project created with that endpoint. A normal project cannot be turned into a cache later. The pull path is Harbor's address, the project name, and the image's full path at the upstream; Docker Hub's official images need the `library/` namespace written out. The cached image becomes a normal repository in the project, which the CLI and the API list like any other.

Over time, the default retention policy keeps only artifacts pulled within the last 7 days, and an expired image is simply fetched again on its next pull. Nobody can push to a proxy cache project. Tags follow the upstream registry, while a pull by digest always returns the same image. The key facts to remember are these:

- Clients pull from Harbor, and Harbor pulls from the upstream once.
- Write `library/` for Docker Hub's official images.
- One proxy cache project per upstream registry, created with its endpoint.
- Anyone who can pull from the project can reach whatever the endpoint's account can reach upstream.

<!-- astrona:playground:destroy -->
