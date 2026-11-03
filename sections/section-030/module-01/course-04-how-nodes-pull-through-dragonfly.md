# How Nodes Pull Through Dragonfly

Preheating fills the seed peers, but a rollout is only faster if the nodes then pull through Dragonfly. This part shows what runs on a node, how the container runtime is sent to it, and what a node pull looks like from Harbor's side.

## The peer on each node

On every node, Dragonfly runs a peer called `dfdaemon`. It does three things: it listens on a local address and acts as a registry proxy, it fetches pieces of images from the seed peers and from other peers, and it shares the pieces it holds with the peers that ask. The container runtime does not talk to Harbor directly. It talks to `dfdaemon`, which talks to the rest of the Dragonfly cluster and, for pieces nobody has, to Harbor.

## Sending the runtime to the peer

A node pull goes through Dragonfly only if the container runtime is told to use the proxy. For `containerd`, this is the same mechanism a registry mirror uses: a `hosts.toml` file in the directory of the registry. The file names the local `dfdaemon` proxy as the host for Harbor:

```toml
server = "https://harbor.example.com"

[host."http://127.0.0.1:4001"]
  capabilities = ["pull", "resolve"]
  [host."http://127.0.0.1:4001".header]
    X-Dragonfly-Registry = ["https://harbor.example.com"]
```

The `server` line is the registry the pod names. The `host` line is the local proxy, port `4001` by default, and the header tells the proxy which registry to fetch from. The pod's image name does not change. Dragonfly provides the tool `dfinit` that writes this configuration on a node, so a cluster does not need to maintain the file by hand.

The playground does not set this up, because its single node does not pull through Dragonfly. A pod there pulls from Harbor directly.

## What Harbor sees

When a node pulls through Dragonfly, Harbor sees fewer requests than the number of nodes. If the seed peer holds the image because of a preheat, Harbor sees no layer downloads at all during the rollout; the preheat already paid for them. If the image was not preheated, the first node's request makes a peer fetch the layers from Harbor, and the other nodes receive pieces from that peer.

You can see the Harbor side with the repository's pull count. Pull an image directly and note the count:

<!-- astrona:playground:renew -->

```sh
ws regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
ws regctl image copy harbor.localtest.me:8443/inventory/podinfo:v1.0.0 ocidir:///tmp/podinfo-direct
harbor_api GET /projects/inventory/repositories/podinfo | ws jq '{name, pull_count, artifact_count}'
```

The command prints the repository with its `pull_count`. With the nodes pulling through Dragonfly after a preheat, this number would stay close to the same during a rollout, instead of growing by one per node. That difference is the benefit of the whole setup, and it is the check to run after a rollout.

You can now describe the part after the preheat: what runs on a node, how the runtime reaches it, and what shows that it worked. The next module goes deeper on the policies that feed it.

## Common pitfalls

> [!WARNING]
> - **Preheating without configuring the runtime.** The seed peers hold the image, but the nodes still pull from Harbor.
> - **Writing the proxy host without the registry header.** The proxy does not know which registry to fetch from.
> - **Expecting the playground nodes to use Dragonfly.** They pull from Harbor directly.
