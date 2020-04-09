.PHONY: default

### DOCKER ###

docker-code-dirs:
	docker container run -it \
		--rm \
		--name src-expose \
		--publish 3434:3434 \
		--volume `pwd`/code/dirs:/app/data:delegated \
		--entrypoint /usr/local/bin/entry.sh \
		sourcegraph/src-expose

docker-git-repos:
	docker container run -it \
		--rm \
		--name src-expose \
		--publish 3434:3434 \
		--volume `pwd`/code/repos:/app/data:delegated \
		sourcegraph/src-expose serve ./


### KUBERNETES ##

build-code-sync:
	docker image build -f code-sync/Dockerfile -t src-expose/code-sync:latest code-sync

k8s-code-dirs: build-code-sync
	kubectl apply -f code-dirs.yaml
	@echo "[info]: Available internally at http://src-expose-code-dirs:3434"
	@echo "[info]: Available externally at http://localhost:30034"

k8s-git-repos: build-code-sync
	kubectl apply -f git-repos.yaml	
	@echo "[info]: Available internally at http://src-expose-git-repos:3434"
	@echo "[info]: Available externally at http://localhost:31034"

k8s-delete:
	kubectl delete -f ./


### SOURCEGRAPH ###

# Here for convenience
.PHONY: sourcegraph
sourcegraph:
	@echo "[info]: running Sourcegraph server insiders Docker container\n"
	docker run --rm \
  --name sourcegraph \
  --volume ~/.sourcegraph/config:/etc/sourcegraph \
  --volume ~/.sourcegraph/data:/var/opt/sourcegraph \
  --publish 7080:7080 \
  sourcegraph/server:3.14.1
