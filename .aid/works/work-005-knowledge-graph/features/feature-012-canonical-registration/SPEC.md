# Canonical Registration And Count Reconciliation

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-31 | **Fix pass 4** — gate D+, row 12 `[HIGH]` and row 13 `[LOW]`, both mechanism (rows 3–5 and 9–11 and 14–16 are LOW/MINOR editorial and stay Pending per Q26). **Row 12:** pass 3 replaced a false "the gates own the edit set" with a hand sweep that was *itself* phrasing-keyed — a fixed set of shapes — and the gate found live lines inside the gate's own corpus matching none of them, including the very line cycle 4's Evidence had named alongside one the fix did recover. Adding another shape would only have produced another escaping line, so the mechanism is replaced rather than widened: the sweep is now keyed on **values**. Its needles are the pre-landing values of every `deriveSkillCounts` field whose value this landing moves, obtained by diffing `--list` before and after; its corpus is the gate's own walk, de-emphasised as the gate de-emphasises it; and a history-shaped line is now **read** rather than skipped by shape, since the script itself records that shape as evadable. A value-keyed rule is exhaustive by construction — a surface stating an old value contains that value, and no noun, operator, emphasis run or line wrap can hold it outside the needle — so the SPEC now carries a termination argument instead of a coverage claim. False positives are accepted and the asymmetry is stated as the justification. The over-claiming sites row 12 named — Class 1's heading, the Description, CR08 and § Figures — plus AC-R5, CR10, Flow step 9, L1's sweep row, L3's 012/013 row and the CR08 and CR10 rows in § Tests are all restated as what the sweep decides; D4's opening "exactly one derived quantity moves" is corrected with them, since it is the same under-description one level up. L3 now closes ownership as a partition — inside the corpus 012's, outside it Open Item 3's, and a stale claim carrying no value at all is prose and 013's. Open Item 7 is broadened past decomposition operands and carries three grades of evidence. **Row 13:** the third gate does check values — `CLAIM_PATTERNS` over `CLAIM_PAGES`, with a **bare** `curated` shape where `check-skill-counts.mjs` is lookahead-guarded — so it gates a phrasing the other two cannot; the "forbids a count rather than checking a value" description is corrected, since AC-R6's third disjunct turns on it. Also restored: § Technical Specification's post-merge citation-scope disclosure, deleted in pass 3, `git log --merges` confirming none has landed since. Paid for by folding the regex detail into Open Item 7 rather than stating it twice | /aid-specify |
| 2026-07-30 | **Fix pass 3** — gate D+, rows 7–8 only (rows 9–11 are MINOR/MINOR/MINOR editorial and stay Pending per Q26's mechanism/editorial split). **Row 7:** D4 Class 1 claimed the gates decide the edit set. They do not — they decide *phrasings*. Read first-hand in `check-skill-counts.mjs`: `CLAIMS` `:96`/`:97` cannot match a `curated` operand followed by `(` or `+`, and `:108–111` have no pattern for the bare phrase `catalog rows`, so a decomposition's total is checked while its parts are not; replaying the file's own `CLAIMS` array over `generate-profile/SKILL.md:106–112` shows exactly that. Class 1 now states what the gates decide and what they miss, corrects "both" to three gates, and defines a **hand sweep** over the gate's own corpus whose oracle is the derivation itself, not arithmetic — summing alone would miss a lone operand on a line carrying no total (CR08). The `:435` "repo-wide" claim is retracted against the script's NOT-YET-SCANNED comment, quoted verbatim. Open Item 3 is **restored and re-scoped** — dead body, live title — and a new **Open Item 7** routes the regex gaps to the work owner as a live repository defect, keeping first-hand evidence and cycle-4-reported evidence explicitly apart. The same false framing was swept out of AC-R5, the Description, CR10, L1, L3's 012/013 row, the Tests table and § Figures. **Row 8:** L1's build-output row now enumerates the tracked artifacts the mandated site generators write, resolved from their `writeFileSync` calls, with Flow step 9's `git status -- site/` as the partition's only oracle. Paid for by deleting merge/draft retrospection the Change Log already carries (Class 3, Class 2's intro, the Source re-read note, § External Integrations' meta-paragraph). The "repo-wide count gate" wording in the row below is superseded by this row | /aid-specify |
| 2026-07-30 | **Fix pass 2** — gate C, row 6 only (rows 3–5 stay Pending per Q27), **plus a post-merge citation re-verification of the whole document**. **Row 6:** row 2's class, one scope out. D1's amendment clause quantifies over *other* features' Layers sections, so it structurally could not reach the already-registered canonical file this feature itself amends — `generated-files.txt`, transformed class, `check-attr` → `text: unspecified`. Fixed at the quantifier rather than the symptom: CR07 now ranges over D1 **∪** L1's `canonical/` paths, D1 and D5 state the seam, M1 adds the path rule, and Open Item 5's residual is restated as the complement of `.gitattributes`'s extension list (it had omitted `.txt`, `.json` and `.ps1`). The same-class conditional residual is closed by pinning G1/G2's `.json` manifest and lockfile under `canonical/aid/scripts/graph/`, a root M1 already covers. **Re-verification:** `origin/master` merged mid-gate (PR #174). Every citation into the twelve moved files re-resolved **by text, not by offset**, and each argument resting on them re-read — `tech-debt.md` L4 is still open and both anchors still say what was claimed. The merge also moved the site's roster out of `gen-reference.mjs` into `skills/curated-roster.mjs`, added a third roster (`groups.mjs` `CURATED_GROUPS`) and a repo-wide count gate (`check-skill-counts.mjs`), and re-anchored the comments D4 Class 3 existed to fix: Class 2 re-derived on disk, Class 3 recorded as discharged, CR09 repointed at the merged **set-equality clamp**, CR10 given its first machine oracle, and Open Item 3 **withdrawn** — its premise no longer holds. The re-verification is what makes this pass **+44** lines rather than the near-zero a numbers-only correction would have cost; the D4 rewrite is the bulk of it | /aid-specify |
| 2026-07-30 | **Fix pass 1** — gate D+, rows 1–2 only (rows 3–5 are LOW/LOW/MINOR and stay Pending per Q27). **Row 1:** D3's trigger set and its UTF-8 exemption were derived over `render.py`'s `translate="none"` branch alone and applied to all four D1 roots. Re-derived **per root** by tracing a production file down each path: `canonical/skills/` goes through `translate="skills"`, which adds two `SKILL.md`-only frontmatter triggers (`allowed-tools:` remap, `context:`/`agent:` deletion), consults no extension frozenset, and has **no** UTF-8 fallback — invalid UTF-8 there aborts the generator instead of degrading to a copy. AC-R3, CR02, CR06 and the legitimate-versus-defect table scoped with it; the comment exemption restated as its real predicate (first non-whitespace `#`, so `.md` and `.ps1` too) instead of an extension list. **Row 2:** D1 had been swept for new-file declarations only, so feature-004's two amendment declarations were missing — added as **amendment** rows, CR01 extended to both declaration kinds, and `settings.yml` given its own `.gitattributes` rule as the one D1 path the path-scoped fix did not reach. Net **+15** lines | /aid-specify |
| 2026-07-30 | **Authored fresh** against the amended REQUIREMENTS, the frozen 001–007 spine and the passed 008/009, per STATE.md **Q26 § Fresh authoring**. Supersedes the 2026-07-28 pre-decision draft entirely; that draft was opened once as a checklist of concerns and used as a base document nowhere. Three of its claims are **not carried forward because they are false on disk**: it attributed the install-manifest lockstep hazard to `tech-debt.md` item **L4** (L4 is the test-effectiveness gap; the manifest incident is *evidence inside* L4), it cited two registration acceptance criteria in REQUIREMENTS §9 (§9 contains none — the obligation is **C-2**/**C-3**), and it said the full generator renders the dogfood `.claude/` tree (it renders `profiles/` only) | /aid-specify |

## Source

- **REQUIREMENTS.md `:776–777` (C-2)** — the skill is authored in the canonical tree and rendered to
  every host profile by the existing profile renderer; it must not be hand-maintained per profile.
- **REQUIREMENTS.md `:778–779` (C-3)** — adding a skill touches the install and emission manifests,
  which the Knowledge Base already flags as lockstep hazards; the change must keep them consistent.
- **REQUIREMENTS.md `:704–705`** — §5.9's *Decision — separate skill, shared scripts* accepts the cost:
  "one more skill in the canonical→profiles render and the install manifests."
- **REQUIREMENTS.md `:664–671` (FR-32)** and **`:902–906` (AC-5)** — consumed as a **boundary**, not as
  this feature's obligation. Their byte-identity is a **runtime** guarantee about `relationships.md`
  across `/aid-graph` runs with **all of FR-11's staleness inputs unchanged**. The byte-identity this
  feature owns is the **render's** (D3). Conflating the two would be a proxy defect of exactly the class
  STATE.md Q17 flags, so the two are named separately everywhere below.
- **REQUIREMENTS.md `:174` (§4 Out of Scope)** — enumerating generated/derived trees; the rendered
  `profiles/` and dogfood `.claude/` trees are build output, never sources.

### Inbound obligations routed to this feature

Every row was verified in the routing SPEC this session. These are the feature's mandate; nothing here
is self-assigned.

| From | Where | Obligation |
|---|---|---|
| feature-001 | SPEC.md`:1515` | `profiles/*/emission-manifest.jsonl` — one record per profile for the canonical vocabulary file, produced by running the full generator, never hand-edited |
| feature-002 | SPEC.md`:1099` | The install and emission manifests account for the added file set; run the **full** generator so the manifests and the render-drift gate stay green |
| feature-002 | SPEC.md`:1096` | `.github/dependabot.yml` plus a scoped manifest, if a dependency is adopted |
| feature-002 | Open Item 9, SPEC.md`:1273–1279` | A vendored bundle is text-transformed into every profile and **the render-drift gate cannot detect the corruption**; the integrity check belongs in the update procedure, not as a one-time observation |
| feature-002 | Open Item 10, SPEC.md`:1280–1285` | The repository-side payload figure — a canonical file plus one render per profile — is a packaging judgment |
| feature-003 | Open Item 10, SPEC.md`:1970–1974` | Generated-file registry placement for `relationships.md` |
| feature-006 | SPEC.md`:1152`, ownership at `:1154` | Migration step 5 — run the FULL profile generator, then confirm no render drift |
| feature-007 | SPEC.md`:1603` | The vendored bundles must be classic scripts, not ES modules — a constraint on the bundle this feature wires |
| feature-007 | SPEC.md`:1596–1598` | Whether the bundle is inlined or referenced as a companion file is this feature's choice, and it decides whether `NM.1`'s token condition becomes live |
| feature-008 | § External Integrations — its "Licence, attribution, payload, update mechanism" and "Bundle integrity under the profile render" rows | Both are landed here, not there. **Cited by section and row name, never by line: that SPEC is being edited concurrently** |

### Knowledge-Base grounding

- `.aid/knowledge/module-map.md` `:310–316` (where a new skill goes), `:321–324` (where a new helper
  script goes), `:325–327` (how a new generated file is registered), `:337–338` and `:346–348` (never
  edit a rendered copy; every shipped file originates in `canonical/`).
- `.aid/knowledge/infrastructure.md` `:84–98` (the render is the build; the drift gate) and `:303`
  (the render-parity command this feature is measured by).
- `.aid/knowledge/tech-debt.md` `:350–353` Gotchas — render-drift needs the **FULL** generator, not a
  per-script renderer, or the gate fails on stale `profiles/` emission manifests.
- `.aid/knowledge/tech-debt.md` `:173–175` and `:233–235` — the `io_bounds.py` incident (several
  surfaces asserting each other while all were wrong) and the invariant-anchoring rule it produced:
  *anchor to ground truth, not a sibling copy*. That rule is this feature's design principle.
- `.aid/knowledge/technology-stack.md` `:217–218` — both published wrappers declare empty dependency
  sets, "so install is fast and supply-chain-light". That invariant must survive any adoption.

### Dependency position

Wiring, not behaviour. Nothing here changes what any skill does at runtime; the blast radius is the
generated trees plus the hand-written surfaces L1 enumerates. It cannot land before the artifacts it
registers exist, and every other feature's delivery is incomplete until it has run.

## Description

Everything this work produces has to become a **registered, rendered, counted** part of the repository
rather than a pile of new files. Three obligations, plus a fourth that arrives conditionally.

**The emission machinery is enumeration-based, not declaration-based.** There is no per-file or
per-skill list to append to. The generator walks the canonical tree and the skill directories and emits
what it finds. So "declared where the emission machinery can see them" does not mean *adding a
declaration* — it means each artifact **satisfying the enumeration predicates**, because a file that
fails one is silently omitted with no error anywhere. Those predicates are the real hazard, and they are
where this feature does its work.

**"No render drift" is the wrong assertion to lead with.** The documented check re-renders and diffs
`profiles/`. A file the generator never emitted produces no diff, no manifest record and no failure — so
the check passes hardest in exactly the case where nothing shipped. Every assertion below therefore pins
**presence** first and asserts **absence of change** second, in that order and never the reverse.

**Counts are the third obligation and the one this work has a scar on.** Landing a curated skill
directory moves more than one derived quantity, and several hand-written surfaces mirror them. The
discipline is `tech-debt.md`'s
invariant-anchoring rule — anchor to ground truth, never to a sibling copy — applied to this SPEC's own
prose as much as to the surfaces it edits: no count of an externally-owned set appears anywhere below,
only the derivation, the gates that decide phrasings, and the value sweep that closes their corpus.

The fourth job is conditional. If the rendering architecture ships third-party code, its packaging,
pinning, licensing, monitoring and **integrity under the render's text transforms** all land here. That
last one is not hypothetical: a bundle in a text-transformed extension is rewritten on its way into every
profile, and the drift gate is structurally blind to it.

## User Stories

- As a **maintainer/architect**, I want every new canonical artifact to be emitted into every host
  profile by the existing generator, so no profile drifts and no rendered copy is ever hand-maintained.
- As a **maintainer/architect**, I want the render verified by *presence then stability*, so a file that
  was silently never emitted fails the check instead of passing it.
- As a **maintainer/architect**, I want each artifact's byte-identity guarantee stated per render class,
  so I can tell a legitimate render difference from a corruption.
- As a **maintainer/architect**, I want every count and roster surface reconciled against ground truth
  rather than against a sibling literal, so adding the next skill does not require hunting numbers.
- As a **newcomer to the project**, I want the stated number of skills to match the number that exists,
  so I can trust the documentation I am reading.
- As the **AID methodology owner**, I want any third-party bundle private, pinned, monitored,
  licence-recorded and integrity-checked at every version bump, so the published wrappers keep their
  empty dependency sets and a silently mangled copy cannot ship.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-R1** Given the work's canonical artifacts on disk, when the full generator has run, then each
      artifact appears as an emission-manifest record in **every** profile the generator enumerates, with
      a `sha256` matching the bytes at its `dst`, and no artifact is silently omitted.
- [ ] **AC-R2** Given a completed render, when render parity is checked, then `profiles/` carries neither
      a tracked modification nor an untracked addition — and this is asserted only **after** AC-R1 holds.
- [ ] **AC-R3** Given each artifact's **root** and extension, when its render class and trigger set are
      read off the code path that root actually takes, then that class's byte-identity guarantee holds in
      every profile, and a difference outside **that root's** permitted causes is a defect, not a render.
- [ ] **AC-R4** Given the repo-root dogfood tree, when the dogfood byte-identity guard runs after the
      render and resync, then every generator-owned path added by this work is present in it and matches
      the manifest.
- [ ] **AC-R5** Given the new skill directory on disk, when the doc-count guard, the stated-count gate
      and the site generators and their tests run, then each passes, **and** the value sweep D4 Class 1
      defines leaves no live line in that gate's corpus still stating a moved quantity's pre-landing
      value — the directory's existence being a precondition, so a run without it fails not passes.
- [ ] **AC-R6** Given any count or roster surface this feature edits, when it is reviewed, then it is
      machine-gated against a derivation from ground truth, or names the derivation instead of a number,
      or — for a numeral no gate's patterns can match — is reconciled against that same derivation by
      D4 Class 1's value sweep and recorded as ungated; no hardcoded total of an externally-owned set is
      introduced or incremented.
- [ ] **AC-R7** Given the generated-file registry, when it is read after this feature lands, then it
      states the disposition of `/aid-graph`'s outputs and the rule behind it, rather than leaving the
      question open for a later feature to re-ask — and carries no data line for either output.
- [ ] **AC-R8** Given a third-party bundle, if one is adopted, when its packaging is reviewed, then every
      condition D6 declares applicable to the chosen packaging holds — exactly pinned, absent from both
      published wrapper manifests, licence-recorded, loadable as a classic script, and cleared by the
      render-transform integrity check unconditionally; private, dependency-watched and lockfiled if the
      packaging carries a manifest — with the integrity check recorded as a step in the update procedure
      rather than as a one-time observation.

---

## Technical Specification

> **Assertion prefix: `CR*`** (canonical registration), verified unused across REQUIREMENTS.md,
> STATE.md and every sibling SPEC. Siblings use `GV*` (007), `GC*` (008), `TV*` (009), `GL*` (006),
> `V*`/`AC-S*` (003) and `GR*` (013).
>
> **A citation convention this section obeys, from STATE.md Q23.** `canonical/` and its profile renders
> are different artifacts, so every artifact path below is the `canonical/` one. The **one** exception is
> the generator itself: `generate-profile` is the lone skill with no canonical original — it lives only
> at `.claude/skills/generate-profile/` (`.aid/knowledge/infrastructure.md:89–90`, "maintainer-only, the
> lone skill outside `canonical/`") — so `render.py`, `render_lib.py` and `run_generator.py` are cited
> there because there is nowhere else to cite them.
>
> Grounded in `.claude/skills/generate-profile/scripts/{run_generator,render,render_lib}.py`,
> `canonical/EMISSION-MANIFEST.md`, `canonical/aid/templates/generated-files.txt`, `.gitattributes`,
> `tests/canonical/{test-doc-counts,test-skill-counts,test-dogfood-byte-identity,test-ascii-only}.sh`
> and `tests/canonical/check-skill-counts.mjs`, `tests/run-all.sh`,
> `site/scripts/{gen-reference,gen-skills}.mjs` + their `__tests__` mirrors and
> `site/scripts/skills/{curated-roster,groups,skill-counts,paths}.mjs`, `lib/aid-install-core.sh`,
> `packages/{npm,pypi}/scripts/vendor.{js,py}`, `.github/{dependabot.yml,workflows/test.yml}`, and the
> KB docs named in § Source. **Every line citation below was re-read on disk *after* the
> `origin/master` merge**, not before it, and `git log --merges` shows none landed since.

### Data Model

#### D1 — The registration inventory

**The derivation is authoritative; the table is a snapshot of it verified this session.** It has **two
kinds of row**, and sweeping for one is what leaves the other short. **New** rows: every canonical path a
**gated** SPEC's Layers & Components section declares under a root this work introduces —
`canonical/aid/templates/graph/`, `canonical/aid/templates/knowledge-graph/`,
`canonical/aid/scripts/graph/`, `canonical/skills/aid-graph/`. **Amendment** rows: every
already-registered canonical file such a section declares it **amends and owns** — already emitted, so the
obligation is render, parity and line endings, never a new registration; one routed to a **non-gated**
owner is Open Item 2's. A reader re-derives both kinds from those sections, not from the rows below.
**Both quantifiers range over *other* features' sections, so neither reaches a canonical file this
feature itself amends** — `generated-files.txt` (D5) is an **L1** row, not a D1 row. L1's canonical edit
list is the strictly larger set, which is why CR07 is written against both; D1 alone leaves it uncovered.

**Render class is not a choice, and the rule deciding it is per-root.** Under the three `canonical/aid/`
roots it follows from the extension against `render.py:77–79`'s `_TEXT_EXTENSIONS` frozenset — `.md`,
`.txt`, `.sh`, `.ps1`, `.mjs`, `.js`, `.html`, `.css`, `.py`, and **not** `.yml`: a member is
text-transformed (`render.py:634–639`), a non-member copied byte-for-byte (`render.py:643`). Under
`canonical/skills/` it is **never consulted** — `SKILL.md` and `references/*.md` transform
unconditionally (`render.py:553–592`), a `scripts/` child is verbatim (`render.py:600`). D3 is per-root.

| Path | Class | Declared by |
|---|---|---|
| `canonical/aid/templates/graph/relationship-schema.yml` | verbatim | feature-003 SPEC.md`:1872` |
| `canonical/aid/templates/graph/relation-vocabulary.yml` | verbatim | feature-003 SPEC.md`:1873`; content owned by feature-001 (SPEC.md`:1058–1060`) |
| `canonical/aid/templates/graph/coverage-bearing.yml` | verbatim | feature-006 SPEC.md`:1096` |
| `canonical/aid/templates/graph/edge-relation-map.yml` | verbatim | feature-005 SPEC.md`:1460` |
| `canonical/aid/templates/knowledge-graph/*` — the template set named in feature-007's file tree | transformed (`.html`, `.css`, `.js`, `.md`) | feature-007 SPEC.md`:1540–1548` |
| `canonical/aid/scripts/graph/coverage-predicate.mjs` | transformed | feature-007 SPEC.md`:1551` |
| `canonical/aid/scripts/graph/detect-kb-gaps.mjs` | transformed | feature-006 SPEC.md`:980` |
| `canonical/aid/scripts/graph/relationship-schema.sh`, `validate-relationships.sh` | transformed | feature-003 SPEC.md`:1875`, `:1876` |
| `canonical/aid/scripts/graph/scan-source.sh`, `significance-rules.sh` | transformed | feature-004 SPEC.md`:2061`, `:2062` |
| `canonical/aid/scripts/graph/harvest-declared.sh`, `derive-edges.sh`, `build-relationships.sh`, `report-endpoint-satisfiability.sh` | transformed | feature-005 SPEC.md`:1456–1459` |
| `canonical/skills/aid-graph/` — `SKILL.md` plus its `references/*.md` state files | transformed | REQUIREMENTS.md`:333–335` (FR-7 names the skill) + `module-map.md:310–316` (where a new skill goes). **Not** cited to feature-010, whose SPEC is still the pre-decision draft |
| `canonical/aid/templates/reviewer-ledger-schema.md`, `canonical/aid/templates/kb-authoring/frontmatter-schema.md` | transformed; **amendment** | feature-006 SPEC.md`:1095`, `:1096` — amendments to existing files, so no new registration, but they are canonical edits and therefore inside the full-generator obligation (feature-006 SPEC.md`:1089–1091` says so) |
| `canonical/aid/scripts/config/read-setting.sh` | transformed; **amendment** | feature-004 SPEC.md`:2064` — gains `--probe`, and that row marks it owned and implemented by feature-004. Already emitted (`canonical/scripts/config/read-setting.sh` is a manifest `src` today), so no new registration; the existing `*.sh` rule already carries `text eol=lf`, so CR07 holds for it unchanged |
| `canonical/aid/templates/settings.yml` | verbatim; **amendment** | feature-004 SPEC.md`:2065` — seeds the `graph:` section with a commented-out `ignore:` list. **The only D1 path reached by neither an existing extension rule nor the four root rules** (`git check-attr text eol` → `text: unspecified`) — L1's `generated-files.txt` is the other such file, outside D1 by the rule above — and verbatim class, so a CRLF amendment would ship to every profile and adopter with a clean diff. M1 gives it its own rule; no tracked `.yml` in the repository carries a CR byte today, verified, so that rule renormalises nothing |

**One artifact is on disk today and is the live proof this feature is needed.**
`canonical/aid/templates/graph/relation-vocabulary.yml` is **committed** (`git log` → `3fc7cdb4`) and is
present in **no** profile tree, **no** emission manifest and **not** in the dogfood tree — verified this
session. The repository is therefore in render drift right now. That matters twice: it makes CR05 a real
check rather than a formality, and it is the shape a reviewer should expect from every subsequent
artifact until this feature runs.

**No marker or manifest file accompanies the template set.** feature-006 SPEC.md`:1083–1085` withdrew the
`knowledge-graph/package.json` ESM marker with the `.mjs` repoint. Reinstating one would be actively
harmful here: a `package.json` inside a *template* directory renders into every profile and lands a stray
manifest in every adopter's install where their own tooling could read it.

> **CR01.** Both derivation kinds are complete: every canonical path a gated SPEC's Layers section
> declares under the roots named above, **and** every already-registered canonical file such a section
> declares it amends and owns, appears in D1 with a render class and a citation resolving to that
> declaration; every D1 row carries such a citation. Decided by re-deriving **both** sets against D1's.
>
> **CR02.** For a D1 row under a `canonical/aid/` root, the declared class is `verbatim` **iff** the
> path's extension is absent from `render.py:77–79`'s `_TEXT_EXTENSIONS`; for the `canonical/skills/` row
> that frozenset does not decide, and `transformed` follows from `render.py:553–592` instead.

#### D2 — What the emission machinery can and cannot see

C-3 calls the manifests a lockstep hazard. Reading the generator narrows that to something both smaller
and sharper, and the narrowing decides what `/aid-detail` has to schedule.

**Nothing needs declaring.** Verified:

| Surface | Why it self-tracks |
|---|---|
| `profiles/*/emission-manifest.jsonl` | `run_generator.py:40–41,63` builds a fresh manifest per profile on every run and writes it; there is no incremental path and no per-file list |
| `canonical/EMISSION-MANIFEST.md` § Asset Kinds (`:111–116`) | Maps directories wholesale — `canonical/aid/scripts/` and `canonical/aid/templates/` as single rows, and `canonical/skills/` as one. A new **subdirectory** under any of them needs no row, so this document takes **no edit** |
| The install trees | `render.py:611–668` (`translate="none"`) walks `canonical/aid/` with `rglob("*")`; `render.py:536–609` (`translate="skills"`) enumerates skill directories with `iterdir()` |
| `.aid/.aid-manifest.json` and the installer | `lib/aid-install-core.sh:1821–1834` (`_prune_aid_subtree`) and `:1858–1883` (`_prune_native_dir`) walk whole directories against the install-time manifest; neither holds a per-skill or per-file list |
| `packages/npm/_vendor/`, `packages/pypi/.../_vendor/` | **Not a copy of canonical content.** `packages/npm/scripts/vendor.js:71` vendors `bin`, `lib`, `dashboard/reader`, `dashboard/server`; `packages/pypi/scripts/vendor.py:46–53` vendors `bin/*`, `lib/*`, `VERSION` plus the `dashboard/MANIFEST`-derived set. Neither reaches `canonical/`, so **no packaging surface here is a registration surface for this work** |
| `tests/run-all.sh:112` | `suites=( tests/canonical/test-*.sh )` — suite discovery is a glob, so a new suite needs no runner or workflow edit. Registration affects discovery **not at all**; the suites themselves are feature-013's |
| `site/src/content/docs/reference/skills.md` intro | `gen-reference.mjs:265` composes it from `onDisk.length`, read at `:240–243` from the skill directories, so the number is data-driven |

**What the machinery silently drops.** This is the actual hazard, and every clause is a verified
predicate whose failure produces no error, no manifest record and no shipped file:

| # | Predicate | Line | Consequence of failing it |
|---|---|---|---|
| P1 | A file under `canonical/aid/` must not have a dot-prefixed basename | `render.py:625` (`not f.name.startswith(".")`) | Silently not emitted |
| P2 | No path component may be `node_modules` or `.git` | `render.py:620,626` | Silently not emitted — and this is the guarantee that a vendor install directory never ships |
| P3 | A skill directory must contain `SKILL.md` | `render.py:549–551` | `FileNotFoundError` — the **only** loud failure in the set; the generator exits non-zero |
| P4 | A skill's reference files must end `.md` and sit directly in `references/` | `render.py:579` (`ref_dir.glob("*.md")`) | Silently not emitted |
| P5 | A file under a skill's `scripts/` must be a direct child | `render.py:596–599` (`iterdir()` + `is_file()`) | A nested subdirectory is silently not emitted. Unexercised today — no canonical skill ships a `scripts/` directory — so a first user of the branch gets no warning |
| P6 | The whole `canonical/aid/` walk is a single tree walk, so a new directory needs no wiring | `render.py:728–729` | — (stated so the inventory is not padded with imagined wiring) |

> **CR03.** Every D1 path satisfies P1, P2, P4 and P5, and every skill directory in D1 satisfies P3.
> Decided per path against the cited lines. **Non-vacuous only in conjunction with CR01**, which
> guarantees the quantified set is non-empty; stated here so the dependency is not left implicit.

#### D3 — Byte-identity, per render class and per root

The obligation feature-006 step 5 hands over is *run the full generator, then confirm no render drift*.
Confirming it requires knowing what a rendered copy is **supposed** to differ by. Verified against real
rendered instances rather than reasoned from the source.

**The trigger set is per-root, and the list below is authoritative — not its length.** The substitution
triggers bind **every** D1 root; the frontmatter trigger is `canonical/skills/`'s alone, reached through
`translate="skills"` (`render.py:536–609`) and not through the `translate="none"` walk.

| Trigger | Scope | Defined at | Effect |
|---|---|---|---|
| `{project_context_file}`, `{reviewer_output_file}`, `{open_questions_file}` | every root | `render_lib.py:45–56` (`_PLACEHOLDER_RE`), applied at `:108–138` | Replaced with the profile's resolved filename |
| `canonical/(aid/)?(scripts\|templates\|recipes\|skills\|agents)/` | every root | `render_lib.py:71–80` (`_CANONICAL_PATH_RE`), applied at `:145–226` | Rewritten to the profile's install root |
| The literal `.claude/worktrees` | every root | `render_lib.py:224` | Rewritten to `<install_root>/worktrees`. **feature-002's Open Item 9 names only `substitute_filenames` and `rewrite_install_paths`**, so this needle is added here; it is a refinement of that item's grep, not a disagreement with it |
| `SKILL.md` frontmatter — the `allowed-tools:` line, and the `context:` / `agent:` keys | `canonical/skills/` **`SKILL.md` only**; not `references/*.md`, which get the substitution triggers and no frontmatter pass (`render.py:580–582`) | `render.py:555` → `_rewrite_skill_frontmatter`, which calls `_remap_tools` (`:105–121`) for the tools line (applied `:447–451`) and drops the `_CC_OPTIONAL` keys (`:428`) with their indented continuations (`:440–444`) | **Two effects, one substitution and one deletion.** Every listed tool the profile's `[tool_names]` table remaps is replaced, so the line differs in every profile declaring such a remap — verified on a production render: `canonical/skills/aid-summarize/SKILL.md:14` carries `Bash`, and each remapping profile's render carries that profile's name for it. Separately, for a **non-claude-code** profile the `context:` / `agent:` keys are deleted outright, so the trigger yields a byte range present in canonical and **absent** from the render. That half is inert on every canonical `SKILL.md` today — none declares either key, verified — but it is live the moment one does |

**Comment lines are exempt** — `render_lib.py:213–215` preserves any line whose first non-whitespace
character is `#`, and `:224`'s literal replacement sits in the `else` branch, so a comment line is
protected from both. Two consequences that matter:

- The exemption is **not** extension-keyed: any line whose first non-whitespace character is `#` is
  preserved — `#`-comment prose in `.sh`, `.ps1`, `.txt`, `.py` **and `#`-first lines in `.md`**, headings
  included. (`.yml` needs none: it is not transformed at all.) Verified in production twice:
  `generated-files.txt`'s `#` block (`:16–26`) discusses `canonical/` paths and its cursor render changes on
  data lines only; and `canonical/skills/aid-discover/references/doc-set-resolve.md` keeps `canonical/aid/…`
  verbatim at its `#` lines `:109`/`:203` while its non-`#` occurrences are rewritten.
- Files whose comment syntax opens `//`, `/*` or `<!--` — `.js`, `.mjs`, `.css`, `.html` — get **no
  protection at all**: a `canonical/` path inside such a comment **is** rewritten.

**The two guarantees, each verified with an instance:**

- **Verbatim class.** Rendered bytes equal canonical bytes, in every profile, unconditionally. Verified:
  `canonical/aid/templates/shortcut-catalog.yml` and its claude-code render share one sha256. This is the
  precedent `relation-vocabulary.yml`'s own header comment already cites (`:8–10`).
- **Transformed class.** Rendered bytes equal canonical bytes **iff** the file carries no in-scope trigger
  on a non-comment line, and otherwise differ **only** at those sites, differently per profile. Verified
  both ways: `canonical/aid/scripts/summarize/validate-visuals.mjs` carries a `canonical/` occurrence and
  its render has a different sha256; `contrast-check.mjs` and `validate-diagram-content.mjs` carry none
  and their renders are byte-identical. **The exemption completing the `iff` is branch-scoped:** under the
  `canonical/aid/` roots invalid UTF-8 falls back to a verbatim copy (`render.py:640–641`) and behaves as
  the verbatim class whatever the extension; the `canonical/skills/` branch has **none** —
  `render.py:553`/`:580` read unguarded, `run_generator.py:41` catches nothing — so invalid UTF-8 there
  **aborts the generator** — a loud failure like P3's, not an exemption CR06 may grant.

**Legitimate difference versus defect**, stated so a reviewer can tell them apart:

| Observation | Verdict |
|---|---|
| A transformed file's render differs from canonical at a trigger site, and differs across profiles only in the install-root basename | **Legitimate.** This is the transform doing its job |
| A verbatim file's render differs from canonical at all | **Defect.** No code path modifies it (`render.py:643`) |
| A transformed file's render differs from canonical anywhere **no trigger in scope for its root** is present | **Defect.** Either a line-ending divergence (below) or a hand edit of a rendered copy, which `module-map.md:337–338` forbids. Read against the wrong root the row misfires: a `SKILL.md` whose only difference is a remapped `allowed-tools:` line, or a `context:`/`agent:` key absent from a non-claude-code render, is **legitimate** — calling that a hand edit is the error the scoping exists to prevent |
| A rendered path exists that no manifest record names | **Defect.** Caught for the claude-code tree by the dogfood guard's Direction 2 (`test-dogfood-byte-identity.sh:178–182`), which walks `profiles/claude-code/.claude/` against the manifest. **The other profiles have no equivalent reverse check**, which is why CR04 quantifies over every profile rather than deferring to that suite |
| `run_generator.py` prints `VERIFY (deterministic): PASS` | **Required**, not incidental: `run_generator.py:71–81` exits 1 otherwise, which is what makes a re-render a fixed point and lets one diff prove both parity and stability |

**Line endings are a registration surface, and this is the one place the drift gate is provably blind.**
`.gitattributes` forces `eol=lf` for `*.sh`, `*.mjs`, `*.py`, `*.md` and `dashboard/MANIFEST` — and for
**nothing else**, verified by reading it. Its own header (`:5–7`) states the reason: this repo is authored
on Windows, and a CRLF commit "would break the byte-exact render-drift CI gate". D1's inventory contains
`.yml`, `.js`, `.css` and `.html` paths, and L1's own amendment adds a `.txt` one; no rule covers any of
them. The two failure modes differ:

- **Verbatim class:** CRLF in canonical ships as CRLF to every profile and every adopter. `git diff` after
  a re-render is clean, because a consistently-copied file matches a freshly-copied one. This is
  feature-002 Open Item 9's blindness, one level up from the bundle case.
- **Transformed class:** `render.py:636` reads with `read_text()` (universal newlines) and writes
  `.encode()`, so CRLF in canonical becomes LF in the render. Canonical and render then diverge with no
  gate asserting the pair, and again the diff is clean.

The fix is **path-scoped** rules, not extension-wide ones: `*.yml text eol=lf` at repo root would change
the checkout behaviour of every tracked `.yml` in the repository, burying an unrelated repo-wide change in
this diff. Scoping is also what leaves the **amendments** uncovered — D1's `.yml` one and L1's own `.txt`
one, both already-registered files sitting outside every new root — so each carries its own path rule.
`**` is honoured in `.gitattributes` (it shares gitignore pattern rules); verified in a throwaway repo.

```gitattributes
canonical/aid/templates/graph/**             text eol=lf
canonical/aid/templates/knowledge-graph/**   text eol=lf
canonical/aid/scripts/graph/**               text eol=lf
canonical/skills/aid-graph/**                text eol=lf
canonical/aid/templates/settings.yml         text eol=lf
canonical/aid/templates/generated-files.txt  text eol=lf
```

The root rules are also what make D6's conditional artifacts safe without a further rule, and that is why
G1 pins their location: `.json` is verbatim class and no extension rule reaches it, so a validator
manifest placed anywhere in the canonical script area *other* than `canonical/aid/scripts/graph/` would
reintroduce exactly this gap.

> **CR04 — presence, and the assertion everything else rests on.** After the full generator run, for
> every D1 path and for **every profile `run_generator.py:24` enumerates from `profiles/*.toml`**, that
> profile's `emission-manifest.jsonl` carries exactly one record whose `src` equals the D1 path with
> `render.py:656–660`'s `canonical/aid/<sub>/` → `canonical/<sub>/` normalisation applied — a **no-op**
> for a `canonical/skills/` path, since that loop rewrites only `scripts`, `templates` and `recipes`
> (`render.py:659`) and the skills branch records its `src` unnormalised (`render.py:569`) — and whose
> `sha256` equals the sha256 of the bytes at that record's `dst`.
>
> **CR05 — then, and only then, absence of change.** `run_generator.py` exits 0 and prints
> `VERIFY (deterministic): PASS`; `git diff --exit-code -- profiles/` exits 0; **and**
> `git status --porcelain --untracked-files=all -- profiles/` prints nothing. The third clause is added
> because `git diff` reports tracked paths only, so the command feature-006 step 5 names — and the CI job
> at `.github/workflows/test.yml:36–42` — cannot see an untracked emission. Adding a clause the frozen
> command omits is a strengthening, not a contradiction: every check that command makes still holds.
>
> **CR06 — class-correct byte-identity, per root.** For every verbatim D1 path, the rendered bytes in
> every profile equal the canonical bytes. For every transformed D1 path, either the rendered bytes equal
> the canonical bytes, or every differing byte range lies at a D3 trigger site **in scope for that path's
> root** — so for `SKILL.md` a remapped `allowed-tools:` line, or a dropped `context:`/`agent:` key, passes.
>
> **CR14 — dogfood parity.** After the render and the resync, `tests/canonical/test-dogfood-byte-identity.sh`
> exits 0, **and** for every D1 path the claude-code manifest record's `dst` exists under the repo-root
> `.claude/` tree carrying that record's `sha256`. The second clause is what makes this non-vacuous: the
> suite passes on the tree as it stands today, before any of this work's artifacts exist, so exit 0 alone
> says nothing about them. `run_generator.py` renders `profiles/` only (`:24`), so the resync is a real
> step and not a consequence of the render — which is why CR05 does not subsume this.
>
> **CR07 — line-ending coverage, over D1 *and* L1.** For every D1 path **and every `canonical/` path
> L1 declares an edit to, D6's conditional artifacts included**, `git check-attr text eol -- <path>`
> reports `text: set` and `eol: lf`; and no such file contains a CR byte. Quantifying over D1 alone is
> the failure this clause is written against — D1 comes from *other* features' sections, so D5's
> `generated-files.txt` is invisible to it. Decided over the union, never over either set.

#### D4 — Count and roster surfaces

Landing a curated skill directory moves more than one derived quantity, and several hand-written
surfaces mirror them. **The derivation is the contract; no count of an externally-owned set appears in
this SPEC.**

**Ground truth, in two derivations.** `tests/canonical/test-doc-counts.sh:44` derives its skill count as
`find canonical/skills -mindepth 1 -maxdepth 1 -type d | wc -l`, and `/aid-graph` is a curated,
hand-authored skill and **not** a `shortcut-catalog.yml` row, so of that suite's quantities only
`SKILLS` moves: `AGENTS` (`:45`) through `SHORTCUTS` (`:51`) are untouched and DC01a's
`CANON + ALIAS == ROWS` (`:56`) holds. `skill-counts.mjs`'s `deriveSkillCounts` is the wider one, and
**several** of its fields move together — which is why Class 1's sweep derives its needles by diffing
that derivation rather than by assuming one number.

**Class 1 — machine-gated mirrors, plus the value sweep that closes their corpus.** The gated part is not
restated here as a list of files, because restating it would create the sibling copy
`tech-debt.md:233–235` forbids. **Three** gates own it, not two: `test-doc-counts.sh:65–95`'s
`${SKILLS}`-interpolating `ASSERTIONS`; `tests/canonical/check-skill-counts.mjs`, which derives from
`site/scripts/skills/skill-counts.mjs` and scans every permanent artifact its `INCLUDE_FILES` /
`INCLUDE_TREES` / `REPO_LOCAL_SKILLS` name (`:145–168`), failing on any stated count that disagrees and
is unmarked; and `site/scripts/__tests__/skill-counts.test.mjs`, which `check-skill-counts.mjs:38–39`
names as the owner of `site/scripts/` and which **does check values**: its `CLAIM_PATTERNS` (`:206–225`)
run at `:239–249` against the hand-authored pages `CLAIM_PAGES` (`:38–46`) lists, and its `curated`
shape (`:210`) is **bare** where `check-skill-counts.mjs:96–97` are lookahead-guarded, so it gates a
phrasing those two cannot — besides forbidding a count outright in the files its `NO_COUNT_FILES`
(`:309–313`) names. All three exit 0 as the branch stands, verified by running each: evidence about
drift **today**, and none about the post-landing edit set.

**They decide phrasings, not the edit set, and the gap is wider than a decomposition.** A gate matches a
digit adjacent to a skill-ish noun; an operator, a parenthesis or a backticked command in that position
makes it invisible. Replaying `CLAIMS` (`:63–118`) over the corpus the script itself walks leaves live,
non-history-shaped lines carrying a current value that match nothing, on their own line or on either
join — Open Item 7 quotes the regexes and grades the evidence. `generate-profile/SKILL.md:102–103`
states the cost: "a decomposition whose parts do not add up to the total is how this file was wrong twice."

**So the edit set is the gates' report ∪ a sweep keyed on values, not on phrasings.** Needles, derived
and never listed: `node tests/canonical/check-skill-counts.mjs --list` (`:309–311`, `deriveSkillCounts`
as JSON) captured before Flow step 1 authors the directory, and again **after the L1 roster edit lands
in Flow step 9** — not merely after step 1, which authors `canonical/` only and so moves the directory
count alone while every roster-derived field is still unchanged. The second snapshot is pinned there
because a pair of snapshots taken either side of step 1 reports a single moved field, and a needle set
of one is exactly the vacuity CR08 would then be satisfied over. Every field whose value differs
between the two is a quantity this landing moves, and its **before** value, in digits or words, is a
needle.
Over the corpus `check-skill-counts.mjs` walks (`:145–168` with `:172–196`), de-emphasised as the script
itself does (`:239`), **every occurrence of a needle is read and set to that field's after value, unless
the sentence counts something else or records a past state** — the F3 rule `:73`, applied to
history-shaped lines by reading them rather than skipping them by shape, which `:211–214` calls evadable.
A bare number also hits dates and line numbers: that is the trade, and the asymmetry justifies it — a
false positive costs one read, a false negative ships a stale artifact. **Why there is no next escaping
line.** A surface stating a moved quantity's old value contains that value, so no phrasing — a noun, an
operator, an emphasis run, a wrap — can hold it outside a needle, and re-sweeping the *before* values
after the edit returns only hits already dismissed. The residual is a corpus boundary, not a phrasing:
the walk skips non-source files inside those trees (`:170`) and two log files by name (`:155–158`), and
of those the only one stating a skill count is `kb.html` — already Open Item 6's.

**Class 2 — roster surfaces, each guarded by a hard failure, and inseparable.** Re-derived on disk.

| Surface | Change | Guard |
|---|---|---|
| `site/scripts/skills/curated-roster.mjs` `SKILL_GROUPS` (`:28–68`) — the *Knowledge Base Maintenance* group at `:40–50`, beside `aid-summarize` (`:44`) | One entry: the skill name, and nothing else. The per-skill `phase` key was dropped when the roster was extracted, because the page it fed no longer exists (`:15–23`) | **Hard failure.** `gen-reference.mjs:237–248` computes `expected` as the curated names ∪ every catalog row name and throws `[gen-reference] skills drift` unless it equals `onDisk` |
| `site/scripts/skills/groups.mjs` `CURATED_GROUPS` (`:63–111`) — a separate taxonomy, deliberately not named `SKILL_GROUPS` (`:4–5`) | The same name, placed in a group | **Hard failure.** `:212–220` throws `[gen-skills] unassignable skill` **by name** for a directory that is neither curated nor a catalog row, and `gen-skills.test.mjs:1071–1073` reaches it from the real corpus |
| `site/scripts/__tests__/gen-reference.test.mjs` `CURATED_SKILL_NAMES` (`:144–154`) | The same name | **Hard failure.** `:164–166` asserts this list equals `SKILL_GROUPS` membership, and the clamp at `:188–190` fails **by name** for any on-disk skill directory that is neither a catalog row nor listed here |

All of them must move together and no guard substitutes for another: omit the roster entry and the
**generator** throws, omit the group entry and the **`/skills/` build** throws, omit the test entry and
the **test** fails. No prose count follows by hand — `gen-reference.mjs:265` reads `onDisk.length`, and
`skills/skill-counts.mjs` is the one derivation every stated count is now checked against.

**Class 3 — comments in the files this feature edits: empty.** `gen-reference.mjs:11` reads `NO SKILL
COUNT IS WRITTEN HERE` and `:158–160` names the derivation; re-anchor-never-increment governs the next.

**Deliberately not swept, and the "repo-wide" claim retracted.** `check-skill-counts.mjs` is not
repo-wide; its own header says so, verbatim at `:36–39`: "NOT YET SCANNED (stated so the SCOPE above is
not read as exhaustive): site/scripts/, tests/, dashboard/, lib/, bin/, packages/ — code trees whose
counts live in comments. site/scripts/ is covered separately by
site/scripts/__tests__/skill-counts.test.mjs; the rest are uncovered." Present-tense corpus totals do
live in those trees, this work makes them stale, and the 012/013 seam puts them outside this feature, so
they are **deferred, not absent** — Open Item 3 names them and is restored for exactly that.

> **CR08 — reconcile completeness, pinned on presence *and* on values.** `test -d
> canonical/skills/aid-graph` succeeds, `bash tests/canonical/test-doc-counts.sh` and
> `node tests/canonical/check-skill-counts.mjs` each exit 0, **and** D4 Class 1's value sweep leaves, in
> the corpus that gate walks, no live line still stating a moved quantity's pre-landing value — which is
> what the sweep decides and the whole of what it claims. Two pins, against two vacuities: the `test -d`
> because both suites pass at the previous derived count if the skill was never created, and the sweep
> because both report agreement over values their needles and patterns never read —
> `test-doc-counts.sh:65–95` has no curated needle at all.
>
> **CR09 — the roster set.** With `canonical/skills/aid-graph/` present, `node site/scripts/gen-reference.mjs`
> and `node site/scripts/gen-skills.mjs` each exit 0, and `npm test` in `site/` exits 0. Same pinning
> argument, and each guard bites in a different direction. The merge made the pin structural rather than
> merely stated: `gen-reference.test.mjs:188–190` is a **set-equality clamp** — every on-disk skill
> directory must be a catalog row or a curated name — so once the directory exists that suite fails **by
> name** until the rosters carry it. `test -d` still earns its place: the clamp is silent when the
> directory was never created.
>
> **CR10 — no new or incremented literal.** No clause in this SPEC, and no edit it requires, introduces
> or increments a hardcoded count of a set another file owns. Every count surface it edits is
> machine-gated against a derivation (Class 1's gated part), re-anchored to name one (Class 3), or
> corrected by Class 1's value sweep under CR08's reconciliation — the third named explicitly because
> it is the one with no gate behind it. Decided by reading this SPEC and the edit list at L1, **and** by
> `bash tests/canonical/test-skill-counts.sh` exiting 0.

#### D5 — The generated-file registry: decided, not deferred

feature-003 Open Item 10 (SPEC.md`:1970–1974`) routes the placement question here, and feature-002
`:1111–1116` records it as open. **Decision: `relationships.md` and `graph.html` are not registered in
`canonical/aid/templates/generated-files.txt`.** Each of that registry's verified consumers would fire
wrongly:

| Consumer | Line | What registration would do |
|---|---|---|
| `/aid-discover` FIX state, step 3 | `canonical/skills/aid-discover/references/state-fix.md:61–69` | Execute the build command mid-discovery, on every cycle — contradicting FR-7, which makes `/aid-graph` an on-demand sibling of `/aid-summarize`, not a phase of discovery |
| The same state's step 4 existence loop | `state-fix.md:71–82` | Fail on any project that has not run `/aid-graph` |
| The KB review rubric | `canonical/aid/templates/kb-authoring/review-rubric.md:252` | Raise `[GEN-MISSING]` at **HIGH** for a registered file that does not exist |
| `cleanup-classify.sh` | `canonical/aid/scripts/housekeep/cleanup-classify.sh:196–205` | Reclassify the outputs against a registry they do not belong to |

**And the registry cannot express the condition anyway.** `/aid-graph` is gated on an approved KB
(FR-8) while the FIX state runs before approval, and the flat `<output-path>|<build-command>` format
(`generated-files.txt:3–4`) has no place to put a precondition. The precedent agrees:
`/aid-summarize`'s `kb.html` is absent from the registry today, verified — its data lines name only
`project-index.md`, `metrics.md` and `INDEX.md`.

**The disposition is recorded where it would otherwise be re-asked, not only here.**
`generated-files.txt`'s `#`-comment block gains one line stating that `/aid-summarize`'s and
`/aid-graph`'s outputs are deliberately unregistered because their build commands are KB-approval-gated
and the format cannot express that. This is safe by construction: `.txt` is transformed, and the
comment-skip (`render_lib.py:213–215`) carries the header verbatim into every profile — which that
block's own note at `:24–26` already documents. **This is the amendment D1 cannot see** — routed by no
other feature's Layers section, already registered, transformed class, and reached by neither an
extension rule nor a new-root rule (`git check-attr text eol` → `text: unspecified`) — so M1 gives it a
path rule of its own and CR07 quantifies over L1 too. No CR byte today, verified: the rule renormalises nothing.

> **CR11.** `generated-files.txt`'s header states the exclusion rule and names both skills, **and** no
> data line in it matches `relationships.md` or `graph.html`. The first clause is what makes this
> non-vacuous — a "must not appear" assertion alone passes when nothing was done at all.

#### D6 — The third-party packaging gate (conditional on FR-18)

REQUIREMENTS `:43` fixes the reference architecture — `d3-force` plus a WebGL drawing layer — and
feature-007 `:1590–1603` fixes the delivery contract: local-vendored companions under
`.aid/knowledge/graph-assets/`, referenced relatively, loadable as **classic scripts**. What is not yet
fixed, and what this feature owns, is the packaging: where the bundle lives canonically, how it is
pinned, watched and licensed, and how it survives the render.

**Canonical home.** A vendored bundle is a rendered asset of the view, so it lives in a subdirectory of
`canonical/aid/templates/knowledge-graph/` and travels the template set's own render path. It lands in the
**transformed** class — a classic-script bundle is delivered as `.js`, which `render.py:77–79` includes —
and choosing an extension outside that frozenset to dodge the transform is explicitly **not** the control
this SPEC relies on; G6's grep is.

| # | Condition | Grounded in |
|---|---|---|
| G1 | Any dev/validator manifest is `"private": true` and unpublished, and lives **under `canonical/aid/scripts/graph/`** — never in `packages/npm/package.json` or `packages/pypi/pyproject.toml`, and not elsewhere in the canonical script area | `.aid/knowledge/technology-stack.md:217–218` (both wrappers declare empty dependency sets). Precedent: `canonical/aid/scripts/summarize/package.json` is `"private": true` with Playwright as a `devDependency`. The root is pinned rather than left to "the script area" because `.json` is verbatim class and no extension rule reaches it; that root is one M1 covers (D3) |
| G2 | The version is pinned exactly and a lockfile is committed, beside the manifest and under the same root | Same precedent: that manifest pins `"playwright": "1.61.1"` and `canonical/aid/scripts/summarize/package-lock.json` is committed and renders alongside it (both `.json`, verbatim class). Same line-ending reason as G1 for the location |
| G3 | No install directory ships | Already guaranteed by P2 (`render.py:620,626`), so this needs asserting rather than building |
| G4 | `.github/dependabot.yml` gains an ecosystem entry for the new manifest directory | That file declares a single `github-actions` ecosystem (`:5–9`), so a new manifest is unwatched by default. feature-002 SPEC.md`:1096` routes this here |
| G5 | Licence text or SPDX id and any required attribution travel with the asset | feature-002's licence findings, landed here per feature-008 § External Integrations, its "Licence, attribution, payload, update mechanism" row |
| G6 | **Integrity under the render.** At vendor time *and at every version bump*, the bundle bytes are grepped for D3's substitution triggers — the set in scope for its root, the frontmatter trigger being unreachable from a template path — and the vendored copy is byte-compared against the upstream distribution at the pinned version | feature-002 Open Item 9 (SPEC.md`:1273–1279`): the render-drift gate compares a fresh render to a committed render, so a consistently-mangled copy passes. The upstream comparison is the only detector, and the condition is not stable across a version bump — hence a step in the update procedure, not an observation |
| G7 | The bundle is a classic script (UMD/IIFE), not an ES-module-only distribution | feature-007 SPEC.md`:1599–1603`: a `file://` page cannot import a relative ES module, and this is routed here as a constraint on the bundle |

**The inline-versus-companion choice is this feature's, and it has one named consequence.**
feature-007 `:1596–1598` records that under the companion layout `NM.1` cannot see the bundle at all,
and that inlining makes its token condition live. **Companion is chosen**, on two grounds already on
disk: it keeps `NM` and `S2` passing by construction under the reference layout (feature-007
`:1621–1622`), and it keeps the repository-side payload to one canonical copy plus one per profile
rather than multiplying it through the assembled page. That per-profile multiplication is feature-002
Open Item 10's point, and it is why the choice belongs to packaging rather than to the view.

**Adoption is not this feature's trigger to pull, and the gate's applicability rule is stated so it is
not read as all-or-nothing.** G1, G4 and G2's *lockfile* clause are **manifest-conditional** — a
no-build vendored asset has no manifest to make private, to watch, or to lock. G2's *exact-pin* clause,
G3, G5, G6 and G7 bind **any** vendored bundle, build chain or not. G6 is the important survivor: it is
the only condition whose failure is invisible to every existing gate.

> **CR12 — the gate is executable as written (unconditional).** G6's needle set is D3's trigger list for
> the bundle's root, each member cited at its defining line, and every G-condition names the file it
> touches. Decided by resolving every citation.
>
> **CR13 — on adoption (conditional).** Every G-condition applicable to the chosen packaging holds, with
> applicability decided by the rule above rather than case by case, and G6 appears as a step in the
> documented update procedure rather than as a one-time result.

### Feature Flow

The C-2 sequence, in the order a contributor performs it. Steps 1 and 2 are named as preconditions
owned elsewhere, not as this feature's work.

1. **(Precondition, elsewhere)** The D1 artifacts are authored in `canonical/`, including
   `canonical/skills/aid-graph/SKILL.md`. Nothing is written into `profiles/` or `.claude/` by hand
   (`module-map.md:337–338`).
2. **(Precondition, elsewhere)** D1's amendment rows land — feature-006's two shared contracts
   (`reviewer-ledger-schema.md`, `frontmatter-schema.md`) and feature-004's two (`read-setting.sh`, `settings.yml`).
3. **Add the `.gitattributes` rules** (D3) *before* the first render **and before this feature's own
   amendment at step 9**, so no CRLF can be committed into any canonical path CR07 quantifies over and
   then rendered from.
4. **Check the silent-drop predicates** (D2 P1–P5) against the authored tree. Doing this before the
   render is what turns a silent omission into a caught one, since the render itself reports nothing.
5. **Run the FULL generator** — never a per-script renderer (`tech-debt.md:350–353`):
   ```bash
   python .claude/skills/generate-profile/scripts/run_generator.py
   ```
   It renders every profile in `profiles/*.toml`, rewrites each emission manifest, performs the
   pure-mirror diff/deletion pass, and runs the verify spine (`run_generator.py:24–90`).
6. **Assert presence FIRST** (CR04). The ordering is the whole point, so the presence check appears
   here rather than being left implicit. Manifest records are `json.dumps(…, sort_keys=True)`, so
   `"src"` is a literal-greppable field (verified against a committed manifest line):
   ```bash
   # <src> = a D1 path with render.py:656-660's normalisation applied (a no-op for canonical/skills/).
   for m in profiles/*/emission-manifest.jsonl; do
     grep -Fq "\"src\": \"<src>\"" "$m" || { echo "NOT EMITTED into $m: <src>"; exit 1; }
   done
   ```
7. **Then assert parity** (CR05):
   ```bash
   python .claude/skills/generate-profile/scripts/run_generator.py \
     && git diff --exit-code -- profiles/ \
     && test -z "$(git status --porcelain --untracked-files=all -- profiles/)"
   ```
   The re-run is deliberate: a second render over an already-rendered tree must be byte-identical, so
   one command proves both that `profiles/` matches `canonical/` and that the render is a fixed point.
   Run **after** step 6, never instead of it — on its own this block is green when nothing was emitted.
8. **Resync the dogfood tree** from `profiles/claude-code/.claude/` — the same install copy any adopter
   performs (`profiles/claude-code/README.md:15`). No repository script automates this; it is a stated
   step, not an invented mechanism. Then:
   ```bash
   bash tests/canonical/test-dogfood-byte-identity.sh
   ```
   Direction 1 requires every `.claude/`-prefixed manifest `dst` to exist under the repo-root tree with
   a matching sha256, so this is the check that catches a skipped resync — but only alongside CR14's
   per-path clause, since the suite already passes today. No Direction-3 allowlist edit is needed: that
   list (`:222–229`) covers non-generator files, and after step 5 these paths are generator-owned
   manifest entries.
9. **Reconcile the counts and rosters** (D4) **and add the registry header line** (D5). Then:
   ```bash
   bash tests/canonical/test-doc-counts.sh
   bash tests/canonical/test-skill-counts.sh          # wrapper over check-skill-counts.mjs
   cd site && node scripts/gen-reference.mjs && node scripts/gen-skills.mjs && npm test
   git status --porcelain --untracked-files=all -- site/   # every path printed must be an L1 row
   ```
   This step follows the render deliberately: the render is what makes a hand-maintained surface inside
   a generated tree visible as such, and reconciling first would invite a second render and a second
   reconcile. Each command is pinned on `canonical/skills/aid-graph/` already existing (CR08, CR09,
   CR10); run without it they pass at the previous derived count and prove nothing. Two things the
   commands do **not** decide are done by hand: D4 Class 1's value sweep, whose *before* `--list` must
   be captured ahead of step 1 and whose *after* `--list` must be captured **once this step's L1 roster
   edit has landed** — taken any earlier it reports only the directory count and hands the sweep a
   needle set of one — and the `git status` line (no workflow diffs `site/`, so a generator
   output left uncommitted, or one L1 never listed, is otherwise invisible).

Ship-time documentation, the Knowledge Base updates and the aggregate HOME-pinned suite run **after**
this sequence and are feature-013's.

### Layers & Components

#### L1 — The complete edit list

Every file this feature changes. Nothing outside this list is touched, and its complement is L2 and L3.

| File | Edit | Class |
|---|---|---|
| `.gitattributes` | Path-scoped `text eol=lf` rules — one per root D1 declares, plus one for each already-registered amendment no extension rule reaches: D1's `.yml` and this feature's own `.txt` (D3) | New rules; no existing file renormalised |
| `canonical/aid/templates/generated-files.txt` | One header-comment line recording the exclusion rule (D5) | Comment only; comment-skip carries it verbatim to every profile. **The `canonical/` path in this list, hence inside CR07 and outside D1** |
| `site/scripts/skills/curated-roster.mjs` | One `SKILL_GROUPS` entry — the *Knowledge Base Maintenance* `skills` array (`:42–49`) (D4 Class 2) | One data entry; every consumer derives from it |
| `site/scripts/skills/groups.mjs` | One `CURATED_GROUPS` member — the *Knowledge Base Maintenance* `members` array (`:80–87`) | The `/skills/` taxonomy; its clamp names an unassigned directory |
| `site/scripts/__tests__/gen-reference.test.mjs` | One `CURATED_SKILL_NAMES` entry (`:144–154`) | The inseparable mirror of the two rows above |
| The `${SKILLS}`-parameterised surfaces at `tests/canonical/test-doc-counts.sh:65–95`; every surface `tests/canonical/check-skill-counts.mjs` reports; **and** every line D4 Class 1's value sweep finds still stating a moved quantity's pre-landing value over that gate's own corpus | Each states the current derived count | Gated mirrors **plus one ungated complement** — the suites decide completeness for the first two only, which is why the third is named rather than implied |
| `profiles/**`, `emission-manifest.jsonl` ×N, the dogfood `.claude/` tree, `site/src/content/docs/skills/**` (the per-skill page and `index.md`) | **Regenerated, never edited** | Build output |
| `site/src/content/docs/reference/skills.md` (`gen-reference.mjs:513` over the `pages` list at `:494–506`), `site/scripts/.reference-manifest.json` (`:528`), `site/src/data/skill-flows/<dir>.flow.json` (`gen-skills.mjs:201`), `site/scripts/.skills-manifest.json` (`:245`) | **Regenerated, never edited.** Every one tracked. The `.flow.json` sidecar is a **new** tracked file, and by mechanism rather than by coincidence: `gen-skills.mjs:95` sets `CHARTABLE_SHAPES` to the whole of `SHAPE_ORDER` and `:188–193` throws on any shape outside it, so `:198`'s skip cannot fire and exactly one sidecar is written per skill directory — `:196–197`'s comment describing a charted subset is stale. `.reference-manifest.json` is rewritten byte-unchanged, its content being the static `pages` list; the other three pages that list names read no skill directory (`SKILLS_DIR` is reached only at `gen-reference.mjs:240` and `:265`, both inside the skills page) and are byte-unchanged too | Build output of the generators Flow step 9 mandates. Enumerated because nothing gates a stale committed copy — no workflow runs `git diff` over `site/` — so step 9's `git status` line is this row's only oracle; `site/.gitignore` covers `node_modules/`, `dist/`, `.astro/` and `.release-data.json`, so that line prints build output and nothing else |

Conditional on FR-18 adoption: a vendored bundle subdirectory under
`canonical/aid/templates/knowledge-graph/`, a private validator manifest and lockfile under
`canonical/aid/scripts/graph/`, and one `.github/dependabot.yml` ecosystem entry (D6). Both canonical
roots are M1-covered — G1 pins them for that reason; `dependabot.yml` is not a `canonical/` path, is
never rendered, and is therefore outside CR07.

#### L2 — Surfaces that need no edit, and why

Each was checked rather than assumed; a reviewer should be able to disprove any row.

| Surface | Why not |
|---|---|
| `canonical/EMISSION-MANIFEST.md` | Its Asset Kinds table (`:111–116`) maps `canonical/aid/scripts/`, `canonical/aid/templates/` and `canonical/skills/` wholesale; a subdirectory needs no row |
| `canonical/aid/templates/shortcut-catalog.yml` | `/aid-graph` is curated and hand-authored, not a shortcut doorway (`module-map.md:328–336`); no row, and the catalog-derived counts do not move |
| `tests/run-all.sh`, `.github/workflows/*.yml` | Suite discovery is the `test-*.sh` glob at `tests/run-all.sh:112` — which is also how `test-skill-counts.sh` reached the runner without a wiring edit |
| `site/scripts/gen-reference.mjs` | It was an L1 row before the merge and is not one now: the roster it held moved to `skills/curated-roster.mjs` (`:27`, `:163–165`), its drift guard reads that import, and its header no longer states a count (`:11`). Nothing in it is keyed on a skill name |
| `tests/canonical/test-ascii-only.sh` | Its `SHIPPED_SCRIPTS` list (`:25–67`) exists for files a PowerShell host may parse under a non-UTF-8 ANSI codepage (`:3–7`). It covers `lib/`, `bin/`, `install*`, `packages/`, `dashboard/`, `canonical/aid/scripts/migrate/` and `canonical/aid/scripts/kb/`; the whole `canonical/aid/scripts/summarize/` area — `.sh` and `.mjs` alike — is absent. `graph/` follows that precedent |
| `tests/canonical/test-dogfood-byte-identity.sh` | No edit: the Direction-3 allowlist (`:222–229`) covers non-generator files, and these paths become generator-owned |
| `lib/aid-install-core.sh`, `lib/AidInstallCore.psm1` | Directory walks, no per-file list (D2) |
| `packages/npm/*`, `packages/pypi/*` | The vendored payloads do not reach `canonical/` (D2) |
| `canonical/aid/templates/knowledge-graph/package.json` | Withdrawn by feature-006 SPEC.md`:1083–1085`; `.mjs` needs no marker, and a manifest inside a template directory would render into every adopter's install |
| `.aid/knowledge/kb.html` | Generated and hand-edit-forbidden, and deliberately outside the doc-count guard: `test-doc-counts.sh:18–20` excludes `.aid/knowledge/` by design and says it "is reconciled by `/aid-housekeep`". It **does** carry the skill count, so a regeneration is owed — routed as Open Item 6 on the precedent at `.aid/knowledge/STATE.md:226`, where a stale generated figure was deferred to the next SUMMARY-DELTA regeneration rather than hand-patched |

#### L3 — What this feature does NOT do

The three-way split of the original packaging feature — 011, 012, 013 — plus the neighbours this
feature borders.

| Boundary | This feature (012) | The other side |
|---|---|---|
| **012 / 011** | The packaging, manifest and monitoring surface of any adopted dependency (D6) | **feature-011** owns every edit to `canonical/aid/scripts/summarize/*` — the `contrast-check.mjs` parameterisation, the `validate-visuals.mjs` capture exemption, any launch-flag change — and owns whether its contingencies fire at all. No clause here specifies a validator change. Cited by name and section only: that SPEC is being authored concurrently, so no line citation to it would be stable |
| **012 / 013** | A documentation edit whose reason is **a number or a roster row**: every surface the count gates report, every line D4 Class 1's **value** sweep finds still stating a moved quantity's pre-landing value in the corpus that gate walks, and every site roster surface D4 Class 2 names. Keying on values rather than on phrasings is what closes that corpus instead of sampling it, so the seam is a partition and not a gap: inside the corpus every stale value is 012's; outside it a stale value is Open Item 3's, or — for a non-source file the walk's extension filter skips — Open Item 6's; and a claim that goes stale without stating a moved quantity's value, a relative or narrative one, is prose and 013's | **feature-013** owns every test suite (including the shipped-result registration suite), the ship-time Knowledge Base updates — `module-map.md`'s `graph/` row (feature-006 Migration step 4, its SPEC.md`:1151`), `artifact-schemas.md`, `capability-inventory.md`, `technology-stack.md`, `infrastructure.md`, `release-tracking.md` — and the discoverability documents |
| **012 / 010** | The render, the manifests, the count surfaces, and this feature's own edit list | Whoever authors the skill body, its `references/*.md` state files and the `graph/` bash scripts. The pre-decision feature-010 draft also assigns `SKILL.md`'s `## References` section and `canonical/skills/aid-graph/README.md` here; that assignment is **not** adopted on a pre-decision authority — see Open Item 1. This feature authors no file **content** at all |
| **012 / 002** | Where a bundle lives, how it is pinned and watched, and whether it survives the render | **feature-002** reports the payload, licence and update findings and derives the bench; it selects nothing this feature must wire beyond the reference architecture already fixed by the owner |
| **012 / 003 + 007** | Nothing | The runtime output contract — `relationships.md`'s frontmatter and index behaviour, and `graph-assets/`'s runtime naming under `.aid/knowledge/` — is theirs. This feature registers **canonical sources**, not runtime outputs |

The 012/013 seam is the only one where two features may edit the same *file*; the rule above is what
keeps them off the same *line*. `/aid-detail` should sequence count before roster prose, because the
doc-count guard is the cheaper gate and gives a clean signal first.

### External Integrations

**Conditional, and currently empty.** No third-party dependency is introduced by this feature as
specified. Until the FR-18 research reports, the integration surface is unchanged:
`.aid/knowledge/technology-stack.md:217–218`'s empty-dependency-set claim stays accurate, both published
wrapper manifests keep their empty dependency sets, and `.github/dependabot.yml` keeps its single
`github-actions` ecosystem (`:5–9`). The section is stated rather than omitted because D6 fixes the gate,
the canonical home and the companion-versus-inline choice now, so adoption is a scheduled consequence
rather than a mid-execution discovery.

### Migration Plan

Nothing here changes any skill's runtime behaviour.

| # | Change | Blast radius | Verification |
|---|---|---|---|
| M1 | Path-scoped `.gitattributes` rules, one per root D1 declares plus one per already-registered amendment outside every root — D1's `.yml` and L1's own `.txt` | New paths only; no existing file renormalised | CR07 — `git check-attr text eol` over D1 ∪ L1's `canonical/` paths, not D1 alone |
| M2 | Silent-drop predicate check over the authored tree | None (read-only) | CR03 |
| M3 | Full generator run | Every profile tree | CR04 then CR05, in that order |
| M4 | Dogfood resync from `profiles/claude-code/.claude/` | The repo-root `.claude/` tree | CR14 — the suite plus the per-path check it cannot make |
| M5 | Count surfaces reconciled to the derived value; every roster surface D4 Class 2 names; the registry header line | User-facing docs, the site's roster modules and its test, one template header | CR08, CR09, CR10, CR11 |
| M6 | *Conditional* — bundle vendoring, private manifest and lockfile under `canonical/aid/scripts/graph/`, dependabot ecosystem entry | The template set, that script root, CI monitoring | CR13, and CR07 for the two canonical roots |

M3 must not be attempted with a per-script renderer; `tech-debt.md:350–353` records that the drift gate
then fails on stale emission manifests. M4 has no automating script and is the step most likely to be
skipped, which is why its verification is a suite rather than an eyeball.

### Tests

**This feature introduces no test suite.** Its proof is existing machinery plus the assertions above;
the shipped-result suite is feature-013's, because it can only run after this render.

| What it decides | Existing machinery |
|---|---|
| CR04, CR05 — presence then parity | `run_generator.py` exit status and its `VERIFY (deterministic)` line; `git diff` + `git status` over `profiles/` |
| CR06 — class-correct byte-identity | `sha256sum` of canonical against each rendered copy; `diff` at trigger sites |
| CR14 — dogfood parity | `tests/canonical/test-dogfood-byte-identity.sh` Direction 1, **plus** the per-D1-path `dst`/`sha256` check the suite cannot supply on its own |
| CR07 — line endings | `git check-attr text eol` per path, over D1 ∪ L1's `canonical/` paths |
| CR03 — silent-drop predicates | Inspection against the cited `render.py` lines; P3 alone is enforced by the generator |
| CR08 — count reconcile | `tests/canonical/test-doc-counts.sh` and `tests/canonical/check-skill-counts.mjs`, both **unmodified** — the derived `SKILLS` and `deriveSkillCounts` are what make them gates. **Plus D4 Class 1's value sweep against `deriveSkillCounts`**, because no existing machinery decides it: the gates match phrasings, and a live value in a phrasing none of them carries matches nothing at all |
| CR09 — roster set | `node site/scripts/gen-reference.mjs` and `node site/scripts/gen-skills.mjs` (each throws) + `npm test` in `site/`, whose clamp names the unregistered directory |
| CR10 — no new or incremented literal | `tests/canonical/test-skill-counts.sh`, new since the merge — wide, **not** repo-wide (`check-skill-counts.mjs:36–39`), and phrasing-keyed rather than value-keyed; the review half remains for clauses in this SPEC's own prose and for every live value the patterns miss |
| CR11 — registry disposition | Read-back of the header line plus a grep of the data lines |
| CR01, CR02, CR12 — inventory, class, gate-executability | Review against the cited lines; these are document-level obligations with no runtime |

`tests/canonical/test-graph-skill-registration.sh` — the suite that asserts the shipped result across
every profile — is **feature-013's**, and is named here only so the boundary is visible.

### Open Items

Recorded rather than silently assumed. Where an item belongs elsewhere, the owner is named and the item
is not absorbed here. Each carries a **Q26 class**; an item that cannot be classified confidently is
treated as **mechanism**, the conservative default. None blocks this feature's own implementation.

1. **`SKILL.md`'s `## References` section and `canonical/skills/aid-graph/README.md` have no owner this
   SPEC will accept.** The pre-decision feature-010 draft assigns both to feature-012, but that document
   is scheduled for fresh authoring under Q24 item 7 and is not a settled input, so adopting the
   assignment would rest this feature on an authority that may not survive. It is also the wrong shape:
   both items are **content authoring**, and this feature authors no file content. One verified fact the
   re-authoring should consume rather than rediscover — a skill's own `README.md` **never ships**:
   `render.py:536–609` emits `SKILL.md`, `references/*.md` and a verbatim `scripts/` and nothing else, so
   a canonical `README.md` is maintainer documentation and satisfies no discoverability obligation.
   **Owner: feature-010** (skill authoring, ungated — no reopen consequence), with **feature-013** if the
   `README.md` is wanted as a documentation surface. **Class: mechanism** — it decides whether a file
   exists.
2. **Where registration meets validation.** Two gated Layers sections declare amendments to
   `canonical/aid/scripts/summarize/*` (feature-002 SPEC.md`:1097`, `:1098`; feature-007 SPEC.md`:1567`),
   but each names a **non-gated** owner and each is contingent, so D1's amendment clause excludes them by
   rule, not by oversight. They stay canonical files inside this feature's full-generator-and-parity
   obligation; both are `.mjs`, already `text eol=lf`, and a new extension falls to Open Item 5. What
   needs coordinating is that `/aid-detail` orders the render **after** the last canonical edit of either
   feature, so parity is not asserted against a tree about to change. **Owner: feature-011** (concurrent,
   so cited by name and section only) **and `/aid-detail`** for the ordering. **Class: mechanism**.
3. **Pre-existing count claims in surfaces this feature does not edit — re-scoped, not withdrawn.** The
   cycle-4 withdrawal was right about this item's *body* and wrong about its *title*, and closing it on
   the narrower of the two lost the deferrals. Dead: the `.claude/skills/generate-profile/SKILL.md`
   premise — the merge re-anchored that file's completion checklist to the derivation (`:263–265`) and
   its `ls` check to "must equal the first number printed above" (`:131`), and `check-skill-counts.mjs`
   scans it (`:166–168`, `REPO_LOCAL_SKILLS`). Live: the **present-tense** corpus totals in the trees that
   gate's header declares NOT YET SCANNED (`:36–39`) — read on disk at
   `site/scripts/lib/provenance/verify.mjs:9` and `site/scripts/skills/render-value.mjs:74`, with siblings
   in the same `provenance/` module, none inside `skill-counts.test.mjs`'s `NO_COUNT_FILES` (`:309–313`).
   This work makes each stale and nothing reports it; the 012/013 seam puts them outside this feature.
   **Owner: the work owner**, to route — to feature-013 as documentation surfaces, or to Open Item 7's
   scope widening. **Class: mechanism** — unrouted, the repository asserts something untrue about itself.
4. **The payload judgment (feature-002 Open Item 10).** A canonical bundle exists once in `canonical/`
   and once per profile render, each with its own manifest `sha256`. Whether that repository-side
   footprint is acceptable at the decided architecture's size is a packaging judgment this SPEC cannot
   make before the research reports a size. D6's companion-over-inline choice is the part decidable now
   and is decided. **Owner: this feature at execution, with the work owner** if the figure is large
   enough to reopen the packaging shape. **Class: mechanism** — it can change the packaging contract.
5. **`.gitattributes` coverage is narrower than the repository needs.** M1's rules close the gap for
   every path CR07 quantifies over — D1's, plus L1's own `generated-files.txt` — and for nothing else.
   The residual is stated as a **complement**, not an extension list, so it cannot be misread as
   exhaustive: every tracked text file whose extension `.gitattributes` does not name (`*.sh`, `*.mjs`,
   `*.py`, `*.md`, `dashboard/MANIFEST`). That includes `.yml`, `.yaml`, `.txt`, `.json`, `.js`, `.css`,
   `.html` and `.ps1` — the last transformed class and uncovered despite sitting in `render.py:77–79`'s
   frozenset. For the verbatim class the render-drift gate is blind to it, and path-scoping is deliberate
   (D3). **Owner: a separate methodology fix**, outside this work. **Class: mechanism** — a gate gap.
6. **`kb.html` will hold a stale skill count after this work, and no feature owns regenerating it.**
   The generated viewer states the skill count and is hand-edit-forbidden;
   `test-doc-counts.sh:18–20` excludes `.aid/knowledge/` from the guard by design and names
   `/aid-housekeep` as the reconciler. The precedent for the disposition is
   `.aid/knowledge/STATE.md:226`, where a stale generated figure was deferred to the next SUMMARY-DELTA
   regeneration rather than hand-patched. This is **not** feature-013's, because 013 owns hand-authored
   Knowledge Base documents and this is build output. **Owner: a `/aid-housekeep` SUMMARY-DELTA run**,
   scheduled by the work owner at ship time. **Class: mechanism** — it is a regeneration, not a wording
   change, and skipping it leaves the repository asserting something untrue about itself, which is the
   exact failure this feature exists to prevent.
7. **The count gate misses a live value wherever its `CLAIMS` set carries no phrasing for it — a live
   defect in `check-skill-counts.mjs`, not in this SPEC, and deliberately not fixed here.** Quoted from
   the file: `:96` `/\b(\d+) curated (?:pipeline|skills?|non-catalog|and|\/)/g` requires one of the words
   it lists after `curated`; `:97` `/\b(\d+) curated\b(?= *[-—,.)]| skills)/g` admits the
   **closing** paren `)` and not the opening `(`, so neither matches *N* `curated (` or *N* `curated +`;
   and `:108–111` provide no pattern for the bare phrase *N* `catalog rows`. **The class is wider than a
   decomposition** — the escaping lines include a value in a backticked shell command, a value in a
   parenthetical and a value in ordinary prose, no operator anywhere near them — which is why Class 1's
   sweep is keyed on values. **Consequence:** the gate exits 0 reporting that every stated count agrees
   while its own corpus holds values it never read. **Three grades of evidence, kept apart.** First-hand
   this session: the regex reading above; the value sweep run over the walk `:145–196` defines; and a
   replay of the `CLAIMS` array, parsed out of the script rather than retyped, over the lines that sweep
   returns, each alone and each joined with either neighbour, matching none. Reported by the cycle-6 gate
   and **not** re-run here: the full-corpus `CLAIMS` replay that first enumerated that line set. Reported
   by the cycle-4 gate and **not** re-run here: the landing simulation, and the operand mutation that
   left the gate at exit 0. **Owner: the work owner** — the fix is a pattern addition plus the scope
   widening Open Item 3 also needs, and this SPEC edits no file under `tests/`. **Class: mechanism** —
   it decides what the next skill addition may miss.

### Figures

**No measured quantity is asserted anywhere in this SPEC.** No node count, bench size, payload size,
timing, line count, skill count, suite count, roster length or file count appears above — including in
the worked examples, the inventory and the acceptance criteria. Where a quantity would have been the
natural way to say something, the **derivation** is given and the file that owns it is cited instead:
the skill count is `tests/canonical/test-doc-counts.sh:44`'s `find` and `skill-counts.mjs`'s
`deriveSkillCounts`, the surfaces needing a count edit are "the `ASSERTIONS` entries at `:65–95` whose
needle interpolates `${SKILLS}`" plus whatever `check-skill-counts.mjs` reports plus whatever D4 Class
1's **value** sweep finds in that gate's corpus, its needles derived from `--list`, the profile set is
"every profile `run_generator.py:24` enumerates from `profiles/*.toml`", the template set is
"the file tree at feature-007 SPEC.md`:1540–1548`", and the curated roster is `SKILL_GROUPS` membership
as `gen-reference.test.mjs:165` derives it. The transform-trigger list in D3
is enumerated in full **per root** and declared authoritative **as a list, not as a length**, per Q19.
Withdrawn figures — the delivery-001 bench and the voided A-5 KB figure — appear nowhere, and no
assertion here rests on either. Two kinds of statement that could be mistaken for measurements are
neither: **line numbers** are locations, disproved by opening the file rather than by re-measuring; and
the "this suite passes on the branch as it stands" claims (D4 Class 1, CR14) and the
universal negatives D1, D3 and D5 rest on — no tracked `.yml` and no `generated-files.txt` CR byte, no
canonical `SKILL.md` declaring `context:` or `agent:` — are **pass/fail statuses** re-checkable with one
command, stated without the assertion counts those runs printed, exactly the externally-owned quantity
that goes stale in a document.
