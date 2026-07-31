# task-041: Provenance verifier

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-041. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-041/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-001-skill-explorer -> delivery-004 (feature-005-verbatim-source-provenance)

**Depends on:** task-039

**Scope:**
- Create `site/scripts/lib/provenance/verify.mjs`: `verifyProvenance(chart) -> void`, running checks **P0 through P6** per node (and P1-P3 on `detail`), **throwing on the first violation**, with a per-run `Map<file, {text, lines}>` cache so each cited file is read **once per run** rather than once per node -- material when a doorway corpus shares a single engine file.
- **P0:** the cited file's text contains no `\r`. `.gitattributes` forces `*.md text eol=lf` and zero CRLF files were measured under `canonical/skills/`; a mis-configured checkout would otherwise fail every excerpt comparison with a confusing diff instead of a one-line cause. **P1:** `file` is non-empty, POSIX, under `canonical/`, free of `..`, and exists on disk. **P2:** `startLine`/`endLine` are integers with `1 <= startLine <= endLine`. **P3:** `endLine <= lineCount(file)` -- the range exists. **P4:** `excerpt === lines.slice(startLine-1, endLine).join('\n')`, safe as a byte comparison because of P0. **P5:** the excerpt contains at least one non-whitespace character -- a range citing only blank lines renders as an empty box and exposes nothing, which fails AC-5's "the verbatim prompt fragment is exposed" while passing P4. **P6:** `detail`, when present, gets P1-P3 only; it carries no excerpt by contract.
- Three new stable, greppable, assertable guard names in feature-001's vocabulary: `provenance path`, `provenance range`, `provenance excerpt`. Messages follow `[gen-skills] <guard>: <detail>`, uncaught, reusing that prefix because this code runs inside that generator. Each message names the skill, the node id and `file#L...`, and the excerpt-mismatch message names the first differing line.
- **Throw, not warn**, for four reasons that must not be re-litigated downstream: the criterion says "the build surfaces it rather than emitting a broken link", and a warning in a log nothing reads emits the broken link anyway; it matches the posture of both features this sits between (feature-001's drift guard throws, feature-003's validator caller throws); FR-2's best-effort boundary does not reach here, because a recorded range that does not match its file is a **factual inconsistency between the artifact and its own cited source**, not a lossy interpretation; and NFR-3 makes the link the corrective of last resort -- a wrong label is survivable because the fragment corrects it, a wrong fragment because the link does, but a wrong link has nothing behind it. Rejected: warn-and-omit-the-link (a page that silently fails AC-5 for one node, strictly worse than a red build) and warn-and-emit (ships the broken link the criterion names).
- Conventions as the rest of the cluster: ESM `.mjs`, `node:` builtins only, 2-space indentation, no new dependency, pure exported function with no import-time side effect.

**Acceptance Criteria:**
- [ ] Each of P0 through P6 has a synthetic case that throws, and each carries the correct stable guard name of the three.
- [ ] Every thrown message contains the skill, the node id and `file#L...`; the P4 message additionally names the first differing line.
- [ ] **P5 rejects an all-whitespace slice even though P4 passes** -- the case that would otherwise render an empty box and silently fail AC-5.
- [ ] A `file` outside `canonical/`, a `..` segment, a non-existent path, and `endLine` beyond EOF are each rejected.
- [ ] Verification **throws on the first violation** -- it never warns, never omits a link, and never returns a partial result.
- [ ] `detail` is checked with P1-P3 only and is never compared for excerpt equality.
- [ ] Each distinct cited file is read **once per run**, asserted by counting reads across a chart citing the same file from multiple nodes.
- [ ] The guard names `provenance path`, `provenance range` and `provenance excerpt` are stable string literals a test can assert on and a CI log can be grepped for.
- [ ] Exit-code semantics are unchanged: an uncaught throw exits 1; no new exit code is introduced.
- [ ] Unit tests exist for every check; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
