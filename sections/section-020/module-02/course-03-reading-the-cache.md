# Reading The Cache: Artifacts, Quota And Audit Logs

After a cache has run for a while, questions arrive. What does it hold, how much space does it use, which images does nobody pull any more, and who pulled what? Harbor keeps the answers in the artifact records, the project's quota and its audit log. This part reads each one.

## What the cache holds

The cache stores each image as an artifact in a repository, like any Harbor project, with a size and a time of the last pull. Pull one small image so that there is something to read, then list the repositories of the project:

<!-- astrona:playground:renew -->

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
ws regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
ws regctl image copy harbor.localtest.me:8443/team-cache/library/alpine:3.22 ocidir:///tmp/alpine-read
harbor_api GET '/projects/team-cache/repositories?page_size=100' | ws jq '.[] | {name, artifact_count, pull_count}'
```

The commands need the project `team-cache` from the first part. The answer lists the repository `team-cache/library/alpine` with its number of artifacts and the number of pulls. Now list the artifacts of that repository with their size and time of last pull:

```sh
harbor_api GET '/projects/team-cache/repositories/library%252Falpine/artifacts?with_tag=true' \
  | ws jq '.[] | {digest, size, push_time, pull_time, tags: [.tags[]?.name]}'
```

Each artifact has a digest, the size in bytes and two times. The `push_time` is when Harbor stored the copy, and the `pull_time` is when someone last pulled it. Harbor's default retention policy for a cache project uses the pull time, so an artifact with an old `pull_time` is the next to expire. The repository name is encoded twice in the URL, `%252F` for the `/` in `library/alpine`, because the API decodes it twice.

## Quota

A project has a storage **quota**, a limit on the bytes its artifacts may use. Harbor counts a cached image like any other artifact. Read the quota of the project and set a limit:

```sh
PROJECT_ID="$(harbor_api GET /projects/team-cache | ws jq -r '.project_id')"
harbor_api GET "/quotas?reference=project&reference_id=$PROJECT_ID" | ws jq '.[] | {hard, used}'
```

The answer shows the limit under `hard` and the use under `used`, both in bytes. A `hard` storage value of `-1` means no limit. To set a limit of 1 GiB, send the new value to the quota with the quota's `id` from the same answer:

```sh
harbor_api PUT /quotas/<QUOTA_ID> --data '{"hard":{"storage":1073741824}}' -w '%{http_code}\n'
```

Harbor answers `200`. Once a cache project reaches its limit, Harbor cannot store the next image it needs, and the pull for that image fails even though Docker Hub is healthy. Set a limit that is a fraction of the disk, and let the retention policy keep the cache within it.

## Audit logs

Harbor's **audit log** records who did what in a project. A pull through a cache is one of the recorded operations. Read the most recent entries of the project:

```sh
harbor_api GET '/projects/team-cache/logs?page_size=10' | ws jq '.[] | {op_time, username, operation, resource}'
```

Each entry shows the time, the account name, the operation (`create`, `pull`, `delete`) and the resource. The entries for the pull show your account and the image path. When the build machines use a robot account, the log shows the robot's name, which tells you which pipeline caused the traffic. This is the reason to give each pipeline its own account.

You can now see what the cache holds, how much room it takes and who uses it. That is enough to decide on a retention policy, a quota and the right number of accounts.

## Common pitfalls

> [!WARNING]
> - **Reading the cache size as the Docker Hub size.** The cache holds only what was pulled through it.
> - **Writing `library/alpine` once in the URL.** The API wants the slash encoded twice, as `library%252Falpine`.
> - **A quota with no retention.** The cache fills up and then fails the next pull.
> - **One shared account for every pipeline.** The audit log can then not tell the pipelines apart.
