# Plan: Reshape AID around plain-agent execution

**Status: proposal for review.** This document describes the intended redesign and a path to test it. It does not approve implementation, replace the currently installed methodology, or claim a quality or cost advantage. The maintainer's direction is to reuse working AID capabilities, particularly KB generation and grading, and change only what is needed for the new approach.

## 1. Goal and boundaries

Make AID a small layer that addresses the weaknesses observed in plain agent work, while leaving the coding agent free to use its own tools, reasoning and normal execution workflow. The layer has three responsibilities:

1. **Project knowledge:** generate, use and maintain a trustworthy, navigable knowledge base (KB) about the project.
2. **Work intention:** ensure ideation happens and one requirements document records what this particular work is meant to achieve.
3. **Whole-result verification:** independently check the result against both sources, the actual implementation and the available evidence, with emphasis on completeness, correctness and testability, and maintainability.

The user remains responsible for decisions that belong to them. The agent executes the work; AID supplies focused context and checks outcomes. The intended end state is **AID itself reshaped around these three responsibilities and plain-agent execution**, not a permanent additional experimental lane beside an unchanged AID. AID should not require its existing sequence of phases, a large family of workflow skills, a prescribed implementation method, or multiple approval pauses for ordinary work. This is a target design, not a statement that current AID already behaves this way.

**Do not trade away:** preservation of unrelated work; authorization before push, merge, deployment or other externally consequential action; honest reporting of failed or missing evidence; an independently performed whole-result review; and platform-specific safeguards where they are actually supported. Do not imply that an instruction alone can enforce a host-level restriction.

## 2. Evidence and uncertainties

The current lean audit records a fix pair and a complex pair where both plain and lean passed their hidden checks, but the lean runs reported substantially more input and took longer. These are small samples, not a measurement of each AID component's contribution. The site runs used different models or environments, and the later two-page lean test had no matched plain control and did not finish final review. The saved site evidence includes both an independently caught incorrect example and failures to detect visible Markdown artifacts or complete instructional coverage. This supports investigating knowledge transfer and whole-result checks; it does **not** establish that plain agents always miss these problems or that a new AID layer will fix them.

Existing `aid-change` supplies targeted KB reading, direct/planned lanes, tests, a separate review and host-specific safeguards. `aid-discover`, `aid-update-kb` and `aid-housekeep` provide current knowledge workflows. They also embody substantial process and state machinery. The new design must inventory those capabilities and their consumers before changing or retiring any of them. The recently changed baseline helper has focused tests but its original large site dependency tree and installed resync remain unverified; do not assume that helper is a necessary part of the new design or optimize it by default.

The maintainer considers existing KB generation useful and wants to retain the grading system. Treat both as starting assets, not candidates for replacement by default. Their use in the new workflow still needs integration and compatibility testing; the maintainer's assessment is not proof that every KB output is current or complete. Review the present grading criteria for suitability before proposing a change; do not silently replace the scale or its existing consumers.

Evidence: [lean design and cost audit](aid-lean-design-cost-audit.md), [architecture ledger](aid-evolution-ledger.md), [current change skill](../canonical/skills/aid-change/SKILL.md), [change review guidance](../canonical/skills/aid-change/references/review.md), and [project card](../.aid/knowledge/PROJECT.md). These describe current evidence and mechanisms, not the final design's measured results.

## 3. Proposed user interaction

1. The user describes a task in ordinary language. The agent uses its normal host workflow and tools.
2. Before implementation, the agent performs **ideation**: identify the outcome, relevant project facts, constraints, and meaningful uncertainties; consider an alternative when a genuine design choice exists. For a small clear change this can be a concise working note; for an open-ended change it can be a discussion with options and consequences. Ask the user when a decision materially changes the intended result or needs their authorization. Do not invent a decision or demand a question merely to satisfy a ritual.
3. Record the agreed or user-specified intention in **one** requirements document for the work. For a small task it may contain a short goal and observable outcomes; for a larger task it may include scope, exclusions, examples, quality expectations and constraints. An agent may propose reasonable implementation details, but must identify assumptions as assumptions. No separate mandatory goal card, specification, acceptance plan and duplicated requirements are needed merely to start work.
4. Execute in plain mode. The agent chooses normal tools and implementation steps. It reads relevant KB entries and checks their source when needed, keeps the requirements current when the user changes the intention, and does not treat AID as a replacement execution engine.
5. The executor runs appropriate checks and analyzes its own result against the requirements before handing off a bounded evidence bundle. A separate reviewer then evaluates the **whole result**, not just the changed lines or test count. The executor addresses substantiated findings and obtains review of the corrections. If review or required evidence is unavailable, report the work as unverified rather than claiming success.
6. Present the result, the verified outcomes, meaningful limitations and any decision actually required. Keep the user's existing approval boundaries; do not manufacture an extra final approval for a routine, already authorized change.

The requirements file is the authoritative record of the **intended work**, not a replacement for the conversation or a claim that unapproved assumptions are user decisions. Its location and lifecycle must be selected during compatibility design. An in-progress work must have exactly one current requirements document; checklists, review results and evidence may reference it, but must not independently redefine the same requirements. A concise change note in that document records scope changes and their authority. Concurrent edits must not silently overwrite another person's requirements.

## 4. Project knowledge: generation, retrieval and maintenance

### What the KB contains

Keep a compact project card plus discoverable, focused documents covering architecture, components, relevant interfaces, build and test commands, constraints, conventions and important decisions. Facts should cite durable source locations such as files and symbols, with observed version or revision where useful. Record what was inspected and what remains unknown; never fill a gap with an unsupported claim.

The KB is the project's maintained knowledge reference. It is not automatically correct: source code, configuration and tests are primary evidence of **current implemented behavior**; the requirements document records **desired behavior for this work**; explicit user decisions and applicable project policies govern intent and constraints. When they disagree, show the conflict and investigate. Tests can themselves be incomplete or wrong; do not automatically treat a green test, an old comment, or a KB page as proof of the whole truth. External contracts and policy decisions need their own cited authorities.

### Generate and use

- Start with the existing `aid-discover` generation, KB templates and indexing scripts. Inventory their inputs, outputs and tests; keep their working behavior and existing knowledge formats. Adapt the entry and handoff to plain-agent execution only where necessary. Propose a replacement only for a specific evidenced gap that cannot reasonably be addressed by an adaptation.
- For an existing project, discover sources, generate an index and card, and summarize evidenced facts and gaps. For an empty project, create only facts that are known and mark the rest unknown. Preserve existing KB content until a supported replacement has been reviewed.
- At task start, use the project card and targeted retrieval to select a small set of facts relevant to the requirements. Return citations and conflicts, not a full KB dump. Record which facts influenced the work and its checks.
- Include source-verification triggers: a changed implementation or source revision, contradictory evidence, or missing/unclear citations requires reinspection. A stale or missing KB entry is not permission to guess or block all ordinary work automatically; disclose the gap and read the source.

### Maintain

After implementation, detect which accepted changes affect KB facts and prepare a scoped update with references to the changed source. Distinguish mechanical source-backed updates from interpretation or policy changes that require the user's decision. Review the proposed KB delta, preserve unrelated knowledge and record conflicts or unfinished updates. Verify links, source references and the affected facts; the KB should not become a transcript or duplicate the work requirements. Define when updates occur and who authorizes them in the design and migration phases, rather than assuming the old two-confirmation process is necessary.

## 5. Work requirements: a single source for the task

The requirements document needs, at minimum:

- the user's goal and the problem or user need;
- scope and any explicit exclusions or constraints;
- observable outcomes, including behavior to preserve or intentionally remove;
- the relevant KB facts or authoritative sources and any conflicts or open questions;
- criteria for correctness, completeness, testability, maintainability and, where applicable, user experience;
- decisions, assumptions and changes, attributed to the user or agent as appropriate.

The format scales with risk and ambiguity. An outcome must be specific enough to verify; it need not prescribe implementation. Before work begins, resolve material ambiguity with the user. Record a changed request in the same document and update affected outcome criteria; do not silently re-scope, create a second competing requirements file, or turn an implementation suggestion into an approved requirement.

For example, a straightforward defect might use a few lines: the reported failure, the desired behavior, the behavior to preserve, the relevant source link, and a reproducible before/after check. Ideation can note that the cause has two plausible locations and which source evidence resolved it. A site rewrite would need a fuller scope and content inventory, intended audiences, topic depth, source citations, navigation and visual requirements, and a way to verify both coverage and rendered use. Both remain **one** current requirements document for their respective work.

For work requiring comprehensive coverage, explicitly define the universe to cover: for example, the set of existing user-facing workflows, pages, skill concepts, or source topics relevant to the requested site. Record exclusions and the reason for each. A few representative pages may be useful diagnostics, but they cannot demonstrate **all** content is present. If the source set or its completeness cannot be established, the result must state that limitation.

## 6. Independent whole-result verification

The executor performs a self-check first, then gives a separate reviewer the original request, current requirements, relevant KB/source facts, changed result, checks and known gaps. The reviewer is independently assigned and must be able to inspect the actual result and run or examine evidence, not just trust the executor's summary. Provide focused evidence with pointers for further inspection; a bounded handoff must not hide relevant source or prevent investigation. If a separate reviewer cannot run, report the missing independence and leave the result unverified; do not label the executor's self-check independent.

Build a trace from every required outcome and relevant project constraint to result locations and evidence. Independently examine changes and important unchanged paths affected by them. Classify each outcome as **verified**, **failed** or **unverified**, with reasons and evidence. Check missing requirements, regressions, incorrect claims, unsupported assumptions, intentionally removed behavior, newly introduced behavior and unresolved conflicts. A single green test count, link list or empty finding list is not proof of a complete outcome.

| Dimension | Review question | Evidence suited to the result |
| --- | --- | --- |
| Completeness | Is every required outcome present, with the requested depth and relevant preserved behavior? | Requirement-to-result map, inventory of the defined source/topic universe, comparison with prior user needs and positive cases that reject plausible omissions. Identify uncovered items. |
| Correctness and testability | Does the result accurately represent the authoritative facts and behave as intended, without invented claims? Can people and agents test its important behavior? | Source citations, executable checks and expected outputs, positive and negative cases, error handling, baseline comparison when trustworthy, and disclosures for unavailable or pre-existing failures. Tests are evidence, not a substitute for the requirement. |
| Maintainability | Is the result clean, simple and reasonably easy for humans and agents to understand and change? | Inspect naming, boundaries, duplication, complexity, interfaces, operational documentation and representative change scenarios. State concrete observations; do not claim objective maintainability from a single score. |
| User experience, when applicable | Is the result visually coherent, usable and accessible, with understandable controls? | Inspect the actual rendered result, representative desktop and mobile views, keyboard behavior and interaction states; pair automated checks with human/agent inspection. Mark unchecked pages or accessibility dimensions as unverified. |

For a site, verify both what the pages say and what readers see. Map the agreed complete topic universe to page content and cited sources, then inspect rendered formatting, navigation and interactive controls. Screenshots and representative page checks alone cannot prove site-wide content completeness; automation can help locate gaps but requires semantic review. Correctness means no unsupported or misleading representation; uncheckable claims stay unverified. For nonvisual work, choose equally concrete evidence appropriate to its behavior.

Review findings cite a requirement, source fact, failing check or demonstrable maintainability problem; distinguish findings from preferences. After fixes, recheck the findings and affected evidence. Do not silently accept an unresolved failure, hide unexpected writes, reduce assertions, or infer success from an incomplete run. Preserve the user's choice of whether to accept a documented limitation; never silently waive a required result.

### Retain grading; calibrate severity for outcomes

Keep the existing five finding levels and letter-grade mechanism as the starting point. The current [grading rubric](../canonical/aid/templates/grading-rubric.md) defines their meanings and maps the worst open severity and its count to a letter; [grade.sh](../canonical/aid/scripts/grade.sh) reads the existing seven-column reviewer ledger and counts Pending and Recurred findings. Preserve those interfaces, status semantics, configured thresholds and historical ledgers unless a specific change is separately justified, reviewed and approved. Retaining the scale does not mean keeping every current severity assignment unchanged.

Review and calibrate how findings are classified against the user's outcomes. Base a proposed severity on the actual consequence, scope and likelihood of harm or failure, whether a core requirement is affected, and the strength of evidence. Assess completeness, factual correctness, testability, maintainability and applicable usability in context; avoid treating every missing detail as cosmetic or every style preference as a serious defect. Write concrete code and content examples for each level, including a missing core workflow, a false instructional claim, inadequate tests, a maintainability problem and a visual or interaction defect. Calibrate those examples with the maintainer and reviewers before changing the canonical rubric or criteria overrides. This plan does not assign final severity thresholds or redefine grades.

Illustrative cases for that calibration, not a replacement rubric:

| Level | Example to discuss | What makes the consequence matter |
| --- | --- | --- |
| Critical | An operation irreversibly destroys user data or exposes secrets. | Severe, broad or irreversible harm. |
| High | A required primary workflow cannot be completed, or instructions produce a dangerous result. | A core outcome is blocked or users face significant harm. |
| Medium | A required workflow omits an important case, or a misleading explanation causes a recoverable failure. | A meaningful part of the intended result is incorrect or incomplete. |
| Low | An isolated defect makes a nonessential task harder, but a clear workaround exists. | Limited impact on a smaller part of the result. |
| Minor | An inconsistent label or visual detail causes no meaningful loss of use. | Cosmetic impact without material functional or comprehension harm. |

The same symptom may warrant a different level in a different context: for example, missing tests are more consequential when they leave critical behavior impossible to verify, and a visual defect can be serious if it hides required information. Assess evidence and impact rather than applying the example labels mechanically.

Keep **verification coverage separate from the letter grade**. An empty ledger or an A+ from the existing grader says no countable open findings were recorded; it does not establish that all requirements were inspected or that the result works. Present each required outcome as verified, failed or unverified, disclose missing evidence and nonfunctional results, and never present a grade alone as proof of completion. Test the existing nonfunctional-grade path as well as severity/status counting. Any changes to severity definitions, grade mapping, thresholds or user-visible interpretation need explicit compatibility analysis and a maintainer decision; preserve old evidence and explain how old and new grades compare.

## 7. Lightweight technical shape and safeguards

**Candidate shape, to validate before committing to file names or interfaces:**

| Part | Responsibility | Cost boundary |
| --- | --- | --- |
| Short entry instruction | Invoke ideation and the requirements/KB/result loop; leave execution to the host agent. | Small always-loaded context; retrieve deeper guidance only when relevant. |
| KB service or files | Discover, index, retrieve cited facts and prepare scoped maintenance. | Targeted reads; do not inject the whole KB on every turn. |
| Work record | One current requirements document and a compact pointer to status/evidence. | No parallel documents that re-state intent or duplicate tracking. |
| Verification capability | Independent whole-result evaluation using task-specific evidence and an explicit coverage map. | Match review depth to risk; never omit required evidence to meet a budget. |
| Minimal host adapter | Integrate with actual host instructions and supported tools without replacing the agent's execution engine. | Observe actual enforcement and configuration; no claims beyond tested hosts. |

Retain no-push/no-merge and other user-approved safety boundaries. Where a host hook is used, test that the intended host actually loads and trusts the exact configuration and that the relevant direct commands are blocked; disclose coverage limitations such as aliases, indirect commands and unverified platforms. Preserve user hook configuration and do not install or trust new hooks without the authorization required for the target. Avoid duplicating checks in multiple layers when evidence shows equivalent protection, but do not remove a protection merely because a simpler one is proposed.

The current repository's canonical sources under `canonical/` render into profiles, release payloads and installed trees; changes to installed mirrors alone will not ship. Map each candidate responsibility to its source, renderer, CLI/installer, host configuration, tests and documentation before editing. Assess Bash/PowerShell and host compatibility from the existing contract. Keep the architecture ledger current as implementation changes occur, clearly separating proposed, implemented, verified and released work.

### Initial repository impact map

This is a starting inventory, not a decision to delete or rewrite each listed component:

| Area | Inspect and decide | Existing verification starting points |
| --- | --- | --- |
| Entry and work intent | `canonical/skills/aid-change/`, `canonical/skills/aid-describe/`, `canonical/aid/templates/work-initiation-gate.md`, and the current work-state writer. Select a single requirements home and a minimal host entry; identify dependencies before retiring phases. | `tests/canonical/test_lean_change.py`; work-initiation and state-reader tests. Add explicit single-source, change and resume cases. |
| Project knowledge | `canonical/skills/aid-discover/`, `canonical/skills/aid-update-kb/`, `canonical/skills/aid-housekeep/`, `canonical/aid/templates/knowledge-base/` and KB scripts. Decide which discovery and update mechanisms remain useful without their present orchestration. | Existing KB freshness, citation, update-scope and housekeep safety suites; add stale/conflicting-source and affected-fact cases. |
| Whole-result verification | `canonical/skills/aid-change/references/review.md`, `canonical/skills/aid-review/` and existing reviewer contracts. Design a short independent reviewer input and coverage/evidence record that works for code and rendered content. | Existing lean change tests and `tests/measure/hidden/`; add missing-outcome, wrong-claim, testability, maintainability and unavailable-review cases. |
| Grading | Reuse `canonical/aid/templates/grading-rubric.md`, `canonical/aid/templates/reviewer-ledger-schema.md` and `canonical/aid/scripts/grade.sh`; inspect criterion severity overrides and grade consumers before any calibration. | Existing grading and ledger tests; add calibrated examples, status and threshold compatibility, nonfunctional results and unverified-coverage cases. |
| Safeguards and hosts | `canonical/aid/scripts/change/safeguard.py`, `codex_safeguard.py`, their host configuration, and existing user-managed hooks. Preserve actual tested protections and user settings during the trial and migration. | Existing safeguard and host tests; native enforcement must be demonstrated per supported host and fixture. |
| Installation and readers | `bin/aid`, `lib/`, release/profile generation, package wrappers, `dashboard/reader/` and both supported shell families. Trace how existing work and KB formats are consumed. | Installer/update, render-drift, Bash/PowerShell parity, dashboard state-reader and rollback tests, selected by impacted paths. |
| Outcome and cost evaluation | `tests/measure/measure.py`, `tests/measure/quality_probe.py`, site graders and recorded experiment evidence. Extend or replace only where the new protocol needs stronger outcome, usage or isolation evidence. | Existing measurement/usage-accounting tests and new evaluator/oracle tests; preserve incomplete historical runs. |

## 8. Compatibility and transition

1. **Reuse and inventory first.** Map existing skills, commands, hooks, work states, KB generation and update tools, grading, settings, integrations, generated artifacts and tests to user needs. Preserve existing KB generation and grading as the default direction. Identify external consumers and the existing state of installed projects; propose adaptation or removal only for a supported need, with migration and rollback.
2. **Add the new path alongside the current one.** Provide an explicit opt-in trial with separate fixtures and reversible installation. Existing users, ongoing work, KBs and integrations continue to function. No destructive migrations or silent replacement of a user's selected workflow.
3. **Test mixed and resumed work.** Define how existing requirements and state are read, how a continuation chooses its single current requirements source, and how it handles conflicts without silently overwriting decisions. Preserve history and unrelated files. If migration cannot identify the authoritative intent, ask the user; retain originals and make a recoverable copy before transforming anything.
4. **Decide what to retain or retire.** Compare the new path to plain agents and, where useful, current lean AID. For each legacy capability, explicitly decide whether its user value is incorporated into the new default, retained as an optional compatibility capability, replaced, or retired. Record the preserved value, affected users, migration and rollback. Do not remove a capability prematurely or silently; obtain any decision required for a breaking change. Review discover, KB maintenance, review, host safeguards and installer commands, not just skill counts.
5. **Make the redesigned AID the intended default through a deliberate rollout.** After its acceptance criteria and the required transition decisions are met, regenerate and verify profiles and packages from canonical sources; check fresh installs, updates and existing installs in supported hosts. Migrate supported users with a documented rollback path and reviewed guidance. A temporary side-by-side trial is a migration method, not the end state. No publish, push or merge without the relevant authorization.

## 9. Implementation sequence and acceptance checks

These are engineering milestones, not mandatory phases for every future AID user. Each produces a reviewable result before the next; work can be adjusted when evidence contradicts a hypothesis.

### Milestone A — Define the contract and inventory

- Translate this proposal and the user's decision into concrete product requirements, examples and boundaries. Identify existing code, KB generation and maintenance, grading, skills, installers, hooks, tests and compatibility dependencies; classify each as reuse unchanged, adapt, candidate for later removal, or unknown, with evidence and reasons. Start by retaining the working KB and grading mechanisms.
- Design the one-document model and concurrent edit/change provenance; identify how it works with existing work records and what to do when old artifacts disagree. Specify KB authority and update behavior, evidence/coverage mapping, reviewer independence, unavailable tools and approval boundaries.
- **Acceptance:** examples cover a small clear fix, an ambiguous feature, a comprehensive site rewrite and a continuation of existing work. They demonstrate that the agent remains free to work normally, ideation and one requirements source exist, and every required outcome has a verification route. The inventory has owners, impacted paths, migration risks and unresolved decisions; it does not assert unsupported retirements.

### Milestone B — Prototype the three responsibilities

- Implement the smallest opt-in entry instruction and requirements artifact; connect existing KB generation and retrieval; adapt existing reviewer and grading components for a focused independent whole-result review with explicit evidence and coverage statuses. Keep existing safeguards and compatibility boundaries. Do not rewrite a working component without an evidenced reason.
- Add deterministic tests for small and large requirement sizing, a change in scope, correct attribution of user decisions, stale/missing KB facts, real source conflicts, preservation of unrelated files, and resume without duplicate requirements. Test reviewer separation, unavailable reviewer, missing checks, failed tests and unsupported claims; ensure those cases do not become a pass.
- Test the existing KB generator on a representative project and verify that new integration preserves its artifacts and behavior. Test severity calibration with representative completeness, correctness, testability and maintainability findings; verify ledger parsing, existing letter mapping and thresholds remain compatible unless an authorized change explicitly updates them. An unverified outcome must never become a verified result merely because the ledger grades A+.
- **Acceptance:** the artifact and checks work without invoking the old phase pipeline; the executor's self-check precedes the independent review; a review catches seeded omissions and false claims; a real or faithful fixture produces traceable evidence. No tool result or agent instruction is represented as stronger enforcement than the host actually provides.

### Milestone C — Verify real outcomes and interoperability

- Exercise the candidate in disposable representative projects, including a documentation/site task with a known topic inventory, render and interaction checks. Compare the output to sources, requirements and prior user needs. Also test a small code fix and a multi-file feature where maintainability and failure behavior matter.
- Verify existing projects and supported hosts: fresh install, opt-in update, resumption, KB refresh, safety hooks, preserved user edits and rollback. Run applicable project checks; disclose platform skips, missing tools, historical failures and what was not exercised.
- **Acceptance:** each test has an explicit result, source revision, evidence and limitations. Site completeness is only claimed against the defined full source/topic universe; representative visual inspections remain identified as sampled. A missing browser or independent reviewer cannot become a pass. The architecture ledger explains the changes and status.

### Milestone D — Measure the value and decide

- Before running models, define task requests, source snapshots, evidence requirements, evaluator isolation, budgets and success thresholds with the user. Start with one small matched pair as a diagnostic and inspect it before spending on a wider study. A single pair cannot establish a general advantage.
- For the pair, use the same host/model, starting project, request, tool availability, permissions and limits for plain and new-AID arms; allow both access to the same project files and KB if present. Only the treatment instructions/integration should differ. Record any unavoidable differences. Do not coach one arm with the evaluator or silently discard failures.
- Use an evaluator independent of both executors, blinded to the arm when feasible, with a predeclared oracle checked against source. Compare completeness, correctness, testability, maintainability and applicable UX separately; include seeded omissions and plausible regressions where appropriate. Preserve the raw evidence and report disagreements or unverified criteria. A diagnostic fixture should test intended outcomes, not reward the presence of AID artifacts alone.
- Capture main and helper usage, cached and uncached input when reported, output tokens, wall time, setup and safeguard cost separately, completion and reported monetary cost if available. Do not sum overlapping counters or infer dollars from tokens. Report failed, timed-out and incomplete runs.
- **Decision:** retain, revise or remove individual components according to demonstrated benefit versus incremental cost and safety impact, while pursuing the user's chosen plain-agent redesign. Agree quantitative thresholds before the broader study; if evidence is too small or incomplete, report inconclusive and identify the next targeted refinement. Update the architecture ledger and recommend the concrete rollout or further investigation. Do not claim universal improvement from one task.

## 10. Risks and design questions

| Risk or open question | How to address it before claiming the redesign works |
| --- | --- |
| KB is stale, incomplete or overconfident | Cite source, test drift/conflict handling, expose uninspected areas and review maintenance proposals. |
| A useful working component is needlessly rewritten | Start with existing KB generation and grading, measure or demonstrate a specific gap before changing them, and test old consumers and outputs. |
| A grade hides incomplete verification or inconsistent severity | Show outcome coverage independently; calibrate representative findings and preserve current scale and consumers until a reviewed decision changes them. |
| One requirements file becomes boilerplate or gets out of date | Keep it right-sized, test a real user change and resume, and maintain one clearly authoritative current document. |
| Ideation becomes a mandatory interview | Use a brief note for clear tasks and ask only when a decision matters; test both simple and ambiguous examples. |
| Reviewer rubber-stamps or lacks independence | Give the reviewer direct access to the result and targeted evidence, use seeded failure cases, and report unavailable independence. |
| Exhaustive completeness is assumed from a sample | Define the source/topic universe, trace outcomes across it and distinguish full semantic review from sampled visual inspection. |
| Checks are cheap but shallow, or thorough but too expensive | Define a risk-based evidence selection policy, measure review and setup costs separately, and leave required but unavailable checks unverified. |
| Host enforcement or hooks are overstated | Test each supported host and exact trust boundary; keep unsupported enforcement explicit. |
| Existing users lose working behavior or state | Use opt-in parallel operation, inventory integrations and old artifacts, test migration/resume and keep rollback before considering retirement. |
| Tests and evaluators reward the method instead of the result | Use independent outcome-based criteria, equal task/tool access and predeclared adversarial cases. |
| Requirements conflict with KB, code or policy | Expose the conflict and its sources; obtain the user's decision where intent is unclear and do not quietly revise either source. |

**Open decisions:** the stable requirements location and schema; how much KB maintenance is automatic; which review checks are mandatory at each risk level; how host-independent reviewer separation is supplied; the calibrated severity examples and any justified changes to grade interpretation or thresholds; which other legacy capabilities remain default; and the acceptable incremental cost for a demonstrated benefit. Keep existing KB generation and grading as the starting point while resolving these decisions from the contract, prototypes and measured evidence.
