#!/usr/bin/env bash
# Print your public source IP in CIDR form, for the SSH rule of the NSG.

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

ip="$(curl -fsS ifconfig.me)" || die "Could not reach ifconfig.me."
[ -n "$ip" ] || die "Empty answer from ifconfig.me."

echo "${ip}/32"
