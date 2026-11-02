# Synthetic Discovery Walkthrough

All people, decisions, and source references here are fictional scenario data.
They are not real approvals, customer research, a deployed product, or pilot
results. The framework's workflow and checker are real; the report exporter
described by this example is not implemented.

## 1. Initial Request

"Let customers export reports." In the interview, the fictional operations lead
asks for a spreadsheet containing filtered rows. A fictional sales stakeholder
wants all account data in the same export. The engineer asks who may export and
how private data is restricted. Neither request establishes a customer need.

## 2. Read-Back and Decision

The facilitator distinguishes an assumption (CSV is sufficient) from a decision
(exports must respect the current user's account boundary). Fictional product
owner Morgan chooses filtered rows only. Cross-account export is excluded.
Source: `scenario-decision-1` in this paragraph, not an external interview.

Teach-back: the contributor identifies CSV as an assumption, corrects "all rows"
to "filtered rows", and explains why cross-account export is excluded. In a
real pilot, record the actual participant response rather than copying this.

## 3. Revision and Approval Boundary

Revision 1 proposed a 10,000-row synchronous export. During fictional engineering
review, request duration is unknown. Morgan chooses a 1,000-row first slice
instead of quietly accepting an untested performance promise. Revision 2 in
`docs/PRODUCT_REQUIREMENTS.md` records that choice; the old approval cannot be
carried to revision 2. `docs/discovery/REVIEW.md` intentionally remains **In
Review** with pending approvals, even though the record is structurally valid.

The changed-evidence row flags FR-001 for reassessment. A prior 10,000-row test
would not prove the new boundary behavior. No test result or approval is claimed.
This demonstrates revision handling without fabricated completion evidence.

## 4. Run the Structural Check

From the framework root (Git Bash on Windows, Bash on macOS/Linux):

```bash
bash scripts/check_product_discovery.sh --strict examples/product-discovery
```

Then edit the canonical scope without updating the review and run again. The
stale digest must fail. Restore the file after trying this. In a real project,
increment intent revision, archive the old review, reset decisions to Pending,
and review the new revision; never refresh a digest to retain an old approval.

Executable evidence for the discovery mechanism lives in
[`test_check_product_discovery.sh`](../../scripts/test_check_product_discovery.sh).
Its synthetic fixtures exercise valid draft and approved records, stale content,
stale decisions, unresolved blockers, retired IDs and invalid evidence records.
Those tests verify the framework's record checks, not the report-export behavior.

## 5. What Happens Next

A real product owner would explicitly approve intent, and an engineering
reviewer would separately decide readiness. Implementers would add boundary,
permission, failure, and recovery tests, recording execution evidence in the
traceability matrix. Only later could an owned observation window establish
business outcomes. This example deliberately stops before those claims.
