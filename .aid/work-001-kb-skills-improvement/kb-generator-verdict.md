# Judge's verdict — can `/aid-discover` generate work-actionable KBs for ANY project type? — 2026-06-25

Second comparison round, reframed from "is the AID KB good" to **"is the new `/aid-discover`
a generator of work-guiding KBs for any domain?"** — old skill code (`master`) vs new (HEAD),
3 critics (advocate/adversary/neutral) + judge. The adversary and neutral *ran* the depth-safeguard
against synthesized non-software doc-sets; I independently confirmed the two load-bearing facts.

## Headline

**Architecturally yes; operationally only for 2 of 8 domains today.** The new generator crossed
from "software-only" to "any-domain *capable*" — a real, regression-free advance — and added an
operational-sufficiency gate the old one entirely lacked. But its **breadth layer is finished while
its depth layer and depth-safeguard were only authored for the two domains AID dogfooded**
(software-cli/web + methodology-tooling). For data-ml / content / research / design / ops it produces
an **oriented, coverage-complete, but depth-unverified** KB: a good *map*, with no machinery that
forces — or even checks — that it reaches a work-actionable *manual*.

## The three-layer model (the precise finding — all VERIFIED)

| Layer | Maturity | Evidence |
|---|---|---|
| **1. Breadth — which docs per domain** | **DONE, domain-general** | 11-dim spine (arc42/C4/ISO-42010-grounded) + 8-domain matrix + research-fallback + hybrid composition + coverage invariant. Non-software rows are substantive (data-ml→data-pipeline/data-schemas/model-cards/evaluation-landscape; design→design-system/tokens/accessibility-landscape). OLD literally could not produce non-software (fixed 15-software-doc seed). |
| **2. Depth — per-doc extraction contract** | **SOFTWARE + METHODOLOGY ONLY** | `document-expectations.md` has entries for ~24 docs (17 software + 7 methodology-tooling). The ~30 non-software filenames the matrix can emit have **0** entries (I confirmed: data-schemas/data-pipeline/model-cards/design-tokens/content-model/methodology/evaluation-landscape all = 0). The custom-doc prompt tells the agent "produce X per its `### X` expectations entry" — **a dangling anchor**; the doc falls back to the generic spine question only. |
| **3. Safeguard — act-back operational-sufficiency keystone** | **SOFTWARE-KEYED, PROVABLY INERT off-software** | Two critics *ran* `kb-actback-task.sh` on data-ml/content/design doc-sets: the representative task degrades to **"add a new endpoint"** (nonsensical for a design/data/docs project), and the operational-structure presence check returns an **empty table** — its owning-table (`_doc_expects_class`) recognizes **only software filenames** (I confirmed: architecture/coding-standards/domain-glossary/integration-map/module-map/pipeline-contracts/schemas/tech-debt — no non-software docs). The gate that's supposed to enforce work-actionability does nothing for 5 of 8 domains. |

The spine/matrix/fallback/gate **machinery is domain-general by construction**; only the
**per-domain content** (depth contracts + safeguard wiring) is software/methodology-complete and
non-software-stubbed. Breadth ran ahead of depth.

## Reconciling the one disagreement (software depth: gained or lost?)

Advocate said the new *improved* software depth (added `## Invariants/Gotchas/Contracts` operational
sections; 15 operational sections vs the baseline's 0). Adversary said it *lost* software depth
(schemas field-types 16→1, exit-codes 38→17, host-tool matrix deleted). **Both are true and not
contradictory:** the new generator added operational-structure *framing* (a real depth gain) but its
"altitude rule" (volatile detail → `sources:` pointers) pushed some inline *signature detail* out.
Net for software: **better-framed, modestly thinner on inline signatures** — an agent occasionally
must follow a `sources:` pointer back to code for a field type the KB used to state. The neutral's
"mostly healthy de-bloat + a modest altitude tax" is the calibrated read.

## Direct answer, per domain (confidence tag)

- **software-cli/web + methodology-tooling → YES, work-effective + gate-verified.** HIGH/VERIFIED — the live dogfood run had full per-doc expectations, populated operational sections, and an act-back keystone *with teeth* (it caught + forced a FIX on a real sufficiency FAIL).
- **data-ml / content / research / design / ops → ORIENTATION-ONLY.** HIGH/VERIFIED that the safeguards are inert there (0 expectations entries; act-back degrades to "add an endpoint"; empty presence check). Whether the resulting prose would still be useful is INFERRED — a capable agent *might* write a decent doc off the generic question, but **nothing verifies it reaches work-actionable depth, and the gate cannot catch it if it doesn't.**

So the honest claim is **not** "produces work-guides for any project type." It is: *"orients any
domain, and delivers gate-verified work-actionable KBs for software + methodology-tooling."* Still a
decisive net win over the old generator (which failed the any-domain question outright) — just not
the full promise its own matrix advertises.

## The fix (targeted, not architectural — all 3 critics converge)

1. **Author `document-expectations.md` entries for the ~30 non-software matrix docs** (content-model, design-tokens, data-pipeline, data-schemas, model-cards, methodology, evidence-sources, config-schemas, …) — each with must-have / investigate / operational-open-question / red-flags, at the domain's work-actionable depth (e.g. data-schemas: field types + nullability + PII + join keys + source access). **This is the single biggest gap** — without it the prompt points at a dangling anchor.
2. **Generalize the act-back owning-table** (`kb-actback-task.sh _doc_expects_class`, single-sourced from `concern-model.md`) so non-software docs are checked for the right operational classes (content-model/design-tokens own Contracts; style-guide/design-principles own Conventions; accessibility-landscape owns Invariants).
3. **Add non-software task shapes** to the representative-task heuristic (add-a-token / add-a-dataset-field / add-a-content-type / add-a-runbook) so the act-back probe is a *meaningful* change, not "add an endpoint."
4. **Validate by dogfooding** the engine on at least one real non-software project (a data or design repo) — the depth + safeguard gaps were invisible precisely because AID only dogfooded software + methodology.

This is a coherent feature-016-shaped piece: "generalize the depth-contract + operational-sufficiency
layer past the dogfooded domains."

## The meta-insight

The any-domain capability is **designed-general but content-complete-only-where-dogfooded.** The
breadth layer was engineered domain-agnostic from the start; the depth contracts and the act-back
wiring naturally followed exactly the two domains AID itself is. That's why the gate had teeth on the
dogfood run (a hybrid that composed in the software docs the owning-table recognizes) and would be
inert on a pure non-software project. The lesson generalizes: **a generator's depth is only as broad
as the domains you've forced it to prove itself on.**

## Bottom line

The new `/aid-discover` is the better generator — strictly and substantially, for software and
methodology work, and architecturally for everything else. To make its "any project type" claim
*operationally* true, the work is not redesign — it's **extending the depth-contract layer and the
act-back safeguard to the other matrix domains, then dogfooding them.** Until then, state the honest
scope: orients any domain; work-guides software + methodology.
