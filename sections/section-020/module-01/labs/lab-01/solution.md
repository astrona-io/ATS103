# Solution: Pull Docker Hub Images Through A Proxy Cache

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: a healthy Docker Hub endpoint, a public proxy cache project named `dockerhub-proxy` that uses it, and a cached `library/alpine:3.22`.

## Step 1: Define the helpers and sign the CLI in

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
ws harbor login https://harbor.localtest.me:8443 -u admin -p Harbor12345
```

## Step 2: Create and test the Docker Hub endpoint

The provider for Docker Hub is `docker-hub`, and its URL is `https://hub.docker.com`. No credentials are needed for public images:

```sh
ws harbor registry create --name docker-hub --type docker-hub --url https://hub.docker.com
harbor_api GET '/registries?page_size=100' | ws jq '.[] | {id, name, type}'
harbor_api POST /registries/ping --data '{"id":<HUB_ID>}' -o /dev/null -w '%{http_code}\n'
```

Replace `<HUB_ID>` with the endpoint's id from the list. The ping answers `200`: Harbor reaches Docker Hub.

## Step 3: Create the proxy cache project

A project becomes a proxy cache only when it is created with an endpoint:

```sh
ws harbor project create dockerhub-proxy --storage-limit -1 --proxy-cache --registry-id <HUB_ID> --public
harbor_api GET /projects/dockerhub-proxy | ws jq '{name, registry_id, public: .metadata.public}'
```

`registry_id` is the endpoint's id and `public` is `"true"`.

## Step 4: Pull alpine through the cache

`alpine` is an official image, so its path at Docker Hub is `library/alpine`. Pull the whole image through Harbor into a folder in the workstation:

```sh
ws regctl image copy harbor.localtest.me:8443/dockerhub-proxy/library/alpine:3.22 ocidir:///tmp/alpine
```

Harbor fetches the image from Docker Hub, serves it, and stores a copy in the background. After a few seconds the copy is listed:

```sh
harbor_api GET '/projects/dockerhub-proxy/repositories/library%252Falpine/artifacts?with_tag=true' \
  | ws jq '.[] | {digest, tags: [.tags[]?.name]}'
```

The list holds one artifact with the tag `3.22`.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Provider `docker-registry` with the Docker Hub URL | Harbor speaks the wrong API; the connection test or the pulls fail, and the grader requires the provider `docker-hub` |
| A normal project with the name `dockerhub-proxy` | It has no endpoint; pulls of `library/alpine` find nothing |
| Copying `alpine` into Harbor with `regctl` | Harbor refuses pushes to a proxy cache project, and a normal project would not follow Docker Hub |
| `dockerhub-proxy/alpine:3.22` | Docker Hub has no repository `alpine` outside `library` |

## Practice on your own

- Pull `alpine:3.22` again and note how much faster the second pull is.
- Look at the project's retention policy and find the 7-day rule.
