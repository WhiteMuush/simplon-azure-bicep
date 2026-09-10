#!/usr/bin/env bash
# Print the Makefile targets, grouped and coloured by the ##@ section markers.

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# One colour per section. Unlisted sections fall back to DEFAULT_COLOR.
SECTION_COLORS="Setup=38;5;170,Bicep=38;5;39,CI=38;5;220,General=38;5;80"
DEFAULT_COLOR="38;5;80"

# Sections follow the include order of the Makefile, not the alphabet.
makefiles() {
  printf '%s\n' "${PROJECT_ROOT}/Makefile"
  awk '/^include /{print $2}' "${PROJECT_ROOT}/Makefile" |
    while read -r rel; do printf '%s\n' "${PROJECT_ROOT}/${rel}"; done
}

print_targets() {
  awk -v colors="$SECTION_COLORS" -v fallback="$DEFAULT_COLOR" '
    BEGIN {
      split(colors, pairs, ",")
      for (i in pairs) {
        split(pairs[i], kv, "=")
        color[kv[1]] = kv[2]
      }
      current = fallback
    }
    /^##@ / {
      section = substr($0, 5)
      current = (section in color) ? color[section] : fallback
      printf "\n\033[1;%sm%s\033[0m\n", current, section
      next
    }
    /^[a-z][a-z0-9-]*:.*## / {
      split($0, parts, ":.*## ")
      printf "  \033[%sm%-16s\033[0m %s\n", current, parts[1], parts[2]
    }
  ' "$@"
}

main() {
  echo "Usage: make <target> [STACK=<name>]"
  echo "Without STACK, the Bicep targets ask which stack to use."
  mapfile -t files < <(makefiles)
  print_targets "${files[@]}"
  echo
}

main "$@"
