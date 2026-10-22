# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Replication

## Scenario

The operations team in a second data centre pulls `podinfo` from its own registry, the mirror. They want every release of `inventory/podinfo` there as soon as it is pushed to Harbor, and nothing else: development builds must stay in Harbor.

Harbor already has a registry endpoint named `mirror` that points at the mirror registry, `http://mirror.localtest.me:5001`. No replication rule exists yet. Release tags start with `v`, for example `v1.0.0`.

## Your task

In Harbor:

1. Create a push-based replication rule named `release-to-mirror` that sends artifacts to the endpoint `mirror`.
2. Make it select only the repositories of the project `inventory`, and only tags that start with `v`.
3. Make the copies arrive in the mirror under the same path they have in Harbor, for example `inventory/podinfo`.
4. Make the rule run on its own whenever a matching artifact is pushed.

## Constraints

- Do not change or delete the endpoint `mirror`.
- Do not copy tags by hand with `regctl` or another client; Harbor must do the copying.
- The rule must be enabled when you finish.

## Done when

- The rule `release-to-mirror` exists, is enabled, is event based and pushes to the endpoint `mirror`.
- A new tag that starts with `v`, pushed to `inventory/podinfo`, appears in the mirror under `inventory/podinfo` within three minutes, without anyone starting the rule.
- A new tag that does not start with `v` never appears in the mirror.
