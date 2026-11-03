# How A Preheat Travels

When a policy fires, a request travels through four components before a seed peer holds the image. Knowing the path tells you where to look when a preheat does not finish. This part follows one request from the policy to the seed peer.

## The path

1. **Harbor selects the artifacts.** The policy's filters and criteria decide which artifacts of the project match. Each match becomes a **task** inside one **execution**.
2. **Harbor's job service sends the request.** It calls the Dragonfly manager's REST address, the one stored in the instance, with the image reference and the credentials Dragonfly needs to read the image from Harbor.
3. **The manager passes the job to a scheduler.** The manager keeps the configuration and the job records. The scheduler decides which peer does the work.
4. **A seed peer downloads the image from Harbor.** It reads the manifest and the layers over the registry API, and stores the pieces. Other peers can now fetch those pieces from the seed peer.

Harbor then asks the manager for the state of the job, and the task takes the state Dragonfly reports. An execution is finished when all of its tasks are finished.

## What the states mean

An execution and its tasks move through these states:

| State | Meaning |
| --- | --- |
| Pending | Harbor created the task and has not sent it yet |
| Running | Dragonfly accepted the job and the seed peer is working |
| Success | The seed peer holds the image |
| Failed | Dragonfly or Harbor reported an error |
| Stopped | Someone stopped the execution |

A task that stays `Pending` points at Harbor's job service. A task that moves to `Failed` after a while points at Dragonfly or at the connection between the seed peer and Harbor.

## Read the tasks

List the tasks of an execution. Replace `<EXECUTION_ID>` with the id from the execution list:

<!-- astrona:playground:renew -->

```sh
harbor_api GET /projects/inventory/preheat/policies/nightly-preheat/executions | ws jq '.[] | {id, status, trigger}'
harbor_api GET "/projects/inventory/preheat/policies/nightly-preheat/executions/<EXECUTION_ID>/tasks" | ws jq '.[] | {id, status, image}'
```

Each task names the image and shows its state. The task's log is in the web portal, under the policy's executions. It holds the text Dragonfly returned, which is where the cause of a failure is.

## Why the playground fails

Two things stop a real preheat in this playground, and both are on Dragonfly's side:

- **No token.** Harbor's instance uses no authentication, while a real Dragonfly manager that is exposed to a network should require a personal access token with the auth mode `OAUTH`.
- **An untrusted certificate.** The seed peer downloads from `https://harbor.localtest.me:8443`, and its certificate authority is not in the seed peer's trust store. The download fails with a certificate error.

The first is a manager setting and the second is a seed peer setting. Neither is a Harbor setting, so the same policy would succeed in a cluster that fixes them. Check the seed peer's log to see the certificate error yourself:

```sh
kubectl -n dragonfly-system get pods
kubectl -n dragonfly-system logs <SEED_PEER_POD> --tail=30
```

The first command lists the pods; replace `<SEED_PEER_POD>` with the pod whose name contains `seed-client`.

You can now trace a preheat from the policy to a seed peer, and say which component owns each state. The last part uses that to diagnose failures.

## Common pitfalls

> [!WARNING]
> - **Treating a failed task as a broken policy.** Read the task log first.
> - **Fixing the policy when the seed peer cannot reach Harbor.** The policy only chooses what to send.
> - **Using the gRPC port in the instance.** Harbor calls the REST address on port `8080`.
