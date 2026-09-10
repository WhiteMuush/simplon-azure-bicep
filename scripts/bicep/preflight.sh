#!/usr/bin/env bash
# Compare what the template asks for with what this subscription actually
# allows: VM size offered in the region, quota left, hypervisor generation,
# and public IP SKU. Catches what 'what-if' only reports at creation time.

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

require_resource_group
require_az

resolve_stack "${1:-}"

TEMPLATE="$(stack_template "$STACK_NAME")"
PARAMS="$(stack_params "$STACK_NAME")"
[ -f "$TEMPLATE" ] || die "No template at ${TEMPLATE}."

LOCATION="$(az group show --name "$RESOURCE_GROUP" --query location -o tsv)"
FAILURES=0

fail() {
  printf '  \033[31mx\033[0m %s\n' "$*"
  FAILURES=$((FAILURES + 1))
}

# Emits one "kind<TAB>value<TAB>value" line per resource worth checking.
inventory() {
  local arm params
  arm="$(az bicep build --file "$TEMPLATE" --stdout)"
  params='{}'
  if [ -n "$PARAMS" ]; then
    params="$(az bicep build-params --file "$PARAMS" --stdout)"
  fi
  ARM_JSON="$arm" PARAMS_JSON="$params" python3 "$(dirname "${BASH_SOURCE[0]}")/inventory.py"
}

check_vm_size() {
  local size="$1" image_sku="$2" sku_json family vcpus generations limit used
  sku_json="$(az vm list-skus --location "$LOCATION" --size "$size" --resource-type virtualMachines -o json)"

  if [ "$(echo "$sku_json" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')" = "0" ]; then
    fail "${size} is not offered in ${LOCATION}"
    return
  fi

  read -r family vcpus generations < <(
    echo "$sku_json" | python3 -c '
import json, sys
s = json.load(sys.stdin)[0]
caps = {c["name"]: c["value"] for c in s.get("capabilities", [])}
blocked = any(r["type"] == "Location" for r in s.get("restrictions", []))
print(s.get("family", "?"), caps.get("vCPUs", "0"), caps.get("HyperVGenerations", "?"), "blocked" if blocked else "")
')

  case "$generations" in
    *V2*) [ "${image_sku}" = "${image_sku%-gen2}" ] &&
            warn "${size} supports generation 2, the image is generation 1" ;;
  esac
  case "$generations" in
    *V1*) ;;
    *) [ "${image_sku}" = "${image_sku%-gen2}" ] &&
         fail "${size} only boots generation 2, the image '${image_sku}' is generation 1" ;;
  esac
  case "$generations" in
    *V2*) ;;
    *) [ "${image_sku}" != "${image_sku%-gen2}" ] &&
         fail "${size} only boots generation 1, the image '${image_sku}' is generation 2" ;;
  esac

  read -r limit used < <(
    az vm list-usage --location "$LOCATION" -o json |
      FAMILY="$family" python3 -c '
import json, os, sys
family = os.environ["FAMILY"].lower()
for u in json.load(sys.stdin):
    if u["name"]["value"].lower() == family:
        print(u["limit"], u["currentValue"]); break
else:
    print(-1, 0)
')

  if [ "$limit" = "-1" ]; then
    warn "No quota entry found for ${family}"
  elif [ "$((limit - used))" -lt "$vcpus" ]; then
    fail "${family} quota exhausted: ${used}/${limit} cores used, ${size} needs ${vcpus}"
  else
    ok "${size}: offered in ${LOCATION}, $((limit - used)) cores left in ${family}"
  fi
}

check_public_ip() {
  case "$1" in
    Basic) fail "Basic public IP: retired by Microsoft and refused by this subscription" ;;
    *) ok "Public IP SKU ${1}" ;;
  esac
}

step "Preflight of ${STACK_NAME} against ${RESOURCE_GROUP} in ${LOCATION}"

mapfile -t resources < <(inventory)
[ "${#resources[@]}" -gt 0 ] || die "Nothing to check, the inventory came back empty."

for line in "${resources[@]}"; do
  IFS=$'\t' read -r kind first second <<< "$line"
  case "$kind" in
    vm) check_vm_size "$first" "$second" ;;
    publicIp) check_public_ip "$first" ;;
  esac
done

echo
[ "$FAILURES" -eq 0 ] || die "${FAILURES} blocking issue(s), the deployment would fail."
ok "Nothing blocking found"
