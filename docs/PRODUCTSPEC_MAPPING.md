# ProductSpec Exchange Boundary

This release supplies guidance, not an automatic converter or ProductSpec
conformance claim. `docs/PRODUCT_REQUIREMENTS.md` remains canonical in the
Constitution workflow. Any export is a derived snapshot and must not become a
second independently edited intent document.

## Reviewed Upstream Baseline

Reviewed 2026-11-02: [ProductSpec specification at
97b90b6288bbcd159bbec0f75fac9bf8212d2dc8](https://github.com/gokulrajaram/ProductSpec/blob/97b90b6288bbcd159bbec0f75fac9bf8212d2dc8/SPEC.md),
format `0.1`. Upstream already includes authoring, generated handoffs, related
evidence, revision checks and run reconciliation. See its [Product Harness](https://github.com/gokulrajaram/ProductSpec/blob/97b90b6288bbcd159bbec0f75fac9bf8212d2dc8/docs/product-harness.md).
This is an interoperability research pin, not an installed runtime dependency.

## Manual Mapping Procedure

1. Pin the source revision and line-ending-normalized content digest as defined
   in PRODUCT_DISCOVERY.md. Preserve problem, hypothesis,
   product summary, scope, acceptance criteria, and success metrics in the six
   mandatory upstream sections. Supply required frontmatter from actual source
   information; request missing author/date information rather than inventing it.
2. Assign persistent upstream `AC-<number>` IDs to observable acceptance
   conditions, `SM-<number>` to post-launch measures, and `EVAL-<number>` only to
   explicit AI evaluations. Keep an explicit many-to-many mapping to Constitution
   requirement/criterion IDs; matching numeric suffixes imply no relationship.
3. Preserve FR/NFR classification, MUST/SHOULD/COULD/WON'T priority, supersession,
   and approval references in a documented custom section. These are not all
   native upstream fields. Mark unsupported semantics and missing mappings;
   do not claim a lossless round trip merely because parsing succeeds.
4. Preserve metric windows. Unknown targets stay provisional with a named owner;
   do not invent numbers. Upstream provisional metrics require `target_owner`.
5. Link evidence by item ID in Related Artifacts. A link is not proof that a
   test ran or an outcome occurred. Retain the reviewed spec revision on any
   downstream Agent Run; structural validity alone is not reconciliation.
6. Increment upstream `spec_revision` when meaning changes, keep durable IDs,
   and reassess approval/evidence. Do not silently retarget an old receipt.

Before implementing a converter, test many-to-many mappings, duplicate IDs,
removed/superseded criteria, unknown custom data, priority preservation, stale
revisions, and provisional targets against a pinned upstream validator. No
upstream CLI installation or network execution happens in our checker.

gstack's [office-hours at
82db89ab3ea3c64185538b8af33da2ffd1a18b57](https://github.com/garrytan/gstack/blob/82db89ab3ea3c64185538b8af33da2ffd1a18b57/office-hours/SKILL.md)
already provides product framing. It is an optional facilitator for contributors;
existing adopted agent configurations retain their enabled-tool conventions.
Compare with competent use of these tools before claiming differentiation.
