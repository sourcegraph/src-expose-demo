# Enabling non-Git code hosts to integrate with Sourcegraph using src-expose

The `src-expose` CLI takes a list of directories as input and serves their contents as Git repositories over HTTP.

This 2 minute video shows end-to-end how to integrate non-Git code hosts with Sourcegraph.

[![Screen Shot 2019-11-04 at 10 57 42 AM](https://user-images.githubusercontent.com/133014/68149262-6dd92980-fef2-11e9-8dc5-8c02f18b86d3.png)](https://vimeo.com/368923038)

## Requirements

- Docker
- Make
- Git (if cloning this repository, otherwise download as a zip file)

## Usage

To provide a reference implementation and get up and running quickly, a Makefile provides commands to run `src-expose` and Sourcegraph using Docker:

1. Run `make build` to build the Docker image
1. Run `make src-expose` to serve the directories in `projects` as individual Git repositories
1. Run `make sourcegraph`, then open [http://localhost:7080/](http://localhost:7080/) and initialize Sourcegraph
1. Navigate to **Site admin > External services > Add external service > Single Git repositories**, then use the below configuration:

```json
{
  "url": "http://src-expose:3434",
  "repos": [
    "src-expose"
  ]
}
```

1. For demo purposes, you can increase the speed at which Sourcegraph indexes code changes by going to **Site admin > Configuration**, then setting `search.index.enabled` to `false`.
1. View the list of indexed repositories in Sourcegraph at **Site Admin > Repositories**
1. Test by searching for `AdServiceClient`. Additionally, limit results to Java files using the `lang:java` filter.

## Optional: to view the API data provided by src-expose

1. Open [http://localhost:3434/v1/list-repos](http://localhost:3434/v1/list-repos) to see the list of repositories
1. Open [http://localhost:3434/repos/cartservice/.git/](http://localhost:3434/repos/cartservice/.git/) to see the response for a specific repository

## FAQs

### How long does it take for changes to local code to be reflected in Sourcegraph?

Approximately one minute but this can vary. To force Sourcegraph to pull the latest changes, navigate to any repository, go to to **Settings > Mirroring**, then click on **Refresh now**. You can also increase the speed at which Sourcegraph indexes code changes by going to **Site admin > Configuration**, then setting `search.index.enabled` to `false`, but note this is only something you would want to do for demo purposes.

### How can I get `src-expose` to serve code from my organization?

Simply replace the directories inside `projects` with checked out code from your own code host. Then stop and restart the `src-expose` container.

> Note Running the `make src-expose` command supplies the list directories inside `projects` so changes to the Makefile are required.


## Implementation notes

- A custom Docker network is used so the `src-expose` container can set a custom hostname, removing the need to figure out what IP address the `src-expose` container has been assigned for use in the external service configuration.
- If you want to run and expose `src-expose` to your existing Soucegraph instance, create a Docker network called `sourcegraph`, then modify the Sourcegraph `docker container run` command to include `--network sourcegraph`.
- Not yet tested on Linux or Windows.
