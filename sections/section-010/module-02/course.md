# Pull Vendor Images Into Harbor

A supplier publishes its tools image, `vendor/tools`, in its own registry. The build team does not want its pipelines to depend on that registry being online, and it wants to decide which releases enter its own Harbor. Harbor can fetch the images on its own: it pulls them from the supplier's registry, keeps them in a project, and repeats the work on a schedule.

This is **pull-based replication**. A pull rule uses a registry endpoint as its source and a project in this Harbor as its destination. Harbor's `jobservice` component runs each pull, just as it runs a push. Pull rules have their own questions: which project receives the copies, what happens when a tag changes at the source, how often the rule should run, and what to do when a run fails.

The module has four parts. **Pull-Based Replication From A Remote Registry** registers a source and writes a first pull rule. **Rule Options: Override, Bandwidth And Resource Types** covers the settings that decide how each copy is made. **Scheduled Triggers And Cron Expressions** makes the rule run by itself on a schedule. **Why Executions Fail And How To Recover** reads a failed run and fixes its cause. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Write a pull-based replication rule and say which side is the source.
- Choose the destination project and flattening level of a pull rule and predict the destination path.
- Explain `override`, bandwidth limits, resource-type filters and label filters.
- Write a Harbor cron expression, with its six fields, for a scheduled rule.
- Start a rule by hand, and say how a manual start differs from a scheduled one.
- Find the cause of a failed execution from its tasks and logs, and recover.

## Before you start

You need container image basics (repositories, tags, digests) and the basics of a Harbor registry endpoint and a replication rule: a registry endpoint is Harbor's record of a remote registry, and a rule copies chosen artifacts on a trigger. You also need `kubectl get`, `kubectl logs` and `kubectl exec`.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Harbor 2.15.4 | At `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345` |
| Project `inventory` | The repository `inventory/podinfo`, with the tags `6.15.0` and `v1.0.0` |
| `mirror` (namespace `mirror`) | A plain CNCF Distribution registry at `http://mirror.localtest.me:5001`. It holds `vendor/tools` (tags `1.0.0`, `1.1.0` and `nightly`) and `vendor/debug` (tag `0.9.0`). Harbor does not know about it yet |
| `workstation` (namespace `workstation`) | A pod with the Harbor CLI `harbor`, the registry client `regctl`, `curl` and `jq`. It trusts Harbor's certificate. Every Harbor command in this module runs here |

The mirror uses plain HTTP because it is a lab. A real remote registry uses HTTPS. Every command runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
