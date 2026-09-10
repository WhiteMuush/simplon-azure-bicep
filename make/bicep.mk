##@ Bicep

.PHONY: stacks check what-if deploy destroy outputs

stacks: ## List the available stacks
	@scripts/bicep/stacks.sh

check: ## Format, lint, then validate the stack against Azure
	@scripts/bicep/bicep.sh check "$(STACK)"

what-if: ## Show the changes the deployment would make
	@scripts/bicep/bicep.sh what-if "$(STACK)"

deploy: ## Create the resource group if needed, then deploy the stack
	@scripts/bicep/bicep.sh deploy "$(STACK)"

destroy: ## Delete the resource group of the stack, asks for confirmation
	@scripts/bicep/bicep.sh destroy "$(STACK)"

outputs: ## Print the outputs of the last deployment
	@scripts/bicep/bicep.sh outputs "$(STACK)"
