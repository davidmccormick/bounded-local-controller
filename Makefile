SERVER_NAME := davidmccormick
IMAGE_NAME := bounded-local-controller
VERSION := $(shell cat VERSION)

.PHONY : build publish

version:
		@echo $(VERSION)

pull:
		-docker pull $(SERVER_NAME)/$(IMAGE_NAME):latest

build: pull
		docker build -t $(IMAGE_NAME) -f Dockerfile .

tag:
		@echo "***Tagging $(IMAGE-NAME) $(VERSION)***"
		docker tag $(IMAGE_NAME) $(SERVER_NAME)/$(IMAGE_NAME):$(VERSION)
		docker tag $(IMAGE_NAME) $(SERVER_NAME)/$(IMAGE_NAME):latest

push:
		@echo "***Pushing $(IMAGE-NAME) $(VERSION)***"
		docker push $(SERVER_NAME)/$(IMAGE_NAME):$(VERSION)
		docker push $(SERVER_NAME)/$(IMAGE_NAME):latest

publish: tag push
