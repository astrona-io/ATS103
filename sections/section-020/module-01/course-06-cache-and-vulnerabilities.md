# Scanning And Securing Cached Images

An image in a proxy cache is still an image in Harbor, and it can be scanned, signed and blocked like any other. This part shows how the security features of a project apply to a cache, and where they can surprise you.

## Scanning a cached image

Harbor's scanner can scan the artifacts of a cache project. A project can scan on push, but nothing is pushed to a cache, so that setting never fires. Start a scan by hand or on a schedule instead. Start one with the API, using the helpers from the earlier parts, for the image you cached:

<!-- astrona:playground:renew -->

```sh
harbor_api POST /projects/docker-cache/repositories/library%252Falpine/artifacts/3.22/scan -w '%{http_code}\n'
```

Harbor answers `202` when it accepts the scan. The result shows in the artifact's vulnerability report. The repository name has its slash encoded twice, as in the earlier parts.

## Blocking vulnerable pulls

A project can refuse pulls of images that have vulnerabilities at or above a chosen severity. This is called **prevent vulnerable images from running**. On a cache project, the effect is useful: a base image with a critical vulnerability is cached and then refused to clients. The image must be scanned before the setting can judge it; an unscanned image is also refused when the setting is on, which can surprise a team on the first pull.

## Content trust and signing

A cache project holds the signatures only if they exist upstream and Harbor fetches them. Do not rely on a cache to add trust. If clients must only run signed images, the policy has to be set on the cache project, and the images must be signed by the team that owns them.

## What a cache cannot promise

The cache copies what the upstream serves. A tag in a cache follows the upstream tag, so `alpine:3.22` can change. A digest never changes, and it is the only name that is stable. Teams that need the same image tomorrow as today should deploy by digest.

## Common pitfalls

> [!WARNING]
> - **Relying on scan on push.** Nothing is pushed to a cache, so scan by hand or on a schedule.
> - **Blocking vulnerable images without scanning first.** Unscanned images are refused too.
> - **Deploying by tag from a cache.** Tags move with the upstream. Use the digest.
