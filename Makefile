SHELL := /bin/bash

PROJECTNAME := $(shell basename "$(PWD)")
CREDENTIAL_SECRETS=.secrets.yaml
ROBOT_FILES=**/*.robot
CLUSTER_NAME=
PATH_TO_PROFILES_DIR=profiles
E2E_PYTHON_TAGS=
COMMIT_ID=
TEMP_DIRECTORY=
TAG=
# Example of DOCKER_REGISTRY: nexus.domain.com:443/
DOCKER_REGISTRY=
HELM_ADDITIONAL_PARAMS=

-include .env

.EXPORT_ALL_VARIABLES:

.PHONY: install-all install-cli install-services install-sdk

check-tag:
	@if [ "${TAG}" == "" ]; then \
	    echo "TAG not defined, please define TAG variable" ; exit 1 ;\
	fi
	@if [ "${DOCKER_REGISTRY}" == "" ]; then \
	    echo "DOCKER_REGISTRY not defined, please define DOCKER_REGISTRY variable" ; exit 1 ;\
	fi

## docker-build-jenkins: Build jenkins docker image
docker-build-jenkins:
	docker build -t legion/k8s-jenkins:latest -f containers/jenkins/Dockerfile .

## docker-build-ansible: Build ansible docker image
docker-build-ansible:
	docker build -t legion/k8s-jenkins-ansible:latest -f containers/toolchains/python/Dockerfile .

## docker-build-agent: Build agent docker image
docker-build-agent:
	docker build -t legion/jenkins-pipeline-agent:latest -f containers/agent/Dockerfile .

## docker-push-jenkins: Push jenkins docker image
docker-push-jenkins:
	docker tag legion/k8s-jenkins:latest ${DOCKER_REGISTRY}/legion/k8s-jenkins:${TAG}
	docker push ${DOCKER_REGISTRY}/legion/k8s-jenkins:${TAG}

## docker-push-ansible: Push ansible docker image
docker-push-ansible:  check-tag
	docker tag legion/k8s-jenkins-ansible:latest ${DOCKER_REGISTRY}/legion/k8s-jenkins-ansible:${TAG}
	docker push ${DOCKER_REGISTRY}/legion/k8s-jenkins-ansible:${TAG}

## docker-push-agent: Push agent docker image
docker-push-agent:  check-tag
	docker tag legion/jenkins-pipeline-agent:latest ${DOCKER_REGISTRY}/legion/jenkins-pipeline-agent:${TAG}
	docker push ${DOCKER_REGISTRY}/legion/jenkins-pipeline-agent:${TAG}

## e2e-robot: Run e2e robot tests
e2e-robot:
	pabot --verbose --processes 6 \
	      -v PATH_TO_PROFILES_DIR:profiles \
	      --listener legion.robot.process_reporter \
	      --outputdir target legion/tests/e2e/robot/tests/${ROBOT_FILES}

help: Makefile
	@echo "Choose a command run in "$(PROJECTNAME)":"
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo
