# Caches For CI And Restricted Networks

Two situations use a cache for more than saving bandwidth: a CI system that pulls the same base images thousands of times, and a network that cannot reach the internet. This part shows how the design differs for each.

## A cache for CI

A CI system has many short jobs on changing machines, so every job starts with an empty node cache. Without a Harbor cache, each job pulls from Docker Hub, and the anonymous limit counts every one. With the cache:

- Jobs pull from Harbor, and only the first one reaches Docker Hub.
- Use a robot account per pipeline, so the audit log shows which pipeline pulls what.
- Pin base images by tag in the Dockerfile, and avoid `latest`, so each build checks the upstream as seldom as possible.

## A cache in a restricted network

A cache needs to reach its upstream. In a network that cannot, there are two options:

| Option | How it works | Cost |
| --- | --- | --- |
| Allow Harbor's address through the firewall | The cache fetches on demand | A firewall rule to maintain |
| Move images by replication | An outside Harbor pulls, a rule pushes to the inside Harbor, or an administrator copies artifacts | The list of images must be maintained |

When the firewall rule is acceptable, the cache is simpler. When it is not, the inside Harbor uses normal projects, not caches, and replication keeps them filled.

## Check what a build used

The list of repositories in the cache project shows what builds pulled, which is the starting list for a replication rule in a restricted network. The helpers are the ones from the earlier parts:

<!-- astrona:playground:renew -->

```sh
harbor_api GET '/projects/team-cache/repositories?page_size=100' | ws jq -r '.[].name'
```

The command prints one repository name per line. The names are the images that were pulled through the cache, which makes the cache a record of what your builds depend on.

## Common pitfalls

> [!WARNING]
> - **Using `latest` in CI.** Each job checks the upstream again.
> - **One shared account for all pipelines.** The audit log cannot separate them.
> - **A cache in a network that cannot reach the upstream.** The first pull of every image fails.
