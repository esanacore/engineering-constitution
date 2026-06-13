# Operations and Infrastructure Standards

Operations work should be reviewable, observable, and recoverable.

## Scope

Apply these standards to:

- deployment workflows
- infrastructure-as-code changes
- environment configuration
- scheduled jobs
- backups and restore procedures
- production support runbooks
- incident response

## Environment Discipline

- Define the environments a project uses, such as local, staging, and production.
- Document the purpose and promotion path for each environment.
- Avoid undocumented "special" environments that only one person understands.
- Keep environment-specific configuration explicit and version controlled where possible.

## Change Management

- Infrastructure changes should be reviewed with the same rigor as application code.
- Prefer infrastructure as code over manual console changes.
- Record rollout steps, rollback steps, and any operator prerequisites.
- Document stateful or destructive changes before execution.

## Secrets and Access

- Do not store secrets in source control.
- Use managed secret storage where available.
- Keep access scoped to least privilege.
- Document who can deploy, rotate credentials, approve production changes, and access operational dashboards.

## CI/CD Expectations

- Every actively delivered project should define a basic validation path in CI.
- CI should run the fastest checks that catch broken builds, broken tests, schema drift, or documentation drift early.
- CD pipelines should make deployment steps, promotion gates, and approvals visible.
- Repositories without CI yet should track that gap in `TODO.md`.

## Observability

- Document where logs, metrics, traces, and alerts live.
- New services should define enough diagnostics to support troubleshooting without guesswork.
- Alerting should focus on actionable failures, not noise.
- Operator-facing dashboards and key health signals should be easy to locate.

## Reliability and Recovery

- Document backup and restore expectations for persistent data.
- Define rollback or mitigation paths for risky changes.
- Capture known failure modes and first-response steps in `docs/OPERATIONS.md` or project runbooks.
- If recovery depends on manual steps, document them before the change ships.

## Incident Response

- Define who gets notified when a service fails or data is at risk.
- Capture the first-response checklist, escalation path, and stakeholder communication expectations.
- Follow up significant incidents with documented corrective actions.

## Agent Responsibilities

Agents working on operational or infrastructure changes should:

- review operational documentation impact
- review security and permissions impact
- identify rollout and rollback needs
- verify the relevant automation or commands
- record follow-up reliability work in `TODO.md`

## Project Documentation Expectations

Projects with meaningful runtime or deployment behavior should maintain `docs/OPERATIONS.md` covering:

- deployment procedure
- monitoring and alert locations
- backup and restore steps
- rollback guidance
- incident contacts or escalation notes
