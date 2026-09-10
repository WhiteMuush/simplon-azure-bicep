#!/usr/bin/env bash
# Print the public key to pass as a deployment parameter.

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

[ -f "${SSH_KEY}.pub" ] ||
  die "No public key at ${SSH_KEY}.pub. Run 'make ssh-key' first."

cat "${SSH_KEY}.pub"
