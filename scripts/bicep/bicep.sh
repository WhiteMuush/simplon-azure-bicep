#!/usr/bin/env bash
# Run one Bicep action against one stack: build, validate, what-if, deploy,
# destroy or outputs. Called by the targets of make/bicep.mk.

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

ACTION="${1:-}"
[ -n "$ACTION" ] || die "Usage: bicep.sh <action> [stack]"

resolve_stack "${2:-}"

TEMPLATE="$(stack_template "$STACK_NAME")"
PARAMS="$(stack_params "$STACK_NAME")"

[ -f "$TEMPLATE" ] || die "No template at ${TEMPLATE}."

require_resource_group
require_az
az group show --name "$RESOURCE_GROUP" >/dev/null 2>&1 ||
  die "Resource group '${RESOURCE_GROUP}' not found. Run 'make setup'."

template_args() {
  printf '%s\n' --resource-group "$RESOURCE_GROUP" --name "$STACK_NAME" --template-file "$TEMPLATE"
  [ -z "$PARAMS" ] || printf '%s\n' --parameters "$PARAMS"
}

warn_missing_params() {
  [ -n "$PARAMS" ] && return 0
  warn "No dev.bicepparam next to the template, parameters will be prompted"
}

case "$ACTION" in
  check)
    step "Formatting ${STACK_NAME}"
    az bicep format --file "$TEMPLATE"
    [ -z "$PARAMS" ] || az bicep format --file "$PARAMS"
    ok "Files formatted"

    step "Linting ${STACK_NAME}"
    az bicep lint --file "$TEMPLATE"
    ok "No linter error"

    step "Validating ${STACK_NAME} against ${RESOURCE_GROUP}"
    warn_missing_params
    mapfile -t args < <(template_args)
    az deployment group validate "${args[@]}" --output none
    ok "Template valid"
    ;;

  what-if)
    step "Planned changes for ${STACK_NAME} in ${RESOURCE_GROUP}"
    warn_missing_params
    mapfile -t args < <(template_args)
    az deployment group what-if "${args[@]}"
    ;;

  deploy)
    # A deployment stack, not a plain deployment: the resource group is shared
    # and pre-created, so the stack is what remembers which resources to remove.
    step "Deploying ${STACK_NAME} to ${RESOURCE_GROUP}"
    warn_missing_params
    mapfile -t args < <(template_args)
    az stack group create "${args[@]}" \
      --action-on-unmanage deleteAll \
      --deny-settings-mode none \
      --yes \
      --output none
    ok "Deployed, run 'make outputs STACK=${STACK_NAME}' to see the outputs"
    ;;

  destroy)
    step "Deleting the resources of ${STACK_NAME} in ${RESOURCE_GROUP}"
    az stack group show --resource-group "$RESOURCE_GROUP" --name "$STACK_NAME" >/dev/null 2>&1 ||
      die "Nothing to delete, ${STACK_NAME} was never deployed."

    if [ -z "${FORCE:-}" ]; then
      [ -t 0 ] || die "Not a terminal. Re-run with FORCE=1 to skip the prompt."
      read -r -p "  Delete every resource of ${STACK_NAME}? Type the stack name: " answer
      [ "$answer" = "$STACK_NAME" ] || die "Answer did not match, nothing deleted."
    fi

    az stack group delete --resource-group "$RESOURCE_GROUP" --name "$STACK_NAME" \
      --action-on-unmanage deleteAll --yes --output none
    ok "Resources deleted, the resource group itself is left untouched"
    ;;

  outputs)
    step "Outputs of ${STACK_NAME}"
    az stack group show --resource-group "$RESOURCE_GROUP" --name "$STACK_NAME" \
      --query outputs --output json
    ;;

  *)
    die "Unknown action '${ACTION}'."
    ;;
esac
