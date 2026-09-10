##@ Bicep

.PHONY: stacks check preflight what-if deploy destroy outputs

stacks: ## List the available stacks
	@scripts/bicep/stacks.sh

check: ## Format, lint, then validate the stack against Azure
	@scripts/bicep/bicep.sh check "$(STACK)"

preflight: ## Check the stack against what this subscription allows
	@scripts/bicep/preflight.sh "$(STACK)"

what-if: ## Show the changes the deployment would make
	@scripts/bicep/bicep.sh what-if "$(STACK)"

deploy: ## Deploy the stack into the configured resource group
	@scripts/bicep/bicep.sh deploy "$(STACK)"

destroy: ## Delete the resources of the stack, asks for confirmation
	@scripts/bicep/bicep.sh destroy "$(STACK)"

outputs: ## Print the outputs of the deployed stack
	@scripts/bicep/bicep.sh outputs "$(STACK)"
