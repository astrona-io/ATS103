# Troubleshooting A Proxy Cache

A proxy cache has more places to fail than a normal registry, because three parties are involved: the client, Harbor and the upstream registry. A good diagnosis starts by finding out which party answered the error. This part lists the errors a proxy cache gives, shows how to reproduce the common ones, and says what to check for each.

## Which party answered

Look at the status code and the text of the error. A client error means the request was refused before Harbor fetched anything, and an upstream error means Harbor reached out and the upstream refused or failed. These are the usual errors:

| What you see | Who answered | Usual cause |
| --- | --- | --- |
| `401` or `denied` on a private project | Harbor | No credentials, or credentials without pull permission in the project |
| `404` or `name unknown` | Harbor | The path is wrong, for example `alpine` without `library/` |
| `unauthorized` from the first request for a new image | Upstream, through Harbor | The endpoint's credentials are wrong, expired or cannot see the image |
| `toomanyrequests` | Upstream, through Harbor | Docker Hub's pull limit was reached |
| A failure when the endpoint is unreachable and nothing is cached | Harbor | The upstream is down or the cluster has no route to the internet |
| A refused push | Harbor | Nobody can push to a proxy cache project |
| Storage quota error | Harbor | The project's quota is full |

## Reproduce the path mistakes

The commands use the helpers from the earlier parts. Pull `alpine:3.22` without `library/`, and read what Harbor returns:

<!-- astrona:playground:renew -->

```sh
ws regctl image copy harbor.localtest.me:8443/team-cache/alpine:3.22 ocidir:///tmp/alpine-no-library
```

The pull fails. Harbor asked Docker Hub for `alpine` in the namespace `team-cache`'s upstream user path, which does not exist, so the error comes from the upstream. Now use the correct path:

```sh
ws regctl image copy harbor.localtest.me:8443/team-cache/library/alpine:3.22 ocidir:///tmp/alpine-with-library
```

The pull works. The difference is only the path. The first thing to check for a `404` is the path, in particular `library/`.

## Check the endpoint

When the first pull of a new image fails but images that were already cached still work, test the endpoint. `POST /registries/ping` answers `200` when Harbor reaches the registry with the credentials stored in the endpoint:

```sh
HUB_ID="$(harbor_api GET '/registries?page_size=100' | ws jq -r '.[] | select(.name=="docker-hub") | .id')"
harbor_api POST /registries/ping --data "{\"id\":$HUB_ID}" -o /dev/null -w '%{http_code}\n'
```

A `200` means the endpoint is healthy. Any other status points to the endpoint: the URL, the provider, the credential or the network. The endpoint list also shows a health status for each endpoint:

```sh
harbor_api GET '/registries?page_size=100' | ws jq '.[] | {name, status}'
```

Harbor re-checks the health of endpoints in the background, so the status can lag behind a recent fix.

## Reading the logs

Harbor's `core` component handles the pull and writes the error. When the pull fails for a reason you cannot see in the client message, read the log of `core` around the time of the failure:

```sh
kubectl -n harbor logs deploy/harbor-core --tail=30
```

The lines name the request, the project and the upstream response. A proxy cache error that mentions the remote registry shows that Harbor reached out. An error that stops at the project means the request was refused inside Harbor.

## A checklist

When a pull through the cache fails, work through these questions in order. First, which status and text did the client get? Second, is the path right, with `library/` for official images? Third, is the project private, and do the credentials have pull permission? Fourth, does the endpoint answer the ping? Fifth, is the upstream limit reached, or the quota full? Sixth, what does the log of `core` say? Most failures end at the second or third question.

You can now trace a failed pull to the client, Harbor or the upstream, and reproduce the most common mistakes in a playground. That is the working knowledge needed to keep a team cache running.

## Common pitfalls

> [!WARNING]
> - **Blaming Docker Hub for a path error.** Check `library/` before anything else.
> - **Fixing the project when the endpoint is broken.** Ping the endpoint first.
> - **Raising the quota without a retention policy.** The cache fills up again.
> - **Reading only the client message.** The log of `core` often names the real cause.
