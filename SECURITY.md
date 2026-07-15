# Security Standards

Security must be considered for all significant changes.

## Review Areas

Review:

- Authentication
- Authorization
- Input validation
- Secret management
- Permissions
- Third-party dependencies
- Logging
- Auditing

## Input Validation

Validate inputs at system boundaries:

- User-submitted data
- API requests
- Uploaded files
- Command-line arguments
- Environment variables
- Webhook payloads
- External service responses

## Secrets

Secrets must not be committed to source control.

Use appropriate secret storage for:

- API keys
- Tokens
- Passwords
- Certificates
- Private keys
- Production credentials

### Secrets Sweep

Sweeping the entire project for secrets that should be gitignored is a
standard practice for every repository that adopts this constitution, not an
optional extra. The framework ships a reference checker,
`scripts/check_secrets.sh`, that adopters run through the `constitution/`
submodule:

```bash
bash constitution/scripts/check_secrets.sh
```

It checks tracked files *and* untracked-but-not-gitignored files (so a
secret sitting in the working tree is caught before an accidental
`git add -A`, not only after it's committed) for:

- Filenames shaped like credentials (`.env`, `id_rsa`, `*.pem`, `*.key`,
  `*.p12`, `credentials.json`, service-account JSON, `.netrc`,
  `terraform.tfstate`, ...).
- High-confidence secret patterns in file content (AWS access keys, GitHub
  and Slack tokens, PEM private key blocks, Google and Stripe API keys).

A real hit always fails the check, with or without `--strict`. It also
reports (warn by default, `--strict` to fail) whether `.gitignore` already
covers the known secret-file patterns above, so a gap can be closed before it
becomes a real leak.

`scripts/bootstrap.sh` wires this in two ways so it runs before a secret ever
reaches a remote:

- A pre-push `pre-commit` hook (`.pre-commit-config.yaml`), so it runs
  locally before every `git push`.
- `.github/workflows/constitution-secrets.yml`, a CI backstop for anyone who
  skipped the local hook.

This is a zero-dependency baseline (bash and Git only) with a curated,
high-confidence pattern set — it is intentionally not exhaustive. Projects
handling unusually sensitive credentials should still consider a dedicated
scanner (for example gitleaks or trufflehog) for deeper coverage.

## Permissions

Apply least privilege:

- Grant only required access.
- Scope credentials narrowly.
- Separate development, staging, and production access.
- Review administrative operations carefully.

## Agent Runtime Security

Autonomous AI agents executing development or operational tasks should operate under the principle of least privilege. Projects should deploy these agents behind an AI-specific protocol firewall (such as Claw Patrol) to restrict their network and system access.

The agent environment should be configured to:

- Block unauthorized or destructive commands (for example, dropping tables, deleting infrastructure, or modifying secrets).
- Prevent the exfiltration of credentials or sensitive data to untrusted endpoints.
- Ensure all agent actions are logged and auditable.

## Dependencies

Review dependency risk regularly:

- Prefer mature and maintained dependencies.
- Remove unused dependencies.
- Track known vulnerabilities.
- Avoid adding dependencies for trivial functionality.

### OTS Software Inventory

Dependency risk review needs a durable record, not just good intentions.
Repositories with third-party dependencies maintain `docs/OTS_SOFTWARE.md` —
an off-the-shelf software inventory documenting, per component, its purpose,
risk level, verification, known-anomaly (defect/CVE) tracking posture, and
update policy. See `DOCUMENTATION.md`'s "OTS Software Inventory" section for
the full structure.

The framework ships a reference checker that adopters run through the
`constitution/` submodule:

```bash
bash constitution/scripts/check_ots_inventory.sh
```

It cross-checks the runtime dependencies declared in root-level manifests
(`package.json`, `requirements.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`,
`Gemfile`) against the inventory, flagging any dependency with no inventory
row — so "we added a dependency but never documented or risk-assessed it"
is caught mechanically instead of in a later audit. It warns by default;
`--strict` makes gaps fail (see `TESTING.md`'s "CI Enforcement" rollout
contract). `scripts/bootstrap.sh` installs
`.github/workflows/constitution-ots.yml` to run it in CI on every push, pull
request, and a daily schedule.

A new dependency in a trust-sensitive position is also a threat-modeling
trigger (see below) — the inventory row records the outcome; it does not
replace the analysis.

## Logging and Auditing

Logs should support diagnosis without leaking sensitive information.

Avoid logging:

- Secrets
- Full tokens
- Passwords
- Sensitive personal data
- Unredacted payment or identity data

## Threat Modeling Triggers

Whether a change needs a threat model should be decided by a checklist, not by reviewer intuition. Produce a lightweight threat model (for example, STRIDE or an OWASP-aligned analysis) before the change ships when it introduces any of the following:

- A new outbound network egress path or a new external endpoint the system talks to.
- A new authentication or authorization surface, or a change to an existing trust boundary.
- A new category of data leaving the device, process, or security boundary.
- A new third-party dependency in a trust-sensitive position (for example, handling credentials, parsing untrusted input, or running with elevated privileges).
- A new way for untrusted input to reach a sensitive sink (for example, a new file upload, deserializer, template renderer, or command/SQL execution path).

The threat model should record the assets, the trust boundaries crossed, the threats considered, and the mitigations chosen. Capture the outcome in an ADR when it affects architecture or operational risk (see below).

## Security Decisions

Document security-sensitive decisions in ADRs when they affect architecture, storage, authentication, authorization, infrastructure, or operational risk.
