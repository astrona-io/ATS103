# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS103 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Replication, P2P Preheating & Remote Registries**
  domain of the **Harbor** training path (`ATP020`). It is 15% of the path.
  There is no official Harbor certification exam; the path's domains and
  weights are Astrona's own, set in `ATP020/path.yaml`.
- **What the domain really tests:** moving artifacts between registries on
  purpose and on time. The student must *do* things: register a remote
  registry, write a replication rule whose filters select exactly the right
  tags, read why an execution failed, cache Docker Hub behind Harbor, and
  register a P2P engine with a preheat policy. Every fix is proved with an
  artifact that arrives (or does not arrive) where it should.
- **The three topics:** registry endpoints and replication, proxy cache
  projects, and P2P preheating with Dragonfly.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Registry Endpoints And Replication | Replication |
  | 020 | Proxy Cache Projects | Remote registries |
  | 030 | P2P Preheating With Dragonfly | P2P preheating |

- **The versions:** **Harbor v2.15.4** (chart `harbor-helm` 1.19.4, Helm
  3.22.1) on a single-node `kind` cluster; the **`harbor` CLI v0.0.27**;
  `regctl` 0.11.7 as the registry client; the mirror is **CNCF Distribution
  `registry:3.1.2`**; **Dragonfly 2.5.2** (chart `dragonfly` 1.8.6) with
  `mysql:8.4.13` and `redis:7.4.11-alpine`. The Harbor documentation set is
  2.15.0. Do not teach fields, flags or output from other versions without
  saying so.
- **The main sources:** the Harbor documentation,
  <https://goharbor.io/docs/2.15.0/>, the Harbor CLI command pages in
  `doc/cli-docs/` of `goharbor/harbor-cli` at tag `v0.0.27`, and the
  Dragonfly documentation, <https://d7y.io/docs/>. Check every page against
  them.

### Status: built, not yet run

The first version of this repository was written from the documentation
**without a live run**. No playground or lab has been started, and no
`astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

The facts most likely to be wrong, in the order to check them:

1. **Harbor REST API field names**, written from the Harbor v2.0 API as
   remembered, not read from the Swagger file: `replicate_deletion`,
   `dest_namespace_replace_count`, filter `decoration`, the `trigger` object of
   a replication rule; the preheat policy's `filters` and `trigger` being JSON
   strings; `POST /registries/ping` and `POST /p2p/preheat/instances/ping`
   answering `200` only when the remote side is healthy. Check them against
   `/devcenter-api-2.0` of the running Harbor first.
2. **Whether Harbor accepts an endpoint or instance it cannot reach.** The
   capstone seeds create an endpoint on the wrong port and a disabled instance
   on the wrong port. If Harbor refuses to save them, seed a working object
   first and break it with `PUT`.
3. **Dragonfly in a small cluster.** The chart values in
   `manifests/dragonfly-values.yaml` (manager on, client off, seed peer
   without persistence, external MySQL and Redis) are written from the chart's
   `values.yaml`, not run. Harbor's health check of the instance is assumed to
   call the manager's `/healthy` endpoint.
4. **`regctl image mod --create <tag> --annotation k=v`** as the way graders
   push a new, distinct artifact; and `regctl registry set <host> --tls
   disabled` for the plain-HTTP mirror.
5. **The `harbor` CLI is young (`v0.0.x`).** `harbor replication start` and
   `harbor replication policies create` take a file or prompt for input; their
   file format is not documented. Pages use the CLI for endpoints, listing and
   viewing, and the REST API for writing rules and policies.

### Design decision: what the preheat labs grade

Harbor's documentation says a Dragonfly preheat needs a Dragonfly personal
access token (auth mode `OAuth`), created in the Dragonfly console, and a
seed peer that can pull from Harbor. The lab environment runs a real but
minimal Dragonfly (manager, scheduler, one seed peer, MySQL, Redis) so the
instance is **healthy** in Harbor, but it does not give the seed peer Harbor's
CA. So the preheat labs grade the **configuration** (an enabled, healthy
instance; a policy with the right filters and an event-based trigger), never
a successful preheat execution. Pages say this plainly, and show the token
and the execution steps as what a real installation adds. This adds about 1.5
GiB to section 030's environments; plan on about 6 GiB in total there.

### Terms, not metaphors

| Term | First-use definition (example wording) |
| --- | --- |
| Registry endpoint | A remote registry that Harbor knows about: a provider type, a URL, credentials, and whether to verify its certificate |
| Provider | The kind of remote registry (Docker Hub, Harbor, Distribution, AWS ECR, Google Artifact Registry, Quay, and more); it decides which API Harbor speaks to it |
| Replication rule | A Harbor policy that copies artifacts to (push-based) or from (pull-based) a registry endpoint |
| Filter | A pattern on the repository name, tag, label or resource type that selects which artifacts a rule copies; `*` stops at `/`, `**` does not |
| Destination namespace / flattening | The namespace the copies land in / how many leading levels of the source path are replaced by it |
| Trigger | When a rule runs: manual, scheduled (cron), or event based (on push, retag and, if enabled, delete) |
| Execution / task | One run of a rule / the copy of one artifact inside a run; jobservice runs both and keeps their logs |
| Proxy cache project | A Harbor project that pulls from one registry endpoint on demand and keeps a copy; nobody can push to it |
| P2P (peer-to-peer) distribution | Nodes fetch image pieces from each other instead of all from the registry |
| Preheat | Asking the P2P engine to fetch an image before any node needs it |
| P2P provider instance | Harbor's record of one P2P engine: vendor, endpoint, authentication |
| Preheat policy | A project policy that selects artifacts and a trigger, and sends them to a provider instance |
| Dragonfly manager / scheduler / seed peer | Dragonfly's control service and REST API (port 8080) / the service that decides which peer downloads what / the peer that fetches from the registry first and serves the others |

### The example workloads

| Name | What it is |
| --- | --- |
| Harbor (namespace `harbor`) | Harbor 2.15.4 at `https://harbor.localtest.me:8443`, administrator `admin` / `Harbor12345` (lab-only). No persistence |
| `workstation` (namespace `workstation`) | `alpine:3.22` with `harbor`, `regctl`, `oras`, `cosign`, `curl` and `jq`, trusting Harbor's CA. Every Harbor command on a page runs here |
| `mirror` (namespace `mirror`) | `registry:3.1.2` on plain HTTP port `5001`, deletes enabled, `emptyDir` storage. Reached as `http://mirror.localtest.me:5001` inside the cluster |
| Project `inventory` | `inventory/podinfo` with the tags `6.15.0` and `v1.0.0` (copied from `ghcr.io/stefanprodan/podinfo:6.15.0`) |
| Dragonfly (namespace `dragonfly-system`, section 030 only) | Manager REST API `http://dragonfly-manager.dragonfly-system.svc.cluster.local:8080`, one scheduler, one seed peer, `mysql`, `redis` |

Pages define their helpers once per page:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
wst() { kubectl -n workstation exec -it deploy/workstation -- "$@"; }
```

Inside the workstation, `regctl` must be told once that the mirror is plain
HTTP: `regctl registry set mirror.localtest.me:5001 --tls disabled`.

### Environment facts the text must respect

- **Harbor images are amd64 only (seen on a live run, 2026-10-23).** On an
  arm64 machine (Apple silicon) every `goharbor/*` image runs under
  emulation. The bundled Valkey (Redis) crashes there with a segmentation
  fault, so every values file replaces it with the multi-architecture
  `docker.io/valkey/valkey:8.1.10-alpine` (`redis.internal.image`). Keep
  that override in every new values file; the other components work under
  emulation. Upgrades must keep it too: use `--reuse-values` or a values
  file that contains it.
- **Two CoreDNS rewrites.** `harbor.localtest.me` →
  `harbor.harbor.svc.cluster.local` and `mirror.localtest.me` →
  `mirror.mirror.svc.cluster.local`, each as a `rewrite stop` block with the
  answer name rewritten back (the function `add_coredns_rewrite` in every
  install script). Never the one-line `rewrite name` form.
- **Port 5001, not 5000**, for the mirror: macOS uses port 5000 for AirPlay,
  and the course keeps one port everywhere.
- **The mirror is HTTP**, so its Harbor endpoint has `insecure: true` (the
  "Verify Remote Cert" box cleared). Say every time that a real remote
  registry uses HTTPS.
- **Docker Hub needs internet** and counts pulls. Docker's documentation sets
  a pull limit for anonymous users (about 100 pulls per 6 hours per IP
  address at the time of writing); say "about" and that the number may change.
  Pages pull only a few small images.
- **Cross-data-centre replication between two Harbor instances is prose.** A
  second Harbor is too heavy for the lab machine; the mirror stands in for the
  remote side, and pages say which settings differ for a Harbor target
  (provider `harbor`, copy by chunk).
- **Replication is asynchronous.** Graders wait up to three minutes for a tag
  to arrive or disappear; pages tell the reader to wait and check the
  execution.

### Where things are in this repo

The layout is the same as every Astrona course. Shared plumbing in every
environment was produced from one generator (kept outside the repository):
`manifests/harbor-values.yaml`, `manifests/lab-start.yaml` (workstation and
mirror), `manifests/dragonfly-*.yaml` (section 030),
`bootstrap/01-install-harbor.sh` or `bootstrap/prepare.sh`,
`testing/wait-for-harbor.sh`, the `config.yaml` files, the author READMEs,
`prerequisites.md`, and the block between `--- shared helpers` and `--- end of
shared helpers ---` in every seed, solution and validation script. **Change a
shared piece in every environment at once.**

### Lab metadata in `astrona.yaml`

`training:` block: id `ATS103`, domain `Replication, P2P Preheating & Remote
Registries`, weight `15`. Lab entries carry `title`, `path`, `difficulty`,
`estimated_duration`, `topic`, `task_kind`, `tags`, `learning_goals`,
`resources`, in that order, as in ATS016.

- `topic`: exactly one of `endpoints`, `replication`, `proxy-cache`,
  `preheat`.
- `task_kind`: `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8, only from this list: `registry-endpoint`, `provider`,
  `docker-hub`, `distribution`, `push-replication`, `pull-replication`,
  `replication-filter`, `flattening`, `event-trigger`, `scheduled-trigger`,
  `delete-sync`, `replication-execution`, `jobservice`, `proxy-cache`,
  `rate-limit`, `cache-retention`, `p2p`, `dragonfly`, `kraken`,
  `provider-instance`, `preheat-policy`, `harbor-cli`, `harbor-api`,
  `regctl`.
- `resources`: 1 to 4 pages on `goharbor.io` or `d7y.io`. The only place
  outside links are allowed.

### Running things

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS103.git -c sections/section-010/module-01/playground
astrona destroy ats-103-playground-010-01
astrona run --git ssh://git@github.com/astrona-io/ATS103.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-103-lab-010-01
astrona test -c sections/section-010/module-01/labs/lab-01   # authors
```

Names: `ats-103-playground-<section>-<module>`, `ats-103-lab-<section>-<module>`,
`ats-103-capstone-<section>`. Graders check **behaviour** where Harbor allows
it (a pushed release tag arrives in the mirror, a non-release tag does not, a
deleted release disappears, an image resolves through the proxy cache, an
endpoint or instance answers Harbor's health check) and reject the plausible
but wrong fix: starting the rule by hand instead of making it event based,
deleting and recreating a rule or policy the task says to repair, a filter so
wide it copies or preheats everything, pulling straight from Docker Hub. A
lab's `question.md` and `solution.md` must match what its `validation/`
scripts check.

### Where to find trusted sources

- **Replication:**
  [configuring replication](https://goharbor.io/docs/2.15.0/administration/configuring-replication/),
  [creating registry endpoints](https://goharbor.io/docs/2.15.0/administration/configuring-replication/create-replication-endpoints/),
  [creating replication rules](https://goharbor.io/docs/2.15.0/administration/configuring-replication/create-replication-rules/),
  [managing replications](https://goharbor.io/docs/2.15.0/administration/configuring-replication/manage-replications/)
- **Proxy cache:** [configure proxy cache](https://goharbor.io/docs/2.15.0/administration/configure-proxy-cache/)
- **P2P preheat:**
  [P2P preheat](https://goharbor.io/docs/2.15.0/administration/p2p-preheat/),
  [manage preheat provider instances](https://goharbor.io/docs/2.15.0/administration/p2p-preheat/manage-preheat-providers/),
  [Dragonfly preheat API and Harbor](https://d7y.io/docs/advanced-guides/open-api/preheat/),
  [Dragonfly on Kubernetes](https://d7y.io/docs/getting-started/quick-start/kubernetes/)
- **CLI:** `doc/cli-docs/` in `goharbor/harbor-cli` at `v0.0.27`
  (`harbor registry`, `harbor replication`, `harbor instance`,
  `harbor project preheat`)
- **API:** the Swagger file served by Harbor at `/devcenter-api-2.0`
