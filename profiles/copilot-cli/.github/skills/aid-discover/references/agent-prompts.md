# Agent Prompts

Full prompts for the 5 discovery subagents. The orchestrator reads the relevant section
and passes it as the prompt to each subagent.

---

## Custom-Doc Runtime Extension (§2.6)

When an agent's target list (computed from the declared doc-set via the `owns-<agent>`
accessor — see `references/doc-set-resolve.md`) contains a **custom doc** (a filename with
no canonical template, i.e., not in the default seed synthesized from
`.github/aid/templates/knowledge-base/*.md`), the orchestrator **extends that agent's base
prompt at runtime** by appending the following line after the base prompt text:

> Also produce `.aid/knowledge/<filename>` per its expectations entry in
> `references/document-expectations.md` (keyed by `### <filename>`).

This extension is appended once per custom doc in the agent's target list. The base prompt
text (the sections below) is never modified — the extension is a runtime-only append.

**Owner resolution:** the owning agent for a custom doc is resolved via the
`owner-of <filename>` accessor (`resolve_doc_set "$raw" | awk -F'\t' -v f="$fn" '$1==f{print $2}'`).
If the declared `owner` is one of the 5 discovery agents, the extension is appended to that
agent's prompt. If the `owner` field does not match any of the 5 agents (unknown owner), the
`resolve_doc_set` function routes to **`aid-researcher` (architecture doc-set)** as the generalist fallback
(FR-P1-5 — no new agent). The Architect prompt section is then extended as above.

**REVIEW path:** because a custom doc appears in the `list-filenames` accessor output (it is
in the declared set), the REVIEW state's artifact list includes it and the `aid-reviewer`
grades it against its `document-expectations.md` entry (keyed by `### <filename>`). This
closes the generated AND reviewed loop end-to-end (§3.3).

---

## Scout

> Analyze this project's repository structure and any external documentation to produce TWO
> foundation documents:
>
> **.aid/knowledge/project-structure.md:**
> Map the repository structure — directory tree (top 3-4 levels), key files and their purpose,
> detected languages and frameworks, build system files, entry points, test directories,
> configuration files, and documentation files. This is an inventory, not deep analysis.
> Annotate each major directory with its purpose (file counts drift — let readers run `find`) and note any unusual structure.
>
> **.aid/knowledge/external-sources.md:**
> {If external docs were provided: "The user provided additional documentation outside the repository: {paths}. Read ALL of these thoroughly. For each source, document: path, type (file/directory), content inventory (list every significant document with topic and key findings), and discrepancies between documentation and code. This is critical — other agents will use this document to find information that is NOT in the code."}
> {If NO external docs: "No external documentation was provided. Write: 'No external documentation was provided during discovery. All knowledge was derived from repository content only. If external documentation becomes available, re-run discovery or add paths during Q&A.'"}
>
> **Additionally**, while analyzing, collect questions about anything that cannot be determined
> from the repository alone — uncertainties, assumptions, and gaps needing human input. For each
> question, use the structured Q&A format: unique ID (Q{N}), category tag (e.g., Architecture,
> Security, Data), impact level (High/Medium/Low), Status: Pending, context explaining why it
> matters, and a Suggested answer when inferrable from repository content. Order by impact
> (High first). Be comprehensive. Write these questions to a TEMPORARY file:
> `.aid/knowledge/.scout-questions.tmp`
>
> Write only to the .aid/knowledge/ directory.

---

## Architect

> Read the reference documents first, then analyze this project's repository — all code,
> configuration, and documentation — and produce .aid/knowledge/architecture.md and
> .aid/knowledge/technology-stack.md.
> Cover: project type, folder structure, architectural patterns, module boundaries, data flow,
> DI registration, entry points, tech stack (languages, frameworks, versions, package managers,
> runtime, build tools, dev tooling).
> When repository documentation describes intended architecture and code shows different
> implementation, note the discrepancy — documentation reveals intent, code reveals reality.
> Both are valuable. Pay special attention to external-sources.md — external documentation
> often contains architecture decisions and design rationale absent from the code.
>
> **Conceptual-synthesis mandate (Step 5b, aid-discover f004):** In addition to the standard
> deep-dive, you own the conceptual-synthesis channel. Propose load-bearing concepts that have
> NO stable recurring coined token — ideas spread across prose that the lexical harvest could
> not fingerprint. For EVERY proposed synthesis concept you MUST cite the supporting source
> span(s) (path + grep-recoverable distinct string) that the concept was inferred from. An
> uncited synthesis proposal is INVALID and must be rejected, not stored. Merge accepted
> concepts into .aid/generated/candidate-concepts.md as synthesis-tagged rows (Source =
> synthesis; Example source = the mandatory cited span). This runs once at the start of Step
> 5b's closure loop, after you have read the full deep-dive KB docs.
>
> **Spine-grounding mandate:** Every candidate-concept term in
> .aid/generated/candidate-concepts.md (both harvest and synthesis rows) that you encounter
> while writing your documents MUST be either (a) grounded into a concept entry in
> .aid/knowledge/domain-glossary.md (definition-as-used-here, relates-to, sources:) or (b)
> explicitly dismissed as not-a-load-bearing-concept with a one-line reason recorded in
> .aid/generated/spine-todo.md. No candidate is silently dropped.
>
> **Can't-explain-it tripwire:** Any project-specific term you reach for while explaining the
> architecture that you cannot confidently define from general knowledge is a MANDATORY
> investigation — ground it from the artifacts or escalate it to Q&A; never skip it as noise.
> This includes terms that appear in candidate-concepts.md AND any term you encounter in
> ADRs/reports/commit prose that recurs but has no clear general-knowledge definition.
>
> REFERENCE DOCUMENTS (read these FIRST before analyzing):
> - .aid/generated/project-index.md — full file inventory with metadata (sizes, languages, mtimes, notable files)
> - .aid/generated/candidate-concepts.md — ranked candidate concepts; ground or dismiss every row
> - .aid/knowledge/project-structure.md — repository structure map (architectural narrative)
> - .aid/knowledge/external-sources.md — external documentation inventory and findings
> Use these to orient your analysis. External sources may contain information directly relevant
> to YOUR documents that is NOT in the code. Cross-reference external findings with code reality
> and note any discrepancies.
>
> Write only to the .aid/knowledge/ and .aid/generated/ directories.

---

## Analyst

> Read the reference documents first, then analyze this project's repository — all code,
> configuration, and documentation — and produce .aid/knowledge/module-map.md,
> .aid/knowledge/coding-standards.md, and .aid/knowledge/schemas.md.
> Map every module (purpose, size, dependencies, test coverage).
> Mine coding conventions from actual code — naming, error handling, logging, config, file
> organization. Extract data schemas: schemas, relationships, migrations, indexes, validation.
> When repository documentation describes conventions and code shows different patterns, note
> the discrepancy — documentation reveals intent, code reveals reality. Pay special attention
> to external-sources.md — external documentation often contains coding standards and data
> model definitions absent from the code.
>
> **Spine-grounding mandate:** Every candidate-concept term in
> .aid/generated/candidate-concepts.md (both harvest and synthesis rows) that you encounter
> while writing your documents MUST be either grounded into a concept entry in
> .aid/knowledge/domain-glossary.md or explicitly dismissed in .aid/generated/spine-todo.md.
> No candidate is silently dropped.
>
> **Can't-explain-it tripwire:** Any project-specific term you reach for while explaining the
> modules, standards, or schemas that you cannot confidently define from general knowledge is a
> MANDATORY investigation — ground it from the artifacts or escalate it to Q&A; never skip it
> as noise. Follow the candidate's Example source anchor into the why-source (ADR/report/commit)
> when grounding it.
>
> REFERENCE DOCUMENTS (read these FIRST before analyzing):
> - .aid/generated/project-index.md — full file inventory with metadata (sizes, languages, mtimes, notable files)
> - .aid/generated/candidate-concepts.md — ranked candidate concepts; ground or dismiss every row you use
> - .aid/knowledge/project-structure.md — repository structure map (architectural narrative)
> - .aid/knowledge/external-sources.md — external documentation inventory and findings
> Use these to orient your analysis. External sources may contain information directly relevant
> to YOUR documents that is NOT in the code. Cross-reference external findings with code reality
> and note any discrepancies.
>
> Write only to the .aid/knowledge/ directory.

---

## Integrator

> Read the reference documents first, then analyze this project's repository — all code,
> configuration, and documentation — and produce .aid/knowledge/pipeline-contracts.md,
> .aid/knowledge/integration-map.md, and .aid/knowledge/domain-glossary.md.
> Map pipelines/APIs exposed and consumed, message queues, caches, webhooks, and third-party services.
> Build a domain glossary from class names, method names, constants, comments, and documentation
> that encode business concepts.
> When documentation describes integrations and code shows different implementations, note the
> discrepancy — documentation reveals intent, code reveals reality. Pay special attention to
> external-sources.md — external documentation often contains API specs, integration diagrams,
> and domain definitions absent from the code.
>
> **Spine-grounding mandate (glossary owner):** You own .aid/knowledge/domain-glossary.md —
> the concept spine. Every candidate-concept term in .aid/generated/candidate-concepts.md
> (BOTH harvest and synthesis rows) MUST be driven to a terminal state before closure:
> (a) GROUNDED — produce a concept entry in domain-glossary.md with definition-as-used-here
> (what the term means in THIS project, not a generic definition), relates-to (how it connects
> to other spine concepts), and sources: (path + grep-recoverable anchor per f001 schema); OR
> (b) DISMISSED — record a one-line reason in .aid/generated/spine-todo.md (generated-identifier
> dump, vendored token, etc.). No candidate is silently dropped. New native terms discovered
> during grounding are appended to candidate-concepts.md (Source = synthesis, with cited span)
> and to spine-todo.md (Status: OPEN).
>
> **Can't-explain-it tripwire:** Any project-specific term you reach for while explaining
> pipelines, integrations, or domain concepts that you cannot confidently define from general
> knowledge is a MANDATORY investigation — ground it from the artifacts or escalate it to Q&A;
> never skip it as noise. This applies to terms in candidate-concepts.md AND to terms you
> encounter in API specs/ADRs/integration diagrams that recur but have no clear
> general-knowledge definition.
>
> REFERENCE DOCUMENTS (read these FIRST before analyzing):
> - .aid/generated/project-index.md — full file inventory with metadata (sizes, languages, mtimes, notable files)
> - .aid/generated/candidate-concepts.md — ranked candidate concepts; ground or dismiss EVERY row
> - .aid/generated/spine-todo.md — work-list tracking terminal state of each candidate
> - .aid/knowledge/project-structure.md — repository structure map (architectural narrative)
> - .aid/knowledge/external-sources.md — external documentation inventory and findings
> Use these to orient your analysis. External sources may contain information directly relevant
> to YOUR documents that is NOT in the code. Cross-reference external findings with code reality
> and note any discrepancies.
>
> Write only to the .aid/knowledge/ and .aid/generated/ directories.

---

## Quality

> Read the reference documents first, then analyze this project's repository — all code,
> configuration, and documentation — and produce .aid/knowledge/test-landscape.md,
> .aid/knowledge/tech-debt.md, and .aid/knowledge/infrastructure.md.
> Assess test frameworks, test types, coverage, CI/CD integration.
> Audit tech debt: large files, TODO/FIXME density, missing tests, outdated packages, dead code.
> Classify all debt items with risk ratings (Critical/High/Medium/Low).
> Security authoring conventions are in coding-standards.md §11 — note any security-relevant
> observations as tech-debt items rather than a separate security-model document.
> Map CI/CD pipelines, Docker/container config, IaC (Terraform, Pulumi, CDK), environments,
> and monitoring.
> When documentation describes testing strategy, security policies, or infrastructure and
> code shows different reality, note the discrepancy — both are valuable findings. Pay special
> attention to external-sources.md — external documentation often contains security policies,
> compliance requirements, deployment guides, and test strategies absent from the code.
>
> **Spine-grounding mandate:** Every candidate-concept term in
> .aid/generated/candidate-concepts.md (both harvest and synthesis rows) that you encounter
> while writing your documents MUST be either grounded into a concept entry in
> .aid/knowledge/domain-glossary.md or explicitly dismissed in .aid/generated/spine-todo.md.
> No candidate is silently dropped.
>
> **Can't-explain-it tripwire:** Any project-specific term you reach for while explaining
> the test landscape, tech debt, or infrastructure that you cannot confidently define from
> general knowledge is a MANDATORY investigation — ground it from the artifacts or escalate
> it to Q&A; never skip it as noise. Follow the candidate's Example source anchor into the
> why-source (ADR/report/commit) when grounding it.
>
> REFERENCE DOCUMENTS (read these FIRST before analyzing):
> - .aid/generated/project-index.md — full file inventory with metadata (sizes, languages, mtimes, notable files)
> - .aid/generated/candidate-concepts.md — ranked candidate concepts; ground or dismiss every row you use
> - .aid/knowledge/project-structure.md — repository structure map (architectural narrative)
> - .aid/knowledge/external-sources.md — external documentation inventory and findings
> Use these to orient your analysis. External sources may contain information directly relevant
> to YOUR documents that is NOT in the code. Cross-reference external findings with code reality
> and note any discrepancies.
>
> Write only to the .aid/knowledge/ directory.

---

## Grounding

> You are a grounding sub-agent dispatched by the SYNTHESIS + CLOSURE loop (Step 5b of
> aid-discover). Your task: ground ONE candidate-concept term (or a small chunk of terms,
> as specified) into a concept entry in the project's concept spine.
>
> **Your assigned term(s):** {TERM_LIST}
>
> **Your task for each term:**
>
> 1. Read the KB docs (.aid/knowledge/*.md), the concept spine
>    (.aid/knowledge/domain-glossary.md), external sources
>    (.aid/knowledge/external-sources.md), and the term's Example source anchor in
>    .aid/generated/candidate-concepts.md.
>
> 2. Follow the Example source anchor into the why-source (ADR/report/commit prose) to
>    understand what the term means in this project specifically.
>
> 3. If you can ground the term from the artifacts, write a concept entry in
>    .aid/knowledge/domain-glossary.md:
>    - Term: the native/coined name as used here
>    - Definition-as-used-here: what it means in THIS project (NOT a generic definition —
>      a generic definition is negative value; only the project-specific meaning is stored)
>    - Relates-to: how it connects to other spine concepts (cross-cutting linkage)
>    - sources: the files/anchors that ground it (path + grep-recoverable distinct string,
>      per f001 schema — same durable-anchor convention the harvest uses)
>    Then mark the term as GROUNDED in .aid/generated/spine-todo.md.
>
> 4. If you discover a NEW native term during grounding (understanding is recursive):
>    append it to .aid/generated/candidate-concepts.md (Source = synthesis; Class =
>    synthesis; Example source = a cited supporting span — MANDATORY) and to
>    .aid/generated/spine-todo.md (Status: OPEN). Do NOT ground it yourself in this pass —
>    it re-enters the loop for the next DETECT pass.
>
> 5. If the term CANNOT be grounded from any artifact after thorough investigation, write
>    a Q&A entry to .aid/knowledge/.scout-questions.tmp (existing scout-questions format):
>    - Category: Concept
>    - Impact: High
>    - Status: Pending
>    - Context: where the term recurs (its candidate-concepts.md anchor) + why it could not
>      be grounded
>    - Suggested: the best partial inference from artifacts, or "—"
>    - Question: "What does `{term}` mean in this project? Where is it defined or described?"
>    Then mark the term as DISMISSED in .aid/generated/spine-todo.md with disposition
>    "Ungroundable — escalated to Q&A".
>
> **Can't-explain-it tripwire:** If while investigating you reach for another project-specific
> term that you cannot confidently define from general knowledge, treat IT as a mandatory
> investigation too — append it to candidate-concepts.md and spine-todo.md (Status: OPEN).
> Never skip an ungrounded project-specific term as noise.
>
> Write only to .aid/knowledge/domain-glossary.md, .aid/knowledge/.scout-questions.tmp,
> .aid/generated/candidate-concepts.md, and .aid/generated/spine-todo.md.
