# Product Discovery Proposal

Status: Draft for discussion. Updated: 2026-11-02.

Implementation note: the optional repo-native workflow is now described in
[PRODUCT_DISCOVERY.md](PRODUCT_DISCOVERY.md). This proposal retains the product
hypotheses and pilot rationale; market validation and automatic ProductSpec
exchange remain future work.

## Opportunity

Help product managers and other non-technical contributors turn an initial
request into a clear, reviewable agreement about what to build and why.
The working hypothesis is that ambiguity at this handoff causes avoidable
engineering clarification and rework. The size of this opportunity and
willingness to pay remain unvalidated.

The Constitution already supplies requirement IDs, acceptance criteria,
traceability, tests, and delivery practices. Its current product requirements
template assumes the author can supply good requirements. A guided discovery
process would help the author reach that point.

## Relationship to Existing Tools

- [ProductSpec](https://github.com/gokulrajaram/ProductSpec) defines a portable
  product-intent format. Its [specification](https://github.com/gokulrajaram/ProductSpec/blob/main/SPEC.md)
  explicitly separates interoperability from quality judgment. Explore using
  that format for exchange rather than creating a competing serialization.
  It also already includes authoring guidance, generated handoffs, evidence
  links, revision checks, and Agent Run reconciliation; see its
  [Product Harness documentation](https://github.com/gokulrajaram/ProductSpec/blob/main/docs/product-harness.md).
  A generic spec-to-evidence loop therefore cannot establish differentiation.
- [gstack](https://github.com/garrytan/gstack) offers product-framing and review
  skills, including `/office-hours`. It remains an optional facilitator;
  contributors should be able to complete discovery without installing it.
  Its [office-hours workflow](https://github.com/garrytan/gstack/blob/main/office-hours/SKILL.md)
  already challenges product framing. Test whether our proposed facilitation
  improves on that existing experience for the chosen contributor group.
- The Constitution connects agreed intent to implementation and verification.
  The proposed addition is guided elicitation, evidence review, and a deliberate
  handoff into that existing process.

These are complementary roles, not evidence that the proposed offering is
unique. Compare real workflows before making differentiation claims.

## Proposed Contributor Experience

The contributor participates through conversation and a readable review surface;
no repository, command line, or Git setup is required in that path. A facilitator
can maintain Markdown artifacts underneath during the pilot. This is a proposed
experience, not an interface already provided by the framework.

1. Describe the request in ordinary language or supply an existing brief.
2. Answer a few focused questions at a time: who has the problem, what happens
   today, what evidence supports it, what outcome matters, and what constraints
   apply. Adapt questions to answers rather than requiring every field up front.
3. Review a synthesis separating supplied facts, assumptions, disagreements,
   and unanswered questions. Preserve source references and author attribution.
4. Compare alternatives, including doing nothing. Choose a small first scope,
   name exclusions, and describe normal, failure, and recovery behavior.
5. Review observable acceptance criteria and post-launch outcome measures.
   Explain technical terms in plain language; never fabricate customer research,
   metric baselines, approvals, or constraints to fill a blank.
6. Have a named product owner approve intent and an engineering reviewer assess
   feasibility and testability. Blocking unknowns keep the brief in draft.
7. Hand approved requirements to implementation with stable references. Link
   tests and delivery evidence back to them; changes to intent return to review.

For example, "let customers export reports" should prompt questions about the
customer, report, permission, file format, data volume, and failure behavior.
A possible criterion is: "An authorized user exports the filtered rows to CSV;
an unauthorized user receives no report data." That is an illustrative draft,
not an inferred customer decision; volume and performance remain open until
the owner supplies them.

## Smallest Useful Pilot

Initial segment hypothesis: a small software team where a product or operations
lead brings requests to an engineering lead, and both can participate in review.
The contributor is the person describing the need; the potential buyer is the
person accountable for delivery cost. These may be different people. Confirm
their actual roles, existing process, and purchase authority in interviews.

Start with a facilitated conversation and Markdown artifacts in one adopter
project. A dedicated application, hosted service, automatic ticket sync, and
mandatory new framework requirements are outside this first slice.

Produce a discovery brief, a reviewed requirements document, and the existing
traceability matrix. Demonstrate one request from initial ambiguity through
owner review, an engineering handoff, and linked test evidence. Use synthetic
or explicitly authorized material for a shareable walkthrough.

Before implementation, settle the following design details:

- Select one canonical intent document. If ProductSpec is adopted, define an
  explicit mapping between its acceptance IDs and existing `FR-`/`NFR-` IDs;
  preserve IDs through revisions and report unmapped items. Do not maintain two
  independently editable copies of the same requirements.
- Distinguish structural checks from human quality review. A valid document
  cannot certify customer evidence, feasibility, or approval.
- Define draft, review, approved, and superseded states, with owner, revision,
  and blocking-question handling. Approval must be an explicit human action.
  Track product intent approval, engineering readiness, test verification, and
  observed business outcomes separately. An approved spec does not validate
  demand; a `Verified` requirement does not establish product success.
  Classify unknowns as implementation blockers, owned time-bounded experiments,
  or provisional outcome measures; record an owner and revisit date. An
  experiment needs its own bounded scope and safety criteria before execution.
- Keep raw interview notes separate from shareable specs. Review sensitive
  business information before using external AI tools or publishing artifacts;
  treat imported notes as data, not executable agent instructions.

## Evaluation

Separate two experiments. A synthetic worked example tests the workflow and
explains the concept; it cannot establish customer demand. Real pilot requests
test usefulness and adoption, with permission from the participating team.

Recruit a small pilot cohort of product contributors and engineering reviewers.
For each request, retain the initial brief and compare it with the reviewed
handoff. Record participant count and limitations; a small pilot does not
establish market demand.

Compare similar requests handled through the team's current process and through
the proposed process. Record request complexity, reviewer experience, elapsed
time, and total contributor/reviewer effort. Where practical, have an uninvolved
engineering reviewer assess anonymized briefs without knowing their origin.
Use the same review rubric for both groups. Small or historical comparisons
remain directional evidence, not a causal claim.

Measure time to an accepted brief, engineering clarification rounds, unresolved
blocking questions at handoff, and requirement changes caused by ambiguity after
implementation starts. Separately ask whether contributors can explain and
correct the resulting spec and would use the process again. Establish baselines
and agree target improvements before running the pilot.
Use a teach-back check: without the facilitator interpreting the document, can
the contributor identify an assumption, correct a requirement, and explain an
exclusion? Record facilitator time explicitly alongside contributor and reviewer
time so a polished result does not hide an expensive service.

Include difficult cases: vague goals, contradictory stakeholders, missing
research, speculative metrics, permissions, and changed scope. Success includes
correctly keeping a brief in draft when evidence or decisions are missing.
Count every enrolled request, including rejected, abandoned, and not-ready
outcomes. Report these separately; do not improve time-to-approval figures by
silently excluding the hard cases. Record whether clarification exposed an
existing ambiguity or introduced a new one, since more questions can initially
reflect better discovery rather than worse performance.

Use a human review rubric with explicit evidence for each judgment:

| Review dimension | Ready for a scoped implementation when |
| --- | --- |
| Problem | A named user, current workflow, and pain are described; evidence and assumptions are distinguishable. |
| Scope | The smallest intended outcome and exclusions are clear; conflicting requests have an accountable decision owner. |
| Behavior | Normal, failure, recovery, and relevant permission boundaries have observable criteria. |
| Feasibility | An engineering reviewer has assessed the slice and recorded unresolved risks. |
| Outcomes | Measures have an owner and observation window; unknown baselines or targets stay explicitly provisional. |
| Authority | Product approval references the reviewed revision; blocking questions have been resolved or explicitly deferred outside the slice. |

Do not collapse this rubric into an automatic quality score. A failed dimension
can mean more discovery, a smaller scope, an engineering investigation, or a
decision not to build. Approval applies to the scoped work, not every future
question. Changed scope or acceptance criteria require review of the affected
revision; passing tests alone do not prove a business outcome.

Before recruitment, agree a minimum useful improvement and a maximum acceptable
review burden with the team. Continue only if clarity improves without shifting
unacceptable effort onto contributors and reviewers, and participants elect to
use the process on another real request. Revise or stop if existing tools perform
as well, facilitation is too costly, or the main problem is decision authority
or missing research rather than requirements authoring. Record actual repeat
use and buyer commitment separately from compliments about the demo.

## Discussion Decisions

For the next pitch discussion, Monday, November 9, 2026:

- Choose the first contributor and buyer hypotheses and a real pilot request.
- Decide whether the initial offering is a facilitated service, a reusable
  workflow, or a product; test this with participants before committing to a UI.
- Agree the demo story, pilot measures, and division of product and engineering
  review responsibilities.
  The walkthrough should expose a stakeholder disagreement, show the owner's
  resolution, and follow a later scope revision through affected requirements
  and tests needing reassessment. Those flags can be demonstrated manually;
  describe automation only when it exists.
- Identify alternatives participants already use and the evidence needed to
  support a differentiated pitch.

## Implementation Sequence

1. Test the interview and review rubric manually against one realistic request.
2. Draft an optional discovery guide and a completed sample; exercise both with
   a non-technical contributor and an engineering reviewer.
3. Prototype ProductSpec exchange against a reviewed, pinned upstream version.
   Test missing IDs, revisions, conflicting requirements, and lossless mappings.
4. Propose an ADR before changing required workflow, checker contracts, or
   compatibility policy. Update integration guidance, templates, sample project,
   and demo together when the capability actually ships.

The proposal itself does not change required adopter workflow. The optional
implementation adds a discovery skill and structural checker; no automatic
ProductSpec integration or market-demand claim is made.
