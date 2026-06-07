# task-014: Docs migration generator — `sync-docs.mjs` + committed generated pages

**Type:** IMPLEMENT

**Source:** feature-005-content-migration → delivery-003

**Depends on:** task-009

**Scope:**
- Author `site/scripts/sync-docs.mjs` (Node stdlib ESM, manifest-driven, deterministic/idempotent): for each manifest entry read the source `docs/*.md`, strip its leading H1, prepend injected frontmatter (`title`/`description`/`sourceDoc`), apply link/anchor/image rewrites, write to the dest under `site/src/content/docs/`, copy referenced images to `site/src/assets/` (D1).
- Manifest = the four sources only: `aid-methodology.md` → `concepts/methodology.md`; `faq.md` → `concepts/faq.md`; `repository-structure.md` → `reference/repository-structure.md`; `glossary.md` → `reference/glossary.md`. EXCLUDE `docs/install.md` and `docs/release.md` (sources owned by 004/006/007).
- Fence-aware H1 detection (D5); copy `mermaid` fences verbatim (D-mermaid); relocate `docs/images/3-ironman.png` → `src/assets/` with relative-path rewrite (D6); apply the link rewrite rules (cross-doc → route+anchor, same-doc anchor unchanged, out-of-scope → GitHub blob URL, external unchanged).
- Emit `site/scripts/.synced-manifest.json` (outside the collection root).
- Add `sync:docs` + `predev`/`prebuild` scripts to `package.json`; commit the generated page tree, the copied image, and the manifest.

**Acceptance Criteria:**
- [ ] `sync-docs.mjs` produces byte-identical output on re-run (deterministic/idempotent) and is driven by an explicit manifest.
- [ ] The four pages are generated with required frontmatter (incl. `title` + `sourceDoc`); `install.md`/`release.md` are NOT in the manifest and nothing is written under `guides/`.
- [ ] `#`-lines inside code fences are treated as literal text; the 7 methodology `mermaid` fences are copied verbatim.
- [ ] The image is relocated to `src/assets/` and referenced relatively; link/anchor/external rewrites follow the rule table.
- [ ] `.synced-manifest.json` is emitted outside the collection root; generated tree, image, manifest, and the `package.json` scripts are committed.
- [ ] Unit tests cover the transform (H1 strip, fence-awareness, each link-rewrite class); build passes; existing tests still pass.
- [ ] All §6 quality gates pass.
