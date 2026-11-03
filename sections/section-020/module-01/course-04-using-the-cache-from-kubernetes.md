# Using The Cache From Kubernetes

The cache exists to serve machines that pull images, and in most teams those machines are Kubernetes nodes. This part shows how a pod ends up pulling through the cache, and how to check from the Harbor side that it did.

## Who pulls the image

The container runtime on each node, such as `containerd`, pulls the images of the pods that run there. It reads the image name from the pod, asks the registry named in it, and stores the layers on the node. Harbor does not know about pods. It sees pull requests for a project path, the same as from any other client.

## The image name for a cached image

A pod uses the cache when its image name contains the Harbor address and the cache project. For the project `docker-cache` from the earlier parts, a pod for `alpine` writes:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cache-demo
spec:
  restartPolicy: Never
  containers:
    - name: demo
      image: harbor.localtest.me:8443/docker-cache/library/alpine:3.22
      command: ["sleep", "3600"]
```

The name has the same parts as the manual pull: the Harbor address, the project, `library/` for an official image, the image and the tag. A public cache project needs no pull secret. A private one needs an image pull secret in the pod's namespace, which a later module covers.

In the playground, the cluster nodes cannot resolve the Harbor name, so a pod that uses this image does not start there. The playground tests the Harbor side with `regctl`, which runs from the workstation and can reach Harbor.

## Check the pull from Harbor

When a node pulls an image through the cache, Harbor stores the copy and counts the pull. Repeat what a node does, with `regctl` from the workstation, and then read the counter. The commands use the helpers from the earlier parts:

<!-- astrona:playground:renew -->

```sh
ws regctl image copy harbor.localtest.me:8443/docker-cache/library/alpine:3.22 ocidir:///tmp/node-pull-1
ws regctl image copy harbor.localtest.me:8443/docker-cache/library/alpine:3.22 ocidir:///tmp/node-pull-2
harbor_api GET '/projects/docker-cache/repositories?page_size=100' | ws jq '.[] | {name, artifact_count, pull_count}'
```

The repository `docker-cache/library/alpine` is listed with a `pull_count`. Each pull from a node would add to it, and only the first pull made Harbor fetch from Docker Hub. This is the saving the cache gives a cluster: a hundred nodes pulling the same image cause one download from Docker Hub.

## Why the tag matters

Kubernetes pulls an image on every pod start when the tag is `latest` or the pull policy is `Always`. Each pull is a request to Harbor, and each request makes Harbor check the upstream with a `HEAD` request. A fixed tag with the default pull policy, `IfNotPresent`, pulls only when the node lacks the image. A fixed tag therefore costs less on the cache, on the upstream and on the pod start time.

You can now describe how a pod uses the cache, why only Harbor sees the traffic, and how to check the result from the Harbor side. The next module takes this further by running the cache for a team with private access.

## Common pitfalls

> [!WARNING]
> - **Leaving `library/` out of the image name.** Official images need it at Docker Hub.
> - **Expecting a pod in the playground to start.** The nodes there cannot resolve the Harbor name.
> - **Using `latest` for every pod.** It forces a check against the upstream on every start.
