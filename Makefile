TOP := $(shell pwd)

REPOSITORY?=panta/restic-backup-docker
TAG?=latest-alpine

OK_COLOR=\033[32;01m
NO_COLOR=\033[0m

.PHONY: all
all: docker-build docker-publish

.PHONY: docker-build
docker-build:
	@echo "$(OK_COLOR)==>$(NO_COLOR) Building $(REPOSITORY):$(TAG)"
	@docker build --rm -t $(REPOSITORY):$(TAG) .

.PHONY: docker-publish
docker-publish:
	@echo "$(OK_COLOR)==>$(NO_COLOR) Pushing $(REPOSITORY):$(TAG)"
	@docker push $(REPOSITORY):$(TAG)
