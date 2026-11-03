# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Replication

## Scenario

A supplier publishes its tools image in a registry that Harbor can reach: the mirror, at `http://mirror.localtest.me:5001`. The repository is `vendor/tools`. The build team wants the supplier's stable releases inside Harbor, in their own project, refreshed every hour. The supplier also publishes `vendor/debug` and a moving tag called `nightly`. Neither of those may enter Harbor.

Harbor already has a registry endpoint named `mirror` that points at the mirror registry, and an empty private project named `vendored`. No replication rule exists yet. Stable release tags of `vendor/tools` start with `1.`, for example `1.0.0`.

## Your task

In Harbor:

1. Create a pull-based replication rule named `pull-vendor-tools` that copies artifacts from the endpoint `mirror` into this Harbor.
2. Make it select only the repository `vendor/tools`, and only tags that start with `1.`.
3. Make the copies arrive in the project `vendored` as `vendored/tools`.
4. Make the rule run on a schedule, every hour on the hour.

## Constraints

- Do not change or delete the endpoint `mirror` or the project `vendored`.
- Do not copy images by hand with `regctl` or another client; Harbor must do the copying.
- The rule must be enabled when you finish.

## Done when

- The rule `pull-vendor-tools` exists, is enabled, is a scheduled pull rule whose source is the endpoint `mirror`, and its schedule is every hour on the hour.
- After the rule is started, `vendored/tools` holds the tags `1.0.0` and `1.1.0` within three minutes, and does not hold the tag `nightly`.
- The repository `vendored/debug` does not exist, and no repository named `vendored/vendor/tools` exists.
