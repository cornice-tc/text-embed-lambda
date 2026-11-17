# text-embed-lambda

AWS Lambda function that serves text embeddings from [snowflake-arctic-embed-xs](https://huggingface.co/Snowflake/snowflake-arctic-embed-xs) (uint8-quantized ONNX) using ONNX Runtime.

A stripped-down, text-only port of [fastembed](https://github.com/qdrant/fastembed). It eliminates dependencies that are not necessary for text embeddings.

- Output: 384 dimensions, L2-normalized
- Max sequence: 512 tokens

Request: `{"texts": ["..."]}`, one or more texts per call. Response: `{"embeddings": [[...], ...]}`, one 384-dim vector per text, in the same order.

## Build

```bash
bash scripts/build_zip.sh   # produces dist/text-embed-lambda.zip (Lambda python3.14, x86_64)
```

## Verify equivalence with fastembed

```bash
cp -R build/model/ model/
uv run --with fastembed==0.9.0 --with huggingface-hub==1.9.2 --group test pytest
```

## Contributions

Published for review. Contributions, issues, and pull requests are not accepted.
