#!/bin/bash

# Script to attach Cursor/VSCode to any microservice dev container
# Usage: ./dev-attach-all.sh [service-name] [cursor|code]
# Examples:
#   ./dev-attach-all.sh ai-api cursor
#   ./dev-attach-all.sh embeddings-api code
#   ./dev-attach-all.sh reranker-api

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service mappings
declare -A SERVICE_MAP=(
    ["ai-api"]="kalygo3-ai-api"
    ["embeddings-api"]="kalygo3-embeddings-api"
    ["reranker-api"]="kalygo3-reranker-api"
)

declare -A SERVICE_DIRS=(
    ["ai-api"]="kalygo3-ai-api"
    ["embeddings-api"]="kalygo3-embeddings-api"
    ["reranker-api"]="kalygo3-reranker-api"
)

declare -A SERVICE_PATHS=(
    ["ai-api"]="/code"
    ["embeddings-api"]="/code"
    ["reranker-api"]="/code"
)

# Parse arguments
SERVICE_NAME="${1:-ai-api}"
EDITOR="${2:-cursor}"

# Validate service name
if [[ ! -v SERVICE_MAP[$SERVICE_NAME] ]]; then
    echo -e "${RED}Error: Unknown service '${SERVICE_NAME}'${NC}"
    echo -e "${YELLOW}Available services:${NC}"
    for svc in "${!SERVICE_MAP[@]}"; do
        echo -e "  - ${svc}"
    done
    exit 1
fi

CONTAINER_NAME="${SERVICE_MAP[$SERVICE_NAME]}"
SERVICE_DIR="${PROJECT_ROOT}/${SERVICE_DIRS[$SERVICE_NAME]}"
WORKSPACE_PATH="${SERVICE_PATHS[$SERVICE_NAME]}"

# Validate editor
if [[ "$EDITOR" != "cursor" && "$EDITOR" != "code" ]]; then
    echo -e "${RED}Error: Invalid editor. Use 'cursor' or 'code'${NC}"
    exit 1
fi

# Check if editor is installed
if ! command -v "$EDITOR" &> /dev/null; then
    echo -e "${RED}Error: $EDITOR command not found.${NC}"
    exit 1
fi

echo -e "${BLUE}Attaching $EDITOR to ${SERVICE_NAME} (${CONTAINER_NAME})...${NC}\n"

# Check if container is running
if ! docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}Container ${CONTAINER_NAME} is not running.${NC}"
    echo -e "${YELLOW}Starting container with docker-compose...${NC}\n"
    
    cd "$PROJECT_ROOT"
    docker-compose -f docker-compose.dev.yml up -d "${SERVICE_NAME}"
    
    echo -e "${BLUE}Waiting for container to be ready...${NC}"
    sleep 3
fi

# Get container ID (short for display)
CONTAINER_ID_SHORT=$(docker ps --filter "name=${CONTAINER_NAME}" --format "{{.ID}}")

if [ -z "$CONTAINER_ID_SHORT" ]; then
    echo -e "${RED}Error: Could not find container ${CONTAINER_NAME}${NC}"
    echo -e "${YELLOW}Make sure the container is running:${NC}"
    echo -e "  docker-compose -f docker-compose.dev.yml up -d ${SERVICE_NAME}"
    exit 1
fi

# Get full container ID (required for URI)
CONTAINER_ID_FULL=$(docker inspect "${CONTAINER_NAME}" --format "{{.Id}}" 2>/dev/null | tr -d '\n')

if [ -z "$CONTAINER_ID_FULL" ]; then
    echo -e "${RED}Error: Could not get full container ID for ${CONTAINER_NAME}${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found container: ${CONTAINER_NAME} (${CONTAINER_ID_SHORT})${NC}"

# Try to attach using Remote Containers
echo -e "${BLUE}Opening workspace and attaching to container...${NC}"

# Method 1: Try using URI with full container ID (most direct)
# Format: vscode-remote://attached-container+<FULL_CONTAINER_ID>/<workspace-path>
ATTACH_URI="vscode-remote://attached-container+${CONTAINER_ID_FULL}${WORKSPACE_PATH}"

echo -e "${BLUE}Attempting direct attachment via URI...${NC}"
echo -e "${BLUE}URI: ${ATTACH_URI}${NC}"

# Try opening with the URI directly
"${EDITOR}" --folder-uri "${ATTACH_URI}" 2>/dev/null &
ATTACH_PID=$!

# Wait a moment to see if it succeeds
sleep 2

if kill -0 $ATTACH_PID 2>/dev/null || ps -p $ATTACH_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Editor opened with container attachment${NC}"
else
    # Method 2: Open workspace and use AppleScript to automate selection (macOS only)
    echo -e "${BLUE}Opening workspace folder...${NC}"
    "${EDITOR}" "${SERVICE_DIR}" 2>/dev/null &
    EDITOR_PID=$!
    
    # Wait for editor to open
    sleep 3
    
    # On macOS, use AppleScript to automate the container selection
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${BLUE}Automating container selection (macOS)...${NC}"
        
        # Execute the command and then use AppleScript to select the container
        osascript <<EOF 2>/dev/null || true
tell application "System Events"
    tell process "${EDITOR}"
        -- Execute the attach command
        keystroke "p" using {command down, shift down}
        delay 0.5
        keystroke "Remote-Containers: Attach to Running Container"
        delay 1
        key code 36 -- Enter
        delay 1.5
        
        -- Try to find and select the container name in the picker
        keystroke "${CONTAINER_NAME}"
        delay 0.5
        key code 36 -- Enter
    end tell
end tell
EOF
        echo -e "${GREEN}✓ Automated selection attempted${NC}"
    else
        # For non-macOS, execute command and provide instructions
        echo -e "${BLUE}Executing 'Attach to Running Container' command...${NC}"
        "${EDITOR}" --command "remote-containers.attachToRunningContainer" 2>/dev/null || true
        
        echo -e "${YELLOW}Note: Please select ${CONTAINER_NAME} from the container picker${NC}"
    fi
fi

echo -e "\n${GREEN}✓ Done!${NC}"
echo -e "${BLUE}Container info:${NC}"
echo -e "  Service: ${SERVICE_NAME}"
echo -e "  Container: ${CONTAINER_NAME}"
echo -e "  ID (short): ${CONTAINER_ID_SHORT}"
echo -e "  Workspace: ${WORKSPACE_PATH}"

