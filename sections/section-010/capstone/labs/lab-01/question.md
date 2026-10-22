# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Replication

## Scenario

A colleague set up release replication from Harbor to the mirror before going on holiday. Since then, no release of `inventory/podinfo` has reached the mirror. Last week a release was withdrawn in Harbor, and the operations team says it would still be in the mirror if it had ever arrived there. The endpoint `mirror` and the rule `release-to-mirror` both exist, and nothing in the web portal is red until you look closely.

The mirror registry itself is fine. It answers at `http://mirror.localtest.me:5001` inside the cluster.

## Your task

In Harbor:

1. Find out why releases do not reach the mirror. Look at the endpoint, the rule and the rule's executions.
2. Repair the endpoint `mirror` and the rule `release-to-mirror` so that every new tag of the project `inventory` that starts with `v` reaches the mirror under the same path, for example `inventory/podinfo`, on its own.
3. Make sure that deleting a release in Harbor also removes it from the mirror.

## Constraints

- **Repair the existing endpoint and rule.** Do not delete and recreate them; the grader checks that the rule is the one you started with.
- Only tags that start with `v` may reach the mirror.
- Do not copy tags by hand with `regctl` or another client.

## Done when

- Harbor can reach the endpoint `mirror`, and it points at `http://mirror.localtest.me:5001`.
- The original rule `release-to-mirror` is enabled and event based.
- A new release tag pushed to `inventory/podinfo` appears in the mirror within three minutes, and a tag that does not start with `v` does not.
- Deleting a replicated release in Harbor removes it from the mirror within three minutes.
