#!/usr/bin/env bash
# Ask for everything the lab needs and write it to config.env, which Git ignores.

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

[ -t 0 ] || die "make setup needs a terminal."

# Suggests the part before the dot of the signed-in account: mpetit.ext@... -> mpetit
suggest_alias() {
  local upn
  upn="$(az account show --query user.name -o tsv 2>/dev/null)" || return 0
  echo "${upn%%@*}" | cut -d. -f1 | tr '[:upper:]' '[:lower:]'
}

ask() {
  local prompt="$1" default="$2" answer
  read -r -p "  ${prompt} [${default}]: " answer
  echo "${answer:-$default}"
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

step "Settings"
alias_value="$(ask 'Your alias, used in resource group names' "${ALIAS:-$(suggest_alias)}")"
[ -n "$alias_value" ] || die "The alias cannot be empty."
location_value="$(ask 'Azure region' "${LOCATION:-francecentral}")"

step "SSH key"
"$(dirname "${BASH_SOURCE[0]}")/ssh-key.sh"

step "Writing config.env"
cat > "$CONFIG_FILE" <<EOF
# Written by 'make setup'. Local to this machine, ignored by Git.
ALIAS=${alias_value}
LOCATION=${location_value}
EOF
ok "config.env written"

step "Ready"
field "Alias" "$alias_value"
field "Region" "$location_value"
field "SSH key" "$SSH_KEY"
field "Next" "make stacks"
echo
