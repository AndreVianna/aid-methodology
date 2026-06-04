# KB Authoring

> Normative specification for authoring `.aid/knowledge/` Knowledge Base documents.
> Loaded by `aid-discover` (review — via the `aid-reviewer` sub-agent),
> `aid-config` (scaffold), and `aid-summarize` (render).

## What's here

| File | Purpose |
|------|---------|
| [principles.md](principles.md) | The 8 normative principles for KB authoring + review |
| [tier-model.md](tier-model.md) | T1-T4 fact stability tiers used inside KB docs |
| [frontmatter-schema.md](frontmatter-schema.md) | YAML frontmatter spec for every KB doc |
| [review-rubric.md](review-rubric.md) | Per-`kb-category` review treatment + temp-ledger format |

## Quick reference

**The 9 principles** (full text in [principles.md](principles.md)):

1. **No drift-prone information** unless it carries semantic value
2. **Proper metric** — relevant, measured, never retroactively changed
3. **Plan first, change later** — temp-ledger pattern; auto-gen files refresh last
4. **Enforce via review, not by mechanical lint** — the `aid-reviewer` sub-agent is the authority
5. **Mark auto-generated / temporary files clearly** — directory + frontmatter
6. **Per-doc review metadata via frontmatter** — exempt from review
7. **Review is read-only on the repo** — discovery WRITES only to `.aid/knowledge/`
8. **Rigor follows value** — verify the load-bearing core with maximum rigor; scaffolding (frontmatter/changelog) gets present-and-parseable checks only
9. **Resolved items leave no trace** — record current state only; a resolved item is removed entirely (inventory, detail, roll-call, changelog), git history is the audit trail

**The 4 fact tiers** (full text in [tier-model.md](tier-model.md)):

| Tier | Stability | Inline in primary docs? |
|------|-----------|-------------------------|
| T1 Concept | months | YES — this is the knowledge |
| T2 Structure | weeks | YES — declared in `contracts:` frontmatter, lint-verified |
| T3 Metric | every commit | NO — lives in `.aid/generated/metrics.md` |
| T4 Temporal | every cycle | NO — lives in frontmatter `changelog:` or `STATE.md` history |

**Required frontmatter** (full text in [frontmatter-schema.md](frontmatter-schema.md)):

```yaml
---
kb-category: primary | meta | extension
source: hand-authored | generated
generator: <script>            # iff source: generated
intent: |
  What this doc is FOR. Drives the reviewer's relevance judgment.
contracts:
  - "Optional structural cardinality claims (T2)."
changelog:
  - YYYY-MM-DD: brief note
---
```

**Review treatment by category** (full text in [review-rubric.md](review-rubric.md)):

| kb-category + source | Rubric |
|----------------------|--------|
| primary + hand-authored | Full Primary — most rigorous |
| primary + generated | Full Primary + Build-Verify (applies to `INDEX.md`) |
| meta + hand-authored | Spot-Check Snapshot only |
| meta + generated | Build-Verify Only — skip content grading (applies to `metrics.md`, `project-index.md`) |
| extension + hand-authored | Extension-Scope (flagged outside the declared doc-set) |
| extension + generated | Extension Build-Verify — confirm script ran + spot-check (rare) |

## How tools consume these docs

- **`/aid-discover`** — reads each KB doc's frontmatter; picks rubric from [review-rubric.md](review-rubric.md); writes findings to temp ledger per [principles.md](principles.md) P3
- **`/aid-config`** — scaffolds new KB docs with frontmatter from [frontmatter-schema.md](frontmatter-schema.md) seed
- **`/aid-summarize`** — extracts `intent:` field from each doc to populate section descriptions in `knowledge-summary.html`
- **`aid-reviewer`** — validates frontmatter compliance; spot-checks `contracts:` against disk; flags inline T3/T4 markers in primary-category docs (REVIEW state of `/aid-discover`)
- **`build-kb-index.sh`** — composes `INDEX.md` from each doc's `intent:` + `kb-category:` + path
- **`build-metrics.sh`** — produces `metrics.md` with all numeric facts (T3) the project tracks
- **`build-project-index.sh`** — produces `.aid/generated/project-index.md`, a build-time inventory of repository files (used by `/aid-discover` Step 0c). Classified `meta + source: generated` → Build-Verify Only.

All three builders are registered in `.cursor/templates/generated-files.txt`
so `/aid-discover` FIX state can iterate them on auto-gen-last (per [principles.md](principles.md) P3).

## Project-specific extension

A project may add `.aid/knowledge/.review-checklist.md` (gitignored by default) to
extend the canonical rubric with project-specific lint rules. See
[review-rubric.md](review-rubric.md) for the format.

## See also

- `.cursor/agents/aid-reviewer/AGENT.md` — adversarial review (semantic + frontmatter + spot-check; the sole KB-quality enforcer)
- `.cursor/scripts/kb/build-metrics.sh` — T3 fact generator
- `.cursor/scripts/kb/build-kb-index.sh` — INDEX.md generator
- `.cursor/scripts/kb/build-project-index.sh` — project-index.md generator
- `.cursor/templates/generated-files.txt` — registry of all generated files + build commands
- `.cursor/templates/knowledge-base/*.md` — KB doc templates pre-filled with frontmatter
