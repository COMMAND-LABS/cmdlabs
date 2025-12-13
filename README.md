# TLDR

How to use this project

## High-level technique

1. Run the APIs (ie the ai-api, embeddings-api, reranker-api)

- Make sure Docker is running
- `docker compose -f docker-compose.dev.yml up`

2. Run the UI

- https://github.com/Kalygo-io/kalygo3-ui

3. Attach a Dev Container to any of the running "API" containers ie:

- ./dev-attach-ai-api.sh

## Prerequisites

- Docker Desktop (https://www.docker.com/products/docker-desktop/)
