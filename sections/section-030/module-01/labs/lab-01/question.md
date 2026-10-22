# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** P2P preheating

## Scenario

The platform team runs Dragonfly next to Harbor so that large rollouts do not overload the registry. Dragonfly is running in the namespace `dragonfly-system`, but Harbor does not know about it, so nothing is ever preheated. The team wants every release of the project `inventory` handed to Dragonfly as soon as it is pushed, and no development builds.

The Dragonfly manager's REST address inside the cluster is `http://dragonfly-manager.dragonfly-system.svc.cluster.local:8080`. It has no token set up for Harbor yet, so Harbor must use no authentication for now.

## Your task

In Harbor:

1. Register Dragonfly as a P2P provider instance named `dragonfly`, with the vendor Dragonfly, pointing at the manager's REST address, with no authentication. It must be enabled, and Harbor must be able to reach it.
2. In the project `inventory`, create a preheat policy named `release-preheat` that uses the instance `dragonfly`.
3. Make the policy select every repository of the project, but only tags that start with `v`.
4. Make the policy run on its own whenever a matching artifact is pushed.

## Constraints

- Do not change anything in the namespace `dragonfly-system`.
- The policy must be enabled when you finish.

## Done when

- The instance `dragonfly` has the vendor Dragonfly, the endpoint above, is enabled, and Harbor's health check of it succeeds.
- The policy `release-preheat` in `inventory` uses `dragonfly`, is enabled and event based, has a repository filter, and selects only the tags `v*`.

Preheat executions do not need to succeed in this environment: the seed peer does not trust Harbor's certificate and no Dragonfly token exists. The grader checks the configuration and the instance's health.
