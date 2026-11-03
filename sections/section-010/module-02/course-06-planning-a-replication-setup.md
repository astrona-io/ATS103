# Planning A Replication Setup

Replication rules are easy to create and hard to keep correct once there are many of them. This part gives a way to plan the rules before you write them, and a checklist to review them afterwards.

## Plan from the data's direction

Start with a list of the flows, one line each: where artifacts come from, where they go, which ones and how fast.

| Flow | Direction | Selection | Trigger |
| --- | --- | --- | --- |
| Releases to a second data centre | Push | Release tags | Event based, with delete |
| Supplier base images into Harbor | Pull | Stable tags of listed repositories | Scheduled |
| A customer's registry | Push | One repository, one tag pattern | Manual per delivery |

Every flow becomes one rule. Resist combining flows in one rule with a wide filter: a rule with a single purpose is easy to read in the execution list.

## Name rules so they explain themselves

Give each rule a name that states direction and content, such as `push-releases-dc2` or `pull-vendor-tools`. The execution list shows the rule name, and a name that says what it does saves the reader from opening it.

## Limit the blast radius

- Use a separate endpoint and robot account for each remote, so a revoked login stops one flow.
- Give each pull rule its own destination project or namespace, so a bad filter cannot overwrite unrelated repositories.
- Use the bandwidth limit on rules that run during working hours.

## Review the setup

List all rules and read them in one view. The helpers are the ones from the earlier parts:

<!-- astrona:playground:renew -->

```sh
harbor_api GET '/replication/policies?page_size=100' | ws jq '.[] | {name, enabled, push: (.dest_registry != null), pull: (.src_registry != null), trigger: .trigger.type, override, speed}'
```

The answer has one object per rule. Check that every rule is enabled, that each pull rule has a source and each push rule a destination, and that every trigger is the one you planned.

## A review checklist

1. Does each rule have one purpose and a name that says it?
2. Does the filter select only what the flow needs?
3. Is the trigger the right one for the direction?
4. Does the endpoint use a least-privilege account?
5. When did the rule last run, and did the last execution succeed?

## Common pitfalls

> [!WARNING]
> - **One rule for every flow.** Failures become hard to separate.
> - **A shared administrator credential in endpoints.** One leak affects every flow.
> - **Rules nobody reviews.** An old rule that fails every night is easy to miss.
