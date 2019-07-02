.PHONY: build
build:
	docker build -t neos-form-yamlbuilder-build-env Build/
	docker run -v `pwd`:/app --rm neos-form-yamlbuilder-build-env cake build
