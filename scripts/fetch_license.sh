#!/usr/bin/env bash
# Fetch the canonical Apache License 2.0 text for the top-level LICENSE.
set -euo pipefail

. "$(dirname "$0")/license_sources.sh"

for entry in "${LICENSE_SOURCES[@]}"; do
  path="${entry%%|*}"
  url="${entry#*|}"
  if [[ "${path}" == "LICENSE" ]]; then
    license_fetch "${url}" "${LICENSE_REPO_ROOT}/${path}"
  fi
done
