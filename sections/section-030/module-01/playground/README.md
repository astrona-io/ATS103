# Preheat Images Into Dragonfly — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-103-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

> **Not yet run.** This playground was written from the Harbor 2.15
> documentation and has not been started on a cluster yet.

A single sandbox environment: Harbor 2.15.4 on `kind`, the `workstation` pod
with the client tools, and the `mirror` registry, and a minimal Dragonfly in the namespace `dragonfly-system`. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-103-playground-030-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-103-playground-030-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (bootstrap only) |
| `bootstrap/prepare.sh` | Helm, CoreDNS rewrites, Harbor, Dragonfly, workstation, mirror, project `inventory` |
| `manifests/` | `harbor-values.yaml`, `lab-start.yaml`, `dragonfly-deps.yaml`, `dragonfly-values.yaml` |
| `docs/overview.md` | What the environment contains and ideas to try (the learner page) |
