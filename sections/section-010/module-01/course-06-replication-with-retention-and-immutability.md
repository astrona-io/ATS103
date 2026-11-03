# Replication, Retention And Immutable Tags

Replication is not the only thing that changes the tags of a project. Tag retention removes tags, and tag immutability refuses changes to them. Both live in the project that receives the copies, and both change what a rule can do. This part explains how they interact.

## Tag retention at the destination

A **tag retention rule** keeps a chosen number of tags per repository and removes the rest. If the destination project has such a rule, replication can copy a tag that retention removes at its next run. The copy then exists for a while and disappears. Nothing is wrong with the rule: the two policies disagree. When a destination is meant to hold every release, give its retention rules a selector that keeps release tags, or leave retention off for that project.

## Tag immutability at the destination

A **tag immutability rule** makes matching tags impossible to overwrite or delete. This matters for replication in one case: a rule whose **override** option is on tries to replace a tag that is immutable at the destination. Harbor refuses the change, and the task for that tag fails. Replicating a new tag name is not affected, since an immutable rule protects existing tags and does not block new ones.

The same rules apply to the source project. An immutable release tag in Harbor cannot be moved to another image, which is the reason release tags are good candidates for immutability: every copy of `v1.2.0` is then the same image.

## Look at what a project enforces

List the retention and immutability rules of the project `inventory` with the REST API. The helpers are the ones from the earlier parts:

<!-- astrona:playground:renew -->

```sh
harbor_api GET /projects/inventory | ws jq '{project_id, metadata}'
harbor_api GET /projects/inventory/immutabletagrules | ws jq 'length'
```

The first command prints the project's id and settings, and the second prints how many immutability rules it has. A new playground project has none. When replication fails for one tag and works for the rest, check these rules at the destination before you change the rule.

## Choosing the combination

| Goal | Source project | Destination project |
| --- | --- | --- |
| Identical releases everywhere | Immutable `v*` tags | Immutable `v*` tags, no retention on releases |
| A bounded mirror | No special rules | Retention keeps the newest tags |
| A moving tag such as `latest` | Mutable | Mutable, and the rule has override on |

## Common pitfalls

> [!WARNING]
> - **Retention at the destination without a thought for replication.** Tags can disappear after they arrive.
> - **Override on with immutable destination tags.** The task for that tag fails.
> - **Reading a failed task as a broken rule.** The task log names the reason.
