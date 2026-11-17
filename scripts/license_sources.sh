#!/usr/bin/env bash
# Single home for the license pin tags + shipped-path -> upstream-URL table;
# sourced, not executed. LICENSES.sha256 must follow any refetch.

LICENSE_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Tags derive from uv.lock (the single version home); the --online diff gate
# fails loudly if an upstream tags differently than 'v' + locked version.
locked_tag() {
  local version
  version="$(awk -v name="$1" '
    /^\[\[package\]\]/{hit=0}
    $0 == "name = \"" name "\"" {hit=1}
    hit && /^version = /{gsub(/[",]/, "", $3); print $3; exit}
  ' "${LICENSE_REPO_ROOT}/uv.lock")"
  echo "v${version}"
}

FASTEMBED_TAG="$(locked_tag fastembed)"
TOKENIZERS_TAG="$(locked_tag tokenizers)"
NUMPY_TAG="$(locked_tag numpy)"
ONNXRUNTIME_TAG="$(locked_tag onnxruntime)"

LICENSE_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The top-level LICENSE row is the license's single canonical location at
# apache.org — no version pin applies, its text is immutable.
LICENSE_SOURCES=(
  "LICENSE|https://www.apache.org/licenses/LICENSE-2.0.txt"
  "third_party_licenses/fastembed/LICENSE|https://raw.githubusercontent.com/qdrant/fastembed/${FASTEMBED_TAG}/LICENSE"
  "third_party_licenses/fastembed/NOTICE|https://raw.githubusercontent.com/qdrant/fastembed/${FASTEMBED_TAG}/NOTICE"
  "third_party_licenses/tokenizers/LICENSE|https://raw.githubusercontent.com/huggingface/tokenizers/${TOKENIZERS_TAG}/LICENSE"
  "third_party_licenses/numpy/LICENSE|https://raw.githubusercontent.com/numpy/numpy/${NUMPY_TAG}/LICENSE.txt"
  "third_party_licenses/onnxruntime/LICENSE|https://raw.githubusercontent.com/microsoft/onnxruntime/${ONNXRUNTIME_TAG}/LICENSE"
)

license_curl() {
  local url="$1"
  local dest="$2"
  curl --fail --silent --show-error --location "${url}" --output "${dest}"
}

license_fetch() {
  local url="$1"
  local dest="$2"
  license_curl "${url}" "${dest}"
  echo "Wrote ${dest#"${LICENSE_REPO_ROOT}"/} ($(wc -c < "${dest}") bytes) from ${url}"
}
