# Stage 1 — the WebGL-under-headless probe

> **Scope: Stage 1 only.** This document is the deliverable of feature-002 Feature Flow **Step 3**
> (and Step 4, which did not fire). It is FR-18 item 1 and nothing else. **No frame time was
> measured, no library was chosen, and `canonical/aid/templates/graph/scale-ceiling.yml` was not
> touched** — it ships with one key and deliberately no value, and that value arrives with Stage 2's
> measurement. Stage 2a, Stage 2b and Stage 3 are **not** in this document and their absence is
> deliberate, not an omission; § D10 coverage below enumerates which required parts are discharged
> here and which are still owed by which stage.

**Work:** work-005-knowledge-graph · **Feature:** feature-002 · **Date run:** 2026-08-05
**Repository state:** HEAD `62210dae`, working tree clean at the time of the run
**Specification:** `.aid/works/work-005-knowledge-graph/features/feature-002-graph-rendering-research/SPEC.md`
§ D1, § D1a, § D1b, § D10 (revision gated A+ 2026-07-30)

---

## 1. Question and scope — D10 part 1

**The question, from FR-18 as rewritten:** *can the Playwright toolchain FR-12 reuses validate a WebGL
canvas at all, with no GPU?*

**The renderer is not in question.** Q9 decided it: `d3-force` on the CPU for physics, PixiJS over
WebGL for drawing, the canvas visual-only, WCAG AA carried by the accessible table view as the
conforming alternate version. This probe validates that decision's *machine-checkability* and, had the
evidence demanded it, would have reported a failure to the owner. It does not re-open the comparison
and it does not evaluate 3D.

**Why one FR-18 item is three facts.** C-5 as extended says a WebGL renderer may leave Playwright
"provisioned *and still unable to draw*". That sentence conflates three independently-checkable
conditions whose fallbacks differ, so collapsing them would produce a single pass/fail whose failure
mode is unknown — the least useful possible outcome for the work's highest-risk item. The three levels
are kept separate throughout, and each carries its own verdict in each environment.

**Explicitly out of scope here**, per § The validation boundary: choosing a renderer; building a
degraded rendering mode; pricing an accessibility proxy layer (there is none — the canvas is
visual-only); authoring the palette; writing product code; writing to the Knowledge Base; deriving the
bench by counting files; and **stating a bench size**. No node count, edge count or degree figure
appears anywhere in this document.

---

## 2. Stage 1 — the probe: three verdicts per environment — D10 part 2 (AC-S1)

### 2.1 The verdict table

Three environments, three levels, reported separately — **a verdict from one environment is not a
verdict for all.**

| Environment | L1 context | L2 readable pixels | L3 capturable pixels | Basis |
|---|---|---|---|---|
| **ENV-1 — the CI `visual-fidelity` runner** (`ubuntu-24.04`) | **NOT VERIFIED** | **NOT VERIFIED** | **NOT VERIFIED** | Not reachable from this host. See § 2.6 — and see § 5, which found that this gate does not currently execute in CI at all |
| **ENV-2 — developer machine WITH Playwright provisioned** (Windows 11, `win32 10.0.26200 x64`) | **PASS** | **PASS** | **PASS** (with one loud qualification — § 2.5) | Probe run, output quoted in full in § 2.4 |
| **ENV-3 — a machine with Playwright NOT provisioned** | **NOT DETERMINABLE** (correctly — and this is not a WebGL failure) | **NOT DETERMINABLE** | **NOT DETERMINABLE** | Both the reused script and the probe degrade to `SKIP` and `exit 0`; output in § 2.3 |

`NOT DETERMINABLE` and `NOT VERIFIED` are distinct from `FAIL` and neither is a pass. ENV-3's row is
the *intended* behaviour of C-5's degradation, confirmed present and undisturbed by the graph work.
ENV-1's row is an honest gap, not a result.

### 2.2 The renderer identity, verbatim — and it is not optional

Recorded alongside every verdict, because a pass on a software rasteriser and a pass on a discrete GPU
are different facts with different consequences for Stage 2.

**ENV-2, all three canvas configurations, both `webgl2` and `webgl`, identical strings:**

```
UNMASKED_VENDOR_WEBGL    : "Google Inc. (Google)"
UNMASKED_RENDERER_WEBGL  : "ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device (Subzero) (0x0000C0DE)), SwiftShader driver)"
```

Masked strings, for completeness:

```
gl.getParameter(gl.VENDOR)                   : "WebKit"
gl.getParameter(gl.RENDERER)                 : "WebKit WebGL"
gl.getParameter(gl.VERSION)                  : "WebGL 2.0 (OpenGL ES 3.0 Chromium)"
gl.getParameter(gl.SHADING_LANGUAGE_VERSION) : "WebGL GLSL ES 3.00 (OpenGL ES GLSL ES 3.0 Chromium)"
```

**The single most consequential fact in this document: every ENV-2 pass was produced by a CPU software
rasteriser, not by a GPU.** `SwiftShader` is Google's software Vulkan implementation; ANGLE is running
on top of it. The host has a discrete GPU and the reused launch configuration does not reach it (§ 4).

**ENV-1 and ENV-3 renderer identity: NOT READ.** For ENV-3 there is no browser to read it from; for
ENV-1 the environment was not reachable. Neither absence is a `NOT EXPOSED` finding — see the next
paragraph for what a real `NOT EXPOSED` would have looked like.

**`WEBGL_debug_renderer_info` was EXPOSED, and reading it exposed a naming defect in D1 itself.** The
extension is present (`getSupportedExtensions()` lists it; `getExtension()` returns an object). But the
constant names § D1 instructs the probe to read — `UNMASKED_RENDERER_STRING` and
`UNMASKED_VENDOR_STRING` — **are not the names the extension defines.** Measured:

```
extension own keys                : []
extension prototype keys          : ["UNMASKED_VENDOR_WEBGL","UNMASKED_RENDERER_WEBGL"]
typeof dbg.UNMASKED_VENDOR_STRING   : undefined
typeof dbg.UNMASKED_RENDERER_STRING : undefined
getParameter(dbg.UNMASKED_VENDOR_STRING)   : null  [gl error 1280]
getParameter(dbg.UNMASKED_RENDERER_STRING) : null  [gl error 1280]
getParameter(dbg.UNMASKED_VENDOR_WEBGL)    : "Google Inc. (Google)"  [gl error 0]
getParameter(dbg.UNMASKED_RENDERER_WEBGL)  : "ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device (Subzero) (0x0000C0DE)), SwiftShader driver)"  [gl error 0]
getParameter(0x9245)                       : "Google Inc. (Google)"  [gl error 0]
getParameter(0x9246)                       : "ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device (Subzero) (0x0000C0DE)), SwiftShader driver)"  [gl error 0]
```

`1280` is `GL_INVALID_ENUM`, from `getParameter(undefined)`. **The first run of this probe took D1's
names literally, recorded the identity as `null`, and would have reported "the extension is exposed but
the strings read back null" — a false finding that also silently poisoned the `getError()` reading in
the L2 block.** One cause, two wrong numbers. It was caught by reading the extension object rather than
trusting the read, and it is recorded here as a routed correction (§ 6, item **S1-1**) rather than
quietly fixed, because D1's sentence "where the extension is not exposed, that absence is itself
recorded as the value" is exactly the clause that would have absorbed the false negative and made it
look like a finding.

### 2.3 ENV-3 — Playwright not provisioned. Both invocations, literal output

Run **before** anything was installed, which is the only order in which this measures what it claims to.

Resolution precondition, from the directory the reused script lives in:

```
$ cd canonical/aid/scripts/summarize && node -e "import('playwright').then(()=>console.log('RESOLVED')).catch(e=>console.log('NOT RESOLVED:', e.code))"
NOT RESOLVED: ERR_MODULE_NOT_FOUND
```

**The reused script** (`validate-visuals.mjs`), the pre-existing C-5 case, with the graph work present
in the tree:

```
$ node canonical/aid/scripts/summarize/validate-visuals.mjs .aid/knowledge/kb.html
SKIP -- Playwright is not installed in this environment.

To install (one-time setup):
  cd canonical/aid/scripts/summarize
  npm ci
  npx playwright install chromium

Visual-inspection fallback:
  Without Playwright, every authored visual must be reviewed via the
  MANUAL-CHECKLIST V1 human visual gate. Reading HTML/CSS source is
  NOT sufficient -- the V1 check requires loading kb.html in a browser
  and visually confirming that every visual is readable and correctly
  laid out. Document the fallback in STATE.md before marking DONE.

CI: the visual-fidelity job in test.yml runs npm ci + playwright install
automatically -- no manual setup needed for CI runs.
EXIT_CODE=0
```

**CONFIRMED — the degradation path is intact and the graph work did not disturb it.** The dynamic
`import('playwright')` inside `try/catch` at `validate-visuals.mjs:119-146` prints the guidance and
`process.exit(0)` at line 144.

**The probe's own degradation**, same shape by construction:

```
$ PROBE_ENV_LABEL="ENV-3: this machine, Playwright NOT provisioned" node .aid/.temp/graph-stage1-probe/probe.mjs
==============================================================================
Stage 1 -- WebGL-under-headless probe
environment label : ENV-3: this machine, Playwright NOT provisioned
host              : win32 10.0.26200 x64
node              : v22.14.0
==============================================================================
SKIP -- Playwright is not installed in this environment.
  import('playwright') failed with: ERR_MODULE_NOT_FOUND
  L1 / L2 / L3 verdicts: NOT DETERMINABLE in this environment.
  This is the C-5 pre-existing case, not a WebGL failure.
EXIT_CODE=0
```

Re-verified after all installs were removed — see § 7.

### 2.4 ENV-2 — the probe, and exactly what it asserts

**The launch configuration was copied, not invented, and was re-verified as live before use.** Read
`canonical/aid/scripts/summarize/validate-visuals.mjs` on **2026-08-05** at HEAD `62210dae`
(master has merged twice since D1's 2026-07-29 read):

- **lines 185-188** — `chromium.launch({ headless: true, args: ['--no-sandbox', '--disable-setuid-sandbox'] })`. **Unchanged.** No GPU-related flag either way.
- **lines 195-202** — `page.route('**/*', …)` continuing only URLs beginning `file://` and aborting everything else. **Unchanged.** Mirrored in the probe.
- **line 204** — `page.goto(…, { waitUntil: 'domcontentloaded' })`. **Unchanged.**
- **lines 119-146** — the degradation block. **Unchanged.**
- `canonical/aid/scripts/summarize/package.json` — `playwright: 1.61.1` as a `devDependency`, `engines.node >= 20`. **Unchanged.** The probe ran against exactly `1.61.1`.

**Invocation:**

```
$ PROBE_ENV_LABEL="ENV-2: developer machine WITH Playwright provisioned (Windows 11, win32 10.0.26200 x64)" \
  PROBE_JSON_OUT=".aid/.temp/graph-stage1-probe/result-env2.json" \
  node .aid/.temp/graph-stage1-probe/probe.mjs
```

**Runtime header, literal:**

```
host              : win32 10.0.26200 x64
node              : v22.14.0
playwright        : 1.61.1
launch            : {"headless":true,"args":["--no-sandbox","--disable-setuid-sandbox"]}
chromium version  : 149.0.7827.55
page              : file:///C:/Projects/Personal/AID/.claude/worktrees/work-005-knowledge-graph/.aid/.temp/graph-stage1-probe/probe.html
```

**The user-agent string, quoted from an earlier run of the same probe against the same browser
build** (the final build reports the figure per canvas and no longer echoes the UA, so it is
attributed to that run rather than presented as this one's output):
```
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/149.0.7827.55 Safari/537.36
```

**The known figure.** One `256 × 256` canvas at `devicePixelRatio 1`, cleared to pure blue
`rgba(0,0,255,255)`, with a red `rgba(255,0,0,255)` figure drawn through a real pipeline — a compiled
and linked GLSL program, a vertex buffer, and `gl.drawArrays(gl.TRIANGLES, …)`. Not `gl.clear` with a
scissor, because that would test clearing rather than drawing, and PixiJS needs the pipeline.

The figure is **asymmetric in both axes and non-square**, and carries a **per-canvas identity mark**.
Both properties are anti-vacuity measures and are justified in § 3.

- `MAIN` rect, GL pixel coordinates (origin bottom-left), half-open: `x [32,96) y [144,240)`
- `MARK` rect, 16 × 16, per canvas slot *k*: `x [200+16k, 216+16k) y [16,32)`
- 19 sample coordinates, defined **once in the page** and handed to the driver, so L3 provably samples
  the same coordinates as L2 rather than a copied list: **6 must be figure, 13 must be background.**

**Three canvas configurations were run**, because the L3 question is not configuration-independent:

| Canvas | Context attributes | Draw pattern | Why it is in the set |
|---|---|---|---|
| `cA` | `{}` — **default** | drawn once | The configuration the project uses today. The primary verdict |
| `cB` | `{preserveDrawingBuffer: true}` | drawn once | D1a remedy (a), priced as evidence rather than described |
| `cC` | `{}` — **default** | **continuous `requestAnimationFrame` redraw** | FR-2's default mode; the shape feature-008 will actually have |

**L1 — context. Verdict PASS on all three.** Literal output, `cA`:

```
  L1 -- CONTEXT
    getContext type obtained         : webgl2
    context non-null                 : true
    isContextLost() after first draw : false
    webglcontextlost events observed : 0
    gl.getError() after first draw    : 0 (0 == NO_ERROR)
    shader compile vs / fs / link    : true / true / true
    => L1 PASS
```

`webgl2` was obtained directly; the `'webgl'` fallback was never needed. A separate isolation run
confirmed a `webgl` (1.0) context is also available: `"WebGL 1.0 (OpenGL ES 2.0 Chromium)"`, 35
extensions against `webgl2`'s 29.

**L2 — readable pixels. Verdict PASS on all three.** Literal output, `cA` — all 19 coordinates, not a
summary:

```
  L2 -- READABLE PIXELS (gl.readPixels)
    readPixels threw                : no
    gl.getError() after readPixels  : 0 (0 == NO_ERROR; queue drained immediately before)
    figure px 6400 (expected 6400)  background px 59136  other px 0
    figure bbox {"x0":32,"y0":16,"x1":215,"y1":239} (expected {"x0":32,"y0":16,"x1":215,"y1":239})
    allSamplesOk=true bboxOk=true countOk=true bothColoursPresent=true
    every sample coordinate:
      ok   fig-inner-BL       ( 34,146) expect FG  got FG    rgba(255,0,0,255)
      ok   fig-inner-TR       ( 94,238) expect FG  got FG    rgba(255,0,0,255)
      ok   fig-centre         ( 64,192) expect FG  got FG    rgba(255,0,0,255)
      ok   fig-inner-TL       ( 36,236) expect FG  got FG    rgba(255,0,0,255)
      ok   fig-inner-BR       ( 94,146) expect FG  got FG    rgba(255,0,0,255)
      ok   bg-canvas-BL       ( 10, 10) expect BG  got BG    rgba(0,0,255,255)
      ok   bg-canvas-TR       (245,245) expect BG  got BG    rgba(0,0,255,255)
      ok   bg-canvas-centre   (128,128) expect BG  got BG    rgba(0,0,255,255)
      ok   bg-canvas-BR       (245, 60) expect BG  got BG    rgba(0,0,255,255)
      ok   bg-canvas-TL       ( 10,245) expect BG  got BG    rgba(0,0,255,255)
      ok   bg-just-left       ( 30,192) expect BG  got BG    rgba(0,0,255,255)
      ok   bg-just-right      ( 98,192) expect BG  got BG    rgba(0,0,255,255)
      ok   bg-just-below      ( 64,142) expect BG  got BG    rgba(0,0,255,255)
      ok   bg-just-above      ( 64,242) expect BG  got BG    rgba(0,0,255,255)
      ok   bg-xmirror-of-BL   (221,146) expect BG  got BG    rgba(0,0,255,255)
      ok   bg-ymirror-of-BL   ( 34,109) expect BG  got BG    rgba(0,0,255,255)
      ok   mark-slot-0        (208, 24) expect FG  got FG    rgba(255,0,0,255)
      ok   mark-slot-1        (224, 24) expect BG  got BG    rgba(0,0,255,255)
      ok   mark-slot-2        (240, 24) expect BG  got BG    rgba(0,0,255,255)
    => L2 PASS
```

`cB` and `cC` are identical except that their identity mark occupies slot 1 and slot 2 respectively,
with the other two slots asserted background, and their expected bounding boxes shift accordingly to
`x1: 231` and `x1: 247`. Both PASS with `figure px 6400 (expected 6400)`, `other px 0`, and all 19
coordinates `ok`.

Colour values are **exact** — `255`/`0` are exactly representable, and the classifier's ±2 tolerance was
never consumed: every reported value is the expected value to the byte, and `other px 0` means not one
pixel of the 65,536 fell outside the two expected colours.

**L3 — capturable pixels. Verdict PASS on all three**, decoded in Node by a dependency-free PNG decoder
so the verification path does not route back through the surface under test. Full matrix:

| Canvas | `toDataURL()` same task as the draw | `toDataURL()` a later task, no redraw | `toDataURL()` inside a rAF right after a redraw | Playwright `locator(canvas).screenshot()` |
|---|---|---|---|---|
| `cA` default, drawn once | **PASS** (2413 B, colorType 6) | **FAIL** — 2364 B, all 65,536 px `rgba(0,0,0,0)` | **PASS** (2413 B) | **PASS** (805 B, colorType 2) |
| `cB` `preserveDrawingBuffer:true` | **PASS** (2409 B) | **PASS** (2409 B) | **PASS** (2409 B) | **PASS** (806 B) |
| `cC` default, continuous rAF (11 frames drawn at capture) | — | **FAIL** — 2364 B, all `rgba(0,0,0,0)` | **PASS** (2409 B) | **PASS** (805 B) |

Every PASS row above carries `figure px 6400 (expected 6400)`, `other px 0`, the exact expected bounding
box for that canvas's mark slot, and all 19 sample coordinates matching — including the two mark slots
that must be background and the two mirror-image controls.

`Playwright locator().screenshot()` **passed for all three canvases, including the two with default
context attributes.** That is L3's load-bearing result, because a screenshot-based gate is precisely
what FR-12 reuses.

**Decoder cross-check.** The capture that carried content on each canvas was re-decoded by a completely
independent path — an in-page `Image` plus a 2D canvas `getImageData` — and compared coordinate by
coordinate against the Node decoder:

```
  cA: browser-decoded dims 256x256; sample disagreements with the node decoder: 0 of 19
  cB: browser-decoded dims 256x256; sample disagreements with the node decoder: 0 of 19
  cC: browser-decoded dims 256x256; sample disagreements with the node decoder: 0 of 19
```

Two independently written decoders agreeing on all 19 coordinates and on both dimensions is what makes
the L3 numbers trustworthy rather than self-consistent.

**Page errors observed across the whole run: `0`.**

### 2.5 The one loud qualification on ENV-2's L3 PASS

**`toDataURL()` on a default-attribute WebGL canvas, called in a task later than the draw, returns a
fully transparent buffer** — 65,536 pixels of `rgba(0,0,0,0)`, for both the drawn-once canvas `cA` and
the **continuously simulating** canvas `cC`. Literal, `cC`:

```
    toDataURL(), a LATER task while the rAF loop is running
      png bytes 2364  256x256 colorType=6 depth=8
      figure px 0 (expected 6400)  background px 0  other px 65536
      figure bbox null (expected {"x0":32,"y0":16,"x1":247,"y1":239})
      dimsOk=true allSamplesOk=false bboxOk=false countOk=false notUniform=false
      => FAIL
```

**This is not an L3 negative and must not be read as one.** It is the documented semantics of
`preserveDrawingBuffer: false`: the drawing buffer is cleared once presented to the compositor. The
same canvas passes when the capture is taken at a controlled point in the frame, and `cB` — the same
draw with `preserveDrawingBuffer: true` — passes in every column. So the fact is:

**L3 is a PASS, and it is a PASS with a synchronisation obligation attached.** The obligation lands on
Stage 2's harness and on feature-008's draw loop, not on the renderer decision. It is stated here
rather than left to be discovered because that column FAILING is exactly what an unsynchronised harness
would see, and it would then be misread as "WebGL does not capture headless".

Note also that the *Playwright screenshot* passed on the default-attribute canvases regardless. The
compositor path and the `toDataURL` path have different timing constraints, and only the latter needed
the qualification.

### 2.6 ENV-1 — the CI runner: what I could not verify, and what would verify it

**NOT VERIFIED at any level.** Not reachable from this host, and it was not simulated or extrapolated
to. Precisely why:

1. It is a different **operating system and CPU architecture** — `ubuntu-24.04` versus this host's
   `win32 10.0.26200 x64`. ANGLE's backend selection is per-platform: this host's default resolves
   through Vulkan/SwiftShader on Windows, and a Linux runner selects among a different set. The
   renderer identity string is therefore not transferable, and the identity string is the one thing D1
   says a verdict is uninterpretable without.
2. It installs with **`npx playwright install chromium --with-deps`** (`test.yml:93`), which pulls
   OS-level libraries this host neither needs nor has. Whether those satisfy SwiftShader's
   requirements on that image is a property of that image.
3. GitHub's `ubuntu-24.04` runners have **no GPU**, so the software path is expected to be the *only*
   path there rather than merely the default — but "expected" is the correct word and I am not
   upgrading it. See § 4 for why the distinction matters.

**What would verify it, exactly:** commit the probe (or a trimmed equivalent) and add a step to the
`visual-fidelity` job that runs it after the existing `npm ci` + `npx playwright install chromium
--with-deps` steps, then read the job log for the three verdicts and the two identity strings. That is
a CI change and therefore an owner decision; it is offered, not taken. **It should be sequenced after
the defect in § 5 is resolved**, because a job whose gate step never executes is a weak place to add a
second gate step.

---

## 3. The vacuity audit of this probe, level by level

*Would a broken implementation pass this?* D1 supplies the answer for one level; the same thinking is
applied to the other two, and each control was **run**, not asserted.

### L1 — context

| Could pass while broken? | Control |
|---|---|
| A `<canvas>` with no real GL support returning a stub | `getContext` returning non-null is necessary but not sufficient: L1's verdict also requires `isContextLost() === false` **after the first draw** and `gl.getError() === 0` after that draw. A stub cannot accept `shaderSource`/`compileShader`/`linkProgram`/`drawArrays` without raising |
| Shaders silently failing to compile or link | Compile and link status are read and reported separately — `true / true / true` — and any failure would surface as a GL error on `useProgram`/`drawArrays`, which is in the verdict |
| A context that is created and then immediately lost | The `webglcontextlost` event is listened for and its count reported (`0`), independently of `isContextLost()` |

**Deliberate residual:** L1 passing does **not** imply pixels. A context that draws nothing passes L1
and fails L2 — that is the D1a row-3 case and separating it is the entire point of having three levels.
This is not a vacuity in L1; it is L1's definition.

### L2 — readable pixels

| Could pass while broken? | Control |
|---|---|
| A uniformly-filled buffer | **13 of the 19 coordinates must be background.** D1's own control, and it is the reason the level is not vacuous |
| A buffer that is all zeros / transparent | `rgba(0,0,0,0)` classifies as `OTHER`, matching neither expectation; and `other px 0` is asserted |
| A figure of the right colour in the wrong place | Four coordinates sit **just outside** each of the figure's four edges (`bg-just-left/right/below/above`, 2 px clear of the boundary) and must be background |
| A y-flip, x-flip or transpose in the read path | The figure is **asymmetric in both axes and non-square** on purpose. Two coordinates sample the exact mirror image of a figure coordinate in each axis (`bg-xmirror-of-BL`, `bg-ymirror-of-BL`) and must be background. A centred square would have let all three transforms pass |
| A right-looking sample set over a wrong image | The whole 65,536-pixel buffer is classified: **exact** figure pixel count (`6400`, asserted equal) and **exact** bounding box (asserted equal in all four edges). This assertion does not use the sample list at all |
| An error swallowed before the read | The GL error queue is **drained immediately before** `readPixels`, so `glErrorAfterReadPixels` is attributable to `readPixels` and nothing earlier. This control was added *because* the first run reported `1280` here and the cause turned out to be upstream (§ 2.2) |

### L3 — capturable pixels

| Could pass while broken? | Control |
|---|---|
| **A screenshot of a blank canvas** | **Ran as an explicit control.** A second WebGL canvas, context created and **never drawn to**, was pushed through the *same* analysis code. Both its `toDataURL` (all `rgba(0,0,0,0)`) and its Playwright screenshot (all `rgba(255,255,255,255)` — the page background showing through) **FAIL every assertion.** Literal: `=> vacuity control HELD (both blank captures FAIL, as required)`. Had it passed, L3 would prove nothing |
| Sampling different coordinates than L2 | The sample list is built **once in the page** and returned to the driver; L2 and L3 consume the same array. Not two lists kept in step by hand |
| The capture returning the **wrong element's** pixels | All three canvases draw the *same* main figure, so without a discriminator a locator returning the wrong element would pass. Each canvas therefore draws a **16 × 16 identity mark in its own x slot**, and each canvas asserts its own slot is figure **and the other two slots are background**. Measured: `cA` slot 0 FG / slots 1,2 BG; `cB` slot 1 FG / 0,2 BG; `cC` slot 2 FG / 0,1 BG. The expected bounding box also differs per canvas (`x1` = 215 / 231 / 247) and is asserted exactly |
| A wrong or lenient PNG decoder manufacturing the expected image | Three defences, all run: (i) the blank-canvas control decodes through the **same** code and fails, so the decoder does not invent content; (ii) an **independently written** decoder in the browser agrees on **0 of 19** disagreements for every canvas; (iii) PNG dimensions are asserted `256 × 256`, so a 1×1 or truncated capture cannot pass — and the two capture routes genuinely differ in encoding (`colorType 6` for `toDataURL`, `colorType 2` for the screenshot), which a decoder bug specific to one path could not survive |
| A stale capture from a previous canvas or frame | The per-canvas identity mark covers the cross-canvas case; the `MAIN`-plus-`MARK` bounding box covers the truncation case; and the deliberately FAILING later-task column (§ 2.5) demonstrates the analysis *does* detect an empty buffer rather than reporting whatever it last saw |

**The residual I cannot close from here, stated rather than glossed:** every control above ran in
**ENV-2 only**. Their design is environment-independent; their *results* are not. That is § 2.6.

---

## 4. Supplementary: is the software rasteriser the only path? — explicitly outside every verdict

D1 permits re-running under additional flags to establish *whether a software-rendering path exists at
all*, as evidence for D1a remedy 1. The default turned out to **be** the software path, so the
symmetric question was asked. **Identity strings only. No timings — frame time is Stage 2 and was not
measured.**

```
THE REUSED CONFIGURATION (validate-visuals.mjs:185-188)
  args     : ["--no-sandbox","--disable-setuid-sandbox"]
  context  : WebGL 2.0 (OpenGL ES 3.0 Chromium)
  vendor   : "Google Inc. (Google)"
  renderer : "ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device (Subzero) (0x0000C0DE)), SwiftShader driver)"

supplementary: + --use-gl=angle --use-angle=default
  args     : ["--no-sandbox","--disable-setuid-sandbox","--use-gl=angle","--use-angle=default"]
  context  : WebGL 2.0 (OpenGL ES 3.0 Chromium)
  vendor   : "Google Inc. (NVIDIA)"
  renderer : "ANGLE (NVIDIA, NVIDIA RTX 2000 Ada Generation Laptop GPU (0x000028B8) Direct3D11 vs_5_0 ps_5_0, D3D11)"

supplementary: + --enable-unsafe-swiftshader removed, GPU forced on
  args     : ["--no-sandbox","--disable-setuid-sandbox","--enable-gpu","--ignore-gpu-blocklist"]
  context  : WebGL 2.0 (OpenGL ES 3.0 Chromium)
  vendor   : "Google Inc. (NVIDIA)"
  renderer : "ANGLE (NVIDIA, NVIDIA RTX 2000 Ada Generation Laptop GPU (0x000028B8) Direct3D11 vs_5_0 ps_5_0, D3D11)"

supplementary: + --use-angle=d3d11 (Windows hardware backend)
  args     : ["--no-sandbox","--disable-setuid-sandbox","--use-angle=d3d11"]
  context  : WebGL 2.0 (OpenGL ES 3.0 Chromium)
  vendor   : "Google Inc. (NVIDIA)"
  renderer : "ANGLE (NVIDIA, NVIDIA RTX 2000 Ada Generation Laptop GPU (0x000028B8) Direct3D11 vs_5_0 ps_5_0, D3D11)"

supplementary: --disable-gpu (the negative control -- should degrade)
  args     : ["--no-sandbox","--disable-setuid-sandbox","--disable-gpu"]
  context  : WebGL 2.0 (OpenGL ES 3.0 Chromium)
  vendor   : "Google Inc. (Google)"
  renderer : "ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device (Subzero) (0x0000C0DE)), SwiftShader driver)"
```

**The third block's label is my harness's own and it is inaccurate** — no
`--enable-unsafe-swiftshader` was ever passed or removed. The `args` line is authoritative in every
block. Quoted verbatim rather than silently corrected, because the label is what the run printed.

Every configuration yielded a non-null `webgl2` context. Two findings:

1. **A hardware-backed headless context is reachable on this host with one added flag.** So on a
   developer machine with a GPU, the choice between software and hardware rendering is a *launch-flag*
   choice, which means a hardware confirmation lane for D4b's second half is technically available
   here. Whether it is *acceptable* as an acceptance path is not a technical question and is not mine.
2. **The negative control `--disable-gpu` produces the same renderer as the reused configuration.**
   The reused configuration is, for WebGL purposes, already running as though the GPU were disabled.
   That is a stronger statement than "no GPU flag is passed" and it is measured, not inferred.

**No flag was needed to turn any verdict positive**, so D1's "a flag that fixes the graph must not
change `kb.html`'s render" clause does not fire, feature-011's Open Item 8 gains no new
parameterisation from Stage 1, and nothing is routed to it here.

**`kb.html`'s existing T1–T4 results are unchanged.** The reused gate was run provisioned, against the
real artifact, under the unmodified configuration:

```
$ node canonical/aid/scripts/summarize/validate-visuals.mjs .aid/knowledge/kb.html
Found 4 visual(s) to validate.
Visual 1: [PASS] diagram-box   T3 PASS (1152x237 px)  T2 PASS (0.0%)  T1 PASS (9 text nodes)   T4 PASS
Visual 2: [PASS] diagram-box   T3 PASS (1152x460 px)  T2 PASS (0.0%)  T1 PASS (29 text nodes)  T4 PASS
Visual 3: [PASS] diagram-box   T3 PASS (1152x410 px)  T2 PASS (0.0%)  T1 PASS (21 text nodes)  T4 PASS
Visual 4: [PASS] diagram-box   T3 PASS (1152x470 px)  T2 PASS (0.0%)  T1 PASS (25 text nodes)  T4 PASS
PASS -- Visual-fidelity gate: 4/4 visual(s) passed (T1/T2/T3/T4 all clear).
EXIT_CODE=0
```

This also **confirms one D1b prediction and refutes a suspected Windows defect.** The collector found
**4** visuals, all `.diagram-box`, and no `<canvas>` — consistent with D1b's verdict that a `<canvas>`
matches none of the three selectors and needs no exemption. And line 204's `page.goto` — whose URL is the
template literal ``file://${absHtmlPath}`` — **works** when `absHtmlPath` is a Windows absolute
path (`file://C:\...`, backslashes, no `pathToFileURL`), because Chromium normalises it. That was
checked because it looked like a live defect; it is not one, and it is recorded as a
checked-and-negative result.

---

## 5. A live repo defect found while verifying ENV-1's basis — recorded, not fixed

**The CI `visual-fidelity` job has never validated anything. It takes its SKIP branch on every run.**

`.github/workflows/test.yml:105` sets the artifact path:

```yaml
SUMMARY=".aid/dashboard/kb.html"
```

and line 106 guards `if [[ ! -f "$SUMMARY" ]]; then … exit 0`. But the generated summary is at
**`.aid/knowledge/kb.html`** — which is what exists on disk, what is tracked in git, and what
`playwright-provisioning.md:53` documents as the invocation. Verified:

```
$ ls -la .aid/dashboard/kb.html
ls: cannot access '.aid/dashboard/kb.html': No such file or directory

$ ls -la .aid/dashboard/
ls: cannot access '.aid/dashboard/': No such file or directory

$ git ls-files --error-unmatch .aid/knowledge/kb.html
.aid/knowledge/kb.html

$ git ls-tree -r origin/master --name-only | grep "kb\.html"
.aid/knowledge/kb.html
dashboard/server/tests/fixtures/pt1h-kb-approved/.aid/knowledge/kb.html
dashboard/server/tests/fixtures/pt1h-repo-a/.aid/knowledge/kb.html

$ git ls-tree -r origin/master --name-only | grep "^\.aid/dashboard"
(no output)
```

Present on `origin/master` too (blob `b88b09ea`, line 105), so it is not a worktree artifact.
Introduced by commit **`5f2b3682`** — *"ci(test): drop dead Mermaid pre-seed step + add
visual-fidelity gate (feature-015 follow-up)"*, **Fri Jun 26 2026** — i.e. the path has been wrong
since the gate was added.

**Why this matters to feature-002 specifically, beyond being a bug.** D1's environment table justifies
ENV-1's place in the set as *"where FR-12's gate actually runs, and the only environment whose
configuration the project controls"*. **That premise is currently false.** The `npm ci` and
`npx playwright install chromium --with-deps` steps do run (they are unconditional, `test.yml:89-93`),
so provisioning is exercised in CI — but the gate step itself always short-circuits. FR-12's visual
gate is, today, a local-and-manual gate wearing a CI badge.

**Owner: the CI maintainer / repo owner.** Not fixed here — this is a research task and the fix is a
one-line change to a shared workflow whose blast radius (a gate that starts failing the moment it
starts running) is an owner call. **Recorded with its owner, as the discipline requires.** A related
observation, offered without a recommendation: the SKIP branch's message says *"not present in this
branch"*, which reads as graceful degradation and is indistinguishable in a green log from the gate
having run.

---

## 6. Stage 1 escalation — D10 part 3 (AC-S2)

### 6.1 The matrix, resolved

All three levels PASS in ENV-2 and no level is negative anywhere, so **§ D1a's escalation rows 2, 3 and
4 do not fire and nothing is handed to the work owner for decision.** The applicable row is the first:

> **L1 ✓ L2 ✓ L3 ✓** — C-5 satisfied by the existing shape; FR-12's reuse intact; the renderer decision
> untouched. *Remedy: record the renderer identity string as evidence and move to Stage 2. Owner: this
> feature.*

Discharged: the identity strings are at § 2.2, and § 7 states what Stage 2 inherits.

**Stated for completeness, because AC-S2 asks what *would* change and a resolved matrix still owes its
reasoning:** the consequence of each negative, and the alternative not taken, are as § D1a states them
and are **not** restated here as though newly derived — that would be re-authoring a frozen contract.
What Stage 1 *adds* to those rows is evidence about their likelihood, and it is one sentence: the row-2
case (draws but the capture is blank) is the one that **nearly** fired, via § 2.5's later-task
`toDataURL` column, and the evidence now says it is a **synchronisation** condition rather than a
capture-path failure. That distinction is what § 6.2 turns into a recommendation.

### 6.2 The one recommendation Stage 1 does owe, on evidence

§ D1a row 2 requires that, *if* L3 were negative, the report **choose** between (a) requesting
`preserveDrawingBuffer` and capturing at a controlled point, and (b) treating the live surface as
capture-exempt with an in-page `readPixels` assertion substituted. L3 is **not** negative, so the
choice is not forced. But the measurement bears on it directly and leaving that unsaid would waste it:

**The evidence says neither (a) nor (b) is needed, and says so with a number.** `cA` and `cC` — both
**default** context attributes, no `preserveDrawingBuffer` — pass the Playwright element screenshot with
`figure px 6400 (expected 6400)` and `other px 0`. A screenshot-based gate on the live surface works
with **no** context-attribute change and therefore **no** documented per-frame penalty for D4 to
measure. `cB` shows (a) would also work; the point is that it is not required.

**Recommendation to feature-008, as a constraint rather than a design:** if the drawing code ever needs
`canvas.toDataURL()` — for an export, a fixture, or a test — the call must be made **inside the frame
that drew**, or the context must be created with `preserveDrawingBuffer: true`. A `toDataURL()` from
outside the draw loop on a default-attribute context returns a fully transparent buffer, measured. This
is a note for feature-008's seam, not a request to change the decided architecture, and **feature-011
is asked for nothing.**

---

## 7. What these verdicts mean — the escalation consequence

### 7.1 For Stage 2

**Stage 2a is unblocked.** § The three stages at a glance gates Stage 2a on "Stage 1 at level 2 or
better"; ENV-2 delivers level 3. FR-18's order is satisfied and the bench's *design* now has the
verdict it was waiting on.

Four things Stage 2 inherits, each of which changes how it must be built:

1. **The measured surface is a software rasteriser.** `ANGLE … SwiftShader driver`. Every frame time
   Stage 2 measures under the reused configuration is a **CPU** rasterisation time. D4b's
   headless-conservatism comparison is therefore not an optional refinement — it is the only thing
   that connects a headless number to a user's machine, and § 4 establishes that the hardware
   comparand is reachable here by a launch flag. **Both renderer strings must be reported with any
   frame-time pair** (AC-S7), and § 2.2 and § 4 supply them.
2. **The draw term is measurable, not just the layout term.** § D1a's load-bearing property — that the
   physics half is unaffected under every verdict — was insurance against L1 ✗. It did not fire. Stage
   2 can separate and measure **both** terms, which is what D4 asks for.
3. **The harness must synchronise to the frame, and D1b already said why.** The reused validator
   asserts at `waitUntil: 'domcontentloaded'`, at which point a continuously-simulating graph has not
   settled; § 2.5 adds that a capture taken outside the drawing frame is *empty*, not merely early.
   Instrument in the page, capture inside the frame.
4. **A screenshot-based measurement route is available.** Confirmed on default context attributes, so
   Stage 2 need not adopt `preserveDrawingBuffer` and need not price its per-frame cost.

**Still absent, and correctly so:** `canonical/aid/templates/graph/scale-ceiling.yml` retains its one
key and no value. **Stage 1 measured nothing that could fill it, and nothing was invented.** NFR-8's
ceiling is Stage 2b's output, gated on delivery-002.

### 7.2 For feature-008's canvas

feature-008 is unbuilt and deliberately so, with its seam documented and nothing vendored, because this
research had not run. **It ran. The result does not change what feature-008 is.**

| Question feature-008 was waiting on | Answer from Stage 1 |
|---|---|
| Does the decided architecture — PixiJS over WebGL — have a live context in the toolchain that validates it? | **Yes.** `webgl2` directly, no `webgl` fallback needed, context not lost, no GL error, shaders compile and link |
| Will its output be machine-checkable, or must the canvas rest on the human visual gate? | **Machine-checkable, two independent ways.** In-page `gl.readPixels` and an external screenshot both resolve the drawn figure exactly |
| Must the draw loop change shape to be capturable? | **No.** Default context attributes; continuous rAF redraw; the element screenshot resolves it. One constraint only: a `toDataURL()` must be taken inside the drawing frame (§ 6.2) |
| Does a canvas disturb the shared validators? | **No new disturbance found.** The reused gate collected 4 `.diagram-box` visuals and no canvas, as D1b predicted; `kb.html` remains 4/4 PASS |
| Any renderer-driven change to its size or shape? | **None from Stage 1.** No proxy layer (Q9), no degraded mode, no `preserveDrawingBuffer` penalty. Its size range and drivers are D10 part 16 and belong to the **full** record, and are **not** stated here — Stage 1 measured nothing that bounds them, and the superseded ~279-line estimate stays void |

**The clearance is scoped.** It rests on ENV-2. If the owner intends the CI job to be the gate that
protects feature-008's output, § 5 must be resolved first, and then ENV-1 must actually be measured —
because the gate cannot protect anything while it is skipping.

---

## 8. D10 coverage — what this document discharges, and what is still owed

Stated so that a reader cannot mistake a Stage-2/3 absence for an omission, and so that a gate cannot
pass this on completeness alone.

| # | D10 part | Status here |
|---|---|---|
| 1 | Question and scope | **Discharged** — § 1 |
| 2 | Stage 1 — three-level verdict per environment, identity strings verbatim, each invocation (AC-S1) | **Discharged for ENV-2 and ENV-3. ENV-1 NOT VERIFIED** — § 2, with the gap and its remedy at § 2.6 |
| 3 | Stage 1 escalation, per negative level, owners, rejected alternative (AC-S2) | **Discharged** — § 6. No level is negative; the applicable row is stated, and the one recommendation the evidence supports is given |
| 4 | Bench derivation procedure and derived figures (AC-S3, AC-S6) | **Owed by Stage 2b**, gated on delivery-002. **No bench size, node count, edge count or degree figure appears in this document** |
| 5 | The response surface (AC-S4) | **Owed by Stage 2a.** Not begun — FR-18's order put this probe first |
| 6 | Every measurand in D4's set (AC-S5) | **Owed by Stage 2a** |
| 7 | The frame-time predicate and headless-conservatism comparison (AC-S7) | **Owed by Stage 2a.** Stage 1 supplies one of its two required renderer strings (§ 2.2) and shows the second is reachable (§ 4) |
| 8 | Settle time, reported not gated (AC-S8) | **Owed by Stage 2a** |
| 9 | The ceiling (AC-S9, AC-16a) | **Owed by Stage 2b.** `scale-ceiling.yml` deliberately still has no value |
| 10 | Payload at every tracked copy (AC-S10) | **Owed by Stage 3**, which does not wait on Stage 1 |
| 11 | Licence and attribution (AC-S11) | **Owed by Stage 3** |
| 12 | The update mechanism (AC-S12) | **Owed by Stage 3** |
| 13 | Runtime prerequisites in prose, WebGL named (AC-6) | **Owed by the full record.** Stage 1 confirms the WebGL prerequisite is satisfiable in the validation toolchain; the prose statement is written once payload and companions are known |
| 14 | The AC-21 validation route (AC-S13, AC-21) | **Owed by the full record** (D9). Stage 1 strengthens it incidentally: the route must survive a canvas that does not render, and no Stage-1 outcome threatens it |
| 15 | Drafted `technology-stack.md` / `infrastructure.md` content | **Owed by the full record.** Nothing drafted here, and **nothing written to `.aid/knowledge/`** — that lands at ship time by feature-013 |
| 16 | What this implies for feature-008's size | **Owed by the full record.** § 7.2 states what Stage 1 does and does not bound, and states no line count |
| 17 | Every figure's attribution (AC-S6) | **Discharged** — § 9 |

---

## 9. Attribution of every figure — AC-S6

Every figure in this document is in one of the three admissible forms. **No figure is carried over from
the superseded record.**

| Figure | Form | Source |
|---|---|---|
| All L1/L2/L3 verdicts; `6400`, `59136`, `other px 0`; every bounding box; every `rgba(…)`; PNG byte counts; `0 of 19` decoder disagreements; `11` frames; `0` page errors | Quoted runtime output | `.aid/.temp/graph-stage1-probe/probe.mjs`, invocation at § 2.4, run 2026-08-05. A machine-readable copy was written to `result-env2.json` in the same scratch directory and removed with it (§ 11); the literal output quoted throughout this document is the durable evidence |
| `1280` (`GL_INVALID_ENUM`); `undefined` typeofs; extension key lists; both identity strings; `29`/`35` extension counts; `"WebGL 1.0 (OpenGL ES 2.0 Chromium)"` | Quoted runtime output | `probe.mjs` and `probe2-identity.mjs`, run 2026-08-05 |
| Every renderer string in § 4 | Quoted runtime output | `probe3-flags.mjs`, run 2026-08-05 |
| `chromium 149.0.7827.55`; `playwright 1.61.1`; `node v22.14.0`; `win32 10.0.26200 x64`; `devicePixelRatio 1` | Quoted runtime output | `probe.mjs` header, § 2.4 |
| `4/4` visuals; `1152x237`/`460`/`410`/`470` px; `9`/`29`/`21`/`25` text nodes; `0.0%` overlap; thresholds `10px` and `732, 390px` | Quoted runtime output | `node canonical/aid/scripts/summarize/validate-visuals.mjs .aid/knowledge/kb.html`, run 2026-08-05 |
| `validate-visuals.mjs` lines `119-146`, `185-188`, `195-202`, `204`; `playwright: 1.61.1` and `engines.node >= 20` in `package.json`; `playwright-provisioning.md:53`; `test.yml:89-93`, `:93`, `:105`, `:106` | Verified on-disk fact with command and read date | Read 2026-08-05 at HEAD `62210dae` |
| `.aid/dashboard/` absent; `.aid/knowledge/kb.html` tracked; blob `b88b09ea` line 105; commit `5f2b3682` dated Fri Jun 26 2026 | Verified on-disk / git fact with command | Commands quoted inline at § 5, run 2026-08-05 |
| `256 × 256`; `x [32,96) y [144,240)`; `x [200+16k, 216+16k) y [16,32)`; `19` samples, `6` figure / `13` background; expected `6400`; expected bounding boxes | Parameter of the harness, not a measurement | Declared in `.aid/.temp/graph-stage1-probe/probe.html` and echoed by the probe at run time (§ 2.4) |
| Everything in § 8 marked *Owed* | **Explicitly labelled as a quantity still to be produced** | Not measured. Named with the stage that owes it |

---

## 10. Routed items — recorded with owners, not fixed here

| # | Item | Owner | Note |
|---|---|---|---|
| **S1-1** | § D1 instructs the probe to read `WEBGL_debug_renderer_info`'s `UNMASKED_RENDERER_STRING` / `UNMASKED_VENDOR_STRING`. The extension defines **`UNMASKED_RENDERER_WEBGL`** / **`UNMASKED_VENDOR_WEBGL`** (numeric `0x9246` / `0x9245`). The SPEC's names read back `undefined` and yield `null` plus `GL_INVALID_ENUM` | **feature-002 / the work owner** — feature-002 is frozen (2026-07-30), so per Q26 the owner decides: correct now, batch into the editorial pass, or carry as debt | **Editorial, not mechanical** — no mechanism depends on the spelling, and the identity was obtained. But it is the kind of clause that makes a false negative look like a finding, and it nearly did (§ 2.2). Suggested queue: the batched editorial sweep (Q24 item 9) |
| **S1-2** | `.github/workflows/test.yml:105` points the `visual-fidelity` gate at `.aid/dashboard/kb.html`, which exists nowhere in the tree; the job has taken its SKIP branch on every run since `5f2b3682` (2026-06-26) | **CI maintainer / repo owner** | Full evidence at § 5. Invalidates D1's stated basis for ENV-1 being "where FR-12's gate actually runs". Not fixed here |
| **S1-3** | ENV-1 (`ubuntu-24.04`) has no Stage-1 verdict | **the work owner** | § 2.6 states exactly what would produce one. Sequence after S1-2 |

---

## 11. Reproduction, and what was installed

**Harness location:** `.aid/.temp/graph-stage1-probe/` — gitignored (`.gitignore:69`), **throwaway by
construction**, and removed after the run per § Layers & Components ("scratch space; not committed").
Files were `probe.html` (the page and the figure), `probe.mjs` (the driver, three levels), `png.mjs` (a
dependency-free PNG decoder), `probe2-identity.mjs` and `probe3-flags.mjs` (the two follow-ups).
**No product code was written and nothing from the harness ships.**

**Installed, and disclosed:**

| What | Where | Command | Tracked files touched? |
|---|---|---|---|
| `playwright` 1.61.1 + 1 transitive package | `canonical/aid/scripts/summarize/node_modules/` | `npm ci` — the documented local path (`playwright-provisioning.md:30-32`); output: `added 2 packages, and audited 3 packages in 1s / found 0 vulnerabilities` | **No.** `npm ci` reads `package.json`/`package-lock.json` and does not write them; `node_modules/` is gitignored (`.gitignore:13`) and excluded from the generator's emission walk at any depth |
| Chromium 149.0.7827.55 (`chromium-1228`) + Chrome Headless Shell | `%LOCALAPPDATA%\ms-playwright\` — **outside the repository** | `npx playwright install chromium`; downloaded 183.6 MiB + 113.6 MiB | **No** |
| `playwright` 1.61.1 into the scratch dir | `.aid/.temp/graph-stage1-probe/node_modules/` | `npm install --no-save playwright@1.61.1`; resolved version verified `1.61.1` | **No** — gitignored path; `--no-save`; the repo's own `package.json`/`package-lock.json` are untouched. Needed because Node's ESM resolution walks up from the probe's own directory and never reaches `canonical/…/summarize/node_modules` |

**Pre-existing state disclosed:** `%LOCALAPPDATA%\ms-playwright\` already contained `chromium-1234`,
`chromium_headless_shell-1234`, `ffmpeg-1011`, `winldd-1007` and several `mcp-chrome-*` builds before
this run, from unrelated tooling on this machine. Playwright 1.61.1 pins build **1228**, which was not
present and was downloaded. The pre-existing builds were not used.

**Cleanup performed:** both `node_modules/` trees and the entire scratch directory were removed after
the run, and ENV-3's SKIP behaviour was re-verified afterwards to confirm the machine was returned to
the unprovisioned state the probe first measured. The downloaded browser binaries were left in the
machine-level cache, outside the repository.

**Re-provisioning to reproduce:** `cd canonical/aid/scripts/summarize && npm ci && npx playwright
install chromium`, then re-create the harness. The harness is reconstructible from this document's
specification of the figure, the sample coordinates, the three canvas configurations and the controls;
it is deliberately not committed.
