#!/usr/bin/env bash
# Fetch upstream LICENSE / NOTICE files for components bundled in the Lambda zip.
set -euo pipefail

. "$(dirname "$0")/license_sources.sh"

for entry in "${LICENSE_SOURCES[@]}"; do
  path="${entry%%|*}"
  url="${entry#*|}"
  [[ "${path}" == third_party_licenses/* ]] || continue
  mkdir -p "$(dirname "${LICENSE_REPO_ROOT}/${path}")"
  license_fetch "${url}" "${LICENSE_REPO_ROOT}/${path}"
done

# snowflake-arctic-embed-xs: no upstream LICENSE/NOTICE file in the HF repo.
# The model card declares Apache-2.0 via HF YAML front matter; attribution
# lives in the top-level NOTICE with a link to the model card.
