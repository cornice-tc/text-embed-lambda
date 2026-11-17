"""Equivalence tests: TextEmbedder output matches the pinned fastembed's."""

import numpy as np
import pytest
from pathlib import Path

from embedder import TextEmbedder

try:
    from fastembed import TextEmbedding
    from fastembed.common.model_description import ModelSource, PoolingType

    _has_fastembed = True
except ImportError:
    _has_fastembed = False

# Same local quantized file as TextEmbedder, so only the code path differs.
CUSTOM_MODEL_NAME = "local/arctic-embed-xs-uint8"
MODEL_DIR = Path(__file__).resolve().parent.parent / "model"

pytestmark = pytest.mark.skipif(
    not (MODEL_DIR / "onnx" / "model.onnx").exists(),
    reason="Model files not downloaded",
)

TEST_TEXTS = [
    "leverage ratio covenant",
    "The borrower shall maintain a minimum interest coverage ratio of 2.0x.",
    "short",
    "",
    "A " * 300,  # truncation test
]


@pytest.fixture(scope="module")
def ours():
    return list(TextEmbedder(model_dir=MODEL_DIR).embed(TEST_TEXTS))


@pytest.fixture(scope="module")
def theirs():
    if not _has_fastembed:
        return None
    TextEmbedding.add_custom_model(
        model=CUSTOM_MODEL_NAME,
        pooling=PoolingType.CLS,
        normalization=True,
        sources=ModelSource(hf="Snowflake/snowflake-arctic-embed-xs"),
        dim=384,
        model_file="onnx/model.onnx",
    )
    return list(
        TextEmbedding(
            model_name=CUSTOM_MODEL_NAME, specific_model_path=str(MODEL_DIR)
        ).embed(TEST_TEXTS)
    )


@pytest.mark.skipif(not _has_fastembed, reason="fastembed not installed")
def test_equivalence(ours, theirs):
    for i, (o, t) in enumerate(zip(ours, theirs)):
        np.testing.assert_allclose(o, t, atol=1e-6, err_msg=f"Mismatch at index {i}")


def test_dimensions(ours):
    for r in ours:
        assert r.shape == (384,)


def test_l2_normalized(ours):
    for r in ours:
        np.testing.assert_allclose(np.linalg.norm(r), 1.0, atol=1e-6)


def test_different_texts_differ(ours):
    assert not np.allclose(ours[0], ours[1])
