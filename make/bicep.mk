##@ Bicep

.PHONY: stacks build validate what-if deploy destroy outputs

stacks: ## List the available stacks
	@scripts/bicep/stacks.sh

build: ## Compile the stack to check it is syntactically valid
	@scripts/bicep/bicep.sh build "$(STACK)"

validate: ## Validate the stack against Azure without deploying
	@scripts/bicep/bicep.sh validate "$(STACK)"

what-if: ## Show the changes the deployment would make
	@scripts/bicep/bicep.sh what-if "$(STACK)"

deploy: ## Create the resource group if needed, then deploy the stack
	@scripts/bicep/bicep.sh deploy "$(STACK)"

destroy: ## Delete the resource group of the stack, asks for confirmation
	@scripts/bicep/bicep.sh destroy "$(STACK)"

outputs: ## Print the outputs of the last deployment
	@scripts/bicep/bicep.sh outputs "$(STACK)"
