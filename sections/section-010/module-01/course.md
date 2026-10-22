# Replicate Artifacts Between Registries

A release of `podinfo` is pushed to Harbor as `inventory/podinfo:v1.0.0`. The operations team in another data centre pulls from its own registry, not from Harbor. Somebody has to get `v1.0.0` there, and the next release, and the one after that.

Harbor can do it. A **registry endpoint** is Harbor's record of another registry: which kind it is, where it is, and how to sign in to it. A **replication rule** is a policy that copies chosen artifacts to that registry, or from it, on a trigger you choose. Harbor's `jobservice` component does the copying in the background and keeps a log of every copy.

Keep one sentence in mind: **the endpoint says where, the rule says what and when, and the execution log says what really happened.** Most replication problems are one of those three, and the module looks at each in turn.

The module has three parts. **Registry Endpoints And Providers** registers the mirror registry in Harbor and tests the connection. **Replication Rules, Filters And Flattening** writes a rule that copies chosen tags, and shows how the filters and the destination path work. **Triggers, Executions And Logs** makes the rule run on every push, and reads what each run did. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Create a registry endpoint with the Harbor CLI and test it.
- Name the main providers Harbor supports and explain what the provider decides.
- Explain push-based and pull-based replication and choose between them.
- Write name and tag filters, and predict which artifacts they select.
- Predict the destination path of a copy from the destination namespace and the flattening level.
- Choose a manual, scheduled or event-based trigger, and turn on delete replication.
- Start a rule, then read its executions, tasks and logs.

## Before you start

You need Kubernetes basics (`kubectl get`, `kubectl logs`, `kubectl exec`) and container image basics: repositories, tags and digests, and what a push and a pull do. You do not need to know Harbor's replication yet.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Harbor 2.15.4 | At `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345` |
| Project `inventory` | The repository `inventory/podinfo`, a small web application image, with the tags `6.15.0` and `v1.0.0` |
| `mirror` (namespace `mirror`) | A plain CNCF Distribution registry at `http://mirror.localtest.me:5001`. It is empty, and Harbor does not know about it yet |
| `workstation` (namespace `workstation`) | A pod with the Harbor CLI `harbor`, the registry client `regctl`, `curl` and `jq`. It trusts Harbor's certificate. Every Harbor command in this module runs here |

The mirror uses plain HTTP because it is a lab. A real remote registry uses HTTPS. Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
