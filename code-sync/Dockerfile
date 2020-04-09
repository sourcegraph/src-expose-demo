FROM sourcegraph/alpine:3.10

# hadolint ignore=DL3018
RUN apk add --no-cache git

WORKDIR /app/data/
USER sourcegraph
ENTRYPOINT ["/sbin/tini", "--"]
COPY ./* /app/bin/
