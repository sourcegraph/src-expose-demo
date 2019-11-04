# Exploring src-expose

The `src-expose` CLI takes a list of directories as input and serves their contents as Git repositories over an HTTP API.

Customers with non-Git code hosts such as Perforce, could create a workspace on a local server, the directories of which are served by `src-expose` as Git repositories. Sourcegraph can then clone and index these repositories for searching.

See this 2 minute video showing end-to-end how to integrate non-Git code hosts with Sourcegraph.

[![Screen Shot 2019-11-04 at 10 57 42 AM](https://user-images.githubusercontent.com/133014/68149262-6dd92980-fef2-11e9-8dc5-8c02f18b86d3.png)](https://vimeo.com/368923038)

## Purpose of this repository

As `src-expose` is still in the discovery and experimentation phase, this repository was created to make it easy for customers and Sourcegraph developers to use and test `src-expose`.

`src-compose` is written in Go and compiled to a single binary. To replicate a realistic deployment scenario, `src-expose` is compiled and run from a Docker container that Sourcegraph communicates with inside a specially created Docker network. The `src-compose` binary is compiled with code from Sourcegraph's master branch to ensure it's always up-to-date.

## Requirements

Docker and Make are the only software requirements.

It has been tested on macOS Mojave but should work on Linux. It will likely not work on Windows 10 (yet).

## Design

To make this easy and to provide a reference implementation, this demo runs both `src-expose` and the Sourcegraph server. 

> Note

It would be easy to get an existing Sourcegraph instance to communicate with the `src-expose` container, as long as they are both added to a custom Docker network, and the container is named `src-expose`.

## Usage

A Makefile is used to make it easy to run the required commands. To bring up `src-expose` and Sourcegraph:

1. Run `make build` to compile `src-expose` and build the Docker image
2. Run `make src-expose` to serve every sub-directory under the `projects` directory as separate Git repositories
3. Run `make sourcegraph` to run the Sourcegraph container
4. Go to http://localhost:7080/ and initialize Sourcegraph
5. Navigate to Admin > External services > Add external service > **Single Git repositories** using the below configuration:

```json
{
  "url": "http://src-expose:3434",
  "repos": [
    "src-expose"
  ]
}
```

6.Navigate to Admin > Repositories and you should a list of repositories
7.Search for `AdServiceClient` where you should see many results. Try filtering using `lang:java`

To see an example of what `src-expose` is serving to Sourcegraph:

- Go to [http://localhost:3434/v1/list-repos](http://localhost:3434/v1/list-repos) to see the list of repositories
- Go to [http://localhost:3434/repos/cartservice/.git/](http://localhost:3434/repos/cartservice/.git/) to see the contents of the `cartservice` Git repository.

## Notes

- A custom Docker network is required to communicate with containers via a hostname as opposed to an IP address.
- If you already have a Sourcegraph instance, for it to see the src-expose container, create a Docker network called `sourcegraph`, then modify the docker container run command to include `--network sourcegraph`.
- This has not been tested on Linux or Windows.
