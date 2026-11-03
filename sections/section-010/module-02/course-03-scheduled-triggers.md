# Scheduled Triggers And Cron Expressions

A rule that runs only when someone starts it will be forgotten. A pull rule cannot use the event-based trigger either: an event-based rule reacts to a push into Harbor, and a push into the supplier's registry is not an event Harbor sees. A pull rule that must stay current therefore runs on a schedule. This part writes the schedule, starts the rule by hand to prove it, and reads what the scheduler does.

## Which triggers a rule can use

A rule has one of three triggers: manual, scheduled and event based. The event-based trigger works only for push rules whose source is this Harbor. A pull rule can be manual or scheduled. A scheduled rule runs at the times a cron expression names. It copies what exists at that time, and it never copies deletions.

## The six fields of a Harbor cron expression

A **cron expression** is a line of fields that says when something runs. Harbor's expression has six fields, and the first is the seconds. Many guides show cron with five fields and no seconds; an expression written in that form does not mean the same in Harbor.

| Field | Range |
| --- | --- |
| Second | 0 to 59 |
| Minute | 0 to 59 |
| Hour | 0 to 23 |
| Day of the month | 1 to 31 |
| Month | 1 to 12 |
| Day of the week | 0 to 6, starting with Sunday |

A `*` in a field means every value. These examples show how the fields combine:

| Expression | When it runs |
| --- | --- |
| `0 0 * * * *` | Every hour, on the hour |
| `0 */15 * * * *` | Every 15 minutes |
| `0 30 2 * * *` | Every day at 02:30 |
| `0 0 6 * * 1` | Every Monday at 06:00 |

Harbor evaluates the expression in the time zone of its `core` component, which usually runs in UTC. Say that when you agree a schedule with someone: "02:30" means 02:30 UTC.

## Make the rule scheduled

Change the rule `pull-tools` from the previous part so that it runs every hour, and let it keep only the stable releases, tags that start with `1.`. The commands read the rule, change the trigger and the filters with `jq`, and send it back. Replace `<RULE_ID>` with the rule's id:

<!-- astrona:playground:renew -->

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
harbor_api GET /replication/policies/<RULE_ID> \
  | ws jq -c '.trigger={"type":"scheduled","trigger_settings":{"cron":"0 0 * * * *"}} | .filters=[{"type":"name","value":"vendor/tools"},{"type":"tag","value":"1.*","decoration":"matches"}]' \
  | harbor_api PUT /replication/policies/<RULE_ID> --data-binary @- -w '%{http_code}\n'
```

Harbor answers `200`. Read the trigger back to confirm that Harbor stored the expression:

```sh
harbor_api GET /replication/policies/<RULE_ID> | ws jq '.trigger'
```

The object holds the type `scheduled` and the cron expression under `trigger_settings`. The next full hour starts the first run. You do not have to wait for it: start the rule by hand, as a scheduled run would, and look at the executions.

```sh
harbor_api POST /replication/executions --data '{"policy_id":<RULE_ID>}' -w '%{http_code}\n'
wst() { kubectl -n workstation exec -it deploy/workstation -- "$@"; }
wst harbor replication executions list
```

The list shows one line per execution, with its trigger. A run you start by hand has the trigger `manual`, and a run the scheduler starts has the trigger `scheduled`. Both copy the same artifacts, because the trigger decides when the rule runs, not what it copies.

## A scheduled rule is not a push notification

A scheduled pull rule sees a new tag at the supplier only at its next run. If the supplier publishes `1.2.0` one minute after a run, the project receives it up to an hour later. Choose the interval from how late a copy may be and how much a run costs. A run that finds nothing new is cheap, because Harbor compares digests and transfers only what differs.

A scheduled rule also never removes anything. A tag the supplier deletes stays in the project until someone deletes it. That is usually what a vendor project needs, because the project is meant to hold a copy that does not disappear when the supplier makes a mistake.

You can now write a Harbor cron expression, set it on a rule, and run the rule by hand to prove it works. A scheduled rule keeps a project current within the interval you chose.

## Common pitfalls

> [!WARNING]
> - **A five-field cron expression.** Harbor needs the seconds field first. Write `0 0 * * * *`, not `0 * * * *`.
> - **Choosing the event-based trigger for a pull rule.** Harbor does not see pushes to a remote registry. Use a schedule.
> - **Waiting for the schedule to prove the rule.** Start an execution by hand to check the filters and the path now.
> - **Reading the cron time as local time.** Harbor uses the time zone of its `core` component, usually UTC.

## Your mission: Pull Vendor Images On A Schedule

You can now write a pull rule with precise filters, a destination path and a schedule. The graded lab gives you Harbor with a working endpoint to the mirror and an empty project, and asks you to pull only the stable releases of one vendor repository, every hour.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-103-playground-010-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS103.git -c sections/section-010/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-103-lab-010-02
astrona start ats-103-playground-010-02
```
