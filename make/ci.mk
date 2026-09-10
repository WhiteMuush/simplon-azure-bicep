##@ CI

.PHONY: ci-setup

ci-setup: ## Wire GitHub Actions to Azure with OIDC, no secret stored
	@scripts/ci/azure-oidc.sh
