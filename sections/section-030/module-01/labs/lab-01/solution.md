# Solution: Preheat Release Tags With Dragonfly

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks two things: the instance `dragonfly` and the policy `release-preheat`.

## Step 1: Define the helpers and check Dragonfly

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
ws curl -sS -o /dev/null -w '%{http_code}\n' http://dragonfly-manager.dragonfly-system.svc.cluster.local:8080/healthy
```

The manager answers `200`. It is ready for Harbor.

## Step 2: Register the instance

```sh
printf '%s' 'Harbor12345' | ws harbor login https://harbor.localtest.me:8443 -u admin --password-stdin
ws harbor instance create --name dragonfly --provider dragonfly \
  --url http://dragonfly-manager.dragonfly-system.svc.cluster.local:8080 \
  --authmode NONE --insecure
ws harbor instance ping dragonfly
```

The ping succeeds. `--enable` defaults to true, so the instance is enabled. Note its id:

```sh
harbor_api GET /p2p/preheat/instances/dragonfly | ws jq '{id, vendor, endpoint, enabled}'
```

## Step 3: Create the policy

Get the project's id:

```sh
harbor_api GET /projects/inventory | ws jq '.project_id'
```

Save this as `preheat-policy-release-preheat.json`, with `<PROJECT_ID>` and `<INSTANCE_ID>` replaced:

```json
{
  "name": "release-preheat",
  "description": "Preheat every release of the project inventory",
  "project_id": <PROJECT_ID>,
  "provider_id": <INSTANCE_ID>,
  "filters": "[{\"type\":\"repository\",\"value\":\"**\"},{\"type\":\"tag\",\"value\":\"v*\"}]",
  "trigger": "{\"type\":\"event_based\",\"trigger_setting\":{\"cron\":\"\"}}",
  "enabled": true
}
```

The filters and the trigger are JSON strings, which is why their quotes are escaped. Send it:

```sh
harbor_api POST /projects/inventory/preheat/policies --data-binary @- < preheat-policy-release-preheat.json -w '%{http_code}\n'
ws harbor project preheat policy list inventory
```

Harbor answers `201`, and the list shows `release-preheat`.

## Step 4: Check the policy as the grader reads it

```sh
harbor_api GET /projects/inventory/preheat/policies/release-preheat \
  | ws jq '{provider_id, enabled, trigger: (.trigger | fromjson | .type), filters: (.filters | fromjson)}'
```

The trigger is `event_based`, and the filters are the repository filter `**` and the tag filter `v*`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Endpoint on port `65003` | That is the manager's gRPC port for its own peers; Harbor's health check fails |
| Tag filter `**` | Every development build is preheated; the grader requires `v*` |
| Manual trigger | Releases are preheated only when someone remembers; the grader requires `event_based` |
| Auth mode `OAUTH` with an invented token | Harbor sends a token Dragonfly never issued; the task asks for no authentication until the team creates a real token |

## Practice on your own

- Push a release tag and look at the execution it starts with `ws harbor project preheat execution list inventory release-preheat`, then read why it fails in this environment.
- Try to delete the instance while the policy uses it.
