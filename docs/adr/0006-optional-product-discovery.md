# ADR-0006: Optional Guided Product Discovery

Status: Accepted
Date: 2026-11-02
Related: ADR-0004 (proportionate workflow)

## Context

The requirements template assumes contributors already know the intended scope.
An approved proposal asks for guided elicitation and explicit review, while
existing ProductSpec and gstack tools already cover substantial adjacent work.

## Decision

Ship an optional discovery skill, guide, templates, worked example and structural
checker. Bootstrap installs supporting records only with `--product-discovery`.
Keep PRODUCT_REQUIREMENTS.md canonical. Do not add required files or mandatory
discovery steps to all adopters. Use Bash, Git and AWK, with no network execution.

The checker follows warn-by-default / strict-to-fail conventions. It checks
revision and digest consistency, explicit decision record fields, typed unknowns,
and changed requirement evidence references. It cannot authenticate approvers,
judge product quality, discover all affected requirements, run product tests, or
certify business outcomes. Draft validity never implies readiness.

ProductSpec exchange is documented against a pinned reference with explicit
many-to-many mappings and unsupported semantics; automatic conversion is deferred.

## Consequences

Non-technical contributors can participate through conversation and a readable
review. Facilitators maintain artifacts and accountable humans make decisions.
Content hashes normalize CR at line ends for Windows/Linux portability, then
conservatively invalidate reviews for other formatting edits. Retired IDs remain
declared as tombstones so their evidence can be reassessed without reusing IDs.
Pilot evidence is needed before claiming usefulness or demand. A hosted UI and
automatic synchronization would add complexity before that evidence exists.

## Alternatives

Expanding only the requirements template would not guide discovery. Requiring
gstack excludes other tools. A new serialization duplicates ProductSpec. Making
discovery mandatory adds ceremony to projects that do not need it.
