# Section 030: P2P Preheating With Dragonfly

A rollout to a hundred nodes means a hundred nodes pulling the same image from the registry at the same moment. The registry's network link becomes the bottleneck, and the rollout waits for it. Peer-to-peer (P2P) distribution lets the nodes share the pieces of an image among themselves, so the registry sends each piece only a few times.

Preheating goes one step further: the P2P engine fetches the image before any node asks for it. Harbor can tell the engine what to fetch and when, through a **P2P provider instance** and a **preheat policy**. This section registers Dragonfly, a CNCF P2P engine, in Harbor and writes a policy that preheats every release.

**Topic covered:** P2P preheating

## What you will learn

- What P2P distribution and preheating are, and which problem each one solves.
- The parts of Dragonfly: manager, scheduler, seed peer and peer, and which of them Harbor talks to.
- Registering Dragonfly as a P2P provider instance, with its authentication modes, and checking its health.
- Writing a preheat policy with repository, tag and label filters, criteria, a trigger and a scope.
- What a real installation needs before a preheat execution succeeds: a Dragonfly personal access token and a seed peer that trusts Harbor.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, and the landing page starts it for you.

### 1. Preheat Images Into Dragonfly

The module starts at its landing page, which also launches the playground. The playground holds Harbor with the project `inventory`, and a minimal Dragonfly in the namespace `dragonfly-system`. Harbor does not know about Dragonfly yet.

1. P2P Distribution And Dragonfly
2. Registering Dragonfly As A Provider Instance
3. Preheat Policies, Triggers And Executions, followed by the lab **Preheat Release Tags With Dragonfly**
4. Summary

## Section capstone: Wire A Release Pipeline End To End

The capstone is one graded scenario that ties replication and preheating together. Every release of `inventory/podinfo` must reach the mirror registry and be preheated into Dragonfly as soon as it is pushed. The rule, the instance and the policy all exist, and none of them does anything on a push. Work it after the module lab. Its environment runs Harbor and Dragonfly together, so give your machine about 6 GiB of memory.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS103.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-103-capstone-030
```
