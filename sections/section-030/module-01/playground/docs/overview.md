# Overview: Preheat Images Into Dragonfly (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor and a minimal Dragonfly, copies an example image into Harbor, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`.
- The project **`inventory`** with the repository `inventory/podinfo` and the tags `6.15.0` and `v1.0.0`.
- **Dragonfly 2.5.2** in the namespace `dragonfly-system`: one manager, one scheduler and one seed peer, with `mysql` and `redis` for the manager. The manager's REST address is `http://dragonfly-manager.dragonfly-system.svc.cluster.local:8080`. Harbor does not know about it yet.
- The **`workstation`** pod in the namespace `workstation`, with the Harbor CLI `harbor`, `regctl`, `curl` and `jq`. It trusts Harbor's certificate.

The seed peer does not trust Harbor's certificate, and no Dragonfly token is set up for Harbor, so preheat executions here do not complete. Everything Harbor configures can still be built and checked.

To open the Harbor web portal, run `kubectl -n harbor port-forward svc/harbor 8443:8443` in a second terminal and open `https://harbor.localtest.me:8443`.

## Helpers

Paste these once in each new terminal. `ws` runs a command in the workstation pod. `harbor_api` calls Harbor's REST API as the administrator. `manager_health` asks the Dragonfly manager whether it is up.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
manager_health() {
  ws curl -sS -o /dev/null -w '%{http_code}\n' http://dragonfly-manager.dragonfly-system.svc.cluster.local:8080/healthy
}
```

Use them like this: `ws harbor instance list`, `harbor_api GET /p2p/preheat/providers`, `manager_health`.

## Practice tasks

- Register the instance on port `65003`, ping it, and compare with port `8080`.
- Scale the manager to zero with `kubectl -n dragonfly-system scale deployment dragonfly-manager --replicas=0`, ping the instance, and watch its status in the web portal. Scale it back to 1 afterwards.
- Write a policy with the tag filter `**`, push a development tag, and look at the execution it starts. Then change the filter to `v*` and push another development tag.
- Try to delete the instance while a policy uses it, and read Harbor's answer.
- Open the task log of a failed execution in the web portal and find the error Dragonfly returned.
