# Preheat Policies, Triggers And Executions

An instance tells Harbor which P2P engine to use. It does not say which images are worth preheating. Preheating everything would fill the seed peers with development builds nobody deploys. A **preheat policy** selects the artifacts and decides when to send them. This part writes a policy that preheats every release of `inventory/podinfo` when it is pushed, and reads what each run does.

## What a policy holds

A project administrator creates preheat policies in the project's **P2P Preheat** tab. Each policy belongs to one project and uses one instance:

| Setting | What it decides |
| --- | --- |
| Provider | The P2P provider instance that receives the preheat requests |
| Filters | Which repositories, tags and labels of the project are selected |
| Criteria | Optional conditions: only signed artifacts, or no vulnerabilities at or above a chosen severity |
| Trigger | Manual, scheduled, or event based |
| Scope | Which Dragonfly peers receive the image: a single seed peer, all seed peers, or all peers |

The filters use the same patterns as replication filters: `*` stops at `/`, `**` does not. A policy with the tag filter `v*` selects only release tags. The criteria let you refuse to preheat an image that would be blocked anyway, for example one with critical vulnerabilities. The trigger works like a replication rule's trigger: an event-based policy runs when a matching artifact is pushed to the project.

## Write the policy

The REST API stores a policy's filters and trigger as JSON strings inside the JSON object, that is, JSON written as text, with its quotes escaped. First get the project's id and the instance's id. The commands use the `ws` and `harbor_api` helpers; define them again in a new terminal:

<!-- astrona:playground:renew -->

```sh
harbor_api GET /projects/inventory | ws jq '.project_id'
harbor_api GET /p2p/preheat/instances/dragonfly | ws jq '.id'
```

Save this as `preheat-policy-release-preheat.json`, with `<PROJECT_ID>` and `<INSTANCE_ID>` replaced by the two numbers:

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

The repository filter `**` selects every repository of the project, and the tag filter `v*` keeps only releases. Send the policy to Harbor:

```sh
harbor_api POST /projects/inventory/preheat/policies --data-binary @- < preheat-policy-release-preheat.json -w '%{http_code}\n'
```

Harbor answers `201`. List the project's policies with the CLI:

```sh
ws harbor project preheat policy list inventory
```

The list shows `release-preheat` with its instance and trigger. In the web portal, the same policy is in the project's **P2P Preheat** tab, where you can also set the scope.

## Executions and what they show

Every run of a policy is an **execution**, and every artifact sent to the engine is a task, as with replication. Push a release tag and look at the executions:

```sh
ws regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
ws regctl image copy harbor.localtest.me:8443/inventory/podinfo:6.15.0 harbor.localtest.me:8443/inventory/podinfo:v1.2.0
ws harbor project preheat execution list inventory release-preheat
```

The push of `v1.2.0` was the event, and an execution for it appears in the list. In this playground, the execution does not end with `Success`. The instance uses no token, and the seed peer does not trust Harbor's certificate, so Dragonfly cannot complete the preheat. The execution's task log, in the web portal under the policy's executions, names the error Dragonfly returned. In a real installation with a token and a trusting seed peer, the same execution ends with `Success`, and the seed peer holds the image.

You can now register an engine and write a policy that preheats exactly the releases you want, on push. Everything Harbor decides is in place; the rest, a token and a trusted seed peer, is Dragonfly's side.

## Common pitfalls

> [!WARNING]
> - **The tag filter `**` or `*`.** It preheats every development build and fills the seed peers. Select releases only.
> - **Filters and trigger as JSON objects in the API.** The API expects both as JSON strings. A plain object is refused.
> - **A manual trigger for a release pipeline.** Nobody remembers to start it. Use the event-based trigger, or a schedule if releases are batched.
> - **Reading a failed execution as a broken policy.** Check the task log first: a missing token or an untrusted Harbor certificate fails at Dragonfly, not in the policy.

## Your mission: Preheat Release Tags With Dragonfly

You can now register Dragonfly as a P2P provider instance and write a preheat policy with precise filters and an event-based trigger. The graded lab gives you Harbor and a running Dragonfly that know nothing of each other, and asks you to connect them so every release is preheated on push.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-103-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS103.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-103-lab-030-01
astrona start ats-103-playground-030-01
```
