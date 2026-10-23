# Triggers, Executions And Logs

A rule that runs only when someone starts it will miss a release sooner or later. And a rule that ran tells you nothing about whether each copy worked, unless you know where to look. This part makes a rule run on every push, turns on the copying of deletions, and reads the record Harbor keeps of every run: executions, tasks and their logs.

## Three triggers

The **trigger** decides when a rule runs. Harbor has three:

| Trigger | When the rule runs | Deletions copied? |
| --- | --- | --- |
| Manual | When a person or a script starts it | No |
| Scheduled | On a schedule written as a cron expression | No |
| Event based | When an artifact is pushed or retagged in the source | Yes, if delete replication is turned on |

An event-based rule is the one that keeps a mirror current without anyone thinking about it. Harbor's `core` component sees each push, checks it against every event-based rule, and hands a copy job to `jobservice` straight away. Changing a label on an artifact does not trigger a rule, even when the rule filters on labels.

**Delete replication** (the setting "Delete remote resources when locally deleted", field `replicate_deletion`) works only with the event-based trigger. When it is on, deleting an artifact in Harbor also deletes it at the endpoint. That keeps a withdrawn release from staying available in the mirror.

## Make the rule event based

Change the rule `copy-6x` so that it runs on every push and copies deletions too. The REST API replaces a whole rule at once, so read it, change the two fields with `jq`, and send it back. The commands use the `ws` and `harbor_api` helpers; define them again in a new terminal. Replace `<RULE_ID>` with the rule's id:

<!-- astrona:playground:renew -->

```sh
harbor_api GET /replication/policies/<RULE_ID> \
  | ws jq -c '.trigger={"type":"event_based"} | .replicate_deletion=true' \
  | harbor_api PUT /replication/policies/<RULE_ID> --data-binary @- -w '%{http_code}\n'
```

Harbor answers `200`. Now push a new tag that matches the filter, without starting the rule. `regctl` can copy the existing artifact under a new tag inside Harbor; it signs in to Harbor first:

```sh
ws regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
ws regctl image copy harbor.localtest.me:8443/inventory/podinfo:6.15.0 harbor.localtest.me:8443/inventory/podinfo:6.15.1
ws regctl tag ls mirror.localtest.me:5001/inventory/podinfo
```

After a few seconds, `6.15.1` is in the mirror. Nobody started the rule: the push was the event, and `core` started an execution for it.

## Executions, tasks and logs

Every run of a rule is an **execution**, and every artifact copied in it is a **task**. A failed copy shows up as a failed task, so this is where you look when an artifact did not arrive. List the executions of all rules with the CLI. The `harbor` CLI (version 0.0.27) draws lists and views as a table only on a terminal, so this command runs through `wst`, which adds `-t` (a terminal) to `kubectl exec`:

```sh
wst() { kubectl -n workstation exec -it deploy/workstation -- "$@"; }
wst harbor replication executions list
```

Each line is one execution, with its id, the rule, its trigger, its status and how many tasks succeeded and failed. The event-based run from the last step is listed with the trigger `event_based`. To see the tasks of one execution, and the log of one task, use the REST API with the ids from the list:

```sh
harbor_api GET /replication/executions/<EXECUTION_ID>/tasks | ws jq '.[] | {id, status, src_resource, dst_resource}'
harbor_api GET /replication/executions/<EXECUTION_ID>/tasks/<TASK_ID>/log
```

The task list names each source artifact and where it went. The log is plain text written by `jobservice` while it copied: which blobs it uploaded, and, for a failed task, the error the remote registry returned. The CLI shows the same log with `ws harbor replication log --execution-id <EXECUTION_ID> --task-id <TASK_ID>`.

When even the execution is missing, look one level lower. The `jobservice` Deployment runs the copy jobs and logs every job it starts:

```sh
kubectl -n harbor logs deploy/harbor-jobservice --tail=20
```

The log lines name the replication jobs it ran. If a push to Harbor produced no execution at all, the rule did not match the push: check its trigger, whether it is enabled, and its filters.

## Replicating to another Harbor

The mirror stands in for a remote registry in this course. Between two Harbor installations, for example one per data centre, three things change. The endpoint's provider is `harbor` and its URL is the other Harbor's address, with a robot account of that Harbor as the credential. The destination namespace must be a project that exists there, because Harbor does not create projects in another Harbor. And copy by chunk becomes an option, because both sides are Harbor. Everything else in this module works the same way.

You can now build a rule that keeps a mirror current on its own, copies deletions, and prove each copy from its execution and its log. That is everything a release mirror needs.

## Common pitfalls

> [!WARNING]
> - **Expecting a scheduled or manual rule to copy deletions.** Only an event-based rule with delete replication turned on removes artifacts at the endpoint.
> - **Starting an event-based rule by hand to "fix" it.** A manual start copies what is there now. It does not prove that the next push will be copied.
> - **Looking only at the execution status.** An execution can succeed with zero tasks when the filters matched nothing. Look at the task list.
> - **Editing a rule while it runs.** Harbor refuses to edit or delete a rule with an execution in progress. Wait for it to finish, or stop it.

## Your mission: Replicate Release Tags To A Mirror

You can now write a push rule with precise filters, make it run on every push, and read its executions. The graded lab gives you Harbor with a working endpoint to the mirror and no rule, and asks you to make every release tag, and only release tags, reach the mirror on its own.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-103-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS103.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-103-lab-010-01
astrona start ats-103-playground-010-01
```
