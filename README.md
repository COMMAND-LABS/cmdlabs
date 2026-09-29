# cmdlabs

Workspace folder for the Command Labs services. Each directory below is its own
git repo (clone, branch and commit inside it); this root repo only holds this
README, `.gitignore` and `docker-compose.dev.yml`.

## What's here

| Path | What it is |
| --- | --- |
| `cmdlabs-api/` | Main FastAPI backend (agents, auth, billing, KBs, …). `runner/` inside it is a separate, self-contained sandbox service that executes model-written Python and trains forecast models. |
| `cmdlabs-ui/` | Next.js frontend (`npm run dev` serves it on port 3001). |
| `cmdlabs-embeddings-api/` | FastAPI service that generates embeddings with sentence-transformers (all-MiniLM-L6-v2). |
| `cmdlabs-qna-ingest-cloud-function-python/` | Cloud Function that ingests Q&A `.csv` knowledge into Pinecone. |
| `cmdlabs-txt-ingest-cloud-function-python/` | Cloud Function that ingests `.txt` / `.md` files from GCS into Pinecone. |
| `tariff-n-duty-scraper/` | Scheduled duty & tariff research job (`tnd_agent`) that writes proposed tariff changes to the cmdlabs DB. See its README. |
| `docker-compose.dev.yml` | Local dev stack (below). |
| `scratch/` | Scratch files; not part of any service. |

## Dev stack

Prerequisites: Docker Desktop running, and the shared network:

```sh
docker network create agent-network   # once
```

Start / follow logs / stop:

```sh
docker compose -f docker-compose.dev.yml up -d
docker compose -f docker-compose.dev.yml logs -f
docker compose -f docker-compose.dev.yml down
```

| Service | Container | Port(s) | Notes |
| --- | --- | --- | --- |
| `api` | `cmdlabs-api` | 4000, 5678 (debug) | Mounts `./cmdlabs-api`, reads `cmdlabs-api/.env`, uvicorn `--reload`. |
| `embeddings-api` | `cmdlabs-embeddings-api` | 9100, 5679→5678 (debug) | Mounts `./cmdlabs-embeddings-api`, uvicorn `--reload`. |
| `postgres` | `cmdlabs-test-pg` | 5432 | Postgres 16 (`test`/`test`, db `kalygo_test`), volume `pgdata`. |
| `stripe-cli` | `cmdlabs-stripe-cli` | — | Only with `--profile stripe`; forwards Stripe webhooks to the api. See the comments in `docker-compose.dev.yml`. |

Logs for one container: `docker logs -f cmdlabs-api`. The UI is not in compose;
run it from `cmdlabs-ui/` with `npm run dev`.
