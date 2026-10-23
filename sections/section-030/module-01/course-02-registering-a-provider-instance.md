# Registering Dragonfly As A Provider Instance

Harbor sends preheat requests to an engine only when it knows the engine's address, its kind and how to authenticate. A **P2P provider instance** holds exactly that. This part registers the playground's Dragonfly as an instance, checks that Harbor considers it healthy, and looks at the authentication a real installation adds.

## What an instance holds

A system administrator creates instances under **Administration**, **Distributions** in the web portal. Every project can then use them in its preheat policies. An instance has these fields:

| Field | What it holds |
| --- | --- |
| Provider (vendor) | `dragonfly` or `kraken` |
| Name and description | How policies and people refer to the instance |
| Endpoint | The preheat API address of the engine; for Dragonfly, the manager's REST address |
| Auth mode | `NONE`, `BASIC` (user name and password) or `OAUTH` (a bearer token) |
| Enable | Whether policies can use the instance |
| Skip certificate verification | Whether Harbor checks the engine's TLS certificate |

The provider decides which preheat API Harbor speaks, in the same way a registry endpoint's provider does. The auth mode decides what Harbor sends with each request. Dragonfly's own documentation for Harbor uses `OAUTH` with a Dragonfly **personal access token**, a token created in the Dragonfly console that allows calls to the manager's preheat API.

## Create the instance

The playground's manager has no token configured for Harbor, so register it with the auth mode `NONE`. Define the helpers, sign the Harbor CLI in, and create the instance:

<!-- astrona:playground:renew -->

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
ws harbor login https://harbor.localtest.me:8443 -u admin -p Harbor12345
ws harbor instance create --name dragonfly --provider dragonfly \
  --url http://dragonfly-manager.dragonfly-system.svc.cluster.local:8080 \
  --authmode NONE --insecure --description "Dragonfly in dragonfly-system"
```

The manager uses plain HTTP inside the cluster, so certificate verification does not apply. A real installation puts the manager behind HTTPS.

## Check its health

Harbor reports whether it can reach each instance. Ping it and list the instances:

```sh
ws harbor instance ping dragonfly
ws harbor instance list
```

The ping reports success when Harbor's `core` component reached the Dragonfly manager. The list shows the instance with its vendor, endpoint and whether it is enabled. In the web portal, under **Distributions**, a reachable instance shows the status **Healthy** in a green box.

The REST API shows the same instance with its id, which policies refer to:

```sh
harbor_api GET /p2p/preheat/instances/dragonfly | ws jq '{id, name, vendor, endpoint, auth_mode, enabled}'
```

Note the id. You need it in every preheat policy that uses this instance.

## What a real installation adds

A healthy instance only proves that Harbor reaches the manager. Two more things decide whether a preheat really runs. First, authentication: in Dragonfly's console, an administrator creates a personal access token under **Personal Access Tokens**, and the Harbor instance uses the auth mode `OAUTH` with that token. Second, trust: the seed peers pull the image from Harbor, so they must resolve Harbor's address and trust its certificate. Dragonfly's manager configuration has a setting for Harbor's CA certificate, `job.preheat.tls.caCert`, for a Harbor with a self-signed certificate.

The playground has neither, on purpose: it shows the configuration Harbor needs, and the graded labs check that configuration and the instance's health, not a completed preheat.

You now have Dragonfly registered in Harbor and know it is reachable. The instance preheats nothing by itself; which artifacts to preheat, and when, is decided by a policy.

## Common pitfalls

> [!WARNING]
> - **The manager's gRPC port instead of its REST port.** The manager also listens on port `65003` for its own peers. Harbor needs the REST address on port `8080`.
> - **A disabled instance.** Policies cannot use an instance that is not enabled, even when it is healthy.
> - **Deleting an instance that policies use.** Harbor deletes only instances that no preheat policy refers to. Edit the instance instead.
> - **Taking "Healthy" as proof that preheating works.** Health means Harbor reaches the manager. A preheat also needs a valid token and a seed peer that can pull from Harbor.
