# Copyright 2021 SAP SE or an SAP affiliate company. All rights reserved. This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the LICENSE file
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This make file is supposed to be included in the top-level make file.
# It can be reused by repos vendoring g/g to have some common make recipes for building and installing development
# tools as needed.
# Recipes in the top-level make file should declare dependencies on the respective tool recipes (e.g. $(CONTROLLER_GEN))
# as needed. If the required tool (version) is not built/installed yet, make will make sure to build/install it.
# The *_VERSION variables in this file contain the "default" values, but can be overwritten in the top level make file.

ifeq ($(strip $(shell go list -m 2>/dev/null)),github.com/gardener/gardener)
TOOLS_PKG_PATH             := ./hack/tools
else
# dependency on github.com/gardener/gardener/hack/tools is optional and only needed if other projects want to reuse
# install-promtool.sh, or logcheck. If they don't use it and the project doesn't depend on the package,
# silence the error to minimize confusion.
TOOLS_PKG_PATH             := $(shell go list -tags tools -f '{{ .Dir }}' github.com/gardener/gardener/hack/tools 2>/dev/null)
endif

TOOLS_BIN_DIR              := $(TOOLS_DIR)/bin
CONTROLLER_GEN             := $(TOOLS_BIN_DIR)/controller-gen
GEN_CRD_API_REFERENCE_DOCS := $(TOOLS_BIN_DIR)/gen-crd-api-reference-docs
GINKGO                     := $(TOOLS_BIN_DIR)/ginkgo
GOIMPORTS                  := $(TOOLS_BIN_DIR)/goimports
GOIMPORTSREVISER           := $(TOOLS_BIN_DIR)/goimports-reviser
GOLANGCI_LINT              := $(TOOLS_BIN_DIR)/golangci-lint
GO_ADD_LICENSE             := $(TOOLS_BIN_DIR)/addlicense
GO_APIDIFF                 := $(TOOLS_BIN_DIR)/go-apidiff
GO_VULN_CHECK              := $(TOOLS_BIN_DIR)/govulncheck
GO_TO_PROTOBUF             := $(TOOLS_BIN_DIR)/go-to-protobuf
HELM                       := $(TOOLS_BIN_DIR)/helm
IMPORT_BOSS                := $(TOOLS_BIN_DIR)/import-boss
KIND                       := $(TOOLS_BIN_DIR)/kind
KUBECTL                    := $(TOOLS_BIN_DIR)/kubectl
LOGCHECK                   := $(TOOLS_BIN_DIR)/logcheck.so # plugin binary
MOCKGEN                    := $(TOOLS_BIN_DIR)/mockgen
OPENAPI_GEN                := $(TOOLS_BIN_DIR)/openapi-gen
PROMTOOL                   := $(TOOLS_BIN_DIR)/promtool
PROTOC                     := $(TOOLS_BIN_DIR)/protoc
PROTOC_GEN_GOGO            := $(TOOLS_BIN_DIR)/protoc-gen-gogo
REPORT_COLLECTOR           := $(TOOLS_BIN_DIR)/report-collector
SETUP_ENVTEST              := $(TOOLS_BIN_DIR)/setup-envtest
SKAFFOLD                   := $(TOOLS_BIN_DIR)/skaffold
YAML2JSON                  := $(TOOLS_BIN_DIR)/yaml2json
YQ                         := $(TOOLS_BIN_DIR)/yq
VGOPATH                    := $(TOOLS_BIN_DIR)/vgopath

# default tool versions
GOLANGCI_LINT_VERSION ?= v1.55.2
GO_APIDIFF_VERSION ?= v0.7.0
GO_ADD_LICENSE_VERSION ?= v1.1.1
GOIMPORTSREVISER_VERSION ?= v3.6.0
GO_VULN_CHECK_VERSION ?= latest
HELM_VERSION ?= v3.13.2
KIND_VERSION ?= v0.20.0
KUBECTL_VERSION ?= v1.29.0
PROMTOOL_VERSION ?= 2.48.0
PROTOC_VERSION ?= 25.1
SKAFFOLD_VERSION ?= v2.9.0
YQ_VERSION ?= v4.40.4
VGOPATH_VERSION ?= v0.1.3

# tool versions from go.mod
CONTROLLER_GEN_VERSION ?= $(call version_gomod,sigs.k8s.io/controller-tools)
GINKGO_VERSION ?= $(call version_gomod,github.com/onsi/ginkgo/v2)
GEN_CRD_API_REFERENCE_DOCS_VERSION ?= $(call version_gomod,github.com/ahmetb/gen-crd-api-reference-docs)
GOIMPORTS_VERSION ?= $(call version_gomod,golang.org/x/tools)
CODE_GENERATOR_VERSION ?= $(call version_gomod,k8s.io/code-generator)
MOCKGEN_VERSION ?= $(call version_gomod,go.uber.org/mock)
OPENAPI_GEN_VERSION ?= $(call version_gomod,k8s.io/kube-openapi)
CONTROLLER_RUNTIME_VERSION ?= $(call version_gomod,sigs.k8s.io/controller-runtime)
YAML2JSON_VERSION ?= $(call version_gomod,github.com/bronze1man/yaml2json)

# default dir for importing tool binaries
TOOLS_BIN_SOURCE_DIR ?= /gardenertools

export TOOLS_BIN_DIR := $(TOOLS_BIN_DIR)
export PATH := $(abspath $(TOOLS_BIN_DIR)):$(PATH)

#########################################
# Common                                #
#########################################

# Tool targets should declare go.mod as a prerequisite, if the tool's version is managed via go modules. This causes
# make to rebuild the tool in the desired version, when go.mod is changed.
# For tools where the version is not managed via go.mod, we use a file per tool and version as an indicator for make
# whether we need to install the tool or a different version of the tool (make doesn't rerun the rule if the rule is
# changed).

# Use this "function" to add the version file as a prerequisite for the tool target: e.g.
#   $(HELM): $(call tool_version_file,$(HELM),$(HELM_VERSION))
tool_version_file = $(TOOLS_BIN_DIR)/.version_$(subst $(TOOLS_BIN_DIR)/,,$(1))_$(2)

# Use this function to get the version of a go module from go.mod
version_gomod = $(shell go list -mod=mod -f '{{ .Version }}' -m $(1))

# This target cleans up any previous version files for the given tool and creates the given version file.
# This way, we can generically determine, which version was installed without calling each and every binary explicitly.
$(TOOLS_BIN_DIR)/.version_%:
	@version_file=$@; rm -f $${version_file%_*}*
	@touch $@

.PHONY: clean-tools-bin
clean-tools-bin:
	rm -rf $(TOOLS_BIN_DIR)/*

.PHONY: import-tools-bin
import-tools-bin:
ifeq ($(shell if [ -d $(TOOLS_BIN_SOURCE_DIR) ]; then echo "found"; fi),found)
	@echo "Copying tool binaries from $(TOOLS_BIN_SOURCE_DIR)"
	@cp -rpT $(TOOLS_BIN_SOURCE_DIR) $(TOOLS_BIN_DIR)
endif

.PHONY: create-tools-bin
create-tools-bin: $(CONTROLLER_GEN) $(GEN_CRD_API_REFERENCE_DOCS) $(GINKGO) $(GOIMPORTS) $(GOIMPORTSREVISER) $(GO_ADD_LICENSE) $(GO_APIDIFF) $(GO_VULN_CHECK) $(GO_TO_PROTOBUF) $(HELM) $(IMPORT_BOSS) $(KIND) $(KUBECTL) $(MOCKGEN) $(OPENAPI_GEN) $(PROMTOOL) $(PROTOC) $(PROTOC_GEN_GOGO) $(SETUP_ENVTEST) $(SKAFFOLD) $(YAML2JSON) $(YQ) $(VGOPATH)

#########################################
# Tools                                 #
#########################################

$(CONTROLLER_GEN): $(call tool_version_file,$(CONTROLLER_GEN),$(CONTROLLER_GEN_VERSION))
	go build -o $(CONTROLLER_GEN) sigs.k8s.io/controller-tools/cmd/controller-gen

$(GEN_CRD_API_REFERENCE_DOCS): $(call tool_version_file,$(GEN_CRD_API_REFERENCE_DOCS),$(GEN_CRD_API_REFERENCE_DOCS_VERSION))
	go build -o $(GEN_CRD_API_REFERENCE_DOCS) github.com/ahmetb/gen-crd-api-reference-docs

$(GINKGO): $(call tool_version_file,$(GINKGO),$(GINKGO_VERSION))
	go build -o $(GINKGO) github.com/onsi/ginkgo/v2/ginkgo

$(GOIMPORTS): $(call tool_version_file,$(GOIMPORTS),$(GOIMPORTS_VERSION))
	go build -o $(GOIMPORTS) golang.org/x/tools/cmd/goimports

$(GOIMPORTSREVISER): $(call tool_version_file,$(GOIMPORTSREVISER),$(GOIMPORTSREVISER_VERSION))
	GOBIN=$(abspath $(TOOLS_BIN_DIR)) go install github.com/incu6us/goimports-reviser/v3@$(GOIMPORTSREVISER_VERSION)

$(GOLANGCI_LINT): $(call tool_version_file,$(GOLANGCI_LINT),$(GOLANGCI_LINT_VERSION))
	@# CGO_ENABLED has to be set to 1 in order for golangci-lint to be able to load plugins
	@# see https://github.com/golangci/golangci-lint/issues/1276
	GOBIN=$(abspath $(TOOLS_BIN_DIR)) CGO_ENABLED=1 go install github.com/golangci/golangci-lint/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)

$(GO_ADD_LICENSE):  $(call tool_version_file,$(GO_ADD_LICENSE),$(GO_ADD_LICENSE_VERSION))
	GOBIN=$(abspath $(TOOLS_BIN_DIR)) go install github.com/google/addlicense@$(GO_ADD_LICENSE_VERSION)

$(GO_APIDIFF): $(call tool_version_file,$(GO_APIDIFF),$(GO_APIDIFF_VERSION))
	GOBIN=$(abspath $(TOOLS_BIN_DIR)) go install github.com/joelanford/go-apidiff@$(GO_APIDIFF_VERSION)

$(GO_VULN_CHECK): $(call tool_version_file,$(GO_VULN_CHECK),$(GO_VULN_CHECK_VERSION))
	GOBIN=$(abspath $(TOOLS_BIN_DIR)) go install golang.org/x/vuln/cmd/govulncheck@$(GO_VULN_CHECK_VERSION)

$(GO_TO_PROTOBUF): $(call tool_version_file,$(GO_TO_PROTOBUF),$(CODE_GENERATOR_VERSION))
	go build -o $(GO_TO_PROTOBUF) k8s.io/code-generator/cmd/go-to-protobuf

$(HELM): $(call tool_version_file,$(HELM),$(HELM_VERSION))
	curl -sSfL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | HELM_INSTALL_DIR=$(TOOLS_BIN_DIR) USE_SUDO=false bash -s -- --version $(HELM_VERSION)

$(IMPORT_BOSS): $(call tool_version_file,$(IMPORT_BOSS),$(CODE_GENERATOR_VERSION))
	go build -o $(IMPORT_BOSS) k8s.io/code-generator/cmd/import-boss

$(KIND): $(call tool_version_file,$(KIND),$(KIND_VERSION))
	curl -L -o $(KIND) https://kind.sigs.k8s.io/dl/$(KIND_VERSION)/kind-$(shell uname -s | tr '[:upper:]' '[:lower:]')-$(shell uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
	chmod +x $(KIND)

$(KUBECTL): $(call tool_version_file,$(KUBECTL),$(KUBECTL_VERSION))
	curl -Lo $(KUBECTL) https://dl.k8s.io/release/$(KUBECTL_VERSION)/bin/$(shell uname -s | tr '[:upper:]' '[:lower:]')/$(shell uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')/kubectl
	chmod +x $(KUBECTL)

ifeq ($(strip $(shell go list -m 2>/dev/null)),github.com/gardener/gardener)
$(LOGCHECK): $(TOOLS_PKG_PATH)/logcheck/go.* $(shell find $(TOOLS_PKG_PATH)/logcheck -type f -name '*.go')
	cd $(TOOLS_PKG_PATH)/logcheck; CGO_ENABLED=1 go build -o $(abspath $(LOGCHECK)) -buildmode=plugin ./plugin
else
$(LOGCHECK): go.mod
	CGO_ENABLED=1 go build -o $(LOGCHECK) -buildmode=plugin github.com/gardener/gardener/hack/tools/logcheck/plugin
endif

$(MOCKGEN): $(call tool_version_file,$(MOCKGEN),$(MOCKGEN_VERSION))
	go build -o $(MOCKGEN) go.uber.org/mock/mockgen

$(OPENAPI_GEN): $(call tool_version_file,$(OPENAPI_GEN),$(OPENAPI_GEN_VERSION))
	go build -o $(OPENAPI_GEN) k8s.io/kube-openapi/cmd/openapi-gen

$(PROMTOOL): $(call tool_version_file,$(PROMTOOL),$(PROMTOOL_VERSION))
	@PROMTOOL_VERSION=$(PROMTOOL_VERSION) $(TOOLS_PKG_PATH)/install-promtool.sh

$(PROTOC): $(call tool_version_file,$(PROTOC),$(PROTOC_VERSION))
	@PROTOC_VERSION=$(PROTOC_VERSION) $(TOOLS_PKG_PATH)/install-protoc.sh

$(PROTOC_GEN_GOGO): $(call tool_version_file,$(PROTOC_GEN_GOGO),$(CODE_GENERATOR_VERSION))
	go build -o $(PROTOC_GEN_GOGO) k8s.io/code-generator/cmd/go-to-protobuf/protoc-gen-gogo

ifeq ($(strip $(shell go list -m 2>/dev/null)),github.com/gardener/gardener)
$(REPORT_COLLECTOR): $(TOOLS_PKG_PATH)/report-collector/*.go
	go build -o $(REPORT_COLLECTOR) $(TOOLS_PKG_PATH)/report-collector
else
$(REPORT_COLLECTOR): go.mod
	go build -o $(REPORT_COLLECTOR) github.com/gardener/gardener/hack/tools/report-collector
endif

$(SETUP_ENVTEST): $(call tool_version_file,$(SETUP_ENVTEST),$(CONTROLLER_RUNTIME_VERSION))
	go build -o $(SETUP_ENVTEST) sigs.k8s.io/controller-runtime/tools/setup-envtest

$(SKAFFOLD): $(call tool_version_file,$(SKAFFOLD),$(SKAFFOLD_VERSION))
	curl -Lo $(SKAFFOLD) https://storage.googleapis.com/skaffold/releases/$(SKAFFOLD_VERSION)/skaffold-$(shell uname -s | tr '[:upper:]' '[:lower:]')-$(shell uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
	chmod +x $(SKAFFOLD)

$(YAML2JSON): $(call tool_version_file,$(YAML2JSON),$(YAML2JSON_VERSION))
	go build -o $(YAML2JSON) github.com/bronze1man/yaml2json

$(YQ): $(call tool_version_file,$(YQ),$(YQ_VERSION))
	curl -L -o $(YQ) https://github.com/mikefarah/yq/releases/download/$(YQ_VERSION)/yq_$(shell uname -s | tr '[:upper:]' '[:lower:]')_$(shell uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
	chmod +x $(YQ)

$(VGOPATH): $(call tool_version_file,$(VGOPATH),$(VGOPATH_VERSION))
	go build -o $(VGOPATH) github.com/ironcore-dev/vgopath
