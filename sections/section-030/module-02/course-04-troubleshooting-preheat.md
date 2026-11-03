# Troubleshooting Preheat

Preheating involves Harbor, a network path and Dragonfly, so a failure can come from any of the three. The skill is to find the side first. This part gives a short order of checks and reproduces three failures in the playground.

## The order of checks

1. **Is the instance healthy?** The instance's health tells you whether Harbor reaches the manager. If it is not, fix the endpoint before looking at policies.
2. **Does the policy select anything?** A policy with a filter that matches nothing creates an execution with no tasks, or no execution at all.
3. **Did the trigger fire?** A scheduled policy runs at its time and an event-based one runs on a push. The execution list shows whether it did.
4. **What does the task log say?** A task that failed carries the error from Dragonfly. It names a missing token, a rejected request, or a certificate problem.
5. **Can the seed peer reach Harbor?** The seed peer must resolve Harbor's name and trust its certificate.

Most failures end at the first, second or fourth question.

## Reproduce an unhealthy instance

Define the helpers from the earlier parts. Register an instance with the gRPC port in place of the REST port:

<!-- astrona:playground:renew -->

```sh
harbor_api POST /p2p/preheat/instances -w '%{http_code}\n' --data '{"name":"wrong-port","vendor":"dragonfly","endpoint":"http://dragonfly-manager.dragonfly-system.svc.cluster.local:65003","auth_mode":"NONE","enabled":true,"insecure":true,"default":false}'
harbor_api POST /p2p/preheat/instances/ping -o /dev/null -w '%{http_code}\n' --data '{"vendor":"dragonfly","endpoint":"http://dragonfly-manager.dragonfly-system.svc.cluster.local:65003","auth_mode":"NONE","insecure":true}'
```

Harbor creates the instance and answers `201`. The ping fails with a status other than `200`, because that port speaks gRPC, not HTTP. Compare it with the correct address:

```sh
harbor_api POST /p2p/preheat/instances/ping -o /dev/null -w '%{http_code}\n' --data '{"vendor":"dragonfly","endpoint":"http://dragonfly-manager.dragonfly-system.svc.cluster.local:8080","auth_mode":"NONE","insecure":true}'
```

The ping answers `200`. Remove the wrong instance before you go on:

```sh
harbor_api DELETE /p2p/preheat/instances/wrong-port -w '%{http_code}\n'
```

## Reproduce a policy that selects nothing

Create a policy whose tag filter cannot match any tag in the project, then start it. Replace the ids as before:

```json
{
  "name": "never-matches",
  "project_id": <PROJECT_ID>,
  "provider_id": <INSTANCE_ID>,
  "filters": "[{\"type\":\"repository\",\"value\":\"**\"},{\"type\":\"tag\",\"value\":\"release-*\"}]",
  "trigger": "{\"type\":\"manual\",\"trigger_setting\":{\"cron\":\"\"}}",
  "enabled": true
}
```

After you create it and start it by hand, list its executions and their tasks. The tasks list is empty, because no tag starts with `release-`. This is the usual cause of a policy that "does nothing": the filter did not match, not Dragonfly.

## Reproduce a certificate failure

The policy `nightly-preheat` selects `v1.0.0`. Start it by hand and read the task log in the web portal. The log ends with an error from the seed peer when it tries to download from Harbor over TLS. The fix is on the seed peer: it must trust Harbor's certificate authority. Until then, no policy can succeed, and that fact tells you not to change the policy.

## What to change where

| Symptom | Where to fix it |
| --- | --- |
| Instance ping fails | The instance: endpoint, port, authentication |
| Execution has no tasks | The policy: filters and criteria |
| No execution at the expected time | The trigger and the cron expression |
| Task fails with a certificate or name error | The seed peer: DNS and trust store |
| Task fails with an authentication error | The instance's auth mode and the Dragonfly token |

You now have a short procedure for any preheat problem. It keeps you from changing Harbor settings when the cause is in Dragonfly, and the other way round.

## Common pitfalls

> [!WARNING]
> - **Changing the policy first.** Check the instance and the task log before you edit a filter.
> - **Leaving test instances and policies behind.** Delete `wrong-port` and `never-matches` when you finish.
> - **Reading "healthy" as "will succeed".** A healthy instance only proves that Harbor reaches the manager.
