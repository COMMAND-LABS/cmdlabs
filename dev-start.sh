#!/bin/bash

# Script to start all Kalygo microservices for development
# Usage: ./dev-start.sh

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}Starting all Kalygo microservices...${NC}\n"

# Function to open a new terminal tab and run a command (macOS)
open_terminal_tab() {
    local service_name=$1
    local working_dir=$2
    local command=$3
    
    osascript -e "tell application \"Terminal\"" \
        -e "tell application \"System Events\" to keystroke \"t\" using {command down}" \
        -e "do script \"cd ${working_dir} && echo '${GREEN}Starting ${service_name}...${NC}' && ${command}\" in front window" \
        -e "end tell" > /dev/null 2>&1 || \
    osascript -e "tell application \"iTerm\"" \
        -e "tell current window" \
        -e "create tab with default profile" \
        -e "tell current session of current tab" \
        -e "write text \"cd ${working_dir} && echo '${GREEN}Starting ${service_name}...${NC}' && ${command}\"" \
        -e "end tell" \
        -e "end tell" \
        -e "end tell" > /dev/null 2>&1
}

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${YELLOW}Warning: This script is optimized for macOS.${NC}"
    echo -e "${YELLOW}For Linux, you may need to modify the terminal opening logic.${NC}\n"
fi

# Start kalygo3-ai-api
echo -e "${GREEN}Starting kalygo3-ai-api on port 4000...${NC}"
open_terminal_tab "kalygo3-ai-api" \
    "${PROJECT_ROOT}/kalygo3-ai-api" \
    "uv sync && uvicorn src.main:app --host 0.0.0.0 --port 4000 --proxy-headers --reload"
sleep 1

# Start kalygo3-embeddings-api
echo -e "${GREEN}Starting kalygo3-embeddings-api on port 9000...${NC}"
open_terminal_tab "kalygo3-embeddings-api" \
    "${PROJECT_ROOT}/kalygo3-embeddings-api" \
    "pip install -r requirements.txt && uvicorn src.main:app --host 0.0.0.0 --port 9000 --proxy-headers --reload"
sleep 1

# Start kalygo3-reranker-api
echo -e "${GREEN}Starting kalygo3-reranker-api on port 7100...${NC}"
open_terminal_tab "kalygo3-reranker-api" \
    "${PROJECT_ROOT}/kalygo3-reranker-api" \
    "uv pip install -e . && uvicorn src.main:app --host 0.0.0.0 --port 7100 --proxy-headers --reload"
sleep 1

# Start kalygo3-ui
echo -e "${GREEN}Starting kalygo3-ui on port 3000...${NC}"
open_terminal_tab "kalygo3-ui" \
    "${PROJECT_ROOT}/kalygo3-ui" \
    "npm run dev"
sleep 1

# Start kalygo3-qna-ingest-cloud-function
echo -e "${GREEN}Starting kalygo3-qna-ingest-cloud-function on port 8080...${NC}"
open_terminal_tab "kalygo3-qna-ingest-cloud-function" \
    "${PROJECT_ROOT}/kalygo3-qna-ingest-cloud-function" \
    "npm run watch"
sleep 1

# Start kalygo3-txt-ingest-cloud-function
echo -e "${GREEN}Starting kalygo3-txt-ingest-cloud-function on port 8081...${NC}"
open_terminal_tab "kalygo3-txt-ingest-cloud-function" \
    "${PROJECT_ROOT}/kalygo3-txt-ingest-cloud-function" \
    "PORT=8081 npm run watch"
sleep 1

echo -e "\n${BLUE}All services are starting in separate terminal tabs!${NC}"
echo -e "${YELLOW}Services:${NC}"
echo -e "  - AI API: http://localhost:4000"
echo -e "  - Embeddings API: http://localhost:9000"
echo -e "  - Reranker API: http://localhost:7100"
echo -e "  - UI: http://localhost:3000"
echo -e "  - QnA Ingest Function: http://localhost:8080"
echo -e "  - Txt Ingest Function: http://localhost:8081"
echo -e "\n${GREEN}Done!${NC}"

