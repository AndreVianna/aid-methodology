# task-044: `provenance.test.mjs` -- the AC-5 suite

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-044. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-044/STATE.md.
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

**Type:** TEST

**Source:** work-001-skill-explorer -> delivery-004 (feature-005-verbatim-source-provenance)

**Depends on:** task-043

**Scope:**
- Author `site/scripts/__tests__/provenance.test.mjs` -- a new file kept separate from `gen-skills.test.mjs`, `flow-graph.test.mjs` and `flow-graph-doorways.test.mjs`, each suite owning one artifact, for the same reason feature-001 keeps its suite separate from `gen-reference.test.mjs`. Run by the site's existing `npm test` and enforced on pull requests by the CI step task-004 added.
- Six groups: the **AC-5 whole-corpus sweep**; the **link half**; **containment** over inline fixtures; the **verifier**; **determinism**; and the **no-JS invariant**.
- **The link half is proven offline.** No test makes a network call, so "resolves to real lines" is established as: the range exists on disk (the sweep) **and** the URL is that range's mechanical encoding. That is the honest reading of AC-5 and the only one that is offline-deterministic.
- Containment fixtures are written in the test file and depend on nothing outside it. The `title=` assertion is the testable half of the Expressive Code guard -- asserting the plugin's own line-deleting behaviour would mean rendering the page, so the suite asserts the meta option that disarms it.
- Determinism is asserted **on the section in isolation**, so a failure localises: feature-001's suite already asserts the whole page by byte comparison.

**Acceptance Criteria:**
- [ ] The AC-5 sweep enumerates directories **from disk** with **no literal count**, and for every node of every chart asserts that `provenance.file` exists and is under `canonical/`, that `1 <= startLine <= endLine <= lineCount(file)`, and that `excerpt` equals `readFileSync(file,'utf8').split('\n').slice(startLine-1, endLine).join('\n')`.
- [ ] `detail`, when present, passes the path and range checks and is **not** compared for excerpt equality.
- [ ] The link half asserts that each entry contains exactly one `[Source: ...]` link whose href equals `GITHUB_BLOB_BASE + '/' + provenance.file + anchor`, with `#L<n>` for a single-line range and `#L<a>-L<b>` otherwise -- **and no test performs a network request**.
- [ ] Containment fixtures round-trip byte-for-byte: a 4-backtick run, a pipe, `<div>`, `{braces}`, and a complete fenced block; a fragment containing a `~~~~` line at column 0 forces a 5-tilde fence.
- [ ] **Every emitted fence is asserted to carry a `title="` meta option** -- the guard that disarms Expressive Code's file-name-comment scan, which would otherwise delete a heading line from four known corpus lines.
- [ ] **The verifier group has a synthetic failing case for every check task-041 implements -- P0 through P6 -- and each is asserted to throw**, so no check task-041 ships is left unproven: **P0** a cited file whose text contains a `\r`; **P1** three separate rejections -- a `file` outside `canonical/`, a path containing a `..` segment, and a path that does not exist on disk; **P2** a non-integer line number **and** an inverted range where `startLine > endLine`; **P3** `endLine` beyond EOF; **P4** an `excerpt` differing from its slice by one character; **P5** a range whose slice is entirely whitespace (which passes P4 and must still fail); **P6** a `detail` whose file lies outside `canonical/`, and a `detail` whose range does not exist -- checked with P1-P3 only and never for excerpt equality.
- [ ] Every one of those throws carries the correct stable guard name of the three (`provenance path`, `provenance range`, `provenance excerpt`), plus the skill, the node id and `file#L...`; **and the P4 message additionally names the first differing line**, which task-041's message-format criterion requires and which nothing else asserts.
- [ ] Determinism: `renderFragmentList` on the same chart twice returns identical strings, and two `gen:skills` runs leave the fragment section byte-identical.
- [ ] The no-JS invariant: the rendered markdown contains no `<script`, no `client:` directive and no `import`, and the `[Source: ...]` link count equals `chart.nodes.length`.
- [ ] Tests are deterministic, use clean setup/teardown, build their own fixtures in the test file, and read nothing under `.aid/works/`.
- [ ] AC-5 is fully covered, in both its verbatim-fragment and deep-link halves.
- [ ] All section-6 quality gates pass
