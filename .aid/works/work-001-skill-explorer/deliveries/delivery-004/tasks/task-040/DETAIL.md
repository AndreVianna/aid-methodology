# task-040: `canonical/` deep-link builder

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-040. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-040/STATE.md.
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
- Create `site/scripts/lib/provenance/deep-link.mjs` with `lineAnchor(startLine, endLine)`, `blobUrl(file, startLine, endLine)` and the path-charset guard.
- `lineAnchor` returns `#L<start>` when the range is a single line and `#L<start>-L<end>` otherwise. `blobUrl` composes `GITHUB_BLOB_BASE + '/' + file + anchor` by **string concatenation**, the same shape `gen-reference.mjs` already uses for its `[Definition: ...]` links -- the `#L...` suffix is the only addition, so this establishes the form rather than competing with one. There are no other `blob/...#L` links anywhere in `site/`, `docs/` or `canonical/` today.
- `GITHUB_BLOB_BASE` is **imported read-only** from `site/scripts/skills/paths.mjs` (task-005), never redeclared here -- one base, one place.
- The ref is pinned to **`master`**, and the reasoning is recorded rather than assumed: the site is built and deployed only from `master`; `npm run build` runs `prebuild` -> `gen:skills`, so deployed pages are regenerated from the checkout being deployed; anchors are a pure function of the same input as the page; and a range that no longer matches its file throws (task-041), so a wrong link cannot be published by a green build. Rejected: a commit SHA (a permalink, but an environment input -- it would change the bytes of every committed page on every commit and break AC-6); a release tag (the site never builds from one); a local filesystem path (unusable from a published page).
- **Path safety.** `blobUrl` **throws** if `file` contains any character outside `[A-Za-z0-9._/-]`, contains a `..` segment, or has a leading `/`. No percent-encoding is needed for today's corpus; the guard makes the day that changes a loud build failure rather than a silently broken URL. Rejected: `encodeURI`, which would paper over a path this generator should never produce.
- Conventions: ESM `.mjs`, `node:`-scheme builtins only, 2-space indentation, kebab-case filename, pure exported functions with no import-time side effect, no new dependency. Every emitted path is a POSIX string built by concatenation, never `path.join`. Output is LF-only.

**Acceptance Criteria:**
- [ ] `lineAnchor` returns `#L<n>` when `startLine === endLine` and `#L<a>-L<b>` otherwise, asserted for both forms.
- [ ] `blobUrl` output equals `GITHUB_BLOB_BASE + '/' + file + anchor` exactly, for both anchor forms.
- [ ] `GITHUB_BLOB_BASE` is imported from `site/scripts/skills/paths.mjs` and **not redeclared** in this module, verified by grep for the literal URL.
- [ ] `blobUrl` **throws** on a character outside `[A-Za-z0-9._/-]`, on a `..` segment, and on a leading `/` -- three separate cases, each asserted.
- [ ] `encodeURI` and `encodeURIComponent` appear nowhere in the module.
- [ ] `path.join` appears nowhere; every returned string is built by concatenation.
- [ ] The module has no import-time side effect and reads no file, no clock and no environment.
- [ ] Unit tests exist for both anchor forms and all three guard rejections; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
