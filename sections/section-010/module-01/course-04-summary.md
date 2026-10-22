# Summary

Harbor copies artifacts between registries with two objects and one background component. This module built both objects against a second registry and read the record of what they did.

## What you learned

A registry endpoint is Harbor's record of a remote registry: a provider, a URL, credentials and whether to verify the remote certificate. The provider decides which API Harbor speaks, so the right URL with the wrong provider still fails. Harbor reports its providers through `/replication/adapters`, and those short names, such as `docker-registry`, `docker-hub` and `harbor`, are what the CLI and the API expect. The Test Connection check, `POST /registries/ping`, proves that Harbor can reach the registry behind an endpoint.

A replication rule says what to copy, in which direction and under which name. A push rule copies Harbor's artifacts to an endpoint; a pull rule copies an endpoint's artifacts into Harbor. Name and tag filters use `*`, `**`, `?` and `{a,b}`, where `*` stops at `/` and `**` does not. The destination namespace and the flattening level together decide the destination path, so `inventory/podinfo` with the namespace `inventory` arrives as `inventory/podinfo` with one level of flattening and as `inventory/inventory/podinfo` with none.

A rule runs on a trigger. Manual and scheduled rules copy what exists when they run and never copy deletions. An event-based rule runs when `core` sees a push or a retag that matches it, and with delete replication turned on it also removes artifacts at the endpoint that were deleted in Harbor. Every run is an execution, every copied artifact is a task, and `jobservice` writes a log for each task. The key facts to remember are these:

- The endpoint says where, the rule says what and when, and the execution log says what really happened.
- Only event-based rules with delete replication turned on copy deletions.
- An execution with zero tasks means the filters matched nothing.
- Between two Harbor installations, the provider is `harbor`, the destination project must already exist, and copy by chunk is available.

<!-- astrona:playground:destroy -->
