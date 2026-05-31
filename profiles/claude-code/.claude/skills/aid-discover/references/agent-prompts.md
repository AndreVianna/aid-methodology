# Agent Prompts

Full prompts for the 5 discovery subagents. The orchestrator reads the relevant section
and passes it as the prompt to each subagent.

---

## Custom-Doc Runtime Extension (§2.6)

When an agent's target list (computed from the declared doc-set via the `owns-<agent>`
accessor — see `references/doc-set-resolve.md`) contains a **custom doc** (a filename with
no canonical template, i.e., not in the default seed synthesized from
`.claude/templates/knowledge-base/*.md`), the orchestrator **extends that agent's base
prompt at runtime** by appending the following line after the base prompt text:

> Also produce `.aid/knowledge/<filename>` per its expectations entry in
> `references/document-expectations.md` (keyed by `### <filename>`).

This extension is appended once per custom doc in the agent's target list. The base prompt
text (the sections below) is never modified — the extension is a runtime-only append.

**Owner resolution:** the owning agent for a custom doc is resolved via the
`owner-of <filename>` accessor (`resolve_doc_set "$raw" | awk -F'\t' -v f="$fn" '$1==f{print $2}'`).
If the declared `owner` is one of the 5 discovery agents, the extension is appended to that
agent's prompt. If the `owner` field does not match any of the 5 agents (unknown owner), the
`resolve_doc_set` function routes to **`discovery-architect`** as the generalist fallback
(FR-P1-5 — no new agent). The architect base prompt is then extended as above.

**REVIEW path:** because a custom doc appears in the `list-filenames` accessor output (it is
in the declared set), the REVIEW state's artifact list includes it and the `discovery-reviewer`
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
> REFERENCE DOCUMENTS (read these FIRST before analyzing):
> - .aid/knowledge/project-index.md — full file inventory with metadata (sizes, languages, mtimes, notable files)
> - .aid/knowledge/project-structure.md — repository structure map (architectural narrative)
> - .aid/knowledge/external-sources.md — external documentation inventory and findings
> Use these to orient your analysis. External sources may contain information directly relevant
> to YOUR documents that is NOT in the code. Cross-reference external findings with code reality
> and note any discrepancies.
>
> Write only to the .aid/knowledge/ directory.

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
> REFERENCE DOCUMENTS (read these FIRST before analyzing):
> - .aid/knowledge/project-index.md — full file inventory with metadata (sizes, languages, mtimes, notable files)
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
> REFERENCE DOCUMENTS (read these FIRST before analyzing):
> - .aid/knowledge/project-index.md — full file inventory with metadata (sizes, languages, mtimes, notable files)
> - .aid/knowledge/project-structure.md — repository structure map (architectural narrative)
> - .aid/knowledge/external-sources.md — external documentation inventory and findings
> Use these to orient your analysis. External sources may contain information directly relevant
> to YOUR documents that is NOT in the code. Cross-reference external findings with code reality
> and note any discrepancies.
>
> Write only to the .aid/knowledge/ directory.

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
> REFERENCE DOCUMENTS (read these FIRST before analyzing):
> - .aid/knowledge/project-index.md — full file inventory with metadata (sizes, languages, mtimes, notable files)
> - .aid/knowledge/project-structure.md — repository structure map (architectural narrative)
> - .aid/knowledge/external-sources.md — external documentation inventory and findings
> Use these to orient your analysis. External sources may contain information directly relevant
> to YOUR documents that is NOT in the code. Cross-reference external findings with code reality
> and note any discrepancies.
>
> Write only to the .aid/knowledge/ directory.
