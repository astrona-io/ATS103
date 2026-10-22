---
estimated_duration: 35m
---

# Repair A Replication Pipeline

- **ID:** CAPSTONE
- **Slug:** ats-103-capstone-010
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespaces `harbor` and `mirror`. Read `question.md` for the task; `solution.md` is the walkthrough.

> **Not yet run.** This lab was written from the Harbor 2.15 documentation
> and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-103-capstone-010
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-103-capstone-010`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough with a submit loop |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Harbor and its neighbours, then the starting state |
| `manifests/` | `harbor-values.yaml`, `lab-start.yaml` (workstation, mirror) |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Waits for Harbor and the workstation |
| `validation/` | Grading scripts, one per check |
