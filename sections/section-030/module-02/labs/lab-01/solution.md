# Solution: Schedule Nightly Preheating

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the schedule, the selection and that the policy was run once.

## Step 1: Define the helpers and find the ids

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
wst() { kubectl -n workstation exec -it deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
harbor_api GET /projects/inventory | ws jq '.project_id'
harbor_api GET /p2p/preheat/instances/dragonfly | ws jq '{id, enabled, endpoint}'
```

The first command prints the project's id and the second the instance's id. The instance is already registered and enabled.

## Step 2: Create the policy

Save this as `preheat-policy-nightly-preheat.json`, with `<PROJECT_ID>` and `<INSTANCE_ID>` replaced:

```json
{
  "name": "nightly-preheat",
  "description": "Preheat release tags every night at 02:00",
  "project_id": <PROJECT_ID>,
  "provider_id": <INSTANCE_ID>,
  "filters": "[{\"type\":\"repository\",\"value\":\"**\"},{\"type\":\"tag\",\"value\":\"v*\"}]",
  "trigger": "{\"type\":\"scheduled\",\"trigger_setting\":{\"cron\":\"0 0 2 * * *\"}}",
  "enabled": true
}
```

The filters and the trigger are JSON strings, which is why their quotes are escaped. The cron has six fields: second, minute, hour, day of month, month and day of week. Send it:

```sh
harbor_api POST /projects/inventory/preheat/policies --data-binary @- < preheat-policy-nightly-preheat.json -w '%{http_code}\n'
wst harbor project preheat policy list inventory
```

Harbor answers `201`, and the list shows `nightly-preheat`.

## Step 3: Start it by hand

```sh
harbor_api POST /projects/inventory/preheat/policies/nightly-preheat/executions --data '{}' -w '%{http_code}\n'
harbor_api GET /projects/inventory/preheat/policies/nightly-preheat/executions | ws jq 'length'
```

The first command starts one execution and the second counts the executions of the policy. The execution may end in an error here, because the seed peer does not trust Harbor's certificate; the grader only needs it to exist.

## Step 4: Check the policy as the grader reads it

```sh
harbor_api GET /projects/inventory/preheat/policies/nightly-preheat \
  | ws jq '{provider_id, enabled, trigger: (.trigger | fromjson), filters: (.filters | fromjson)}'
```

The trigger is `scheduled` with the cron `0 0 2 * * *`, and the filters are the repository filter `**` and the tag filter `v*`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Five-field cron `0 2 * * *` | Harbor reads the first field as seconds, so the schedule is wrong or refused |
| Tag filter `**` | Every development build is preheated; the grader requires `v*` |
| Event-based trigger | The policy runs on every push, not at night; the grader requires `scheduled` |
| Skipping the manual run | The first real run happens at night, when nobody is watching |

## Practice on your own

- Read the execution list of the policy and open the task log of the manual run in the web portal.
- Change the cron to run every hour and read the policy back.
