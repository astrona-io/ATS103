# Solution: Wire A Release Pipeline End To End

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the replication rule, a release pushed by the grader reaching the mirror, the instance, and the policy. There are four faults across three objects.

## Step 1: Define the helpers

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
wst() { kubectl -n workstation exec -it deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
ws harbor login https://harbor.localtest.me:8443 -u admin -p Harbor12345
```

## Step 2: The replication rule

```sh
harbor_api GET '/replication/policies?page_size=100' \
  | ws jq '.[] | select(.name=="release-to-mirror") | {id, enabled, trigger, filters, dest_registry: .dest_registry.name}'
```

The filters and the destination are right, and the rule is enabled, but its trigger is `manual`. Nothing starts it on a push. Change only the trigger, keeping the rule's id, replacing `<RULE_ID>`:

```sh
harbor_api GET /replication/policies/<RULE_ID> \
  | ws jq -c '.trigger={"type":"event_based"} | .enabled=true' \
  | harbor_api PUT /replication/policies/<RULE_ID> --data-binary @- -w '%{http_code}\n'
```

## Step 3: The instance

```sh
harbor_api GET /p2p/preheat/instances/dragonfly | ws jq '{id, endpoint, enabled}'
ws harbor instance ping dragonfly
```

The instance points at port `65003`, the manager's gRPC port, and it is disabled; the ping fails. Fix both in place:

```sh
harbor_api GET /p2p/preheat/instances/dragonfly \
  | ws jq -c '.endpoint="http://dragonfly-manager.dragonfly-system.svc.cluster.local:8080" | .enabled=true' \
  | harbor_api PUT /p2p/preheat/instances/dragonfly --data-binary @- -w '%{http_code}\n'
ws harbor instance ping dragonfly
```

The update answers `200`, and the ping now succeeds.

## Step 4: The preheat policy

```sh
harbor_api GET /projects/inventory/preheat/policies/release-preheat \
  | ws jq '{enabled, trigger: (.trigger | fromjson), filters: (.filters | fromjson)}'
```

The policy's trigger is `manual`, and its tag filter is `**`, which would preheat every development build. Change both, keeping the policy's id. Its filters and trigger are JSON strings, so `jq`'s `tojson` turns the new objects into strings:

```sh
harbor_api GET /projects/inventory/preheat/policies/release-preheat \
  | ws jq -c '.filters=([{"type":"repository","value":"**"},{"type":"tag","value":"v*"}] | tojson)
              | .trigger=({"type":"event_based","trigger_setting":{"cron":""}} | tojson) | .enabled=true' \
  | harbor_api PUT /projects/inventory/preheat/policies/release-preheat --data-binary @- -w '%{http_code}\n'
```

## Step 5: Prove the pipeline

Push a release with its own digest and check the mirror after about half a minute:

```sh
ws regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
ws regctl registry set mirror.localtest.me:5001 --tls disabled
ws regctl image mod harbor.localtest.me:8443/inventory/podinfo:6.15.0 --create v4.0.0 --annotation org.example.build=v4.0.0
ws regctl tag ls mirror.localtest.me:5001/inventory/podinfo
wst harbor project preheat execution list inventory release-preheat
```

The `harbor` CLI (version 0.0.27) draws lists and views as a table only on a terminal, so these commands run through `wst`, which adds `-t` (a terminal) to `kubectl exec`.

The mirror lists `v4.0.0`, and the preheat policy shows a new execution for the push. That execution does not succeed in this environment, because the seed peer does not trust Harbor's certificate and no Dragonfly token exists; its existence shows the trigger works.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete and recreate the rule, instance or policy | The grader compares ids with the starting state and rejects new objects |
| Start the rule by hand | The next release still waits; the grader pushes a tag and starts nothing |
| Leave the tag filter at `**` | Every build is preheated; the grader requires `v*` |
| Enable the instance but keep port `65003` | Harbor's health check fails on the gRPC port |
