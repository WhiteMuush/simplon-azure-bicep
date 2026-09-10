#!/usr/bin/env bash
# Shared helpers for the scripts in this directory. Meant to be sourced.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Key pair used by every exercise that provisions a VM. Override with SSH_KEY.
SSH_KEY="${SSH_KEY:-${HOME}/.ssh/tp-bicep-az104}"
SSH_COMMENT="${SSH_COMMENT:-tp-bicep-az104}"

die() {
  echo "$*" >&2
  exit 1
}

ok()   { printf '  \033[32m*\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
