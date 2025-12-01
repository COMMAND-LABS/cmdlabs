# Development Scripts Guide

This directory contains scripts to help you start and stop all Kalygo microservices for local development.

## Available Scripts

### 1. `dev-start.sh` - Start all services in separate terminal tabs (macOS)

Opens each microservice in a new terminal tab/window. Best for development where you want to see logs for each service.

**Usage:**

```bash
./dev-start.sh
```

**Requirements:**

- macOS (uses AppleScript to open terminal tabs)
- Terminal.app or iTerm2
- All dependencies installed in each microservice directory

**Services started:**

- kalygo3-ai-api (port 4000)
- kalygo3-embeddings-api (port 9000)
- kalygo3-reranker-api (port 7100)
- kalygo3-ui (port 3000)
- kalygo3-qna-ingest-cloud-function (port 8080)
- kalygo3-txt-ingest-cloud-function (port 8081)

### 2. `dev-start-simple.sh` - Start all services in background

Runs all services in the background with logs written to `/tmp/kalygo-*.log` files.

**Usage:**

```bash
./dev-start-simple.sh
```

**View logs:**

```bash
tail -f /tmp/kalygo-*.log
# Or for a specific service:
tail -f /tmp/kalygo-ai-api.log
```

**Stop services:**

```bash
./dev-stop.sh
# Or manually:
pkill -f 'uvicorn|next dev|functions-framework'
```

### 3. `dev-stop.sh` - Stop all running services

Stops all Kalygo microservices that are currently running by process name patterns.

**Usage:**

```bash
./dev-stop.sh
```

### 4. `dev-kill-ports.sh` - Kill processes on microservice ports

Kills any processes running on the ports used by Kalygo microservices (4000, 9000, 7100, 3000, 8080, 8081). Useful when ports are stuck or occupied by unknown processes.

**Usage:**

```bash
./dev-kill-ports.sh
```

**What it does:**

- Checks each microservice port for running processes
- Attempts graceful termination (SIGTERM) first
- Force kills (SIGKILL) if necessary
- Provides detailed output about what was killed
- Verifies all ports are free after cleanup

### 5. Docker Compose - Start all services in containers

**Prerequisites:**

- Docker and Docker Compose installed
- Create the Docker network: `docker network create agent-network`

**Start all services:**

```bash
docker-compose -f docker-compose.dev.yml up
```

**Start in background:**

```bash
docker-compose -f docker-compose.dev.yml up -d
```

**View logs:**

```bash
docker-compose -f docker-compose.dev.yml logs -f
# Or for a specific service:
docker-compose -f docker-compose.dev.yml logs -f ai-api
```

**Stop all services:**

```bash
docker-compose -f docker-compose.dev.yml down
```

**Rebuild containers:**

```bash
docker-compose -f docker-compose.dev.yml up --build
```

### 6. Docker Compose - Start only ingest services

For running just the ingest cloud functions (QnA and Txt ingest):

**Quick start (using helper script):**

```bash
./dev-start-ingest.sh
```

**Manual start:**

```bash
docker-compose -f docker-compose.ingest.yml up
```

**Start in background:**

```bash
docker-compose -f docker-compose.ingest.yml up -d
```

**View logs:**

```bash
docker-compose -f docker-compose.ingest.yml logs -f
# Or for a specific service:
docker-compose -f docker-compose.ingest.yml logs -f qna-ingest-function
```

**Stop ingest services:**

```bash
docker-compose -f docker-compose.ingest.yml down
```

**Services included:**

- QnA Ingest Function (port 8080)
- Txt Ingest Function (port 8081)

## Service URLs

Once started, services will be available at:

- **AI API**: http://localhost:4000
- **Embeddings API**: http://localhost:9000
- **Reranker API**: http://localhost:7100
- **UI**: http://localhost:3000
- **QnA Ingest Function**: http://localhost:8080
- **Txt Ingest Function**: http://localhost:8081

## Troubleshooting

### Port already in use

If a port is already in use, you can:

1. Stop the service using that port: `lsof -ti:PORT | xargs kill -9`
2. Or modify the port in the script/docker-compose file

### Docker network doesn't exist

Create it with: `docker network create agent-network`

### Services not starting

- Check that all dependencies are installed in each microservice directory
- For Python services: ensure `uv` or `pip` dependencies are installed
- For Node services: ensure `npm install` has been run
- Check logs for specific error messages

### macOS terminal tabs not opening

The `dev-start.sh` script uses AppleScript. If it doesn't work:

- Try using `dev-start-simple.sh` instead
- Or manually start each service in separate terminals

## Notes

- The cloud functions (qna-ingest and txt-ingest) use the Google Cloud Functions Framework for local development
- All Python services use uvicorn with hot-reload enabled
- The UI uses Next.js development server with hot-reload
- Docker Compose services use volume mounts for live code reloading
