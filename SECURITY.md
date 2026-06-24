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

## Permissions

Apply least privilege:

- Grant only required access.
- Scope credentials narrowly.
- Separate development, staging, and production access.
- Review administrative operations carefully.

## Dependencies

Review dependency risk regularly:

- Prefer mature and maintained dependencies.
- Remove unused dependencies.
- Track known vulnerabilities.
- Avoid adding dependencies for trivial functionality.

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
