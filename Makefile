# Old-skool build tools.
# TODO: clean up this file

.DEFAULT_GOAL := build

ARCH?=amd64
OUT_DIR?=./_output

TAG ?= openshift/online-hibernation
TARGET ?= prod

DOCKERFILE := Dockerfile
ifeq ($(TARGET),dev)
DOCKERFILE := Dockerfile.local
endif

# Builds and installs the hibernation binary.
build: check-gopath
	CGO_ENABLED=0 GOARCH=$(ARCH) go build -a \
		-o $(OUT_DIR)/$(ARCH)/hibernate github.com/openshift/online-hibernation/cmd/hibernate
.PHONY: build


# Runs the integration tests.
#
# Args:
#   TESTFLAGS: Flags to pass to `go test`. The `-v` argument is always passed.
#
# Examples:
#   make test-integration TESTFLAGS="-run TestSomething"
test-integration: build
	go test -v $(TESTFLAGS) \
		github.com/openshift/online-hibernation/pkg/...

.PHONY: test
# Runs the unit tests.
#
# Args:
#   TESTFLAGS: Flags to pass to `go test`. The `-v` argument is always passed.
#
# Examples:
#   make test TESTFLAGS="-run TestSomething"
test: build
	go test -v $(TESTFLAGS) \
		github.com/openshift/online-hibernation/pkg/cache/... github.com/openshift/online-hibernation/pkg/idling/...
.PHONY: test


# Build a release image. The resulting image can be used with test-release.
#
# Args:
#   TAG: Docker image tag to apply to the built image. If not specified, the
#     default tag "openshift/online-hibernation" will be used.
#
# Example:
#   make release TAG="my/online-hibernation"
release:
	docker build --rm -f $(DOCKERFILE) -t $(TAG) .
.PHONY: release


# Tests a release image.
#
# Prerequisites:
#   A release image must be built and tagged (make release)
#
# Examples:
#
#   make test-release
#   make test-release TAG="my/online-hibernation"
test-release:
	docker run --rm -ti \
		$(DOCKERFLAGS) \
		--entrypoint make \
		$(TAG) \
		test
.PHONY: test-release


# Verifies that source passes standard checks.
verify:
	$(GOPATH)/src/github.com/openshift/online/hack/verify-source.sh
	go vet \
		github.com/openshift/online-hibernation/cmd/... \
		github.com/openshift/online-hibernation/pkg/...
.PHONY: verify


# Prints a list of useful targets.
help:
	@echo ""
	@echo "OpenShift Online Hibernation Controller"
	@echo ""
	@echo "make build                compile binaries"
	@echo "make test-integration     run integration tests"
	@echo "make release              build release image using Dockerfile"
	@echo "make test-release         run unit and integration tests in Docker container"
	@echo "make verify               lint source code"
	@echo ""
.PHONY: help

# Checks if a GOPATH is set, or emits an error message
check-gopath:
ifndef GOPATH
	$(error GOPATH is not set)
endif
.PHONY: check-gopath
