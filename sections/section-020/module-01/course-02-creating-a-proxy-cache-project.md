# Creating And Using A Proxy Cache Project

A proxy cache needs two objects in Harbor, in a fixed order: first a registry endpoint for the upstream registry, then a project that uses it. This part creates both for Docker Hub, pulls an official image through the project, and finds the copy Harbor kept.

## The Docker Hub endpoint

A proxy cache project cannot exist without an endpoint, and the endpoint must use the provider of the registry it caches. For Docker Hub, the provider is `docker-hub` and the URL is Docker Hub's web address. Anonymous access needs no credentials; a Docker Hub account in the endpoint raises the pull limit to that account's.

Define the helpers, sign the Harbor CLI in, and create the endpoint:

<!-- astrona:playground:renew -->

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
ws harbor login https://harbor.localtest.me:8443 -u admin -p Harbor12345
ws harbor registry create --name docker-hub --type docker-hub --url https://hub.docker.com
```

Then check that Harbor can reach Docker Hub through the endpoint. Get its id and test it, replacing `<HUB_ID>`:

```sh
harbor_api GET '/registries?page_size=100' | ws jq '.[] | {id, name, type, url}'
harbor_api POST /registries/ping --data '{"id":<HUB_ID>}' -o /dev/null -w '%{http_code}\n'
```

The ping answers `200` when Harbor's `core` component reached Docker Hub. Do not go on until it does; a project built on a broken endpoint serves nothing.

## The proxy cache project

A project is a proxy cache from the moment it is created, or never: Harbor sets the endpoint when it creates the project. Create a public project named `dockerhub-proxy` that caches the `docker-hub` endpoint:

```sh
ws harbor project create dockerhub-proxy --storage-limit -1 --proxy-cache --registry-id <HUB_ID> --public
harbor_api GET /projects/dockerhub-proxy | ws jq '{name, registry_id, metadata}'
```

The project's `registry_id` is the endpoint's id, which is what makes it a proxy cache. `metadata.public` is `"true"`, so any client can pull through it without signing in to Harbor. A private proxy cache project works the same way, but clients must sign in first. `--storage-limit -1` means no storage quota; without it, `harbor project create` opens an interactive form instead of creating the project.

## The pull path

To pull through the cache, put Harbor's address and the project name in front of the image's path at Docker Hub. Docker Hub's **official images**, such as `alpine` and `nginx`, live under the namespace `library` there, even though `docker pull alpine` hides it. Through the cache, that namespace must be written out:

| Image at Docker Hub | Pull path through the cache |
| --- | --- |
| `alpine:3.22` (official) | `harbor.localtest.me:8443/dockerhub-proxy/library/alpine:3.22` |
| `prom/prometheus:v3.5.0` (organisation) | `harbor.localtest.me:8443/dockerhub-proxy/prom/prometheus:v3.5.0` |

Pull `alpine:3.22` through the cache. `regctl image copy` with an `ocidir://` target pulls the whole image, manifest and layers, into a folder in the workstation, which is what a container runtime does on a node:

```sh
ws regctl image copy harbor.localtest.me:8443/dockerhub-proxy/library/alpine:3.22 ocidir:///tmp/alpine
```

The copy succeeds after a few seconds. Harbor fetched the image from Docker Hub, sent it to the workstation, and started keeping a copy.

## Find the copy

The cached image is an ordinary repository in the project, named after its path at Docker Hub:

```sh
ws harbor repo list dockerhub-proxy
harbor_api GET '/projects/dockerhub-proxy/repositories/library%252Falpine/artifacts?with_tag=true' \
  | ws jq '.[] | {digest, tags: [.tags[]?.name]}'
```

The repository list shows `dockerhub-proxy/library/alpine`. The artifact list shows its digest and the tag `3.22`. In the API path, the repository name `library/alpine` is URL-encoded twice, `library%252Falpine`, because it contains a slash. Harbor stores the copy in the background after it serves the pull, so if the list is empty, wait a few seconds and ask again.

You can now put Harbor in front of Docker Hub and prove that an image came through it. What the cache does with that copy over the following days, and what it will not let you do with it, is still open.

## Common pitfalls

> [!WARNING]
> - **Leaving out `library/`.** `dockerhub-proxy/alpine:3.22` asks Docker Hub for a repository named `alpine` outside `library`, which does not exist.
> - **The wrong provider.** An endpoint with the provider `docker-registry` and Docker Hub's address is not a Docker Hub endpoint. Use `docker-hub`.
> - **Trying to turn an existing project into a cache.** A project becomes a proxy cache only when it is created with an endpoint. Create a new project.
> - **Checking the cache straight after the first pull.** Harbor stores the copy after it serves the pull. Wait a moment before you list the artifacts.

## Your mission: Pull Docker Hub Images Through A Proxy Cache

You can now create a Docker Hub endpoint and a proxy cache project, and pull an official image through it. The graded lab gives you Harbor with internet access and asks you to build the cache under fixed names and prove that `alpine:3.22` is in it.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-103-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS103.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-103-lab-020-01
astrona start ats-103-playground-020-01
```
