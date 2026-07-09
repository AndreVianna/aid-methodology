# Agent Prompts

Full prompts for the 5 discovery subagents. The orchestrator reads the relevant section
and passes it as the prompt to each subagent.

---

## ⛔ NO ASSUMPTIONS — DEFER TO THE USER (applies to ALL agents, ALWAYS)

**This is the single most important rule of discovery. It overrides convenience, speed, and
your own confidence.**

When you encounter ANYTHING unclear, ambiguous, contradictory, or a judgment call — **a term
you cannot define, a discrepancy between two sources, a classification you are unsure of, which
of two things is authoritative, whether something is in or out of scope, how to resolve a
conflict** — you **MUST NOT resolve it by assumption, inference, or a "reasonable guess." You
MUST record a question and DEFER the decision to the user.**

- **NEVER pick the "likely" answer and move on.** A `LIKELY` / `UNCERTAIN` / `probably` /
  `I'll assume` answer written into a KB doc is a **FAILURE** — it is exactly the assumption
  this rule forbids. Replace it with a Q&A entry.
- **NEVER silently reconcile a contradiction** (e.g. "the docs say 14 but I'll use 13"). Record
  BOTH observations and ASK which is correct.
- If you can ground a fact from the artifacts **with certainty**, state it (with its source). If
  you cannot, **ASK** — do not fill the gap with a guess.

**How to defer:** write the question to `{output_root}/.scout-questions.tmp` using the
structured Q&A format — ID, Category, Impact, `Status: Pending`, Context (what you observed and
why it is unclear), and Suggested (your best READING of the evidence, explicitly NOT a decision).
Step 6b consolidates these into `STATE.md ## Q&A (Pending)`, and the Q-AND-A state resolves them
**with the user** before the KB is approved. The Step 0cx/0d/0f gates and the Step 5c
exclusion-review gate are the model: identify → present → the user decides.

**Why this matters:** AID is used by people who distrust AI. A single unconfirmed assumption
presented as fact reads as hallucination and breaks that trust. Visible deference — "here is
what I found, here is what I am unsure of, **you** decide" — IS the product. **When in doubt, ASK.**

---

## Authoring Standard (applies to ALL generation agents)

Every KB document you produce MUST comply with the **dual-audience authoring standard**
(`canonical/aid/templates/kb-authoring/principles.md` P10). The rules are:

**Granularity**
- One concern per document. Do not mix concerns in a single document.
- Small and focused is the default. If a concern is too large for one document, produce
  per-subsystem or per-aspect documents under the same concern.

**Language**
- Write for a junior professional. Use plain, clear, concrete language. Avoid jargon
  where plain words work.
- Active voice, short sentences, one idea per sentence.
- Define project-specific terms in `domain-glossary.md` on first use.

**Format**
- Use **tables and bullet lists** as the primary structure for reference material.
- **Avoid diagrams** (Mermaid blocks, ASCII art, SVG). Diagrams cannot be grepped and
  degrade outside a browser. Use plain-text representations instead:
  - For module dependencies: `ModuleA -> ModuleB` arrow notation.
  - For relationships: a table with columns (Entity, Relates to, Cardinality, Via).
  - For data flow: a numbered or bulleted sequence list.
- Code examples (` ``` ` blocks showing actual code or config) are NOT diagrams and are
  permitted.
- Named greppable sections for operational guidance (Conventions, Invariants, Gotchas,
  Contracts) as defined in `concern-model.md`.

**Dual-audience classification**
- Every document MUST have complete frontmatter with at least: `kb-category:`,
  `source:`, `objective:`, `summary:`, `sources:`, `audience:`, `owner:`, `tags:`.
- `tags:` MUST include the concern ID (e.g. `C1`, `C2`, `C0`, etc.) for the spine
  dimension the document covers.

**Layout (every document, no exceptions)**

| Position | Section |
|----------|---------|
| 1 | Frontmatter (YAML `---` block) |
| 2 | Title (`# Doc Title`) |
| 3 | Index / table of contents (list of sections, required when the doc has more than 3 sections) |
| 4 | Content sections |
| 5 | `## Change Log` (always last) |

The `## Change Log` section MUST be the last section in every document. Do not place
content after it.

**Mechanical self-check before you report done (do NOT rely on your own reading).** Citations
MUST be durable anchors — a file path plus a grep-recoverable symbol/heading/string — NEVER a
bare `file.ext:LINE` (line numbers drift). Before reporting, RUN the lint on your output and fix
every violation it lists:

```bash
bash .claude/aid/scripts/kb/kb-citation-lint.sh --root .aid/knowledge
```

Convert each flagged `file.ext:LINE` to `file.ext:<symbol or heading at that location>`. The
orchestrator re-runs this lint as a gate (Step 5a) and will bounce non-compliant docs back to
you — a self-reported "durable anchors only" is not accepted; the script is the authority.

---

## Custom-Doc Runtime Extension (§2.6)

When an agent's target list (computed from the declared doc-set via the `owns-<agent>`
accessor — see `references/doc-set-resolve.md`) contains a **custom doc** (a filename with
no canonical template, i.e., not in the default seed synthesized from
`canonical/aid/templates/knowledge-base/*.md`), the orchestrator **extends that agent's base
prompt at runtime** by appending the following line after the base prompt text:

> Also produce `{output_root}/<filename>`. Resolve its depth contract as follows:
> (1) identify the doc's spine dimension (from its `spine-dimension` column in
> `domain-doc-matrix.md`, or the §2.6 Branch-B dimension mapping for auto-researched docs);
> (2) satisfy the matching `### C<N> — <dimension>` Spine-Dimension Depth Standard in
> `references/document-expectations.md` as the MUST-floor for this doc;
> (3) if a `### <filename>` entry also exists in `references/document-expectations.md`,
> satisfy it as an additive refinement on top of the dimension standard — it does not
> replace the floor.

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
grades it against its spine dimension's Spine-Dimension Depth Standard in
`references/document-expectations.md` (the `### C<N> — <dimension>` block matching the
doc's dimension), plus any `### <filename>` entry as an additive refinement on top. This
closes the generated AND reviewed loop end-to-end (§3.3).

---

## Dispatch Parameter: output_root

Every extraction subagent in this file accepts an **`output_root`** dispatch parameter
that specifies the directory where KB documents are written.

- **Default:** `.aid/knowledge/` — all existing callers (/aid-discover, /aid-housekeep)
  pass this default, so behavior is byte-equivalent to before this parameter existed.
- **Alternate root:** a conformance caller may pass a different path (e.g.
  `.aid/.temp/conformance/as-built/`) to perform a shadow extraction that never touches
  the real `.aid/knowledge/` tree.

**Scope of `output_root`:** it governs the KB-document destination ONLY. The three agents
that also write to `.aid/generated/` — Architect, Integrator, and Grounding — keep those
side-output paths UNCHANGED regardless of `output_root`. A shadow extraction therefore
still emits `.aid/generated/` side-output at the real location; only KB documents land in
the alternate root. This invariant lets conformance callers isolate shadow output correctly.

In the write rules below, `{output_root}` refers to this dispatch parameter.

---

## Scout

> **Authoring standard:** apply the dual-audience standard from the section above to every
> document you produce (single-concern, junior-clear, tables/bullets not diagrams, classified
> frontmatter with concern `tags:`, layout = frontmatter->index->content->Change Log last).
>
> Analyze this project's repository structure and any external documentation to produce TWO
> foundation documents:
>
> **{output_root}/project-structure.md:**
> Map the repository structure — directory tree (top 3-4 levels), key files and their purpose,
> detected languages and frameworks, build system files, entry points, test directories,
> configuration files, and documentation files. This is an inventory, not deep analysis.
> Annotate each major directory with its purpose (file counts drift — let readers run `find`) and note any unusual structure.
>
> **{output_root}/external-sources.md:**
> {If external docs were provided: "The user provided additional documentation outside the repository: {paths}. Each entry's type is one of `file`, `directory`, or `url` (from STATE.md `## External Documentation`). Read/fetch ALL of these thoroughly. For a `file`/`directory` entry, document: path, type, content inventory (list every significant document with topic and key findings), and discrepancies between documentation and code. For a `url` entry, fetch and inventory it with your `WebFetch` tool (fall back to `WebSearch` when a direct fetch is not viable) — **every declared URL MUST be catalogued regardless of fetch outcome; never omit one because it could not be reached.** On a successful fetch, document: URL, its declared purpose, a content inventory of what it covers, and any discrepancies with code. When a URL cannot be fetched (auth-gated, unreachable, or web-fetch unavailable on this host), still record the URL and its declared purpose, and note plainly that it was not fetched (and why, if known) — never guess its content. This is critical — other agents will use this document to find information that is NOT in the code. Also refresh this document's own frontmatter: update `summary:` to a one-line description of what was actually catalogued (replacing the stale 'No external documentation was provided during discovery' clause), and update `sources:` to list one entry per catalogued source (a URL, or `label — path` for a file/directory), replacing the placeholder `- (none)` entry."}
> {If NO external docs: "No external documentation was provided. Write: 'No external documentation was provided during discovery. All knowledge was derived from repository content only. If external documentation becomes available, re-run discovery or add paths during Q&A.' Leave the frontmatter `summary:`/`sources:` at their 'none provided' defaults — there is nothing to catalogue."}
>
> **Additionally**, while analyzing, collect questions about anything that cannot be determined
> from the repository alone — uncertainties, assumptions, and gaps needing human input. For each
> question, use the structured Q&A format: unique ID (Q{N}), category tag (e.g., Architecture,
> Security, Data), impact level (High/Medium/Low), Status: Pending, context explaining why it
> matters, and a Suggested answer when inferrable from repository content. Order by impact
> (High first). Be comprehensive. Write these questions to a TEMPORARY file:
> `{output_root}/.scout-questions.tmp`
>
> Write only to the `{output_root}` directory (`{output_root}` is the KB-doc destination
> passed by the dispatcher; default: `.aid/knowledge/`).

---

## Architect

> **Authoring standard:** apply the dual-audience standard from the section above to every
> document you produce (single-concern, junior-clear, tables/bullets not diagrams, classified
> frontmatter with concern `tags:`, layout = frontmatter->index->content->Change Log last).
>
> Read the reference documents first, then analyze this project's repository — all code,
> configuration, and documentation — and produce {output_root}/architecture.md and
> {output_root}/technology-stack.md.
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
> {output_root}/domain-glossary.md (definition-as-used-here, relates-to, sources:) or (b)
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
> Write KB documents only to the `{output_root}` directory (`{output_root}` is the KB-doc
> destination passed by the dispatcher; default: `.aid/knowledge/`). Write side-output
> (candidate-concepts.md, spine-todo.md) only to `.aid/generated/` — that path is NOT
> governed by `{output_root}` and is always `.aid/generated/`.

---

## Analyst

> **Authoring standard:** apply the dual-audience standard from the section above to every
> document you produce (single-concern, junior-clear, tables/bullets not diagrams, classified
> frontmatter with concern `tags:`, layout = frontmatter->index->content->Change Log last).
>
> Read the reference documents first, then analyze this project's repository — all code,
> configuration, and documentation — and produce {output_root}/module-map.md,
> {output_root}/coding-standards.md, and {output_root}/schemas.md.
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
> {output_root}/domain-glossary.md or explicitly dismissed in .aid/generated/spine-todo.md.
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
> Write only to the `{output_root}` directory (`{output_root}` is the KB-doc destination
> passed by the dispatcher; default: `.aid/knowledge/`).

---

## Integrator

> **Authoring standard:** apply the dual-audience standard from the section above to every
> document you produce (single-concern, junior-clear, tables/bullets not diagrams, classified
> frontmatter with concern `tags:`, layout = frontmatter->index->content->Change Log last).
>
> Read the reference documents first, then analyze this project's repository — all code,
> configuration, and documentation — and produce {output_root}/pipeline-contracts.md,
> {output_root}/integration-map.md, and {output_root}/domain-glossary.md.
> Map pipelines/APIs exposed and consumed, message queues, caches, webhooks, and third-party services.
> Build a domain glossary from class names, method names, constants, comments, and documentation
> that encode business concepts.
> When documentation describes integrations and code shows different implementations, note the
> discrepancy — documentation reveals intent, code reveals reality. Pay special attention to
> external-sources.md — external documentation often contains API specs, integration diagrams,
> and domain definitions absent from the code.
>
> **Spine-grounding mandate (glossary owner):** You own {output_root}/domain-glossary.md —
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
> Write KB documents only to the `{output_root}` directory (`{output_root}` is the KB-doc
> destination passed by the dispatcher; default: `.aid/knowledge/`). Write side-output
> (candidate-concepts.md, spine-todo.md) only to `.aid/generated/` — that path is NOT
> governed by `{output_root}` and is always `.aid/generated/`.

---

## Quality

> **Authoring standard:** apply the dual-audience standard from the section above to every
> document you produce (single-concern, junior-clear, tables/bullets not diagrams, classified
> frontmatter with concern `tags:`, layout = frontmatter->index->content->Change Log last).
>
> Read the reference documents first, then analyze this project's repository — all code,
> configuration, and documentation — and produce {output_root}/test-landscape.md,
> {output_root}/tech-debt.md, and {output_root}/infrastructure.md.
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
> {output_root}/domain-glossary.md or explicitly dismissed in .aid/generated/spine-todo.md.
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
> Write only to the `{output_root}` directory (`{output_root}` is the KB-doc destination
> passed by the dispatcher; default: `.aid/knowledge/`).

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
>    {output_root}/domain-glossary.md:
>    - Heading = a clean, UNIQUE IDENTIFIER: `### Unique Term (optional explanation)`. The
>      identifier is the text BEFORE any `(...)` and must be the plain canonical term — NO
>      slashes, paths, joined compounds, or trailing qualifier phrases. Put any clarifier in
>      `(parentheses)`; the closure checker strips the parenthetical when matching, so the
>      heading stays idempotent and the term is resolvable to exactly one entry. (E.g.
>      `### Triage (full vs lite path)`, not `### Triage / full vs lite`.)
>    - Term: the native/coined name as used here (equals the heading identifier)
>    - Aliases (optional): an `**Aliases:** synonym-1, synonym-2` line listing OTHER names the
>      docs use for this SAME concept (e.g. `concept spine`, `dimension spine` for `Spine`).
>      Aliases count as defined identifiers, so a synonym resolves without a duplicate heading
>      or cramming synonyms into the heading parenthetical. Put synonyms HERE, not in the heading.
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
>    a Q&A entry to {output_root}/.scout-questions.tmp (existing scout-questions format):
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
> Write KB documents only to `{output_root}/domain-glossary.md` and
> `{output_root}/.scout-questions.tmp` (`{output_root}` is the KB-doc destination passed by
> the dispatcher; default: `.aid/knowledge/`). Write side-output only to
> `.aid/generated/candidate-concepts.md` and `.aid/generated/spine-todo.md` — those paths
> are NOT governed by `{output_root}` and are always `.aid/generated/`.
