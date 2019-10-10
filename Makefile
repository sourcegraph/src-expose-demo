NETWORK=sourcegraph
DATA_DIR=/usr/app/data
PORT=3434
HOST_DATA_DIR=$(shell pwd)/PerforceSample/depot
REPOS=Jam

get-sample-depot:
	rm -fr ./sampledepot-nostreams.zip ./PerforceSample
	wget -qq ftp://ftp.perforce.com/perforce/tools/sampledepot-nostreams.zip
	unzip -qq sampledepot-nostreams.zip
	rm -f sampledepot-nostreams.zip

# Not using right now, as the Dockerfile downloads a built binary from Google cloud using
# https://github.com/sourcegraph/sourcegraph/blob/master/dev/src-expose/release.sh
compile:
	rm -fr ./master.zip sourcegraph-master
	wget -qq https://github.com/sourcegraph/sourcegraph/archive/master.zip
	unzip -qq master.zip
	cd sourcegraph-master && \
		env GOOS=linux CGO_ENABLED=0 GOARCH=amd64 go build ./dev/src-expose && \
		mv src-expose ../
	chmod +x ./src-expose
	rm -fr ./master.zip sourcegraph-master

build: get-sample-depot
	docker image build -t sourcegraph/src-expose:latest .

network:
	docker network create $(NETWORK)

run:	
	docker container run -it \
		--rm \
		--name src-expose \
		--publish $(PORT):$(PORT) \
		--volume ${HOST_DATA_DIR}:$(DATA_DIR) \
		--network $(NETWORK) \
		sourcegraph/src-expose:latest \
		serve $(REPOS)

sourcegraph:
	docker image pull sourcegraph/server:insiders
	docker run --rm \
		--name sourcegraph \
		--network $(NETWORK) \
		--volume ~/.sourcegraph/config:/etc/sourcegraph \
		--volume ~/.sourcegraph/data:/var/opt/sourcegraph \
		--publish 7080:7080 \
		--publish 2633:2633 \
		sourcegraph/server:insiders


### DEBUGGING ###

src-expose-shell:
	docker container exec -it src-expose sh

debug-container:
	docker container run -it \
		--rm \
		--network $(NETWORK) \
		--volume /Users/rb/Projects/sourcegraph:/sourcegraph \
		sourcegraph/alpine:3.9@sha256:e9264d4748e16de961a2b973cc12259dee1d33473633beccb1dfb8a0e62c6459 \
		sh
