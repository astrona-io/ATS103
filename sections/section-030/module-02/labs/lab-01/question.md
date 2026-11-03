# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** P2P preheating

## Scenario

The platform team releases a batch of images every evening and wants Dragonfly to hold them before the morning rollout. Dragonfly is already registered in Harbor as the P2P provider instance `dragonfly`. The project `inventory` has no preheat policy yet.

Preheating must not happen on every push. The team wants one run each night at 02:00, and only release tags, which start with `v`. The team also wants to see one run work before the first night, so the policy must be started by hand once.

## Your task

In the project `inventory`:

1. Create a preheat policy named `nightly-preheat` that uses the instance `dragonfly`.
2. Make the policy select every repository of the project, but only tags that start with `v`.
3. Make the policy run on a schedule, every day at 02:00. Harbor's schedule uses six fields, with the seconds first.
4. Keep the policy enabled, and start it by hand once.

## Constraints

- Do not change the instance `dragonfly` and do not change anything in the namespace `dragonfly-system`.
- Do not use the event-based trigger.

## Done when

- The policy `nightly-preheat` in `inventory` uses `dragonfly`, is enabled, and is scheduled with the cron `0 0 2 * * *`.
- The policy selects a repository filter and only the tags `v*`.
- The policy has at least one execution.

Preheat executions do not need to succeed in this environment: the seed peer does not trust Harbor's certificate and no Dragonfly token exists. The grader checks the configuration and that an execution exists.
