##@ Bicep

.PHONY: stacks check what-if deploy destroy outputs

stacks: ## List the available stacks
	@scripts/bicep/stacks.sh

check: ## Format, lint, then validate the stack against Azure
	@scripts/bicep/bicep.sh check "$(STACK)"

what-if: ## Check the subscription limits, then show the planned changes
	@scripts/bicep/bicep.sh what-if "$(STACK)"

deploy: ## Check the subscription limits, then deploy the stack
	@scripts/bicep/bicep.sh deploy "$(STACK)"

destroy: ## Delete the resources of the stack, asks for confirmation
	@scripts/bicep/bicep.sh destroy "$(STACK)"

outputs: ## Print the outputs of the deployed stack
	@scripts/bicep/bicep.sh outputs "$(STACK)"
