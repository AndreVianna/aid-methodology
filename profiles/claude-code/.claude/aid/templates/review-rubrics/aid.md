# Review Rubric — AID class

**Family:** none — this class is guarded by `canonical/EMISSION-MANIFEST.md` at repo root and is
**unreachable** in adopter installations.
**Kind:** A (adversarial content grade)
**Universal tier:** [`INDEX.md`](INDEX.md)

Severity is looked up from
[`grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale).

Apply these rules on **every review that adds, moves, or renames AID-delivered files**, regardless of
task type. They are the catalog relocation of the former "Standing KB-Convention Checks" block in
`aid-reviewer/AGENT.md`.

---

## Rules

| Rule | Check | Criterion | Modality | Mode | Evidence | Severity |
|---|---|---|---|---|---|---|
| `AID-01` | Every AID-own directory is nested under an `aid/` subtree, not emitted at an un-nested tool path | `authoring-conventions.md § Content Isolation` | MUST | judgment | Name the emitted path and the correct nested path per `canonical/EMISSION-MANIFEST.md`. An AID-own dir at `.claude/scripts/` instead of `.claude/aid/scripts/` is the finding | `[HIGH]` |
| `AID-02` | Every AID file inside a tool-native directory carries the `aid-` prefix | `authoring-conventions.md § Content Isolation` | MUST | mechanical | `find` tool-native dirs (`agents/`, `skills/`, `rules/`) and flag any file whose basename does not start with `aid-` and is AID-managed | `[HIGH]` |
| `AID-03` | No new AID content is placed at the `.github` root — copilot-cli scoping walks only `.github/{agents,skills,aid}` | `lib/aid-install-core.sh` `_prune_tool_dirs` scoping comment (R1) | MUST | judgment | Name any AID file outside `.github/agents/`, `.github/skills/`, or `.github/aid/` | `[HIGH]` |
| `AID-04` | No AID-own content lives at the `.codex/` root outside `.codex/aid/` | `canonical/EMISSION-MANIFEST.md § Filename and Location` | MUST | judgment | Name any AID file under `.codex/` that is not under `.codex/aid/` | `[HIGH]` |
| `AID-05` | Orphan pruning uses manifest membership — not a diff against an old manifest or by directory alone | `authoring-conventions.md § Content Isolation` | MUST | judgment | Name the prune logic and what it keys on. Pruning by directory or by old-manifest diff is the finding | `[CRITICAL]` |
| `AID-06` | Root-agent updates perform an in-place region replacement between `AID:BEGIN` / `AID:END` — no `.aid-new` sidecar | `authoring-conventions.md § Content Isolation` | MUST | mechanical | `grep` for `.aid-new` sidecar writes, or read the install path and confirm in-place region copy | `[CRITICAL]` |

---

## Severity note

Isolation violations that break prune correctness anchor at `[HIGH]`. Violations that could cause
**user content to be pruned** anchor at `[CRITICAL]`. These are Fixed anchors — the
radius/reversibility shape does not vary between instances for these rules.

---

## See also

- [`INDEX.md`](INDEX.md) — routing (the `AID` class is manifest-guarded)
- [`authoring-conventions.md`](../../.aid/knowledge/authoring-conventions.md) — cornerstone isolation rule

## Change Log

| Date | Change |
|---|---|
| 2026-07-28 | Created. Six rules relocated from `aid-reviewer/AGENT.md` Standing KB-Convention Checks. |
