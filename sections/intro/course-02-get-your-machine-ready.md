# Get Your Machine Ready

Every playground and lab in this course runs on your own machine, in a small Kubernetes cluster. A tool called `astrona` builds it for you, sets it up, grades your work and removes it again. This page gets your machine ready: first the tools you need, then the handful of `astrona` commands you will use every day, and last what to do when a start goes wrong.

## What you need

Every section needs the same set of tools. Install these before you start:

- **A container engine:** Docker or Podman. The cluster runs inside it.
- **`kind`:** runs Kubernetes inside the container engine.
- **`kubectl`:** talks to the cluster.
- **The astrona command-line tool.**
- **A web browser:** the Harbor web portal shows the same objects the commands create.

You do not need Harbor's tools on your machine. Each environment installs Helm 3.22.1 for its own set-up, and every Harbor command runs in the `workstation` pod inside the cluster, which already holds the Harbor command-line tool and the registry clients.

Harbor is a large application, so give your container engine enough memory. Plan on about **4 GiB** for most environments and about **6 GiB** for the last section, which also runs Dragonfly. The environments also need **outbound internet** while they start and while you work: they download Harbor's images from Docker Hub, the client tools from GitHub, and the example image from `ghcr.io`. The proxy cache section pulls a few small images from Docker Hub through Harbor. The first start of an environment can take up to 15 minutes.

## Reaching Harbor

Inside the cluster, Harbor answers at `https://harbor.localtest.me:8443`. To open the Harbor web portal in your browser, start a port-forward in a second terminal and leave it running:

```sh
kubectl -n harbor port-forward svc/harbor 8443:8443
```

Then open `https://harbor.localtest.me:8443` and sign in as `admin` with the password `Harbor12345`. These are lab-only credentials. The name `harbor.localtest.me` is a public DNS name that points at `127.0.0.1`, your own machine, so the port-forward answers it. The browser warns you about the certificate, because the lab generates its own. A real installation uses a certificate from a certificate authority your browser trusts.

Some home routers block DNS answers that point at `127.0.0.1`. If the browser cannot find `harbor.localtest.me`, add this line to `/etc/hosts` on your machine:

```
127.0.0.1 harbor.localtest.me
```

You do not have to check your tools by hand. Let `astrona` look at your machine for you:

```sh
astrona setup
```

`astrona setup` looks at what is missing, shows you each step it would take, and asks before it does anything. On macOS it can install `kind`, `kubectl` and Podman.

Later, you can check your machine at any time:

```sh
astrona check
```

## The commands you use every day

Once your machine is ready, you need only a handful of `astrona` commands. Each module page and lab page shows the exact command to copy, so you do not need to remember paths. This section walks through them in the order you meet them: sign in, start, pause, submit and clean up.

Labs from the course catalog are tied to your Astrona account, so you sign in first:

```sh
astrona login
```

Next you start a playground or a lab. Each module page and lab page shows the exact `astrona run` command for it. It looks like this:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS103.git -c sections/section-010/module-01/playground
```

When the cluster is ready, `kubectl` already points at it.

A chapter that sends you to a lab asks you to pause the playground first. Pausing frees your machine's memory but keeps everything you built:

```sh
astrona stop <name>
```

When the lab is done, start the playground again and carry on where you left off:

```sh
astrona start <name>
```

Inside a lab, you send your work for grading with `astrona submit`. The grader checks the live cluster. It reads Harbor through its API and pushes its own test images, so your fix has to actually work, not only make an error message go away. Each lab page shows the exact command:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

You can submit as often as you like.

When you are done with a playground or a lab, remove it:

```sh
astrona destroy <name>
```

The name is the environment's name, printed by `astrona run` and shown on each page (for example `ats-103-playground-010-01`). It is not the folder path. To see what is on your machine, list it:

```sh
astrona list
```

> [!WARNING]
> **Run one environment at a time.** Each playground and lab is a whole cluster with its own Harbor. Two running at once can use up your machine's memory, and it is easy to send a command to the wrong one. Pause or destroy the playground before you start the lab.

## When a start goes wrong

Sometimes a playground or lab does not start cleanly. Ask `astrona` what is wrong before you try anything else:

```sh
astrona doctor
```

It checks your machine, the lab's configuration and the running lab, and tells you how to fix what it finds.

If a start seems stuck, Harbor is usually still pulling its images or waiting for its database; give it up to 15 minutes. If a start fails while it downloads something, check your network first. If the `workstation` pod cannot reach Harbor, check that every pod in the namespace `harbor` is running. Remember also that a lab whose replication or preheating does nothing at the start is often broken on purpose: the lab's task tells you when that is the case. With your machine ready and these commands at hand, you can start the first module.
