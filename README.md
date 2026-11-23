[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/huggingchat?utm_medium=integration&utm_source=button&utm_campaign=huggingchat)

# HuggingChat on Railway

This repo packages [HuggingChat](https://github.com/huggingface/chat-ui) (Hugging Face's open-source `chat-ui`, the app behind huggingface.co/chat) as a one-click Railway template. It talks to any OpenAI-compatible API: the Hugging Face Inference router by default, or OpenAI, OpenRouter, Groq, Together, a vLLM/Ollama server and so on.

## What the template deploys

| Service | Source | What it does |
|---|---|---|
| **HuggingChat** | this repo, folder `app/` | `chat-ui` (official image `ghcr.io/huggingface/chat-ui:sha-152ee7d`, pinned by digest) behind a small Caddy proxy that asks for a username and password and answers `/healthcheck` for Railway. Public HTTPS domain. |
| **MongoDB** | `mongo:7.0.48` (pinned by digest) | Stores conversations, settings, assistants and uploaded files (GridFS) on a Railway volume at `/data/db`. Password generated at deploy. Private network only. |

Upstream's latest release is `v0.10.0` (2026-05-11), but its release image was never published (the build failed upstream). The pinned image is upstream's official build of `152ee7d`, the commit just before the `v0.10.0` tag; the tag only adds a CSS margin tweak on top.

## Variables

| Service | Variable | Default | Notes |
|---|---|---|---|
| HuggingChat | `OPENAI_API_KEY` | *(you enter it)* | API key for the endpoint below (a Hugging Face token `hf_…` for the default router). |
| HuggingChat | `OPENAI_BASE_URL` | `https://router.huggingface.co/v1` | Any OpenAI-compatible base URL. Models are discovered from `${OPENAI_BASE_URL}/models`. |
| HuggingChat | `BASIC_AUTH_USER` | `admin` | Username for the login prompt. |
| HuggingChat | `BASIC_AUTH_PASSWORD` | generated | Password for the login prompt. Read it in the service's Variables tab. |
| HuggingChat | `MONGODB_URL` | reference to MongoDB | Private-network connection string. |
| HuggingChat | `PUBLIC_ORIGIN` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Public URL, used for share links. |
| HuggingChat | `PORT` | `8080` | Port the proxy listens on. |
| MongoDB | `MONGO_INITDB_ROOT_USERNAME` / `MONGO_INITDB_ROOT_PASSWORD` | `mongo` / generated | Database login, used only on the private network. |
| MongoDB | `MONGO_REPLICA_KEY` | generated | Key for the single-node replica set `rs0` (chat-ui's migrations use transactions). |
| MongoDB | `MONGO_URL` | built from the above | Connection string the HuggingChat service references. |

Any other `chat-ui` setting from upstream's [`.env`](https://github.com/huggingface/chat-ui/blob/main/.env) can be added as a variable on the HuggingChat service (for example `MODELS`, `TASK_MODEL`, `PUBLIC_APP_NAME`, `OPENID_*` for single sign-on, `MCP_SERVERS`).

## Why a password proxy?

`chat-ui` has no built-in user accounts unless you configure OpenID Connect, so anyone who finds the URL could chat on your API key. The proxy asks for `BASIC_AUTH_USER` / `BASIC_AUTH_PASSWORD` and passes the username to `chat-ui` (`TRUSTED_EMAIL_HEADER`), so your conversations follow you across browsers and devices.

## After deploy

1. Open the service's public URL and sign in with `admin` and the generated `BASIC_AUTH_PASSWORD` (HuggingChat service → Variables).
2. Pick a model from the list (discovered from your endpoint) and start chatting.
3. To switch providers, change `OPENAI_BASE_URL` and `OPENAI_API_KEY` and redeploy.

## Memory

Tested with each service limited to 0.5 GB RAM and 1 vCPU (Railway's Free plan). The start script caps Node's heap (`NODE_OPTIONS=--max-old-space-size=320`), libvips threads and MongoDB's WiredTiger cache (0.25 GB).

## Updates

Railway tells everyone who deployed this template when a change lands on this repo's `main` branch, and you choose when to apply it. Every update is listed in [`CHANGELOG.md`](CHANGELOG.md), breaking changes first. MongoDB's image is not updated automatically.

## Licence

`chat-ui` is Apache-2.0 (Hugging Face). This wrapper is Apache-2.0 as well.
