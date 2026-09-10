#!/usr/bin/env python3
"""List the resources preflight.sh has to check, one per line.

Reads the compiled ARM template in ARM_JSON and the compiled parameters in
PARAMS_JSON, resolves "[parameters('x')]" references, and prints tab separated
lines: "vm<TAB>size<TAB>imageSku" or "publicIp<TAB>sku".
"""

import json
import os
import re
import sys

PARAM_REF = re.compile(r"^\[parameters\('([^']+)'\)\]$")
VAR_LOOKUP = re.compile(r"^\[variables\('([^']+)'\)\[parameters\('([^']+)'\)\]\]$")


def load(name):
    raw = os.environ.get(name, "") or "{}"
    data = json.loads(raw)
    # az bicep build-params wraps the result in a JSON string.
    if isinstance(data, dict) and "parametersJson" in data:
        data = json.loads(data["parametersJson"])
    return data


def resolve(value, template, params):
    """Turn a "[parameters('x')]" expression into its value, when we can."""
    if not isinstance(value, str):
        return value
    match = PARAM_REF.match(value)
    if not match:
        return value
    name = match.group(1)
    given = params.get("parameters", {}).get(name)
    if isinstance(given, dict) and "value" in given:
        return given["value"]
    declared = template.get("parameters", {}).get(name, {})
    return declared.get("defaultValue", value)


def image_sku(profile, template, params):
    reference = profile.get("imageReference", {})

    # Common shape: imageReference is a lookup in a variable map, keyed by a
    # parameter, as in "[variables('imageReference')[parameters('osVersion')]]".
    if isinstance(reference, str):
        match = VAR_LOOKUP.match(reference)
        if not match:
            return ""
        table = template.get("variables", {}).get(match.group(1), {})
        key = resolve("[parameters('%s')]" % match.group(2), template, params)
        reference = table.get(key, {}) if isinstance(table, dict) else {}

    if not isinstance(reference, dict):
        return ""
    sku = resolve(reference.get("sku", ""), template, params)
    return sku if isinstance(sku, str) else ""


def main():
    template = load("ARM_JSON")
    params = load("PARAMS_JSON")
    lines = []

    for resource in template.get("resources", []):
        kind = resource.get("type", "")
        props = resource.get("properties", {})

        if kind == "Microsoft.Compute/virtualMachines":
            size = resolve(props.get("hardwareProfile", {}).get("vmSize", ""), template, params)
            lines.append(("vm", size, image_sku(props.get("storageProfile", {}), template, params)))

        elif kind == "Microsoft.Compute/virtualMachineScaleSets":
            size = resolve(resource.get("sku", {}).get("name", ""), template, params)
            profile = props.get("virtualMachineProfile", {}).get("storageProfile", {})
            lines.append(("vm", size, image_sku(profile, template, params)))

        elif kind == "Microsoft.Network/publicIPAddresses":
            lines.append(("publicIp", resolve(resource.get("sku", {}).get("name", "Basic"), template, params), ""))

    for line in lines:
        print("\t".join(str(part) for part in line))


if __name__ == "__main__":
    main()
    sys.exit(0)
