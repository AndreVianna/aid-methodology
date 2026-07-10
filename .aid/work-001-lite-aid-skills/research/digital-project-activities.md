# Digital-Project Activity Landscape — Research Report

**Work:** work-001-lite-aid-skills
**Purpose:** Ground the design of a curated set of Lite-path "shortcut" skill families in the real,
cross-discipline landscape of recurring "units of work" a digital-project practitioner performs —
so the shortcut catalog (and any recipe pruning) is derived from established process frameworks
rather than from the current software-only recipe list alone.
**Access date for all external sources:** 2026-07-07
**Confidence legend:** CONFIRMED (framework verified directly online this session) · LIKELY (strong cross-source inference) · UNCERTAIN (weak/indirect signal)

> Method note: every framework cited below was verified online during this research session (not
> from memory). Each activity row names the framework it derives from; full URLs + access date are
> in `## Sources`. Activities are stated verb-first ("the atomic *I need to do X*"), because a
> shortcut skill is invoked by intent, not by artifact type.

---

## Disciplines & activities

### 1. Software development (SDLC, Agile/Scrum)

The SDLC is the canonical phase model (plan → requirements/analysis → design → implement → test →
deploy → maintain); Agile/Scrum overlays an iterative event cadence on top of it. [CONFIRMED]

| Activity (verb-first) | Framework / source |
|---|---|
| Elicit & analyze requirements for a change | SDLC "Requirements & Analysis" phase [Atlassian SDLC; Emergent] |
| Design the solution / system blueprint | SDLC "Design" phase [Atlassian SDLC] |
| Implement / code a new capability | SDLC "Coding & Implementation" [Emergent] |
| Refactor / improve existing code | SDLC "Maintenance" (perfective) [Atlassian SDLC] |
| Fix a defect / bug | SDLC "Maintenance" (corrective) [Atlassian SDLC] |
| Test / validate the change | SDLC "Testing" phase [Emergent] |
| Deploy / release to users | SDLC "Deployment" phase [Emergent] |
| Break an item into a small user story & size it | Scrum Product Backlog refinement [Scrum Guide] |
| Plan a sprint / select backlog items | Scrum Sprint Planning [Scrum Guide; Atlassian ceremonies] |
| Review shipped increment with stakeholders | Scrum Sprint Review [Scrum Guide] |
| Run a retrospective / improve the process | Scrum Sprint Retrospective [Scrum Guide] |

### 2. Data & analytics / data science (CRISP-DM, Microsoft TDSP)

CRISP-DM's six phases and Microsoft's five-stage TDSP are the two dominant data-science lifecycle
models; both are explicitly iterative. [CONFIRMED]

| Activity (verb-first) | Framework / source |
|---|---|
| Frame the business problem as a data question | CRISP-DM "Business Understanding"; TDSP "Business Understanding" [Wikipedia CRISP-DM; TDSP] |
| Collect / ingest initial data | CRISP-DM "Data Understanding"; TDSP "Data Acquisition" [Data Science PM; TDSP] |
| Explore data (EDA) / profile quality & patterns | CRISP-DM "Data Understanding"; TDSP EDA [Wikipedia CRISP-DM; TDSP] |
| Clean / prepare / format a dataset | CRISP-DM "Data Preparation" [Wikipedia CRISP-DM] |
| Engineer features | TDSP "Modeling" (feature engineering) [TDSP] |
| Select & train a model | CRISP-DM "Modeling"; TDSP "Modeling" [Data Science PM] |
| Evaluate / validate model against unseen data | CRISP-DM "Evaluation" [Wikipedia CRISP-DM] |
| Deploy model into the business process | CRISP-DM "Deployment"; TDSP "Deployment" [Wikipedia CRISP-DM; TDSP] |
| Produce the final project report / hand-off | TDSP "Customer Acceptance" (Project Final Report) [TDSP] |
| Build a dashboard / BI view for insight | DAMA "Data Warehousing, BI & Analytics" KA [Snowflake DMBOK; Wikipedia Data management] |

### 3. Data engineering / DataOps (DAMA-DMBOK, DataOps)

DAMA-DMBOK organizes data management as a wheel of ~11 knowledge areas with Data Governance at the
hub; DataOps applies Agile + DevOps practice to data pipelines. [CONFIRMED for framework structure;
the KA count is cited 11 by DAMA sources]

| Activity (verb-first) | Framework / source |
|---|---|
| Model & design data structures / schemas | DAMA "Data Modeling & Design" KA [Snowflake DMBOK; cimt] |
| Define data architecture / flows | DAMA "Data Architecture" KA [Snowflake DMBOK] |
| Build / orchestrate a data pipeline | DataOps pipeline orchestration [Dagster DataOps; IBM DataOps] |
| Add data-quality checks / validations | DataOps data-quality monitoring; DAMA "Data Quality" KA [Dagster; Snowflake DMBOK] |
| Integrate / move data between systems | DAMA "Data Integration & Interoperability" KA [Snowflake DMBOK] |
| Manage reference / master data | DAMA "Reference & Master Data" KA [cimt] |
| Manage metadata / catalog | DAMA "Metadata" KA [Snowflake DMBOK] |
| Version pipelines as code / CI-CD for data | DataOps CI/CD + IaC for data [Dagster; IBM DataOps] |
| Observe pipeline health / freshness / SLA | DataOps continuous observability [Dagster] |
| Govern data (policy, ownership, compliance) | DAMA "Data Governance" (wheel hub) [Snowflake DMBOK] |
| Secure data / manage access | DAMA "Data Security" KA [Wikipedia Data management] |

### 4. Design & UX (Double Diamond, Design Thinking 5-stage)

The Design Council's Double Diamond (Discover → Define → Develop → Deliver) and Stanford d.school's
five-stage Design Thinking (Empathize → Define → Ideate → Prototype → Test) are the two most-cited
design-process models; both alternate divergent/convergent thinking and are iterative. [CONFIRMED]

| Activity (verb-first) | Framework / source |
|---|---|
| Research users / observe & interview | Double Diamond "Discover"; DT "Empathize" [Wikipedia Double Diamond; IxDF DT] |
| Synthesize research into a problem statement | Double Diamond "Define"; DT "Define" [Wikipedia Double Diamond; IxDF DT] |
| Ideate / generate solution options | DT "Ideate"; Double Diamond "Develop" [IxDF DT] |
| Prototype a solution (low/high fidelity) | DT "Prototype"; Double Diamond "Develop" [IxDF DT] |
| Test the prototype / gather feedback | DT "Test"; Double Diamond "Deliver" [IxDF DT] |
| Refine & launch the final design | Double Diamond "Deliver" [uxpin Double Diamond] |
| Write a design spec / hand-off to build | Double Diamond "Deliver" (deliver-to-implementation) [uxpin Double Diamond] |

### 5. Content, documentation & reporting (Diátaxis, Content lifecycle)

Diátaxis classifies technical docs into four intent-driven types; content-lifecycle models describe
the operational stages a content asset moves through. [CONFIRMED]

| Activity (verb-first) | Framework / source |
|---|---|
| Write a tutorial (learning-oriented) | Diátaxis "Tutorials" [diataxis.fr; start-here] |
| Write a how-to guide (task-oriented) | Diátaxis "How-to guides" [diataxis.fr] |
| Write / update reference material (info-oriented) | Diátaxis "Reference" [diataxis.fr] |
| Write an explanation (understanding-oriented) | Diátaxis "Explanation" [diataxis.fr] |
| Plan content / set editorial goals | Content lifecycle "Planning & ideation" [Bynder CLM] |
| Create / draft content | Content lifecycle "Creation & collaboration" [Bynder CLM] |
| Review & approve content | Content lifecycle "Review & approval" [Bynder CLM] |
| Publish / distribute content | Content lifecycle "Distribution & activation" [Bynder CLM; Acquia] |
| Measure & optimize / maintain content | Content lifecycle "Performance & optimization"; govern/maintain [Bynder CLM; Acquia] |
| Produce a status / progress report | (reporting analogue of content-create; see PM §9 & Analytics §2) |

### 6. QA / testing (ISTQB fundamental test process)

ISTQB's fundamental test process has five activity clusters (may overlap/run concurrently): planning
& control, analysis & design, implementation & execution, evaluating exit criteria & reporting, and
test closure. [CONFIRMED]

| Activity (verb-first) | Framework / source |
|---|---|
| Plan tests / define scope & approach | ISTQB "Test planning & control" [ISTQB glossary; rogeriodasilva] |
| Analyze the test basis & design test cases | ISTQB "Test analysis & design" [ISTQB glossary] |
| Implement test scripts / build test suites | ISTQB "Test implementation & execution" [ISTQB glossary; rogeriodasilva] |
| Execute tests / run the suite | ISTQB "Test implementation & execution" [ISTQB glossary] |
| Evaluate exit criteria & report results | ISTQB "Evaluating exit criteria & reporting" [rogeriodasilva] |
| Close testing / capture lessons | ISTQB "Test closure" [rogeriodasilva] |
| Add / extend automated test coverage | ISTQB test implementation (automation) + DORA test automation [ISTQB glossary; DORA CD] |

### 7. Infrastructure / DevOps / SRE (DevOps 8-phase loop, DORA, Google SRE)

The DevOps "infinity loop" (plan · code · build · test · release · deploy · operate · monitor) plus
DORA delivery capabilities describe the make-and-ship side; Google SRE covers the run-and-sustain
side (SLOs, incidents, toil). [CONFIRMED]

| Activity (verb-first) | Framework / source |
|---|---|
| Build / configure infrastructure (IaC) | DevOps "build/release"; DataOps IaC [IBM DevOps; Dagster] |
| Automate deployment / release pipeline | DORA "deployment automation" & continuous delivery [DORA CD; Octopus DORA] |
| Deploy / release a change to production | DevOps "release → deploy" [IBM DevOps] |
| Define / track SLOs & alerting | Google SRE SLO-based monitoring [Google SRE book] |
| Monitor / observe a live service | DevOps "monitor"; SRE observability [IBM DevOps; Google SRE book] |
| Respond to an incident / mitigate outage | Google SRE incident management [Google SRE incident guide] |
| Write a postmortem / prevent recurrence | Google SRE blameless postmortem culture [Google SRE incident guide] |
| Author / update a runbook or playbook | Google SRE playbooks [Google SRE incident guide] |
| Automate away toil / repetitive ops work | Google SRE toil reduction (<50%) [Google Cloud toil] |
| Plan capacity / manage change | Google SRE capacity planning & change management [Google SRE book] |

### 8. Security (OWASP SAMM, NIST SSDF / SP 800-218)

OWASP SAMM structures software security into five business functions (Governance, Design,
Implementation, Verification, Operations); NIST SSDF into four practice groups (Prepare, Protect,
Produce, Respond). [CONFIRMED]

| Activity (verb-first) | Framework / source |
|---|---|
| Define security requirements / policy | SAMM "Governance"; SSDF "Prepare the Organization" [OWASP SAMM model; NIST SSDF] |
| Threat-model / design secure architecture | SAMM "Design" [OWASP SAMM model] |
| Protect artifacts / secure the build & supply chain | SSDF "Protect the Software" [NIST SSDF] |
| Apply secure coding & static analysis | SSDF "Produce Well-Secured Software" (PW) [NIST SSDF] |
| Verify / test security (SAST, DAST, fuzz, review) | SAMM "Verification"; SSDF PW (dynamic/fuzz) [OWASP SAMM model; NIST SSDF] |
| Audit dependencies / manage component risk | SSDF PS/PW component practices [NIST SSDF] |
| Manage environments & operational security | SAMM "Operations" (environment/operational mgmt) [OWASP SAMM model] |
| Respond to / remediate a vulnerability | SSDF "Respond to Vulnerabilities" (RV); SAMM incident mgmt [NIST SSDF; OWASP SAMM model] |
| Harden / assess security maturity | SAMM maturity assessment (levels 0–3) [OWASP SAMM model] |

### 9. Product & project management / operations (PMBOK, Scrum, product discovery)

PMBOK's five process groups (Initiating, Planning, Executing, Monitoring & Controlling, Closing)
frame project management; product-management practice adds discovery, prioritization, roadmapping,
experimentation and metrics. [CONFIRMED]

| Activity (verb-first) | Framework / source |
|---|---|
| Initiate / authorize a project or phase | PMBOK "Initiating" process group [PMI process groups; 4pmti] |
| Plan scope, schedule & resources | PMBOK "Planning"; SDLC project planning [PMI process groups] |
| Execute / coordinate the work | PMBOK "Executing" [PMI process groups] |
| Monitor & control progress vs. plan | PMBOK "Monitoring & Controlling" [PMI process groups] |
| Close the project / gain acceptance | PMBOK "Closing" [PMI process groups; 4pmti] |
| Run product discovery / user research | Product discovery (interviews, analytics, competitive research) [Productboard; Product School] |
| Prioritize features (RICE / MoSCoW) | Product prioritization frameworks [Productboard] |
| Build / maintain a roadmap | Product roadmapping [Productboard] |
| Run an A/B test / experiment | Product experimentation & A/B testing [Productboard] |
| Define & measure success metrics | Product success metrics (activation, retention, churn) [Productboard] |
| Produce a status / stakeholder report | PMBOK monitoring & communications [PMI process groups] |

---

## Proposed major activity groups

Synthesized across the nine disciplines above. Twelve groups, ordered along a generic
digital-deliverable arc (frame → make → assure → ship → run → steer). Each is a candidate
shortcut-skill family; the "make" trio (Build, Change, Fix) is exactly where AID's current catalog
already lives. Groups are deliberately **verb-first and artifact-agnostic** — the artifact type
(API, UI, dataset, doc, dashboard, pipeline) becomes a *parameter*, not a separate family.

| # | Group | One-line intent | Spanned activities (with source disciplines) |
|---|---|---|---|
| G1 | **Discover & Research** | Investigate a problem/opportunity space and gather evidence before committing to a solution. | Business understanding (CRISP-DM/TDSP §2); Empathize/Discover (Design §4); product discovery & user research (PM §9); data understanding/EDA (Data §2); requirements elicitation (SDLC §1). |
| G2 | **Define & Specify** | Turn a fuzzy need into a crisp, agreed problem statement, spec, or requirements set. | Define diamond (Design §4); requirements analysis (SDLC §1); data modeling/schema design (Data §3); security & test planning (§6, §8); acceptance criteria / SLO definition (§7). |
| G3 | **Design & Prototype** | Produce a design artifact or a low-fidelity working model to validate direction before full build. | Ideate + Prototype (Design §4); Develop diamond; SDLC "Design"; SAMM "Design"/threat model (§8); data-architecture sketch (§3). |
| G4 | **Build & Create (new)** | Create a new artifact or capability from scratch. | Implement/code (SDLC §1); build data pipeline (§3); build infra/IaC (§7); author content (Diátaxis §5); build dashboard (§2); secure coding produce (§8). |
| G5 | **Change & Improve (modify)** | Modify, enhance, refactor, or optimize an existing artifact without changing its intent. | Perfective maintenance/refactor (SDLC §1); improve performance; edit/update content (§5); tune/re-train model (§2); optimize pipeline (§3); bump/patch dependency (§8). |
| G6 | **Fix & Remediate** | Diagnose and correct a defect, regression, incident, or vulnerability. | Corrective maintenance/bug fix (SDLC §1); incident response + mitigation (SRE §7); respond-to-vulnerability RV (SSDF §8); data-quality fix (§3). |
| G7 | **Verify & Test** | Establish or extend confidence that something works and meets its criteria. | ISTQB test process (§6); add test coverage; model evaluation (CRISP-DM §2); A/B test / experiment (PM §9); data-quality checks (§3); security verification SAST/DAST (§8); content review & approval (§5). |
| G8 | **Document & Communicate** | Produce human-facing explanatory/reference artifacts and progress communication. | Diátaxis 4 doc types (§5); runbook/postmortem (SRE §7); ADR/changelog; status & stakeholder reports (PM §9); TDSP final report (§2). |
| G9 | **Deploy & Release** | Ship an artifact to its target environment / audience. | Deployment (SDLC/CRISP-DM/TDSP); release→deploy (DevOps §7); CI/CD promotion for data (§3); publish content (§5); protect-the-build supply chain (§8). |
| G10 | **Operate & Monitor** | Run, observe, and sustain a live system or asset. | Operate + monitor (DevOps §7); SLO/observability + toil reduction (SRE §7); pipeline observability (§3); capacity/change mgmt; environment/operational security (SAMM §8). |
| G11 | **Analyze & Report (insight)** | Extract insight from data/usage and communicate it for decisions. | Modeling/evaluation (CRISP-DM §2); BI/analytics KA (DMBOK §3); build dashboard; product metrics + A/B analysis (PM §9); DORA delivery metrics (§7). |
| G12 | **Plan, Govern & Steer** | Scope/sequence/track the work itself and set & enforce the policies, standards, and controls around the assets. | PMBOK process groups + Scrum events (§1, §9); roadmap & prioritization (PM §9); data governance hub (DMBOK §3); SAMM Governance + SSDF Prepare/Protect (§8); feature-flag/config governance. |

> Consolidation note: G1–G3 (frame + design) are tightly coupled and could ship as one "Shape /
> Discovery" family if a lean set is preferred; likewise G11 (Analyze) overlaps G7 (evaluate) and G8
> (report). The 12-group form is the *maximal* useful decomposition within the requested 6–14 band;
> a lean cut is 8: Discover-Define-Design, Build, Change, Fix, Verify, Document, Deploy-Operate,
> Plan-Govern.

---

## Mapping to existing AID recipes

The current 52-recipe catalog is essentially **three verbs × ~17 artifact nouns** (`fix-*`,
`change-*`, `add-*`) plus `add-test-coverage`. It concentrates almost entirely in three of the twelve
groups (G4/G5/G6) and is *over-decomposed by artifact noun*. The table maps each group to existing
coverage, flags gaps (candidate NEW shortcut skills), and flags narrow/redundant recipes (candidate
PRUNES).

| Group | Covered by existing recipes | Coverage gaps (candidate NEW skills) | Prune candidates (narrow / redundant) |
|---|---|---|---|
| G1 Discover & Research | None (discovery lives in `aid-describe` interview, not a Lite recipe) | **GAP** — no `aid-research` / `aid-explore` shortcut. Highest-value new family for cross-discipline reach. | — |
| G2 Define & Specify | Partial — this is the pipeline's own Specify phase; no Lite recipe | **GAP** — arguably intentional (the methodology defines specs); a lightweight `aid-spec` shortcut could still help. | — |
| G3 Design & Prototype | None | **GAP** — `aid-prototype-ui` is explicitly named as a wanted shortcut; also design-spec / data-model design. | — |
| G4 Build & Create | Strong — all 21 `add-*` recipes | Gaps within family: build data pipeline, build dashboard, author content (`add-docs` only partial), build/provision infra beyond `add-container`. | `add-member`, `add-rule`, `add-feature-flag` (see below); the per-noun explosion generally. |
| G5 Change & Improve | Strong — 23 `change-*` + `rename-symbol` + `bump-dependency` + `improve-performance` | Gaps: tune/re-train model, optimize data pipeline, edit content (only `change-docs`). | `change-member`, `change-rule`, `change-feature-flag`, `change-ui-style`, `rename-symbol` (mechanical), `change-cli-command`, `change-container`. |
| G6 Fix & Remediate | Strong — 7 `fix-*` (application/api/ui/integration/infrastructure/regression/security) | Gaps: data-quality fix; incident response is reactive-only (`fix-infrastructure`), no runbook-driven path. | Possibly `fix-regression` (a mode of `fix-application`, not a distinct workflow). |
| G7 Verify & Test | Partial — `add-test-coverage` only | **GAP** — no run-experiment / A-B test, no evaluate-model, no security-verify (SAST/DAST), no data-quality-check recipe. | — |
| G8 Document & Communicate | Partial — `add-docs`, `change-docs` | **GAP** — no status-report, runbook, changelog, ADR, or Diátaxis-typed doc shortcuts. | `change-report`/`add-report` fit better here or in G11 (see below). |
| G9 Deploy & Release | Covered by `aid-deploy` pipeline skill (not a Lite recipe) | Minor gap — publish-content / promote-pipeline as data/content analogues. | — |
| G10 Operate & Monitor | None | **GAP** — no operate/monitor family (SLO setup, observability, toil automation, capacity). Reactive `fix-infrastructure` is the only touchpoint. | — |
| G11 Analyze & Report | Partial — `add-report`, `change-report` (software "report" artifacts) | **GAP** — no data-analysis, dashboard/BI, or product-metrics analytics shortcut; existing report recipes are code-artifact reports, not analytical insight. | — |
| G12 Plan, Govern & Steer | None (planning is the pipeline itself) | **GAP** — no proactive govern/harden/audit recipe; `fix-security` is reactive only. Config/flag/rule recipes touch governance narrowly. | `add-rule`/`change-rule` (ambiguous "rule"), `add-feature-flag`/`change-feature-flag`, `add-config-option`/`change-config-option` overlap here and with G5. |

### Prune synthesis (the noun-explosion problem) [LIKELY]

The single biggest catalog observation: **~52 recipes exist mostly because each of three verbs was
cloned across ~17 artifact nouns.** A verb-first, noun-parameterized shortcut family collapses most
of this. Strongest individual prune candidates, by redundancy/narrowness:

- **`rename-symbol`** — a mechanical IDE refactor; too trivial to warrant a full Lite work/spec. Fold into `change-interface` or drop.
- **`add-member` / `change-member`** — a class "member" is subsumed by `change-interface` + `rename-symbol`; narrow.
- **`add-rule` / `change-rule`** — ambiguous "rule"; overlaps `change-config-option` and domain-logic changes.
- **`add-feature-flag` / `change-feature-flag`** — subsumed by `change-config-option`; a flag is a config with a rollout, not a distinct workflow.
- **`change-ui-style`** — a CSS/token tweak; subsumed by `change-ui-component`.
- **`add-cli-command` / `change-cli-command`** — thin over an interface; fold into an API/interface family.
- **`add-container` / `change-container`** — infra-shaped; overlaps `fix-infrastructure` and the (missing) G10 operate family.
- **`fix-regression`** — a mode of `fix-application`, not a separate workflow.

Recommended consolidation shape: collapse the `add-*`/`change-*` noun matrix into a small number of
verb-first families that take an artifact-type parameter (e.g. `add-ui` absorbing
component/endpoint/style; `add-api` absorbing endpoint/middleware/cli; `add-messaging` absorbing
message/queue/event-handler), keeping a distinct recipe only where the artifact genuinely changes the
workflow (schema/data migration, integration, entity/domain modeling). [LIKELY]

### Where the catalog is blind [CONFIRMED against catalog list]

Groups with **zero** Lite-recipe coverage today: **G1 Discover**, **G3 Design/Prototype**, **G10
Operate & Monitor**, and (analytically) **G11 Analyze & Report** and **G12 Govern**. These are
precisely the non-software-centric groups the stakeholder wants to reach (data/analytics, design/UX,
ops). G7 Verify and G8 Document are only thinly covered. The current catalog is a near-pure
implementation-phase (build/change/fix) tool.

---

## Sources

All accessed 2026-07-07.

**Software development / Agile / Scrum / DevOps**
- What is the Software Development Life Cycle (SDLC)? — https://www.atlassian.com/agile/software-development/sdlc
- The 7 Stages of the Software Development Life Cycle — https://www.emergentsoftware.net/blog/the-7-stages-of-the-software-development-life-cycle-sdlc/
- The Scrum Guide (2020) — https://scrumguides.org/scrum-guide.html
- A guide to agile ceremonies and scrum meetings (Atlassian) — https://www.atlassian.com/agile/scrum/ceremonies
- What are the phases of the DevOps lifecycle? (IBM) — https://www.ibm.com/think/topics/devops-lifecycle
- DORA — Capabilities: Continuous delivery — https://dora.dev/capabilities/continuous-delivery/
- Understanding the 4 DORA Metrics (Octopus Deploy) — https://octopus.com/devops/metrics/dora-metrics/

**Data science / analytics**
- Cross-industry standard process for data mining (CRISP-DM) — Wikipedia — https://en.wikipedia.org/wiki/Cross-industry_standard_process_for_data_mining
- What is CRISP-DM? — Data Science PM — https://www.datascience-pm.com/crisp-dm-2/
- Microsoft TDSP lifecycle detail (Azure/Microsoft-TDSP) — https://github.com/Azure/Microsoft-TDSP/blob/master/Docs/lifecycle-detail.md
- What is TDSP? — Data Science PM — https://www.datascience-pm.com/tdsp/

**Data management / data engineering / DataOps**
- DAMA-DMBOK Explained: Data Management Framework (Snowflake) — https://www.snowflake.com/en/data-governance/frameworks/dama-dmbok/
- DAMA DMBoK explained: the 11 knowledge areas (cimt) — https://cimt.nl/en/dama-dmbok/
- Data management — Wikipedia (topics in data management) — https://en.wikipedia.org/wiki/Data_management
- DataOps in Practice: Principles, Lifecycle & Tips (Dagster) — https://dagster.io/learn/dataops
- What Is DataOps? (IBM) — https://www.ibm.com/think/topics/dataops

**Design & UX**
- Double Diamond (design process model) — Wikipedia — https://en.wikipedia.org/wiki/Double_Diamond_(design_process_model)
- Double Diamond Design Process Explained (UXPin, citing Design Council) — https://www.uxpin.com/studio/blog/double-diamond-design-process/
- The 5 Stages in the Design Thinking Process (Interaction Design Foundation) — https://ixdf.org/literature/article/5-stages-in-the-design-thinking-process

**Content, documentation & reporting**
- Diátaxis (official site) — https://diataxis.fr/
- Diátaxis — Start here / in five minutes — https://diataxis.fr/start-here/
- The 5 stages of content lifecycle management (Bynder) — https://www.bynder.com/en/blog/5-stages-content-lifecycle-management/
- 6 Stages of the Digital Content Lifecycle (Acquia) — https://www.acquia.com/glossary/content-lifecycle

**QA / testing**
- Test Process — ISTQB Glossary — https://istqb-glossary.page/test-process/
- Five Core Test Activities and Tasks (ISTQB) — https://rogeriodasilva.com/five-fundamental-test-activities-and-tasks-from-planning-to-test-closure-istqb/

**Infrastructure / DevOps / SRE**
- Google SRE — Incident Management Guide — https://sre.google/resources/practices-and-processes/incident-management-guide/
- Google SRE Book — Table of Contents — https://sre.google/sre-book/table-of-contents/
- Identifying and tracking toil using SRE principles (Google Cloud) — https://cloud.google.com/blog/products/management-tools/identifying-and-tracking-toil-using-sre-principles

**Security**
- The Model — OWASP SAMM — https://owaspsamm.org/model/
- OWASP SAMM (OWASP Foundation project page) — https://owasp.org/www-project-samm/
- NIST SP 800-218, Secure Software Development Framework (SSDF) v1.1 — https://csrc.nist.gov/pubs/sp/800/218/final
- NIST SP 800-218 (full PDF) — https://nvlpubs.nist.gov/nistpubs/specialpublications/nist.sp.800-218.pdf

**Product & project management / operations**
- Process Groups: A Practice Guide (PMI) — https://www.pmi.org/standards/process-groups
- Traditional PM Process Groups Complete Guide (PMTI) — https://www.4pmti.com/learn/traditional-process-groups/
- Guide: Product Discovery Process & Techniques (Productboard) — https://www.productboard.com/blog/step-by-step-framework-for-better-product-discovery/
- The Definitive Guide to Product Discovery and Frameworks (Product School) — https://productschool.com/blog/product-fundamentals/what-is-product-discovery
