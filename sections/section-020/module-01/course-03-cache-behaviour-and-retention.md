# Cache Behaviour, Retention And Limits

A cache that works on the first day can surprise you on the thirtieth. Copies expire, an upstream image changes under the same tag, and a project that anyone can pull from may hand out more than you meant. This part looks at the rules a proxy cache project follows over time: its retention policy, the pushes it refuses, and the access it gives.

## Set up the project for this part

The commands below need a Docker Hub endpoint named `docker-hub` and a proxy cache project named `dockerhub-proxy` that uses it, with `alpine:3.22` pulled through it once. If your playground does not have them yet, these commands create them; `harbor registry create` fails harmlessly if the endpoint exists:

<!-- astrona:playground:renew -->

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
printf '%s' 'Harbor12345' | ws harbor login https://harbor.localtest.me:8443 -u admin --password-stdin
ws harbor registry create --name docker-hub --type docker-hub --url https://hub.docker.com
HUB_ID="$(harbor_api GET '/registries?page_size=100' | ws jq -r '.[] | select(.name=="docker-hub") | .id')"
ws harbor project create dockerhub-proxy --storage-limit -1 --proxy-cache --registry-id "$HUB_ID" --public
ws regctl image copy harbor.localtest.me:8443/dockerhub-proxy/library/alpine:3.22 ocidir:///tmp/alpine
```

## Retention: copies do not stay forever

A cache that only grows fills Harbor's storage with images nobody pulls any more. So Harbor gives every new proxy cache project a **tag retention policy** that keeps an artifact only while it is used: by default, artifacts pulled within the last 7 days. A tag retention policy is a project rule that decides which tags to keep and deletes the rest when it runs. Read the project's policy:

```sh
RETENTION_ID="$(harbor_api GET /projects/dockerhub-proxy | ws jq -r '.metadata.retention_id')"
harbor_api GET "/retentions/$RETENTION_ID" | ws jq '{rules, trigger}'
```

The answer holds one rule that keeps artifacts pulled recently, and a schedule for when the policy runs. An image that expires is not lost: the next pull fetches it from Docker Hub again, at the cost of one more counted pull. You can change the rule in the web portal under the project's **Policy** tab, for example to keep the base images you always need.

## Pushes are refused

A proxy cache project mirrors one upstream registry, so Harbor does not let anyone push into it. Try to push `podinfo` from the project `inventory` into the cache:

```sh
ws regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
ws regctl image copy harbor.localtest.me:8443/inventory/podinfo:6.15.0 harbor.localtest.me:8443/dockerhub-proxy/library/podinfo:test
```

The copy fails, even for the administrator, and `regctl` prints the error Harbor returned. Your own images belong in normal projects; the cache only ever holds what the upstream registry serves.

## What the cache serves over time

The cache checks the upstream registry on every pull, not on a timer. When the tag `3.22` of `alpine` moves to a new digest at Docker Hub, the next pull through the cache gets the new digest and Harbor stores it. When Docker Hub cannot be reached, Harbor serves the copy it has. When the image has been deleted at Docker Hub, Harbor serves nothing, even if it still holds a copy.

Pulling by digest instead of by tag makes the result fixed: a digest names one exact artifact, so the cache never has to ask whether it changed. Look at the digest your copy has:

```sh
harbor_api GET '/projects/dockerhub-proxy/repositories/library%252Falpine/artifacts?with_tag=true' \
  | ws jq -r '.[] | .digest'
```

A pull of `harbor.localtest.me:8443/dockerhub-proxy/library/alpine@<DIGEST>` always returns that same image.

## Limits and access

Two settings protect the upstream link. A proxy cache project has a **bandwidth** setting, the speed limit Harbor uses when it pulls from the upstream registry, where `-1` means no limit. And the project's storage quota counts the cached copies like any other artifacts.

Access needs more care. Anyone who can pull from a proxy cache project can make Harbor fetch any image that the endpoint's account can reach upstream. Harbor's documentation warns about exactly this: configure endpoints only within your trust boundary, and give the endpoint's account the fewest rights it needs. A public proxy cache project behind an endpoint signed in with a powerful account would hand that account's private images to everyone.

You now know how a proxy cache behaves after the first pull: copies expire after 7 days without use, pushes are refused, tags follow the upstream while digests stay fixed, and the endpoint's account sets the limit of what the cache can expose.

## Common pitfalls

> [!WARNING]
> - **Expecting a tag to stay the same.** A tag pulled through the cache follows the upstream tag. Pull by digest when the image must not change.
> - **Deleting the retention policy to "keep everything".** The cache then grows without limit. Change the rule to keep what you need instead.
> - **A private upstream account behind a public cache project.** Everyone who can pull from the project can pull what that account can reach.
