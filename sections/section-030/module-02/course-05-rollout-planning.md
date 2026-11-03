# Planning Preheat For A Rollout

A preheat policy only helps if it finishes before the rollout needs the image. This part gives a way to plan the timing, the selection and the load so that it does.

## Work backwards from the rollout

Write down the time of the rollout, and subtract the time a preheat takes. A preheat of a large image can take minutes, since the seed peer has to download every layer from Harbor. Run the policy with enough margin that a failure can be seen and repaired before the rollout.

| Step | Example |
| --- | --- |
| Rollout starts | 06:00 |
| Preheat must be done | 05:00 |
| Policy runs | 02:00, with the scheduled trigger |
| Check the result | 08:00 the day before, or an alert after the run |

## Choose the selection

Select only what the rollout will use. A policy for release tags with a repository filter for the services in the rollout sends a fraction of what a policy for the whole project would. Use criteria to leave out unsigned images or images with severe vulnerabilities, since those will not be deployed.

## Choose the scope

For a cluster with one seed peer, the scope makes no difference. With several seed peers, "all seed peers" gives every site its copy. Send to "all peers" only when the next rollout is close and the nodes have disk to spare.

## Verify the result

After a run, read the execution and its tasks. The helpers are the ones from the earlier parts:

<!-- astrona:playground:renew -->

```sh
harbor_api GET '/projects/inventory/preheat/policies/nightly-preheat/executions?page_size=5' | ws jq '.[] | {id, status, trigger, start_time, end_time}'
```

The start and end times show how long the run took, which is the number to use when you plan the next margin.

## Common pitfalls

> [!WARNING]
> - **A schedule that ends after the rollout starts.** Plan backwards from the rollout.
> - **Preheating the whole project.** Select what the rollout uses.
> - **Never reading the result.** A failed run is found at rollout time.
