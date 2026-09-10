#!/usr/bin/env bash
# List the available stacks. All of them deploy into the same resource group.

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

require_resource_group

while read -r stack; do
  field "$stack" "$RESOURCE_GROUP"
done < <(list_stacks)
