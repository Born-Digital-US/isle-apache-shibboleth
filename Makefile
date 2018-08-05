DATE_RFC3339=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
VERSION_DATE=`date -u +"%Y%m%dT%H%M%SZ"`
VERSION ?= RC-$(DATE_RFC3339)
TAG ?= RC-$(VERSION_DATE)

docker_build:
	@docker build \
	--build-arg BUILD_DATE=$(DATE_RFC3339) \
	--build-arg VCS_REF=`git rev-parse --short HEAD` \
	--build-arg VERSION=$(VERSION) \
	--tag isle-apache:$(TAG) .

default: docker_build