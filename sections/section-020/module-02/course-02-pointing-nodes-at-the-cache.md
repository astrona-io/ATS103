# Pointing Kubernetes Nodes At The Cache

A cache only helps if the machines that pull images actually use it. In a Kubernetes cluster, the container runtime on each node pulls the images, not `kubectl` and not the pod. The runtime asks a registry for the image named in the pod, and it asks the registry whose name is in that image name. This part shows the two ways to send those pulls through Harbor: change the image name, or configure the runtime to use Harbor as a mirror. It also shows what a pod needs to sign in to a private cache.

## Option one: change the image name

The simplest way is to write the Harbor name in the pod. A pod that used `alpine:3.22` uses the cache path instead:

| Before | After |
| --- | --- |
| `alpine:3.22` | `harbor.example.com/team-cache/library/alpine:3.22` |
| `docker.io/library/alpine:3.22` | `harbor.example.com/team-cache/library/alpine:3.22` |
| `docker.io/grafana/grafana:11.0.0` | `harbor.example.com/team-cache/grafana/grafana:11.0.0` |

The host name is the Harbor address, the next part is the proxy cache project, and the rest is the path Docker Hub uses. Official images keep `library/`. The change is explicit and easy to read, and it needs no node configuration. Its cost is that every manifest, Helm chart and operator must be edited, including images that charts pull on their own.

## Option two: configure the runtime as a mirror

The container runtime `containerd` can be told that a registry has a mirror. The pod keeps the name `alpine:3.22`, and the runtime asks Harbor first. Each registry has a directory under the runtime's certificate directory, by default `/etc/containerd/certs.d`, with a file named `hosts.toml`. For Docker Hub, the directory is `docker.io`. This is the file on a node:

```toml
server = "https://registry-1.docker.io"

[host."https://harbor.example.com/v2/team-cache"]
  capabilities = ["pull", "resolve"]
  override_path = true
```

The `server` line is the original registry, used if the mirror fails. The `host` line is the mirror, with the cache project in the path. `capabilities` says the mirror may be used to pull and to resolve tags. `override_path = true` tells the runtime that the path in the host is complete, so the runtime must not add `/v2/` and the project name again. The runtime must also be told to read the directory: in its configuration, the registry setting `config_path` must point at `/etc/containerd/certs.d`.

The file is on each node, so it is a job for the cluster's node image, an `Ansible` run or a `DaemonSet` that writes the file. It is not a Kubernetes object, and the playground cannot show it working: the playground's nodes cannot resolve the Harbor name. The commands below that apply to the playground check the Harbor side.

## Signing in from a pod

A private cache project needs credentials. A pod gets them from an **image pull secret**, a Kubernetes Secret of the type `kubernetes.io/dockerconfigjson` that holds registry credentials. A pod, or the pod's service account, names it under `imagePullSecrets`. Create one from the robot account of the earlier part. The commands use the helpers from the earlier parts; replace `<SECRET>` with the robot's secret:

<!-- astrona:playground:renew -->

```sh
kubectl create namespace builds
kubectl -n builds create secret docker-registry harbor-pull \
  --docker-server=harbor.localtest.me:8443 \
  --docker-username='robot$team-cache+puller' \
  --docker-password='<SECRET>'
kubectl -n builds get secret harbor-pull -o jsonpath='{.type}{"\n"}'
```

The last command prints `kubernetes.io/dockerconfigjson`. A pod in the namespace `builds` that lists `harbor-pull` under `imagePullSecrets` can then pull from the private cache. When the runtime is configured as a mirror, the secret is still needed for the mirror host, and many clusters add it to the namespace's default service account so that no pod has to name it.

## What Harbor sees from a node

Whichever option you use, Harbor sees ordinary pull requests with a project path. Check that the pull path through the cache works from the Harbor side, with the name a node would use. A manifest `HEAD` request asks for the image's digest without downloading layers:

```sh
ws regctl manifest head harbor.localtest.me:8443/team-cache/library/alpine:3.22
```

The command prints the digest of the image. If the image was not in the cache yet, this request made Harbor fetch it from Docker Hub first. A node that pulls through the cache does the same sequence of requests, and every node after the first gets the copy that Harbor holds.

You now know the two ways to make nodes use the cache, and what each one needs: image names for the first, a `hosts.toml` file and the `config_path` setting for the second, and a pull secret for a private project in both. The next question is what the cache holds once nodes start using it.

## Common pitfalls

> [!WARNING]
> - **Forgetting `library/` for official images.** The cache path keeps Docker Hub's path, so `alpine` is `library/alpine`.
> - **Leaving `override_path` out of `hosts.toml`.** The runtime then builds a path that the project does not serve.
> - **Setting the mirror and forgetting `config_path`.** The runtime ignores the directory.
> - **A pull secret in the wrong namespace.** A secret works only for pods in its own namespace.
> - **Expecting the mirror to hide a Harbor outage.** When the runtime cannot reach the mirror, it falls back to the `server` line, which uses Docker Hub directly.
