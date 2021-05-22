REPONAME=secrets

RELEASE_LEVEL ?= staging
VERSION ?= $(shell git rev-parse HEAD)

build:
	DOCKER_CONTENT_TRUST=1 docker build --build-arg release_level=${RELEASE_LEVEL} --build-arg release_number=${VERSION} -f Dockerfile.release -t $(REPONAME):release ../..

setup:
	mix do ecto.create -r Audit.Repo, ecto.migrate -r Audit.Repo
