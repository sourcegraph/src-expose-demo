NETWORK := sourcegraph
DATA_DIR := /usr/app/data
PORT := 3434
HOST_DATA_DIR := $(shell pwd)/projects
PERFORCE_DATA_DIR := $(shell pwd)/perforce/data
SOURCEGRAPH_VERSION := 3.9.1

.PHONY: default
default:
	@echo "\nRun sourcegraph and src-expose with:\n"
	@echo "  make build"
	@echo "  make network"
	@echo "  make src-expose\n"	
	@echo "  make sourcegraph"

###############
##  Perforce ##
###############
#
# Everything required for running a Perforce server with a sample depot 
# for local testing of src-expose
#
# Requires p4d to be on $PATH
#

.PHONY: perforce
perforce:
	@echo "\n[info]: downloading and configuring Perforce depot\n"
	@rm -fr $(PERFORCE_DATA_DIR)
	@wget ftp://ftp.perforce.com/perforce/tools/sampledepot-nostreams.zip
	@unzip -qq sampledepot-nostreams.zip && rm -f sampledepot-nostreams.zip
	@mv PerforceSample $(PERFORCE_DATA_DIR)

	p4d -r $(PERFORCE_DATA_DIR) -jr $(PERFORCE_DATA_DIR)/checkpoint
	p4d -r $(PERFORCE_DATA_DIR) -xu	

perforce-up:
	@echo "\n[info]: starting Perforce server\n"
	p4d -r $(PERFORCE_DATA_DIR) -p 1492 -d

perforce-down:
	@echo "\n[info]: stopping Perforce server\n"
	@$(shell kill $(shell pgrep -f p4d) > /dev/null 2> /dev/null || :)

## END PERFORCE ##


# Dowload set of directories (simpler alternative to using Perforce)
projects:
	@echo "\n[info]: downloading sample directories (projects)\n"
	@wget -O microservices-demo.zip https://github.com/GoogleCloudPlatform/microservices-demo/archive/master.zip
	@unzip -qq microservices-demo.zip
	@rm -f microservices-demo.zip
	@mv microservices-demo-master/src/ projects
	@ rm -fr microservices-demo-master

compile:
	@echo "\n[info]: compiling src-expose from sourcegraph master\n"
	@rm -fr ./master.zip sourcegraph-master
	@wget https://github.com/sourcegraph/sourcegraph/archive/master.zip
	@unzip -qq master.zip
	@cd ../sourcegraph && \
		env GOOS=linux CGO_ENABLED=0 GOARCH=amd64 go build ./dev/src-expose && \
		mv src-expose ../src-expose-demo
	@chmod +x ./src-expose
	@rm -fr ./master.zip sourcegraph-master

.PHONY: build
build: compile
	@echo "\n[info]: building src-expose Docker image\n"
	@docker image build -t sourcegraph/src-expose:latest .	
	@rm src-expose

.PHONY: network
network:
	@echo "\n[info]: ensuring Docker network "sourcegraph" exists\n"
	@$(eval NETWORK_ID=$(shell docker network ls -qf name=$(NETWORK)))

	@if [[ "$(NETWORK_ID)" = "" ]]; then \
		docker network create $(NETWORK); \
	fi

.PHONY: src-expose
src-expose:
	@echo "\n[info]: running src-expose Docker container\n"
	$(eval REPOS=$(shell cd $(HOST_DATA_DIR) && ls -d *))
	docker container run -it \
		--rm \
		--name src-expose \
		--publish $(PORT):$(PORT) \
		--volume ${HOST_DATA_DIR}:$(DATA_DIR) \
		--network $(NETWORK) \
		sourcegraph/src-expose:latest \
		-addr 0.0.0.0:3434 \
		$(REPOS)		

.PHONY: sourcegraph
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

.PHONY: src-expose-shell
src-expose-shell:
	@echo "\n[info]: Launching shell inside src-expose container \n"
	docker container exec -it src-expose sh

.PHONY: debug-container
debug-container:
	@echo "\n[info]: Launching Alpine container for debugging purposes \n"
	docker container run -it \
		--rm \
		--network $(NETWORK) \
		--volume /Users/rb/Projects/sourcegraph:/sourcegraph \
		sourcegraph/alpine:3.9@sha256:e9264d4748e16de961a2b973cc12259dee1d33473633beccb1dfb8a0e62c6459 \
		sh
