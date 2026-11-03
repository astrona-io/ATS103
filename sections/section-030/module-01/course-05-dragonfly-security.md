# Securing The Connection To Dragonfly

In the playground, Harbor talks to Dragonfly with no authentication and no certificate check. That is acceptable in a lab and not in production. This part lists what to set up so that only Harbor can start preheats, and only trusted components download from Harbor.

## Authentication from Harbor to the manager

An instance has an authentication mode. The values in the REST API are `NONE`, `BASIC` and `OAUTH`. Dragonfly's manager accepts a **personal access token** created in its console, and Harbor sends it when the mode is `OAUTH`. The token is stored in the instance as the authentication information:

```json
{
  "name": "dragonfly",
  "vendor": "dragonfly",
  "endpoint": "https://dragonfly-manager.example.com",
  "auth_mode": "OAUTH",
  "auth_info": { "token": "<TOKEN>" },
  "enabled": true,
  "insecure": false
}
```

Create the token with the least access that allows preheat jobs, and replace it on a schedule. Harbor does not show the token again after saving, as with a robot account's secret.

## Certificate checks

The instance has an **insecure** option that skips the check of the manager's certificate. Keep it off whenever the manager has a certificate from a known authority, and turn it on only for a lab. A real endpoint uses `https`, a name that matches the certificate, and a trusted authority.

## The seed peer's trust in Harbor

The download runs from the seed peer to Harbor, so the seed peer also needs to trust Harbor's certificate authority and to resolve Harbor's name. It also needs credentials that can read the artifact, which Harbor supplies with the preheat request. Without the trust, the symptom is a failed task with a certificate error, as shown in the second module.

## A checklist before production

1. Use `https` for the manager and Harbor.
2. Use the `OAUTH` mode with a token that expires.
3. Keep `insecure` off.
4. Put Harbor's authority in the seed peers' trust store.
5. Limit network access to the manager's REST address to Harbor and to administrators.

## Common pitfalls

> [!WARNING]
> - **Leaving `insecure` on after the lab.** It disables the certificate check.
> - **A token that never expires.** Replace it on a schedule.
> - **Securing Harbor to Dragonfly and forgetting the seed peer to Harbor.** Both directions need trust.
