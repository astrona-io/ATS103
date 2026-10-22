# Section 020: Proxy Cache Projects

Most images start from a public base image: `alpine`, `nginx`, `busybox`. When every build machine and every node pulls those from Docker Hub directly, three things go wrong. Docker Hub limits how many pulls an anonymous user can make, the same layers cross the internet again and again, and an outage at Docker Hub stops your builds.

A **proxy cache project** puts Harbor in between. Clients pull from Harbor; Harbor pulls each image from Docker Hub once, keeps a copy and serves it from then on. This section builds one in front of Docker Hub and shows what the cache does when the upstream image changes, disappears or cannot be reached.

**Topic covered:** Remote registries

## What you will learn

- Why a registry needs a cache in front of public registries, and which registries Harbor can cache.
- Creating a Docker Hub registry endpoint and a proxy cache project that uses it.
- The pull path through a proxy cache project, including the `library/` prefix for Docker Hub's official images.
- What the cache serves when the upstream image is unchanged, changed, deleted, or unreachable.
- The default retention policy of a proxy cache project, why nobody can push to it, and the security limit it carries.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, and the landing page starts it for you.

### 1. Cache Docker Hub With A Proxy Cache Project

The module starts at its landing page, which also launches the playground. The playground holds Harbor with internet access and no proxy cache project yet.

1. Why Cache A Remote Registry
2. Creating And Using A Proxy Cache Project, followed by the lab **Pull Docker Hub Images Through A Proxy Cache**
3. Cache Behaviour, Retention And Limits
4. Summary

## Section capstone: Route Base Image Pulls Through The Cache

The capstone is one graded scenario that combines the whole module. Someone started on a Docker Hub cache and stopped halfway: an endpoint that cannot work, a project that is not a cache, and a CI pull list that still goes straight to Docker Hub. Finish the job without changing which images CI uses. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS103.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-103-capstone-020
```
