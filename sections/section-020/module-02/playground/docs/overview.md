# Overview: Operate A Proxy Cache Project (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor with internet access, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`. No registry endpoint and no proxy cache project exist yet.
- The **`workstation`** pod in the namespace `workstation`, with the Harbor CLI `harbor`, the registry client `regctl`, `curl` and `jq`. It trusts Harbor's certificate.
- A plain registry named `mirror` and the project `inventory`; this module does not need them.

Pulls through a proxy cache reach Docker Hub over the internet and count against Docker Hub's limit for anonymous users, about 100 pulls every 6 hours per address at the time of writing. Pull only small images, and only a few.

To open the Harbor web portal, run `kubectl -n harbor port-forward svc/harbor 8443:8443` in a second terminal and open `https://harbor.localtest.me:8443`.

## Helpers

Paste these once in each new terminal. `ws` runs a command in the workstation pod. `wst` does the same with a terminal. `harbor_api` calls Harbor's REST API as the administrator. `pull_through` pulls a whole image through Harbor into a folder in the workstation, the way a node would.

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

- Create the Docker Hub endpoint and a private proxy cache project. Try to pull an image without signing in, and read the error. Then sign in and pull.
- Create a project robot account with pull permission only, sign `regctl` in as the robot, pull, and then try a push.
- Add a second user as a project member with the role Limited Guest and compare what the user can pull.
- Pull `alpine:3.22` and read the artifact's `pull_time`. Pull it again and read `pull_time` again.
- Read the audit log of the project for pull events with `harbor_api GET /projects/<PROJECT>/logs`.
- Set a storage quota of 10 MiB on the project, pull an image larger than that, and read the error.
