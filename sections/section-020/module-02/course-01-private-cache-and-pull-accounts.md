# Private Cache Projects And Pull Accounts

A public proxy cache project lets anyone who can reach Harbor use your Docker Hub allowance, and lets Harbor fetch what the endpoint's account can reach on behalf of strangers. A private project closes that door. This part creates the endpoint and a private cache project, shows what an unauthenticated pull does, and gives the build machines a robot account that can do nothing but pull.

## Public and private projects

Every Harbor project is public or private. Anyone can pull from a **public** project without signing in. Only project members, and accounts with a permission in the project, can pull from a **private** project. The setting is the same for a proxy cache project and a normal one. A proxy cache project adds one rule on top: nobody can push to it, not even a project administrator.

For a team cache, private is the safe choice. Each pull through the cache costs a request to Docker Hub, and an open cache gives that allowance to everyone on the network.

## Create the endpoint and a private cache project

The commands use the `ws` and `harbor_api` helpers; define them again in a new terminal. They sign the Harbor CLI in, create the Docker Hub endpoint, read its id, and create a private proxy cache project named `team-cache`:

<!-- astrona:playground:renew -->

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
ws harbor login https://harbor.localtest.me:8443 -u admin -p Harbor12345
ws harbor registry create --name docker-hub --type docker-hub --url https://hub.docker.com
HUB_ID="$(harbor_api GET '/registries?page_size=100' | ws jq -r '.[] | select(.name=="docker-hub") | .id')"
ws harbor project create team-cache --storage-limit -1 --proxy-cache --registry-id "$HUB_ID"
```

The last command has no `--public`, so the project is private. Read it back to confirm both facts, the private setting and the endpoint:

```sh
harbor_api GET /projects/team-cache | ws jq '{name, registry_id, public: .metadata.public}'
```

The answer shows `"public": "false"` and the id of the Docker Hub endpoint as `registry_id`.

## What an unauthenticated pull does

Try to pull `alpine:3.22` through the private project without signing in. Remove any saved login first, then copy:

```sh
ws regctl registry logout harbor.localtest.me:8443
ws regctl image copy harbor.localtest.me:8443/team-cache/library/alpine:3.22 ocidir:///tmp/alpine-anonymous
```

The copy fails, and `regctl` prints the refusal that Harbor returned: the request had no credentials, and the project is private. Harbor did not contact Docker Hub for it. A rejected pull costs nothing upstream.

## Give the build machines their own account

The build machines need an account that is not a person's. A **robot account** is a Harbor account made for software: it has a name, a secret and a list of permissions, and an optional expiry. A project robot account belongs to one project. Save this as `robot-puller.json`:

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
      "namespace": "team-cache",
      "access": [
        { "resource": "repository", "action": "pull" }
      ]
    }
  ]
}
```

Create the account. The answer holds the full name, `robot$team-cache+puller`, and the secret. Harbor shows the secret once, so copy it now:

```sh
harbor_api POST /robots --data-binary @- < robot-puller.json | ws jq '{name, secret}'
```

Sign in as the robot and pull. Replace `<SECRET>` with the secret from the answer:

```sh
ws regctl registry login harbor.localtest.me:8443 -u 'robot$team-cache+puller' -p '<SECRET>'
ws regctl image copy harbor.localtest.me:8443/team-cache/library/alpine:3.22 ocidir:///tmp/alpine-as-robot
```

This time the pull works. Harbor accepted the robot's credentials, did not find the image in the cache, fetched it from Docker Hub, stored it and returned it. The robot can pull but cannot push, delete or change settings, and a proxy cache project would refuse its pushes anyway.

You can now run a cache that only your own machines use, with an account that holds the least power it needs. The administrator account stays out of the build pipeline, and the secret of one pipeline can be rotated or disabled without touching anyone else.

## Common pitfalls

> [!WARNING]
> - **A public cache project for a team cache.** Everyone who can reach Harbor can use the team's Docker Hub allowance.
> - **The administrator account on build machines.** One leaked secret gives full control of Harbor.
> - **Losing the robot secret.** Harbor shows it once. Create a new account or refresh the secret.
> - **A robot account that never expires.** Choose an expiry, and plan its renewal.
> - **Typing the robot name without `robot$` and the project.** The full name is `robot$<project>+<name>`.

## Your mission: Serve A Private Team Cache

You can now create a private proxy cache project and a pull-only robot account for it. The graded lab gives you Harbor with a Docker Hub endpoint and nothing else, and asks you to build the private cache, cache `alpine:3.22` in it, and create the robot account.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-103-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS103.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-103-lab-020-02
astrona start ats-103-playground-020-02
```
