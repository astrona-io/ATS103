# Section 010: Registry Endpoints And Replication

One registry is rarely enough. A team keeps a copy of its release images in a second data centre, a customer wants the images in their own registry, or a build system in another region needs them close by. Copying them by hand with a pull and a push works once. It does not work for every release, every day, without anyone forgetting a tag.

Harbor does this copying itself. You tell it where the other registry is with a **registry endpoint**, and what to copy, when and where with a **replication rule**. This section builds both from scratch against a second registry in the cluster, the mirror, and then shows how to find out what a rule did and why a copy failed.

**Topic covered:** Replication

## What you will learn

- What a registry endpoint holds, which providers Harbor can talk to, and how to test an endpoint.
- The difference between push-based and pull-based replication.
- Writing name and tag filters with `*`, `**`, `?` and `{a,b}`, and choosing a destination namespace and a flattening level.
- The options of a rule: override, delete replication, bandwidth and copy by chunk.
- The manual, scheduled and event-based triggers, and when each one fits.
- Reading executions, tasks and task logs with the Harbor CLI and the REST API, and finding the jobservice component that runs them.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Replicate Artifacts Between Registries

The module starts at its landing page, which also launches the playground. The playground holds Harbor with the project `inventory` and the repository `inventory/podinfo`, and an empty mirror registry. Harbor does not know about the mirror yet.

1. Registry Endpoints And Providers
2. Replication Rules, Filters And Flattening
3. Triggers, Executions And Logs, followed by the lab **Replicate Release Tags To A Mirror**
4. Summary

## Section capstone: Repair A Replication Pipeline

The capstone is one graded scenario that combines the whole module. A colleague set up release replication to the mirror before going on holiday. Releases have not reached the mirror since, and a release that was withdrawn in Harbor is still in the mirror. The endpoint and the rule both exist, and nothing reports an error until you look at the executions. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS103.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-103-capstone-010
```
