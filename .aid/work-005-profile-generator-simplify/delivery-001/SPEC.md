# Delivery SPEC -- delivery-001: Format Decision + Symmetric Copy Generator

> **Delivery:** delivery-001
> **Work:** work-005-profile-generator-simplify
> **Created:** 2026-06-20

---

## Objective

Deliver the radically simpler **copy-based generator** on the symmetric per-tool layout, resting on an evidence-based format decision. This delivery makes the decision (feature-001: the capability study + the uniform-markdown, verify-first FR4 decision) and acts on it (feature-002: collapse the 13-script / ~7,000-LOC compiler to ~4 scripts / ~900–1,300 LOC, unify Codex `.agents/`→`.codex/`, delete all rules-folder machinery, FR5 minimal `{root}`-prefix). The repo renders the new `profiles/*` trees + re-renders the dogfood `.claude/`, drift-clean, and adds a mechanized §7a/C2 byte-identity guard. It is internally complete but is not released alone (see the Release-Safety Gate in PLAN.md).

## Scope

- **feature-001-behavioral-parity-format** — the per-tool capability study (`capability-study.md`, table + decision section) + the FR4 format decision; the AC4b gate (study produced before any branch deleted) is an intra-delivery task ordering.
- **feature-002-symmetric-copy-generator** — the copy-based generator; Codex unify (FR2); drop all rules folders + `canonical/rules/` + extras mechanism (FR3); `canonical/aid/` reshape (A4); FR5 minimal `{root}`-prefix (Option (c)); delete the dead emitter conformance tests + CI de-wire; re-render `profiles/*` + dogfood `.claude/`; new `tests/canonical/test-dogfood-byte-identity.sh`.

**Out of scope:** install-time migration of user repos (delivery-002); `release.sh` codex roots, docs/site/KB lockstep, the final CI/multi-tool acceptance gate (delivery-003). No release is cut from this delivery.

## Gate Criteria

- [ ] **AC4b** — the per-tool capability study is produced + documented before any format branch is deleted; the FR4 decision cites it.
- [ ] **AC1** — all 5 tools render the uniform internal `{agents, skills, aid}` shape under their host-required root dir; the same canonical content is provably present in each tree.
- [ ] **AC2** — generator script count + LOC substantially reduced; determinism, prune manifest, and render-drift CI guarantees intact.
- [ ] **AC6** — §7a byte-identity (mechanized guard), ASCII-only, and content-isolation invariants all hold.
- [ ] render-drift CI is green; the dogfood `.claude/` is byte-identical to `profiles/claude-code/.claude/`.
- [ ] All section-6 quality gates pass

## Tasks

_none yet_ -- aid-detail will fill this.

| Task | Type | Title |
|------|------|-------|

## Dependencies

- **Depends on:** -- (none; foundation)
- **Blocks:** delivery-002, delivery-003

## Notes

- AC4b ordering gate is an **intra-delivery task dependency** (study → decide → then delete branches), not a separate delivery.
- **AC4a** (feature-001's 3-tool behavioral check) is gated in **delivery-003's AC4**, not here — the multi-tool behavioral check needs all rendered trees + the install path, available only at delivery-003. delivery-001 gates AC4b (study-before-deletion); AC4a is owned downstream, nothing uncovered.
- E-CODEX-1 may stay `docs`-only / `medium` during this delivery — the Codex TOML branch ships **dormant** (verify-first), with a tracked follow-up to delete it once E-CODEX-1 is `high`.
- **Release-Safety Gate (PLAN.md):** this delivery may merge to master, but NO release until delivery-001+002+003 all merge.
