#!/bin/bash

# Script to stop all Kalygo microservices
# Usage: ./dev-stop.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stopping all Kalygo microservices...${NC}"

# Stop processes by name pattern
pkill -f "uvicorn.*kalygo3-ai-api" 2>/dev/null && echo -e "${GREEN}✓ Stopped kalygo3-ai-api${NC}" || echo -e "${RED}✗ kalygo3-ai-api not running${NC}"
pkill -f "uvicorn.*kalygo3-embeddings-api" 2>/dev/null && echo -e "${GREEN}✓ Stopped kalygo3-embeddings-api${NC}" || echo -e "${RED}✗ kalygo3-embeddings-api not running${NC}"
pkill -f "uvicorn.*kalygo3-reranker-api" 2>/dev/null && echo -e "${GREEN}✓ Stopped kalygo3-reranker-api${NC}" || echo -e "${RED}✗ kalygo3-reranker-api not running${NC}"
pkill -f "next dev" 2>/dev/null && echo -e "${GREEN}✓ Stopped kalygo3-ui${NC}" || echo -e "${RED}✗ kalygo3-ui not running${NC}"
pkill -f "functions-framework.*processQnaIngestTopicMessage" 2>/dev/null && echo -e "${GREEN}✓ Stopped kalygo3-qna-ingest-cloud-function${NC}" || echo -e "${RED}✗ kalygo3-qna-ingest-cloud-function not running${NC}"
pkill -f "functions-framework.*processTxtIngestTopicMessage" 2>/dev/null && echo -e "${GREEN}✓ Stopped kalygo3-txt-ingest-cloud-function${NC}" || echo -e "${RED}✗ kalygo3-txt-ingest-cloud-function not running${NC}"

# Also try to kill by port (more aggressive)
lsof -ti:4000 | xargs kill -9 2>/dev/null || true
lsof -ti:9100 | xargs kill -9 2>/dev/null || true
lsof -ti:7100 | xargs kill -9 2>/dev/null || true
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
lsof -ti:8080 | xargs kill -9 2>/dev/null || true
lsof -ti:8081 | xargs kill -9 2>/dev/null || true

echo -e "\n${GREEN}Done!${NC}"

