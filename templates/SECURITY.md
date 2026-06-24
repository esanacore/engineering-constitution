# Project Security

This project follows [Eric's Engineering Constitution Security Standards](constitution/SECURITY.md).

## Local Security Concerns

- **LAN Exposure**: <!-- Document if services bind to 0.0.0.0 or 127.0.0.1 -->
- **Credential Handling**: Never commit secrets. Use `.env` files (ignored by Git).
- **Sensitive Data**: <!-- Document any PII or sensitive data handled by the repo -->

## Security Checklist

- [ ] Credentials are stored in environment variables, not code.
- [ ] Dependencies are audited for vulnerabilities.
- [ ] Inputs are validated at boundaries.
- [ ] Logs do not contain secrets or PII.
- [ ] A threat model was produced if the change hit any trigger in the constitution's [Threat Modeling Triggers](constitution/SECURITY.md) (new egress path, new auth/authz surface, new data leaving the boundary, or new trust-sensitive dependency).
