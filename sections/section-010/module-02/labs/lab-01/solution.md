# Solution: Pull Vendor Images On A Schedule

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the rule's settings, that the rule, when started, brings the stable tags into `vendored/tools` and leaves `nightly` out, and that only `vendor/tools` arrives, under the right path.

## Step 1: Define the helpers and look at the source

Every Harbor command runs in the `workstation` pod. Define the helpers, then list what the mirror holds and what Harbor knows:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
wst() { kubectl -n workstation exec -it deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
ws regctl registry set mirror.localtest.me:5001 --tls disabled
ws regctl repo ls mirror.localtest.me:5001
ws regctl tag ls mirror.localtest.me:5001/vendor/tools
harbor_api GET '/registries?page_size=100' | ws jq '.[] | {id, name, type, url}'
```

The mirror holds `vendor/debug` and `vendor/tools`, and `vendor/tools` has the tags `1.0.0`, `1.1.0` and `nightly`. Note the id of the endpoint `mirror`.

## Step 2: Work out the filters, the path and the schedule

The name filter `vendor/tools` matches that one repository, because the name filter tests the full source name. The tag filter `1.*` with the decoration `matches` keeps `1.0.0` and `1.1.0` and leaves out `nightly`.

For the path, the copy of `vendor/tools` must arrive as `vendored/tools`. The destination namespace `vendored` with one level of flattening does that: the first level of the source path, `vendor`, is replaced by `vendored`. Without flattening, the copy would arrive as `vendored/vendor/tools`.

Harbor writes a schedule as a cron expression with six fields, and the first field is the seconds. Every hour on the hour is `0 0 * * * *`: second 0, minute 0, every hour, every day, every month, every weekday.

## Step 3: Create the rule

Save this as `replication-rule-pull-vendor-tools.json`, with `<MIRROR_ID>` replaced by the endpoint's id:

```json
{
  "name": "pull-vendor-tools",
  "description": "Stable releases of vendor/tools every hour",
  "src_registry": { "id": <MIRROR_ID> },
  "dest_namespace": "vendored",
  "dest_namespace_replace_count": 1,
  "filters": [
    { "type": "name", "value": "vendor/tools" },
    { "type": "tag", "value": "1.*", "decoration": "matches" }
  ],
  "trigger": { "type": "scheduled", "trigger_settings": { "cron": "0 0 * * * *" } },
  "override": true,
  "replicate_deletion": false,
  "deletion": false,
  "speed": -1,
  "enabled": true
}
```

A pull rule sets `src_registry` and leaves `dest_registry` out, because the destination is this Harbor. Send the rule to Harbor:

```sh
harbor_api POST /replication/policies --data-binary @- < replication-rule-pull-vendor-tools.json -w '%{http_code}\n'
```

Harbor answers `201`.

## Step 4: Start the rule and check the result

A scheduled rule waits for its next hour, so start it by hand to prove it works. Get its id, start an execution, wait about half a minute and list the project:

```sh
harbor_api GET '/replication/policies?page_size=100' | ws jq '.[] | select(.name=="pull-vendor-tools") | .id'
harbor_api POST /replication/executions --data '{"policy_id":<RULE_ID>}' -w '%{http_code}\n'
harbor_api GET '/projects/vendored/repositories?page_size=100' | ws jq -r '.[].name'
harbor_api GET '/projects/vendored/repositories/tools/artifacts?with_tag=true' | ws jq -r '[.[] | .tags[]? | .name]'
```

The start answers `201`. The repository list holds `vendored/tools`, and its tags are `1.0.0` and `1.1.0`. If the list is empty, read the execution with `wst harbor replication executions list` and the task log with the REST API.

## Step 5: Submit

Send the lab for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| A push rule created at the mirror's end | Harbor is the destination here, so the rule must be a pull rule with `src_registry` |
| Tag filter `*` | `nightly` enters Harbor too |
| Name filter `vendor/*` | `vendor/debug` enters Harbor too |
| No flattening | The copies arrive as `vendored/vendor/tools` |
| The cron expression `0 * * * *` | It has five fields, and Harbor needs six with the seconds first |

## Common mistakes

- Forgetting `"decoration": "matches"` on the tag filter.
- Writing the schedule in the five-field form.
- Creating the rule with a manual trigger because "I will start it myself".
