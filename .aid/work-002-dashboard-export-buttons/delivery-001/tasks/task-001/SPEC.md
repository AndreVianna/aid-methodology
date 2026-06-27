# task-001: Generation-time Markdown export payload

**Type:** IMPLEMENT

**Source:** work-002-dashboard-export-buttons → delivery-001

**Depends on:** — (none)

**Scope:**
- Build the optimized single-file Markdown export at `/aid-summarize` GENERATE time from the
  source `.aid/knowledge/*.md` documents (NOT scraped from the DOM), and embed it in `kb.html`
  as a hidden text payload (e.g. a `<script type="text/markdown" id="…">` block).
- Convert inline SVG images to `data:` URIs and embed every image inline in the Markdown so the
  export is a single portable `.md` (no separate image files, no zip); viewers without data-URI
  support degrade to alt text.
- Touches: a new build step under `canonical/aid/scripts/summarize/` (e.g. `build-md-export`),
  its wiring into `canonical/aid/scripts/summarize/assemble.sh` (concatenate the payload into the
  skeleton), and the GENERATE prose in `canonical/skills/aid-summarize/references/state-generate.md`
  (new step authoring the payload + defining the hidden-element id/shape contract that task-002
  reads). While editing `state-generate.md`, reconcile its existing **stale** assemble-path
  reference (`canonical/scripts/summarize/assemble.sh` at ~lines 256/263) to the correct
  `canonical/aid/scripts/summarize/assemble.sh`.
- **Self-containment validator interaction (must own):** the hidden Markdown payload is a
  `<script type="text/markdown">` block that will exceed 100 KB and, because KB source docs mention
  "mermaid" (6 files / 13 hits), its body matches the anti-Mermaid heuristic NM.1 in
  `canonical/aid/scripts/summarize/validate-html-output.sh` (awk ~lines 290-303 fails ANY
  `<script>` >100 000 bytes whose body matches `/mermaid/`, regardless of `type`). Refine NM.1 so
  it targets the actual Mermaid *engine* signature (or explicitly excludes the
  `type="text/markdown"` payload element) so the legitimate payload does not false-trip the gate.
- Preserve self-containment: no external fetch, no large embedded engine.

**Acceptance Criteria:**
- [ ] A fresh `kb.html` generated via the updated GENERATE path embeds a hidden Markdown payload built from `.aid/knowledge/*.md` (not DOM-scraped). (work SPEC AC3, AC7)
- [ ] Each image in the payload is embedded inline as a `data:` URI (inline SVG → data URI); the payload is a single self-contained Markdown document, and every image carries an `alt`/title so a viewer that ignores `data:` URIs degrades to alt text. (work SPEC AC4)
- [ ] The hidden-payload element id/shape is documented in `state-generate.md` as the contract task-002 consumes, and the stale `assemble.sh` path reference in that doc is corrected. (enables AC1; resolves doc drift)
- [ ] `validate-html-output.sh` NM.1 is refined so the >100 KB `type="text/markdown"` payload (which legitimately contains the "mermaid" token from KB text) does NOT false-trip the anti-Mermaid-engine check, while still catching a real re-embedded Mermaid engine. (work SPEC AC6)
- [ ] `assemble.sh` still produces a single self-contained `kb.html` with no new external fetch, and the canonical summarize validators + `tests/run-all.sh` pass on it. (work SPEC AC6, AC8)
- [ ] All applicable project quality gates pass (`tests/run-all.sh`, the `/aid-summarize` validators including the §7 visual-fidelity gate).
