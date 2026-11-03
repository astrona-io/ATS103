# Preheat Together With Replication

Large setups often have more than one Harbor: a central one that builds push to, and local ones near the clusters. Replication moves artifacts between them, and preheating moves them to the nodes. This part shows how the two fit in order.

## The chain

1. A build pushes a release to the central Harbor.
2. A replication rule copies it to the Harbor near the cluster.
3. A preheat policy on the local Harbor sends it to the local Dragonfly.
4. The rollout starts, and the nodes pull from the local peers.

The order matters. A preheat policy in the central Harbor would prepare Dragonfly in the wrong place. The policy belongs in the Harbor that the cluster pulls from.

## Event timing

An event-based preheat policy fires when an artifact is pushed to its project. A replicated artifact arrives by a push from the replication job, so the policy on the local Harbor fires when replication finishes. Because the preheat follows the replication, the two do not need to be scheduled against each other. A scheduled preheat needs a time that is later than the scheduled replication.

## Check the whole chain

Check each step on its own. The helpers are the ones from the earlier parts. First the replication on the central Harbor:

<!-- astrona:playground:renew -->

```sh
harbor_api GET '/replication/executions?page_size=5' | ws jq '.[] | {id, status, trigger}'
```

Then the preheat executions on the local one:

```sh
harbor_api GET '/projects/inventory/preheat/policies/release-preheat/executions?page_size=5' | ws jq '.[] | {id, status, trigger}'
```

When a release is not preheated, find the first step in the chain that has no execution. The missing execution points to the place to fix.

## Common pitfalls

> [!WARNING]
> - **A preheat policy on the wrong Harbor.** Put it where the cluster pulls from.
> - **A scheduled preheat earlier than the scheduled replication.** It finds nothing to send.
> - **Debugging the last step first.** Start with the first step that has no execution.
