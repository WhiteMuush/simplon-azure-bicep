##@ Setup

.PHONY: ssh-key ssh-key-show my-ip

ssh-key: ## Generate the lab SSH key pair if it does not exist
	@scripts/setup/ssh-key.sh

ssh-key-show: ## Print the public key to pass as a deployment parameter
	@scripts/setup/ssh-key-show.sh

my-ip: ## Print your public source IP in CIDR form, for the NSG rule
	@scripts/setup/my-ip.sh
