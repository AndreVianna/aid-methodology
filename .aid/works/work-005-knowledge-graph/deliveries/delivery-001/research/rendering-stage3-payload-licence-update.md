# Stage 3 — payload, licence, attribution and the update mechanism (D6, D7)

> **Scope: Stage 3 only, and only its two parts.** This document is the deliverable of feature-002's
> **D6** (payload, packaging shape, licence and attribution) and **D7** (the update mechanism and the
> ongoing obligation it creates) — D10 parts **10, 11 and 12** in the SPEC's own numbering. It does
> **not** touch Stage 1 (the WebGL probe — discharged by `rendering-stage1-webgl-probe.md`, beside this
> document) or Stage 2 (the response surface, the bench, the ceiling — D10 parts 4–9, 13, 14, 16, owed
> by the Stage-2 tasks of this same feature once feature-004's enumerator and feature-005's Pass 1a have
> run). **The renderer is not reopened here.** Q9 decided `d3-force` for physics and PixiJS (WebGL) for
> drawing, 2D; this document reports what adopting that decided pair costs and obliges, not whether to
> adopt it.
>
> **This document is a research artifact under a transient work folder and cites none of its own
> siblings as authority.** Every claim below traces to a source outside `.aid/works/` — an upstream
> package registry entry, an upstream distribution file at a pinned version, or a file already
> permanent in this repository (`canonical/`, `.github/`, the root `LICENSE`). Per `CLAUDE.md` §
> Tracking discipline, no permanent artifact may depend on this document either; the facts that must
> survive land in `technology-stack.md` and `infrastructure.md` at ship time, by feature-013, and the
> packaging wiring lands by feature-012 — neither is done here.

**Work:** work-005-knowledge-graph · **Feature:** feature-002 · **Date run:** 2026-08-05
**Repository state:** HEAD `02be5296` (working tree carried unrelated concurrent edits to other
tasks' `STATE.md` files at read time; nothing this document cites is one of them)
**Specification:** `.aid/works/work-005-knowledge-graph/features/feature-002-graph-rendering-research/SPEC.md`
§ D6, § D7, § D10 parts 10–12 (consulted as the task definition, not cited as a fact source below)

---

## 1. Question and scope

**D6's question:** what does the project take on by shipping `d3-force` and PixiJS — how many bytes, in
what shape, under what licence, with attribution owed where?

**D7's question, the sharper of the two:** who notices when either library moves upstream, and — a
second, distinct question — who notices if the shipped copy silently stops equalling upstream? The
verified baseline is that nobody does either today for any JavaScript dependency in this repository.

**Explicitly out of scope here:** the renderer choice (Q9, closed); any frame-time, bench, or ceiling
figure (Stage 2's); the palette and its contrast obligation (D8, a different task); AC-21's keyboard
route (D9, a different task). No performance number appears anywhere below.

---

## 2. The vendored set is five files, not two — a finding this task owes before it can price anything

Feature-008's SPEC (`features/feature-008-interactive-graph-canvas/SPEC.md` § External Integrations, §
Feature Flow step 2) fixes the consumption shape: both libraries are reached as **globals**, via classic
`<script src>` tags, because a `file://` page cannot import a relative ES module. That shape determines
which distributed build of each library is the one that ships, and inspecting that build surfaced a
dependency chain the requirements text does not mention.

**Method.** Read on **2026-08-05** via the npm registry and `unpkg.com`'s CDN (which mirrors npm
packages verbatim and is used here only to *read* the published bytes, never as part of the shipped
packaging):

```
$ curl -sL https://registry.npmjs.org/d3-force/latest      # -> version 3.0.0, license "ISC"
$ curl -sL https://registry.npmjs.org/pixi.js/latest        # -> version 8.19.0, license "MIT"
$ curl -sL https://unpkg.com/d3-force@3.0.0/package.json    # -> dependencies: d3-dispatch "1 - 3",
                                                             #    d3-quadtree "1 - 3", d3-timer "1 - 3"
$ curl -sL https://unpkg.com/d3-force@3.0.0/dist/d3-force.min.js | head -c 260
// https://d3js.org/d3-force/ v3.0.0 Copyright 2010-2021 Mike Bostock
!function(n,t){"object"==typeof exports&&"undefined"!=typeof module?t(exports,require("d3-quadtree"),
require("d3-dispatch"),require("d3-timer")):"function"==typeof define&&define.amd?define(...
```

**The finding.** `d3-force`'s UMD build's global-scope branch does not stand alone: its factory function
still expects `d3-quadtree`, `d3-dispatch` and `d3-timer` to already be merged into the same global `d3`
object (each of those three modules' own UMD build does exactly that merge — verified the same way,
same date, for each: `d3-quadtree@3.0.1`, `d3-dispatch@3.0.1`, `d3-timer@3.0.1`, all three ISC, all three
the latest 3.x release per `registry.npmjs.org/<name>` read the same date). Loading only
`d3-force.min.js` as a classic script and nothing else throws at parse time, because
`require("d3-quadtree")` is unconditionally reached inside the UMD wrapper's Node/CommonJS branch check
— and even reaching the global branch cleanly, the factory it calls needs `n.d3.quadtree`, `n.d3.dispatch`
and `n.d3.timer` to exist, which only the other three scripts, loaded first, provide.

**PixiJS carries no equivalent chain.** Its browser bundle contains zero `require(` calls (`grep -c
"require(" pixi.min.js` → `0`, same date) — everything PixiJS's global build needs is bundled into the
one file.

**Consequence for D6.** The "two libraries" the requirement names are **five vendored files** in
practice: `d3-quadtree`, `d3-dispatch`, `d3-timer` and `d3-force` (loaded in that order — the last three
of the four merge onto the same `d3` global that `d3-force` then extends) plus `pixi.js`. Every payload
and licence figure below is stated per file and combined, so this is not lost in a single number.

---

## 3. Payload — AC-S10

### 3.1 Per-file bytes, at the exact evaluated version

Each file is the classic-script (UMD/IIFE) minified build a `file://` page can load with `<script src>`
and no bundler — the same build class feature-008's contract requires. Downloaded verbatim on
**2026-08-05** from `unpkg.com` (npm's own CDN mirror) and measured with `wc -c` on the actual bytes, not
an approximate directory-listing figure:

| File | Package @ exact version | Bytes | Licence (§4) |
|---|---|---|---|
| `d3-quadtree.min.js` | `d3-quadtree@3.0.1` | 5,279 | ISC |
| `d3-dispatch.min.js` | `d3-dispatch@3.0.1` | 1,901 | ISC |
| `d3-timer.min.js` | `d3-timer@3.0.1` | 1,947 | ISC |
| `d3-force.min.js` | `d3-force@3.0.0` | 8,300 | ISC |
| `pixi.min.js` | `pixi.js@8.19.0` | 797,792 | MIT |
| **Combined, one copy** | — | **815,219 bytes** (≈ 796.1 KiB, ≈ 0.777 MiB) | — |

"Latest" is not a value per D6's own instruction, so each version above is the exact `dist-tag: latest`
npm reported on the read date for that package, individually confirmed reproducible: `d3-quadtree`,
`d3-dispatch` and `d3-timer` each have exactly two published 3.x releases (`3.0.0`, `3.0.1`), with `3.0.1`
current for all three; `d3-force` has one 3.x release, `3.0.0`; `pixi.js` is at `8.19.0`. A future
`/aid-graph` build that pins different versions must restate this table — it is a property of the pinned
versions, not of the libraries.

Since the artifact opens via `file://` (FR-17), no HTTP compression applies at load time — the bytes
above are what a reader's browser parses, not a wire-compressed approximation.

### 3.2 The delivered artifact — the figure for a reader

`.aid/knowledge/graph.html`'s companions add these 815,219 bytes once, under whatever
`.aid/knowledge/<subdir>/vendor/<name>/` layout § 5 recommends. This is the number that answers "what do
I download to open the graph."

### 3.3 The repository-side figure — corrected, with its own evidence

The SPEC that dispatched this task states the multiplier as **six** tracked copies (one canonical
source, five profile install trees, each `sha256`-recorded in `profiles/*/emission-manifest.jsonl`). This
task's measurement posture — never carry a figure forward unverified — applies to that number as much as
to any other, so it was checked rather than copied, on the sibling directory that already exists on disk
today (`canonical/aid/templates/graph/`, feature-001's data files; `canonical/aid/templates/knowledge-graph/`
itself does not exist yet, since feature-008 has not built it):

```
$ ls -d profiles/*/                                    # 5 profile trees, confirmed:
profiles/antigravity/  profiles/claude-code/  profiles/codex/  profiles/copilot-cli/  profiles/cursor/

$ git ls-files | grep -E '^\.(claude|cursor|github)/' | sed -E 's#^(\.[a-z]+)/.*#\1#' | sort -u
.claude
.cursor
.github

$ git ls-files .claude/aid/templates/graph/ .cursor/aid/templates/graph/ .github/aid/templates/graph/ 2>&1
.claude/aid/templates/graph/coverage-bearing.yml   [... 5 files]
.cursor/aid/templates/graph/coverage-bearing.yml   [... 5 files]
[.github/aid/templates/graph/ -- no output; not tracked there]

$ wc -c canonical/aid/templates/graph/relation-vocabulary.yml \
        .claude/aid/templates/graph/relation-vocabulary.yml \
        .cursor/aid/templates/graph/relation-vocabulary.yml \
        profiles/claude-code/.claude/aid/templates/graph/relation-vocabulary.yml
   52198  canonical/...   52198  .claude/...   52198  .cursor/...   52198  profiles/claude-code/.../...

$ diff -rq .cursor/aid/templates/graph profiles/cursor/.cursor/aid/templates/graph
[no output -- byte-identical]
```

**Finding: for this template family, there are eight real, separately git-tracked, byte-identical
regular files (not symlinks, not a build cache) — not six.** In addition to the canonical source and the
five `profiles/*/` install trees, this repository also carries **root-level dogfood mirrors** at
`.claude/` and `.cursor/` — the two host tools this repository's own contributors run — that are full,
independently tracked copies of the `claude-code` and `cursor` profile renders respectively, verified
byte-identical to their `profiles/` counterparts. `.github/` at repo root carries no such mirror for this
directory (`git ls-files .github/aid/templates/graph/` returns nothing; `.github`'s 8 tracked files are
workflow/config, not a profile mirror), and no root-level `.codex/` or `.agent/` mirror exists at all
(confirmed: `ls -d .claude .cursor .github` on 2026-08-05 lists only three root dotdirs).

**This is stated as an extrapolation, labelled as such, not as a verified fact about the still-unbuilt
`knowledge-graph/` directory.** The dogfood-mirror mechanism is a repository-wide policy over
`canonical/aid/` (not a `graph/`-specific rule — the same three root dotdirs and the same absence of a
`.github` mirror hold for `shortcut-catalog.yml`, checked the same way), so it is reasonable to expect a
future `canonical/aid/templates/knowledge-graph/vendor/` to be mirrored the same way once feature-008
builds it and the dogfood sync step runs — but that has not happened yet and cannot be observed on disk
today. **The multiplier to use until that directory exists and is measured directly is therefore stated
as a range, not a corrected single number:** at minimum **6×** (if the vendor directory somehow does not
receive a root dogfood mirror), and **8×** if it mirrors the sibling directory's own measured pattern —
815,219 × 6 = **4,891,314 bytes** (≈ 4.665 MiB) at the low end, 815,219 × 8 = **6,521,752 bytes** (≈ 6.22
MiB) at the pattern-consistent figure. **feature-012, which owns the packaging wiring, is the party that
can and should re-run this exact `git ls-files` / `wc -c` / `diff` check once the vendor directory is
authored, and pin the number Stage 3 could only bound.**

### 3.4 The render-transform integrity verdict — AC-S10's other half

`render.py`'s `_TEXT_EXTENSIONS` frozenset (`.claude/skills/generate-profile/scripts/render.py:77–79`,
read 2026-08-05) is `{".md", ".txt", ".sh", ".ps1", ".mjs", ".js", ".html", ".css", ".py"}`. A vendored
`.js` file's suffix is in that set (`render.py:634`: `if src_file.suffix.lower() in _TEXT_EXTENSIONS:`),
so every one of the five files above is run through `substitute_filenames` then `rewrite_install_paths`
on its way into each profile render — this is a **verified property of the render pipeline**, not a
hypothetical.

Both transforms have a narrow, decidable trigger set: `rewrite_install_paths` rewrites literal
`canonical/{scripts,templates,skills,agents,recipes}/…` path references, and `substitute_filenames`
substitutes exactly three placeholder tokens, `{project_context_file}`, `{reviewer_output_file}`,
`{open_questions_file}`. Grepping the five actual downloaded bundles for every trigger, same date:

```
$ for f in d3-quadtree.min.js d3-dispatch.min.js d3-timer.min.js d3-force.min.js pixi.min.js; do
    grep -c "canonical/" "$f"; grep -c "{project_context_file}" "$f"
    grep -c "{reviewer_output_file}" "$f"; grep -c "{open_questions_file}" "$f"; grep -ci "mermaid" "$f"
  done
# every count for every file, every trigger: 0
```

**Verdict, at these exact versions: clean.** None of the five vendored files contains any string that
would trip either transform, so the vendored bytes survive `render.py`'s text transforms unchanged at
`d3-quadtree@3.0.1` / `d3-dispatch@3.0.1` / `d3-timer@3.0.1` / `d3-force@3.0.0` / `pixi.js@8.19.0`. The
zero-hit result also clears the `NM.1` inline-Mermaid-bundle heuristic
(`canonical/aid/scripts/summarize/validate-html-output.sh:280–314`: fires on an inline `<script>` block
over 100 KB whose content contains the token `mermaid`) regardless of packaging shape, since the token
is simply absent — though § 5 below still recommends the packaging shape that would make `NM.1` structurally
inapplicable even if a future version introduced the token.

**This verdict is not stable across a version bump, and the report says so rather than treating it as a
one-time fact.** A future PixiJS or D3-module release could introduce any of these five trigger strings
with no relationship to the rendering feature at all. § 7.4 and § 8 make re-running exactly this grep,
plus a byte-comparison against a fresh upstream download, a named step in the update procedure —
matching feature-012's own G6 condition, which this finding grounds.

---

## 4. Licence and attribution — AC-S11

Each licence below is read from the **upstream `LICENSE` file at the pinned version**, downloaded
verbatim on **2026-08-05**, not from a registry `license` field, a summary page, or this SPEC. The
registry `license` field is quoted too, and matches the file in both cases, but the file is the source
of record per D6's own instruction.

### 4.1 `d3-force`, `d3-quadtree`, `d3-dispatch`, `d3-timer` — ISC

`https://registry.npmjs.org/d3-force/latest` reports `"license": "ISC"`; the identical field appears for
the other three at their pinned versions. The upstream `LICENSE` file, identical text at all four
packages and all four pinned versions (`d3-force@3.0.0`, `d3-quadtree@3.0.1`, `d3-dispatch@3.0.1`,
`d3-timer@3.0.1`), fetched from `https://unpkg.com/<package>@<version>/LICENSE`:

```
Copyright 2010-2021 Mike Bostock

Permission to use, copy, modify, and/or distribute this software for any purpose
with or without fee is hereby granted, provided that the above copyright notice
and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.
```

This is the standard ISC licence text (a permissive licence functionally equivalent to the 2-clause
BSD/MIT family), copyright Mike Bostock, the D3 project's original author, 2010–2021. **Permissive; no
copyleft; no source-disclosure obligation; commercial and closed-source use permitted.**

**What ships inside the minified bundle itself, and what does not.** Each of the four minified files
opens with a one-line comment naming the project, version and copyright holder (verified on the actual
downloaded bytes, e.g. `d3-force.min.js`: `// https://d3js.org/d3-force/ v3.0.0 Copyright 2010-2021 Mike
Bostock`) — but **not** the full permission-notice paragraph the licence requires to "appear in all
copies." The one-line comment is attribution; it is not, by itself, the licence text ISC's own wording
asks to travel with the software.

### 4.2 PixiJS — MIT

`https://registry.npmjs.org/pixi.js/latest` reports `"license": "MIT"`. Upstream `LICENSE` at
`pixi.js@8.19.0`, fetched from `https://unpkg.com/pixi.js@8.19.0/LICENSE`:

```
The MIT License

Copyright (c) 2013-2023 Mathew Groves, Chad Engler

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

**Permissive; no copyleft; no source-disclosure obligation.** Copyright Mathew Groves and Chad Engler,
2013–2023 (the licence file's own copyright window; PixiJS's current maintainer organisation has
continued the project past 2023, but the shipped `LICENSE` file at this pinned version states this
window and that is what is quoted).

**What ships inside the minified bundle itself.** `pixi.min.js`'s header comment, read directly off the
downloaded bytes:

```
/*!
 * PixiJS - v8.19.0
 * Compiled Thu, 04 Jun 2026 08:22:17 UTC
 *
 * PixiJS is licensed under the MIT License.
 * http://www.opensource.org/licenses/mit-license
 */
```

This names the licence and links to its canonical text, but — like the D3 modules — does **not** carry
the copyright-holder names or the full permission/warranty paragraph MIT's own wording asks to be
"included in all copies or substantial portions."

### 4.3 The superseded record's D3 licence claim — checked, not carried forward

D6 flags, by name, that the superseded pre-redesign decision record's ISC claim for its vendored D3
modules was itself corrected during review, and instructs that "inputs to verify, not facts to copy" is
the right posture for every inherited licence claim. This document does not use or cite that superseded
record's number — the ISC finding above was re-derived from the upstream `LICENSE` files and the
registry `license` field independently, at the versions this document evaluates, and happens to agree
with what a correct ISC claim would say; agreement with a since-corrected document is not treated as
confirmation of it.

### 4.4 Where attribution should appear — the recommendation, and why

D6 requires naming the place, not just asserting that a place is needed. Four candidate places, and the
reasoning that rules out the two that are cheapest to reach for:

| Candidate | Verdict | Why |
|---|---|---|
| Rely on each bundle's own header comment | **Insufficient by itself** | Verified above: neither bundle's inline comment carries the copyright-holder name and the full permission notice; a one-line attribution is not the same instrument as "this permission notice…included" |
| Add the full notice as a new comment block inside the vendored `.js` files | **Not recommended** | The files are in `render.py`'s `_TEXT_EXTENSIONS` (§3.4) and the update procedure (§7–8) already re-fetches and byte-diffs them against upstream on every version bump; hand-editing a vendored bundle's bytes defeats that check's premise — the "vendored copy" would no longer be upstream's bytes, and every future integrity diff would report a permanent, expected mismatch that a real corruption could hide behind |
| A visible footer or about panel in `graph.html` | **Not recommended as the primary route** | Adds UI surface, a copywriting/i18n concern, and a place NFR-2's WCAG obligations now reach, none of which the licence itself requires; MIT/ISC ask for notice to travel *with copies of the software*, not for a user-facing credit line |
| **A companion `LICENSE` file placed beside each vendored bundle**, copied verbatim from the upstream package at the pinned version | **Recommended** | Satisfies "included in all copies" for both ISC and MIT directly and cheaply — no editing, no UI. And it is **structurally immune to the corruption risk in §3.4 and §8**: a file literally named `LICENSE` has no suffix, so `src_file.suffix.lower()` is the empty string, which is not a member of `_TEXT_EXTENSIONS` — verified against the same `render.py:634` logic already cited. It renders byte-identical to every profile, the same way `.yml` data files do, with nothing for `substitute_filenames` or `rewrite_install_paths` to touch |

**Recommendation:** one `LICENSE` file per vendored library (four identical ISC copies for the D3
modules — or one shared copy, since the text and copyright line are byte-identical across all four —
plus one MIT copy for PixiJS), placed in the same directory as that library's bundle, carrying the exact
upstream text quoted in § 4.1/4.2 verbatim. This is a packaging detail for feature-012 to wire; this
document supplies the text and the placement reasoning, not the file.

### 4.5 The combined-work question D6 raises, and why it resolves cleanly here

D6 names a question the pre-redesign record never had to ask, because the redistributed unit is now a
file generated into a **third party's** repository — an adopter's project — under this project's own
`LICENSE` (root, read 2026-08-05: MIT, "Copyright (c) 2026 AID Methodology Contributors"). D6's own
wording: "a permissive licence poses no problem [but] anything else is an owner decision rather than a
formality." Both § 4.1's finding (ISC, for all four D3 modules) and § 4.2's finding (MIT, for PixiJS) are
permissive, non-copyleft licences with no source-disclosure obligation and no requirement that the
combined work (this project's MIT-licensed generator output, carrying an ISC- and an MIT-licensed
third-party bundle) itself be relicensed or that its own source be disclosed. **So this is the
"permissive" case D6 names, not the "owner decision" case** — nothing about combining an MIT project with
ISC- and MIT-licensed dependencies constrains the licence this project ships `graph.html` and its
generator under. Had either library carried a copyleft licence (GPL-family, or a "weak copyleft" licence
with a distribution trigger), generating it into an adopter's own repository would have been exactly the
owner decision D6 flags — it is not, and the report says so on the evidence above rather than assuming it.

---

## 5. The packaging shape — stated so feature-011 and feature-012 can read their firing conditions off it directly

**Recommended shape:** all five files from § 2 vendored as local companion files (not inlined into
`graph.html`, not fetched from a CDN), loaded as classic `<script src="…">` tags in dependency order
(`d3-quadtree`, `d3-dispatch`, `d3-timer`, `d3-force`, then `pixi.min.js` — the first three must precede
`d3-force`; `pixi.min.js` has no ordering dependency on any of them per § 2), each accompanied by its
companion `LICENSE` file per § 4.4. No CDN reference anywhere in the delivered page. No bundler, no build
step: each file is the upstream distribution's own pre-built minified bundle, unedited.

**Why no CDN — a functional reason, not only a preference.** Two independent, verified facts both point
the same way:

1. `canonical/aid/scripts/summarize/validate-visuals.mjs`'s hermetic `page.route('**/*', …)` handler
   (read 2026-08-05, consistent with the SPEC's own D1 citation of the same lines) continues only
   `file://` requests and aborts everything else. A CDN-sourced script simply never loads under that
   gate — the graph would render *without its renderer* whenever the visual-fidelity harness runs it,
   which is the harness FR-12 commits this feature to reusing.
2. `validate-html-output.sh`'s **S2** check (`canonical/aid/scripts/summarize/validate-html-output.sh:252–264`,
   read 2026-08-05) fails only when it finds `<script src="https?://…">` or `<link href="https?://…">` in
   the output HTML. A companion-file reference such as `<script src="graph-assets/vendor/pixi.min.js">`
   is a relative path with no scheme, so it never matches that pattern.

**Consequence 1 — feature-011's S2 offline-render carve-out, stated so it can be read without
inferring.** Under this packaging shape, **S2 never fires against the graph's vendored scripts, because
no CDN reference exists in the packaging to trigger it.** feature-011's held-in-reserve carve-out for S2
is therefore a **recorded no-op** under this recommendation — the same shape D1b already found for the
`validate-visuals.mjs` T1–T4 canvas exemption (a `<canvas>` matches none of its three selectors). If a
future revision of this feature's packaging *does* introduce a CDN reference, S2's existing, unmodified
behaviour already fails the build; no carve-out is needed either way, and none is recommended.

**Consequence 2 — feature-012's D6 gate (G1–G7), mapped onto this document's findings.**
feature-012's own SPEC (`features/feature-012-canonical-registration/SPEC.md` § D6, read 2026-08-05,
consulted as the consumer of this research, not as a source this document treats as settled fact) states
seven packaging conditions. This document supplies the facts each one needs:

| Condition | What this document supplies |
|---|---|
| G1 — private, unpublished manifest under `canonical/aid/scripts/graph/` | Applies only if a manifest is created (§7 recommends one, for Dependabot); this document does not author it |
| G2 — exact pin + committed lockfile | The five exact versions in § 3.1's table |
| G3 — no install directory ships | Not this document's to verify; unaffected by anything found here |
| G4 — new `.github/dependabot.yml` entry for the manifest directory | § 7's mechanism recommendation and its directory target |
| G5 — licence text/SPDX id and required attribution travel with the asset | § 4's SPDX ids (`ISC`, `MIT`), verbatim licence texts, and the companion-`LICENSE`-file placement recommendation |
| G6 — integrity grep + byte-comparison against upstream, at vendor time and every version bump | § 3.4's clean grep result at the pinned versions, and § 8's naming of the procedure as a recurring step, not a one-time check |
| G7 — classic script (UMD/IIFE), not ES-module-only | § 2's confirmation: all five files are UMD/IIFE builds, verified from their own source bytes (the `!function(n,t){...}` / `var PIXI=(function(d){...}` wrapper patterns) |

This document does not decide G1–G7 — feature-012 owns that gate — but it removes every place in that
gate where "the report must state X" would otherwise be an open question.

---

## 6. D7 — the update-mechanism baseline, re-verified rather than carried forward

`.github/dependabot.yml`, read directly on **2026-08-05**:

```yaml
# Keeps the SHA-pinned GitHub Actions in .github/workflows/ current.
# Actions are pinned to immutable commit SHAs (with a `# vN` comment) for
# supply-chain safety; dependabot opens weekly PRs that bump those pins.
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "ci"
    groups:
      github-actions:
        patterns:
          - "*"
```

**Confirmed independently: exactly one ecosystem, `github-actions`, scoped to `/`.** Nothing in this
repository watches a JavaScript dependency today — not one declared in a manifest, not one pinned to a
CDN URL, not one vendored into a generated artifact. This is the verified floor § 7 compares every
candidate mechanism against.

**The one precedent that exists**, read the same date:
`canonical/aid/scripts/summarize/package.json` — `"private": true`, `"devDependencies": {"playwright":
"1.61.1"}`, `engines.node >= 20`, described in its own `description` field as tooling "Not shipped to
adopters" — with `package-lock.json` committed beside it. **But that description is aspirational, not
structural**: `canonical/aid/scripts/summarize/playwright-provisioning.md` § "Dependency isolation" (read
the same date, and independently confirmed by `git ls-files` against every profile) states, and this
document verified by listing tracked files, that both `package.json` and `package-lock.json` **do**
render into every one of the five profile install trees — `.claude/aid/scripts/summarize/package.json`,
`.cursor/…`, `.codex/…`, `.github/…`, `.agent/…` are all real, separately tracked copies. "Scoped" here
means scoped **by directory** (Dependabot only watches the directory a `dependabot.yml` entry names), not
withheld from what ships to an adopter. Any manifest this document's recommendation adds inherits the
same property, and § 7.1 states that plainly rather than implying privacy the manifest does not have.

---

## 7. D7 — comparing update mechanisms

Three candidate mechanisms, compared on what each one is a mechanism *for* — noticing that upstream
moved — because that is the question D7 states first and the one every named example in the SPEC (a new
Dependabot ecosystem entry, a scoped manifest, a CI check, a named human responsibility) addresses.

### 7.1 Candidate A — a scoped manifest + a new Dependabot `npm` ecosystem entry

**Mechanism.** Add a `package.json` under `canonical/aid/scripts/graph/` (the root feature-012's own G1
already fixes for any dev/validator manifest in this feature's area), `"private": true`, declaring the
five packages as pinned `dependencies` at the exact versions in § 3.1, with a `package-lock.json`
committed beside it — the same shape as the Playwright precedent in § 6. Add one new entry to
`.github/dependabot.yml`:

```yaml
  - package-ecosystem: "npm"
    directory: "/canonical/aid/scripts/graph"
    schedule:
      interval: "weekly"
```

**Party that acts.** Dependabot itself checks the npm registry against the manifest's pinned versions
and opens a PR when a newer release exists; a human (whoever triages Dependabot PRs in this repository
today, per the existing `github-actions` entry's own pattern) reviews and merges.

**What it is good at, and what it structurally cannot do.** It answers "has a newer version been
published" with no human having to remember to ask. It does **not** update the vendored bundle bytes
themselves — those are not `npm install`ed at runtime here, they are downloaded once and copied
statically into `canonical/aid/templates/knowledge-graph/vendor/`. A merged Dependabot PR only bumps the
version string in the manifest; re-vendoring the actual `.min.js` files, re-running § 3.4's integrity
grep, and re-checking § 4's licence text are manual follow-on steps the PR does not perform. Per § 6, the
manifest is scoped by directory, not private in the sense of withheld from adopters.

### 7.2 Candidate B — a named human responsibility, no automation

**Mechanism.** A recurring, calendared or backlog-tracked check ("review d3-force/PixiJS for a new
release quarterly"), assigned to a named maintainer role.

**Party that acts.** Whoever is assigned, on whatever cadence is set, if the reminder itself does not
lapse.

**Why this is the weakest of the three.** It formalises exactly the status quo this repository already
has for every JavaScript dependency (§ 6's verified baseline) and gives it a label rather than a forcing
function. Nothing detects a missed check; the failure mode is silent by construction, which is the
precise failure mode D7 exists to close.

### 7.3 Candidate C — a scheduled CI job that queries upstream directly

**Mechanism.** A new, separate GitHub Actions workflow (not a Dependabot entry) on a `schedule: cron`
trigger that runs `npm view <package> version` for each of the five packages, compares the result against
the pinned version recorded in the manifest, and opens an issue (or fails a non-blocking check) when they
differ; optionally, the same job re-downloads the **exact pinned** version's dist file and byte-compares
it against the checked-in vendored copy, which Candidate A cannot do at all.

**Party that acts.** CI raises the signal; a human still performs the re-vendor.

**Why it is not the recommendation.** It is strictly more capable than Candidate A on the "did the
shipped copy drift from the exact pinned upstream bytes" question — the corruption question § 3.4 and § 8
raise — because it operates on bytes, not on a manifest's version field. But it is new code this project
must author and maintain (a workflow file, its cron schedule, its own failure-notification path), where
Candidate A reuses a mechanism (`dependabot.yml`) and a manifest shape (§ 6's precedent) already present
and already trusted in this repository. Per D7's own steer — "two libraries in one manifest are covered
by one entry, so the cost here is small" — the marginal cost of Candidate A over doing nothing is one
manifest and one config entry; Candidate C's marginal cost is a new, bespoke script this project would be
solely responsible for keeping correct.

### 7.4 Recommendation, and the ongoing obligation it carries

**Recommended: Candidate A** (scoped manifest + Dependabot `npm` ecosystem entry), for the "who notices
upstream moved" question. It is the cheapest mechanism that is still a real mechanism rather than an
intention (ruling out Candidate B), and it reuses a shape this repository already runs and already
trusts (the `github-actions` Dependabot entry, and the Playwright manifest precedent), rather than adding
a bespoke script this project alone must maintain (ruling out Candidate C as the *primary* mechanism).

**The ongoing obligation this choice creates, stated rather than left implicit:** every Dependabot PR
against this manifest is *only* a version-bump notification. Merging it correctly requires a human to,
each time: re-download the new version's dist file(s), re-run § 3.4's integrity grep against the trigger
set, re-verify § 4's licence text and version number (a licence can change between major versions even
when a project's overall reputation does not), re-measure § 3's payload figures, and only then replace
the vendored bytes and update the pin. **Merging the manifest bump without redoing that work is the
single most likely way this mechanism's benefit is lost in practice** — the manifest would then claim a
version the vendored bytes do not match, which is a corruption of exactly the kind § 8 describes, just
introduced by the update process instead of by `render.py`. This is why Candidate C's byte-level check is
not discarded outright: § 8 recommends it as a **second, narrower mechanism** layered on top of
Candidate A rather than a replacement for it, because it is the only one of the three that can catch a
human skipping that follow-on work.

---

## 8. The second D7 question — who notices if the shipped copy stops equalling upstream

This is not "who notices a new release exists" (§ 7); it is "who notices the bytes already vendored have
silently diverged from what they claim to be" — and it has a distinct, verified mechanical cause, not
just a hypothetical one.

**The cause, verified on disk 2026-08-05.** `render.py`'s `_TEXT_EXTENSIONS` (§ 3.4) includes `.js`,
`.mjs`, `.html` and `.css`; every vendored file in § 2 is a `.js` file, so every one of them is run
through `substitute_filenames` and `rewrite_install_paths` on its way into each profile render. § 3.4's
grep found **zero** trigger hits at the currently-evaluated versions — clean today — but the check is a
property of *this version's bytes*, not a property that holds by construction. **The render-drift CI job
cannot see a consistent corruption**, because it diffs a fresh render against the committed render; a
bundle mangled the same way on every render matches itself perfectly. The only thing that can catch this
is a byte comparison against the **upstream** distribution at the pinned version — something outside the
render pipeline entirely.

**Who notices, under the recommended mechanism.** Under Candidate A alone: nobody, mechanically. Under
Candidate A plus the byte-comparison half of Candidate C, applied not as a separate scheduled job but as
a **step inside the update procedure** — run once at vendor time, and again every time the pinned version
changes — the answer becomes "the person executing that step, if the procedure is followed." This is not
this document's obligation to build; it is the finding this document owes and the reason feature-012's
own **G6** condition exists in the shape it does (integrity check "at vendor time and at every version
bump," not once). **This document supplies the check's method (§ 3.4's grep, plus a `diff` of the vendored
bytes against a fresh download at the pinned version) and its clean result at the currently-evaluated
versions; feature-012 owns wiring it into the documented procedure, and feature-013 owns the
`infrastructure.md` prose that states the procedure to a reader.**

---

## 9. Coverage — what this document discharges, and what it does not

| D10 part | Status |
|---|---|
| 10 — Payload at the delivered artifact and at all tracked copies, plus the render-transform integrity verdict | **Discharged.** § 3. One correction recorded against the SPEC's stated multiplier (§ 3.3: verified 8×-pattern on a sibling directory vs. the SPEC's stated 6×, bounded as a range pending the vendor directory's own construction) |
| 11 — Licence and attribution per library, exact version, upstream file, attribution location | **Discharged.** § 4 |
| 12 — The update mechanism, against the verified Dependabot baseline, both questions | **Discharged.** § 6, § 7, § 8 |
| 1–9, 13, 14, 16, 17 | **Not this document's.** Parts 1–3 (question/scope, Stage-1 probe, Stage-1 escalation) are `rendering-stage1-webgl-probe.md`'s, already delivered. Parts 4–9 (bench derivation, response surface, D4 measurands, frame-time predicate, settle time, ceiling), 13–14 (runtime prerequisites in prose, AC-21's route) and 16 (feature-008's size range) are Stage 2's, owed once feature-004's enumerator and feature-005's Pass 1a have run on a real repository — this document's findings do not depend on them and do not wait for them, per the SPEC's own "Stage 3 does not wait for Stage 1" framing extended here to Stage 2 as well |
| 15 — Drafted `technology-stack.md` / `infrastructure.md` content | **Not this document's.** Lands at ship time, by feature-013, per the SPEC's explicit "It does not write to the Knowledge Base" boundary |

**Acceptance-criteria self-check against this task's DETAIL.md:**

- Research document only; no product code, no vendored library placed on disk, no manifest edited — every
  library file this document discusses lives only in the scratch download used to measure it, never in
  this repository.
- Every D6 and D7 required part is present (§ 3–8); the one deferred part this document's own scope
  excludes (Stage 1/2's parts) names its owner in § 9.
- The packaging shape (§ 5) states feature-011's S2 firing condition (never fires, under the recommended
  shape) and feature-012's D6 gate mapping (§ 5, table) without either downstream feature needing to infer.
- Licence and attribution text is recorded verbatim (§ 4.1, § 4.2), with the exact evaluated version named
  for every one of the five files.
- No fixture was built or used; every figure traces to an upstream download or an on-disk command run on
  this repository's own permanent files, never to a work folder.
- **Sources cited, actionable recommendations stated** (§ 5, § 7.4, § 4.4) — RESEARCH type-defaults.
- **The "≥2 alternatives" override applied correctly:** D6 has no live alternative (the renderer pair is
  settled) and none is compared here. D7 compares **three** mechanisms (§ 7.1–7.3), not merely the
  required two, and § 7.4 states why the chosen one (Candidate A) carries the ongoing obligation it does —
  namely, that it notices a version exists without ever updating the bytes, which is why § 8 layers a
  second, narrower mechanism on top of it rather than treating Candidate A as sufficient alone.

---

## 10. Sources

All accessed **2026-08-05** unless a different read date is stated inline.

- `https://registry.npmjs.org/d3-force/latest` — version `3.0.0`, licence field `ISC`
- `https://registry.npmjs.org/pixi.js/latest` — version `8.19.0`, licence field `MIT`
- `https://registry.npmjs.org/d3-quadtree`, `.../d3-dispatch`, `.../d3-timer` — dist-tags and full 3.x
  version lists (each: `3.0.0`, `3.0.1`; latest `3.0.1`)
- `https://unpkg.com/d3-force@3.0.0/package.json` — dependency list (`d3-quadtree`, `d3-dispatch`,
  `d3-timer`)
- `https://unpkg.com/d3-force@3.0.0/dist/d3-force.min.js`,
  `https://unpkg.com/d3-quadtree@3.0.1/dist/d3-quadtree.min.js`,
  `https://unpkg.com/d3-dispatch@3.0.1/dist/d3-dispatch.min.js`,
  `https://unpkg.com/d3-timer@3.0.1/dist/d3-timer.min.js`,
  `https://unpkg.com/pixi.js@8.19.0/dist/pixi.min.js` — downloaded verbatim; `wc -c` measured;
  `require(` count checked; UMD/IIFE header bytes inspected directly
- `https://unpkg.com/d3-force@3.0.0/LICENSE` (and the same path for `d3-quadtree@3.0.1`,
  `d3-dispatch@3.0.1`, `d3-timer@3.0.1` — byte-identical text, verified) — ISC licence text, quoted in § 4.1
- `https://unpkg.com/pixi.js@8.19.0/LICENSE` — MIT licence text, quoted in § 4.2
- `canonical/aid/scripts/summarize/validate-html-output.sh:252–264` (S2), `:280–314` (NM.1) — this
  repository, read on disk
- `canonical/aid/scripts/summarize/validate-visuals.mjs` — hermetic `page.route` handler (`file://`-only),
  consistent with the citation already on record in `rendering-stage1-webgl-probe.md`, this feature's own
  Stage-1 deliverable, re-confirmed present
- `.claude/skills/generate-profile/scripts/render.py:77–79,634` — `_TEXT_EXTENSIONS` and the suffix check
  that gates the text-transform, read on disk
- `.github/dependabot.yml` — read on disk, quoted verbatim in § 6
- `canonical/aid/scripts/summarize/package.json`, `canonical/aid/scripts/summarize/playwright-provisioning.md`
  § "Dependency isolation" — read on disk, and the "renders into every profile" claim independently
  confirmed via `git ls-files` against all five `profiles/*/` trees
- Root `LICENSE` — this project's own MIT terms, first five lines read, for § header context (the
  redistributed vendor files land inside a project already under a permissive licence of its own)
- `git ls-files`, `wc -c`, `diff -rq`, `git check-ignore` against `canonical/aid/templates/graph/`,
  `.claude/aid/templates/graph/`, `.cursor/aid/templates/graph/`, `.github/aid/templates/graph/`, and the
  five `profiles/*/` trees — run on disk, this repository, HEAD `02be5296`, § 3.3
- `features/feature-008-interactive-graph-canvas/SPEC.md` § External Integrations, § Feature Flow step 2
  — consulted for the classic-script/global consumption shape this document's payload figures depend on
  (a design decision owned by feature-008, not restated as this document's own finding)
- `features/feature-012-canonical-registration/SPEC.md` § D6 (G1–G7) — consulted as the downstream
  consumer this document's findings feed, per § 5; not cited as a source of the facts themselves

---

## 11. What this document does not determine

- **The exact repository-side payload multiplier** (§ 3.3) is bounded (6×–8×) rather than pinned, because
  the vendor directory this multiplier applies to does not exist on disk yet. Whoever authors it
  (feature-012, at wiring time) should re-run the § 3.3 commands against the real directory rather than
  use either bound as a final figure.
- **Whether Dependabot's `npm` ecosystem entry actually opens a working PR against a `private: true`
  manifest with no corresponding `node_modules` install** was not tested end-to-end (that would require
  landing the manifest and waiting for Dependabot's next scheduled run, which is out of scope for a
  RESEARCH task that authors no manifest) — the recommendation in § 7.1 rests on the manifest shape,
  which is a documented, working Dependabot pattern in general, not on having observed this exact
  manifest trigger a PR in this repository.
- **Whether a future PixiJS or D3-module release changes licence terms.** Both are currently permissive
  and both projects have used the same licence for their entire public history to date; this document
  makes no claim about future releases beyond naming, in § 7–8, the mechanism by which a licence change
  would eventually surface.
- **The precise reason only `.claude/` and `.cursor/` (and not `.codex/`, `.agent/`, or `.github/`) carry
  root-level dogfood mirrors** was not investigated — it is orthogonal to this task's D6/D7 scope and is
  noted only because it bears on § 3.3's multiplier.
