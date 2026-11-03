# Delete Replication And Keeping Copies In Step

A rule that copies releases to a second registry makes two copies of every release. When a release is withdrawn in Harbor, the second copy would stay unless something removes it. This part covers the option that removes it, and the limits of what a rule keeps in step.

## The delete option

A push rule has the option **Delete remote resources when locally deleted**. In the REST API, the rule field is `replicate_deletion`. When it is on and an artifact that the rule's filters select is deleted in Harbor, Harbor deletes the same artifact at the destination. The deletion is an event, so the option fits the event-based trigger. A scheduled run copies what exists at the time and does not look for deletions.

## What the option does not do

- It does not copy deletions that happened before the rule existed.
- It acts on artifacts that match the rule's filters. A deleted artifact that the filters never selected is left alone at the destination.
- It acts on deletions made in Harbor. A tag removed by hand at the destination is not restored, unless the source artifact is pushed or replicated again.
- It is a property of push rules. A pull rule never deletes anything in Harbor because a source registry deleted something.

## Check the setting

Read a rule back and look at the option. The commands use the helpers from the earlier parts, and `<RULE_NAME>` is the name of your rule:

<!-- astrona:playground:renew -->

```sh
harbor_api GET '/replication/policies?name=<RULE_NAME>' | ws jq '.[] | {name, trigger: .trigger.type, deletion, replicate_deletion}'
```

The answer shows the trigger type and the two deletion fields. A rule that must keep the destination in step with Harbor needs the event-based trigger and the deletion option together.

## When copies still drift

Even with the option on, copies can drift apart. A failed task leaves one tag missing at the destination, a retention policy at the destination can remove tags that Harbor still holds, and a destination project can be changed by its own team. The way to detect drift is to compare the tag lists of both sides:

```sh
ws regctl tag ls harbor.localtest.me:8443/inventory/podinfo
ws regctl tag ls mirror.localtest.me:5001/inventory/podinfo
```

Compare the two lists by eye. A tag in only one of them is the thing to explain, and the execution list of the rule is where to start.

## Common pitfalls

> [!WARNING]
> - **Expecting deletes from a scheduled rule.** Use the event-based trigger with the delete option.
> - **Turning the option on and expecting old deletions to replay.** It acts on new deletions only.
> - **Never comparing both sides.** A silent failed task is found only by looking.
