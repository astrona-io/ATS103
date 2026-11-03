# Cache Retention And Garbage Collection

A cache grows with use. Two mechanisms keep it in check: the retention policy removes artifacts that are no longer pulled, and garbage collection frees the disk space that removed artifacts used. This part shows how they work together.

## Retention removes the reference

A proxy cache project has a default retention policy that keeps artifacts pulled within the last 7 days. When it removes an artifact, the artifact disappears from the project and its size no longer counts toward the project's quota. The next pull of the image fetches it from the upstream again.

## Garbage collection frees the space

Deleting an artifact does not remove its layers from the storage right away. **Garbage collection** (GC) is a system job that deletes layers no artifact refers to. Without it, the storage of Harbor keeps growing even when the quota shows free space. GC is a system administrator task, and it can run on a schedule.

Start a GC run by hand through the API. The helpers are the ones from the earlier parts, and the call needs the administrator account:

<!-- astrona:playground:renew -->

```sh
harbor_api POST /system/gc/schedule -w '%{http_code}\n' --data '{"schedule":{"type":"Manual"},"parameters":{"delete_untagged":true}}'
harbor_api GET /system/gc?page_size=5 | ws jq '.[] | {id, job_status, creation_time}'
```

The first command requests a manual run and answers `200`. The second lists the latest GC runs with their status. In a registry that is in use, schedule GC for a quiet hour, because Harbor is in a read-heavy state while the job runs.

## A plan for a team cache

1. Set a quota that is a fraction of the disk.
2. Keep the default retention, or shorten it when the disk is small.
3. Schedule GC daily or weekly.
4. Watch the quota and the GC results in the audit log and the system job list.

## Common pitfalls

> [!WARNING]
> - **Expecting retention to free disk.** It frees quota; GC frees the disk.
> - **Never scheduling GC.** The storage fills while the quota looks fine.
> - **Running GC in a busy hour.** Plan it for a quiet one.
