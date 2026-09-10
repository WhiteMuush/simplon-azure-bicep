#!/usr/bin/env bash
# Wire GitHub Actions to Azure without any stored secret: an app registration,
# two federated credentials, one role assignment, and the repository variables
# the workflows read. Safe to run twice.

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

require_resource_group
require_az
command -v gh >/dev/null || die "GitHub CLI not found."

REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
APP_NAME="${APP_NAME:-gh-$(basename "$REPO")}"
ENVIRONMENT="${ENVIRONMENT:-azure}"

SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"
SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}"

step "Application registration"
APP_ID="$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)"
if [ -z "$APP_ID" ]; then
  APP_ID="$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)"
  ok "Created ${APP_NAME}"
else
  ok "${APP_NAME} already there"
fi

az ad sp show --id "$APP_ID" >/dev/null 2>&1 || az ad sp create --id "$APP_ID" --output none
OBJECT_ID="$(az ad sp show --id "$APP_ID" --query id -o tsv)"

step "Federated credentials"
# One subject per context GitHub can present: the branch for the first jobs,
# the environment for the ones a human approves.
add_credential() {
  local name="$1" subject="$2"
  if az ad app federated-credential list --id "$APP_ID" --query "[?name=='${name}']" -o tsv | grep -q .; then
    ok "${name} already there"
    return
  fi
  az ad app federated-credential create --id "$APP_ID" --parameters "{
    \"name\": \"${name}\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"${subject}\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }" --output none
  ok "Created ${name}"
}

add_credential "${ENVIRONMENT}-environment" "repo:${REPO}:environment:${ENVIRONMENT}"
add_credential "main-branch" "repo:${REPO}:ref:refs/heads/main"

step "Role assignment"
if az role assignment list --assignee "$OBJECT_ID" --scope "$SCOPE" --query "[?roleDefinitionName=='Contributor']" -o tsv | grep -q .; then
  ok "Contributor on ${RESOURCE_GROUP} already there"
else
  az role assignment create --assignee-object-id "$OBJECT_ID" \
    --assignee-principal-type ServicePrincipal \
    --role Contributor --scope "$SCOPE" --output none
  ok "Contributor granted on ${RESOURCE_GROUP}"
fi

step "Repository variables"
set_variable() {
  gh variable set "$1" --body "$2" --repo "$REPO"
  field "$1" "$2"
}

set_variable AZURE_CLIENT_ID "$APP_ID"
set_variable AZURE_TENANT_ID "$TENANT_ID"
set_variable AZURE_SUBSCRIPTION_ID "$SUBSCRIPTION_ID"
set_variable AZURE_RESOURCE_GROUP "$RESOURCE_GROUP"
set_variable SSH_PUBLIC_KEY "${SSH_PUBLIC_KEY:-}"
set_variable ALLOWED_SSH_SOURCE_IP "${MY_SOURCE_IP:-}"

step "Ready"
field "Environment" "$ENVIRONMENT"
field "Next" "add a required reviewer on the '${ENVIRONMENT}' environment"
echo
