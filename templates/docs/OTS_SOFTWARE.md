# OTS Software Inventory

This inventory tracks every off-the-shelf (OTS) software component this project depends on: third-party libraries, frameworks, runtimes, databases, and any other software the project uses but did not develop. It answers, for each component: what it is, why we use it, how risky it is, how we verified it is fit for use, and how it stays current.

The structure follows the intent of the FDA's OTS software guidance and IEC 62304's SOUP (Software of Unknown Provenance) requirements, generalized for any repository — regulated or not. For most projects it is simply the auditable answer to "what third-party software are we shipping, and is anyone watching it?"

It is a living document. Update it in the same change that adds, removes, or upgrades a dependency.

Related documents:

- `SECURITY.md` (constitution) — dependency risk review expectations and threat-modeling triggers.
- `docs/TEST_PLAN.md` — where verification evidence (test suites exercising a component) is declared.

## Conventions

- **Component ID**: a stable identifier, `OTS-001`, `OTS-002`, ... Once assigned, an ID is never reused, even after the component is removed. When a component is removed, set its Status to `Removed` rather than deleting the row.
- **Name**: the component's name **exactly as it is declared in the dependency manifest** (`package.json`, `requirements.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`, ...). The automated checker (`constitution/scripts/check_ots_inventory.sh`) matches manifest entries against this cell by exact value (case-insensitive), so a paraphrased or prettified name counts as undocumented.
- **Risk**: `Low`, `Medium`, or `High`. A component is at least `Medium` when it sits in a trust-sensitive position — handling credentials, parsing untrusted input, or running with elevated privileges (see `SECURITY.md`'s "Threat Modeling Triggers").
- **Verification**: how fitness for use was established — for example, the project's own integration tests that exercise it, upstream test-suite maturity, vendor certification, or a manual validation record.
- **Anomaly Review**: known-issue posture — where known defects/CVEs for this component are tracked, and the date they were last reviewed.
- **Update Policy**: how the version moves — pinned exactly, pinned to a range, Dependabot/Renovate-managed, vendored, etc.
- **Status**: `Active`, `Evaluating`, or `Removed`.

## Managed Dependencies

Components declared in a dependency manifest in this repository. `constitution/scripts/check_ots_inventory.sh` cross-checks the manifests against this table, so a dependency added without a row here is flagged.

<!-- Add one row per manifest-declared dependency. Delete the placeholder row once real entries exist. -->

| Component ID | Name | Version | Supplier / Maintainer | Purpose | Risk | Verification | Anomaly Review | Update Policy | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| OTS-001 | `<name exactly as declared in the manifest>` | `<version or range>` | `<who maintains it>` | `<role in this system>` | `<Low / Medium / High>` | `<how fitness for use was established>` | `<tracker link — last reviewed <YYYY-MM-DD>>` | `<pinned / range / bot-managed>` | Active |

## System-Level OTS

Software the project depends on that is **not** declared in a dependency manifest: operating systems, language runtimes, databases, message brokers, container base images, and similar. The checker cannot discover these automatically — keep this section honest by hand.

<!-- Add one row per system-level component. Delete the placeholder row once real entries exist. -->

| Component ID | Name | Version | Supplier / Maintainer | Purpose | Risk | Verification | Anomaly Review | Update Policy | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| OTS-101 | `<e.g. PostgreSQL>` | `<version>` | `<who maintains it>` | `<role in this system>` | `<Low / Medium / High>` | `<how fitness for use was established>` | `<tracker link — last reviewed <YYYY-MM-DD>>` | `<managed by / upgrade cadence>` | Active |

## Review Cadence

- Review this inventory whenever a dependency is added, removed, or upgraded — in the **same change**, not a later documentation pass.
- Periodically (at least once per release), re-review the Anomaly Review column: check each `Medium`/`High` component's tracker for newly reported defects and CVEs, and refresh the last-reviewed dates.
- A dependency the checker reports as undocumented is a gap: add its row (or remove the dependency) before the change merges.
