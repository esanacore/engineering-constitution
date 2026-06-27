# Operations — Orders API

This is a **fully worked example** of `docs/OPERATIONS.md` for a deployed
service, written to show what a complete operations runbook looks like under
Eric's Engineering Constitution. It describes a fictional service, **Orders
API**, and fills in every section the blank template
(`templates/docs/OPERATIONS.md`) leaves as a placeholder. Copy the structure,
not the specifics: replace the service details, hostnames, and tool names with
your own.

> Orders API is a containerized HTTP service that accepts and queries customer
> orders. It is written in Python (FastAPI), packaged as a Docker image, and
> deployed to Kubernetes. It is backed by a PostgreSQL database and a Redis
> cache, sits behind a managed load balancer, and is deployed by GitHub Actions.

## Service Summary

| Property | Value |
| --- | --- |
| Service name | `orders-api` |
| Runtime | Python 3.12 / FastAPI on Uvicorn |
| Packaging | Docker image `registry.example.com/orders-api` |
| Orchestration | Kubernetes namespace `orders` |
| Datastores | PostgreSQL 16 (`orders-db`), Redis 7 (cache, ephemeral) |
| Public entry point | `https://api.example.com/orders` via managed load balancer |
| Source of truth for infra | `infra/` (Terraform) and `deploy/` (Helm chart) |
| Owning team | Fulfilment Platform (`#team-fulfilment`) |

## Environments

| Environment | Purpose | URL | Promotes from |
| --- | --- | --- | --- |
| `local` | Developer machines via `docker compose up` | `http://localhost:8080` | — |
| `staging` | Pre-production validation; production-like data shape, synthetic data | `https://api.staging.example.com/orders` | `main` branch |
| `production` | Live customer traffic | `https://api.example.com/orders` | promoted staging release |

- Promotion path: `local → staging → production`. There are no other
  environments. Anything else (a one-off load test cluster, for example) is
  created from the same Helm chart, labelled `ephemeral`, and torn down within
  24 hours.
- Per-environment configuration lives in `deploy/values/<env>.yaml` (committed)
  and secrets in the cluster's secret store (not committed — see
  [Secrets](#secrets-and-configuration)).

## Toolchain and Prerequisites

The local toolchain must match what CI assumes (see the constitution's
Toolchain Parity standard).

- Pinned versions: `.python-version` (3.12.x), `.tool-versions` (Terraform,
  Helm, kubectl), and `engines` is not used (Python project).
- Run the prerequisite check before operating on the service:

  ```bash
  make doctor
  ```

  It verifies the Python version, that `kubectl`, `helm`, `terraform`, and
  `psql` are installed and on a supported version, that the `constitution/`
  submodule is initialized, and that a cluster context is selected. It fails
  fast and names exactly what is missing.

## Deployment

### Deployment Procedure

Deployment is automated through GitHub Actions; no one deploys from a laptop.

1. Merge to `main`. CI builds and tags the image
   `registry.example.com/orders-api:<git-sha>` and runs the full test suite.
2. The `deploy-staging` workflow deploys that image to `staging` automatically
   and runs smoke tests (`make smoke ENV=staging`).
3. To promote to production, run the `deploy-production` workflow
   (`workflow_dispatch`) with the staging release tag. It:
   - applies any pending database migrations (see [Stateful Changes](#stateful-changes-and-migrations)),
   - performs a rolling update of the Kubernetes Deployment (`maxUnavailable: 0`,
     `maxSurge: 1`), and
   - runs production smoke tests and waits for readiness before completing.

### Approvals and Gates

- A pull request requires passing CI (unit, integration, `check_compliance.sh`,
  `check_traceability.sh`, and the constitution version gate) and one human
  review before it can merge.
- The `deploy-production` workflow requires approval from a second member of
  the owning team via a GitHub Environments protection rule on the `production`
  environment.
- Production deploys are blocked during the Friday 16:00–Monday 09:00 freeze
  window except for incident mitigation.

### Rollback

Rollback is the first response to a bad deploy; diagnosis comes after service is
restored.

```bash
# Roll back to the previous released revision
helm rollback orders-api --namespace orders

# Or pin a specific known-good image tag
helm upgrade orders-api deploy/chart \
  --namespace orders \
  --values deploy/values/production.yaml \
  --set image.tag=<last-good-git-sha>
```

- Confirm recovery: `make smoke ENV=production` passes and the error-rate and
  latency dashboards return to baseline.
- Rollback is safe **only** for application changes. A deploy that included a
  destructive or non-backward-compatible migration cannot be rolled back by
  redeploying the old image — see [Stateful Changes](#stateful-changes-and-migrations).

## Monitoring and Observability

| Signal | Where | Notes |
| --- | --- | --- |
| Logs | Grafana Loki, label `app=orders-api`, also `kubectl logs -n orders` | Structured JSON; include `request_id` |
| Metrics | Grafana dashboard "Orders API — Service" | Backed by Prometheus; RED metrics (rate, errors, duration) |
| Traces | Tempo, service `orders-api` | OpenTelemetry, sampled at 10% (100% on error) |
| Uptime | Synthetic check against `/healthz` every 30s | Public-path probe |
| Alerts | Alertmanager → PagerDuty service "Orders API" and `#alerts-fulfilment` | See thresholds below |

### Health Endpoints

- `GET /healthz` — liveness; process is up.
- `GET /readyz` — readiness; database and Redis reachable. Kubernetes uses this
  to gate traffic during rollout.

### Alert Thresholds

| Alert | Condition | Severity |
| --- | --- | --- |
| High error rate | 5xx rate > 2% over 5 min | SEV2 (page) |
| Latency | p99 > 800 ms over 10 min | SEV3 (notify) |
| Saturation | CPU > 85% or memory > 90% over 10 min | SEV3 (notify) |
| Pod crash loop | any pod restarts > 3 in 10 min | SEV2 (page) |
| DB connections | pool usage > 90% over 5 min | SEV2 (page) |
| Synthetic down | `/healthz` failing > 2 min | SEV1 (page) |

## Safe Operations

### Backup and Restore

- **Backups**: `orders-db` (PostgreSQL) is backed up by the managed database
  service with automated daily snapshots and 5-minute point-in-time recovery
  (PITR) WAL archiving. Snapshots are retained for 30 days. Redis holds only
  cache data and is **not** backed up.
- **Restore drill**: restore the latest snapshot into a scratch database and run
  `make verify-restore` quarterly. Record the result in the team log. A backup
  that has never been restored is not a backup.
- **Restore procedure** (data loss / corruption):
  1. Put the service in [maintenance mode](#maintenance-mode).
  2. Restore the target snapshot (or PITR timestamp) into a new database
     instance.
  3. Repoint `DATABASE_URL` (secret) and restart the Deployment.
  4. Run `make verify-data` and exit maintenance mode.

### Maintenance Mode

```bash
# Enable: serve HTTP 503 with a maintenance page from the ingress
kubectl annotate ingress orders-api -n orders \
  maintenance=true --overwrite

# Disable
kubectl annotate ingress orders-api -n orders maintenance-
```

Enable maintenance mode before any restore or destructive migration so the
service does not write to a database that is being replaced underneath it.

### Stateful Changes and Migrations

Database migrations are the highest-risk operation and follow the
**expand/contract** pattern so every deploy is independently reversible:

1. **Expand**: add new columns/tables as nullable/additive. Deploy. The old and
   new code both work against this schema.
2. **Migrate data**: backfill in batches via a one-off Job (`make backfill`),
   monitoring replication lag.
3. **Contract**: only after the new code is fully rolled out and stable, a
   later deploy removes the old columns.

- Migrations run via `alembic upgrade head` as a pre-deploy step in the
  production workflow; they are forward-only.
- A destructive step (dropping a column, deleting rows) requires a fresh backup
  taken immediately beforehand, is documented in the PR, and never shares a
  deploy with the change that stops using that data.

### Secrets and Configuration

- Secrets (`DATABASE_URL`, `REDIS_URL`, signing keys, third-party API tokens)
  live in the cluster secret store and are injected as environment variables;
  they are never committed.
- Rotation: rotate credentials quarterly and immediately after any suspected
  exposure. `make rotate-db-credentials` performs a zero-downtime rotation by
  adding the new credential, rolling the Deployment, then revoking the old one.
- Non-secret configuration is in `deploy/values/<env>.yaml` and version
  controlled.

## Dependencies

| Dependency | Purpose | Failure behavior |
| --- | --- | --- |
| PostgreSQL (`orders-db`) | System of record | Hard dependency; `/readyz` fails, requests return 503 |
| Redis (cache) | Read-through cache | Soft dependency; service degrades to direct DB reads |
| Payments API (external) | Order authorization | Circuit breaker opens after 5 failures; orders queue for retry |
| Identity provider (OIDC) | Request authentication | Cached JWKS for 1 hour; new logins fail if down |

## Incident Response

### Severities and Response

| Severity | Definition | Response |
| --- | --- | --- |
| SEV1 | Full outage or data loss | Page on-call immediately; open incident channel; notify stakeholders within 15 min |
| SEV2 | Major degradation, partial outage | Page on-call; mitigate before deep diagnosis |
| SEV3 | Minor degradation, no customer impact yet | Notify; handle within business hours |

### On-Call and Ownership

- On-call rotation: Fulfilment Platform team, weekly, managed in PagerDuty.
- Escalation: on-call → team lead (15 min unack) → engineering manager.
- Incident channel: open `#inc-orders-api-<date>` and pin the dashboard,
  recent deploy list, and the incident commander.

### General Incident Procedure

1. **Assess impact**: who and what is affected; assign a severity.
2. **Mitigate first**: if a recent deploy correlates with the start,
   [roll back](#rollback) before diagnosing. If a dependency is down, confirm
   the circuit breaker / degradation is behaving as designed.
3. **Diagnose**: check the Orders API dashboard (errors, latency, saturation),
   recent deploys, logs in Loki filtered by `request_id`, and traces in Tempo.
4. **Communicate**: post status updates in the incident channel at a regular
   cadence; notify stakeholders for SEV1/SEV2.
5. **Recover**: confirm smoke tests pass and dashboards return to baseline.
6. **Follow up**: file a blameless postmortem within two business days with
   timeline, root cause, and action items; track the action items in `TODO.md`.

### Common Runbooks

- **5xx spike right after a deploy** → roll back (`helm rollback orders-api`),
  confirm recovery, then investigate the reverted change.
- **`/readyz` failing, DB unreachable** → check the database service status and
  connection pool metrics; fail over to the replica if the primary is down;
  if connections are exhausted, scale down noisy clients and raise the pool
  limit via config.
- **Payments API errors / circuit breaker open** → confirm the upstream status
  page; orders are queued for retry, so verify the retry worker is draining the
  queue once the dependency recovers; no rollback needed.
- **Crash loop after config change** → inspect `kubectl describe pod` and recent
  events; revert the offending `values/<env>.yaml` change and redeploy.
