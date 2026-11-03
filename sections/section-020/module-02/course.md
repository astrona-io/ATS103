# Run A Proxy Cache Project For A Team

A proxy cache project in front of Docker Hub works for one person in a playground. A team makes harder demands. Not everyone should be able to use the cache, the build machines need an account that is not a person's, someone must be able to see what the cache holds and who pulled from it, and the cluster nodes must be configured to pull through it. A cache that nobody can operate gets switched off the first time it fails.

This module is about running a proxy cache project after it exists. It treats the cache as a service with users, limits, records and failure modes: who may pull, how the nodes reach it, what Harbor records about it, and how to read its errors.

The module has four parts. **Private Cache Projects And Pull Accounts** makes the cache private and gives the build machines a robot account. **Pointing Kubernetes Nodes At The Cache** shows how containerd and the pull path reach the cache. **Reading The Cache: Artifacts, Quota And Audit Logs** looks at what the cache holds, what it costs and who used it. **Troubleshooting A Proxy Cache** reads the typical errors. A graded lab follows the first part.

## Learning objectives

After this module you can:

- Create a private proxy cache project and explain who can pull from it.
- Create a project robot account that can only pull, and use it with `regctl`.
- Explain how a container runtime is configured to use a registry mirror, and which path it must request.
- Read a cached artifact's size and last pull time, a project's quota and its audit log.
- Recognize the common proxy cache errors and say which part is at fault.

## Before you start

You need the basics of a proxy cache project: it pulls from one registry endpoint on demand and keeps a copy, and nobody can push to it. You also need `kubectl exec` and the basics of Harbor projects and members.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Harbor 2.15.4 | At `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345`. No registry endpoint and no proxy cache project exist yet |
| `workstation` (namespace `workstation`) | A pod with the Harbor CLI `harbor`, the registry client `regctl`, `curl` and `jq`. It trusts Harbor's certificate. Every Harbor command in this module runs here |

The cluster must reach the internet, because Harbor fetches images from Docker Hub. Pulls through the cache count against Docker Hub's limit for anonymous users, so pull only small images, and only a few.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
