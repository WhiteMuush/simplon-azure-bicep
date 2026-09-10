-include config.env

LOCATION ?= francecentral
STACK ?=

export ALIAS
export LOCATION

include make/setup.mk
include make/bicep.mk

##@ General

.PHONY: help
help: ## Show this help
	@scripts/help.sh
