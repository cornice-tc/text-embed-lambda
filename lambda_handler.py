"""AWS Lambda handler for text embedding."""

from embedder import TextEmbedder

# Module-level: loads once on cold start, persists across warm invocations
EMBEDDER = TextEmbedder(model_dir="/var/task/model")


def lambda_handler(event, context):  # type: ignore[no-untyped-def]
    """Accept {"texts": ["..."]} and return {"embeddings": [[...], ...]}."""
    texts = event["texts"]
    embeddings = [e.tolist() for e in EMBEDDER.embed(texts)]
    return {"embeddings": embeddings}
