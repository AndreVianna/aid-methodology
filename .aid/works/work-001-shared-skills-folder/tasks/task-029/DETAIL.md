# task-029: State the shared layout in the Knowledge Base

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

**Type:** DOCUMENT

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-19

**Depends on:** task-026, task-027

**Scope:**
- Resolve each target doc's review criteria before editing (global `G-*`, the `kb-doc` row
  `KB-01` to `KB-18`, and any file-level `review-criteria:`), per
  `.aid/knowledge/authoring-conventions.md` § Review Criteria.
- Every `.aid/knowledge/` doc that states the old layout is updated to the current one. Find them
  with the AC-19 grep (`git grep -nE '\.(claude|codex|cursor|agent)/aid/|\.github/aid/' -- .aid/knowledge ':!.aid/knowledge/release-tracking.md' ':!.aid/knowledge/kb.html'`)
  and by reading for prose statements of per-tool skill trees or rendered runtimes. At minimum:
  - `architecture.md`: § Build & Distribute Architecture (render output is agents and
    `aid-tool.conf`, the generator wipes and regenerates each profile tree, and the profile
    emission manifests are gone; release = one shared payload plus per-tool agents artifacts, with
    no wrapper directory), § Data Flow / Install flow (CLI places `.agents/skills/aid-*`,
    the `.claude/skills` mirror, `.aid/runtime/`, the `AGENTS.md` region and the Claude Code
    `CLAUDE.md` `@AGENTS.md` import region; reference counting; drift; one version per repo),
    § Invariants (content isolation now reads: skills use the `aid-` prefix under `.agents/skills/`
    and each mirror, the runtime lives under `.aid/runtime/`, and the root files are updated only
    between their markers -- the `AGENTS.md` pointer region (the rules live in
    `.aid/runtime/rules.md`) for every tool and, while Claude Code is
    installed, the `CLAUDE.md` region, which holds only `@AGENTS.md`), § Gotchas (the INDEX-path gotcha is dissolved; the dogfood resync is a CLI install),
    § Doc-vs-Code Discrepancies (the `EMISSION-MANIFEST.md` gap is removed with the file);
  - `authoring-conventions.md`: `G-10` and `G-11` state the `.aid/runtime/` and `.agents/skills/aid-*`
    placement rules; `G-13` no longer names a `.codex/aid/` namespace; § Content Isolation matches;
  - `artifact-schemas.md`: settings `format_version` current value `5`; the install manifest is
    format 3 with shared entries;
  - `project-structure.md`, `module-map.md`, `integration-map.md`, `infrastructure.md`,
    `test-landscape.md` (new suites, `tests/lib/bundle.sh`),
    `technology-stack.md`, `coding-standards.md`, `quality-gates.md`, `decisions.md`, `tech-debt.md`
    and `.aid/knowledge/STATE.md` wherever the grep or a read finds the old layout.
- `.aid/knowledge/release-tracking.md`: shipped history stays as history; add the entry for this
  change through the normal release-tracking flow (and `backlog.md` if that flow requires it).
- Regenerate `.aid/knowledge/INDEX.md` with
  `bash .aid/runtime/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md`
  (or the `canonical/aid/` copy; both now embed the same path).
- KB rule (project `CLAUDE.md` / `AGENTS.md`, "Never name a work in the Knowledge Base"): no edited
  or added KB text may contain a work id (`work-NNN`), a work-folder path (`.aid/works/...`), or
  phrasing such as "added in"/"specified by" a work; cite the durable artifacts instead (scripts,
  tests, `canonical/` files). No `## Change Log` / `## Revision History` section and no `changelog:`
  field is added.

**Acceptance Criteria:**
- [ ] `git grep -nE '\.(claude|codex|cursor|agent)/aid/|\.github/aid/' -- .aid/knowledge ':!.aid/knowledge/release-tracking.md' ':!.aid/knowledge/kb.html'` prints no lines.
- [ ] A reviewer confirms that `architecture.md` § Invariants (content isolation) and `G-10` and `G-11` in `authoring-conventions.md` state the `.aid/runtime/` and `.agents/skills/aid-*` placement rules, and that the content-isolation checks in `canonical/agents/aid-reviewer/AGENT.md` (edited in task-003) accept that placement.
- [ ] `bash tests/canonical/test-kb-no-work-ids.sh` exits `0`, and `git diff -U0 -- .aid/knowledge | grep -E '^\+.*(work-[0-9]{3}|\.aid/works/)'` prints nothing.
- [ ] `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and `bash canonical/aid/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit `0`; the CI "INDEX.md is fresh" regenerate-and-diff (timestamp lines filtered) prints nothing.
- [ ] `bash tests/canonical/test-doc-counts.sh` exits `0` (any KB count it checks still matches disk).
- [ ] All section-6 quality gates pass.
