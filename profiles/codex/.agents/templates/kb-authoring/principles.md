# KB Authoring — Principles

> Normative rules for authoring `.aid/knowledge/` Knowledge Base documents.
> See [README.md](README.md) for the index and the list of tools that consume these docs.

These principles exist because **review effort scales with what's in the KB, not with
what's useful in the KB**. Every claim a reviewer must verify is a tax on the discovery
cycle. The principles below remove information that adds review cost without adding
knowledge value — and keep the information that's actually load-bearing.

## P1. No drift-prone information unless it carries semantic value

Three classes of content are commonly inlined into KB docs but rarely carry value:

- **(a) Cosmetic counting** — line counts, byte counts, method counts, "this file has
  N functions". The number drifts every commit; the reader can run `wc -l` themselves.
  **Banned from primary docs.** Replace with structural assertions where the count is
  load-bearing (see [tier-model.md](tier-model.md) T2 Structure).
- **(b) Dates without semantic anchor** — "as of 2026-05-22", "verified during cycle-N",
  inline timestamps in historical narratives. Git log carries this with higher fidelity.
  **Banned from primary docs.** Allowed in: `STATE.md` Review History (which is exempt
  from review), per-doc `changelog:` field (frontmatter, exempt from review), and as a
  semantic anchor only when the date marks a load-bearing inflection
  (e.g., "post-FR2 retirement, 2026-05") — even then, justify case-by-case.
- **(c) Other low-value clutter** — requires judgment. When unclear whether something is
  load-bearing, ask the user. Default to removal.

## P2. Proper metric

When a numerical fact IS load-bearing, it must follow three rules:

- **(a) Relevance** — the metric must serve a concrete purpose (driving an agent's
  decision, enforcing a contract, signaling a constraint). If you can't state what
  consumes it, it isn't proper.
- **(b) Measure before registering** — the value must be derived from disk truth at
  the moment of authoring. No copying old values forward; no estimating.
- **(c) No retroactive changes** — once a metric is correctly measured and registered,
  do NOT update it in historical contexts. A statement like
  "pre-canonical-generator the trees diverged at 453 / 1,078 / 1,090 lines" is a
  HISTORICAL FACT and must stay accurate to that point in time, regardless of present-day
  file sizes. Retroactive edits corrupt historical narrative into present-tense lies.

## P3. Plan first, change later

Review and fix are SEPARATE phases. Never blend them.

The discipline is encoded as a temp-file ledger pattern at
`.aid/.temp/review-pending/<skill-name>.md`:

1. **REVIEW phase** — as findings are identified, **upsert** each one to the ledger file.
   Each entry has: id, severity, source-doc + line, claim/issue, fix-tier (T1/T2/T3/T4),
   status (`pending` initially).
2. **FIX phase** — process the ledger top-to-bottom. For each entry, mark `in-progress`,
   apply the fix, mark `fixed`, then remove the entry from the file (or move to a
   resolved section if you want to inspect later).
3. **Completion** — when the file is empty, FIX is done. Delete the file. Move to next state.

**Rationale:** restart-safe (a session crash leaves the ledger intact for resume);
prevents cascade-fixing (you see ALL findings before applying ANY); enables batched
commits per scope; allows deferral (mark `deferred: <reason>` instead of fixing if
out of cycle scope).

**Auto-generated files refresh LAST.** Hand-edits land first; generated files
(metrics.md, INDEX.md, project-index.md) regenerate at the end of FIX, so they reflect
the final state. Refresh is driven by `.agents/templates/generated-files.txt`
registry.

## P4. Enforce via lint, not convention

Convention alone won't survive contributor turnover. The principles must be enforced
mechanically:

- `.agents/scripts/kb/verify-claims.sh` is the enforcer. It parses
  frontmatter, validates declared `contracts:` against disk, warns on inline T4
  markers in primary-category docs, and confirms registered generated files were
  regenerated.
- A per-project checklist may extend the linter, but the linter is the authority.
  See [review-rubric.md](review-rubric.md) for the rubric the linter executes.

The checklist itself is intentionally adaptable per project profile — a CLI project's
KB has different shape than a web-app's. The checklist template lives at
[review-rubric.md](review-rubric.md) and may be extended via per-project `.aid/knowledge/.review-checklist.md`
overrides (gitignored by default; see [frontmatter-schema.md](frontmatter-schema.md)).

## P5. Mark auto-generated / temporary files clearly

Two kinds of non-curated files exist:

- **Generated content** (`.aid/generated/*`) — persistent build artifacts produced by
  registered scripts. Each file MUST carry an HTML-style comment at the top:

  ```html
  <!-- AUTO-GENERATED 2026-05-27T12:34:56Z by build-index.sh — DO NOT EDIT — regenerate with `bash .agents/scripts/kb/build-index.sh` -->
  ```

  The `source: generated` + `generator: <script>` frontmatter fields also declare this.
- **Temporary state** (`.aid/.temp/*`) — transient ledger / scratch files used during
  a skill's state machine execution. Gitignored. Lifecycle = "exists during a skill
  cycle; deleted when complete".

Skills MUST NOT review files in `.aid/.temp/`. Skills MUST verify generated files were
regenerated (existence check + build-script run) but do not grade the content beyond
spot-check correctness — see [review-rubric.md](review-rubric.md).

The canonical-default excluded paths are listed in [review-rubric.md](review-rubric.md).
Per-project additions are declared via `kb-category` + `source` frontmatter on each doc
(per P6); the lint reads frontmatter to determine review treatment.

## P6. Per-doc review metadata via frontmatter

Every KB doc carries YAML frontmatter declaring how it should be reviewed:

```yaml
---
kb-category: primary | meta | extension
source: hand-authored | generated
generator: <script>            # required iff source: generated
intent: |
  What this doc is FOR. Drives the reviewer's relevance judgment.
contracts:
  - "Structural claim 1 (verified by lint)"
  - "Structural claim 2"
changelog:
  - 2026-05-26: Migrated to v2 format (KB Authoring overhaul)
---
```

**The whole frontmatter block is exempt from review.** Reviewer reads it for
classification + intent; doesn't grade its content. Changelog drift, intent prose
quality, contract count — none affect the grade. This gives docs a way to carry
self-describing metadata without polluting the review surface.

See [frontmatter-schema.md](frontmatter-schema.md) for the full schema specification.

## P7. Review is read-only on the repo

`/aid-discover` and the discovery skill family READ the repository and WRITE to
`.aid/knowledge/`. They MUST NOT modify any file outside `.aid/knowledge/`,
`.aid/generated/`, or `.aid/.temp/`.

If a review finds the repo is wrong (a citation points to a missing line; a contract
mismatches disk), the response is:

- **Fix the KB** — if the KB's assertion was wrong (the file was reorganized; the
  claim was stale); or
- **Raise a tech-debt entry** in `.aid/knowledge/tech-debt.md` — if the repo is
  genuinely missing the documented behavior.

The KB follows the repo, never the reverse. **Modifying repo code, configs, skills,
templates, or installers from within a `/aid-discover` cycle is a category violation
and a hard guard in the skill's pre-flight.**

Exception: the one-time KB-format migration (when these principles are first applied
to an existing project) is a separate operation — not a review. It may touch KB doc
content liberally because the act of migration is structural, not corrective.

---

## How the principles interact

- **P1 + P6** — frontmatter exemption gives docs a place to carry historical / metric /
  temporal info without exposing it to review. The principles ban inlining; the
  frontmatter accepts it.
- **P2 + P5** — proper metrics live in generated files (metrics.md), regenerated from
  disk truth; inlined "proper metrics" are still drift-prone.
- **P3 + P5** — the temp ledger pattern is itself a temporary file convention.
- **P4 + P6** — the lint enforces what the frontmatter declares.
- **P7 + P3** — review is observation only; the temp ledger is the action queue, but
  it acts on the KB, never on the repo.

## See also

- [tier-model.md](tier-model.md) — T1-T4 stability tiers for individual facts within a doc
- [frontmatter-schema.md](frontmatter-schema.md) — schema specification + per-field rules
- [review-rubric.md](review-rubric.md) — per-category review treatment
- [README.md](README.md) — index of the kb-authoring docs
