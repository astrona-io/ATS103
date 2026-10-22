---
estimated_duration: 40m
---

# Wire A Release Pipeline End To End

- **ID:** CAPSTONE
- **Slug:** ats-103-capstone-030
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespaces `harbor`, `mirror` and `dragonfly-system`. Read `question.md` for the task; `solution.md` is the walkthrough.

> **Not yet run.** This lab was written from the Harbor 2.15 documentation
> and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-103-capstone-030
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-103-capstone-030`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough with a submit loop |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Harbor and its neighbours, then the starting state |
| `manifests/` | `harbor-values.yaml`, `lab-start.yaml` (workstation, mirror), `dragonfly-deps.yaml`, `dragonfly-values.yaml` |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Waits for Harbor and the workstation |
| `validation/` | Grading scripts, one per check |
