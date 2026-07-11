# Playwright headless-browser provisioning — summarize visual-fidelity gate

> **Audience:** task-074 (validate-visuals.mjs author) + CI maintainers + local developers.
> **Task:** task-073 (CONFIGURE — provision Playwright + CI support).
> **Stability:** pinned; update the version in `package.json` + regenerate `package-lock.json`
> when a new Playwright version is needed.

---

## What is provisioned

`canonical/aid/scripts/summarize/package.json` (this directory) declares **Playwright 1.61.1**
as a `devDependency`. A matching `package-lock.json` locks every transitive dependency for
reproducible installs. Neither file is shipped to adopters — this is dev/validator tooling
isolated to the summarize scripts directory.

The provisioning enables task-074 to write `validate-visuals.mjs` using:

```javascript
import { chromium } from 'playwright';
```

---

## How to install locally (development)

From the repo root (one-time setup):

```bash
cd canonical/aid/scripts/summarize
npm ci                                # install playwright (uses lock file)
npx playwright install chromium       # download the pinned Chromium binary
```

After this, `validate-visuals.mjs` can launch a headless browser without any network access
(it renders a local self-contained file).

**Why `npm ci` instead of `npm install`:** `npm ci` uses the lock file exactly, ensuring every
developer and CI run uses identical binaries. Never run `npm install` unless intentionally
upgrading (which also requires regenerating the lock file).

---

## How CI runs it (`.github/workflows/test.yml` — `visual-fidelity` job)

The `visual-fidelity` job is **isolated** from the `canonical-tests` job so it does not slow
unrelated suites. It runs on every PR/push to `master` alongside the other CI jobs.

Steps:
1. `npm ci` in `canonical/aid/scripts/summarize/` — reproducible install from lock file.
2. `npx playwright install chromium --with-deps` — downloads the pinned Chromium binary +
   its OS-level system dependencies (fonts, libs) required for headless rendering on Ubuntu.
3. `node canonical/aid/scripts/summarize/validate-visuals.mjs .aid/knowledge/kb.html` —
   runs the visual-fidelity gate against the generated summary.

**Headless, no display server:** Playwright runs Chromium in headless mode by default. No X
server, Xvfb, or display environment variable is needed. The `--with-deps` flag ensures the
required system libraries are present on the runner.

**No external fetch during render:** `kb.html` is a single self-contained file (guardrails C2/C3)
— all CSS, JS, and visuals are inlined. The validator must launch Chromium with `--offline` or
by blocking network access so it never depends on a CDN fetch to produce its render. This makes
the gate hermetic and reproducible across environments.

---

## Graceful degradation

The `visual-fidelity` CI job applies the same pattern as other environment-dependent tests in
this repo — it exits `0` with a clear SKIP message rather than hard-failing when:

| Condition | Behavior |
|---|---|
| `kb.html` is absent (not yet generated in this branch) | `SKIP` — gate requires a generated summary |
| `validate-visuals.mjs` is absent (task-074 not yet landed) | `SKIP` — provisioning ready, validator not yet written |

A **visual defect detected by the validator** (text clipped, elements overlapping, layout
collapsed/empty) is NOT graceful degradation — it is a generation defect that **blocks DONE**,
the same rigor as the old "no broken diagram" guarantee.

When Playwright is not installed locally, `validate-visuals.mjs` should also degrade gracefully
(check for Playwright with a `try/catch` import or `--check-only` flag, and print a clear skip
message rather than crashing), so local dev without the browser binary installed does not break
the dev loop. The explicit visual-inspection fallback documented in task-074 covers this case
for human-driven validation.

---

## How task-074 invokes Playwright

`validate-visuals.mjs` should follow this pattern:

```javascript
import { chromium } from 'playwright';

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();

// Render the local self-contained file — no network needed
await page.goto(`file://${path.resolve(htmlPath)}`);

// For each .diagram-box element, assert:
//   - bounding box is non-trivial (not collapsed/empty)
//   - text elements are legible (font-size >= threshold, not clipped)
//   - no significant overlap between sibling elements
const diagrams = await page.locator('.diagram-box').all();
// ... assertions per diagram ...

await browser.close();
```

The `chromium` import resolves from `node_modules/playwright` via the `package.json` in this
directory. Run the script with `node validate-visuals.mjs <html-file>` — the same invocation
pattern as the existing `.mjs` validators in this directory.

---

## Dependency isolation

The `package.json` + `package-lock.json` in `canonical/aid/scripts/summarize/` ship as part of
the install tree (the generator copies `canonical/aid/` verbatim into each profile's `aid/`
subtree). They serve as the **on-demand install manifest**: adopters who want to run the visual-
fidelity gate locally run `npm ci` in their installed `aid/scripts/summarize/` directory to get
Playwright.

`node_modules/` is **install-time-only** and is never shipped:
- It is listed in `.gitignore` (never committed).
- The generator (`run_generator.py`) explicitly excludes any `node_modules/` directory at any
  depth from the emission walk, so it never appears in any profile output tree or emission
  manifest.
- CI runs `npm ci` in `canonical/aid/scripts/summarize/` before the visual-fidelity gate; the
  resulting `node_modules/` is ephemeral and stays in the working tree only for that job.

Other isolation boundaries:
- The dashboard reader (`server.mjs` / `server.py`) has a zero-third-party-dep rule — Playwright
  does not touch it.
- The npm/pypi release packages do not bundle `node_modules/`.
