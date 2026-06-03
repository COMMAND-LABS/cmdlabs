#!/bin/bash

# Simplified script to start all services in background
# Usage: ./dev-start-simple.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting all Kalygo microservices..."

# Start services in background
(cd "${PROJECT_ROOT}/kalygo3-ai-api" && uv sync && uvicorn src.main:app --host 0.0.0.0 --port 4000 --proxy-headers --reload > /tmp/kalygo-ai-api.log 2>&1) &
(cd "${PROJECT_ROOT}/kalygo3-embeddings-api" && pip install -r requirements.txt && uvicorn src.main:app --host 0.0.0.0 --port 9100 --proxy-headers --reload > /tmp/kalygo-embeddings-api.log 2>&1) &
(cd "${PROJECT_ROOT}/kalygo3-reranker-api" && uv pip install -e . && uvicorn src.main:app --host 0.0.0.0 --port 7100 --proxy-headers --reload > /tmp/kalygo-reranker-api.log 2>&1) &
(cd "${PROJECT_ROOT}/kalygo3-ui" && npm run dev > /tmp/kalygo-ui.log 2>&1) &
(cd "${PROJECT_ROOT}/kalygo3-qna-ingest-cloud-function" && npm run watch > /tmp/kalygo-qna-function.log 2>&1) &
(cd "${PROJECT_ROOT}/kalygo3-txt-ingest-cloud-function" && PORT=8081 npm run watch > /tmp/kalygo-txt-function.log 2>&1) &

echo "All services started! Check logs in /tmp/kalygo-*.log"
echo ""
echo "Services:"
echo "  - AI API: http://localhost:4000 (log: /tmp/kalygo-ai-api.log)"
echo "  - Embeddings API: http://localhost:9100 (log: /tmp/kalygo-embeddings-api.log)"
echo "  - Reranker API: http://localhost:7100 (log: /tmp/kalygo-reranker-api.log)"
echo "  - UI: http://localhost:3000 (log: /tmp/kalygo-ui.log)"
echo "  - QnA Ingest Function: http://localhost:8080 (log: /tmp/kalygo-qna-function.log)"
echo "  - Txt Ingest Function: http://localhost:8081 (log: /tmp/kalygo-txt-function.log)"
echo ""
echo "To stop all services: pkill -f 'uvicorn|next dev|functions-framework'"
echo "To view logs: tail -f /tmp/kalygo-*.log"

