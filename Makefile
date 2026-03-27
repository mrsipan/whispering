.PHONY : clean deploy

.EXPORT_ALL_VARIABLES:
LW_ACCOUNT_NAME = $(bamboo.LW_ACCOUNT_NAME)
LW_ACCESS_TOKEN_PASSWORD = $(bamboo.LW_ACCESS_TOKEN_PASSWORD)

version_chart := 0.0.1
version_app := v1.8.4
img_patch := 1
name := whispering
tmpdir := $(shell mktemp -d)
curdir := $(shell pwd)
docker := $(shell command -v podman || command -v docker)
distro := fedora
namespace := llm

docker-build:
	-$(docker) rmi $(name)
	# $(docker) build --platform=linux/amd64 -t $(name) \
	#
	$(docker) build --tls-verify=false -t $(name) \
		-f Dockerfile --build-arg=LLAMA_CPP_VERSION_ARG=$(version_app) .
	$(docker) tag $(name):latest \
		867279688038.dkr.ecr.us-east-1.amazonaws.com/sncr/sip/$(name):$(version_app)-$(img_patch)
	$(docker) tag $(name):latest \
		ghcr.io/mrsipan/$(name):$(version_app)-$(img_patch)
	$(docker) tag $(name):latest \
		docker-write.synchronoss.net/sncr/sip/$(name):$(version_app)-$(img_patch)

helm-package:
	sed -i -e 's/tag: "\(.*\)"/tag: "$(version_app)-$(img_patch)"/g' charts/$(name)/values.yaml
	sed -i -e 's/appVersion: "\(.*\)"/appVersion: "$(version_app)"/g' charts/$(name)/Chart.yaml
	sed -i -e 's/version: \(.*\)/version: $(version_chart)/g' charts/$(name)/Chart.yaml
	helm package charts/$(name)

helm-upgrade:
	helm -n $(namespace) upgrade --install $(name) -f charts/$(name)/values.yaml charts/$(name)/

helm-template:
	helm -n $(namespace) template $(name) -f charts/$(name)/values.yaml charts/$(name)/

helm-curl-upload:
	curl -i -v -T $(name)-$(version_chart).tgz \
		-u $(HELM_USER):$(HELM_PASSWORD) \
		"https://docker-write.synchronoss.net:8443/repository/helm-releases/"

helm-push:
	helm push \
		$(name)-$(version_chart).tgz \
		https://docker-write.synchronoss.net:8443/repository/helm-releases/

helm: helm-package helm-curl-upload

docker-login:
	aws ecr get-login-password --region us-east-1 | $(docker) login \
		--username AWS --password-stdin 867279688038.dkr.ecr.us-east-1.amazonaws.com

docker-push:
	$(docker) push 867279688038.dkr.ecr.us-east-1.amazonaws.com/sncr/sip/$(name):$(version_app)-$(img_patch)

docker-push-github:
	$(docker) push ghcr.io/mrsipan/$(name):$(version_app)-$(img_patch)

docker-login-nexus:
	$(docker) login -u "$(DOCKER_DEPLOY_USER)" -p "$(DOCKER_DEPLOY_PASSWORD)" \
		docker-write.synchronoss.net

docker-push-nexus:
	$(docker) push docker-write.synchronoss.net/sncr/sip/$(name):$(version_app)-$(img_patch)

docker-all: docker-build docker-login-nexus docker-push-nexus

helmfile-mldev:
	helmfile sync -f helmfiles/mldev.helmfile.yaml

# lacework:
# 	. ./utils/lacework.sh
