# Welcome To The Course

This course trains you for the **Replication, P2P Preheating & Remote Registries** part of the Astrona **Harbor** training path. That part is 15% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, Deployments, Services, ConfigMaps, `kubectl get`, `kubectl logs` and `kubectl exec`. You know what a container image is, and what a tag and a digest are. You have pushed or pulled an image before. You do not need to know Harbor's replication or preheating features yet. Each new idea is explained the first time it appears.

## What you can do at the end

A registry rarely stands alone. Images move to other registries, come in from public ones, and go out to many nodes at once. This course asks you to set up each of those moves, check that it really happened, and find out why when it did not. It has three topics, and each one turns into a set of skills you will practise.

The first topic is **registry endpoints and replication**. You will learn to:

- Register a remote registry in Harbor as a registry endpoint, and test it.
- Write a replication rule that pushes artifacts to it, with filters that select exactly the right tags.
- Choose between a manual, a scheduled and an event-based trigger, and replicate deletions too.
- Read an execution, its tasks and their logs to find out why a copy failed.

The second topic is **proxy cache projects**. You will learn to:

- Put a Harbor project in front of Docker Hub, so images are pulled once and then served from Harbor.
- Build the right pull path, including the `library/` prefix for official images.
- Explain what the cache does when the upstream image changes, disappears or cannot be reached.

The third topic is **P2P preheating with Dragonfly**. You will learn to:

- Explain what peer-to-peer (P2P) distribution and preheating are, and what the parts of Dragonfly do.
- Register Dragonfly in Harbor as a P2P provider instance.
- Write a preheat policy that selects release tags and runs when they are pushed.

Everything is written for **Harbor 2.15.4** and the **Harbor CLI v0.0.27**.

## The words this course uses

The pages use Harbor's, the Open Container Initiative's (OCI) and Kubernetes' own terms, because those are the words you meet in the product, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **registry** is a server that stores container images and other OCI artifacts. An **artifact** is anything stored in the OCI format: an image, a Helm chart, a signature. A **repository** is a named collection of artifacts, such as `inventory/podinfo`, and a **tag** is a name for one artifact in it, such as `v1.0.0`. In Harbor, every repository lives in a **project**, which decides who may push and pull.

Three Harbor objects come back on almost every page:

| Object | What it does |
| --- | --- |
| Registry endpoint | Tells Harbor where another registry is and how to sign in to it |
| Replication rule | Copies chosen artifacts to or from a registry endpoint |
| Proxy cache project | Pulls images from a registry endpoint on demand and keeps a copy |

## The example setup in your playground

Every playground and lab runs the same small setup. Harbor runs inside the cluster at `https://harbor.localtest.me:8443`. It holds the project `inventory` with the repository `inventory/podinfo`, a small web application image, with the tags `6.15.0` and `v1.0.0`. A second, much simpler registry called the mirror stands in for a remote registry. It answers at `http://mirror.localtest.me:5001` inside the cluster.

You run every Harbor command from the `workstation` pod. It holds the Harbor command-line tool `harbor`, the registry client `regctl` and a few other tools, and it trusts Harbor's certificate. The last section adds Dragonfly, a P2P distribution engine. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has three sections. They follow the way an image travels: out of Harbor to another registry, into Harbor from a public registry, and on to the nodes that run it.

| Section | What it covers |
| --- | --- |
| 010 | Registry Endpoints And Replication |
| 020 | Proxy Cache Projects |
| 030 | P2P Preheating With Dragonfly |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
