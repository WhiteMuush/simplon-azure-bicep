#!/usr/bin/env bash
# Run one Bicep action against one stack: build, validate, what-if, deploy,
# destroy or outputs. Called by the targets of make/bicep.mk.

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

require_alias

ACTION="${1:-}"
[ -n "$ACTION" ] || die "Usage: bicep.sh <action> [stack]"

resolve_stack "${2:-}"

RG="$(stack_rg "$STACK_NAME")"
TEMPLATE="$(stack_template "$STACK_NAME")"
PARAMS="$(stack_params "$STACK_NAME")"

[ -f "$TEMPLATE" ] || die "No template at ${TEMPLATE}."

# Every action but 'build' talks to Azure.
[ "$ACTION" = "build" ] || require_az

deployment_args() {
  printf '%s\n' --resource-group "$RG" --name "$STACK_NAME" --template-file "$TEMPLATE"
  [ -z "$PARAMS" ] || printf '%s\n' --parameters "$PARAMS"
}

ensure_group() {
  if az group show --name "$RG" >/dev/null 2>&1; then
    ok "Resource group ${RG} already there"
  else
    az group create --name "$RG" --location "$LOCATION" --output none
    ok "Resource group ${RG} created in ${LOCATION}"
  fi
}

warn_missing_params() {
  [ -n "$PARAMS" ] && return 0
  warn "No dev.bicepparam next to the template, parameters will be prompted"
}

case "$ACTION" in
  build)
    step "Compiling ${STACK_NAME}"
    az bicep build --file "$TEMPLATE" --stdout >/dev/null
    ok "Template compiles"
    ;;

  validate)
    step "Validating ${STACK_NAME} against ${RG}"
    warn_missing_params
    ensure_group
    mapfile -t args < <(deployment_args)
    az deployment group validate "${args[@]}" --output none
    ok "Template valid"
    ;;

  what-if)
    step "Planned changes for ${STACK_NAME} in ${RG}"
    warn_missing_params
    ensure_group
    mapfile -t args < <(deployment_args)
    az deployment group what-if "${args[@]}"
    ;;

  deploy)
    step "Deploying ${STACK_NAME} to ${RG}"
    warn_missing_params
    ensure_group
    mapfile -t args < <(deployment_args)
    az deployment group create "${args[@]}" --output none
    ok "Deployed, run 'make outputs STACK=${STACK_NAME}' to see the outputs"
    ;;

  destroy)
    step "Deleting ${RG}"
    az group show --name "$RG" >/dev/null 2>&1 ||
      die "Nothing to delete, ${RG} does not exist."

    if [ -z "${FORCE:-}" ]; then
      [ -t 0 ] || die "Not a terminal. Re-run with FORCE=1 to skip the prompt."
      read -r -p "  Delete ${RG} and everything in it? Type the stack name: " answer
      [ "$answer" = "$STACK_NAME" ] || die "Answer did not match, nothing deleted."
    fi

    az group delete --name "$RG" --yes --no-wait
    ok "Deletion started, Azure finishes it in the background"
    ;;

  outputs)
    step "Outputs of ${STACK_NAME}"
    az deployment group show --resource-group "$RG" --name "$STACK_NAME" \
      --query properties.outputs --output json
    ;;

  *)
    die "Unknown action '${ACTION}'."
    ;;
esac
