# TLDR

How to use this project

## Prerequisites

- Docker Desktop (https://www.docker.com/products/docker-desktop/)
- Make sure Docker Engine is running
- a docker network called: `agent-network`
  - `docker network create agent-network`

## How to boot up the development environment

- Run the APIs: `docker compose -f docker-compose.dev.yml up`
- Attach dev containers as needed ie: `./dev-attach-ai-api.sh`
- Run the UI: `https://github.com/Kalygo-io/kalygo3-ui`
