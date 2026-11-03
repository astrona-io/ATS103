# Selecting Artifacts, Criteria And Scope

A policy that selects too much fills the seed peers with images nobody deploys, and one that selects too little leaves the rollout slow. This part covers the three tools that narrow a policy: filters, criteria and scope.

## Filters

A policy has up to three filters, and an artifact must match all of them:

| Filter | What it matches | Example |
| --- | --- | --- |
| Repository | The repository name inside the project | `**` for every repository, `podinfo` for one |
| Tag | The tag of the artifact | `v*` for release tags |
| Label | A label on the artifact | `release` for artifacts a person marked |

The patterns work as in replication filters. `*` matches any characters except `/`, and `**` also matches `/`. The tag filter `v*` matches `v1.0.0` and does not match `6.15.0`. Read a policy back to see the filters Harbor stored:

<!-- astrona:playground:renew -->

```sh
harbor_api GET /projects/inventory/preheat/policies/nightly-preheat | ws jq '{name, filters: (.filters | fromjson)}'
```

The `filters` field is stored as text, which is why `fromjson` turns it back into a list. The label filter is useful when the tag cannot tell releases from other builds: a person or a pipeline labels the artifact that should be preheated, and the policy follows the label.

## Criteria

**Criteria** are conditions on the artifact itself, and an artifact must also pass them to be sent. They exist in the policy form of the web portal:

- **Only signed images.** The artifact must have a signature, so unsigned builds are never preheated.
- **Vulnerability severity.** The artifact must not have vulnerabilities at or above the chosen severity, so an image that Harbor's deployment security would block is not preheated either.

Criteria turn Harbor's other checks into preheat rules. An image that fails a criterion is simply left out, and the execution shows no task for it.

## Scope

The **scope** says which Dragonfly peers receive the preheated image. It is set in the policy form of the web portal, and Harbor offers three choices:

| Scope | Which peers receive the image |
| --- | --- |
| Single seed peer | One seed peer, chosen by Dragonfly |
| All seed peers | Every seed peer of the cluster |
| All peers | Every peer, including the ones on the nodes |

A single seed peer is the cheapest, and the other peers then fetch the image from it when they need it. All seed peers suit a cluster that has several and wants the image everywhere at once. All peers moves the most data, and it only makes sense when the nodes have free disk and the next rollout is soon. In this playground, a seed peer is the only peer.

## An example: choose the right selection

A team pushes `v1.4.0`, `v1.4.0-rc1`, `main-3f2a1b` and `6.15.0` to the project. The tag filter `v*` selects `v1.4.0` and `v1.4.0-rc1`. The release candidate is probably not worth preheating, so the team can narrow the pattern to `v*.*.*`, which `v1.4.0` matches and `v1.4.0-rc1` does not, because `-rc1` follows the third number. Then check what the policy would pick, by listing the tags of the repository:

```sh
ws regctl tag ls harbor.localtest.me:8443/inventory/podinfo
```

The output lists every tag. Compare it with the pattern by eye, and push a test tag when you are unsure. A filter you never tested is the most common reason for a policy that does nothing.

You can now narrow a policy with filters, criteria and scope. The next part follows a selected artifact on its way to the seed peer.

## Common pitfalls

> [!WARNING]
> - **A `*` tag filter.** It matches every tag, development builds included.
> - **A label filter nobody sets.** The policy then selects nothing.
> - **Scope "All peers" on every policy.** It moves the most data for the least benefit.
> - **Trusting a pattern you did not test.** Push a test tag and read the execution list.
