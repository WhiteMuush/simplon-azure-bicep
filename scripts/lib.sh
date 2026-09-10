#!/usr/bin/env bash
# Shared helpers for the scripts in this directory. Meant to be sourced.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACKS_DIR="${PROJECT_ROOT}/infra/stacks"

# Key pair used by every exercise that provisions a VM. Override with SSH_KEY.
SSH_KEY="${SSH_KEY:-${HOME}/.ssh/tp-bicep-az104}"
SSH_COMMENT="${SSH_COMMENT:-tp-bicep-az104}"

# Naming and placement of the resource groups. Override with ALIAS or LOCATION.
ALIAS="${ALIAS:-mpetit}"
LOCATION="${LOCATION:-francecentral}"

export STACK_NAME=""

die() {
  echo "$*" >&2
  exit 1
}

step()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
ok()    { printf '  \033[32m*\033[0m %s\n' "$*"; }
warn()  { printf '  \033[33m!\033[0m %s\n' "$*"; }
field() { printf '  %-16s %s\n' "$1" "$2"; }

list_stacks() {
  [ -d "$STACKS_DIR" ] || die "No infra/stacks/ directory at the project root."
  find "$STACKS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

# Sets STACK_NAME. Refuses to guess outside a terminal.
resolve_stack() {
  local requested="${1:-}"
  local -a stacks
  mapfile -t stacks < <(list_stacks)

  if [ -n "$requested" ]; then
    [ -d "${STACKS_DIR}/${requested}" ] ||
      die "Unknown stack '${requested}'. Run 'make stacks' to list them."
    STACK_NAME="$requested"
    return
  fi

  case "${#stacks[@]}" in
    0) die "No stack found under infra/stacks/." ;;
    1) STACK_NAME="${stacks[0]}"; return ;;
  esac

  [ -t 0 ] ||
    die "Several stacks available. Run with STACK=<name>, see 'make stacks'."

  local choice
  PS3="Which stack? "
  select choice in "${stacks[@]}"; do
    if [ -n "${choice:-}" ]; then
      STACK_NAME="$choice"
      return
    fi
  done
}

# One resource group per stack, as the lab requires.
stack_rg() {
  echo "rg-${ALIAS}-tp104-${1}"
}

stack_template() {
  echo "${STACKS_DIR}/${1}/main.bicep"
}

# The real parameter file is git-ignored, the sample one is committed.
stack_params() {
  local file="${STACKS_DIR}/${1}/dev.bicepparam"
  if [ -f "$file" ]; then
    echo "$file"
  fi
}

require_az() {
  command -v az >/dev/null || die "Azure CLI not found. See docs/CONSIGNES.md."
  az account show >/dev/null 2>&1 || die "Not signed in. Run 'az login'."
}
