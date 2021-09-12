DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
MAKEFILE_PATH := $(DIR)/Makefile

OPENAPI_GENERATOR_CLI_IMAGE_TAG := v5.0.1
OPENAPI_VALIDATOR_IMAGE_TAG := 0.38.0
MAVEN_DIGEST := sha256:95de2b5763a6542ea9f4c2cbd954bbdc3d41d9629a914928e1d2bec1adfe7243

default: setup

# set up
.PHONY: init
init:
	make setup_server_stub

# set up server stub
.PHONY: setup_server_stub
setup_server_stub:
	make validate_openapi
	make generate_server_stub
	make build_server_stub

# generate the server stub
.PHONY: generate_server_stub
generate_server_stub:
	make clean_server_stub
	mkdir -p $(DIR)/ServerStub
	docker run --rm \
	-v $(DIR):/local \
	-e JAVA_OPTS="-Dlog.level=warn" \
	openapitools/openapi-generator-cli generate \
		-i /local/openapi.yaml \
		-g spring \
		-o /local/ServerStub \
		--additional-properties returnSuccessCode=true,serverPort=8080

# build the server stub
.PHONY: build_server_stub
build_server_stub:
	docker run --rm \
	-v $(DIR)/ServerStub:/local \
	-v ~/.m2:/root/.m2 \
	-w /local \
	maven mvn package

# run the server stub
.PHONY: run
run:
	docker run --rm \
	-v $(DIR)/ServerStub:/local \
	-w /local \
	-p 3000:8080 \
	openjdk java -jar target/openapi-spring-1.0.0.jar

# validate the oepnapi.yaml
.PHONY: validate_openapi
validate_openapi:
	docker run --rm \
	-v $(DIR):/local \
	jamescooke/openapi-validator \
		--verbose \
		--report_statistics \
		--config /local/.validaterc.json \
		/local/openapi.yaml

# clean server stub
clean_server_stub:
	rm -rf $(DIR)/ServerStub
