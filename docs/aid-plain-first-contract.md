# Plain-first AID: initial contract and reuse inventory

**Status:** working prototype contract, not a released default. The trial files
live under `experiments/aid-plain-first/`, outside the normal release payload;
their presence does not install or activate the prototype. The approved
direction is in [the redesign plan](aid-plain-first-redesign-plan.md). This
document records implementation choices for an opt-in trial; it does not retire
existing workflows or approve a change to severity levels or grade thresholds.

## Contract

An agent first identifies the goal, relevant facts and material uncertainties.
It records the user's intention in one current `REQUIREMENTS.md` for that work:
goal, scope, constraints, observable outcomes and relevant source references.
It may be brief for a clear fix. Assumptions are attributed; material ambiguity
is resolved with the user. The user can change the intention and the same
document is updated without silently discarding prior decisions.

The candidate uses the existing `.aid/works/<work>/REQUIREMENTS.md` convention
and valid active state when a related work record already exists. The opt-in
trial reuses the existing allocation gate and direct-state initializer for new
work; an explicit initiator records `aid-outcome` before state publication. The
initializer and exclusive requirements creation have been exercised in a
disposable installed project, but an actual host has not yet followed the full
allocation and resume route.
If multiple existing documents disagree about the user's intent, preserve them
and ask which is authoritative. The prototype does not automatically migrate,
merge or overwrite existing requirements, or claim that a plain Markdown file
provides atomic concurrent editing. Before an edit, check the version read;
if another writer changed it, stop and reconcile instead of overwriting it.

The executor uses its usual tools and reads the relevant project card and KB
facts, checking sources when needed. It performs appropriate checks and a
self-review. A separate reviewer then inspects the actual result against the
requirements, relevant project knowledge and source evidence. The reviewer
traces every outcome to evidence and classifies it verified, failed or
unverified; missing evidence is unverified, not a pass. Completeness is
measured against the defined full scope, not a few sampled pages. Correctness
includes testability; maintainability covers clarity and ease of change;
rendered usability is checked where applicable. The reviewer records supported
findings and uses the existing grading rubric and ledger; a grade does not
replace the outcome trace. If independence or required evidence is unavailable,
the user sees the limitation and the result is not called verified.

The prototype keeps existing authorization and host-safeguard boundaries. A
host hook is only a proven protection where its actual loading, trust and
coverage have been tested. It is not an agent execution replacement or a claim
that every indirect command is intercepted.

## Reuse inventory

| Capability and owner | Initial decision | Evidence and compatibility concern |
| --- | --- | --- |
| KB discovery: `canonical/skills/aid-discover/` and `canonical/aid/templates/knowledge-base/` | Reuse; adapt the entry/handoff only when needed. | Existing KB artifacts and indexing are consumed by `.aid/knowledge/`; stale facts need source checks. |
| KB updates: `canonical/skills/aid-update-kb/`, `aid-housekeep/` and KB scripts | Reuse existing tools; decide what updates need confirmation. | Preserve unrelated knowledge and existing user decisions; test affected-fact and conflict handling. |
| Requirements: `canonical/skills/aid-describe/` and work `REQUIREMENTS.md` | Reuse the existing document convention; prototype a concise path. | Existing work may have approved requirements and dependent features; never replace or silently re-scope it. |
| Verification: `canonical/skills/aid-review/` and `aid-change/references/review.md` | Adapt the independent-review guidance, without replacing the host executor. | Tests and changed lines alone do not establish whole-result coverage or rendered quality. |
| Grade: `canonical/aid/templates/grading-rubric.md`, reviewer ledger and `canonical/aid/scripts/grade.sh` | Reuse unchanged for the trial. | Existing letter mapping, status parsing, thresholds and consumers must remain compatible. Severity calibration is a separate decision. |
| Host protections: `canonical/aid/scripts/change/*safeguard*` and configuration | Retain; make only tested host-specific claims. | Preserve user's configuration and actual trust requirements; no push or merge without authorization. |
| Install and readers: `release.sh`, `bin/aid`, profiles, dashboard readers | Reuse the existing distribution and readers; prototype remains opt-in. | Existing installed work must continue to load. Generated mirrors are not canonical. |
| Baselines: `canonical/aid/scripts/change/checks.py` | Keep existing implementation, do not require it for every task or optimize it by assumption. | Large dependency-tree cost and installed resync remain unverified. A missing baseline is disclosed. |

## Examples and evidence routes

1. **Small fix:** one brief requirements document names the failure, expected
   behavior and preserved behavior. A reproduction and a passing regression
   check support the outcome; an independent reviewer inspects the result.
2. **Ambiguous feature:** ideation identifies plausible choices; the user
   decides the materially different intent. The same requirements document
   records that decision, outcome criteria and checks, then is updated if the
   user changes scope.
3. **Comprehensive site rewrite:** define the full relevant topic and workflow
   universe and intentional exclusions. Map every item to sourced page content;
   inspect rendered views and controls. Sampled visual inspection is not proof
   of complete content or site-wide accessibility.
4. **Continuation:** locate the genuinely related existing requirements and
   read its decisions and current evidence. Preserve it and its history. If
   authority or concurrent changes are unclear, stop for reconciliation rather
   than creating a competing source or losing edits.

## Verification boundaries and open decisions

The existing severity meanings, `grade.sh` mapping and thresholds are unchanged.
The [proposed calibration examples](aid-plain-first-redesign-plan.md) need
maintainer and reviewer agreement before any rubric change. A structural
outcome-coverage check can catch missing or malformed records; it cannot prove
that cited evidence is true or that an independent agent actually reviewed it.
Those claims require inspection or an actual run.

Open design decisions remain: the new-work allocation mechanism and concurrent
writer support, how much KB maintenance is automatic, host-specific execution
and reviewer separation, calibrated severity definitions and thresholds, and
the acceptable cost of observed benefits. These are not silently decided by
the prototype. Existing artifacts and workflows remain available for rollback.

The updated shared work-initiation gate directs running `aid-outcome` work to
the opt-in entry when available and otherwise stops; other direct work retains
the `aid-change` route. The experimental entry is not installed by ordinary
releases. A reversible, explicit trial installer and offline fixtures exercise
the state and document helpers. One Codex host diagnostic read the installed
entry, selected the outcome route and preserved the requirements. Its fixture
had no KB, and its event stream did not establish hook execution. Broader live
acceptance, KB use and host safeguard enforcement remain unverified.
