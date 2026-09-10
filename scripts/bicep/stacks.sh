#!/usr/bin/env bash
# List the available stacks and the resource group each one deploys into.

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

while read -r stack; do
  field "$stack" "$(stack_rg "$stack")"
done < <(list_stacks)
