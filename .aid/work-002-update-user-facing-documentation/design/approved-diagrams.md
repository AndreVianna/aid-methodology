# Approved diagrams — work-002 visual-first rewrite

These Mermaid blocks were reviewed and **user-approved** (rendered + validated). Writers
must paste them VERBATIM (only the README hero may drop the two `Mon -.-> Intv` feedback
arrows for a simpler glance version). Keep the shared palette below consistent in ANY new
diagram or table.

## Shared palette (use everywhere — diagrams AND table accents)

| Role | Hex | Mermaid classDef |
|------|-----|------------------|
| Prepare | `#1E3A8A` (navy) | `prep` |
| Define | `#6D28D9` (purple) | `def` |
| Map | `#0F766E` (teal) | `map` |
| Execute | `#166534` (green) | `exe` |
| Deliver / optional | `#C2410C` (orange, dashed) | `delopt` (stroke-dasharray:5 4) |
| Off-pipeline | `#374151` (slate, dashed) | `offpipe` (stroke-dasharray:6 4) |
| Auxiliary (config/summarize) | `#E5E7EB` (grey, dashed) | `aux` |
| Lite path | `#92400E` (amber) | `lite` |
| KB center | `#0B1F3A` · standard `#1D4ED8` · meta `#7C3AED` · generated `#166534` · extensions `#B45309` | kb/std/meta/gen/ext |

GitHub callouts: `> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`. Dashed = optional/off-pipeline.

---

## D1 — Hero pipeline (README pre-## block + methodology §1)

```mermaid
flowchart TB
    classDef prep    fill:#1E3A8A,stroke:#1E3A8A,color:#ffffff
    classDef def     fill:#6D28D9,stroke:#6D28D9,color:#ffffff
    classDef map     fill:#0F766E,stroke:#0F766E,color:#ffffff
    classDef exe     fill:#166534,stroke:#166534,color:#ffffff
    classDef delopt  fill:#C2410C,stroke:#C2410C,color:#ffffff,stroke-dasharray:5 4
    classDef aux     fill:#E5E7EB,stroke:#9CA3AF,color:#1F2937,stroke-dasharray:4 3
    classDef offpipe fill:#374151,stroke:#374151,color:#ffffff,stroke-dasharray:6 4

    subgraph G1[" 1 · Prepare "]
        Init["aid-config<br/>setup · once"]:::aux
        Disc["1 · aid-discover<br/>brownfield"]:::prep
        Sum["aid-summarize<br/>optional"]:::aux
    end
    subgraph G2[" 2 · Define "]
        Intv["2 · aid-interview<br/>TRIAGE → full or lite"]:::def
        Spec["3 · aid-specify<br/>full path only"]:::def
    end
    subgraph G3[" 3 · Map "]
        Plan["4 · aid-plan<br/>full path only"]:::map
        Det["5 · aid-detail<br/>full path only"]:::map
    end
    subgraph G4[" 4 · Execute "]
        Exe["6 · aid-execute<br/>8 task types · graded loop"]:::exe
    end
    subgraph G5[" 5 · Deliver (optional) "]
        Dep["aid-deploy"]:::delopt
        Mon["aid-monitor"]:::delopt
    end

    HK["aid-housekeep<br/>on-demand · off-pipeline<br/>KB-DELTA · SUMMARY · CLEANUP"]:::offpipe

    Init --> Disc --> Intv --> Spec --> Plan --> Det --> Exe
    Exe -. "on demand" .-> Dep
    Exe -. "on demand" .-> Mon
    Mon -. "bugs → LITE-BUG-FIX" .-> Intv
    Mon -. "change requests" .-> Intv
    HK  -. "targeted KB refresh" .-> Disc
```

README simplified caption: "11 skills · 5 groups · 2 paths (TRIAGE-routed)." Methodology caption keeps the full explanation. README version MAY omit the two `Mon -.-> Intv` lines.

---

## D2 — TRIAGE routing (README "The Lite Path" + methodology §4 Interview)

```mermaid
flowchart LR
    classDef def   fill:#6D28D9,stroke:#6D28D9,color:#ffffff
    classDef exe   fill:#166534,stroke:#166534,color:#ffffff
    classDef lite  fill:#92400E,stroke:#92400E,color:#ffffff

    Triage["aid-interview · TRIAGE<br/>T1 breadth · T2 task-count · T3 type"]:::def

    subgraph FullPath[" Full path "]
        direction LR
        F1["Interview<br/>REQUIREMENTS + feature SPEC stubs"]:::def
        F2["aid-specify"]:::def
        F3["aid-plan"]:::def
        F4["aid-detail"]:::def
    end
    subgraph LitePath[" Lite path "]
        direction LR
        L1["CONDENSED-INTAKE"]:::lite
        L2["TASK-BREAKDOWN"]:::lite
        L3["LITE-REVIEW"]:::lite
    end
    Exec["aid-execute"]:::exe

    Triage -- "ANY large signal:<br/>T1 = multiple · T2 = many (6+)<br/>· T3 = new feature/system" --> F1
    F1 --> F2 --> F3 --> F4 --> Exec
    Triage -- "ALL small:<br/>T1 none/one-small · T2 a few (≤5)<br/>· T3 bug-fix / refactor / doc" --> L1
    L1 --> L2 --> L3 --> Exec
    L3 -. "escalate if scope grows" .-> F1
```

---

## D3 — Agent model, 22 agents / 3 tiers (README compact form; methodology §5 may list all names)

```mermaid
flowchart TB
    classDef large fill:#1E3A8A,stroke:#1E3A8A,color:#ffffff
    classDef med   fill:#0F766E,stroke:#0F766E,color:#ffffff
    classDef small fill:#E5E7EB,stroke:#9CA3AF,color:#1F2937

    subgraph L["Large tier — 10 · highest-stakes (Opus / GPT-5.5 / Gemini-3 Pro hi)"]
        direction LR
        LA["architect"]:::large
        LR2["reviewer"]:::large
        LI["interviewer"]:::large
        LS["security"]:::large
        LD["6 × discovery-*"]:::large
    end
    subgraph M["Medium tier — 9 · production workhorses (Sonnet / GPT-5.4 / Gemini-3 Pro lo)"]
        direction LR
        MO["orchestrator"]:::med
        MR["researcher"]:::med
        MD["developer"]:::med
        MOps["operator"]:::med
        MDE["5 × data-engineer · performance<br/>devops · tech-writer · ux-designer"]:::med
    end
    subgraph S["Small tier — 3 · mechanical (Haiku / GPT-5.4-mini / Gemini-3 Flash)"]
        direction LR
        SE["simple-extractor"]:::small
        SF["simple-formatter"]:::small
        SG["simple-glob"]:::small
    end
    L -. "reviewer tier ≥ executor tier" .-> M -.-> S
```

Authoritative roster (22): **Large (10)** architect, reviewer, interviewer, security, discovery-scout, discovery-architect, discovery-analyst, discovery-integrator, discovery-quality, discovery-reviewer · **Medium (9)** orchestrator, researcher, developer, operator, data-engineer, performance, devops, tech-writer, ux-designer · **Small (3)** simple-extractor, simple-formatter, simple-glob.

---

## D4 — Knowledge Base (methodology §3; README may link instead)

```mermaid
flowchart TD
    classDef kb   fill:#0B1F3A,stroke:#0B1F3A,color:#ffffff
    classDef std  fill:#1D4ED8,stroke:#1D4ED8,color:#ffffff
    classDef meta fill:#7C3AED,stroke:#7C3AED,color:#ffffff
    classDef gen  fill:#166534,stroke:#166534,color:#ffffff
    classDef ext  fill:#B45309,stroke:#B45309,color:#ffffff,stroke-dasharray:5 4

    KB["Knowledge Base<br/>.aid/knowledge/"]:::kb
    KB --> STD["14 standard documents<br/>(default seed)"]:::std
    KB --> META["3 meta-documents<br/>STATE · INDEX · README"]:::meta
    KB --> GEN["1 generated pre-pass<br/>project-index.md"]:::gen
    KB --> EXT["KB extensions<br/>optional · project-specific<br/>via discovery.doc_set"]:::ext
    STD --> S1["architecture · tech-stack<br/>coding-standards · module-map"]:::std
    STD --> S2["schemas · pipeline-contracts<br/>integration-map · infrastructure"]:::std
    STD --> S3["test-landscape · tech-debt<br/>domain-glossary · …"]:::std
    DISC["aid-discover<br/>6 discovery sub-agents"]:::gen
    DISC -. "populate" .-> STD
    DISC -. "populate" .-> GEN
```

---

## D5 — Feedback loops (methodology §6) — group-specific colors

```mermaid
flowchart TB
    classDef prep    fill:#1E3A8A,stroke:#1E3A8A,color:#ffffff
    classDef def     fill:#6D28D9,stroke:#6D28D9,color:#ffffff
    classDef map     fill:#0F766E,stroke:#0F766E,color:#ffffff
    classDef exe     fill:#166534,stroke:#166534,color:#ffffff
    classDef delopt  fill:#C2410C,stroke:#C2410C,color:#ffffff,stroke-dasharray:5 4
    classDef offpipe fill:#374151,stroke:#374151,color:#ffffff

    D["1 · Discover"]:::prep
    I["2 · Interview"]:::def
    S["3 · Specify"]:::def
    P["4 · Plan"]:::map
    Dt["5 · Detail"]:::map
    E["6 · Execute"]:::exe
    Dp["Deploy · optional"]:::delopt
    M["Monitor · optional"]:::delopt
    Any["Any phase<br/>L11 · cross-cutting"]:::offpipe

    D --> I --> S --> P --> Dt --> E
    E  -. "optional" .-> Dp
    E  -. "optional" .-> M
    I  -. "L1" .-> D
    S  -. "L2" .-> D
    P  -. "L3" .-> D
    P  -. "L4" .-> S
    Dt -. "L5" .-> P
    E  -. "L6 · impediment" .-> D
    E  -. "L7 · review" .-> S
    Dp -. "L8 · verification" .-> E
    M  -. "L9 · bug" .-> I
    M  -. "L10 · change request" .-> I
    Any -. "targeted re-discovery" .-> D
```

> Verify loop count/labels against `domain-glossary.md` / methodology §6 before shipping;
> keep numbering consistent with the prose.

## SDD-vs-AID comparison (methodology §9)

Reuse the existing §9 comparison Mermaid if present; restyle its AID side with the group
palette above (not monochrome). Keep the comparison TABLE as the primary element; the
diagram complements it.
