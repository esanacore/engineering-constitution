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

## Security Decisions

Document security-sensitive decisions in ADRs when they affect architecture, storage, authentication, authorization, infrastructure, or operational risk.
