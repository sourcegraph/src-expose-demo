# src-expose demos

The [`src-expose` CLI](https://docs.sourcegraph.com/admin/external_service/non-git) can sync changes to git and ordinary directories and serve them over http.

The purpose of this repo is to provide working code examples for both Docker and Kubernetes that can be used for testing `src-expose` and as be used as a starting point that can be adapted for customer specific implementation.

## The code

This repo operates under the assumption that the best documentation is working code, not code snippets that can fall out of date and stop working.

Therefore, everything works by running commands via `make` and the `Makefile` is your source of truth

## Requirements

- Make
- Git
- Docker
- Kubernetes

## Usage

There are two use cases covered here, both of which have Docker and Kubernetes examples.

1. Serve a list of non-git code (ordinary folders)
1. Serve git repositories found in a parent folder

## Using Docker

Runs a single container using the `sourcegraph/src-expose` image. The demo expects Git repositories and ordinary code directories to be mounted from the `./code` directory in this repository, and you can populate the code directory by running:

```sh
./resources/code-download.sh
```

### To serve ordinary code directories

Notice in the `Makefile` that we're using a custom `--entrypoint` argument of `/usr/local/bin/entry.sh`. The reason for this, is because by default, `src-expose` expects a list of directories to be passed to it, if not using the `serve` command. 

This custom [entry point script](https://github.com/sourcegraph/sourcegraph/blob/master/dev/src-expose/entry.sh) creates a list of the directories in the `/app/data` directory, then computes the list of directories to pass to `src-expose` so you don't have to manually create as an argument to pass in.

To serve ordinary directories as git repositories:

```sh
make docker-code-dirs
```

### To serve existing git repositories

Many customers have used a CLI tool to convert repositories from a non-git VCS into a git repository, but still need to make them available to Sourcegraph over HTTP.

This is what `src-expose serve` is for, which has saved many customers the trouble of running a Git code host, purely for the purposes of serving local git repositories.

To serve existing git repositories over HTTP:

```sh
make docker-git-repos
```

### Index repositories from `src-expose` in Sourcegraph

Once you have the `src-expose` container running, you need to configure Sourcegraph to index the available repositories:

1. Go to **Site admin** > **Manage repositories** > **Add repositories**
1. Select **Generic Git host**
1. Paste the following:

```json
{
  "url": "http://<host ip address>:3434",
  "repos": [
    "src-expose"
  ]
}
```

If running Docker for Desktop, you can use the hostname of `host.docker.internal:3434`, otherwise you'll need the IP address or fully qualified hostname of the host machine running the `src-expose` container.

---

## Using Kubernetes

To make things easy, we use a single Pod with a shared volume and 2 containers, one for syncing code, and the other for `src-expose`.

An init container is responsible for downloading the code to be served before the `src-expose` container is started. This design allows the Pod to deployed to any node, with the drawback that the entire codebase must be downloaded.

![](resources/src-expose-k8s.png)

Depending upon the size of code to be served, binding the Pod to a node and using a `hostPath` volume might be a better choice.

### The code sync container

The code sync container is merely to demonstrate how such a container might be used but the implementation itself is demo quality only.

It either downloads and extracts zip files to simulate non-git code syncing, or clones and pulls git repositories to simulate directly serving git repositories.

### Customizing these examples to serve your code

To customize to use your own code, either replace the code sync container with your own implementation, or you can eliminate the need for a code sync container if mounting the code from the node into the container via a `hostPath` volume or PersistentVolumeClaim (PVC).

### Serving ordinary code directories

The [code-dirs.yaml](code-dirs.yaml) file has the service and deployment for serving ordinary code directories:

```sh
make k8s-code-dirs
```

Once the init container has finished downloading code, you'll be able to access the `src-expose` service externally at `http://localhost:30034`, and inside the cluster at `http://src-expose-code-dirs:3434`.

### Serving git repositories

The [git-repos.yaml](git-repos.yaml) file has the service and deployment for serving git repositories:

```sh
make k8s-git-repos
```

Once the init container has finished cloning the repositories, you'll be able to access the `src-expose` service externally at `http://localhost:31034`, and inside the cluster at `http://src-expose-git-repos:3434`.

### Index repositories from `src-expose` in Sourcegraph

The URL you will use for Sourcegraph to communicate with the `src-expose` service will depend on how you have deployed Sourcegraph. The above deployment options provide both an internal and external URL and this guide presumes the reader knows Docker and Kubernetes sufficiently well to know which one to chose.

Once you have the `src-expose` Pod running, you need to configure Sourcegraph to index the available repositories:

1. Go to **Site admin** > **Manage repositories** > **Add repositories**
1. Select **Generic Git host**
1. Paste the following:

```json
{
  "url": "http://<internal or external hostname or ip>:3434",
  "repos": [
    "src-expose"
  ]
}
```

### Cleaning up deployments

To remove all Kubernetes resources, run:

```sh
make k8s-delete
```

## FAQs

### How long does it take for changes to local code to be reflected in Sourcegraph?

Approximately one minute but this can vary. To force Sourcegraph to pull the latest changes, navigate to any repository, go to to **Settings** > **Mirroring**, then click on **Refresh now**. You can also increase the speed at which Sourcegraph indexes code changes by going to **Site admin** > **Configuration**, then setting `search.index.enabled` to `false`, but note this is only something you would want to do for demo purposes.
