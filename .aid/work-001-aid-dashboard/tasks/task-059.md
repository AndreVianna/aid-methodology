# task-059: /aid-config kb_baseline schema key — additive settings template + validation table (schema owner)

**Type:** CONFIGURE

**Source:** feature-007-kb-dashboard → delivery-009

**Depends on:** —

**Scope:**
- Add the additive, `/aid-config`-owned **`kb_baseline: {branch, tip_date}`** key to the per-repo settings schema (DD-A4, LC-A7, R13). `/aid-config` is the **schema owner**; the producers (task-061 `aid-discover`, task-062 `aid-housekeep`) are the **writers** and the reader (task-064) is the consumer — this task fixes the shape all three resolve against. This is the **seam** of the producer-chain + reader areas.
- **`canonical/templates/settings.yml`:** add the documented `kb_baseline` block exactly as DM-A4 specifies — a commented nested block (`branch:` + `tip_date:`) marked "written by aid-discover / aid-housekeep, read by the dashboard reader for FR35 outdated-detection. Absent until the first KB generation." Additive: no existing key changes; an absent `kb_baseline` ≡ "no baseline recorded" (the reader reads `null` and the freshness check is skipped, stays `approved`).
- **`canonical/skills/aid-config/SKILL.md` validation table:** add the `kb_baseline` key with its shape (`{branch: <default-branch>, tip_date: <ISO-8601 commit date>}`) — producer-written, NOT user-authored; validation tolerates absence. Cross-reference feature-010 residual-OQ #5 (the two features' `settings.yml` reads must agree).
- **Write-path note (no write-idiom change here — documentation only):** `kb_baseline` is a **MULTI-LINE nested block**, so the producers' *first* write uses `/aid-config`'s "append a new block" idiom (`SKILL.md` Step 6, second idiom — intro at `SKILL.md:126`, code fence `:127-132`), NOT the single-line "Save in place" replace prose at `SKILL.md:124`; a re-stamp of `tip_date` is that single-line replace (`:124`) inside the existing block (R13). This task documents the schema + which write path applies; the producer tasks execute the writes.
- Edits are **canonical/-authored** (rendered to `.claude/` + 5 install trees by task-063's FULL `run_generator.py` — NOT a per-script renderer, NOT a vendor-refresh). **ASCII-only.** Behavior-additive (C7 — no existing `/aid-config` validation/decision changes). Edits `canonical/**` only; do NOT edit `.claude/**` here (that is task-063).

**Acceptance Criteria:**
- [ ] `canonical/templates/settings.yml` carries the documented additive `kb_baseline: {branch, tip_date}` block (DM-A4) — commented, marked producer-written/reader-read, "absent until first KB generation"; no existing key is changed or reordered.
- [ ] `canonical/skills/aid-config/SKILL.md` validation table lists `kb_baseline` with its `{branch, tip_date}` shape, flagged producer-written (not user-authored) and absence-tolerant.
- [ ] The schema documents the block-vs-line write-path selection (multi-line `kb_baseline` first write uses the append-block idiom — intro `SKILL.md:126`, fence `:127-132`; single-line `tip_date` re-stamp uses the replace idiom `SKILL.md:124`) so task-061/task-062 resolve the identical idiom (R13).
- [ ] All touched canonical files are ASCII-only; the edit adds content only and changes no existing `/aid-config` validation, gate, or decision (C7-additive).
- [ ] All §6 quality gates pass; the canonical edit is left to be dogfood-rendered by task-063 (this task does not run `run_generator.py` and does not modify `.claude/**`).
