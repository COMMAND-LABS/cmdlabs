# TLDR

How to use this project

## Prerequisites

- Docker Desktop (https://www.docker.com/products/docker-desktop/)
- Make sure Docker Engine is running
- a docker network called: `agent-network`
  - `docker network create agent-network`

## How to boot up the development environment

- Run the APIs: `docker compose -f docker-compose.dev.yml up`
- Attach dev containers as needed ie:
  - `./dev-attach-ai-api.sh`
  - `./dev-attach-completion-api.sh`
- Run the UI: `https://github.com/Kalygo-io/kalygo3-ui`

## Services (Docker Compose)

| Service        | Port | Description                                     |
| -------------- | ---- | ----------------------------------------------- |
| ai-api         | 4000 | Core API (agents CRUD, auth, credentials, etc.) |
| completion-api | 4100 | Streaming completion (POST …/completion)        |
| embeddings-api | 9000 | Embeddings                                      |
| reranker-api   | 7100 | Reranker                                        |

The **completion** endpoint (`POST /api/agents/{id}/completion`) runs on the **Completion API** (port 4100). Point the UI or clients at `http://localhost:4100` for streaming chat; use `http://localhost:4000` for all other API routes. If your UI uses a single API base URL, configure it to call the Completion API (e.g. `COMPLETION_API_URL=http://localhost:4100`) for completion requests and the AI API for the rest.
