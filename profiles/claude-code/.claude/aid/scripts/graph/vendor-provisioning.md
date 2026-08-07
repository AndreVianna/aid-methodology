# Graph-view vendored bundles — provisioning, pinning and the update procedure

> **Audience:** whoever merges a Dependabot PR against `package.json` in this directory, and
> whoever next touches `.claude/aid/templates/knowledge-graph/vendor/`.
> **Task:** task-023 (feature-012 D6 — the third-party dependency gate), implementing the
> packaging shape task-002/task-011 already decided; this document is not a fresh decision.
> **Stability:** the five files under `../../templates/knowledge-graph/vendor/` and the pins in
> `package.json` change together, only through the procedure below — never independently.

---

## What is vendored, and why it is five files for two libraries

The graph view (feature-008) consumes `d3-force` (physics) and PixiJS/WebGL (drawing) as
**global** objects, reached via classic `<script src>` tags — a `file://` page cannot import a
relative ES module. Inspecting `d3-force`'s own UMD build surfaces a dependency chain the
requirement text does not mention: its factory function will not run until `d3-quadtree`,
`d3-dispatch` and `d3-timer` have already merged onto the same `d3` global. PixiJS carries no
equivalent chain (its browser bundle is self-contained; `require(` count is zero).

| File | Package @ exact version | Licence |
|---|---|---|
| `vendor/d3-quadtree/d3-quadtree.min.js` | `d3-quadtree@3.0.1` | ISC |
| `vendor/d3-dispatch/d3-dispatch.min.js` | `d3-dispatch@3.0.1` | ISC |
| `vendor/d3-timer/d3-timer.min.js` | `d3-timer@3.0.1` | ISC |
| `vendor/d3-force/d3-force.min.js` | `d3-force@3.0.0` | ISC |
| `vendor/pixi.js/pixi.min.js` | `pixi.js@8.19.0` | MIT |

Each subdirectory carries its own `LICENSE`, copied verbatim from the upstream package at the
pinned version — a companion file, never a comment edited into the vendored `.js` bytes (editing
the bytes would defeat the integrity check below). Loading order matters: the first three
`<script src>` tags must precede `d3-force`'s; `pixi.min.js` has no ordering dependency on any of
them. This is wired by `render-graph-view.sh` / `build-graph-src.mjs` in this same directory —
not by hand-editing `graph-skeleton.html`, which carries no vendor-specific markup at all, so a
project with none of these five files vendored still renders a valid (degraded, `mode:
'unavailable'`) page.

**Full source citation:** `.aid/works/work-005-knowledge-graph/deliveries/delivery-001/research/`
`rendering-stage3-payload-licence-update.md` and `rendering-decision-record.md` (transient work
folder — cited here for provenance only; nothing permanent depends on either).

---

## What `package.json` / `package-lock.json` here are for, and are not for

`package.json` in this directory is `"private": true`, pins all five packages at their exact
vendored versions, and is **not published, not installed, and not built from**. Its only job is
to give Dependabot (`.github/dependabot.yml`, `npm` ecosystem, `directory:
"/.claude/aid/scripts/graph"`) something to diff against the npm registry, so a version bump
upstream produces a PR instead of going unnoticed — the verified baseline before this manifest
existed was that nothing in this repository watched a JavaScript dependency at all.

`package-lock.json` fully resolves the five direct pins plus PixiJS's own transitive dependency
tree (eleven further packages, all leaf utilities except `gifuct-js`, which pulls in
`js-binary-schema-parser`), each entry's `resolved` and `integrity` read from
`registry.npmjs.org` — the same shape as the Playwright manifest precedent
(`.claude/aid/scripts/summarize/package.json` + its lock file), and the same reason: a
reproducible resolution record, not an install anyone runs routinely. **No `node_modules/`
directory ever ships** — `render.py`'s emission walk already excludes any `node_modules` path
component at any depth (the general P2 guarantee every canonical root gets), so this needs no
project-specific control here.

---

## The update procedure — the ongoing obligation this manifest creates

**Merging a Dependabot PR against this manifest bumps a version string. It does not, by itself,
update a single vendored byte.** That gap is the obligation this document names, so it is not
left to be rediscovered the first time it matters:

1. **Re-download** the new version's dist file(s) from `https://unpkg.com/<package>@<version>/`
   `dist/<package>.min.js` (or the equivalent path for the bundle actually consumed), for every
   package whose pin moved — remember the dependency chain: a `d3-force` bump can require
   re-checking `d3-quadtree`/`d3-dispatch`/`d3-timer` too, if their own ranges moved.
2. **Re-run the integrity grep** against the new bytes, before replacing anything:
   ```bash
   for f in <the changed files>; do
     grep -c "canonical/" "$f"; grep -c "CLAUDE.md" "$f"
     grep -c "STATE.md" "$f"; grep -c "additional-info.md" "$f"
     grep -ci "mermaid" "$f"
   done
   # every count, every file, every trigger, must be 0 before proceeding
   ```
   This is feature-012's own **G6** condition — it is a step in *this* procedure, not a one-time
   observation, because the render-drift CI job diffs a fresh render against a committed render
   and cannot see a bundle that is consistently mangled the same way on every render. The last
   verified run (2026-08-06, at the versions pinned above) was clean: zero hits on every trigger,
   for all five files.
3. **Re-verify the licence.** Download the new version's own `LICENSE` file
   (`https://unpkg.com/<package>@<version>/LICENSE`) and diff it against the committed companion
   copy — a licence can change between major versions even when a project's overall reputation
   does not. Replace the companion `LICENSE` file only if the text actually changed, and note the
   change if it did.
4. **Re-measure the payload** (`wc -c` on the new files) if the combined-bytes figure is recorded
   anywhere downstream (feature-013's `technology-stack.md`).
5. **Only then** replace the vendored `.min.js` bytes, update the version comment if one exists,
   update the pin in `package.json`, and regenerate `package-lock.json`'s affected entries against
   the same registry data this document's own entries were built from.
6. **Run the full generator** (`run_generator.py`) so every profile picks up the new bytes, and
   confirm render parity — the standard obligation any canonical edit under
   `.claude/aid/templates/knowledge-graph/` already carries.

Skipping step 2 or 3 and merging the version bump anyway is the single most likely way this
mechanism's benefit is lost in practice: the manifest would then claim a version the vendored
bytes do not match, which is a corruption of exactly the kind step 2 exists to catch, just
introduced by the update process instead of by the render pipeline.

**Trigger, named plainly:** a Dependabot PR against this manifest (weekly schedule, per
`.github/dependabot.yml`) is the trigger for steps 1–6; there is no other scheduled trigger, and
none is recommended — a bespoke scheduled CI job that re-checks upstream on its own was compared
and rejected as the *primary* mechanism (new code this project alone would maintain, for a
capability Dependabot already gives for free), though nothing here forbids adding one later as a
narrower, secondary check specifically for byte-level drift.
