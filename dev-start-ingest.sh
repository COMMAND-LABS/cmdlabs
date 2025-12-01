#!/bin/bash

# Script to start Kalygo ingest microservices using Docker Compose
# Usage: ./dev-start-ingest.sh

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Kalygo ingest microservices with Docker Compose...${NC}\n"

# Check if docker network exists
if ! docker network inspect agent-network > /dev/null 2>&1; then
    echo -e "${YELLOW}Creating Docker network 'agent-network'...${NC}"
    docker network create agent-network
fi

# Start the services
docker-compose -f docker-compose.ingest.yml up -d

echo -e "\n${GREEN}Ingest services started!${NC}"
echo -e "${BLUE}Services:${NC}"
echo -e "  - QnA Ingest Function: http://localhost:8080"
echo -e "  - Txt Ingest Function: http://localhost:8081"
echo -e "\n${YELLOW}To view logs:${NC} docker-compose -f docker-compose.ingest.yml logs -f"
echo -e "${YELLOW}To stop:${NC} docker-compose -f docker-compose.ingest.yml down"

