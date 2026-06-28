# State: KB-DELTA

KB-DELTA is a lightweight, drift-focused **re-discovery**: you (the agent)
autonomously inspect the actual repository content against what the Knowledge
Base claims, find what has drifted, and drive a targeted re-approval through
`/aid-discover`'s existing gate. Detecting and scoping the drift is **analysis
you perform**, informed by a **deterministic per-doc suspect pre-pass** (f007
`kb-freshness-check.sh`) that prioritizes which docs to re-examine first and
supplies a fast no-drift exit. No doc is skipped -- a `current` verdict proves
only source-ancestry, not summary-correctness (AC1: subtly-wrong-all-along).

> Cross-delivery reuse: Steps 1-2 consume task-040 (delivery-007, f007)
> `kb-freshness-check.sh` per-doc suspect verdicts. The closure re-verify
> (below) consumes task-008 (delivery-001, f004) `closure-check.sh` oracle.
> The boundary realized here is recorded in task-053 (this delivery,
> `pipeline-contracts.md`).

It is entered after PREFLIGHT succeeds, when `**KB Stage:**` is absent / `-` /
`stalled` / `running` (resume rows 1, 3) and `**Mode:** full` (the default --
not `cleanup-only`). On first entry you run Steps 1-4 (inspect + scope +
delegate); a resume after the user acts on the synthesized Q&A re-enters and
runs Steps 5-6 (read-back + gate). Resume is disk-driven: read
`.aid/knowledge/STATE.md` for the synthesized entry's `**Status:**` and for a
fresh `**User Approved:**` to know which half to run.

WARN **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.** Do NOT rely on memory from a
previous run. Always read the actual files on disk.

---

## On entry -- write run-state + ensure branch

`<STATE_FILE>` is the project-level run-state file resolved by `SKILL.md S State
Detection` (`.aid/.temp/HOUSEKEEP_STATE_<ts>.md`; created on first write). Write
through `housekeep-state.sh` (never hand-edit `## Housekeep Status`):

```bash
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "State" --value "KB-DELTA"
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "running"
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Last Run" \
    --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

KB-DELTA is the first stage to write, so ensure the `aid/housekeep-*` branch
exists, then record it:

```bash
bash .cursor/aid/scripts/housekeep/branch-commit.sh \
    --ensure-branch --slug "$(date +%Y-%m-%d)"
BRANCH=$(git rev-parse --abbrev-ref HEAD)
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Branch" --value "$BRANCH"
```

Print the `[State: KB-DELTA]` banner from `SKILL.md S State Detection`.

---

## Step 1 -- Deterministic suspect pre-pass (f007); optionally refresh git

Optionally bring git up to date so the local graph is current before the check:

```bash
git fetch origin master 2>/dev/null || true
```

- **Fetch succeeded** -- the local graph reflects origin/master. The `git fetch`
  is a convenience; the freshness check uses the local graph regardless.
- **Fetch failed (offline)** -- say so plainly and proceed. There is **no hard
  offline gate**: `kb-freshness-check.sh` uses pure local git plumbing (no
  network), so the suspect pre-pass runs against the local graph. Do NOT pause.

Now run the per-doc freshness check (task-040/f007) to capture the commit-graph-
exact set of drifted docs and their drifted sources:

```bash
SUSPECT_TSV=".aid/.temp/kb-freshness-$$.tsv"
bash .cursor/aid/scripts/kb/kb-freshness-check.sh \
    --root .aid/knowledge --format tsv > "$SUSPECT_TSV"
# TSV columns (f007): doc-relpath | verdict | approved_at_commit |
#                     n_current | n_suspect | n_unknown | suspect_sources_csv
# verdict in {current, suspect, unknown}
```

Parse the TSV to separate docs by verdict:

- **suspect** rows: docs whose `sources:` changed after their
  `approved_at_commit:` baseline (commit-graph-exact drift signal). These are
  the **priority re-review set**; `suspect_sources_csv` names which source(s)
  drifted each doc -- start the content review there.
- **unknown** rows: docs with no approved baseline (f011 unstamped or untracked
  sources). No baseline to clear -- treat as un-cleared.
- **current** rows: docs whose declared `sources:` are at-or-before the baseline.
  A `current` verdict proves source-ancestry only, NOT summary-correctness. Still
  content-reviewed at lower priority (Tier 2 below) -- brownfield only (see
  source-routing carve below).

**Source-routing carve (NFR-5).** For each `current`-verdict doc, also read its
`source` frontmatter field using the same `fm_scalar` accessor pattern
`kb-freshness-check.sh` uses (lines 143-156):

    DOC_SOURCE=$(fm_scalar "$doc" "source")

Separate the current-verdict docs by source value:

- `source: forward-authored` -> **Conformance Lane** (below). These docs appear as
  `current` in the TSV because `kb-freshness-check.sh` short-circuits the source-
  drift check for design-authoritative docs (the design is the contract; no code
  file drifts it). Do NOT route these to the Tier-2 update-the-doc set.
- `source: hand-authored`, `source: generated`, or absent -> brownfield review path
  (Tier 1 / Tier 2 below); behavior unchanged.

If no `.aid/knowledge/*.md` has `source: forward-authored`, the Conformance Lane is a
no-op and KB-DELTA proceeds exactly as today.

The git-date range from `**Last KB Review:**` **is no longer the scoping
boundary**. The suspect pre-pass replaces it as the cheap, deterministic drift
signal. You are **not limited to suspect docs** -- proceed to Step 2 to review
all docs.

## Step 2 -- Two-tier whole-KB content review; find drift (AC1, f010 FR-33)

Review the entire KB in two tiers. Both tiers are always executed -- the verdict
sets **priority**, never a skip gate.

**Tier 1 -- Priority (suspect docs, definite drift).**
For each `suspect` doc (from Step 1), read the doc and each entry in its
`suspect_sources_csv`. Ask: *does what this doc asserts still match the repo
state in those changed sources?* Plan the correction: what specifically drifted
and what change is needed. This is the precise, source-keyed drift signal -- the
definite/priority re-review set with an exact pointer to where drift occurred.

Common patterns to look for:

- Skills/scripts/agents added, removed, or renamed since the doc's baseline
  (`architecture.md`, `module-map.md`, `feature-inventory.md`,
  `pipeline-contracts.md`).
- Contracts, schemas, or templates that changed (`pipeline-contracts.md`,
  `schemas.md`).
- Test suites added or removed (`test-landscape.md`).
- Setup or infra changes (`infrastructure.md`).
- Stale counts, file lists, or anchors that no longer resolve.

**Tier 2 -- Retained whole-KB content re-review (preserves AC1, brownfield only).**
After the Tier 1 suspect docs, content-review the remaining brownfield docs --
`unknown` docs next (no baseline cleared), then `current` docs whose `source` is
`hand-authored` or absent. `source: forward-authored` docs are excluded from this
tier: routing a design-authoritative doc through the update-the-doc path would
reconcile in the NFR-5-forbidden doc<-code direction. Confirming KB-DELTA's routine
scope-refresh prompt (Step 3) for a forward-authored doc must NEVER be reachable --
it would ask "refresh this doc?" and overwrite the design with as-built. Forward-
authored docs are handled exclusively in the Conformance Lane below. For the
remaining brownfield docs, ask: *does what this doc asserts still match the repo?*
A `current` verdict proves only that the declared `sources:` have not moved since
approval; it does **not** prove the doc's *summary* was ever correct. A doc can be
subtly-wrong-at-approval with stable `sources:` -- the exact AC1 "subtly-wrong-all-
along" case. No brownfield doc is skipped. Tier 2 is why KB-DELTA is the
**broad/global/periodic** skill vs `aid-update-kb`'s targeted speed.

**Result.** Collect the brownfield drift list across both tiers:

- Suspect docs that confirmed drift (Tier 1 hit): note `suspect_sources_csv` as
  the flagging signal.
- Any unknown/brownfield-current doc whose content review found a summary that no
  longer matches reality (Tier 2 hit): note "content drift (current-verdict doc --
  AC1 catch)" as the flagging signal.

`source: forward-authored` docs are NOT in this list -- they are handled in the
Conformance Lane below.

If the brownfield drift list is **empty** (zero suspect docs AND the brownfield
whole-KB content review found nothing), proceed to the **Conformance Lane** below.
The no-drift exit fires only when BOTH the brownfield lane and the Conformance Lane
report no findings. If the brownfield drift list is **non-empty**, evaluate the
Conformance Lane too (any findings are handled in the Conformance Lane's own
reconciliation flow), then continue to Step 3.

---

## Conformance Lane -- forward-authored docs (NFR-5 carve, feature-005)

### Purpose and routing

This lane handles `.aid/knowledge/*.md` docs with `source: forward-authored` in their
frontmatter -- the greenfield design-authoritative seed docs authored by feature-003.
The relationship is the INVERSE of KB-DELTA's normal doc<-code direction:

| Doc type | Authority direction | KB-DELTA lane |
|----------|---------------------|---------------|
| `source: hand-authored` or absent | code is truth; doc describes it | Tier-2 update-the-doc (doc<-code) |
| `source: forward-authored` | doc is the design contract | Conformance Lane (code->design, flag-not-overwrite) |

The check direction is code->design: when as-built code diverges from a forward-authored
design doc, the divergence is flagged for human reconciliation. The design doc is never
auto-overwritten by the check.

**NFR-5 carve -- Step 3 is never reachable for a forward-authored doc.** Routing a
forward-authored doc through KB-DELTA's routine scope-refresh prompt (Step 3 / "confirm --
refresh this scope") would overwrite the design with as-built -- the exact NFR-5-forbidden
doc<-code direction. The Conformance Lane is the ONLY path for these docs; the Step 3
scope-refresh / update-the-doc prompt is unreachable for them by construction.

**Freshness tie.** f007 (`kb-freshness-check.sh`) already folds `forward-authored` docs to
verdict `current` via an explicit short-circuit: source-drift detection does not apply
because the design is the contract, not a derivative of code files. The source-routing
carve in Step 1 above reads `source` with `fm_scalar` and separates these `current`-verdict
docs INTO this lane, so the two mechanisms agree -- housekeep never treats a forward-authored
doc as stale-by-code-drift.

**Scoping accessor.** Uses the existing `fm_scalar "$doc" "source"` pattern (lines 143-156
of `kb-freshness-check.sh`); no new schema, enum, or frontmatter field is added (C-1). The
carve is entirely scoped by the `source: forward-authored` marker that feature-003 ships.

**No-op when empty.** If no `.aid/knowledge/*.md` has `source: forward-authored`, this lane
has nothing to check and is a no-op. KB-DELTA then proceeds as today: if the brownfield drift
list (Step 2) is also empty, the no-drift exit fires; if it is non-empty, Step 3 handles the
brownfield scope-confirm.

---

### CL-Step 1 -- Extract-and-diff mechanism

#### Sub-step 1 -- Scope by the marker (deterministic)

Enumerate the forward-authored set: every `.aid/knowledge/*.md` whose frontmatter `source`
field equals `forward-authored`. Use the `fm_scalar` accessor from `kb-freshness-check.sh`
(lines 143-156) -- the same function the source-routing carve in Step 1 already uses:

    DOC_SOURCE=$(fm_scalar "$doc" "source")

Iterate over `.aid/knowledge/*.md`; collect each doc where `DOC_SOURCE` is
`forward-authored` into `FA_DOCS`. For each doc in `FA_DOCS`, read the declared concern
dimension ID from its `tags:` frontmatter field. The concern ID is the spine dimension tag
matching the pattern `C[0-9]` or the letter `D` (e.g. `C0`, `C1`, `C3`, `C4`, `D`).
Record the pair `(doc-path, concern-id)` for every in-scope doc. Collect the concern IDs
across all in-scope docs into `FA_CONCERNS`.

If `FA_DOCS` is empty -- no forward-authored docs exist in this repo -- skip Sub-steps 2
through 4 and proceed directly to the "Conformance Lane -- no findings" path. The lane is a
no-op when no greenfield seed has been authored.

#### Sub-step 2 -- Shadow extraction (parameterized subagent reuse)

Dispatch the aid-discover extraction subagents with the shadow root as the KB-doc
destination. The safety invariant -- `.aid/knowledge/` is NEVER written by this step -- is
enforced BY CONSTRUCTION via the `output_root` dispatch parameter (task-028):

    output_root=.aid/.temp/conformance/as-built/

Every extraction subagent in `.cursor/skills/aid-discover/references/agent-prompts.md`
writes its KB documents only to the `output_root` it receives (see `## Dispatch Parameter:
output_root`; default `.aid/knowledge/`). Passing a throwaway root makes `.aid/knowledge/`
structurally unreachable from this step. No convention or discipline is needed to protect
the real KB tree; the parameter enforces the write boundary mechanically.

Ensure the shadow root exists before dispatching:

```bash
mkdir -p .aid/.temp/conformance/as-built/
```

**Agent-set scoping (concern-intersection rule).** Each deep-dive subagent owns a fixed
concern bundle. Dispatch only the agents whose bundle intersects `FA_CONCERNS`:

- **Scout** -- always dispatched first (serial, foundation pass). Produces
  `project-structure.md` and `external-sources.md` in the shadow root; these are consumed
  by the deep-dive agents and are NOT included in the diff set.
- **Architect** -- dispatch if `FA_CONCERNS` contains C0, C1, or D. The Architect bundle
  produces `technology-stack.md` (C0), `architecture.md` (C1), and `decisions.md` (D) in
  the shadow root, along with other docs out of scope for this diff.
  **decisions.md prompt extension (D concern):** The Architect base prompt
  (`agent-prompts.md ## Architect`) does not statically list `decisions.md`. When D is in
  `FA_CONCERNS`, extend the Architect's prompt by appending (following the Custom-Doc
  Runtime Extension mechanism in `agent-prompts.md ## Custom-Doc Runtime Extension (Section 2.6)`):
  > Also produce `{output_root}/decisions.md`. Enumerate realized architectural decisions
  > from the codebase: for each technology choice, pattern, or structural constraint the
  > code actually implements, record a decision entry with: decision title, chosen
  > alternative as implemented, other options if inferable from code comments or docs (omit
  > the field if unknown), and available rationale from the codebase (flag
  > `rationale not in code` when absent from the repo). This is as-built decision evidence
  > only -- do not fabricate rationale not grounded in the artifacts.
- **Analyst** -- dispatch if `FA_CONCERNS` contains C3. The Analyst bundle produces
  `coding-standards.md` (C3) in the shadow root, along with other docs out of scope.
- **Integrator** -- dispatch if `FA_CONCERNS` contains C4. The Integrator bundle produces
  `domain-glossary.md` (C4) in the shadow root, along with other docs out of scope.
- **Quality** -- not dispatched; its bundle (C6, C7, C8) does not intersect the seed
  concern set (C0/C1/C3/C4/D).

Read each dispatched agent's full prompt from `.cursor/skills/aid-discover/references/
agent-prompts.md` (Scout / Architect / Analyst / Integrator sections). Pass the shadow
root as the `output_root` parameter. Pass the foundation reference block as follows:
`project-index` (`.aid/generated/project-index.md`) and `candidate-concepts`
(`.aid/generated/candidate-concepts.md`) remain at their fixed generated paths. The two
Scout-produced foundation docs MUST be redirected to the shadow root:
`project-structure` = `{output_root}/project-structure.md` and
`external-sources` = `{output_root}/external-sources.md`. Scout wrote these into the
shadow root in the serial pass above; pointing at the real `.aid/knowledge/` path would
reference absent or stale foundation docs and degrade as-built diff fidelity.
Dispatch under `SKILL.md S Dispatch Protocol (L1+L2+L3)`: Scout serial first, then
concerned deep-dive agents in parallel.

**Side-output note.** The `output_root` parameter governs KB-doc destination only.
Architect and Integrator also write to `.aid/generated/` (side-output: `candidate-
concepts.md`, `spine-todo.md`). That path is NOT governed by `output_root` and is always
`.aid/generated/`. The conformance lane ignores all `.aid/generated/` side-output; only KB
docs in the shadow root feed the diff.

**Keep-only-in-scope filter.** After all dispatched agents complete, scan the shadow root
for produced KB docs. Retain ONLY the docs matching in-scope concern IDs from `FA_CONCERNS`:

| Concern in FA_CONCERNS | Retain from shadow root |
|------------------------|-------------------------|
| C0 | technology-stack.md |
| C1 | architecture.md |
| C3 | coding-standards.md |
| C4 | domain-glossary.md |
| D  | decisions.md |

Discard all other docs the bundles produced (e.g. `module-map.md`, `schemas.md`,
`pipeline-contracts.md`, `integration-map.md`, `test-landscape.md`, `tech-debt.md`,
`infrastructure.md`). Discard `project-structure.md` and `external-sources.md` (Scout
foundation docs; not diffed). Discard all `.aid/generated/` side-output.

**C4 term universe.** When C4 is in `FA_CONCERNS`, also run the deterministic coined-term
harvest over the current codebase to produce the ranked as-built term list. The `--top`
value is the C4 altitude threshold (default 60; tunable at task-034 DoD V5):

```bash
bash .cursor/aid/scripts/kb/harvest-coined-terms.sh \
    --root . \
    --output .aid/.temp/conformance/as-built-terms.md \
    --top ${CONFORMANCE_C4_TOP:-60}
```

This ranked list is the "undeclared load-bearing term" signal source and feeds the altitude
filter in Sub-step 4.

#### Sub-step 3 -- Concern-keyed structured diff (agent-driven, at seed altitude)

For each concern ID in `FA_CONCERNS`, pair the forward-authored seed doc (in
`.aid/knowledge/`) with its shadow as-built counterpart (in `.aid/.temp/conformance/as-
built/`) by concern ID -- same concern ID maps to the same filename in the seed model (see
the retain table in Sub-step 2). Dispatch an `aid-architect`/`aid-reviewer`-class judgment
subagent to compute the element-level diff -- NOT a textual-line diff -- at the seed's
declared altitude. This is the same tier of judgment KB-DELTA's Tier-2 content review
performs ("does what this doc assert still match the repo?"), applied here in the
code->design direction.

Diff inputs and element targets per concern:

**C4 -- domain-glossary.md.** Compare the seed glossary's declared term headings against:
(a) the harvested as-built terms in `.aid/.temp/conformance/as-built-terms.md` (top-N
ranked list) and (b) the `closure-check.sh` output for the shadow as-built
`domain-glossary.md`:

```bash
bash .cursor/aid/scripts/kb/closure-check.sh \
    --output-a .aid/.temp/conformance/closure-a.md \
    --output-b .aid/.temp/conformance/closure-b.md
```

Feed `closure-a.md` (ungrounded as-built terms) into the classifier. A seed glossary term
that appears below the top-N ranked threshold in the as-built harvest is `design-ahead`. A
top-N as-built term absent from the seed glossary is a candidate `code-ahead` (subject to
the altitude filter in Sub-step 4). A term present in both seed and as-built but with
contradicting meaning or boundary is `contradiction`.

**C1 -- architecture.md.** Compare the seed's declared boundaries, module relationships,
and `## Invariants` entries against the named elements in the shadow `architecture.md`. A
declared invariant or boundary whose as-built realization violates the constraint is
`contradiction`. A new top-level module or boundary named in the shadow `architecture.md`
that the seed never declared is a candidate `code-ahead` (subject to altitude filter). A
declared boundary not yet realized in the as-built code is `design-ahead`.

**C3 -- coding-standards.md.** Compare the seed's declared rules and conventions against
those identified in the shadow `coding-standards.md`. A declared rule the as-built code
consistently contradicts (a pattern that reverses the declared convention, visible across
multiple files) is `contradiction`. A convention adopted pervasively in code and named in
the shadow doc that materially contradicts or augments a seed-declared rule is a candidate
`code-ahead` (subject to altitude filter). A declared rule the code has not yet adopted is
`design-ahead`.

**C0 -- technology-stack.md.** Compare the seed's declared stack entries (language,
runtime, framework, and any TBD or `latest-at-init` version placeholders) against those
identified in the shadow `technology-stack.md`. A declared TBD or `latest-at-init` version
now pinned to a concrete value in the as-built config is `placeholder-resolved`. A stack
element in the as-built that contradicts the declared choice (different language, different
framework than declared) is `contradiction`. A declared stack element not yet present in the
as-built config is `design-ahead`.

**D -- decisions.md.** Compare each recorded decision (chosen alternative, rejected
alternatives) in the seed against the shadow `decisions.md` and the actual code structure.
A decision whose chosen alternative is reflected in the as-built code is conformant (no
finding). A decision whose rejected alternative is what the code actually implements is
`contradiction`. A decision not yet realized in any as-built code is `design-ahead`.

Collect all element-level deltas into a divergence list. Each entry has the shape:
`concern | element-name | raw-class | evidence`.
The evidence field is the seed excerpt, the as-built excerpt, or the harvest reference that
grounds the finding.

#### Sub-step 4 -- Classify + altitude filter (false-positive control)

**Assign canonical class.** Confirm or refine the raw class from Sub-step 3 using the four
canonical classes:

    design-ahead         -- design declares X; code has not built it yet; expected (forward-
                            authoring leads by design); NOT a finding; dropped from output
    placeholder-resolved -- a declared TBD / latest-at-init value is now concretely pinned
                            in the as-built code; low-friction flag ("design left this open;
                            code pins it to <X> -- adopt into the design?")
    code-ahead           -- as-built code introduces a load-bearing element at seed altitude
                            that the design never declared
    contradiction        -- as-built code violates or reverses a declared invariant,
                            definition boundary, convention rule, or decision

**Drop design-ahead.** Remove all `design-ahead` rows from the divergence list.
Forward-authoring leads; unbuilt items are the normal and expected state for a design-first
project. They are not surfaced to the user or to the reconciliation flow.

**Carry forward.** Retain `placeholder-resolved`, `code-ahead`, and `contradiction` rows.
This is the classified divergence set that CL-Step 2 (task-031) consumes.

**Seed-altitude filter (tunable knob; final calibration at task-034 DoD V5).** After
assigning classes, suppress any `code-ahead` row whose element is below the seed's declared
altitude. The filter is expressed as per-concern altitude gates with configurable thresholds
-- NOT hard constants -- so task-034 can calibrate against fixtures without re-authoring
this prose:

- **C4:** a `code-ahead` term qualifies only if it appears within the top-N ranked terms
  from the harvest (`--top N`; default N=60, the same value passed to `harvest-coined-
  terms.sh` in Sub-step 2). A term outside the top-N cutoff is below seed altitude and is
  suppressed. The threshold N is the C4 altitude knob.
- **C1:** a `code-ahead` boundary or module qualifies only if it is named as a top-level
  structural entry in the shadow `architecture.md`'s primary structure section (not an
  unnamed helper sub-module or implementation-only sub-directory). The "top-level" boundary
  criterion is the C1 altitude knob.
- **C3:** a `code-ahead` convention qualifies only if it recurs across at least M files at
  the same coding convention site (default M=3). A one-off pattern in a single file is
  below seed altitude and is suppressed. The threshold M is the C3 altitude knob.
- **C0:** all `placeholder-resolved` deltas qualify (the seed explicitly left the value
  open; any concrete resolution is at seed altitude by definition). No altitude filter
  applied for C0.
- **D:** all `contradiction` deltas qualify (recorded decisions are by definition at seed
  altitude). No altitude filter applied for D.

After applying the altitude filter, the filtered divergence set is final. If it is empty
(all deltas were `design-ahead` or suppressed as sub-altitude), proceed to "Conformance
Lane -- no findings" below -- the check writes nothing to `.aid/knowledge/` and nothing
persists in `.aid/.temp/conformance/` beyond the transient shadow files.

If the filtered set is non-empty, CL-Step 2 (task-031's reconciliation flow) consumes it.
Retain the shadow root and transient files under `.aid/.temp/conformance/` until CL-Step 2
completes (the evidence must be available for the Required Q&A entries and the present-the-
choice gate). Clean up the shadow tree after CL-Step 2 finishes:

```bash
rm -rf .aid/.temp/conformance/as-built/
rm -f  .aid/.temp/conformance/as-built-terms.md \
       .aid/.temp/conformance/closure-a.md \
       .aid/.temp/conformance/closure-b.md
```

---

### CL-Step 2 -- Reconciliation flow

**Invariant -- flag, never overwrite.** This step NEVER writes `.aid/knowledge/*.md`. Its
only outputs are the Required Q&A entry (Sub-step 2b) and, for "Fix the code" choices, a
code task. The forward-authored doc's bytes, its `source: forward-authored` marker, and
its f007 `current` verdict are UNCHANGED by this step. The default for every unresolved
divergence is to FLAG it for the human, never to silently change the design. Authority
stays design->code until the human explicitly reconciles.

#### Sub-step 2a -- Present the divergence set (PAUSE-FOR-USER-DECISION)

Present the classified divergence set from CL-Step 1, grouped by class, and pause for the
user to supply a per-item choice (NFR3 transparency -- no silent KB edits). State that the
design stays authoritative until reconciled:

```
Code<->design conformance: <N> divergence(s) between forward-authored design and as-built code.
Authority stays design->code -- no design doc is modified until you choose.

[placeholder-resolved] -- declared TBD/latest-at-init value now pinned in code:
  <i>. <concern> | <element>
      Design declares: "<seed-excerpt>"
      Code pins it to: "<as-built-excerpt>"
      Suggested [3]: the design left this open; the code's pin is low-friction to adopt or defer.
      [1] Evolve the design  -- adopt the pinned value into the design doc (deliberate update)
      [2] Fix the code       -- raise a code task; design doc held untouched
      [3] Accept / defer     -- record as known divergence; revisit later

[code-ahead] -- load-bearing element at seed altitude in code, not declared in design:
  <j>. <concern> | <element>
      Code introduces: "<as-built-excerpt>"
      Not declared in design.
      Suggested [2]: the design is the contract; if this element should exist, declare it first.
      [1] Evolve the design  -- add the element to the design doc (deliberate declaration)
      [2] Fix the code       -- raise a code task to align code to design; doc untouched
      [3] Accept / defer     -- record as known divergence; revisit later

[contradiction] -- code violates or reverses a declared invariant, rule, or decision:
  <k>. <concern> | <element>
      Design: "<seed-excerpt>"
      Code:   "<as-built-excerpt>"
      Suggested [2]: authority stays design->code; the code must conform unless intent changed.
      [1] Evolve the design  -- explicitly update the design to reflect the code's intent
      [2] Fix the code       -- raise a code task; design stays authoritative; doc untouched
      [3] Accept / defer     -- record as known divergence; revisit later

For each item, state your choice: e.g. "<i>:[3] <j>:[2] <k>:[1]"
```

- `[1] Evolve the design` -- the ONLY path by which a forward-authored doc is edited from
  as-built code, and only with explicit human approval (Sub-step 2c). Suggested rationale:
  the divergence reflects a deliberate decision made during execution -- the design intent
  has genuinely changed and the doc should record it.
- `[2] Fix the code` -- the design IS still the intent; the code deviated. A code task is
  raised; the design doc is held untouched. Suggested for contradictions and code-ahead items
  where the declared constraint should be enforced.
- `[3] Accept / defer` -- records the divergence as a known delta for later reconciliation.
  Suggested for low-friction `placeholder-resolved` items where neither side is wrong -- the
  design left the value open and the code's concrete choice is uncontroversial.

If the user defers the entire set (all `[3]`), all forward-authored docs remain byte-
unchanged. The lane records the full set in the Q&A entry and proceeds to cleanup.

#### Sub-step 2b -- Write Required Q&A entry (Style A)

After the user supplies per-item choices, append one Q&A entry to
`.aid/knowledge/STATE.md ## Q&A (Pending)` (Style A -- `### Q{N}` + sub-bullets,
`coding-standards.md S12`). `{N}` is the next integer after the highest existing
`### Q{N}` (`grep '### Q[0-9]\+'`). Populate with the full divergence set + per-item
choices:

```markdown
### Q{N}
- **Category:** Housekeep / Conformance Reconciliation
- **Impact:** Required
- **Status:** Pending
- **Context:** /aid-housekeep conformance check found <N> divergence(s) between
  forward-authored design doc(s) and as-built code:
    <i>. <concern> | <element> [placeholder-resolved] -- <evidence-excerpt>
         User choice: [<choice>]
    <j>. <concern> | <element> [code-ahead] -- <evidence-excerpt>
         User choice: [<choice>]
  Forward-authored design docs are byte-unchanged. The check flagged; it did not reconcile.
- **Suggested:** Apply each user choice: "[1] Evolve the design" items -> invoke
  /aid-discover targeted re-entry naming that doc (the only approved edit path for a
  forward-authored doc); "[2] Fix the code" items -> raise a code task per item;
  "[3] Accept / defer" items -> already recorded above as known divergences, no action.
```

`**Impact:** Required` is what routes `/aid-discover`'s targeted re-entry to the named
doc(s) for any "[1] Evolve the design" items -- the same `Impact: Required` ->
targeted-re-entry path KB-DELTA Step 4 already drives (Step 4 / `state-generate.md`
targeted re-entry state). You do not resolve owners yourself; `/aid-discover`'s re-entry
resolves each named doc to its owning sub-agent via its `owns-<agent>` accessor.

The entry carries the reconciliation record. It never auto-applies an edit. Until the
entry is actioned, every forward-authored doc is byte-unchanged.

#### Sub-step 2c -- Apply per-item choices (human-gated)

For each item, apply the user's choice exactly -- no auto-resolution, no default rewrite:

- **[1] Evolve the design:** Invoke `/aid-discover` targeted re-entry naming the affected
  forward-authored doc. This is the ONLY path by which a forward-authored doc is edited
  from as-built code, and only after the user has explicitly chosen this option. The
  re-entry drives REVIEW -> Q-AND-A -> FIX -> APPROVAL; the doc is updated only after
  APPROVAL lands. Until APPROVAL the doc is byte-unchanged. Because sub-agents run,
  this dispatch operates under `SKILL.md S Dispatch Protocol (L1+L2+L3)` (inherit -- do
  not re-implement). Whether the doc then sheds the `source: forward-authored` marker
  (converting to `source: hand-authored`) is a separate human call, out of this check's
  scope.

- **[2] Fix the code:** Raise one code task per item. Record the divergence description
  (concern, element, evidence) as the task's scope. The forward-authored doc is untouched;
  authority stays design->code. The task enters the project pipeline via the normal task
  mechanism.

- **[3] Accept / defer:** The divergence is already recorded in the Q&A entry (Sub-step
  2b). No doc edit. No code task. The item is a known accepted delta; the conformance lane
  will re-surface it on the next /aid-housekeep run if the relevant doc or code changes.

Until all "[1] Evolve the design" targeted re-entries reach APPROVAL, every affected
forward-authored doc is byte-unchanged. The check has flagged; it has not reconciled.
Authority stays design->code.

#### Sub-step 2d -- Shadow tree cleanup

After all per-item choices are applied (or deferred), clean up the transient shadow files
CL-Step 1 retained until this point (the evidence is now recorded in the Q&A entry; the
shadow tree is no longer required):

```bash
rm -rf .aid/.temp/conformance/as-built/
rm -f  .aid/.temp/conformance/as-built-terms.md \
       .aid/.temp/conformance/closure-a.md \
       .aid/.temp/conformance/closure-b.md
```

The Conformance Lane is complete. If the brownfield drift list (Step 2) is non-empty,
continue to **Step 3** (the brownfield scope-confirm handles those docs). If the brownfield
drift list is empty, proceed to the **no-drift exit**.

---

### Conformance Lane -- no findings

When the forward-authored set is empty (no-op path) OR the extract-and-diff (CL-Step 1)
produces no `placeholder-resolved`, `code-ahead`, or `contradiction` deltas:

- The check writes nothing to `.aid/knowledge/` and nothing to `.aid/.temp/conformance/`.
- Print: `Conformance check: no divergence found between forward-authored design and as-built code.`
- If the brownfield drift list (Step 2) is also empty -> **no-drift exit** (below).
- If the brownfield drift list is non-empty -> continue to **Step 3** (the brownfield
  scope-confirm handles those docs; the Conformance Lane is complete with no findings).

---

## Step 3 -- Propose the scope; confirm-and-adjust (AC2, NFR3)

Present the affected docs annotated by the flagging signal, and pause for the
user to confirm or adjust before any KB change (NFR3 transparency -- no silent
KB edits):

```
KB drift detected (signal: kb-freshness-check suspect verdicts, prioritizing a whole-KB content review).
Proposed KB refresh scope:
  architecture.md   -- suspect: <suspect_sources_csv> drifted
  module-map.md     -- suspect: <suspect_sources_csv> drifted
  test-landscape.md -- content drift (current-verdict doc; summary no longer matches repo -- AC1 catch)
[1] Confirm -- refresh this scope
[2] Adjust  -- add/remove docs: ___
[3] Cancel  -- stall this stage
```

- `[1]` -> carry the confirmed doc list to Step 4.
- `[2]` -> the user adds or drops docs; recompute the confirmed list.
- `[3]` -> write `**KB Stage:** stalled` + `**Stall Reason:** KB refresh scope
  cancelled` and PAUSE (stalled exit below).

## Step 4 -- Synthesize an `Impact: Required` Q&A entry + invoke `/aid-discover` (AC3)

You do **not** duplicate the review/approval machinery -- you reuse
`/aid-discover`'s **existing** Targeted Discovery re-entry
(`.cursor/skills/aid-discover/SKILL.md S Targeted Discovery (Re-entry)`),
which runs *only* the affected sub-agents when a Pending Q&A entry with
`**Impact:** Required` names what needs refreshing (entered from `/aid-discover`'s
State Detection State 3). Drive it by **writing exactly such an entry**.

Append one Q&A entry to `.aid/knowledge/STATE.md` `## Q&A (Pending)` in the
canonical Style A schema (`### Q{N}` + sub-bullets -- `coding-standards.md S12`).
`{N}` is the next integer after the highest existing `### Q{N}`
(`grep '### Q[0-9]\+'`). Populate it with the user-confirmed scope from Step 3:

```markdown
### Q{N}
- **Category:** Housekeep / KB Delta Refresh
- **Impact:** Required
- **Status:** Pending
- **Context:** /aid-housekeep reconciled the repo against the KB and found drift in:
  <architecture.md, module-map.md, ...>. Corrections: <one line per doc>. These docs
  need targeted re-discovery.
- **Suggested:** Re-run the sub-agents that own these docs (targeted re-discovery),
  then REVIEW -> APPROVAL.
```

`**Impact:** Required` is what forces `/aid-discover` into Q-AND-A -> targeted
re-entry regardless of the current grade. `/aid-discover`'s re-entry resolves
each named doc to its owning sub-agent via its own `owns-<agent>` accessor -- you
do not resolve owners yourself.

The targeted re-entry of `/aid-discover` also (re)runs f004's harvest over the
staged KB -- the fresh `candidate-concepts.md` it produces will be consumed by
the closure re-verify step after the KB edits land. Record the run start time
so the closure step can verify the harvest is fresh:

```bash
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "KB-DELTA Run Start" \
    --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

Then invoke `/aid-discover` to drive its state machine (targeted re-entry ->
REVIEW -> Q-AND-A -> FIX -> APPROVAL). Because sub-agents run, this dispatch
operates **under `SKILL.md S Dispatch Protocol (L1+L2+L3)`** (heartbeat
pre-create via `read-setting.sh --path traceability.heartbeat_interval
--default 1`, three armed L2 timers as separate background dispatches,
Calibration-Log writeback). Inherit that protocol -- do not re-implement it. Take
the ETA band from `.cursor/aid/templates/rough-time-hints.md` for the
discovery-subagent class.

After invoking, the stage pauses for `/aid-discover` to settle; the re-entry
(below) reads back the result.

---

## Step 5 -- Read back: did a fresh approval land? (re-entry)

On re-entry, re-read `.aid/knowledge/STATE.md` (filesystem = source of truth):

- `/aid-discover`'s targeted re-entry flips the synthesized entry's
  `**Status:**` to `Answered` and resets `**Grade:**` to `Pending`, so a fresh
  REVIEW runs; on APPROVAL it writes `**User Approved:** yes` with a fresh date
  (`aid-discover/references/state-approval.md`).
- Check that `**User Approved:** yes` carries a date **newer than this run's
  start** (`grep -m1 '\*\*User Approved:\*\*'`).

If a fresh approval is present -> Step 6 (passed). If it is missing, declined, or
the grade is still below minimum with no resolution -> the **stalled** exit.

## Step 6 -- Passed: closure re-verify BEFORE commit, then commit and chain

A fresh `**User Approved:** yes` was reached. The staged KB refresh is approved
but **not yet committed**. Before committing, re-verify concept-closure to
ensure the refresh left no native term undefined -- a standing invariant
(FR-34, task-008/f004). This step is inserted BETWEEN the approved KB edits and
the `branch-commit.sh --commit` call.

### Step 6a -- Ensure a fresh candidate-concepts.md

`closure-check.sh` (f004) requires `.aid/generated/candidate-concepts.md` as
its term-universe input. This file is produced by f004's harvest, which the
`/aid-discover` targeted re-entry ran in Step 4. Verify the file exists and is
newer than the `**KB-DELTA Run Start:**` timestamp recorded in Step 4:

```bash
CONCEPTS=".aid/generated/candidate-concepts.md"
RUN_START=$(grep -m1 '\*\*KB-DELTA Run Start:\*\*' <STATE_FILE> | \
    sed 's/.*\*\*KB-DELTA Run Start:\*\* *//')
CONCEPTS_MTIME=$(date -r "$CONCEPTS" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")
```

If `candidate-concepts.md` is absent or its modification time is NOT newer than
`$RUN_START` (stale or predates the staged edits), re-run f004's harvest FIRST
so the term universe matches the staged-but-not-committed KB -- the closure
verdict must never be computed against a stale or absent term universe:

```bash
# Re-run harvest if candidate-concepts.md is stale or absent:
bash .cursor/aid/scripts/kb/harvest-coined-terms.sh \
    --root . \
    --output .aid/generated/candidate-concepts.md
```

The closure verdict is **never** computed against a stale/absent term universe.
No new script -- this reuses f004's harvest + `closure-check.sh` (task-008/f004).

### Step 6b -- Run closure-check.sh

```bash
CLOSURE_OUT=".aid/.temp/closure-verify-a.md"
bash .cursor/aid/scripts/kb/closure-check.sh \
    --output-a "$CLOSURE_OUT" \
    --output-b .aid/.temp/closure-verify-b.md
```

Read `$CLOSURE_OUT` (output (a) -- ungrounded/un-closed concept set). An empty
table body (no data rows beyond the header) means closure is intact. A non-empty
table body means the refresh introduced or exposed an undefined native term.

Clean up transients after reading:

```bash
rm -f .aid/.temp/closure-verify-a.md \
      .aid/.temp/closure-verify-b.md
```

### Step 6c -- Closure intact: mark, commit, chain

Closure is intact (output (a) is empty). Write the gate fields and commit the
refreshed KB:

```bash
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Closure" --value "verified"
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "KB Stage" --value "passed"
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "passed"
bash .cursor/aid/scripts/housekeep/branch-commit.sh \
    --commit --message "chore(housekeep): KB delta refresh [feature-002]" \
    --add .aid/knowledge/
```

**Advance:** CHAIN -> SUMMARY-DELTA.

### Step 6d -- Closure broken: escalate via Q&A + stall (never commit a hole)

Closure is broken (output (a) contains ungrounded term rows). Do NOT commit.
Append one Q&A entry to `.aid/knowledge/STATE.md ## Q&A (Pending)` (Style A;
`### Q{N}` where `{N}` is next after the highest existing `### Q{N}`):

```markdown
### Q{N}
- **Category:** Closure / Standing Invariant Break
- **Impact:** Required
- **Status:** Pending
- **Context:** A KB change by /aid-housekeep (KB-DELTA refresh) left native term(s) undefined
  in the spine: <ungrounded-term @ doc:anchor, ...> (closure-check.sh output (a)). The KB is
  no longer self-contained -- a fresh reader cannot resolve these terms from the spine.
- **Suggested:** Ground each term into domain-glossary.md (a spine entry) via /aid-discover
  targeted re-entry naming domain-glossary.md + the using-doc, then re-verify closure.
```

The `Impact: Required` routes `/aid-discover`'s targeted re-entry to
`domain-glossary.md` (the spine) and the using-doc -- the same escalation
mechanism KB-DELTA Step 4 already uses. No new routing is introduced.

Then take the **stalled exit** (below) with:

```
**Stall Reason:** closure invariant broken -- undefined native term in the staged KB refresh (not committed)
```

The staged KB refresh is **left uncommitted** -- the KB hole is never committed
to the housekeep branch. Re-running `/aid-housekeep` resumes at KB-DELTA; once
the term is grounded and `closure-check.sh` output (a) is empty, the stage
advances and then commits.

---

## Exit -- no drift (AC4)

Step 2 found no brownfield drift: zero suspect docs (Step 1 deterministic check)
AND the brownfield whole-KB content review (Step 2 Tier 2) found nothing wrong.
The Conformance Lane (above) also found no divergences between the forward-authored
design and as-built code (or the forward-authored set is empty). All signals are
clean. Print:

```
KB current -- no drift between the repo and the Knowledge Base; skipping refresh.
```

Then write `**KB Stage:** skipped`, dispatch **no** sub-agents, make **no**
commit (NFR2 idempotent), and do NOT run the closure re-verify step (nothing
changed):

```bash
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "KB Stage" --value "skipped"
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "skipped"
```

**Advance:** CHAIN -> SUMMARY-DELTA.

## Exit -- stalled (scope cancelled, re-approval declined, or closure broken)

Reached when Step 3 was cancelled (`[3]`), Step 5 found no fresh approval
(declined / still below grade with no resolution), or Step 6d detected a
closure invariant break (refresh uncommitted):

```bash
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "KB Stage" --value "stalled"
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "stalled"
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stall Reason" --value "<reason>"
```

Print the resume banner, then PAUSE:

```
[!] /aid-housekeep paused at KB-DELTA -- <reason>.
   Fix: <actionable instruction>.
   Resume: re-run /aid-housekeep -- it will pick up at KB-DELTA (not job 1).
```

**Advance:** PAUSE-FOR-USER-ACTION (re-run resumes at KB-DELTA via `SKILL.md S
State Detection` row 3).
