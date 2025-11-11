# Project settings
PROJECT := github.com/album/backend
BIN_DIR := bin

# Version metadata (can be overridden by environment variables)
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
BUILD_TIME ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)
GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)

# Shared ldflags
LDFLAGS := -X '$(PROJECT)/internal/version.Version=$(VERSION)' \
           -X '$(PROJECT)/internal/version.BuildTime=$(BUILD_TIME)' \
           -X '$(PROJECT)/internal/version.GitCommit=$(GIT_COMMIT)' \
           -X '$(PROJECT)/internal/version.GitBranch=$(GIT_BRANCH)'

.PHONY: all build build-server build-cli clean print-version

all: build

build: build-server build-cli

build-server:
	@echo ">> building server (version: $(VERSION))"
	@mkdir -p $(BIN_DIR)
	go build -ldflags "$(LDFLAGS)" -o $(BIN_DIR)/album-server ./cmd/server

build-cli:
	@echo ">> building cli (version: $(VERSION))"
	@mkdir -p $(BIN_DIR)
	go build -ldflags "$(LDFLAGS)" -o $(BIN_DIR)/album-cli ./cmd/cli

print-version:
	@echo "Version:    $(VERSION)"
	@echo "BuildTime:  $(BUILD_TIME)"
	@echo "GitCommit:  $(GIT_COMMIT)"
	@echo "GitBranch:  $(GIT_BRANCH)"

clean:
	@echo ">> removing $(BIN_DIR)/"
	rm -rf $(BIN_DIR)
