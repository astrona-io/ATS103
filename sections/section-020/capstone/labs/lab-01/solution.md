# Solution: Route Base Image Pulls Through The Cache

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: every endpoint is reachable, `hub` is a public Docker Hub proxy cache, the pull list uses `hub`, and every listed image resolves through Harbor. There are three faults.

## Step 1: Define the helpers and read what exists

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
harbor_api GET '/registries?page_size=100' | ws jq '.[] | {id, name, type, url}'
harbor_api GET /projects/dockerhub-proxy | ws jq '{name, registry_id}'
kubectl -n workstation get configmap ci-pull-config -o jsonpath='{.data.images}{"\n"}'
```

The endpoint `dockerhub` has the provider `docker-registry` and the URL `https://registry.example.invalid`: the wrong provider and an address that does not exist. The project `dockerhub-proxy` has no `registry_id`, so it is a normal project, not a cache. The pull list points at `docker.io`.

## Step 2: Replace the endpoint

An endpoint's provider cannot be changed, so create a new one with the provider `docker-hub` and test it:

```sh
printf '%s' 'Harbor12345' | ws harbor login https://harbor.localtest.me:8443 -u admin --password-stdin
ws harbor registry create --name docker-hub --type docker-hub --url https://hub.docker.com
harbor_api POST /registries/ping --data '{"id":<HUB_ID>}' -o /dev/null -w '%{http_code}\n'
```

The ping answers `200`. Now remove the broken endpoint, replacing `<BROKEN_ID>` with the id of `dockerhub`; no rule or project uses it, so Harbor allows the delete:

```sh
harbor_api DELETE /registries/<BROKEN_ID> -w '%{http_code}\n'
```

## Step 3: Create the proxy cache project hub

A normal project cannot become a cache, so create `hub` with the new endpoint. The old project `dockerhub-proxy` is empty and can be deleted so nobody pulls from it by mistake:

```sh
ws harbor project create hub --proxy-cache --registry-id <HUB_ID> --public
harbor_api DELETE /projects/dockerhub-proxy -w '%{http_code}\n'
```

## Step 4: Move the pull list to the cache

Each image gets Harbor's address, the project `hub` and the `library/` namespace that Docker Hub's official images live under. Save this as `configmap-ci-pull-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ci-pull-config
  namespace: workstation
data:
  images: |-
    harbor.localtest.me:8443/hub/library/alpine:3.22
    harbor.localtest.me:8443/hub/library/busybox:1.37
    harbor.localtest.me:8443/hub/library/nginx:1.27-alpine
```

Apply it:

```sh
kubectl apply -f configmap-ci-pull-config.yaml
```

## Step 5: Prove every image resolves

Ask Harbor for the manifest of each image, which makes it fetch the image from Docker Hub through the cache:

```sh
ws regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
for image in $(kubectl -n workstation get configmap ci-pull-config -o jsonpath='{.data.images}'); do
  ws regctl manifest head "$image" && echo "ok: $image"
done
```

Each line ends with `ok`. A few seconds later, `ws harbor repo list hub` shows the three repositories.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Change only the endpoint's URL to Docker Hub | The provider stays `docker-registry`; Harbor speaks the wrong API to Docker Hub |
| Keep `dockerhub-proxy` and point the list at it | It is a normal project with no endpoint; the images are not there |
| Leave the broken endpoint in place | The grader requires every endpoint to pass the connection test |
| `harbor.localtest.me:8443/hub/alpine:3.22` | Without `library/`, Docker Hub has no such repository |
