#!/usr/bin/env python3
"""Build knowledge-summary.html — pipeline-focused rewrite per user 2026-05-21."""
from datetime import date
from pathlib import Path
import html

ROOT = Path(r"C:\Projects\Personal\AID\.claude\worktrees\aid-init")
KB = ROOT / ".aid" / "knowledge"
TMPL = ROOT / ".aid" / "templates" / "knowledge-summary"
BUILD = ROOT / ".aid" / "build"
BUILD.mkdir(parents=True, exist_ok=True)

PROJECT = "AID"
LANG = "en"
GEN_DATE = date.today().isoformat()
MERMAID_VER = "11.15.0"

skeleton = (TMPL / "html-skeleton.html").read_text(encoding="utf-8")
css = (TMPL / "component-css.css").read_text(encoding="utf-8")
lightbox = (TMPL / "lightbox.js").read_text(encoding="utf-8")

# ---------------------------------------------------------------------------
# 9 Mermaid figures — pipeline-focused
# ---------------------------------------------------------------------------

FIG1 = """flowchart TB
    classDef setup  fill:#E3E8EF,stroke:#667085,color:#101828,stroke-dasharray:3 3;
    classDef phase  fill:#0E4D4A,stroke:#00A3A1,color:#fff,stroke-width:2px;
    classDef opt    fill:#E3E8EF,stroke:#667085,color:#101828,stroke-dasharray:3 3;

    subgraph Define[" Group 1 - Define "]
        Init["aid-init<br/>(setup — not a phase)"]:::setup
        Disc["1. aid-discover<br/>(brownfield)"]:::phase
        Intv["2. aid-interview"]:::phase
        Spec["3. aid-specify<br/>(per feature)"]:::phase
        Sum["aid-summarize<br/>(optional — not a phase)"]:::opt
    end
    subgraph MapG[" Group 2 - Map "]
        Plan["4. aid-plan"]:::phase
        Det["5. aid-detail<br/>(typed tasks)"]:::phase
    end
    subgraph ExeG[" Group 3 - Execute "]
        Exe["6. aid-execute<br/>(8 task types)"]:::phase
    end
    subgraph Deliver[" Group 4 - Deliver "]
        Dep["7. aid-deploy"]:::phase
        Mon["8. aid-monitor"]:::phase
    end

    Init --> Disc --> Intv --> Spec --> Plan --> Det --> Exe --> Dep --> Mon"""

FIG2 = """flowchart LR
    classDef in   fill:#DBEAFE,stroke:#1D4ED8,color:#1D4ED8;
    classDef agent fill:#0E4D4A,stroke:#00A3A1,color:#fff,stroke-width:2px;
    classDef out  fill:#E8F5E9,stroke:#2E7D32,color:#2E7D32;
    classDef kb   fill:#F4EBFF,stroke:#6941C6,color:#6941C6;

    subgraph Inputs[" Inputs "]
        Code["Target codebase"]:::in
        ExtURL["8 vendor doc URLs<br/>(external-sources.md)"]:::in
        PI["project-index.md<br/>(pre-pass)"]:::in
    end

    subgraph Dispatch[" Skill dispatches 6 sub-agents "]
        Scout["discovery-scout<br/>(runs alone first)"]:::agent
        Arch["discovery-architect"]:::agent
        Anly["discovery-analyst"]:::agent
        Intg["discovery-integrator"]:::agent
        Qual["discovery-quality"]:::agent
        Rev["discovery-reviewer<br/>(separate context)"]:::agent
    end

    subgraph KB[" Writes to .aid/knowledge/ "]
        Docs["16 KB docs<br/>+ INDEX + README"]:::kb
        DS["DISCOVERY-STATE.md<br/>(grade + Q&A + Issues)"]:::kb
    end

    Code --> Scout
    Code --> Arch
    Code --> Anly
    Code --> Intg
    Code --> Qual
    PI --> Scout
    PI --> Arch
    PI --> Anly
    PI --> Intg
    PI --> Qual
    ExtURL -. "deferred fetch" .-> Scout

    Scout --> Docs
    Arch --> Docs
    Anly --> Docs
    Intg --> Docs
    Qual --> Docs

    Docs --> Rev
    Rev --> DS"""

FIG3 = """graph TD
    classDef center fill:#0B1F3A,stroke:#00A3A1,color:#fff,stroke-width:2px;
    classDef std    fill:#0E4D4A,stroke:#00A3A1,color:#fff,stroke-width:2px;
    classDef meta   fill:#DBEAFE,stroke:#1D4ED8,color:#1D4ED8;
    classDef gen    fill:#E8F5E9,stroke:#2E7D32,color:#2E7D32;
    classDef ext    fill:#FEF3C7,stroke:#B45309,color:#B45309;

    KB[(".aid/knowledge/<br/>21 files total")]:::center

    Standard["16 standard KB docs<br/>(load-bearing for downstream skills)"]:::std
    Meta["3 meta-documents<br/>INDEX + README + DISCOVERY-STATE"]:::meta
    Gen["1 generated pre-pass<br/>project-index.md (from build-project-index.sh)"]:::gen
    Ext["KB extensions (outside the 16)<br/>currently: host-tools-matrix.md"]:::ext

    KB --> Standard
    KB --> Meta
    KB --> Gen
    KB --> Ext

    Std1["project-structure / external-sources<br/>(scout)"]:::std
    Std2["architecture / technology-stack / ui-architecture<br/>(architect)"]:::std
    Std3["module-map / coding-standards / data-model<br/>(analyst)"]:::std
    Std4["api-contracts / integration-map / domain-glossary<br/>(integrator)"]:::std
    Std5["test-landscape / security-model / tech-debt / infrastructure<br/>(quality)"]:::std
    Std6["feature-inventory<br/>(orchestrator, post-Q&A)"]:::std

    Standard --> Std1
    Standard --> Std2
    Standard --> Std3
    Standard --> Std4
    Standard --> Std5
    Standard --> Std6"""

FIG4 = """graph TB
    classDef opus   fill:#0B1F3A,stroke:#00A3A1,color:#fff,stroke-width:2px;
    classDef sonnet fill:#0E4D4A,stroke:#00A3A1,color:#fff,stroke-width:2px;
    classDef haiku  fill:#DBEAFE,stroke:#1D4ED8,color:#1D4ED8;

    subgraph OpusTier[" Opus tier — 10 agents (gpt-5.5 / high) "]
        OC["Core (3): architect, reviewer, interviewer"]:::opus
        OS["Specialist (1): security"]:::opus
        OD["Discovery sub-agents (6): scout, architect, analyst, integrator, quality, reviewer"]:::opus
    end

    subgraph SonnetTier[" Sonnet tier — 9 agents (gpt-5.4 / medium) "]
        SC["Core (4): orchestrator, researcher, developer, operator"]:::sonnet
        SS["Specialist (5): data-engineer, performance, devops, tech-writer, ux-designer"]:::sonnet
    end

    subgraph HaikuTier[" Haiku tier — 3 agents (gpt-5.4-mini / low) "]
        HU["Utility (3): simple-extractor, simple-formatter, simple-glob<br/>(mechanical work only — never synthesis)"]:::haiku
    end

    Total["Total: 22 agents per install tree<br/>tier-consistent across Claude Code + Codex + Cursor<br/>verified post-May-2026 migration"]"""

FIG5 = """graph LR
    classDef skill fill:#0B1F3A,stroke:#00A3A1,color:#fff,stroke-width:2px;
    classDef opus  fill:#0B1F3A,stroke:#00A3A1,color:#fff;
    classDef sonnet fill:#0E4D4A,stroke:#00A3A1,color:#fff,stroke-width:2px;
    classDef haiku fill:#DBEAFE,stroke:#1D4ED8,color:#1D4ED8;

    AidDisc["/aid-discover"]:::skill --> DispDisc["6 discovery sub-agents<br/>(all Opus)"]:::opus
    AidIntv["/aid-interview"]:::skill --> Interv["Interviewer<br/>(Opus)"]:::opus
    AidSpec["/aid-specify"]:::skill --> ArchA["Architect<br/>(Opus)"]:::opus
    AidPlan["/aid-plan"]:::skill --> ArchB["Architect<br/>(Opus)"]:::opus
    AidDet["/aid-detail"]:::skill --> ArchC["Architect<br/>(Opus)"]:::opus
    AidExe["/aid-execute"]:::skill --> Dev["Developer<br/>(Sonnet, default)"]:::sonnet
    AidExe -. "task-type-routed" .-> Spec["Specialist agents<br/>(Sonnet, e.g., Data Engineer for DATA tasks)"]:::sonnet
    AidExe -. "review" .-> Rev["Reviewer<br/>(Opus, tier ≥ Executor invariant)"]:::opus
    AidDep["/aid-deploy"]:::skill --> Ops["Operator<br/>(Sonnet)"]:::sonnet
    AidMon["/aid-monitor"]:::skill --> Orch["Orchestrator<br/>(Sonnet)"]:::sonnet
    Util["Utility sub-agents (Haiku)<br/>simple-extractor, -formatter, -glob"]:::haiku -. "internal-only, never user-invoked" .-> AnyAgent["any higher-tier agent"]"""

FIG6 = """flowchart LR
    classDef in fill:#DBEAFE,stroke:#1D4ED8,color:#1D4ED8;
    classDef proc fill:#0E4D4A,stroke:#00A3A1,color:#fff,stroke-width:2px;
    classDef out fill:#E8F5E9,stroke:#2E7D32,color:#2E7D32;
    classDef feedback fill:#FEF3C7,stroke:#B45309,color:#B45309;

    KB["KB<br/>(updated continuously)"]:::in
    REQ["REQUIREMENTS.md<br/>(per project)"]:::proc
    SPEC["per-feature SPEC.md"]:::proc
    PLAN["PLAN.md<br/>(ordered deliveries)"]:::proc
    DET["DETAIL.md +<br/>task-{id}.md (8 types)"]:::proc
    IMPL["IMPLEMENTATION-STATE.md<br/>(per task)"]:::proc
    DEPL["package-NNN.md +<br/>DEPLOYMENT-STATE.md"]:::out
    MON["MONITOR-STATE.md +<br/>track-report-*.md"]:::out

    GAP["GAP.md /<br/>IMPEDIMENT.md /<br/>KNOWN-ISSUES.md"]:::feedback

    KB --> REQ --> SPEC --> PLAN --> DET --> IMPL --> DEPL --> MON
    MON -. "BUG / CR" .-> KB

    IMPL -. "executor escalation" .-> GAP
    DET -. "plan-too-vague" .-> GAP
    GAP -. "feeds back to" .-> KB"""

FIG7 = """stateDiagram-v2
    [*] --> GENERATE: fresh project
    GENERATE --> REVIEW: 16 KB docs populated
    REVIEW --> Q_AND_A: Issues + Q&A captured
    Q_AND_A --> FIX: all Pending resolved (Answer / Skip)
    FIX --> REVIEW: re-dispatch reviewer (clean context)
    REVIEW --> APPROVAL: grade >= minimum
    APPROVAL --> DONE: user approves
    APPROVAL --> Q_AND_A: user adds consideration
    DONE --> [*]

    GENERATE: GENERATE<br/>(1 scout alone first,<br/>then 4 parallel sub-agents)
    REVIEW: REVIEW<br/>(discovery-reviewer<br/>grades A+ - F)
    Q_AND_A: Q&A<br/>(auto-answer trivial,<br/>user-decide strategic)
    FIX: FIX<br/>(apply Q&A answers to<br/>KB docs, REMOVE issues)
    APPROVAL: APPROVAL<br/>(user gate)
    DONE: DONE<br/>(User Approved: yes)"""

FIG8 = """graph TB
    classDef canon fill:#0B1F3A,stroke:#00A3A1,color:#fff,stroke-width:2px;
    classDef tree  fill:#0E4D4A,stroke:#00A3A1,color:#fff,stroke-width:2px;
    classDef sync  fill:#FEF3C7,stroke:#B45309,color:#B45309;

    Canon["Canonical sources<br/>methodology/ + skills/ + agents/ + templates/<br/>(human-readable)"]:::canon

    CC["claude-code/.claude/<br/>22 .md agents + 10 SKILL.md + templates"]:::tree
    CX["codex/.codex/agents/ + codex/.agents/<br/>22 .toml agents + 10 SKILL.md (inlined) + templates"]:::tree
    CR["cursor/.cursor/<br/>22 .md agents + 10 SKILL.md (inlined) + 2 .mdc rules + templates"]:::tree

    Sync["⚠️ Manual cross-tree sync<br/>(CONTRIBUTING.md:21-26 — needs Cursor add per Q34/Q72)<br/>~36% of repo is 4-way duplicated"]:::sync

    Canon --> CC
    Canon --> CX
    Canon --> CR
    CC <-. drift risk .-> Sync
    CX <-. drift risk .-> Sync
    CR <-. drift risk .-> Sync

    Future["Future targets:<br/>Copilot CLI, Antigravity<br/>(no install tree yet)"]
    Canon -. "aspirational" .-> Future"""

FIG9 = """flowchart TB
    classDef ctx  fill:#0B1F3A,stroke:#00A3A1,color:#fff,stroke-width:2px;
    classDef tier fill:#0E4D4A,stroke:#00A3A1,color:#fff,stroke-width:2px;
    classDef repo fill:#E3E8EF,stroke:#667085,color:#101828;

    Agent["Agent task context<br/>(kept lean — pays only for what a task needs)"]:::ctx

    subgraph T1[" Tier 1 - always loaded "]
        IDX["INDEX.md<br/>2-3 line summary of every KB doc<br/>(~200-500 tokens total)"]:::tier
    end
    subgraph T2[" Tier 2 - loaded on demand "]
        DOC["one specific KB document<br/>16 standard + 3 meta + extensions<br/>(fixed-shape — navigate by convention)"]:::tier
    end
    subgraph T3[" Tier 3 - pinpointed, never bulk-loaded "]
        REPO["exact file + line in the repo<br/>via inline path:line citation<br/>(49,226-line repository)"]:::repo
    end

    Agent --> IDX
    IDX -- "agent picks the one doc it needs" --> DOC
    DOC -- "agent jumps to path:line" --> REPO"""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def figure(num: int, title: str, mermaid: str, caption: str) -> str:
    src = html.escape(mermaid)
    return f'''<figure class="diagram" id="fig{num}">
  <div class="mermaid-box" tabindex="0" role="button" aria-label="Expand Figure {num}: {html.escape(title)}">
    <pre class="mermaid">{src}</pre>
  </div>
  <figcaption><strong>Figure {num}.</strong> {html.escape(caption)}</figcaption>
</figure>'''

def section(num: int, anchor: str, title: str, body_html: str, featured: bool = False) -> str:
    cls = ' class="featured"' if featured else ""
    star = " ★" if featured else ""
    return f'''<section id="{anchor}"{cls}>
<h2>{num}. {html.escape(title)}{star}</h2>
{body_html}
</section>'''

# ---------------------------------------------------------------------------
# Sections — pipeline-first
# ---------------------------------------------------------------------------

s1 = section(1, "at-a-glance", "At a Glance", '''<p><strong>AID — AI-Integrated Development</strong> is a methodology for building software with AI agents across the full lifecycle. The repository ships the methodology spec + install bundles for three AI coding tools (Claude Code, Codex CLI, Cursor); adopters install AID into their target project, then run the AID pipeline.</p>

<p class="meta">This summary is itself a dogfood artifact — generated by AID's own <code>/aid-summarize</code> skill from the Knowledge Base produced by AID's own <code>/aid-discover</code> against AID's own repo.</p>

<table>
  <tbody>
    <tr><th scope="row">What it is</th><td>Methodology + multi-tool install bundle. No deployable runtime.</td></tr>
    <tr><th scope="row">Pipeline</th><td><strong>10 SKILL files</strong> = 1 setup (Init) + 8 development phases + 1 optional (Summarize) per user-confirmed Q16 canonical taxonomy.</td></tr>
    <tr><th scope="row">Knowledge Base</th><td><strong>The gravitational center.</strong> 16 standard docs + 3 meta + 1 generated + extensions. Every phase reads it; every phase may revise it via formal feedback loops.</td></tr>
    <tr><th scope="row">Agents</th><td>22 per install tree = 7 Core + 6 Specialist + 3 Utility (Haiku) + 6 Discovery sub-agents. Tier-consistent across all 3 trees.</td></tr>
    <tr><th scope="row">Three convictions</th><td>(1) Understanding precedes specification — drives Discovery as Phase 1, brownfield-first. (2) Specs are hypotheses, not contracts — feedback loops let any phase revise upstream. (3) The KB is the gravitational center — not the spec, not the code; the accumulated living understanding.</td></tr>
    <tr><th scope="row">Distribution</th><td><code>git clone</code> + interactive <code>setup.sh</code> / <code>setup.ps1</code>. Tagged GitHub Releases planned (Q1/R1).</td></tr>
    <tr><th scope="row">KB grade</th><td>A+ (user-approved 2026-05-21 after 10 review cycles)</td></tr>
  </tbody>
</table>''')

s2 = section(2, "the-pipeline", "The AID Pipeline", f'''<p>The pipeline of <strong>10 SKILL files</strong> — 1 setup (Init) + 8 development phases + 1 optional (Summarize), per the KB's canonical Q16 taxonomy — is the core of AID. The Knowledge Base sits at the center; every phase reads it, and any phase can revise it via formal feedback loops (10 numbered + 1 "any phase → targeted Discovery"). The linear path is the default; the feedback loops are the escape hatches that prevent silent workarounds.</p>

{figure(1, "Pipeline overview — the 4 groups, forward flow", FIG1, "The forward pipeline — skill to skill — organized into the 4 groups from the methodology README: Group 1 Define, Group 2 Map, Group 3 Execute, Group 4 Deliver. Each group is a teal subgraph. The 8 development phases are numbered 1-8 (dark teal); aid-init (setup) and aid-summarize (optional) are dashed — skills but not phases. Only the forward path is drawn; the feedback loops and Monitor return paths are described in 'The 11 feedback loops' below, kept off the diagram for legibility.")}

<h3>The 4 groups — setup skill + 8 development phases + optional skill</h3>
<table>
  <thead><tr><th>Group</th><th>#</th><th>Phase</th><th>Skill</th><th>Default agent</th><th>Primary output</th></tr></thead>
  <tbody>
    <tr><td>—</td><td>—</td><td>Init (setup, runs once)</td><td><code>/aid-init</code></td><td>(scaffolding)</td><td><code>.aid/</code> structure, KB placeholders, CLAUDE.md/AGENTS.md</td></tr>
    <tr><td rowspan="3"><strong>1 · Define</strong></td><td>1</td><td>Discover</td><td><code>/aid-discover</code></td><td>6 Discovery sub-agents (Opus) + Reviewer</td><td>16 KB docs + DISCOVERY-STATE.md</td></tr>
    <tr><td>2</td><td>Interview</td><td><code>/aid-interview</code></td><td>Interviewer (Opus)</td><td>REQUIREMENTS.md, per-feature SPEC.md</td></tr>
    <tr><td>3</td><td>Specify</td><td><code>/aid-specify</code></td><td>Architect (Opus)</td><td>per-feature SPEC.md (Technical Specification)</td></tr>
    <tr><td rowspan="2"><strong>2 · Map</strong></td><td>4</td><td>Plan</td><td><code>/aid-plan</code></td><td>Architect (Opus)</td><td>PLAN.md (sequenced deliveries)</td></tr>
    <tr><td>5</td><td>Detail</td><td><code>/aid-detail</code></td><td>Architect (Opus)</td><td>DETAIL.md + typed task-{{id}}.md (8 types)</td></tr>
    <tr><td><strong>3 · Execute</strong></td><td>6</td><td>Execute</td><td><code>/aid-execute</code></td><td>Developer (Sonnet) + per-type Specialist</td><td>IMPLEMENTATION-STATE.md, code changes</td></tr>
    <tr><td rowspan="2"><strong>4 · Deliver</strong></td><td>7</td><td>Deploy</td><td><code>/aid-deploy</code></td><td>Operator (Sonnet)</td><td>package-NNN.md, DEPLOYMENT-STATE.md</td></tr>
    <tr><td>8</td><td>Monitor</td><td><code>/aid-monitor</code></td><td>Orchestrator (Sonnet)</td><td>MONITOR-STATE.md (template pending — Q8/H7)</td></tr>
    <tr><td>—</td><td>—</td><td>Summarize (optional)</td><td><code>/aid-summarize</code></td><td>(orchestrator)</td><td><code>knowledge-summary.html</code> (this file)</td></tr>
  </tbody>
</table>
<p>Group structure per the methodology <code>README.md</code> "The 11 Phases" section and <a href="./architecture.md">architecture.md</a> §"Stage groups and phases". Init and Summarize are skills but not phases (per Q16 canonical taxonomy) — hence the dashes.</p>

<h3>The 11 feedback loops</h3>
<p>The methodology defines 11 formal feedback paths so any phase can revise upstream artifacts when reality contradicts assumptions. L1-L8 are development-time; L9-L10 are post-production; L11 (per Q17 resolution) is the "any phase → targeted Discovery" re-entry pattern shown in the pipeline diagram. Details in <a href="./architecture.md">architecture.md §2.1</a>.</p>''', featured=True)

s3 = section(3, "kb-gravitational-center", "The Knowledge Base — the Gravitational Center", f'''<p><strong>The KB is the central artifact AID is built around.</strong> Not the spec, not the code — the accumulated living understanding of the project. Every phase reads it (KB context fed to every task as RAG-by-convention). Every phase may revise it (the formal feedback loops). The KB has a <em>fixed shape</em> — 16 standard documents enforced by tooling — so downstream skills (<code>aid-interview</code>, <code>aid-specify</code>, <code>aid-plan</code>) know exactly where to look.</p>

{figure(2, "KB document taxonomy", FIG3, "The .aid/knowledge/ directory: 21 files = 16 standard KB docs (load-bearing — downstream skills depend on these exact names) + 3 meta-documents (INDEX, README, DISCOVERY-STATE) + 1 generated pre-pass (project-index.md) + KB extensions outside the standard 16 (currently host-tools-matrix.md, project-type-specific). The 16 standard docs are produced by the 6 discovery sub-agents grouped by domain.")}

<h3>What every KB doc covers</h3>
<table>
  <thead><tr><th>Doc</th><th>Owner sub-agent</th><th>Purpose</th></tr></thead>
  <tbody>
    <tr><td>project-structure</td><td>scout</td><td>Repo layout, file inventory</td></tr>
    <tr><td>external-sources</td><td>scout</td><td>Vendor docs registered as references</td></tr>
    <tr><td>architecture</td><td>architect</td><td>Patterns, levels, data flow</td></tr>
    <tr><td>technology-stack</td><td>architect</td><td>Languages, runtimes, build/test commands</td></tr>
    <tr><td>ui-architecture</td><td>architect</td><td>Front-end / HTML viewer architecture (this file's source profile)</td></tr>
    <tr><td>module-map</td><td>analyst</td><td>Module dependency graph + per-module owners</td></tr>
    <tr><td>coding-standards</td><td>analyst</td><td>Conventions mined from actual code/configs</td></tr>
    <tr><td>data-model</td><td>analyst</td><td>Schemas, artifact flow, cardinality</td></tr>
    <tr><td>api-contracts</td><td>integrator</td><td>Public surfaces (or, for AID: host-tool frontmatter schemas)</td></tr>
    <tr><td>integration-map</td><td>integrator</td><td>External integration topology</td></tr>
    <tr><td>domain-glossary</td><td>integrator</td><td>Project-specific vocabulary</td></tr>
    <tr><td>test-landscape</td><td>quality</td><td>Test frameworks + coverage + gaps</td></tr>
    <tr><td>security-model</td><td>quality</td><td>Auth, permissions, OWASP-adjacent</td></tr>
    <tr><td>tech-debt</td><td>quality</td><td>Severity-rated debt items + remediation</td></tr>
    <tr><td>infrastructure</td><td>quality</td><td>Distribution, CI, environments</td></tr>
    <tr><td>feature-inventory</td><td>orchestrator (post-Q&A)</td><td>Canonical feature list (from Required Q&A answer)</td></tr>
  </tbody>
</table>

<h3>Progressive disclosure — the 3-tier context economy</h3>
<p>FIG2 above shows <em>what</em> files exist. Just as important is <em>how an agent reads them</em>: the KB is structured so an agent <strong>never loads the whole repository — or even the whole KB — into its context window</strong>. Retrieval happens in three tiers, cheapest first (per <a href="./architecture.md">architecture.md</a> Pattern 4, "Progressive disclosure").</p>

{figure(3, "RAG-by-convention — the 3-tier context economy", FIG9, "How an agent navigates the KB without bloating its context. Tier 1: INDEX.md (~200-500 tokens) rides in every task prompt — the agent always knows what exists and where. Tier 2: from an INDEX entry the agent loads exactly one specific KB document on demand — the fixed 16-doc shape makes this deterministic, no search. Tier 3: every KB claim carries an inline path:line citation, so the agent jumps straight to the exact file + line in the 49,226-line repository — never globbing, never bulk-loading source. Net effect: retrieval-augmented behavior with no vector database, no embeddings, no chunking.")}

<ol>
  <li><strong>Tier 1 — <code>INDEX.md</code>, always loaded.</strong> Every task prompt carries INDEX.md (a 2-3 line summary of every KB doc, ~200-500 tokens total). The agent knows what knowledge exists and which file holds it — at negligible context cost.</li>
  <li><strong>Tier 2 — one KB document, on demand.</strong> From an INDEX entry the agent reads only the single KB doc a task needs. The fixed 16-doc shape makes this navigation deterministic — <code>data-model.md</code> always holds schemas, <code>tech-debt.md</code> always holds debt — so the agent navigates by convention, never by search.</li>
  <li><strong>Tier 3 — exact repo location, via citation.</strong> Every factual claim in a KB doc carries an inline <code>path:line</code> citation (<a href="./coding-standards.md">coding-standards.md §4.4</a>). The agent jumps straight to the precise file and line in the 49,226-line repository — never globbing, never bulk-loading unrelated source. The same citations that enforce accuracy double as the context-economy navigation layer.</li>
</ol>
<p><strong>Net effect:</strong> the agent pays ~200-500 tokens to know the location of everything, then spends context budget only on the one KB doc and the specific repo lines a task genuinely needs. That is what "RAG-by-convention" means — no vector store, no embeddings, no chunking; just predictable structure + a navigation index + mandatory citations.</p>''', featured=True)

s4 = section(4, "agent-model", "The Agent Model — Three Tiers", f'''<p>AID separates agents into three tiers by cost / capability, applied consistently across all 3 install trees. The mapping was verified across all 22 agents during cycle 1 review (<a href="./tech-debt.md">tech-debt.md</a> L6).</p>

{figure(4, "Three-tier agent model", FIG4, "Opus tier (10 agents): judgment-heavy work — 3 Core (architect, reviewer, interviewer) + 1 Specialist (security) + all 6 Discovery sub-agents. Sonnet tier (9 agents): operational / orchestration work — 4 Core (orchestrator, researcher, developer, operator) + 5 Specialist (data-engineer, performance, devops, tech-writer, ux-designer). Haiku tier (3 agents): mechanical-only utility — simple-extractor, simple-formatter, simple-glob. Tier-consistent across Claude Code (model: opus/sonnet/haiku) + Codex (model: gpt-5.5/gpt-5.4/gpt-5.4-mini with reasoning_effort high/medium/low) + Cursor (matches Claude Code).")}

<h3>Skill → Agent dispatch</h3>
<p>Skills are the state-machine orchestrators; agents are the workers. The dispatch mapping is deterministic — each skill has a default executor agent + a default reviewer (the <strong>Reviewer ≥ Executor tier invariant</strong> is enforced: a Sonnet executor gets an Opus reviewer; a Haiku utility never reviews anything).</p>

{figure(5, "Skill → Agent dispatch", FIG5, "Per-skill default agent assignments. /aid-discover dispatches all 6 Discovery sub-agents (Opus). Interview/Specify/Plan/Detail share the Architect (Opus). Execute defaults to Developer (Sonnet) but routes task-type-specific work to matching Specialists (Sonnet) and uses an Opus Reviewer per the tier-invariant rule. Deploy uses Operator, Monitor uses Orchestrator. Utility Haiku agents are internal-only (never user-invoked, never used for synthesis).")}''', featured=True)

s5 = section(5, "phase-deep-dive", "Phase Deep-Dive — Discover (the Most Complex Skill)", f'''<p>Discover is the largest and most-orchestrated AID skill. It runs a 6-state state machine (GENERATE → REVIEW → Q&A → FIX → APPROVAL → DONE), dispatches 6 discovery sub-agents in parallel + a separate reviewer, and includes a built-in quality gate with deterministic grading. It's representative of how all AID skills work — others are simpler variants of the same pattern.</p>

{figure(6, "/aid-discover state machine", FIG7, "GENERATE produces the 16 KB docs (1 scout alone first, then 4 parallel sub-agents — architect/analyst/integrator/quality). REVIEW dispatches discovery-reviewer with clean context for fresh grading. Q&A presents Pending questions to the user (or auto-answers trivial). FIX applies answers + removes resolved Issues from DISCOVERY-STATE.md, then re-enters REVIEW. APPROVAL is the user gate. DONE marks the KB ready for downstream phases. Loops continue until grade ≥ minimum AND user-approved.")}

{figure(7, "Phase IO — Discover", FIG2, "Inputs (blue): target codebase + project-index.md (the pre-pass file inventory) + 8 vendor doc URLs (deferred fetch). The skill (green sub-agents) dispatches 6 specialists — scout always alone first to produce project-structure + external-sources docs that anchor the 4 parallel agents (architect, analyst, integrator, quality). The reviewer runs SEPARATELY with clean context for unbiased grading. Outputs (purple): the 16 KB docs + DISCOVERY-STATE.md with grade + Issues + Q&A.")}

<h3>Why this pattern works for the other skills too</h3>
<ul>
  <li><strong>State machine + state file:</strong> every skill runs one step per invocation, persists state, exits. Filesystem is the only source of truth.</li>
  <li><strong>Orchestrator-worker dispatch:</strong> the skill dispatches specialized agents; the agents return; the skill merges results.</li>
  <li><strong>Separate reviewer:</strong> the agent that writes never grades. Adversarial review by a higher-tier agent.</li>
  <li><strong>User gates:</strong> approval is explicit — no auto-advance between phases.</li>
  <li><strong>Feedback loops:</strong> downstream phases can revise upstream artifacts via formal GAP / IMPEDIMENT / Change-Request paths.</li>
</ul>''')

s6 = section(6, "artifact-dataflow", "Artifact Dataflow Across the Pipeline", f'''<p>The "data" AID moves through the pipeline is a sequence of structured markdown files. Each phase produces specific artifacts that downstream phases consume. The Knowledge Base sits behind all of them — updated continuously, referenced everywhere.</p>

{figure(8, "Artifact dataflow", FIG6, "Forward path (green = output, teal = produced-and-consumed): KB → REQUIREMENTS → SPEC → PLAN → DETAIL + tasks → IMPLEMENTATION-STATE → DEPLOYMENT artifacts → MONITOR artifacts. Feedback (yellow): GAP / IMPEDIMENT / KNOWN-ISSUES are produced when reality contradicts a downstream artifact's premise; they feed back into the KB to update the gravitational center. Monitor's BUG / Change-Request paths feed directly back to KB.")}

<h3>The 15 artifact sections (per <a href="./data-model.md">data-model.md</a>)</h3>
<ol>
  <li><strong>DISCOVERY-STATE.md</strong> — Grade / Issues / Q&A / Review History</li>
  <li><strong>REQUIREMENTS.md</strong> — feature list + non-functional requirements</li>
  <li><strong>INTERVIEW-STATE.md</strong> — interview state machine</li>
  <li><strong>SPEC.md</strong> (per feature) — requirements + technical spec</li>
  <li><strong>PLAN.md</strong> — ordered deliveries</li>
  <li><strong>DETAIL.md</strong> — typed task decomposition</li>
  <li><strong>task-{id}.md</strong> — one per task, 8 types (RESEARCH / DESIGN / IMPLEMENT / TEST / DOCUMENT / MIGRATE / REFACTOR / CONFIGURE)</li>
  <li><strong>IMPLEMENTATION-STATE.md</strong> — per-task execution log</li>
  <li><strong>GAP-{id}.md</strong> — feedback when KB has a gap</li>
  <li><strong>IMPEDIMENT-{id}.md</strong> — feedback when reality contradicts spec (silent workarounds forbidden)</li>
  <li><strong>known-issues.md</strong> — per-work issue tracking</li>
  <li><strong>DEPLOYMENT-STATE.md + package-NNN.md</strong> — per-deploy</li>
  <li><strong>MONITOR-STATE.md + track-report-*.md</strong> — per-monitor (templates pending — H7/Q8)</li>
  <li><strong>project-index.md</strong> — generated file inventory (pre-pass for discovery sub-agents)</li>
  <li><strong>Agent / Skill frontmatter</strong> — see <a href="./api-contracts.md">api-contracts.md</a></li>
</ol>

<p>Every artifact carries a metadata header (Source / Status / Last Updated). The long-lived ones (REQUIREMENTS, SPEC, KB docs) carry a mandatory <code>## Revision History</code> table — every edit gets a row.</p>''')

s7 = section(7, "cross-tool-delivery", "Cross-Tool Delivery — One Pipeline, Three Install Bundles", f'''<p>AID ships the same methodology to three host AI coding tools. The canonical sources live at the repo root (<code>methodology/</code>, <code>skills/</code>, <code>agents/</code>, <code>templates/</code>). The three install bundles (<code>claude-code/.claude/</code>, <code>codex/.codex/</code> + <code>codex/.agents/</code>, <code>cursor/.cursor/</code>) duplicate the content in each tool's native format.</p>

{figure(9, "Triplicated install bundles", FIG8, "The canonical sources are human-readable. Each install tree carries the same content in its host tool's native format: Claude Code uses markdown + YAML frontmatter; Codex uses split layout — TOML agents under .codex/ + markdown skills under .agents/ (inlined SKILL.md bodies); Cursor uses markdown + YAML (like Claude Code) plus .mdc rules for always-on context. ~36% of repo lines are 4-way duplicated. Manual cross-tree sync is enforced by CONTRIBUTING.md:21-26 (pending Cursor add per Q34/Q72). Copilot CLI + Antigravity are aspirational future targets per Q5.")}

<h3>Per-tool format summary</h3>
<table>
  <thead><tr><th>Tool</th><th>Agent format</th><th>Skill body</th><th>Project context</th><th>Always-on rules</th></tr></thead>
  <tbody>
    <tr><td>Claude Code</td><td>markdown + YAML</td><td>SKILL.md + <code>references/</code> + <code>scripts/</code></td><td><code>CLAUDE.md</code></td><td>n/a</td></tr>
    <tr><td>Codex CLI</td><td>TOML</td><td>SKILL.md (inlined — no references/)</td><td><code>AGENTS.md</code></td><td>n/a</td></tr>
    <tr><td>Cursor</td><td>markdown + YAML</td><td>SKILL.md (inlined)</td><td><code>AGENTS.md</code></td><td><code>.cursor/rules/*.mdc</code></td></tr>
  </tbody>
</table>

<p>See <a href="./host-tools-matrix.md">host-tools-matrix.md</a> for the full per-host-tool feature parity matrix including 10 known divergences/bugs cross-linked to Q&A entries.</p>''')

s8 = section(8, "tech-debt", "Tech Debt", '''<p>Audit complete in <a href="./tech-debt.md">tech-debt.md</a>: <strong>20 items total — 7 HIGH, 6 MEDIUM, 7 LOW</strong>, plus a 29-row Resolution Roadmap (R1–R29). The two most-urgent items are real adopter-impacting bugs:</p>

<table>
  <thead><tr><th>ID</th><th>Severity</th><th>Item</th><th>Effort</th></tr></thead>
  <tbody>
    <tr><td><strong>H6</strong></td><td>HIGH (CONFIRMED bug)</td><td><code>setup.sh</code> + <code>setup.ps1</code> Codex branches omit copying <code>codex/.agents/</code> (skills + templates). Every Codex user has been getting agent TOMLs without skill bodies.</td><td>Trivial (~10 min)</td></tr>
    <tr><td><strong>H7</strong></td><td>HIGH</td><td>Missing Monitor-phase templates (<code>MONITOR-STATE.md</code>, <code>track-report-template.md</code>) referenced in <code>templates/README.md</code> but not authored.</td><td>Small</td></tr>
    <tr><td>H1</td><td>HIGH</td><td>Triplication drift between install trees (SKILL.md bodies diverge 2.4× across trees; no propagation tool)</td><td>Medium</td></tr>
    <tr><td>H2</td><td>HIGH</td><td>No CI / no test runner / no <code>VERSION</code> file</td><td>Medium</td></tr>
    <tr><td>H3</td><td>HIGH</td><td>No triplication-drift checker</td><td>Small</td></tr>
    <tr><td>H4</td><td>HIGH</td><td>4-way duplicated assets (~17,600 lines = ~36% of repo)</td><td>Medium</td></tr>
    <tr><td>H5</td><td>HIGH</td><td><code>CONTRIBUTING.md:21-26</code> omits Cursor from cross-tree update rule</td><td>Trivial</td></tr>
  </tbody>
</table>

<p><strong>Positive parity finding:</strong> all 22 agents are tier-consistent across all 3 install trees — the May 2026 tier-rename migration (<code>codex/README.md:35</code>) was applied cleanly. Verified during cycle-1 review.</p>

<p><strong>Tooling shipped this cycle:</strong> <code>templates/scripts/verify-kb-claims.sh</code> (R29 implementation, 300 lines Bash) — scans KB markdown for <code>file.ext:NN</code> citations and grep-checks them; checks README.md line-counts vs actual; targeted count-drift spot-checks. Latest run: <strong>897/897 citations valid, 0 drifts</strong>.</p>''')

s9 = section(9, "adopting-aid", "Adopting AID", '''<p>To use AID in your own project:</p>

<pre><code># 1. Get the methodology
git clone https://github.com/AndreVianna/aid-methodology.git
cd aid-methodology

# 2. Install into your target project (interactive menu picks tools)
bash setup.sh /path/to/your/project           # Linux / macOS / git-bash
bash setup.sh /path/to/your/project --force   # overwrite without prompts
# Windows native (PowerShell 5.1+):
.\\setup.ps1 C:\\path\\to\\your\\project

# 3. In your project, run the AID pipeline (slash commands)
/aid-init           # once per project — scaffolds .aid/
/aid-discover       # brownfield only — analyzes existing code into the KB
/aid-interview      # build REQUIREMENTS.md from a dialogue
/aid-specify        # add technical spec per feature
/aid-plan           # sequence features into deliveries
/aid-detail         # decompose deliveries into typed tasks
/aid-execute        # implement tasks (with built-in review loop)
/aid-deploy         # package + ship a delivery
/aid-monitor        # observe production; classify findings; route fixes
/aid-summarize      # optional — generate an HTML KB viewer like this one</code></pre>

<h3>What gets installed in your project</h3>
<ul>
  <li><code>.claude/</code>, <code>.codex/</code>, <code>.agents/</code>, or <code>.cursor/</code> (depending on the tools you selected) — agents, skills, templates, scripts.</li>
  <li><code>CLAUDE.md</code> or <code>AGENTS.md</code> at project root — host-tool project-context file with <code>(pending discovery)</code> placeholders that <code>/aid-init</code> + <code>/aid-discover</code> populate.</li>
  <li>Your project's <code>.gitignore</code> gets <code>.aid/</code> appended automatically — the dogfooded KB stays out of git by default (override if you want to share).</li>
</ul>

<h3>Runtime requirements</h3>
<ul>
  <li>One or more host AI tools: Claude Code / Codex CLI / Cursor</li>
  <li>Bash (or git-bash on Windows) for scripts</li>
  <li>PowerShell 5.1+ for <code>setup.ps1</code></li>
  <li>Node 18+ (optional, only for <code>/aid-summarize</code> diagram validation)</li>
  <li>Git</li>
</ul>''')

s10 = section(10, "kb-index", "Knowledge Base Index", '''<p>Full per-document summaries in <a href="./INDEX.md">INDEX.md</a>. The 16 standard KB documents that downstream skills depend on:</p>

<ul>
  <li><a href="./project-structure.md">project-structure.md</a></li>
  <li><a href="./external-sources.md">external-sources.md</a></li>
  <li><a href="./architecture.md">architecture.md</a></li>
  <li><a href="./technology-stack.md">technology-stack.md</a></li>
  <li><a href="./module-map.md">module-map.md</a></li>
  <li><a href="./coding-standards.md">coding-standards.md</a></li>
  <li><a href="./data-model.md">data-model.md</a></li>
  <li><a href="./api-contracts.md">api-contracts.md</a></li>
  <li><a href="./integration-map.md">integration-map.md</a></li>
  <li><a href="./domain-glossary.md">domain-glossary.md</a> — 150 terms</li>
  <li><a href="./test-landscape.md">test-landscape.md</a></li>
  <li><a href="./security-model.md">security-model.md</a> — 21 findings (0 CRITICAL)</li>
  <li><a href="./tech-debt.md">tech-debt.md</a> — 20 items + 29-row Resolution Roadmap</li>
  <li><a href="./infrastructure.md">infrastructure.md</a></li>
  <li><a href="./ui-architecture.md">ui-architecture.md</a> — covers the aid-summarize viewer (this file)</li>
  <li><a href="./feature-inventory.md">feature-inventory.md</a> — 18 features (12 ✅ / 6 ⚠️)</li>
</ul>

<p><strong>Plus:</strong> 3 meta (<code>INDEX</code> / <code>README</code> / <code>DISCOVERY-STATE</code>), 1 generated (<code>project-index.md</code>), 1 extension (<code>host-tools-matrix.md</code>).</p>''')

# ---------------------------------------------------------------------------
# Hero + TOC
# ---------------------------------------------------------------------------

hero = '''<section class="hero" id="hero">
  <h1>AID — AI-Integrated Development</h1>
  <p class="tagline">A methodology pipeline for building software with AI agents — a 10-skill lifecycle, formal feedback loops, and a Knowledge Base as the gravitational center.</p>
  <p class="meta">Knowledge Base summary · Generated 2026-05-21 · KB Grade: <strong>A+</strong> (user approved) · 9 diagrams</p>
</section>'''

toc = '''<nav class="toc" aria-labelledby="toc-title">
  <h2 id="toc-title">On this page</h2>
  <ol>
    <li><a href="#at-a-glance">At a Glance</a></li>
    <li><a href="#the-pipeline">The AID Pipeline ★</a></li>
    <li><a href="#kb-gravitational-center">The Knowledge Base ★</a></li>
    <li><a href="#agent-model">The Agent Model ★</a></li>
    <li><a href="#phase-deep-dive">Phase Deep-Dive — Discover</a></li>
    <li><a href="#artifact-dataflow">Artifact Dataflow</a></li>
    <li><a href="#cross-tool-delivery">Cross-Tool Delivery</a></li>
    <li><a href="#tech-debt">Tech Debt</a></li>
    <li><a href="#adopting-aid">Adopting AID</a></li>
    <li><a href="#kb-index">Knowledge Base Index</a></li>
  </ol>
</nav>'''

body = "\n\n".join([hero, toc, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10])

# ---------------------------------------------------------------------------
# Template substitution
# ---------------------------------------------------------------------------

substituted = (skeleton
    .replace("{{LANG}}", LANG)
    .replace("{{PROJECT_NAME}}", PROJECT)
    .replace("{{INLINE_CSS}}", css)
    .replace("{{BODY_CONTENT}}", body)
    .replace("{{GENERATION_DATE}}", GEN_DATE)
    .replace("{{MERMAID_VERSION}}", MERMAID_VER)
    .replace("{{MERMAID_VERSION_COMMENT}}", f"Mermaid {MERMAID_VER} inlined for offline use")
    .replace("{{INLINE_LIGHTBOX_JS}}", lightbox))

placeholder = "/* Mermaid library inlined here by /aid-summarize concat step. */"
idx = substituted.find(placeholder)
if idx == -1:
    raise SystemExit("ERROR: placeholder for Mermaid library not found in skeleton")

part1 = substituted[:idx]
part2 = substituted[idx + len(placeholder):]

(BUILD / "part1.html").write_text(part1, encoding="utf-8")
(BUILD / "part2.html").write_text(part2, encoding="utf-8")

print(f"[build-html] Wrote part1.html ({len(part1):,} bytes) + part2.html ({len(part2):,} bytes).")
print(f"[build-html] Body content: {len(body):,} bytes · 9 diagrams · 10 sections · pipeline-focused")
