# Triggers And Manual Runs

A policy's **trigger** decides when Harbor sends the selected artifacts to Dragonfly. The choice changes how much load the seed peers get and how much attention the policy needs. This part compares the three triggers, writes a schedule, and starts a policy by hand.

## The three triggers

| Trigger | When the policy runs | A good fit |
| --- | --- | --- |
| Manual | Only when someone starts it | A one-time preheat before a planned rollout |
| Scheduled | At the times given by a cron expression | Releases that arrive in batches |
| Event based | When a matching artifact is pushed, labeled or finished scanning | One image per release, deployed soon after the push |

An event-based policy sends each matching artifact as it arrives, so a pipeline that pushes ten tags creates ten executions. A scheduled policy runs once and sends everything that matches at that moment. A manual policy never runs on its own, which makes it the safest choice while you are still testing.

## Write a schedule

Harbor's cron expression has **six fields**, and the first is the seconds:

```text
0 0 2 * * *
```

The fields are second, minute, hour, day of month, month and day of week. The example runs at 02:00:00 every day. A five-field expression from a Linux crontab, `0 2 * * *`, is read with the wrong meaning: its first field becomes the seconds. Write the seconds first, always.

## Register the instance

The commands use two helpers; define them again in a new terminal. Register Dragonfly if the playground has no instance yet:

<!-- astrona:playground:renew -->

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
wst() { kubectl -n workstation exec -it deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
harbor_api POST /p2p/preheat/instances -w '%{http_code}\n' --data '{"name":"dragonfly","vendor":"dragonfly","endpoint":"http://dragonfly-manager.dragonfly-system.svc.cluster.local:8080","auth_mode":"NONE","enabled":true,"insecure":true,"default":false}'
```

Harbor answers `201`. If the instance exists already, Harbor answers `409` and you can go on.

## Create a scheduled policy

Get the two ids and save the policy. The `trigger` field is a JSON string, so its quotes are escaped:

```sh
harbor_api GET /projects/inventory | ws jq '.project_id'
harbor_api GET /p2p/preheat/instances/dragonfly | ws jq '.id'
```

```json
{
  "name": "nightly-preheat",
  "project_id": <PROJECT_ID>,
  "provider_id": <INSTANCE_ID>,
  "filters": "[{\"type\":\"repository\",\"value\":\"**\"},{\"type\":\"tag\",\"value\":\"v*\"}]",
  "trigger": "{\"type\":\"scheduled\",\"trigger_setting\":{\"cron\":\"0 0 2 * * *\"}}",
  "enabled": true
}
```

Send it as in the previous module, with the file saved as `preheat-policy-nightly-preheat.json`:

```sh
harbor_api POST /projects/inventory/preheat/policies --data-binary @- < preheat-policy-nightly-preheat.json -w '%{http_code}\n'
```

Harbor answers `201`. The field for the cron is named `trigger_setting`, singular, in the preheat API. The replication API names its field `trigger_settings`, plural, so do not copy one into the other.

## Start it by hand

A scheduled policy can also be started at any time, which is how you test it before the first night:

```sh
harbor_api POST /projects/inventory/preheat/policies/nightly-preheat/executions --data '{}' -w '%{http_code}\n'
harbor_api GET /projects/inventory/preheat/policies/nightly-preheat/executions | ws jq '.[] | {id, status, trigger}'
```

The first command starts one execution. The second lists the executions with their status and what started them. In this playground an execution does not end well, because the seed peer does not trust Harbor's certificate; the next parts say why. The execution list is the proof that Harbor sent the request.

## Your mission: Schedule Nightly Preheating

You can now choose a trigger, write a six-field schedule and start a policy by hand. The graded lab gives you Harbor with Dragonfly already registered, and asks for a scheduled policy that selects only release tags and has been run once.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-103-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS103.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-103-lab-030-02
astrona start ats-103-playground-030-02
```

## Common pitfalls

> [!WARNING]
> - **A five-field cron.** Harbor reads the first field as seconds.
> - **`trigger_settings` in a preheat policy.** The preheat API uses `trigger_setting`.
> - **An event-based trigger for a batch release.** It creates one execution per push instead of one run.
> - **Testing only on the schedule.** Start the policy by hand first.
