# Solution: Replicate Release Tags To A Mirror

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the rule's settings, that a release tag it pushes reaches the mirror on its own, and that a development tag it pushes does not.

## Step 1: Define the helpers and look at the endpoint

Every Harbor command runs in the `workstation` pod. Define the helpers, then list the endpoints:

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

The list holds one endpoint, `mirror`, with the provider `docker-registry` and the URL `http://mirror.localtest.me:5001`. Note its id. Test it before you build on it, replacing `<MIRROR_ID>`:

```sh
harbor_api POST /registries/ping --data '{"id":<MIRROR_ID>}' -o /dev/null -w '%{http_code}\n'
```

`200` means Harbor reaches the mirror. The endpoint is fine and stays as it is.

## Step 2: Work out the filters and the destination path

The rule needs two filters. The name filter `inventory/**` matches every repository in the project `inventory`, at any depth. The tag filter `v*` with the decoration `matches` lets only tags that start with `v` through.

For the path, the copy of `inventory/podinfo` must arrive as `inventory/podinfo`. The destination namespace `inventory` with one level of flattening does that: the first level of the source path, `inventory`, is replaced by the namespace `inventory`. Without flattening, the copy would arrive as `inventory/inventory/podinfo`.

## Step 3: Create the rule

Save this as `replication-rule-release-to-mirror.json`, with `<MIRROR_ID>` replaced by the endpoint's id:

```json
{
  "name": "release-to-mirror",
  "description": "Every release of the project inventory to the mirror",
  "dest_registry": { "id": <MIRROR_ID> },
  "dest_namespace": "inventory",
  "dest_namespace_replace_count": 1,
  "filters": [
    { "type": "name", "value": "inventory/**" },
    { "type": "tag", "value": "v*", "decoration": "matches" }
  ],
  "trigger": { "type": "event_based" },
  "override": true,
  "replicate_deletion": false,
  "speed": -1,
  "enabled": true
}
```

The trigger `event_based` makes Harbor's `core` component start the rule on every matching push. Send the rule to Harbor:

```sh
harbor_api POST /replication/policies --data-binary @- < replication-rule-release-to-mirror.json -w '%{http_code}\n'
```

Harbor answers `201`. In the web portal, the same rule is under **Administration**, **Replications**, with the trigger "Event Based" and the destination flattening "Flatten 1 Level".

## Step 4: Prove it with two pushes

Push one release tag and one development tag. `regctl image mod` with `--create` makes a new tag from `6.15.0`; the changed annotation gives each tag its own digest:

```sh
ws regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
ws regctl image mod harbor.localtest.me:8443/inventory/podinfo:6.15.0 --create v1.1.0 --annotation org.example.build=v1.1.0
ws regctl image mod harbor.localtest.me:8443/inventory/podinfo:6.15.0 --create dev-42 --annotation org.example.build=dev-42
```

Wait about half a minute, then list the mirror:

```sh
ws regctl registry set mirror.localtest.me:5001 --tls disabled
ws regctl tag ls mirror.localtest.me:5001/inventory/podinfo
```

The list holds `v1.1.0` and not `dev-42`. If it is empty, check the executions with `wst harbor replication executions list`: a new execution with the trigger `event_based` should be there. The tag `v1.0.0` that existed before the rule is not in the mirror either, because an event-based rule copies only what is pushed after it exists. That is fine for this task.

The `harbor` CLI (version 0.0.27) draws lists and views as a table only on a terminal, so these commands run through `wst`, which adds `-t` (a terminal) to `kubectl exec`.

## Step 5: Submit

Send the lab for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| A manual rule started after each release | The first release nobody remembers never reaches the mirror; the grader pushes a tag and does not start the rule |
| Tag filter `*` | Development builds reach the mirror too |
| Name filter `podinfo` | It matches no repository, because the name filter tests the full name `inventory/podinfo` |
| No flattening | The copies arrive as `inventory/inventory/podinfo`, a path the operations team does not pull |

## Common mistakes

- Forgetting `"decoration": "matches"` on the tag filter, or using `excludes`, which turns the filter around.
- Creating the rule disabled, or leaving it disabled after a test.
- Copying a tag with `regctl image copy` when the tag already points at the same digest under another name, and then deleting it: deleting an artifact deletes every tag on that digest.

## Practice on your own

- Turn on delete replication, delete `v1.1.0` in Harbor, and watch it leave the mirror.
- Add a label filter and check that changing a label does not start the rule.
- Start the rule by hand and compare the execution's trigger with the event-based ones.
