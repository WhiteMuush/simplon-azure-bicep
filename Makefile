-include config.env

STACK ?=

export RESOURCE_GROUP

include make/setup.mk
include make/bicep.mk

##@ General

.PHONY: help
help: ## Show this help
	@scripts/help.sh
