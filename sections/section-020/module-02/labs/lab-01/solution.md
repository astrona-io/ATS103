# Solution: Serve A Private Team Cache

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: a private proxy cache project that uses the endpoint `docker-hub`, a cached `library/alpine` in it, and a pull-only project robot account.

## Step 1: Define the helpers and find the endpoint

Every Harbor command runs in the `workstation` pod. Define the helpers, then read the endpoint's id:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
wst() { kubectl -n workstation exec -it deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
harbor_api GET '/registries?page_size=100' | ws jq '.[] | {id, name, type}'
```

The list holds the endpoint `docker-hub`. Note its id. The endpoint stays as it is.

## Step 2: Create the private proxy cache project

A proxy cache project is a project that has a `registry_id`. A project is private when its `public` metadata is `false`. Save this as `project-hub-private.json`, with `<HUB_ID>` replaced by the endpoint's id:

```json
{
  "project_name": "hub-private",
  "registry_id": <HUB_ID>,
  "metadata": { "public": "false" }
}
```

Create the project:

```sh
harbor_api POST /projects --data-binary @- < project-hub-private.json -w '%{http_code}\n'
```

Harbor answers `201`.

## Step 3: Pull alpine through the cache

Sign `regctl` in as the administrator, then copy the image to a local folder in the workstation. The pull path has the project name and then the Docker Hub path, which includes `library/` for an official image:

```sh
ws regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
ws regctl image copy harbor.localtest.me:8443/hub-private/library/alpine:3.22 ocidir:///tmp/alpine-through-private-cache
```

Check that the repository exists in the project:

```sh
harbor_api GET '/projects/hub-private/repositories?page_size=100' | ws jq -r '.[].name'
```

The list holds `hub-private/library/alpine`.

## Step 4: Create the pull-only robot account

Save this as `robot-puller.json`:

```json
{
  "name": "puller",
  "description": "Pull-only account for the build machines",
  "level": "project",
  "duration": 30,
  "disable": false,
  "permissions": [
    {
      "kind": "project",
      "namespace": "hub-private",
      "access": [
        { "resource": "repository", "action": "pull" }
      ]
    }
  ]
}
```

Create the account and note the secret in the answer:

```sh
harbor_api POST /robots --data-binary @- < robot-puller.json | ws jq '{name, secret}'
```

The full name is `robot$hub-private+puller`. Test it, replacing `<SECRET>`:

```sh
ws regctl registry login harbor.localtest.me:8443 -u 'robot$hub-private+puller' -p '<SECRET>'
ws regctl image copy harbor.localtest.me:8443/hub-private/library/alpine:3.22 ocidir:///tmp/alpine-as-robot
```

The copy works. Sign `regctl` in as `admin` again afterwards.

## Step 5: Submit

Send the lab for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| A public project | Anyone who can reach Harbor can pull through the cache and use up the team's Docker Hub allowance |
| The administrator account on the build machines | One leaked secret gives full control of Harbor |
| A robot account with push or delete permission | A proxy cache project is read-only, and the extra permissions are not needed |
| A normal project with an endpoint added later | A project is a proxy cache only when it is created as one |

## Common mistakes

- Leaving out `library/` in the pull path.
- Giving the robot account a system-level scope instead of a project-level one.
- Forgetting to save the secret. Harbor shows it only once.
