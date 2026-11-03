# Overview: Pull-Based Replication And Rule Options (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor and a second, plain registry, fills both with example images, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`.
- The project **`inventory`** with the repository `inventory/podinfo` and the tags `6.15.0` and `v1.0.0`.
- The **mirror**: a plain CNCF Distribution registry in the namespace `mirror`, at `http://mirror.localtest.me:5001` inside the cluster. It holds the repository `vendor/tools` with the tags `1.0.0`, `1.1.0` and `nightly`, and the repository `vendor/debug` with the tag `0.9.0`. Harbor does not know about the mirror yet.
- The **`workstation`** pod in the namespace `workstation`, with the Harbor CLI `harbor`, the registry client `regctl`, `curl` and `jq`. It trusts Harbor's certificate.

To open the Harbor web portal, run `kubectl -n harbor port-forward svc/harbor 8443:8443` in a second terminal and open `https://harbor.localtest.me:8443`.

## Helpers

Paste these once in each new terminal. `ws` runs a command in the workstation pod. `wst` does the same with a terminal, which the `harbor` CLI needs to draw tables. `harbor_api` calls Harbor's REST API as the administrator. `mirror_tags` lists the tags of a repository in the mirror.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
wst() { kubectl -n workstation exec -it deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
mirror_tags() {
  ws regctl registry set mirror.localtest.me:5001 --tls disabled
  ws regctl tag ls "mirror.localtest.me:5001/$1"
}
```

Use them like this: `mirror_tags vendor/tools`, `wst harbor registry list`, `harbor_api GET /replication/policies`.

## Practice tasks

- Register the mirror as an endpoint, create the project `vendored`, and write a pull rule with the name filter `vendor/**`. Predict which repositories arrive, start the rule, and compare.
- Create the same rule with the destination namespace `vendored` and no flattening, and list the repositories it creates.
- Set a bandwidth limit on a rule with `"speed": 512` and read it back.
- Set `"override": false`, push a changed `nightly` to the mirror with `regctl image mod`, run the rule again, and compare the digest in Harbor with the digest in the mirror.
- Change the schedule of a rule to every minute (`0 * * * * *`), watch executions appear, and change it back.
- Stop the mirror with `kubectl -n mirror scale deployment mirror --replicas=0`, start a pull rule, and read the failed task. Scale it back to 1 afterwards.
