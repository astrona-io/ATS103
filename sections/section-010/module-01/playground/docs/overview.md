# Overview: Replicate Artifacts Between Registries (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor and a second, plain registry, copies an example image into Harbor, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`.
- The project **`inventory`** with the repository `inventory/podinfo` and the tags `6.15.0` and `v1.0.0`.
- The **mirror**: a plain CNCF Distribution registry in the namespace `mirror`, at `http://mirror.localtest.me:5001` inside the cluster. It is empty, and Harbor does not know about it yet. It uses plain HTTP because it is a lab; a real remote registry uses HTTPS.
- The **`workstation`** pod in the namespace `workstation`, with the Harbor CLI `harbor`, the registry client `regctl`, `curl` and `jq`. It trusts Harbor's certificate.

To open the Harbor web portal, run `kubectl -n harbor port-forward svc/harbor 8443:8443` in a second terminal and open `https://harbor.localtest.me:8443`. The browser warns about the lab certificate.

## Helpers

Paste these once in each new terminal. `ws` runs a command in the workstation pod. `harbor_api` calls Harbor's REST API as the administrator. `mirror_tags` lists the tags of a repository in the mirror. `new_tag` pushes a copy of `podinfo:6.15.0` under a new tag with its own digest, so deleting it later does not delete the other tags.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
mirror_tags() {
  ws regctl registry set mirror.localtest.me:5001 --tls disabled
  ws regctl tag ls "mirror.localtest.me:5001/$1"
}
new_tag() {
  ws regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
  ws regctl image mod harbor.localtest.me:8443/inventory/podinfo:6.15.0 \
    --create "$1" --annotation "org.example.build=$1"
}
```

Use them like this: `ws harbor registry list`, `harbor_api GET /replication/adapters`, `mirror_tags inventory/podinfo`, `new_tag v1.1.0`.

## Practice tasks

- Register the mirror with the provider `harbor` instead of `docker-registry`, and test the connection. Read the answer, then fix the provider.
- Write a rule with the tag filter `{6.15.0,v1.0.0}` and predict what it copies before you start it.
- Change the flattening of a rule to no flattening with the destination namespace `inventory`, run it, and list `inventory/inventory/podinfo` in the mirror.
- Make a rule event based with delete replication, push a matching tag with `new_tag`, then delete it in Harbor with `harbor_api DELETE /projects/inventory/repositories/podinfo/artifacts/<TAG>` and watch it disappear from the mirror. Deleting an artifact deletes every tag that points at the same digest, which is why `new_tag` gives each tag its own.
- Stop the mirror with `kubectl -n mirror scale deployment mirror --replicas=0`, push a matching tag, and read the failed task's log. Scale it back to 1 afterwards.
