# Making src-expose easy to test, demo, and debug

The `src-expose` service **exposes** a list of directories as Git repositories that Sourcegraph can clone and index.

It is designed, so either non-Git code hosts, or code not under version control, can still be indexed and searchable by Sourcegraph.

## Overview

The `src-expose` binary is run in a Docker container that Sourcegraph communicates with inside a specially created Docker network.

## Instructions

1. `make build` to build the docker container and pull down a sample Perforce depot
1. `make network` to create the docker network for Sourcegraph and src-expose*
1. In a terminal, run `make src-expose` to run the src-expose container
1. In a different terminal, run `make sourcegraph` to run the Sourcegraph container**
1. Create an external service of type **Single Git repositories** for Sourcegraph to communicate with src-expose

```json
{
  "url": "http://src-expose:3434",
  "repos": [
    "src-expose"
  ]
}
```

## Notes

- A custom Docker network is required to communicate with containers via a specified hostname.
- If you already have a Sourcegraph instance, in order for it to see the src-expose container, create a Docker network called `src-expose`, then modify the docker container run command to include `--network sourcegraph`.
- Has not been tested on Linux or Windows.
