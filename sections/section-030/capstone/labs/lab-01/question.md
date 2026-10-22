# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** P2P preheating

## Scenario

Every release of `inventory/podinfo` must do two things as soon as it is pushed: reach the mirror registry in the second data centre, and be handed to Dragonfly for preheating. A colleague built the whole pipeline: the endpoint `mirror`, the replication rule `release-to-mirror`, the P2P provider instance `dragonfly` and the preheat policy `release-preheat`. Yet the last release neither reached the mirror nor started a preheat.

The mirror answers at `http://mirror.localtest.me:5001`, and the Dragonfly manager's REST address is `http://dragonfly-manager.dragonfly-system.svc.cluster.local:8080`. Both are working.

## Your task

1. Find out why a release push neither replicates nor preheats. Look at the rule, the instance, the policy and their executions.
2. Repair the rule `release-to-mirror` so that every new release of `inventory` reaches the mirror on its own.
3. Repair the instance `dragonfly` so that it is enabled and Harbor can reach the manager.
4. Repair the policy `release-preheat` so that it runs on push and preheats only release tags.

Release tags start with `v`.

## Constraints

- **Repair the existing rule, instance and policy.** Do not delete and recreate them; the grader checks that they are the ones you started with.
- Do not change anything in the namespaces `mirror` and `dragonfly-system`.
- Do not copy tags by hand into the mirror.

## Done when

- The original rule `release-to-mirror` is enabled and event based, and a new release tag pushed to `inventory/podinfo` appears in the mirror within three minutes.
- The original instance `dragonfly` points at the manager's REST address, is enabled, and Harbor's health check of it succeeds.
- The original policy `release-preheat` uses `dragonfly`, is enabled and event based, and selects only the tags `v*`.

Preheat executions do not need to succeed in this environment; the grader checks the preheat configuration and the instance's health.
