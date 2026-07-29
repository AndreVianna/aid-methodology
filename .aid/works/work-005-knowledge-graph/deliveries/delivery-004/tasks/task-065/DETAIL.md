# task-065: Graph assembly, payload embedding and byte-identical predicate inlining

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

**Source:** work-005-knowledge-graph -> delivery-004

**Depends on:** task-045, task-057, task-058, task-062, task-064

**Scope:**
- Author the graph's section manifest in the template set and the mechanics that materialise
  `.aid/.temp/graph/graph-src/` into the exact layout `assemble.sh` already validates:
  `skeleton-head.html`, `sections/*.html`, `section-manifest.txt`, `skeleton-foot.html`,
  `post-script.html`.
- Invoke the **unmodified** `canonical/aid/scripts/summarize/assemble.sh` with
  `--src .aid/.temp/graph/graph-src --manifest <the graph's section-manifest.txt>
  --output .aid/knowledge/graph.html` (feature-011 D5). No assembler is forked and the script's
  defaults are untouched.
- Build `post-script.html` as one inline `<script type="module">` whose body is
  `coverage-predicate.mjs` **inlined byte-identically first**, then `graph-model.js`,
  `graph-controls.js` and `graph-table.js` in manifest order, followed by the reused
  `lightbox.js` tail the `{{INLINE_LIGHTBOX_JS}}` contract fills.
- Read the shared module from **the tree that generates the page** --
  `<install-root>/aid/scripts/graph/coverage-predicate.mjs` -- resolved at run time, never from a
  hard-coded `canonical/…` path.
- Embed `relationships.md` verbatim as
  `<script type="text/markdown" id="graph-relationships" data-encoding="base64">`, using the
  `/aid-summarize` payload element contract.
- Emit the `<!-- aid-graph inputs-digest: <hex> -->` comment carrying the same composite digest
  `relationships.md` frontmatter records (feature-010 D2).
- **Out of scope:** authoring `coverage-predicate.mjs` (task-045, delivery-003); the RENDER state
  prose that calls this machinery (task-066); computing the digest itself (task-027,
  delivery-002); companion-asset layout, which exists only if delivery-001's packaging produced
  any; any edit to `assemble.sh` or any other shared summarize script.

**Acceptance Criteria:**
- [ ] `assemble.sh` is invoked with the three flags above and is **unmodified**; its defaults
      (`SRC_DIR=".aid/.temp/summarize/summary-src"`, `OUTPUT=".aid/knowledge/kb.html"`) are
      untouched, so `test-guardrails-d012.sh`'s `C1b` and `NM-e` assertions on that file still
      hold, and no assembler or validator logic is duplicated (AC-17, C-4).
- [ ] `.aid/.temp/graph/graph-src/` contains exactly the five-part layout `assemble.sh` validates
      for existence and non-emptiness, and assembly fails loudly if any part is missing.
- [ ] The inlined module block places `coverage-predicate.mjs` **first and byte-identically** --
      no wrapper, no transform, no re-export -- followed by the view files in manifest order; the
      whole block is one module scope and contains **no `import` statement** anywhere.
- [ ] The module's bytes are read from the generating tree's own
      `<install-root>/aid/scripts/graph/coverage-predicate.mjs`: a grep over the assembly code and
      the manifest finds **no `canonical/` path to the module**, and running the assembly from a
      rendered profile tree inlines that tree's copy.
- [ ] `relationships.md` is embedded as `<script type="text/markdown" id="graph-relationships"
      data-encoding="base64">` carrying base64 of the UTF-8 bytes, decodable by
      `new TextDecoder().decode(Uint8Array.from(atob(b64), c => c.charCodeAt(0)))`; the assembled
      page issues no network request and reads no second file (AC-10).
- [ ] The payload is a `text/markdown` script, so `validate-html-output.sh`'s NM.1 awk rule
      excludes it (`is_md_payload`) regardless of size -- confirmed by running the validator over
      the assembled page.
- [ ] The page carries exactly one `<!-- aid-graph inputs-digest: <hex> -->` comment and its hex
      equals `relationships.md`'s `graph_inputs_digest`, so STALE-CHECK can compare the artifacts
      without parsing the table.
- [ ] Re-assembling from an unchanged `graph-src` produces a byte-identical `graph.html`.
- [ ] All existing canonical suites still pass, and no suite is modified by this task; the named
      suite is `tests/canonical/test-graph-view-shell.sh`, where task-070 carries GV02's same-tree
      byte-identity assertion. *(Stated override of the IMPLEMENT default "unit tests for all new
      public methods", per the vehicle note in task-059.)*
- [ ] Build passes: `python .claude/skills/generate-profile/scripts/run_generator.py` completes;
      the render-drift confirmation for this delivery is task-069.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
