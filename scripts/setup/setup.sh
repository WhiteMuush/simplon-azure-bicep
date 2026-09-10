#!/usr/bin/env bash
# Ask for everything the lab needs and write it to config.env, which Git ignores.

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

[ -t 0 ] || die "make setup needs a terminal."

# The lab account is Owner of one resource group only, and Reader elsewhere.
writable_groups() {
  az role assignment list --assignee "$(az account show --query user.name -o tsv)" \
    --all --query "[?roleDefinitionName=='Owner' || roleDefinitionName=='Contributor'].scope" -o tsv |
    grep -i '/resourceGroups/' | sed 's|.*/resourceGroups/||' | sort -u
}

step "Azure account"
if az account show >/dev/null 2>&1; then
  ok "Signed in as $(az account show --query user.name -o tsv)"
else
  warn "Not signed in"
  read -r -p "  Run 'az login' now? [Y/n]: " answer
  case "${answer:-y}" in
    [Yy]*) az login --output none ;;
    *) die "Sign in first, then run 'make setup' again." ;;
  esac
fi

step "Resource group"
mapfile -t groups < <(writable_groups)
case "${#groups[@]}" in
  0) read -r -p "  Resource group to deploy into: " group ;;
  1) group="${groups[0]}"; ok "Only one you can write to: ${group}" ;;
  *) PS3="  Which resource group? "
     select group in "${groups[@]}"; do [ -n "${group:-}" ] && break; done ;;
esac
[ -n "$group" ] || die "The resource group cannot be empty."
az group show --name "$group" >/dev/null 2>&1 || die "Resource group '${group}' not found."

step "SSH key"
"$(dirname "${BASH_SOURCE[0]}")/ssh-key.sh"

step "Writing config.env"
cat > "$CONFIG_FILE" <<EOF
# Written by 'make setup'. Local to this machine, ignored by Git.
RESOURCE_GROUP=${group}
EOF
ok "config.env written"

step "Ready"
field "Resource group" "$group"
field "SSH key" "$SSH_KEY"
field "Next" "make stacks"
echo
