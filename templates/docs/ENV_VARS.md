# Environment & Configuration Contract

This document lists all environment variables required or optionally supported by this project.
It acts as the single source of truth for configuration parameters across development, staging, and production environments.

> [!IMPORTANT]
> If you add a new environment variable to a manifest (like `.env.example` or `docker-compose.yml`), you **must** document it in this file in the same pull request.

## Required Variables

These variables must be set for the application to start or build correctly.

| Variable | Description | Example Value |
| :--- | :--- | :--- |
| `NODE_ENV` | (Example) The runtime environment | `development`, `production` |

## Optional Variables

These variables have safe defaults or toggle non-critical features.

| Variable | Description | Default Value | Example Value |
| :--- | :--- | :--- | :--- |
| `LOG_LEVEL` | (Example) The verbosity of system logs | `info` | `debug` |
