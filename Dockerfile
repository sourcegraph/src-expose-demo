FROM sourcegraph/alpine:3.9

RUN apk add --no-cache git

# Change download the latest src-expose binary
ENV LAST_UPDATED=2020-04-01

RUN BINARY_URL=https://storage.googleapis.com/sourcegraph-artifacts/src-expose/latest/linux-amd64/src-expose?v=$LAST_UPDATED && \
    wget -O /usr/local/bin/src-expose $BINARY_URL && \
    chmod +x /usr/local/bin/src-expose

WORKDIR /usr/app/data/
USER sourcegraph
CMD ["src-expose"]
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/src-expose"]
EXPOSE 3434
