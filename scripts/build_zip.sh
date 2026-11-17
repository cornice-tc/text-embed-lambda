#!/bin/bash
# Build dist/text-embed-lambda.zip. Cross-compiles for Lambda's runtime regardless
# of host arch. Dep versions come from pyproject.toml + uv.lock — never edit pins here.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${REPO_DIR}/build"
DIST_DIR="${REPO_DIR}/dist"
ZIP_PATH="${DIST_DIR}/text-embed-lambda.zip"

HF_REPO="Snowflake/snowflake-arctic-embed-xs"
HF_ONNX_FILENAME="model_uint8.onnx"
HF_BASE="https://huggingface.co/${HF_REPO}/resolve/d8c86521100d3556476a063fc2342036d45c106f"

PYTHON_VERSION="3.14"
# manylinux_2_28 matches Lambda Python 3.14 (AL2023, glibc 2.34). ARM64 unusable:
# onnxruntime crashes on Lambda Graviton from a cpuinfo /sys parse failure.
PYTHON_PLATFORM="x86_64-manylinux_2_28"

rm -rf "${BUILD_DIR}" "${ZIP_PATH}"
mkdir -p "${BUILD_DIR}/model/onnx" "${DIST_DIR}"

# Production deps only (excludes dev + test groups) — what actually ships to Lambda.
REQUIREMENTS="${BUILD_DIR}/.lambda-requirements.txt"
echo "==> Exporting production deps from pyproject.toml + uv.lock..."
uv export \
    --no-dev \
    --no-default-groups \
    --no-group test \
    --no-hashes \
    --no-emit-project \
    --format requirements-txt \
    --output-file "${REQUIREMENTS}"

echo "==> Installing deps for ${PYTHON_PLATFORM} / py${PYTHON_VERSION}..."
uv pip install \
    --target "${BUILD_DIR}" \
    --python-version "${PYTHON_VERSION}" \
    --python-platform "${PYTHON_PLATFORM}" \
    -r "${REQUIREMENTS}"
rm -f "${REQUIREMENTS}"

echo "==> Downloading model + tokenizer from ${HF_REPO}..."
curl -sL --fail "${HF_BASE}/onnx/${HF_ONNX_FILENAME}" -o "${BUILD_DIR}/model/onnx/model.onnx"
for f in tokenizer.json tokenizer_config.json config.json special_tokens_map.json; do
    curl -sL --fail "${HF_BASE}/${f}" -o "${BUILD_DIR}/model/${f}"
done

echo "==> Copying handler + license files..."
cp "${REPO_DIR}/embedder.py" "${REPO_DIR}/lambda_handler.py" \
    "${REPO_DIR}/LICENSE" "${REPO_DIR}/NOTICE" "${BUILD_DIR}/"
cp -r "${REPO_DIR}/third_party_licenses" "${BUILD_DIR}/"

# Strip bytecode caches; Lambda rebuilds them on first invoke. Saves a few MB.
find "${BUILD_DIR}" -type d -name "__pycache__" -exec rm -rf {} +

find "${BUILD_DIR}" -exec touch -t 200001010000 {} +

echo "==> Zipping..."
(cd "${BUILD_DIR}" && find . -type f | LC_ALL=C sort | zip -X -q9 "${ZIP_PATH}" -@)
ls -lh "${ZIP_PATH}"
unzip -l "${ZIP_PATH}" | tail -1
echo "==> Build complete: ${ZIP_PATH}"
