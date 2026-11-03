# Summary

A preheat policy decides what to send and when, and Dragonfly does the work. This module covered the triggers, the selection tools, the path of a preheat and the checks that tell a Harbor problem from a Dragonfly problem.

## What you learned

There are three triggers. A manual policy runs only when started, a scheduled policy runs at the times of a cron expression, and an event-based policy runs when a matching artifact is pushed, labeled or scanned. Harbor's cron has six fields with the seconds first, so a five-field Linux expression has the wrong meaning. Any policy can be started by hand through the executions endpoint, which is how you test it. In the REST API, the preheat trigger field is `trigger_setting` and the replication field is `trigger_settings`.

A policy selects artifacts with repository, tag and label filters, which an artifact must all match. Criteria add conditions on signatures and vulnerability severity. The scope sets which Dragonfly peers receive the image: a single seed peer, all seed peers or all peers. A filter you did not test is the most common reason for a policy that does nothing.

A preheat goes from Harbor's job service to the Dragonfly manager, then to a scheduler, and a seed peer downloads the image from Harbor. Executions and tasks report the states `Pending`, `Running`, `Success`, `Failed` and `Stopped`, and the task log holds Dragonfly's error text. A real preheat needs a token and a seed peer that resolves Harbor and trusts its certificate. The key facts to remember are these:

- Test a policy with a manual run before the first scheduled one.
- An execution with no tasks means the filters selected nothing.
- A failed task usually means a Dragonfly or seed peer setting, not a Harbor policy.
- Check the instance, the selection and the task log, in that order.

<!-- astrona:playground:destroy -->
