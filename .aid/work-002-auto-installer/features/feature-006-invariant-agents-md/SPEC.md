# Invariant Root AGENTS.md (canonical normalization)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-04 | Feature identified from cross-reference Q1; REQUIREMENTS.md §4, §5 (FR12), §9 | /aid-interview (cross-reference) |

## Source

- REQUIREMENTS.md §4 Scope, §5 (FR12), §9; cross-reference Q1

## Description

A small **canonical-content normalization**: make the rendered root `AGENTS.md` **byte-identical**
across the four AGENTS.md-writing profiles (codex, cursor, copilot-cli, antigravity). Today they
differ by ~1 byte (a tool-specific token), which forces a tool-vs-tool collision when an adopter
installs more than one of these tools into the same repo. Making the file invariant eliminates that
collision entirely, so the installer's protect-on-diff warning (feature-001 / FR11) only ever fires
for the **user's own** file — never for a second AID tool.

This is a content change in the canonical source, re-rendered via the existing generator
(`run_generator.py`). It does **not** modify the render pipeline mechanics. claude-code is
unaffected (it uses `CLAUDE.md`, not `AGENTS.md`).

## User Stories

- As an adopter installing two AID-supported tools into one repo, I want their root `AGENTS.md` to be identical so that installing the second tool doesn't collide with or warn about the first.
- As the maintainer, I want one canonical `AGENTS.md` content so that I don't maintain four near-duplicate files.

## Priority

Should (simplification; correctness is already guaranteed by feature-001's protect-on-diff, so this reduces false-positive warnings rather than fixing a correctness bug)

## Acceptance Criteria

- [ ] After re-render, the root `AGENTS.md` is byte-identical across codex, cursor, copilot-cli, and antigravity (single sha256 across all four).
- [ ] The canonical source change is re-rendered via `run_generator.py` with no render-drift; the render pipeline itself is unchanged.
- [ ] No tool-specific information is lost that the tools actually require (verify the ~1-byte difference is incidental, not load-bearing).

## Dependencies

- Independent of the installer features (001–005); can be done anytime. Most valuable before multi-tool installs are common. claude-code `CLAUDE.md` out of scope.

---

## Technical Specification

### 1. Exact diff finding (evidence)

The four AGENTS.md-writing profiles produce **four distinct sha256 hashes**:

```
cfc8db24…  profiles/codex/AGENTS.md          (992 bytes)
1e8cd488…  profiles/cursor/AGENTS.md         (992 bytes)
c7ac1ec9…  profiles/copilot-cli/AGENTS.md    (992 bytes)
75631914…  profiles/antigravity/AGENTS.md    (991 bytes)
```

A pairwise `diff` shows the files are identical **except for a single line — line 16** — the
install-root prefix in the schema path inside the `## Review output format (global)` block:

```
codex        16: `.agents/templates/reviewer-ledger-schema.md`. Write the ledger as a single
cursor       16: `.cursor/templates/reviewer-ledger-schema.md`. Write the ledger as a single
copilot-cli  16: `.github/templates/reviewer-ledger-schema.md`. Write the ledger as a single
antigravity  16: `.agent/templates/reviewer-ledger-schema.md`.  Write the ledger as a single
```

The "~1-byte" framing comes from antigravity: `.agent` is one character shorter than
`.agents`/`.cursor`/`.github`, so its file is 991 vs 992 bytes. The other three are the same
length but still differ in the 4 prefix bytes (`agents`/`cursor`/`github`). **The differing
token is the per-tool install-root directory name**, nothing else.

### 2. Root-cause location

**Critical correction to a premise in the requirements half and AC.** The root agent files are
**hand-maintained, not generated**. They are NOT in any profile `emission-manifest.jsonl`, NOT
emitted by `run_generator.py`, and explicitly out of the manifest safety boundary
(`canonical/EMISSION-MANIFEST.md:83` — "Files outside any manifest (user-created,
hand-maintained) are **never touched**"). `run_generator.py` renders only the install **trees**
(`canonical/agents|skills|templates|scripts|recipes` → `profiles/<tool>/<install-root>/…`); it
contains zero references to `AGENTS.md`/`CLAUDE.md`.

The differing token therefore does **not** originate from `rewrite_install_paths` at render time
(that rewriter is what produces the *consumer* references inside the install tree, e.g.
`profiles/cursor/.cursor/skills/aid-execute/references/state-delivery-gate.md`). The root-file
divergence is **authored directly** in each profile's hand-maintained source:

- `profiles/codex/AGENTS.md:16`        → `.agents/templates/reviewer-ledger-schema.md`
- `profiles/cursor/AGENTS.md:16`       → `.cursor/templates/reviewer-ledger-schema.md`
- `profiles/copilot-cli/AGENTS.md:16`  → `.github/templates/reviewer-ledger-schema.md`
- `profiles/antigravity/AGENTS.md:16`  → `.agent/templates/reviewer-ledger-schema.md`

(Sibling for context, out of scope: `profiles/claude-code/CLAUDE.md:15` → `.claude/templates/…`.)

The token is install-root-relative because the schema file physically installs at a different
path per tool — each tool ships the schema only under its own dir:

```
.agents/templates/reviewer-ledger-schema.md   (codex)
.cursor/templates/reviewer-ledger-schema.md   (cursor)
.github/templates/reviewer-ledger-schema.md   (copilot-cli)
.agent/templates/reviewer-ledger-schema.md    (antigravity)
.claude/templates/reviewer-ledger-schema.md   (claude-code)
```

There is **no tool-invariant copy** of the schema (e.g. no `.aid/templates/…`). So the prefix is
"tool-specific by physical-layout necessity" for the link to resolve, but the AC asks whether the
specific prefix is *load-bearing* — see §5.

### 3. The normalization change (minimal, content-only)

Make line 16 **tool-agnostic** in all four hand-maintained root files so the byte content no
longer encodes the install root. The block is a project-wide convention reminder, not a
machine-parsed link; line 17 already uses the tool-invariant `.aid/.temp/review-pending/…` path
and line 10 uses tool-invariant `.aid/knowledge/INDEX.md`, so a non-rooted form is consistent
with the existing style of this block.

**Proposed replacement (line 16, identical in all four files):**

```
`templates/reviewer-ledger-schema.md` (under this tool's install root). Write the ledger as a single
```

This drops the leading install-root segment, replacing it with a relative path plus a short
parenthetical that names the resolution rule generically. Every agent already knows its own
install root (it is reading the file from inside that tree), so "under this tool's install root"
is unambiguous and resolves correctly for all four tools — while the **bytes are identical**.

Scope of edit (content-only, no pipeline change):

- Edit `profiles/codex/AGENTS.md`, `profiles/cursor/AGENTS.md`,
  `profiles/copilot-cli/AGENTS.md`, `profiles/antigravity/AGENTS.md` — line 16 only.
- **Do NOT** edit `run_generator.py`, any `render_*.py`, `rewrite_install_paths`, profile TOMLs,
  or `verify_deterministic.py`. The render pipeline is unchanged (satisfies §4 In-Scope /
  REQUIREMENTS §4 Out-of-Scope).
- **claude-code is unaffected**: `profiles/claude-code/CLAUDE.md` is a different file with other
  legitimate differences (title, `## Project` heading, `@.aid/knowledge`, permissions wording).
  It is out of scope and intentionally NOT normalized to match AGENTS.md. (Optionally, for
  maintenance symmetry only, CLAUDE.md:15 could receive the same wording change — but that is NOT
  required by FR12 and is not part of this feature's AC.)

The other ~991/992-byte content (titles, knowledge-base lines, permissions including codex's
`(Python, Bash, PowerShell)` parenthetical) is **already identical** across the four AGENTS.md —
line 16 is the *only* divergence — so normalizing line 16 alone achieves a single sha256.

### 4. Re-render + verification

Because the root files are hand-maintained, the change is a **direct edit of the four source
files**, not a canonical re-render. The AC phrase "re-rendered via `run_generator.py`" is adapted
as follows (and the verification steps satisfy its intent):

1. **Apply the edit** to line 16 of the four `profiles/<tool>/AGENTS.md` files.
2. **Invariance check** — single sha256 across all four:
   ```
   sha256sum profiles/{codex,cursor,copilot-cli,antigravity}/AGENTS.md | awk '{print $1}' | sort -u | wc -l
   # must print: 1
   ```
3. **Pipeline-untouched / no render-drift** — run the generator and its deterministic verify to
   prove the install **trees** are unchanged by this edit (the edit touches only out-of-manifest
   root files, so the manifest diff must be empty):
   ```
   python run_generator.py        # expect "0 deleted", VERIFY (deterministic): PASS
   git status --porcelain profiles/*/emission-manifest.jsonl profiles/*/.*/  # expect no changes
   ```
4. **Consumer references still resolve** — the in-tree consumer paths (e.g.
   `profiles/cursor/.cursor/skills/…/state-delivery-gate.md` referencing
   `.cursor/templates/reviewer-ledger-schema.md`) are produced by `rewrite_install_paths` and are
   intentionally left install-rooted; they are unaffected and still resolve. Only the
   hand-maintained root file is made tool-agnostic.

### 5. Safety check (token is not load-bearing)

The AC requires confirming the normalized token is not load-bearing. Evidence:

- The `## Review output format (global)` block is **human/agent-facing convention prose**, not a
  machine-parsed include. No tooling reads line 16 of the root AGENTS.md to locate the schema:
  `grep` shows the only consumers of the schema path are other **prose** reference files inside
  each install tree (which keep their own correct install-rooted path) and the schema file itself
  — none parse the root AGENTS.md.
- The schema file still ships at `<install-root>/templates/reviewer-ledger-schema.md` in every
  tool tree (unchanged). An agent following the relative `templates/reviewer-ledger-schema.md`
  from its own install root resolves to the real file in all four trees.
- The two other paths in the same block (`.aid/knowledge/INDEX.md`, `.aid/.temp/review-pending/`)
  are already tool-invariant and work today — establishing that tool-agnostic pathing in this
  block is correct and load-bearing-safe.

**Conclusion: the install-root prefix on line 16 is incidental, not load-bearing.** Removing it
loses no information any tool requires.

### 6. Testing (assert invariance, CI-able)

Add a single assertion that all four root AGENTS.md share one sha256. Recommended placement
alongside the existing canonical render/copy tests:

- Extend `tests/canonical/test-setup.sh` (which already byte-compares installed AGENTS.md to
  source at SU14a) with one new assertion, or add a focused check:
  ```bash
  uniq_hashes=$(sha256sum \
      "$REPO_ROOT"/profiles/{codex,cursor,copilot-cli,antigravity}/AGENTS.md \
      | awk '{print $1}' | sort -u | wc -l)
  assert_eq "$uniq_hashes" "1" "FR12 root AGENTS.md byte-identical across all four profiles"
  ```
- This guards against future drift: any maintainer who reintroduces a tool-specific token into one
  root AGENTS.md fails the check. Because the files are hand-maintained, this CI guard (not the
  generator) is the enforcement mechanism — a deliberate addition this feature contributes.

### 7. Risks

- **Premise mismatch in the AC (primary risk, mitigated above).** The AC/requirements imply the
  root file is generated and re-rendered by `run_generator.py`; it is not. Acting on that premise
  (editing a canonical source and expecting a re-render to update AGENTS.md) would be a no-op and
  silently leave the files divergent. This spec corrects the mechanism: edit the four
  hand-maintained files directly; use the generator only to *prove the trees are untouched*.
- **Wording-vs-link trade-off (low).** Dropping the explicit install root makes the reference a
  relative hint rather than a literal in-tree path. Mitigation: the parenthetical "(under this
  tool's install root)" plus the existing precedent (lines 10/17 already tool-agnostic) keeps it
  unambiguous; no tool machine-parses this line (§5).
- **CLAUDE.md divergence by design (informational, not a defect).** After normalization, the four
  AGENTS.md are identical to each other but still differ from claude-code's CLAUDE.md (different
  file, out of scope). This is expected and correct — FR11/FR12 only require AGENTS.md-vs-AGENTS.md
  invariance; CLAUDE.md is a single-tool file with no collision partner.
- **Future-drift without the test (medium if §6 omitted).** Since nothing generates these files,
  invariance is only as durable as the CI guard. The §6 assertion is therefore part of the
  feature's deliverable, not optional.
- **Line-length / lint (low).** The replacement line is slightly longer than the original; if any
  markdown line-length lint applies to these files, the parenthetical may need trimming (e.g.
  `(under this tool's dir)`). Verify against repo lint config before finalizing wording.
