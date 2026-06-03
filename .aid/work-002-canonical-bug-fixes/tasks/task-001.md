# task-001: complexity-score.sh — four correctness fixes (A1–A4)

**Type:** IMPLEMENT

**Source:** work-002-canonical-bug-fixes → delivery-001

**Depends on:** — (none)

**Scope:**
All four fixes are in `canonical/scripts/execute/complexity-score.sh`. One cohesive pass over the
script; review as a unit.

- **A1 — Type matching (~line 168).** The risk loop greps only `^\*\*Type:\*\*` (bold), but the
  canonical recipe template and all six recipes emit the flat `- Type: …` form
  (`templates/recipe-template.md:58`, `recipes/bug-fix.md:57`, etc.). Change the `type_line` capture
  to a case-insensitive ERE that accepts both, e.g.
  `grep -m1 -iE '^[[:space:]]*(- )?\*{0,2}Type:\*{0,2}'`. Leave the `case` risk-weight mapping
  (MIGRATE/REFACTOR +2, IMPLEMENT/TEST +1, else +0) unchanged.

- **A2 — portable awk (~line 81).** Replace the gawk-only 3-arg
  `match($0, /delivery-([0-9]+)/, m) && m[1] == did` with a portable 2-arg `match()` +
  `substr($0, RSTART, RLENGTH)` capture, compared numerically with base-10 forcing (mirror the
  pattern already in `compute-block-radius.sh`). Scan the whole script and confirm no other 3-arg
  `match(...)` remains. Must run under BSD/macOS awk and mawk.

- **A3 — lite/recipe graphs (~lines 78–90).** `--plan-file` only extracts `#### Execution Graph`
  nested under `### delivery-`. Add a fallback: when the PLAN has no `### delivery-` section, capture
  the top-level `## Execution Graph` block (`templates/specs/lite-spec-template.md:38`; all recipes)
  and drop the `--delivery-id` requirement for that shape. Guard the lite extractor so it stops at
  the next equal-or-higher heading and does NOT swallow a preceding/following `## Tasks` table or the
  `### Task Dependencies` / `### Can Be Done In Parallel` subheadings — only `| Task | Depends On |`
  rows under the Execution Graph heading become edges.

- **A4 — cycle guard (~lines 131–153).** `compute_depth()` memoizes but has no in-progress guard; a
  circular `Depends On` recurses until bash aborts. Add a recursion-stack marker (e.g.
  `DEPTH_VISITING`) that detects the back-edge, breaks that path (contributes 0), warns to stderr,
  and still yields a finite `depth=`/`score=`/`tier=` with exit 0. Acyclic results must not change.

**Acceptance Criteria:**
- [ ] A1: bold `**Type:** IMPLEMENT` scores +1 and flat `- Type: REFACTOR` scores +2 (was 0);
      non-risk types still score +0.
- [ ] A2: no 3-arg `match` remains; under `mawk` a multi-delivery PLAN extracts the correct delivery
      graph (was an empty graph); delivery-id matching is exact and leading-zero tolerant.
- [ ] A3: a lite spec and a recipe spec (top-level `## Execution Graph`) score correctly and exit 0
      (was empty graph + exit 2); a full multi-delivery `PLAN.md` is unchanged with no `## Tasks`
      rows captured and no cross-delivery bleed.
- [ ] A4: a 2-node cycle and a self-loop terminate with a finite depth + warning; linear/diamond
      acyclic depths are identical to the pre-change script.
- [ ] All §6 quality gates pass; `bash tests/run-all.sh` passes (add/extend complexity-score
      coverage for the recipe Type form, non-gawk awk, lite graph, and cyclic graph).
