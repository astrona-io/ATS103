# Cache Docker Hub With A Proxy Cache Project

A cluster with twenty nodes rolls out a new version of an application built on `alpine:3.22`. Every node that has not seen the image pulls it from Docker Hub. Docker Hub counts each of those pulls against a limit, and when the limit is reached, the next pull fails and pods stay in `ImagePullBackOff`.

A **proxy cache project** removes that dependency. It is a Harbor project that refers to one registry endpoint, such as Docker Hub. When a client pulls an image through the project, Harbor fetches it from the endpoint, serves it, and keeps a copy. The next client gets the copy, and Harbor only asks Docker Hub whether the image changed.

Keep one sentence in mind: **clients pull from Harbor, and Harbor pulls from Docker Hub once.** Every command in this module tests where an image really came from.

The module has three parts. **Why Cache A Remote Registry** explains the problem and how the cache decides what to serve. **Creating And Using A Proxy Cache Project** builds a Docker Hub cache and pulls an image through it. A graded lab follows the second part. **Cache Behaviour, Retention And Limits** looks at what the cache does over time: retention, pushes it refuses, and what it can expose.

## Learning objectives

After this module you can:

- Explain the problems a proxy cache solves, and name the registries Harbor can cache.
- Create a Docker Hub registry endpoint and a proxy cache project that uses it.
- Build the pull path through a proxy cache project, with the `library/` prefix for official images.
- Find the cached copy of an image in Harbor.
- Predict what the cache serves when the upstream image is unchanged, changed, deleted or unreachable.
- Read a proxy cache project's default retention policy, and explain why the project refuses pushes.

## Before you start

You need container image basics (repositories, tags, digests, pulls) and Kubernetes basics (`kubectl get`, `kubectl exec`). You do not need to know Harbor's proxy cache yet.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Harbor 2.15.4 | At `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345`. It can reach the internet |
| Project `inventory` | The repository `inventory/podinfo`; not used in this module |
| `workstation` (namespace `workstation`) | A pod with the Harbor CLI `harbor`, the registry client `regctl`, `curl` and `jq`. It trusts Harbor's certificate. Every Harbor command in this module runs here |

Pulls through the cache reach Docker Hub, which needs internet access and counts against Docker Hub's limit for anonymous users. The pages pull only a few small images.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
