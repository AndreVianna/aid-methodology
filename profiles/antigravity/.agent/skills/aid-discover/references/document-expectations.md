# Document Expectations

These define what the aid-reviewer agent (and FIX mode) should look for in each document.
Each entry leads with the open question(s) the doc must answer, retains the investigation
slots as a parenthetical, and keeps the red-flags as calibration aids.

---

### project-structure.md

**What is this project's actual shape -- where does it begin, where does it end, and how
is it laid out for someone who has never opened it?** Walk the directory tree and explain
why each major directory exists. Where do the builders put the things that matter: the
entry points, the build files, the configs, the tests, the documentation? What languages
and frameworks appear? Report what is actually here, not a generic skeleton. Other agents
use this doc to know WHERE to look; it is a map, not an analysis.
*(Investigate: top-3-to-4-level directory tree with per-directory purpose annotations,
key files and their roles -- entry points, build files, configs, tests -- detected
languages and frameworks, documentation files found in the repository.)*
**Red flags:** Too shallow (a tree dump without annotations). Missing directory-purpose
explanations. Too deep (analyzing patterns instead of mapping structure). Missing key
build or config files.

---

### architecture.md

**Describe how this system is built and why it is shaped this way.** What kind of system
is it, and what shape did its builders give it? Where are its boundaries and why do they
fall there? How does work or data flow from entry to outcome, and what is non-obvious
about that flow? What did the builders decide that a newcomer could not guess from the
code alone? Ground every claim in a file or path.
*(Investigate: project type, the load-bearing boundaries, the real data path from entry
to processing to persistence, the architectural patterns with evidence from code, module
boundaries, DI registration, entry points -- but report what this project actually does,
not a generic architecture checklist.)*
**Operational open question:** What must a newcomer never break when changing this system's
structure -- the invariants that must always hold (an ordering, a single-source-of-truth
rule, a non-null guarantee) and the gotchas that will bite if violated? Surface these as
a `## Invariants` section and a `## Gotchas` section.
**Red flags:** Generic descriptions without file paths. Missing data flow.

---

### technology-stack.md

**What is this project actually built with, and how does a developer build and lint it?**
For every language, framework, database, package manager, build tool, and runtime: give
the actual version from the config files, not an assumption. Then answer: what is the
exact command to build this project? What is the exact command to lint it? An agent
cannot execute "Maven" or "npm" without the full command.
*(Investigate: languages with versions, frameworks with versions from actual config files,
databases, package managers, build tools, runtime, dev tooling; Build Commands section
with exact runnable command(s); Lint Commands section with exact runnable command(s).)*
**Red flags:** "Version TBD" on things extractable from pom.xml, package.json, or
manifests. Missing or vague Build/Lint Commands (e.g. just "Maven" without
`mvn clean package`).

---

### module-map.md

**What are the parts of this system, and how do they depend on each other?** For every
module: what is it for, and what does it depend on? A module listed without its purpose
or its dependencies tells the reader nothing useful.
*(Investigate: every module listed with purpose, key classes, dependencies between
modules.)*
**Operational open question:** What must a newcomer follow, never break, and watch out for
when changing this system's parts and connections -- the conventions for how a new module
is named and wired in, the invariants that must hold across module boundaries, and the
gotchas that will bite on a structural change? Surface these as a `## Conventions` section,
a `## Invariants` section, and a `## Gotchas` section.
**Red flags:** Module listed without purpose explanation. Missing dependency relationships.

---

### coding-standards.md

**What are this project's own conventions -- the rules a contributor must follow that are
not obvious from general programming knowledge?** For naming, file layout, DI patterns,
error handling, logging, and testing: what does *this* project do and where is the
evidence in the code? General advice ("use meaningful names") is not a finding.
*(Investigate: naming conventions with examples from actual code, file layout, DI
patterns, error handling patterns, logging patterns, test patterns.)*
**Operational open question:** What are the project's own conventions for every recurring
change -- the specific naming patterns, file-layout rules, registration steps, and wiring
sequences a contributor must follow? Surface these as a `## Conventions` section so an
agent making a change can follow the project's own way, not invent one.
**Red flags:** Generic advice instead of project-specific conventions extracted from code.

---

### schemas.md

**What are the core data shapes in this system, and how do they relate to each other?**
What entities exist, what is each one for, and how do they connect (one-to-many,
many-to-many, inheritance)? Where does the data live and how is the schema managed over
time?
*(Investigate: entity hierarchy, relationships -- 1:N, M:N -- base classes, key entities
with purpose, database config, migration strategy.)*
**Operational open question:** What structural contracts must a change to these data shapes
satisfy -- the schema invariants, the field contracts, and the conventions for adding a
new entity or field? Surface the contracts as a `## Contracts` section and any conventions
for schema evolution as a `## Conventions` section.
**Red flags:** Entity list without relationships. Missing how entities connect to each
other.

---

### pipeline-contracts.md

**How does a caller actually invoke this system's pipeline or API, and what comes back?**
Give real endpoint paths or URLs, not just class or action names. What is the auth
mechanism? What do request and response bodies look like? What happens on errors?
*(Investigate: pipeline or API style, actual endpoint paths/URLs not just class names,
auth mechanism, request and response formats, error patterns.)*
**Operational open question:** What structural contracts must a new endpoint or pipeline
stage satisfy -- the required fields, response shapes, auth constraints, and error
contracts -- and what are the conventions for adding one (naming, registration, wiring)?
Surface these as a `## Contracts` section and a `## Conventions` section so an agent
adding a new endpoint knows exactly what to conform to.
**Red flags:** Lists action classes without URLs. Missing how to actually call the
pipeline or API.

---

### integration-map.md

**What external systems does this project depend on, and how does it connect to each one?**
For each external system: what protocol, what configuration, where is that configuration,
how are errors handled, how are retries managed? This is not the same as
module-map.md -- it is about connections outside the boundary of this project.
*(Investigate: external systems with connection details, protocols, config locations,
error handling, retry patterns.)*
**Operational open question:** What contracts govern each external connection -- the
required protocol, auth, and payload shape a new integration must satisfy -- and what are
the gotchas (config that must change in lockstep, retry hazards, ordering constraints)?
Surface these as a `## Contracts` section and a `## Gotchas` section.
**Red flags:** Same content as module-map.md. Missing connection details for external
systems.

---

### domain-glossary.md

**What is the project's own language -- the terms you must understand to understand the
system?** For each native or coined term: what does it mean *here* (not in general),
where does it live in the code or domain, and why does the project need it? Reach for the
term while explaining the system; if you cannot define it from general knowledge, it is a
mandatory investigation, never noise. Keep going until you can explain the system using
only defined native terms plus general knowledge.
*(Investigate: business-specific terms, technical terms coined or overloaded by this
project, abbreviations, product names with explanations -- not generic programming
vocabulary.)*
*(The 'Relative bus' failure: a load-bearing coined concept treated as noise. This doc
closes that gap; it is the concept spine.)*
**Operational open question:** Which terms carry load-bearing conceptual invariants -- the
concepts a newcomer must never confuse, conflate, or misuse (e.g. a coined term whose
boundary distinguishes two subtly different roles)? Surface these as a `## Invariants`
section so an agent using the vocabulary knows which term boundaries are non-negotiable.
**Red flags:** Generic programming terms with no project-specific meaning. Missing
project-specific vocabulary that appears throughout the codebase.

---

### test-landscape.md

**How is this project tested, and how healthy is its test coverage?** Which frameworks
does it use, what types of tests exist, and which modules actually have real tests vs.
placeholders? What is the exact command to run all unit tests? To run per-module tests?
To generate a coverage report? An agent cannot run tests without runnable commands.
*(Investigate: frameworks, test types, coverage target/enforcement if defined, CI
integration, which modules have real tests vs. placeholders, test gaps with severity;
Test Commands section with exact runnable commands for full suite, per-module, and
coverage.)*
**Red flags:** Too short. Missing per-module coverage assessment. Missing or vague Test
Commands (e.g. just "JUnit" without `mvn test`).

---

### tech-debt.md

**What is risky, owed, or worked around in this codebase -- and how serious is each
item?** For each debt item: where exactly is it, what is the risk if it stays, and what
would it take to resolve? Classify by severity so a reader knows where to look first.
*(Investigate: categorized by severity -- Critical, High, Medium, Low -- each with
location, risk, and resolution notes; observations about overall codebase health.)*
**Operational open question:** What are the non-obvious traps a contributor will step on
when changing this system -- the gotchas that are not obvious from code reading (config
that must change in lockstep, build steps that must run, ordering hazards, workarounds
that will break if touched)? Surface these as a `## Gotchas` section so an agent making
a change is warned before hitting the trap, not after.
**Red flags:** Missing severity classification. No actionable locations.

---

### infrastructure.md

**How does this project move from code to running software, and how is it operated?**
Where is the source controlled, how does CI/CD work, what does the container or packaging
look like, how is a release made, and what runs it in production? If there is no
deployment, say so explicitly. Also: what project management tool is used (or say "none")?
*(Investigate: Source Control section -- VCS type, hosting, branch/commit commands; CI/CD
pipeline details; container config; Deployment section -- build output type, packaging,
publishing target, versioning scheme, release process; Project Management section -- tool
or "none", access method, entity mapping if applicable; artifact repos, runtime config,
monitoring, environments.)*
**Red flags:** Lists tools without explaining how they are configured or connected.
Missing Source Control section or assuming Git without verifying. Missing Deployment
section. Project Management section absent -- should explicitly say "none" if no tool is
used.

---

### feature-inventory.md

**What does this project actually do for its users, in the terms its owners use?** List
every feature the user identified. For each one: describe it, give its status, map it to
modules and endpoints, and identify the data entities it touches. A feature without
module mapping or with a placeholder description is not a finding.
*(Investigate: all features from the user's list, each with description, status, modules,
endpoints, data entities.)*
**Red flags:** Features without module mapping. Features with placeholder descriptions.
Features obviously missing from the user's original list.

---

### STATE.md

**What does the reviewer still need to know that the code alone cannot tell?** Every
open question must be specific to this project, answerable by the user (not inferable
from the code), and ordered by how much the answer would change what agents do next.
*(Investigate: questions in structured Q&A format -- each with unique ID Q{N}, category
tag, impact level High/Medium/Low, status Pending/Answered/Skipped, context explaining
why the question matters, suggested answer when inferable from code patterns; questions
ordered by impact.)*
**Red flags:** Too few questions. Generic questions applicable to any project. Missing
impact classification. Missing context field. Vague questions without actionable
specificity. Questions that ARE answerable from the code (should have been resolved during
generation).

---

### external-sources.md

**What external documentation did the user provide, and what did it contain?** For each
source: path, type (file or directory), date provided, accessibility status, and a
summary of the key content. If no external sources were provided, say so explicitly --
all knowledge came from the repository only.
*(Investigate: list of all external documentation sources registered in aid-config, each
with path, type, date provided, accessibility status, and content summary; explicit
statement if no external sources were provided.)*
**Red flags:** Missing when external paths were registered in aid-config. No summary of
what was found in external sources. Not reflecting which KB documents reference external
content.

---

### INDEX.md

**Does the INDEX accurately describe what is actually in each KB doc?** For every doc,
the summary must reflect the real content -- not a generic description that could apply
to any project.
*(Investigate: accurate 2-3 line summary per document, each reflecting actual content.)*
**Red flags:** Generic summaries. Summaries that do not match document content.

---

### README.md

**Is the KB complete and honestly assessed?** The README must have a completeness table
that acknowledges gaps, and a revision history that shows how the KB has evolved.
*(Investigate: completeness table, revision history.)*
**Red flags:** Missing gap acknowledgment.

---

### AGENTS.md

**Does this context file give an agent everything it needs to operate on this project
without additional discovery?** The description, build commands, test commands,
conventions, and architecture summary must be real -- not placeholders. No remaining
"(pending discovery)" text.
*(Investigate: accurate project description, project overview, real build/test commands,
conventions extracted from code, architecture summary, KB reference.)*
**Red flags:** Placeholder text still present. Commands that would not actually work.
Missing key gotchas for agents.

---

### repo-presentation.md

**What does someone new to this repository need to understand before they can navigate or
contribute to it -- beyond the architecture and code patterns?** Describe the purpose and
scope of the repository, who it is for, how to navigate the key directories, and any
contribution or workflow conventions. This doc is about the *repository* as a social and
organizational artifact, not about the code's internal structure.
*(Investigate: purpose and scope of this repository, intended audience, navigation guide
for key directories and their roles, contribution guidelines or workflow conventions,
project-specific conventions that do not fit elsewhere -- e.g. naming norms, branching
strategy, release process overview.)*
**Red flags:** Duplicates architecture.md content (architectural patterns belong there).
Missing audience or navigation guidance. Placeholder or template text still present.
Focuses on code conventions instead of repository presentation (those belong in
coding-standards.md).

---

<!-- Domain-matrix extension docs (domain-doc-matrix.md): non-software-seed filenames the
     curated matrix can emit (e.g. the methodology-tooling / data-ml / content rows). Each is
     keyed by `### <filename>` so the GENERATE custom-doc extension can point an agent at it. -->

### process-architecture.md

**Describe how this process or methodology is structured, and why it is shaped that way.**
What are its major phases or stages, in what order do they run, and what governing model
connects them (a linear pipeline, a state machine, an iterative loop)? What gates or
transitions sit between stages? What must a practitioner understand about the overall
process anatomy that they could not guess from any single step?
*(Investigate: the phase/stage list and ordering, the entry/exit criteria and gates between
stages, the governing control model, where the process branches or loops back, and the
artifacts each phase consumes and produces. Ground every claim in the defining files —
process/skill/template definitions — not a generic process checklist.)*
**Operational open question:** Which phase transitions are mandatory vs optional, and what
invariants must hold across the whole process (ordering rules, single-source-of-truth
artifacts)? Surface these as an `## Invariants` section.
**Red flags:** A flat list of steps with no ordering, gates, or control model. Generic
process description not grounded in the project's own definitions. Overlaps workflow-map.md
(the connections/routing between steps belong there, not the static anatomy).

---

### workflow-map.md

**Describe how the parts of this process connect — which step, role, or tool hands off to
which, and how work flows from start to finish.** What triggers each transition? Where does
control or an artifact move between phases, agents, or tools? What are the routing rules,
and where do parallel paths, loopbacks, or escalations occur?
*(Investigate: the handoff graph between phases/steps/roles, what triggers each transition (a
gate pass, an artifact, a human decision), sequential vs parallel paths, loopbacks and
escalations, and the mapping from each process step to the tool/skill/role that executes it.
Ground claims in the routing definitions.)*
**Operational open question:** Where can the workflow stall or deadlock, and what are the
re-entry / resume rules? Surface these as a `## Re-entry & Loopbacks` section.
**Red flags:** Duplicates process-architecture.md (the static anatomy belongs there; this is
the connections and routing). Missing transition triggers. No evidence of where handoffs are
defined.

---

### authoring-conventions.md

**Describe the conventions and standards this methodology mandates for producing its own
artifacts and content.** What rules govern how its documents, definitions, or deliverables
are written, named, structured, and formatted? What style, tone, and structural rules apply,
and where are they enforced?
*(Investigate: naming conventions, document/section structure rules, formatting and style
standards, required frontmatter/metadata, any dual-audience (human + machine) rules, where
the conventions are codified (a principles/standards doc) and where they are enforced (lint,
CI, review). Ground in the convention-defining files.)*
**Operational open question:** Which conventions are enforced automatically vs by review, and
what breaks when one is violated? Surface these as an `## Enforcement` section.
**Red flags:** Generic writing advice not specific to this project's rules. Duplicates
coding-standards.md (source-code style belongs there; this is artifact/process authoring). No
evidence of where the conventions live or how they are enforced.

---

### artifact-schemas.md

**Describe the structural contracts of the artifacts this methodology produces — the required
shape of each document, record, or file type it defines.** For each artifact type: what
sections or fields are required, what is optional, what template or schema it must conform to,
and which steps or tools produce and consume it?
*(Investigate: the artifact types the methodology defines, the required vs optional
sections/fields of each, the template or schema source for each, the producer/consumer of each
artifact, and any validation rules. Ground in the template/schema files.)*
**Operational open question:** What happens when an artifact is malformed or missing a required
section — is it detected, and where? Surface this as a `## Validation` section.
**Red flags:** Prose description with no field- or section-level schema. Duplicates schemas.md
(code/data schemas belong there; this is process-artifact shapes). Missing the template source
for an artifact.

---

### quality-gates.md

**Describe how this methodology checks the quality of its work — the gates, reviews, grading,
or acceptance criteria that work must pass before it advances.** What are the gates, what does
each measure, who or what runs it, and what is the pass/fail (or grading) rule for each?
*(Investigate: each quality gate and where it sits in the process, the criteria/rubric each
applies, the grading or pass-fail mechanism, who or what executes the gate (a reviewer role, a
script, CI), what happens on failure (loopback, block), and the minimum bar. Ground in the
gate/rubric/review definitions.)*
**Operational open question:** Which gates are blocking vs advisory, and can any be overridden
— by whom? Surface these as a `## Blocking vs Advisory` section.
**Red flags:** Duplicates test-landscape.md (executable test suites belong there; this is
process/review gates). Lists gates without their criteria or pass rule. No evidence of where
the gates are defined or enforced.

---

### capability-inventory.md

**Describe what this methodology or tool does for its users — the capabilities, workflows, or
commands it offers and the value each delivers.** For each capability: what does it let a user
accomplish, when would they use it, and how is it invoked? This is the user-facing "what can
it do" catalogue.
*(Investigate: the full set of user-facing capabilities/workflows/commands, what each
accomplishes and its trigger or use-case, how each is invoked, dependencies or ordering between
capabilities, and which are core vs optional. Ground in the capability definitions —
skills/commands/workflows.)*
**Operational open question:** What is the typical end-to-end path a user follows through these
capabilities, and which are the entry points? Surface this as a `## Typical Path` section.
**Red flags:** Duplicates feature-inventory.md (software features/components belong there; this
is methodology capabilities/workflows). A bare list with no value or use-case per capability.
Missing invocation detail.

---

### decisions.md

**Describe the significant decisions that shaped this project and why they were made — the
rationale a newcomer cannot reconstruct from the artifacts alone.** For each decision: what was
decided, what alternatives were considered and rejected, why, and what constraints or
trade-offs drove it. Record decisions and their reasoning, not a restatement of the current
state.
*(Investigate: rationale-bearing decisions (architectural, process, tooling, scope), the
alternatives weighed and why they were rejected, the constraints and trade-offs, the status
(accepted/superseded) and date where recoverable, and where each decision is evidenced (commits,
design notes, ADRs, discussions). Ground each decision in its evidence.)*
**Operational open question:** Which decisions are still load-bearing (expensive to reverse) vs
superseded? Surface these as a `## Still Load-Bearing` section.
**Red flags:** Restates current state without the "why" or the rejected alternatives. Invents
rationale not grounded in evidence. Duplicates architecture.md / process-architecture.md (those
describe what *is*; this describes *why* it was chosen over alternatives).
