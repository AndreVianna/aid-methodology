# task-042: Fragment-list renderer

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-042. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-042/STATE.md.
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

**Depends on:** task-040

**Scope:**
- Create `site/scripts/lib/provenance/render-list.mjs` with `buildEntries(chart)` and `renderFragmentList(entries)`.
- `buildEntries` iterates `chart.nodes` in **array order and does not re-sort** -- feature-003 guarantees ascending `order` with no gaps, and a second sort would create a second ordering authority that could silently disagree with the chart. Entry count equals node count, with **no de-duplication** even when two nodes cite the same range, because the 1:1 node-to-entry mapping is what AC-5 is checked against. Self-edges add no entry: the list is node-indexed.
- `renderFragmentList` emits one `## Source fragments` H2 (an H2 so Starlight's table of contents anchors it as a sibling of the chart's `## Flow`), one fixed intro sentence carrying **no count**, then one entry per node in chart order.
- Each entry is three blocks at **column 0**: a lead-in paragraph carrying the inline `<a id="fragment-<nodeId>"></a>` anchor on the same line as the text (so CommonMark parses it as inline HTML inside a paragraph rather than as an HTML block), the position, the name in a code span, the escaped derived label and the `kind`, plus the exit marker when `terminal` is set; then the fenced verbatim block; then the link line.
- **Column 0, not a markdown ordered list.** A real `<ol>` would need its fences indented to the marker width, CommonMark strips that indentation *by column*, and a fragment line beginning with a tab would render de-tabbed -- a silent alteration of the one thing this feature exists to guarantee. The indent would also vary with the item number. "Ordered list" is honoured as a numbered sequence of entries in chart order.
- **Layer 1, markdown -- solved by a tilde fence with zero escaping.** The fragment is emitted inside a fence of `N` tildes where `N = max(4, 1 + longest run of '~' at the start of any fragment line)`. Inside a fenced block no character is markdown, so **not one byte of the fragment is escaped, substituted or re-indented**. Tildes rather than backticks because a backtick fence must out-run the fragment's own backticks (already 4 in this corpus) and because a tilde fence may carry an info string containing backticks.
- **Layer 2, Expressive Code's file-name extraction -- solved by always setting `title=`.** Its frames plugin scans the first four lines of every block for a file-name comment and **deletes that line** on a match; that regex fires on lines starting with `#`, which is exactly what an inline-`## State:` fragment starts with. Extraction is skipped when `title` is defined, so **every emitted fence carries `title="<file><anchor>"`**, which doubles as the visible provenance caption. Rejected: `frame="none"`, which also suppresses extraction but throws the caption away.
- The fence declares `plaintext` -- one of Shiki's hard-coded plain languages, so no grammar loads and the unknown-language warning never fires -- with the bare `wrap` flag. Rejected: `markdown` highlighting, which would let a syntax grammar visually reinterpret the very text whose literalness is the point.
- The **label** is escaped (`&`, `<`, then a backslash before each of backtick, `*`, `_`, `[`, `]`, `\` and the pipe), which is legitimate precisely because the label is an interpretation, not evidence. `kind` and `advanceType` are closed enums needing none.
- Deliberately **not** rendered: outgoing edges, their `condition` prose, and `terminal.handoff`. All three are free text that would need inline escaping in a list whose whole point is exactness, and the chart already carries them. `detail` is **link only, never inlined** -- its range can be a whole worker file, which is the page-weight control.

**Acceptance Criteria:**
- [ ] `buildEntries` returns exactly one entry per node, in `chart.nodes` array order, with no re-sort and no de-duplication -- asserted against a chart where two nodes cite the same range.
- [ ] Fence width is `max(4, 1 + longest run of '~' at the start of any fragment line)`; a fragment containing a `~~~~` line at column 0 forces a 5-tilde fence.
- [ ] **Every** emitted fence carries a `title="<file><anchor>"` meta option and the bare `wrap` flag, with language `plaintext`.
- [ ] The fragment round-trips **byte-for-byte**: backticks (including a 4-run), pipes, `<div>`, `{braces}` and a complete fenced code block all survive unaltered -- extract the emitted fence body and assert it equals the input fragment exactly.
- [ ] Every entry's three blocks start at **column 0**; the output contains no markdown ordered-list markers wrapping a fence.
- [ ] The anchor is `<a id="fragment-<nodeId>"></a>` **on the same line as the lead-in text**, not standing alone on its own line.
- [ ] The `## Source fragments` heading is an H2, the intro sentence contains **no count**, and no count literal appears anywhere in the module.
- [ ] The exit marker renders only when `terminal` is set, reading `terminal.advanceType`; `terminal.handoff`, outgoing edges and edge conditions are **not** rendered.
- [ ] `[full step: ...]` appears if and only if `detail !== null`, as a link only, never inlined.
- [ ] The label escaper applies its full character set; `kind` and `advanceType` pass through unescaped.
- [ ] `renderFragmentList` called twice on the same chart returns identical strings; output is LF-terminated with no `os.EOL`.
- [ ] Unit tests exist for every public function and every containment case above; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
