#!/usr/bin/env bash
# Generate the lab SSH key pair and apply the permissions ssh expects.

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

if [ -f "$SSH_KEY" ]; then
  warn "Key already there, nothing to do: ${SSH_KEY}"
else
  ssh-keygen -t ed25519 -C "$SSH_COMMENT" -f "$SSH_KEY" -N ""
  ok "Key created: ${SSH_KEY}"
fi

chmod 700 "$(dirname "$SSH_KEY")"
chmod 600 "$SSH_KEY"
chmod 644 "${SSH_KEY}.pub"
