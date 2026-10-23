# Solution: Repair A Replication Pipeline

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks five things: the endpoint, that the rule is the original one and is enabled and event based, that a release tag reaches the mirror, that a development tag does not, and that a deleted release disappears from the mirror. There are four faults, and each one alone stops releases from arriving.

## Step 1: Define the helpers and read the endpoint

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
wst() { kubectl -n workstation exec -it deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
harbor_api GET '/registries?page_size=100' | ws jq '.[] | {id, name, type, url}'
```

The endpoint `mirror` points at `http://mirror.localtest.me:5000`. The mirror listens on port `5001`. Test the endpoint to confirm, replacing `<MIRROR_ID>` with its id:

```sh
harbor_api POST /registries/ping --data '{"id":<MIRROR_ID>}' -o /dev/null -w '%{http_code}\n'
```

The answer is not `200`: Harbor cannot reach anything on port 5000. That is the first fault.

## Step 2: Fix the endpoint in place

Change only the URL. The endpoint keeps its id, so the rule that refers to it keeps working:

```sh
harbor_api PUT /registries/<MIRROR_ID> --data '{"url":"http://mirror.localtest.me:5001","insecure":true}' -w '%{http_code}\n'
harbor_api POST /registries/ping --data '{"id":<MIRROR_ID>}' -o /dev/null -w '%{http_code}\n'
```

The update answers `200`, and the ping now answers `200` too. Harbor would refuse to delete this endpoint anyway, because a rule refers to it.

## Step 3: Read the rule

```sh
harbor_api GET '/replication/policies?page_size=100' \
  | ws jq '.[] | select(.name=="release-to-mirror") | {id, enabled, trigger, filters, replicate_deletion, dest_namespace, dest_namespace_replace_count}'
```

The rule has three more faults:

- `enabled` is `false`, so it never runs.
- The trigger is `manual`, so even an enabled rule waits for someone to start it.
- The name filter is `inventry/**`, which matches no repository. A manual start would have produced executions with zero tasks.

`replicate_deletion` is also `false`, so a deleted release would stay in the mirror. The destination namespace and flattening are already right.

## Step 4: Fix the rule in place

Read the rule, change the four fields with `jq`, and send it back under the same id:

```sh
harbor_api GET /replication/policies/<RULE_ID> \
  | ws jq -c '.filters=[{"type":"name","value":"inventory/**"},{"type":"tag","value":"v*","decoration":"matches"}]
              | .trigger={"type":"event_based"} | .enabled=true | .replicate_deletion=true' \
  | harbor_api PUT /replication/policies/<RULE_ID> --data-binary @- -w '%{http_code}\n'
```

Harbor answers `200`. Delete replication only works with the event-based trigger, which is why both changes belong together.

## Step 5: Prove the pipeline

Push a release with its own digest, check the mirror, then delete it in Harbor and check again:

```sh
ws regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
ws regctl registry set mirror.localtest.me:5001 --tls disabled
ws regctl image mod harbor.localtest.me:8443/inventory/podinfo:6.15.0 --create v2.0.0 --annotation org.example.build=v2.0.0
ws regctl tag ls mirror.localtest.me:5001/inventory/podinfo
```

After about half a minute the list holds `v2.0.0`. Now delete it in Harbor and list the mirror again after another half minute:

```sh
harbor_api DELETE /projects/inventory/repositories/podinfo/artifacts/v2.0.0 -w '%{http_code}\n'
ws regctl tag ls mirror.localtest.me:5001/inventory/podinfo
```

`v2.0.0` is gone from the mirror. Two executions now show in `wst harbor replication executions list`, one for the push and one for the delete.

The `harbor` CLI (version 0.0.27) draws lists and views as a table only on a terminal, so these commands run through `wst`, which adds `-t` (a terminal) to `kubectl exec`.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete the rule and create a new one | The grader rejects it: the task is to repair the rule other things refer to, and its history of executions goes with it |
| Delete the endpoint and create a new one | Harbor refuses while a rule refers to it |
| Start the rule by hand | The next release still waits for someone; the grader pushes a tag and starts nothing |
| Tag filter `*` | Development builds reach the mirror |

## Practice on your own

- Set the rule's bandwidth to a low value and watch the task take longer in its log.
- Stop the mirror, push a release, and read the error in the failed task's log.
