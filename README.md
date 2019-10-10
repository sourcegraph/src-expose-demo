# Making src-expose easy to test, demo, and debug

The `src-expose` server is an awesome way to *expose* any directory, e.g., directories inside a Perforce depot, or directories not under version control, in a way that Sourcegraph can index for searching.

## Overview

The src-expose binary is exposed in a Docker container that Sourcegraph can communicate with
using a created Docker network.

### Why not use Docker Compose

Not everyone likes or uses Docker Compose, plus it is not always bundled with a package manager's version of Docker. This may change, but for now, keeps things simpler.

## Instructions

1. `make build` to build the docker container and pull down a sample Perforce depot
1. `make network` to create the docker network for Sourcegraph and src-expose*
1. In a terminal, run `make run` to run the src-expose container
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

\* The default Docker network does not allow the hostname to set for a container, and
is required so the src-expose container will always be reachable at http://src-expose

\*\* If you already have a Sourcegraph instance, in order for it to see the src-expose container
  container, create a Docker network called `src-expose`, then modify the docker container run
  command to include `--network sourcegraph`

> Note:

  Has not been tested on Linux or Windows.