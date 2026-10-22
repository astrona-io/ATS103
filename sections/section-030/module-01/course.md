# Preheat Images Into Dragonfly

A new release of `podinfo` is pushed to Harbor, and a few minutes later it rolls out to every node of a large cluster. Each node starts its pull at the same time, and each one asks Harbor for every layer. Harbor's network link, not the nodes, decides how long the rollout takes.

**Dragonfly** is a P2P distribution engine and a project of the Cloud Native Computing Foundation (CNCF). With Dragonfly, a node fetches image pieces from other nodes that already have them, and only a **seed peer** fetches from the registry. **Preheating** means the seed peers fetch a new image as soon as it exists, before any node needs it. Harbor starts preheating through a **P2P provider instance**, its record of the P2P engine, and a **preheat policy**, a project rule that says which artifacts to preheat and when.

Keep one sentence in mind: **the instance says which engine, the policy says which artifacts and when.** It is the same split as a registry endpoint and a replication rule.

The module has three parts. **P2P Distribution And Dragonfly** explains P2P distribution and preheating, and looks at the Dragonfly parts running in your playground. **Registering Dragonfly As A Provider Instance** adds Dragonfly to Harbor and checks its health. **Preheat Policies, Triggers And Executions** writes a policy that preheats every release on push. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain P2P distribution and preheating, and when they are worth their cost.
- Name the parts of Dragonfly and say which one Harbor sends preheat requests to.
- Register Dragonfly in Harbor as a P2P provider instance, choose its authentication mode, and check its health.
- Write a preheat policy with repository and tag filters, criteria, a trigger and a scope.
- Read a preheat policy's executions, and explain what a Dragonfly personal access token and a trusted seed peer add.

## Before you start

You need container image basics and Kubernetes basics (`kubectl get`, `kubectl logs`, `kubectl exec`). It helps to know what a Harbor project is. You do not need to know Dragonfly.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Harbor 2.15.4 | At `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345` |
| Project `inventory` | The repository `inventory/podinfo` with the tags `6.15.0` and `v1.0.0` |
| Dragonfly 2.5.2 (namespace `dragonfly-system`) | One manager, one scheduler and one seed peer, with MySQL and Redis for the manager. The manager's REST address is `http://dragonfly-manager.dragonfly-system.svc.cluster.local:8080`. No per-node peer runs, because the `kind` node does not pull through Dragonfly in this module |
| `workstation` (namespace `workstation`) | A pod with the Harbor CLI `harbor`, `regctl`, `curl` and `jq`. It trusts Harbor's certificate. Every Harbor command in this module runs here |

This environment is the heaviest of the course. Give your machine about 6 GiB of memory for it, and expect the first start to take up to 15 minutes.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
