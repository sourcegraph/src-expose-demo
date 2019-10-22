NETWORK=sourcegraph
DATA_DIR=/usr/app/data
PORT=3434
HOST_DATA_DIR=$(shell pwd)/PerforceSample/depot
REPOS=./Jam ./Jamgraph
SOURCEGRAPH_VERSION := 3.9.1

get-sample-depot:
	rm -fr ./sampledepot-nostreams.zip ./PerforceSample
	wget ftp://ftp.perforce.com/perforce/tools/sampledepot-nostreams.zip
	unzip -qq sampledepot-nostreams.zip
	rm -f sampledepot-nostreams.zip

compile:
	rm -fr ./master.zip sourcegraph-master
	wget https://github.com/sourcegraph/sourcegraph/archive/master.zip
	unzip -qq master.zip
	cd ../sourcegraph && \
		env GOOS=linux CGO_ENABLED=0 GOARCH=amd64 go build ./dev/src-expose && \
		mv src-expose ../src-expose-demo
	chmod +x ./src-expose
	rm -fr ./master.zip sourcegraph-master

build: compile get-sample-depot
	@echo "\n[info]: building src-expose Docker image\n"
	docker image build -t sourcegraph/src-expose:latest .	

network:
	@echo "\n[info]: creating "sourcgraph" Docker network\n"
	docker network create $(NETWORK)

run:
	@echo "\n[info]: running src-expose Docker container\n"
	docker container run -it \
		--rm \
		--name src-expose \
		--publish $(PORT):$(PORT) \
		--volume ${HOST_DATA_DIR}:$(DATA_DIR) \
		--network $(NETWORK) \
		sourcegraph/src-expose:latest \
		-addr 0.0.0.0:3434 \
		$(REPOS)		

sourcegraph:
	@echo "\n[info]: running Sourcegraph server insiders Docker container\n"
	docker run --rm \
		--name sourcegraph \
		--network $(NETWORK) \
		--volume ~/.sourcegraph/config:/etc/sourcegraph \
		--volume ~/.sourcegraph/data:/var/opt/sourcegraph \
		--publish 7080:7080 \
		--publish 2633:2633 \
		sourcegraph/server:$(SOURCEGRAPH_VERSION)


### DEBUGGING ###

src-expose-shell:
	@echo "\n[info]: Launching shell inside src-expose container \n"
	docker container exec -it src-expose sh

debug-container:
	@echo "\n[info]: Launching Alpine container for debugging purposes \n"
	docker container run -it \
		--rm \
		--network $(NETWORK) \
		--volume /Users/rb/Projects/sourcegraph:/sourcegraph \
		sourcegraph/alpine:3.9@sha256:e9264d4748e16de961a2b973cc12259dee1d33473633beccb1dfb8a0e62c6459 \
		sh
