# Preheat Policies In Depth

The first module connected Harbor to Dragonfly and wrote a policy that preheats every release on push. Real teams need more than that. A release batch may land in the evening and be needed in the morning. A policy may preheat too much, or nothing at all, and the execution list is the only place that says why.

A **preheat policy** has four decisions: which artifacts it selects, when it runs, which Dragonfly peers receive the image, and what happens when something fails. This module covers all four, and ends with the troubleshooting steps that separate a Harbor problem from a Dragonfly problem.

Keep one sentence in mind: **a policy chooses artifacts and a moment, and Dragonfly does the work.** Anything that goes wrong after the choice is a Dragonfly problem, and anything before it is a Harbor problem.

The module has four parts. **Triggers And Manual Runs** compares the three triggers and starts a policy by hand. A graded lab follows this part. **Selecting Artifacts, Criteria And Scope** covers filters, the conditions an artifact must meet, and which peers receive the image. **How A Preheat Travels** follows one preheat from Harbor to a seed peer. **Troubleshooting Preheat** lists the failures and how to tell which side caused them.

## Learning objectives

After this module you can:

- Compare the manual, scheduled and event-based triggers, and write a six-field cron schedule.
- Start a policy by hand and find its executions.
- Select artifacts with repository, tag and label filters, and explain the criteria and the scope.
- Describe the path of a preheat from Harbor's job service to a Dragonfly seed peer.
- Find out whether a failed preheat failed in Harbor or in Dragonfly.

## Before you start

You need the module on Dragonfly and provider instances: what the manager, scheduler and seed peer do, and what a preheat policy is. You also need `kubectl` basics.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Harbor 2.15.4 | At `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345` |
| Project `inventory` | The repository `inventory/podinfo` with the tags `6.15.0` and `v1.0.0` |
| Dragonfly 2.5.2 (namespace `dragonfly-system`) | One manager, one scheduler and one seed peer, with MySQL and Redis. The manager's REST address is `http://dragonfly-manager.dragonfly-system.svc.cluster.local:8080`. Harbor does not know about it yet |
| `workstation` (namespace `workstation`) | A pod with the Harbor CLI `harbor`, `regctl`, `curl` and `jq`. It trusts Harbor's certificate. Every Harbor command in this module runs here |

This environment is the heaviest of the course. Give your machine about 6 GiB of memory for it, and expect the first start to take up to 15 minutes.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
