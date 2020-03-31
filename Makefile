.PHONY: default
SOURCEGRAPH_VERSION=3.14.0

default:
	@echo "\nRun sourcegraph and src-expose with:\n"
	@echo "  make build"
	@echo "  make src-expose"
	@echo "  make sourcegraph\n"

###############
##  Perforce ##
###############
#
# Everything required for running a Perforce server with a sample depot 
# for local testing of src-expose. This is a WIP.
#
# Requires p4d to be on $PATH
#
PERFORCE_DATA_DIR := $(shell pwd)/perforce/data
.PHONY: perforce
perforce:
	@echo "[info]: downloading and configuring Perforce depot\n"
	@rm -fr $(PERFORCE_DATA_DIR)
	@wget ftp://ftp.perforce.com/perforce/tools/sampledepot-nostreams.zip
	@unzip -qq sampledepot-nostreams.zip && rm -f sampledepot-nostreams.zip
	@mv PerforceSample $(PERFORCE_DATA_DIR)

	p4d -r $(PERFORCE_DATA_DIR) -jr $(PERFORCE_DATA_DIR)/checkpoint
	p4d -r $(PERFORCE_DATA_DIR) -xu	

perforce-up:
	@echo "[info]: starting Perforce server\n"
	p4d -r $(PERFORCE_DATA_DIR) -p 1492 -d

perforce-down:
	@echo "[info]: stopping Perforce server\n"
	@$(shell kill $(shell pgrep -f p4d) > /dev/null 2> /dev/null || :)

## END PERFORCE ##

# Dowload set of directories (simpler alternative to using Perforce)
projects:
	@echo "[info]: downloading sample directories (projects)\n"
	@wget -O microservices-demo.zip https://github.com/GoogleCloudPlatform/microservices-demo/archive/master.zip
	@unzip -qq microservices-demo.zip
	@rm -f microservices-demo.zip
	@mv microservices-demo-master/src/ projects
	@ rm -fr microservices-demo-master

compile:
	@echo "[info]: compiling src-expose from sourcegraph master\n"
	@wget https://github.com/sourcegraph/sourcegraph/archive/master.zip
	@unzip -qq master.zip
	@cd sourcegraph-master && \
		env GOOS=linux CGO_ENABLED=0 GOARCH=amd64 go build ./dev/src-expose && \
		mv src-expose ../
	@chmod +x src-expose
	@rm -fr master.zip sourcegraph-master

compile-local:
	@echo "[info]: compiling src-expose from local sourcegraph directory\n"	
	@cd ../sourcegraph && \
		env GOOS=linux CGO_ENABLED=0 GOARCH=amd64 go build ./dev/src-expose && \
		mv src-expose ../src-expose-demo/
	@chmod +x src-expose

.PHONY: build
build:
	@echo "[info]: building src-expose Docker image\n"
	@docker image pull sourcegraph/alpine:3.9
	@docker image build -t sourcegraph/src-expose:latest .	

.PHONY: network
network:
	@echo "[info]: ensuring Docker network 'sourcegraph' exists\n"
	@$(eval NETWORK_ID=$(shell docker network ls -qf name=sourcegraph))

	@if [[ "$(NETWORK_ID)" = "" ]]; then \
		docker network create sourcegraph; \
	fi

SERVE_DIR := projects
.PHONY: src-expose
src-expose: network projects
	@echo "[info]: running src-expose Docker container\n"
	$(eval REPOS=$(shell cd `pwd`/$(SERVE_DIR) && ls -d *))
	@echo "[info]: serving subdirectories of '$(SERVE_DIR)' as Git repositories\n"
	docker container run -it \
  --rm \
  --name src-expose \
  --publish 3434:3434 \
  --volume $(shell pwd)/${SERVE_DIR}:/usr/app/data \
  --network sourcegraph \
  sourcegraph/src-expose:latest \
  -before "echo '*** run command to sync from non-Git VCS ***'" \
  -addr 0.0.0.0:3434 \
  $(REPOS)

# usage: make src-expose-serve /home/user/repos
# Path to local directory with Git repos must be absolute
src-expose-serve: network
	$(eval GIT_SERVE_DIR = $(filter-out $@,$(MAKECMDGOALS)))
	@echo "[info]: serving git repositories from '$(GIT_SERVE_DIR)'"
	docker container run -it \
  --rm \
  --name src-expose \
  --publish 3434:3434 \
  --volume $(GIT_SERVE_DIR):/usr/app/data \
  --network sourcegraph \
  sourcegraph/src-expose:latest \
	serve -addr 0.0.0.0:3434 /usr/app/data

.PHONY: sourcegraph
sourcegraph:
	@echo "[info]: running Sourcegraph server insiders Docker container\n"
	docker run --rm \
  --name sourcegraph \
  --network sourcegraph \
  --volume ~/.sourcegraph/config:/etc/sourcegraph \
  --volume ~/.sourcegraph/data:/var/opt/sourcegraph \
  --publish 7080:7080 \
  --publish 2633:2633 \
  sourcegraph/server:$(SOURCEGRAPH_VERSION)


#################
##  DEBUGGING  ##
#################

.PHONY: src-expose-shell
src-expose-shell:
	@echo "[info]: Launching shell inside src-expose container \n"
	@docker container exec -it src-expose sh

.PHONY: debug-container
debug-container:
	@echo "[info]: Launching Alpine container for debugging purposes \n"
	@docker container run -it \
    --rm \
    --network sourcegraph \
    sourcegraph/alpine:3.9@sha256:e9264d4748e16de961a2b973cc12259dee1d33473633beccb1dfb8a0e62c6459 \
    sh
