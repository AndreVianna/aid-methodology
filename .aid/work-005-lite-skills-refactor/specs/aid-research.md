# Behavioral Spec — `aid-research` / `aid-investigate` / `aid-spike` Redesign

> **Status:** LOCKED for implementation (design agreed 2026-07-15).
> **Tracked under:** `.aid/work-005-lite-skills-refactor/` (branch `work-005-lite-skills-refactor`).
> **Scope:** `aid-research` (canonical) + `aid-investigate`, `aid-spike` (aliases).
> Second of the "clear mismatch" redesigns. Shares the [`aid-review` §12 patterns](aid-review.md);
> this doc records only what research adds or changes.
> **Not implemented yet** — this is the contract the implementation must satisfy.

---

## 1. Problem

- **Objective (catalog `intent`):** *"Investigate an open technical question: evaluate
  options or run a feasibility spike; end with a recommendation."*
- **Actual behavior today:** identical mismatch to `aid-review` — the thin doorway runs
  the shortcut engine (`INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT`,
  ~5 Opus dispatches), *plans* a RESEARCH work, and **halts before investigating**. The
  user gets a planning package, never an answer.

## 2. Objective (locked)

`/aid-research <question>` **investigates the question in depth now** and returns a
**curated, verified answer** — the complete picture, presented clearly and simply. It
**resolves nothing**: it lays out conclusions (positive *and* negative), conflicts /
contradictions (each with its reason), and gaps, then **the user resolves**.

> Not a recommendation engine. The agent gathers and curates verified information; it
> does not pick a winner or issue a directive. Presenting a conclusion ("A meets X/Y; B
> fails Z") is in scope; resolving the question ("therefore do A") is the user's.

## 3. Topology change

Same mechanism as `aid-review` (`aid-review.md §3`):

- Flip `aid-research`, `aid-investigate`, `aid-spike` to **`repurpose: true`** in
  `shortcut-catalog.yml`.
- Hand-author `canonical/skills/aid-research/SKILL.md`; `aid-investigate` and `aid-spike`
  become **thin hand-authored aliases** → `aid-research`.
- Detach the `research` rows from the shortcut-engine's family-grouping / default-type
  tables. **Leave `analyze-report.md` intact** — `report` still uses it (until that
  redesign lands).
- Keep `default_type: RESEARCH`, `group: G11` on all three rows (for `/aid-triage`).
- **Soften the `intent` line** on all three rows: drop *"end with a recommendation"* →
  *"…present curated, verified conclusions, conflicts, and gaps for the user to resolve."*

## 4. Invariants (non-negotiable)

1. **The agent resolves nothing.** Output is curated information + surfaced conclusions
   (±), conflicts, and gaps — never a resolution or a directive. The user decides.
2. **Two-tier grounding.**
   - **KB + project source/codebase are the grounding truth** — mandatory to consult,
     authoritative; the answer is reconciled against what the project actually is.
   - **External / web sources are allowed and encouraged** (prior art, options, industry
     context) but **supplementary**; cited with **URL + access date** (`aid-researcher`'s
     standing contract). They inform; they never override the project's reality.
   - **Conflict rule:** a KB↔web contradiction is **presented to the user with the reason
     for the contradiction** (what the external source claims + cite, what the KB/source
     says + cite, why they diverge). Never silently resolved — in either direction. A
     contradiction may mean the KB is stale; auto-favoring the project would bury that.
3. **Clean context.** INVESTIGATE and VERIFY each run in fresh context; the verifier
   never sees the researcher's working notes
   (`architecture.md § Agent / Sub-Agent Dispatch Model`).
4. **The response is verified and graded** before the user sees it — clean-context
   `aid-reviewer`, bounded loop (see [§8](#8-grading-model-one-grade)).
5. **Human final say before any commit.** Presenting the answer is not a commit. Any
   *durable* side effect — a spike writing code, a KB update, a decision doc, a ticket
   comment — happens only on explicit user authorization.
6. **Clear + simple presentation.** Plain language; conclusions, conflicts, and gaps all
   first-class. Negatives and gaps are never buried under positives.
7. **Reviews/verification are always a sub-agent dispatch** (`aid-reviewer`), never inline.

## 5. State machine

```
INTAKE
  ├─ well-scoped question?  ──yes──▶ (FAST PATH) ─────────────────────┐
  └─ vague/broad ─▶ ask 2–3 scoping Qs → [validate scope] ────────────┤
                                                                       ▼
INVESTIGATE  (aid-researcher, clean context; KB+source authoritative, web supplementary+cited)
  │   └─ gap answerable only by code?  ─▶ PROPOSE-SPIKE [human] ─┐
  │                                                              │
  │        authorized → isolated throwaway spike → fold back ────┘
  │        declined   → proceed analytically, state the limit
  ▼
VERIFY       (aid-reviewer, clean context; grades the RESPONSE; bounded loop) ⤾
  ▼
PRESENT      ── ALWAYS: curated answer + conclusions(±) + conflicts(+reasons) + gaps ──  [user resolves]
  ▼
HANDOFF?     (optional, printed suggestions only; each is human-authorized)
  ▼
DONE
```

## 6. States in detail

### INTAKE

- **Require a question.** Empty argument → one bootstrapping question ("What do you want
  investigated?").
- **Fast path** — the question is concrete and well-scoped with clear evaluation criteria
  ("Is lib X compatible with our Node 24 build?", "Postgres vs SQLite for use-case Y
  against criteria A/B/C") → investigate immediately.
- **Guided path** — vague / broad / underspecified ("research our DB options") → ask 2–3
  scoping questions first (the `deep-research` skill's pattern), then investigate.
- Allocate `.aid/work-NNN-<slug>/` + STATE (normal template, `phase` not driven;
  `aid-review.md §10`). Worktree optional (recommended if a spike is later authorized).
- **Classify complexity** → sets INVESTIGATE/VERIFY model+effort ([§9](#9-modeleffort-tiering)).

### INVESTIGATE

Dispatch **`aid-researcher`** (clean context, tiered) to gather and curate the evidence:
read the KB (`.aid/knowledge/`) and project source as the **authoritative** base, then
enrich with external/web sources as needed (**cited URL + date**). It writes a structured
`RESEARCH.md` into the work folder (see the response shape in [§7](#7-response-shape)).

**Spike escalation (conditional, human-authorized).** Default is **analytical-with-
handoff** — no code is written. If the researcher determines a gap genuinely cannot be
closed on paper, it **stops and proposes a spike**: *what* it would build, *where*
(isolated in the work folder / opt-in worktree, never touching production), and *what it
would learn*. On authorization → write the throwaway spike, fold the finding into
`RESEARCH.md`. On decline → proceed analytically and **state the resulting limit** in the
gaps. The spike is a means to close a gap, never a production change and never a
resolution.

### VERIFY ("who reviews the researcher")

1. **Mechanical grounding check** (no dispatch): every project claim carries a KB/source
   cite; every external claim carries a URL + date; the Gaps and Conflicts sections
   exist (empty-but-present is allowed, silently-omitted is not).
2. **Adversarial verification** — a *clean-context* `aid-reviewer` checks `RESEARCH.md`:
   claims grounded and correctly attributed; conclusions evidence-backed and **not
   overstated into resolutions**; KB↔web conflicts surfaced with reasons; no material
   angle of the question left silently unaddressed. Output: a review-quality 7-column
   ledger (`reviewer-ledger-schema.md`).
3. **Grade** — `grade.sh --explain <ledger>`. Not clean → loop back to INVESTIGATE
   (bounded, 3-cycle circuit-breaker → IMPEDIMENT + surface).

### PRESENT (always a hard stop for the user to resolve)

Show the curated answer, **clearly and simply** (the [§7](#7-response-shape) shape):
the in-depth answer, conclusions (±), conflicts/contradictions **with their reasons**,
and gaps. The user resolves. No resolution is asserted by the skill.

### HANDOFF (optional; printed suggestions only)

Offer the natural next steps as **printed suggestions**, each requiring the user to act:
record an ADR (`/aid-document-decision`), update the KB (`/aid-update-kb`), act on a
conclusion (`/aid-create` · `/aid-change`), or comment on a source ticket (MCP connector).
Never auto-invoked; never a resolution.

### DONE

Finalize STATE; keep the work folder (`RESEARCH.md`, any spike scratch, the verify ledger)
as the audit record.

## 7. Response shape

`RESEARCH.md` (the "clear + simple" deliverable), sections in order:

1. **Question** — the query, restated as scoped/investigated.
2. **Answer** — the in-depth, curated response.
3. **Conclusions** — positive *and* negative, each evidence-backed and cited.
4. **Conflicts & contradictions** — especially KB↔web, each with **its reason** and both
   citations; `none` if there were none.
5. **Gaps** — what could not be answered / what stays uncertain (incl. any limit from a
   declined spike); `none` if none.
6. **Sources** — KB docs + `file:line` (authoritative) and external `URL (accessed
   YYYY-MM-DD)` (supplementary), clearly separated.

## 8. Grading model (one grade)

Unlike `aid-review` (which had an informational *target* grade + a gating *review*
grade), research has no separate target artifact — **the response *is* the deliverable**,
so there is a **single grade on `RESEARCH.md`** (grounded / in-depth / complete /
conflicts+gaps surfaced / conclusions not overstated). That grade gates via the VERIFY
loop. Reuses `grade.sh` + `reviewer-ledger-schema.md` unchanged.

## 9. Model/effort tiering

Producer **`aid-researcher`**, verifier **`aid-reviewer`** (writer ≠ grader; verifier
tier ≥ producer tier). Per-call model+effort override by complexity (agent frontmatter
untouched — the full pipeline is unaffected):

| Complexity | Examples | Producer (researcher) | Verifier (reviewer) |
|---|---|---|---|
| Simple | bounded question, few docs, ≤1 web source | sonnet / medium | sonnet / medium |
| Standard/complex | broad options analysis, deep traversal, many web sources, a spike | opus / high | opus / high |

**Dispatch-count delta:** today ~5 Opus fixed. After: **~2 tiered** (research + verify),
plus one more only if a spike is authorized. As low as 2 × sonnet for a simple question.

## 10. Boundary vs `aid-query-kb`

Pin this so the two don't blur:

- **`aid-query-kb`** — the answer **already exists** in the project's knowledge; retrieve
  it in one read-only pass, **no work folder**, cite, done.
- **`aid-research`** — the answer **must be investigated and assembled** (open question,
  option evaluation, external context, possibly a spike); full work-folder + verify +
  grade + human presentation.
- **Rule of thumb:** *query = the answer exists; research = the answer must be built.*

## 11. Files the implementation will touch

1. `shortcut-catalog.yml` — `repurpose: true` on `aid-research`/`aid-investigate`/
   `aid-spike`; soften their `intent` lines (§3).
2. `canonical/skills/aid-research/SKILL.md` — hand-authored per this spec.
3. `canonical/skills/aid-investigate/SKILL.md`, `canonical/skills/aid-spike/SKILL.md` —
   hand-authored thin aliases → `aid-research`.
4. `shortcut-engine.md` — detach the `research` rows (leave `report`'s `analyze-report.md`
   usage intact).
5. Regenerate: `build-shortcut-skills.py` → full `run_generator.py` → dogfood `.claude/`
   resync (test-dogfood-byte-identity).

## 12. Settled decisions

Resolved with the user 2026-07-15:

1. **Feasibility spike** → **analytical-with-handoff by default**; a spike is a
   **human-authorized escalation** only, isolated + throwaway (§6).
2. **Producer/verifier split** → `aid-researcher` produces, `aid-reviewer` verifies (§9).
3. **Grounding** → KB+source authoritative, web supplementary + cited; **conflicts
   presented to the user with their reason**, never silently resolved (§4.2).
4. **Frame** → the agent **resolves nothing**; it gathers curated, verified information
   and presents conclusions (±), conflicts, and gaps clearly and simply (§2, §4.1, §6).
5. **`aid-query-kb` boundary** → query retrieves an existing answer; research builds a
   new one (§10).
6. Shared with `aid-review`: single-shot, hand-authored + `repurpose: true`, normal STATE
   template, clean-context verify, human-final-say, printed-suggestion handoffs, per-call
   tiering (`aid-review.md §12`).
