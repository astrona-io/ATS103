# Summary

A proxy cache project is a service with users, limits and records. This module ran one for a team: it made the cache private, gave the build machines their own account, pointed the nodes at it, read what the cache held, and traced its errors.

## What you learned

A private proxy cache project lets only accounts with permission pull from it, so the team's Docker Hub allowance stays with the team. A project robot account is the right credential for software: it belongs to one project, holds only the listed permissions, can expire and can be disabled without changing anyone's password. Its full name is `robot$<project>+<name>`, and Harbor shows its secret once.

Nodes use the cache in one of two ways. A pod can name the Harbor path, `<harbor>/<project>/library/alpine:3.22`, or the container runtime can be configured with a `hosts.toml` file that makes Harbor a mirror, with `override_path` set because the project is in the path. A private project also needs an image pull secret in the pod's namespace.

Harbor records what the cache holds and who uses it. Each cached artifact has a size and a `pull_time` that the retention policy uses. The project has a storage quota that counts cached images, and a full quota fails the next pull. The audit log records pulls with the account name, which is why each pipeline needs its own account.

Errors in a proxy cache come from three parties, and the key facts to remember are these:

- A `401` or `denied` comes from Harbor, a missing `library/` gives a `404`, and `toomanyrequests` comes from Docker Hub.
- Ping the endpoint before you change the project.
- The log of `core` names the real cause when the client message does not.
- Nobody can push to a proxy cache project.

<!-- astrona:playground:destroy -->
