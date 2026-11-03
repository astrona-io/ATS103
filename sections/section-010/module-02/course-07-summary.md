# Summary

Harbor can fetch artifacts from a remote registry as well as send them to one. This module built a pull rule against a supplier's registry, shaped the way it copies, ran it on a schedule, and diagnosed its failures.

## What you learned

A pull rule is a replication policy that sets `src_registry` and leaves `dest_registry` out. The endpoint is the source and a Harbor project is the destination. The name filter tests names at the source, and the destination namespace with the flattening level decides the name in Harbor, so `vendor/tools` with the namespace `vendored` and one level of flattening arrives as `vendored/tools`.

The options of a rule shape each copy. Override decides whether a changed source tag replaces the copy in the destination. The bandwidth limit caps each task in kilobytes per second. The resource filter selects images, charts or every OCI artifact, and the label filter selects by Harbor label and works only when the source is a Harbor. The filters of a rule combine with AND, and copy by chunk is available only between two Harbors.

A pull rule is manual or scheduled, because Harbor sees no events at a remote registry. A scheduled rule uses a cron expression with six fields, starting with the seconds, in the time zone of Harbor's `core` component. It copies what exists at the time of the run and never copies deletions. An execution you start by hand copies the same artifacts as a scheduled one.

When a run fails, the execution list shows that something failed, the task list shows which artifact, and the task log shows why. The key facts to remember are these:

- A pull rule sets `src_registry`; a push rule sets `dest_registry`.
- Harbor's cron expression has six fields and starts with the seconds.
- An execution with zero tasks succeeds; check the filters first.
- Fix the endpoint or the destination in place and start a new execution; do not recreate the rule.

<!-- astrona:playground:destroy -->
