# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Self-hosted GitHub Actions runner designed for DigitalOcean App Platform. The runner auto-registers on container start and auto-deregisters on shutdown via SIGTERM trap. Supports both repository-level and organization-level runners with horizontal/vertical scaling.

## Architecture

This is a Docker-only project with two core files:

- **Dockerfile** — Ubuntu 24.04 base image that installs GitHub Actions Runner (latest), Docker CLI, Node.js LTS, Git, and packages from GitHub's official `toolset-2404.json`. Runs as non-root `actions` user.
- **entrypoint.sh** — Bash script that validates env vars, fetches a runner registration token from GitHub API, registers the runner via `config.sh`, runs it via `run.sh` in background, and traps SIGTERM for cleanup/deregistration.
- **.do/deploy.template.yaml** — DigitalOcean App Platform deployment spec.

## Build & Run

```bash
# Build the Docker image
docker build -t do-actions-runner .

# Run (repository-level)
docker run -e TOKEN=<github_pat> -e OWNER=<owner> -e REPO=<repo> do-actions-runner

# Run (organization-level)
docker run -e TOKEN=<github_pat> -e ORG=<org_name> do-actions-runner

# Optional: set custom runner name
docker run -e TOKEN=<github_pat> -e OWNER=<owner> -e REPO=<repo> -e NAME=my-runner do-actions-runner
```

## Required Environment Variables

- `TOKEN` — GitHub PAT (`repo` scope for repo-level, `admin:org` for org-level)
- `OWNER` + `REPO` — For repository-level runners
- `ORG` — For organization-level runners
- `NAME` — Optional custom runner name (defaults to hostname)

## Key Implementation Details

- The toolset packages are fetched dynamically from `actions/runner-images` repo at build time — if builds fail, check if the toolset URL or JSON structure changed.
- Runner version is fetched from GitHub API at build time (`actions/runner/releases/latest`).
- `entrypoint.sh` uses `set -eEuo pipefail` — any unhandled error will stop the container.
- The runner process is backgrounded (`./run.sh &`) with `wait $!` so the trap can catch SIGTERM for graceful deregistration.
