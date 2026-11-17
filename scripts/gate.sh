#!/usr/bin/env bash
# The checks pre-commit and CI both run. --online adds the license diff against upstream.
set -euo pipefail

cd "$(dirname "$0")/.."

uv run ruff format --check .
uv run ruff check .
uv run mypy . --config-file=pyproject.toml
uv run bandit -q -r embedder.py lambda_handler.py
uv run pytest tests/ -v
bash scripts/verify_licenses.sh "$@"
# Production deps only: dev and test deps don't land in the zip.
uv audit --preview-features audit --no-dev --no-group test --locked --python-version 3.14 --python-platform x86_64-manylinux_2_28
