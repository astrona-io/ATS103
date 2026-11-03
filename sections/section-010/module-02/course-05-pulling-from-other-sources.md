# Pulling From Docker Hub And Another Harbor

The earlier parts pulled from a plain registry. A pull rule works the same with other providers, and each has a few details of its own. This part compares the two most common sources.

## A Docker Hub source

An endpoint with the provider `docker-hub` lets a pull rule copy selected images from Docker Hub into a Harbor project. The difference from a proxy cache is when the copy happens: a proxy cache fetches on the first pull, and a pull rule copies everything that matches at the time it runs, whether anyone pulls it or not. A pull rule fits a fixed list of base images that must exist in Harbor before a build starts.

Names at Docker Hub include the namespace, so the name filter for the official `alpine` image is `library/alpine`. Docker Hub's pull limit counts the requests the rule makes, so a rule that selects many tags on a schedule can use up the allowance for the address Harbor uses. Select tags narrowly.

## Another Harbor as the source

An endpoint with the provider `harbor` points at a second Harbor. It is the case with the most features, because both sides speak the same API:

- Label filters work, because labels exist on both sides.
- The option **copy by chunk** is available between two Harbors, and it splits large layers into pieces for a link that drops.
- The endpoint credential should be a robot account of the source project with pull permission only.

## Compare the sources

List the providers Harbor knows and the endpoints you created. The helpers are the ones from the earlier parts:

<!-- astrona:playground:renew -->

```sh
harbor_api GET /replication/adapters | ws jq -c '.'
harbor_api GET '/registries?page_size=100' | ws jq '.[] | {name, type: .type, url}'
```

The first command lists the provider names Harbor can use in an endpoint, and the second shows the endpoints you have. The provider decides how Harbor reads names and tags, so the same URL with a different provider behaves differently.

## Choosing between a pull rule and a proxy cache

| Need | Use |
| --- | --- |
| Images available before anyone asks | A pull rule |
| Only images that are actually used | A proxy cache |
| A schedule and a fixed list | A pull rule |
| No list to maintain | A proxy cache |

## Common pitfalls

> [!WARNING]
> - **Leaving out the namespace for Docker Hub.** Official images need `library/`.
> - **Broad tag filters on a schedule.** They spend the pull limit.
> - **A personal login in a Harbor endpoint.** Use a pull-only robot account.
