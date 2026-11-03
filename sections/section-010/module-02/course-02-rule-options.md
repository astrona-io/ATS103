# Rule Options: Override, Bandwidth And Resource Types

A rule that copies everything, as fast as it can, and replaces whatever it finds, is rarely what a team wants. Real registries need limits: some tags must not be overwritten, the network link is shared, and only some kinds of artifacts belong in the project. This part covers the options of a replication rule that control how each copy is made, and the filters that choose the kind of artifact.

## Override

The **override** option decides what happens when the destination already holds an artifact with the same name and tag. With override on, the copy replaces the existing artifact when the content differs. With override off, Harbor leaves the existing artifact alone and skips the copy.

Override matters for tags that move. At the supplier, `nightly` points at a different image every day. With override on, the project keeps up with it. With override off, the project keeps the first `nightly` it ever received. For release tags such as `1.0.0` that must never change, override off protects the copy you already have; a changed source tag is then not allowed to enter.

Override works on the tag, not on the digest. If the destination tag points at a different digest than the source tag, the two artifacts differ and override decides which one wins. If both tags point at the same digest, there is nothing to copy and the task succeeds without transferring blobs.

## Bandwidth

The **bandwidth** option (field `speed`) limits the speed of each copy task, in kilobytes per second. The value `-1` means no limit. A limit protects a shared link: a rule that copies a large image at full speed during working hours can starve other traffic. The limit applies to each task separately, so a rule that runs several tasks at once can use more than the limit in total.

Set it when the rule is created or edit it later:

<!-- astrona:playground:renew -->

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
harbor_api GET /replication/policies/<RULE_ID> \
  | ws jq -c '.speed=512' \
  | harbor_api PUT /replication/policies/<RULE_ID> --data-binary @- -w '%{http_code}\n'
```

The commands need the endpoint `mirror` and the rule `pull-tools` from the previous part; the rule's id comes from `harbor_api GET /replication/policies`. The REST API replaces a whole rule on `PUT`, so the command reads the rule, changes one field with `jq`, and sends the whole object back. Harbor answers `200`. Read the value back with `harbor_api GET /replication/policies/<RULE_ID> | ws jq '.speed'`; it prints `512`.

## Resource types and label filters

Harbor stores more than container images. The **resource** filter limits a rule to one kind of artifact: `image`, `chart`, or the generic value that covers every OCI artifact, such as signatures and SBOMs attached to an image. A rule for a project that only runs containers can select `image` and leave the other kinds behind.

The **label** filter selects artifacts by the Harbor labels attached to them. Labels are a Harbor feature, so the filter is useful when the source is a Harbor. Like the tag filter, it has a decoration: `matches` keeps artifacts that carry the label, and `excludes` removes them. A team can mark artifacts it has approved with a label such as `approved`, and a rule that matches that label copies only approved artifacts.

Set a resource filter on the rule with the same read-change-send pattern:

```sh
harbor_api GET /replication/policies/<RULE_ID> \
  | ws jq -c '.filters += [{"type":"resource","value":"image"}]' \
  | harbor_api PUT /replication/policies/<RULE_ID> --data-binary @- -w '%{http_code}\n'
```

Harbor answers `200`. The filters of a rule are combined with a logical AND: an artifact must pass every filter to be copied.

## Copy by chunk

When both sides are Harbor, a rule can copy large blobs in chunks. Each chunk is a separate request, so one failed chunk does not restart the whole blob. Chunked copying is not available against other registries, so the option stays off in this playground, where the mirror is a CNCF Distribution registry.

You now know the options that shape each copy: override for tags that move, bandwidth for shared links, resource and label filters for the kind of artifact, and chunks for large blobs between two Harbors. The remaining question is when a rule runs without anyone starting it.

## Common pitfalls

> [!WARNING]
> - **Override off for a moving tag.** The project never receives a new `nightly`.
> - **Override on for release tags.** A changed source tag silently replaces the copy you already trust.
> - **Expecting the bandwidth limit to cap the whole rule.** It caps each task.
> - **A label filter against a source that is not a Harbor.** Other registries have no Harbor labels, so the filter has nothing to match.
> - **Sending only the changed field with `PUT`.** The whole rule must be sent, or the missing fields are reset.
