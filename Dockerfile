# Interim Dockerfile for demo and local testing purposes
FROM sourcegraph/alpine:3.9@sha256:e9264d4748e16de961a2b973cc12259dee1d33473633beccb1dfb8a0e62c6459

# Copy locally built binary
# COPY ./src-expose /usr/local/bin/src-expose

# Change to force a fresh download src-expose
ENV LAST_UPDATED=2019-10-09

# Download the latest uploaded binary using a cache bust param
RUN CACHE_BUST=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '') && \
    BINARY_URL=https://storage.googleapis.com/sourcegraph-artifacts/src-expose/latest/linux-amd64/src-expose?v=$CACHE_BUST && \
    wget -O /usr/local/bin/src-expose $BINARY_URL && \
    chmod +x /usr/local/bin/src-expose

WORKDIR /usr/app/data/
USER sourcegraph
CMD ["src-expose"]
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/src-expose"]
EXPOSE 3434
