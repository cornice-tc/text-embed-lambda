#!/usr/bin/env bash
# Check shipped license texts against LICENSES.sha256; --online also diffs
# against the pinned upstream URLs. The top-level NOTICE has no upstream to pin.
set -euo pipefail

. "$(dirname "$0")/license_sources.sh"
REPO_ROOT="${LICENSE_REPO_ROOT}"
MANIFEST="${REPO_ROOT}/LICENSES.sha256"

online=false
case "${1:-}" in
  "") ;;
  --online) online=true ;;
  *) echo "usage: $(basename "$0") [--online]" >&2; exit 2 ;;
esac

checksum_check() {
  local manifest="$1"
  echo "Checking $(grep -c . "${manifest}") license files against ${manifest##*/}"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -c "${manifest}"
  else
    sha256sum -c "${manifest}"
  fi
}

verify_against_upstream() {
  local failures=0
  local entry path url fetched
  for entry in "${LICENSE_SOURCES[@]}"; do
    path="${entry%%|*}"
    url="${entry#*|}"
    fetched="$(mktemp)"
    license_curl "${url}" "${fetched}"
    if diff --unified "${REPO_ROOT}/${path}" "${fetched}" >/dev/null; then
      echo "${path}: OK (matches ${url})"
    else
      echo "${path}: FAILED, differs from ${url}" >&2
      diff --unified --label "${path}" --label "${url}" \
        "${REPO_ROOT}/${path}" "${fetched}" >&2 || true
      failures=$((failures + 1))
    fi
    rm -f "${fetched}"
  done
  if [[ "${failures}" -gt 0 ]]; then
    echo "${failures} shipped license file(s) differ from pinned upstream" >&2
    return 1
  fi
}

cd "${REPO_ROOT}"

# Both checks run to completion before exiting so a checksum failure does not
# hide what the upstream diff would have said.
failed=false
checksum_check "${MANIFEST}" || failed=true

if [[ "${online}" == true ]]; then
  echo
  echo "Diffing against pinned upstream sources"
  verify_against_upstream || failed=true
fi

if [[ "${failed}" == true ]]; then
  echo
  echo "License verification FAILED." >&2
  exit 1
fi

echo
echo "All shipped license texts verified."
