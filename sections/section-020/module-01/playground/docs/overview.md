# Overview: Cache Docker Hub With A Proxy Cache Project (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor with internet access, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`. No registry endpoint and no proxy cache project exist yet.
- The **`workstation`** pod in the namespace `workstation`, with the Harbor CLI `harbor`, the registry client `regctl`, `curl` and `jq`. It trusts Harbor's certificate.
- A plain registry named `mirror` and the project `inventory`; this module does not need them.

Pulls through a proxy cache reach Docker Hub over the internet and count against Docker Hub's limit for anonymous users, about 100 pulls every 6 hours per address at the time of writing. Pull only small images, and only a few.

To open the Harbor web portal, run `kubectl -n harbor port-forward svc/harbor 8443:8443` in a second terminal and open `https://harbor.localtest.me:8443`.

## Helpers

Paste these once in each new terminal. `ws` runs a command in the workstation pod. `wst` does the same with a terminal. The `harbor` CLI (version 0.0.27) draws lists and views as a table only on a terminal, so list and view commands run through `wst`, which adds `-t` (a terminal) to `kubectl exec`. `harbor_api` calls Harbor's REST API as the administrator. `pull_through` pulls a whole image through Harbor into a folder in the workstation, the way a node would.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
wst() { kubectl -n workstation exec -it deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
pull_through() {
  ws regctl image copy "harbor.localtest.me:8443/$1" "ocidir:///tmp/pull-$(date +%s)"
}
```

Use them like this: `wst harbor registry list`, `harbor_api GET /projects`, `pull_through dockerhub-proxy/library/alpine:3.22`.

## Practice tasks

- Create the Docker Hub endpoint with the provider `docker-registry` instead of `docker-hub`, test it, and compare with the right provider.
- Pull `dockerhub-proxy/alpine:3.22` without `library/` and read the error. Then pull it with `library/`.
- Pull `alpine:3.22` twice and compare how long each pull takes.
- Read the default retention policy of the proxy cache project and change it in the web portal to keep the 5 most recently pulled artifacts instead.
- Try to create a normal project first and give it an endpoint afterwards. Note what Harbor allows.
