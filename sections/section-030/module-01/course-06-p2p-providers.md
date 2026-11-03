# Provider Choices And When Not To Use P2P

This course uses Dragonfly, but Harbor treats it as one provider among others. This part shows how to see the providers your Harbor offers, and gives a way to decide whether a P2P engine is worth running at all.

## See the providers

Harbor lists the P2P providers it supports. Use the helpers from the earlier parts:

<!-- astrona:playground:renew -->

```sh
harbor_api GET /p2p/preheat/providers | ws jq -c '.'
```

The answer lists the provider names and whether they are enabled. Harbor supports Dragonfly and Kraken. The instance's `vendor` field takes one of these names, and the other fields of the instance depend on it.

## Is P2P worth it

P2P pays off in specific situations, and costs something in every case:

| Situation | P2P helps | Reason |
| --- | --- | --- |
| Many nodes pull one large image at once | Yes | Pieces come from peers, not from the registry |
| A few nodes, small images | No | The registry link is not a bottleneck |
| Nodes far from the registry in other sites | Yes | Peers in the same site share pieces |
| A cluster that rarely rolls out | No | The engine runs all the time for rare benefit |

The costs are a manager, schedulers, seed peers with disk, a peer on every node and the work of trusting certificates. A registry in front of a cache, and a faster link, are the alternatives to compare.

## Measure before and after

Use the pull time of a rollout, and the pull count in Harbor, as the measurement. A rollout that takes long because of registry bandwidth is the case P2P solves. A rollout that is slow because the nodes are busy is not.

## Common pitfalls

> [!WARNING]
> - **Adding P2P for a small cluster.** The engine costs more than it saves.
> - **Not measuring.** Without a rollout time before the change, there is nothing to compare.
> - **Assuming every provider has the same fields.** Check the provider's documentation.
