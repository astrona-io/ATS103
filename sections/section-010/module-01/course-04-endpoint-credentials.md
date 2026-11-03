# Endpoint Credentials And Least Privilege

An endpoint stores a credential, and every rule that uses the endpoint acts with it. If the credential is the administrator account of the remote registry, then a mistake in a rule, or anyone who can edit the endpoint, has administrator power over the remote registry. This part explains what a credential must be able to do for each kind of rule, and creates a Harbor robot account that can do only that.

## What the credential must be allowed to do

The account in the endpoint does the work at the remote registry, so it needs exactly the rights that the rule's direction uses:

| Rule | The account at the remote registry must be able to |
| --- | --- |
| Push-based | Push and pull artifacts in the destination namespace, and delete them when delete replication is on |
| Pull-based | Pull artifacts from the source namespaces, and list their tags |
| Proxy cache | Pull from the upstream registry, and see only what the cache may expose |

The tests of a connection check only that the registry answers and the credential is accepted. They do not check that the account has the right to push or to delete. A rule can therefore pass its connection test and still fail on the first push. The task log names the refusal.

## Robot accounts

A **robot account** is a Harbor account made for software, not for a person. It has a name, a secret (a long random string), an optional expiry and a list of permissions. Harbor has two kinds. A **project robot account** belongs to one project and can hold permissions only in that project. A **system robot account** is created by an administrator and can hold permissions in several projects, or in all of them. The full name of a project robot is `robot$<project>+<name>`, and the secret is shown once, when Harbor creates the account.

Between two Harbor installations, the best credential for an endpoint is a robot account of the remote Harbor, with only the permissions the rule needs. It has no access to the web portal, it can expire, and an administrator can disable it without changing any person's password.

## Create a robot account with pull permission only

The commands use the `ws` and `harbor_api` helpers; define them again in a new terminal. Create a project robot account in the project `inventory` that can only pull repositories:

<!-- astrona:playground:renew -->

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
harbor_api() {
  local method="$1" path="$2"; shift 2
  ws curl -sS -u admin:Harbor12345 -X "$method" -H 'Content-Type: application/json' \
    "https://harbor.localtest.me:8443/api/v2.0$path" "$@"
}
```

Save this as `robot-inventory-reader.json`:

```json
{
  "name": "reader",
  "description": "Pull-only account for a remote replication rule",
  "level": "project",
  "duration": 30,
  "disable": false,
  "permissions": [
    {
      "kind": "project",
      "namespace": "inventory",
      "access": [
        { "resource": "repository", "action": "pull" }
      ]
    }
  ]
}
```

The `duration` is the number of days until the account expires; `-1` means never. Create the account:

```sh
harbor_api POST /robots --data-binary @- < robot-inventory-reader.json | ws jq '{name, id}'
```

Harbor answers with the full name `robot$inventory+reader` and the account's id. The answer also holds a `secret`, which the command above filters out on purpose. Save the secret when you create a real account, because Harbor does not show it again.

## Prove that the account can do only that

Sign `regctl` in as the robot account and try one read and one write. Replace `<SECRET>` with the account's secret:

```sh
ws regctl registry login harbor.localtest.me:8443 -u 'robot$inventory+reader' -p '<SECRET>'
ws regctl manifest head harbor.localtest.me:8443/inventory/podinfo:6.15.0
ws regctl image copy harbor.localtest.me:8443/inventory/podinfo:6.15.0 harbor.localtest.me:8443/inventory/podinfo:robot-test
```

The read succeeds and `regctl` prints the digest. The write fails, because the account has no push permission, and `regctl` prints the refusal Harbor returned. Sign `regctl` in as the administrator again before you continue:

```sh
ws regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
```

## Put the credential into an endpoint

A pull rule against another Harbor would store this account in its endpoint. The endpoint's credential has a type, `basic`, an access key (the robot's full name) and an access secret. You send them in the `credential` field when you create or update the endpoint:

```json
{
  "name": "remote-harbor",
  "type": "harbor",
  "url": "https://harbor.example.com",
  "insecure": false,
  "credential": {
    "type": "basic",
    "access_key": "robot$inventory+reader",
    "access_secret": "<SECRET>"
  }
}
```

The example is only for reading: `harbor.example.com` does not exist in the playground, so do not send it. It shows where the robot account goes and the provider `harbor` for a Harbor-to-Harbor rule. Harbor stores the secret in its database and never returns it in an API answer, so you cannot read a secret back from an endpoint.

You can now give an endpoint exactly the power a rule needs. The mirror in this playground has no credentials, but every real remote registry does, and the account behind it decides how much damage a wrong rule can do.

## Common pitfalls

> [!WARNING]
> - **The administrator account in an endpoint.** Anyone who can edit the rule or the endpoint then has administrator rights at the remote registry.
> - **Trusting the connection test.** It does not prove the account can push or delete.
> - **Losing the robot secret.** Harbor shows it once. Create a new account or refresh the secret.
> - **Robot accounts that never expire.** Choose an expiry, and put the renewal date in a calendar.
> - **Typing the account name without the `robot$` prefix.** The full name starts with `robot$` and contains the project.
