# Prerequisites

Before starting this lab you should be able to:

- Edit registry endpoints, replication rules, P2P provider instances and preheat policies.
- Read replication executions and their logs.
- Explain how replication and preheating fit into one release pipeline.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`.
- The **`workstation`** pod in the namespace `workstation`, with `harbor` (the Harbor CLI v0.0.27), `regctl`, `oras`, `cosign`, `curl` and `jq`. It trusts Harbor's certificate authority. Run every Harbor command there: `kubectl -n workstation exec -it deploy/workstation -- sh`.
- The **mirror** registry, a plain CNCF Distribution registry, at `http://mirror.localtest.me:5001` inside the cluster.
- The project **`inventory`** with the repository `inventory/podinfo` and the tags `6.15.0` and `v1.0.0`.
- A minimal **Dragonfly 2.5.2** in the namespace `dragonfly-system`: one manager, one scheduler and one seed peer, with MySQL and Redis. The manager's REST address inside the cluster is `http://dragonfly-manager.dragonfly-system.svc.cluster.local:8080`.
- The endpoint **`mirror`**, the replication rule **`release-to-mirror`**, the P2P provider instance **`dragonfly`** and the preheat policy **`release-preheat`**, all left behind by an unfinished set-up.

## Working rules

- Everything is graded on the **final state** of Harbor, so check your work at the end and leave it in place.
- Change one thing at a time and check again. A second change made before you check the first makes it impossible to know which one worked.
- Do not change the administrator password, and do not reinstall Harbor.
