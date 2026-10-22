# Summary

Harbor can hand new images to a P2P engine before any node needs them. This module looked at what P2P distribution and preheating do, and connected Harbor to Dragonfly with an instance and a policy.

## What you learned

When many nodes pull the same image at once, the registry's network link sets the speed of the rollout. P2P distribution lets nodes fetch image pieces from each other, so only a few copies come from the registry. Preheating goes further: the P2P engine fetches a new image as soon as it is released, so the pieces are ready before the rollout starts.

Dragonfly has four parts. The manager holds the configuration, offers the REST API on port `8080` and accepts preheat jobs. The scheduler decides which peer fetches which piece from where. Seed peers pull from the registry first, and peers on the nodes fetch pieces from them. Harbor talks only to the manager. Harbor 2.12 and later work with Dragonfly 2.1.59 and later; Kraken is the other supported engine.

A P2P provider instance is Harbor's record of an engine: vendor, endpoint, auth mode, whether it is enabled, and whether to check the engine's certificate. A healthy instance proves that Harbor reaches the manager. A preheat policy belongs to a project and selects artifacts with repository, tag and label filters, optional criteria for signatures and vulnerabilities, a trigger and a scope. In the REST API, the policy's filters and trigger are JSON strings. Every run is an execution with tasks and logs. A real preheat also needs a Dragonfly personal access token with the auth mode `OAUTH`, and seed peers that can resolve Harbor and trust its certificate. The key facts to remember are these:

- The instance says which engine; the policy says which artifacts and when.
- Point the instance at the manager's REST address, port `8080`, not its gRPC port.
- Preheat releases only, on push, with a tag filter such as `v*`.
- "Healthy" means reachable, not that a preheat will succeed.

<!-- astrona:playground:destroy -->
