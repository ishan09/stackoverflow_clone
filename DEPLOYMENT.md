# Local Deployment Guide

Two paths are supported: **Docker Compose** (no Elixir/Postgres install needed) and **Native Elixir** (faster iteration, full control).

---

## Option A — Docker Compose (Recommended)

### Prerequisites

| Tool | Install |
|------|---------|
| Docker + Docker Compose | https://docs.docker.com/get-docker/ |
| ngrok (for Slack) | https://ngrok.com/download |

### Step 1 — Clone and create `.env`

```bash
git clone <repo-url>
cd stackoverflow_clone
cp .env.example .env
```

### Step 2 — Fill in `.env`

```bash
# REQUIRED — from https://api.slack.com/apps → Your App → OAuth & Permissions
SLACK_BOT_TOKEN=xoxb-your-token-here

# REQUIRED — from https://api.slack.com/apps → Your App → Basic Information
SLACK_SIGNING_SECRET=your-signing-secret-here

# Transcription backend
# "local"  → whisper CLI inside container (no API cost, GPU optional)
# "openai" → OpenAI Whisper API (costs money, no extra install)
TRANSCRIPTION_PROVIDER=local

# LLM backend
# "ollama" → local Llama 3.2 on your machine (free, needs GPU for speed)
# "openai" → OpenAI GPT-4o-mini (costs money, fast)
LLM_PROVIDER=ollama

# Only required if either provider above is set to "openai"
OPENAI_API_KEY=sk-...
```

Leave Postgres values as-is — they match the `db` service in `docker-compose.yml`.

### Step 3 — (If using `LLM_PROVIDER=ollama`) Install Ollama on your host

```bash
# macOS / Linux
curl -fsSL https://ollama.com/install.sh | sh

# Pull the model the app uses by default
ollama pull llama3.2

# Verify it's running on port 11434
ollama list
```

The docker-compose already sets `OLLAMA_BASE_URL=http://host.docker.internal:11434`, which lets the container reach Ollama on your host. No changes needed.

### Step 4 — Build and start all services

```bash
docker compose up --build
```

First build takes 3–5 minutes (downloads Elixir deps, ffmpeg, yt-dlp, whisper). Subsequent starts are fast due to layer caching.

The entrypoint automatically:
- Waits for Postgres to be healthy
- Runs `mix ecto.create` + `mix ecto.migrate` (Postgres + Oban tables)
- Runs SQLite migrations at app startup (reels table)
- Starts the Phoenix server on port `4000`

### Step 5 — Expose the server for Slack

Slack needs to reach your machine via HTTPS. Open a new terminal:

```bash
ngrok http 4000
```

Copy the `https://xxxx.ngrok.io` URL from ngrok output.

### Step 6 — Configure your Slack App

1. Go to https://api.slack.com/apps → select your app (or click **Create New App**)
2. **Event Subscriptions** → Enable → set Request URL to:
   ```
   https://xxxx.ngrok.io/api/slack/events
   ```
   Slack sends a challenge request; the app responds automatically.
3. **Subscribe to bot events** → Add:
   - `message.channels`
   - `app_mention`
4. **OAuth & Permissions** → Bot Token Scopes → Add:
   - `chat:write`
   - `channels:history`
5. **Install App to Workspace** → copy the Bot User OAuth Token into `SLACK_BOT_TOKEN` in `.env`
6. Restart: `docker compose restart phoenix`

### Step 7 — Verify it works

```bash
# Tail logs
docker compose logs -f phoenix
```

In Slack, paste an Instagram or YouTube URL in a channel the bot is in:
```
https://www.instagram.com/reel/ABC123/
```

You should see:
```
[info] Enqueued reel job 1 for https://...
[info] Processing: https://...
[info] caption_present=true
[info] transcript_length=432
[info] Processed successfully: https://...
```

---

## Option B — Native Elixir

### Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Elixir | 1.18+ | `brew install elixir` or https://elixir-lang.org/install |
| Erlang/OTP | 27 | bundled with Elixir via asdf/brew |
| PostgreSQL | 14+ | `brew install postgresql@15` / `apt install postgresql` |
| ffmpeg | any | `brew install ffmpeg` / `apt install ffmpeg` |
| yt-dlp | latest | see below |
| whisper | any | see below (only for `TRANSCRIPTION_PROVIDER=local`) |
| Ollama | latest | https://ollama.com/download (only for `LLM_PROVIDER=ollama`) |

**Install yt-dlp:**
```bash
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
  -o /usr/local/bin/yt-dlp && chmod +x /usr/local/bin/yt-dlp

yt-dlp --version   # verify
```

**Install Whisper (local transcription only):**
```bash
pip3 install openai-whisper
whisper --help   # verify
```

**Install Ollama + pull model (local LLM only):**
```bash
brew install ollama          # macOS
ollama serve &               # start server in background
ollama pull llama3.2         # ~2GB first-time download
```

### Step 1 — Clone and set environment variables

```bash
git clone <repo-url>
cd stackoverflow_clone
cp .env.example .env
# Edit .env with your Slack credentials and provider choices
```

Load into your shell:
```bash
export $(grep -v '^#' .env | xargs)
```

### Step 2 — Install Elixir dependencies

```bash
mix deps.get
```

### Step 3 — Set up Postgres

```bash
# Create the DB + run all migrations (includes Oban tables)
mix ecto.setup
```

SQLite migrations for the reels table run automatically at app startup.

### Step 4 — Start the server

```bash
mix phx.server
```

Watch for:
```
[info] Running StackoverflowCloneWeb.Endpoint with Bandit
[info] ReelsRepo: migrated 2 migration(s)
```

### Step 5 — Expose and configure Slack

Same as Docker Steps 5–6 above (`ngrok http 4000`, then configure the Slack app).

---

## Running Tests

```bash
# Make sure Postgres is running, then:
mix test

# Watch mode during development
mix test.watch
```

The test suite:
- Uses the Postgres sandbox for controller tests
- Creates a per-partition SQLite file at `/tmp/reels_testN.db`
- Runs Oban jobs inline (no background workers needed)
- Uses Mox mocks for all external calls (yt-dlp, ffmpeg, Whisper, Ollama/OpenAI, Slack)

---

## Environment Variable Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `SLACK_BOT_TOKEN` | — | **Required.** `xoxb-...` from Slack OAuth |
| `SLACK_SIGNING_SECRET` | — | **Required.** From Slack app Basic Information |
| `TRANSCRIPTION_PROVIDER` | `local` | `local` (whisper CLI) or `openai` |
| `LLM_PROVIDER` | `ollama` | `ollama` (local) or `openai` |
| `OPENAI_API_KEY` | — | Required if either provider is `openai` |
| `OLLAMA_BASE_URL` | `http://localhost:11434` | Override if Ollama runs elsewhere |
| `TRANSCRIPT_MAX_LENGTH` | `500` | Max chars of transcript shown in Slack reply |
| `POSTGRES_HOST` | `localhost` | Postgres hostname |
| `POSTGRES_USER` | `postgres` | Postgres user |
| `POSTGRES_PASSWORD` | `postgres` | Postgres password |
| `POSTGRES_DB` | `stackoverflow_clone_dev` | Postgres database name |
| `REELS_DB_PATH` | `priv/reels_dev.db` (dev) | SQLite file path (production only) |

---

## Choosing Providers

**Fully local (no API costs):**
```bash
TRANSCRIPTION_PROVIDER=local
LLM_PROVIDER=ollama
# whisper downloads ~140MB model on first run
# Ollama downloads ~2GB llama3.2 model on first run
```

**Fully cloud (fastest, needs OpenAI key):**
```bash
TRANSCRIPTION_PROVIDER=openai
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-...
```

**Hybrid (local LLM, cloud transcription):**
```bash
TRANSCRIPTION_PROVIDER=openai   # fast, no GPU needed
LLM_PROVIDER=ollama             # private, no cost
OPENAI_API_KEY=sk-...
```
