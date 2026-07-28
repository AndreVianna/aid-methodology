# Source Enumeration By Structural Significance

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.7 (FR-19–FR-24), §2 item 1, §9 (AC-16) | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Gate finding 3 [HIGH] fixed — the `never inferred` rule promoted to a named, citable invariant (`no-inferred-node`, D3) with its enforcement and its consequences for feature-006 and feature-007 stated explicitly | /aid-specify |

## Source

- REQUIREMENTS.md §5.7 (FR-19, FR-20, FR-21, FR-22, FR-23, FR-24)
- REQUIREMENTS.md §2 Problem Statement item 1 (a source concept significant enough to appear
  in the graph but absent from the Knowledge Base is a **defect**, not merely a missing edge —
  this is why enumeration must not be driven by the Knowledge Base)
- REQUIREMENTS.md §4 Out of Scope (no function- or line-level granularity; no enumeration of
  generated/derived trees or vendored code)
- REQUIREMENTS.md §9 (AC-16); feeds the `int:` half of AC-1, which feature-003 validates

**Shared implementation seam with feature-005.** This feature and feature-005 will almost
certainly share **one scanner walk** over the project source: the same traversal that decides
whether an artifact is structurally significant also observes the references, invocations, and
dependency edges feature-005's deterministic pass harvests. These are two specifications over
one mechanism. `/aid-specify` and `/aid-detail` must treat them that way and **must not produce
two competing scanners** — a second independent walk would drift from this one and the two
would disagree about what exists. The split is deliberate: the significance rule is the
highest-risk decision in this work and deserves its own specification, its own reviewer, and
its own acceptance criterion, independent of row production.

**Dependency position.** Not blocked by either RESEARCH feature — enumeration needs no
relation vocabulary and no rendering decision, so it can start immediately. Blocks feature-005
(which needs the node set) and feature-006 (which detects gaps against it).

## Description

The graph's value as a quality signal depends entirely on how the project's own artifacts are
discovered. If they were discovered by following what the Knowledge Base already mentions, then
anything the Knowledge Base failed to capture could never appear — and the single most
important defect this work exists to reveal would be structurally invisible. So the project
source is enumerated on its own terms, independently of the Knowledge Base, and whatever the
Knowledge Base does not account for is surfaced rather than silently absent.

Not every file deserves to be a node. An artifact earns its place by mattering structurally:
because it is an entry point or public surface that others reach through, because something
else depends on it, or because the project's own conventions already treat it as a named unit.
Mere existence on disk is not enough — a graph of every file would be noise, and noise would
bury the signal.

Some things are excluded outright. Mechanically generated and rendered trees are excluded
because they are reproductions of a single source and would multiply every node, and every
reported gap, by the number of renderings. Third-party vendored code is excluded because it is
not the project's to document. And anything the project has explicitly asked to be ignored in
its own settings is excluded, because that is the project's stated intent.

Everything is enumerated at the level of a whole artifact — a script, a skill, a template —
never at the level of individual functions or lines. That keeps the graph legible and keeps
node counts tractable.

Finally, significance is decided by rules wherever it can be, not by opinion. A reported gap
that rests on a judgment call is a gap a reviewer cannot check and may reasonably dismiss. So
qualification arrives with evidence, and the mechanism does not manufacture defects out of
inference alone.

## User Stories

- As a **maintainer/architect**, I want the project's significant artifacts discovered
  independently of what the Knowledge Base says, so that the graph can show me what the
  Knowledge Base missed rather than only confirming what it already claims.
- As a **KB reviewer**, I want an artifact's qualification as significant to rest on a rule with
  checkable evidence, so that I can verify a reported gap instead of taking it on trust.
- As the **AID methodology owner**, I want the significance rule stated explicitly and held to,
  so that it cannot be quietly loosened until inconvenient gaps disappear.
- As a **maintainer/architect**, I want generated trees, vendored code, and ignored paths kept
  out entirely, so that the graph is not swamped by copies and the gap list is not padded with
  findings I would never act on.

## Priority

Must

## Acceptance Criteria

- [ ] AC-16: Given an enumeration run over the project source, when the resulting node set is
      inspected, then no node originates from a generated or derived tree, from vendored
      third-party code, or from a path matched by the project's ignore list; and no node is
      finer-grained than a whole artifact — none names a function or a line range.
- [ ] Given a source artifact that is an entry point or public surface, is depended upon by
      another artifact, or is a named unit the project's conventions already treat as a unit,
      when enumeration runs, then that artifact appears as a node.
- [ ] Given a source file that satisfies none of the significance conditions, when enumeration
      runs, then it does not appear as a node — file existence alone never qualifies.
- [ ] Given enumeration runs on a project whose Knowledge Base never mentions a particular
      significant artifact, when the node set is produced, then that artifact is nonetheless
      present — proving enumeration is independent of the Knowledge Base and can therefore
      surface the defect described in §2 item 1.
- [ ] Given any node in the enumerated set, when its qualification is examined, then it carries
      rule-based evidence a reviewer can check, and no node qualifies on inference alone.

---

## Technical Specification

### The shared scanner seam (binding on `/aid-detail`)

**This feature owns the walk. Feature-005 consumes its output and never walks the source
itself.**

One script, `canonical/aid/scripts/graph/scan-source.sh`, performs a single traversal of the
project source and writes **two** streams into the gitignored scratch space
(`.gitignore` carries `.aid/.temp/`; `authoring-conventions.md` designates `.aid/.temp/*` as
the ledger/scratch space, deleted at skill DONE):

| Stream | Owner | Consumer | Content |
|--------|-------|----------|---------|
| `.aid/.temp/graph/nodes.tsv` | this feature | feature-005 (pass 1b, pass 2 bounding), feature-006 (gap detection) | one row per structurally significant artifact (D1) |
| `.aid/.temp/graph/observations.tsv` | this feature (mechanism) | feature-005 pass 1b (meaning) | one row per mechanically observed reference/invocation/dependency seen during the same walk (D5) |
| `.aid/.temp/graph/candidates.tsv` | this feature | feature-005 pass 2 only | one row per artifact or reference the walk noticed but could **not** qualify or resolve by rule (D4) |

The division of labour: **this feature decides which nodes exist**; feature-005 decides which
rows exist. The scanner therefore *emits* observations without typing them — it never consults
the relation vocabulary and never writes a relationship row. Feature-005's `derive-edges.sh`
reads `observations.tsv` and does all typing.

The seam is enforced mechanically, not by convention, so `/aid-detail` cannot decompose this
into two competing scanners: `tests/canonical/test-graph-single-scanner.sh` asserts that within
`canonical/aid/scripts/graph/`, no file other than `scan-source.sh` contains a **repository**
traversal — a `find` or `git ls-files` whose root is the repo root. A second walk fails that
suite.

The guard is deliberately scoped to *repository* traversal so it does not obstruct the sibling
features that legitimately read a fixed single directory or an already-enumerated list:
feature-005's pass 1a reads `.aid/knowledge/` non-recursively at depth 1 (it produces the `kb:`
node set, which no walk of the source could produce), and feature-010's staleness digest hashes
the paths listed in `nodes.tsv` plus that same depth-1 KB directory. Neither is a second walk of
the project source, and neither can disagree with this scanner about what exists.

### Data Model

#### D1. Node record

`nodes.tsv` — tab-separated, no header, `LC_ALL=C`-sorted by `node_id`, LF-only, one row per
node. Tab-separated because the values contain `/`, `#`, and spaces but never a tab, and
because the repo already uses TSV for deterministic machine streams
(`kb-freshness-check.sh --format tsv`, and `build-project-index.sh`'s internal
`path\tlang\tlines\tmtime` join).

| # | Field | Value space |
|---|-------|-------------|
| 1 | `node_id` | `int:<repo-relative-path>` for a file, `int:<repo-relative-path>/` for a directory artifact — feature-003 D2b |
| 2 | `name` | display name; feature-003 D5 requires the full repo-relative path verbatim, so this equals `node_id` minus the `int:` prefix |
| 3 | `kind` | closed enum (D2) |
| 4 | `qualifier` | `entry-point` \| `public-surface` \| `depended-upon` \| `named-unit` — which FR-21 clause qualified it |
| 5 | `evidence` | a durable anchor: a path plus a grep-recoverable symbol, heading, glob, or matched literal (D3) |
| 6 | `evidence_provenance` | `declared` \| `derived` — **never `inferred`**; the field has no third value (FR-24, and invariant `no-inferred-node` in D3) |

`node_id` is the primary key. A given path appears at most once; when more than one clause
qualifies it, the first-matching clause in the D3 evaluation order wins, so the record is a
pure function of disk state and the row cannot flip between runs.

No field carries a timestamp, an absolute path, a line number, or a file size. That is what
makes `nodes.tsv` — and therefore the `derived` half of `relationships.md` — byte-identical
across runs (FR-32).

#### D2. `kind` enum

Closed, and every value is grounded in an artifact kind this repository actually has:

| `kind` | Unit | Representative real path |
|--------|------|--------------------------|
| `skill` | directory | `canonical/skills/aid-discover/` |
| `agent` | directory | `canonical/agents/aid-architect/` |
| `script` | file | `canonical/aid/scripts/kb/build-kb-index.sh` |
| `template` | file | `canonical/aid/templates/shortcut-engine.md` |
| `library` | file | `lib/aid-install-core.sh`, `lib/AidInstallCore.psm1` |
| `cli-entrypoint` | file | `bin/aid`, `bin/aid.ps1`, `bin/aid.cmd` |
| `installer` | file | `install.sh`, `install.ps1` |
| `manifest` | file | `canonical/EMISSION-MANIFEST.md`, `packages/npm/package.json`, `packages/pypi/pyproject.toml`, `canonical/aid/templates/generated-files.txt` |
| `settings-schema` | file | `canonical/aid/templates/settings.yml`, `.aid/settings.yml` |
| `test-suite` | file | `tests/canonical/test-aid-cli.sh`, `tests/run-all.sh` |
| `workflow` | file | `.github/workflows/test.yml` |
| `renderer` | file | `.claude/skills/generate-profile/scripts/run_generator.py` |
| `dashboard-module` | file | `dashboard/reader/parsers.py`, `dashboard/server/reader.mjs` |
| `site-module` | file | `site/scripts/`-and-`site/src/`-rooted sources |
| `doc` | file | `docs/aid-methodology.md`, `README.md` |

`kind` is descriptive metadata for feature-007's grouping and feature-006's gap phrasing. It is
**not** a significance test — `qualifier` is. Keeping them separate is what stops "it is a
script, therefore it matters" from smuggling in file existence as a qualification (the failure
mode FR-21's second sentence forbids).

The `renderer` row is the one node that legitimately lives under a normally-excluded tree:
`.claude/skills/generate-profile/` is maintainer tooling authored in place, not a render of
`canonical/` (`module-map.md`: "Lives at `.claude/skills/generate-profile/scripts/`"). It is
therefore a declared allowlist entry in D4, not an exception in the significance rule.

#### D3. What counts as derivable evidence (FR-24 — the highest-risk requirement)

FR-24 requires significance to be **derivable rather than judged**, so that a KB gap arrives
with evidence a reviewer can check. Concretely: `evidence` must be a string a reviewer can
paste into `grep` and see the same thing the scanner saw, and `evidence_provenance` must say
whether the project *stated* it or the scanner *computed* it. Nothing else qualifies a node.

**`declared` evidence — the project itself names the artifact.** Each item below is a real,
present-on-disk carrier:

| Carrier | What it declares | Evidence string form |
|---------|------------------|----------------------|
| `canonical/aid/templates/generated-files.txt` | an output path, and the script named in its `\|`-separated build command | the registry path + the matched output-path token |
| `canonical/aid/templates/shortcut-catalog.yml` | a shortcut skill by name (`module-map.md`: the doorways are emitted from this catalog) | the catalog path + the matched row's `name` |
| `.aid/settings.yml` `knowledge.doc_set` | a KB doc and the agent that authors it | the settings path + the matched `doc_set` entry |
| `canonical/EMISSION-MANIFEST.md` "Asset Kinds" table | the four canonical asset roots the renderer emits | the manifest path + the matched table row |
| a KB doc's frontmatter `sources:` list | a path or glob the KB claims to summarise | the KB doc path + the matched `sources:` entry |
| `.github/workflows/*.yml` | a path a CI step invokes | the workflow path + the matched command token |
| `packages/npm/package.json` (`bin`, `files`), `packages/pypi/pyproject.toml` | a published entry point | the manifest path + the matched key |
| `tests/run-all.sh` | the suite glob `tests/canonical/test-*.sh` (`test-landscape.md`, "Glob discovery") | `tests/run-all.sh` + the glob |

**`derived` evidence — the scanner computes it, with no judgment.** Three mechanisms only:

1. **Convention membership.** The path matches a naming convention the project's *own*
   documented rule treats as a unit. Each pattern is quoted from a rule that exists:
   `canonical/skills/*/SKILL.md` ⇒ the containing directory is a `skill`; `canonical/agents/*/AGENT.md`
   ⇒ the containing directory is an `agent` (both from `module-map.md` "Where a new skill goes" /
   "Where a new agent goes"); `canonical/aid/scripts/<area>/*` ⇒ a `script` (`module-map.md`
   "Where a new helper script goes"); `tests/canonical/test-*.sh` ⇒ a `test-suite`
   (`tests/run-all.sh`'s discovery glob). Evidence string: the matched pattern plus the rule's
   grep-recoverable anchor.
2. **Inbound reference count ≥ 1.** Another *already-enumerated* artifact's bytes contain this
   artifact's repo-relative path, or contain its basename in a resolvable position (D5).
   Evidence string: the citing path plus the matched literal. This is the `depended-upon`
   clause of FR-21 and the only qualifier that depends on other nodes, so it runs in a second
   settling pass (Feature Flow step 6).
3. **Executable-header presence.** The file's first line is a `#!/usr/bin/env {bash,node,python3}`
   shebang, or the file is a `.ps1` carrying `#Requires -Version 5.1`. `coding-standards.md`
   makes the header block and the shebang a project rule, so their presence is a declared
   intent-to-be-invoked, mechanically visible. Evidence string: the path plus the matched
   shebang/`#Requires` line. This yields `entry-point`.

##### The hard rule — invariant `no-inferred-node` (stated for feature-006 and feature-007 to rely on)

> **`evidence_provenance` is never `inferred`, and a candidate that only a reading would qualify
> is not emitted as a node.** Equivalently, as a property of the output: every row of `nodes.tsv`
> carries `evidence_provenance ∈ {declared, derived}`, and the field has no third value. Such a
> candidate is written to `candidates.tsv` with a `drop_reason`, where feature-005's pass 2 may use
> it to *type an edge between nodes that already exist*, and may never promote it to a node.

This is the mechanical form of FR-24's second sentence ("The skill must not manufacture defects
from `inferred` opinion alone"). It is deliberately stated as an invariant of the *node set*, not
as a property of a downstream view, because that is where it can actually be enforced.

**Three consequences, so downstream features can rely on it rather than re-deriving it:**

1. **feature-006 needs no gap-predicate filter for this case.** A predicate of the form "drop
   `int:` nodes whose sole qualification is `inferred`" is **vacuous** over this node set — the
   set it would filter cannot contain such a node. The filter should be dropped, not
   reimplemented: it is not merely hard to express in the view layer, there is nothing for it to
   remove.
2. **feature-007's node record needs no qualification-provenance field for this purpose.** Its
   absence is correct rather than an omission. (Whether feature-007 carries `kind` or `qualifier`
   for display or grouping is its own call; nothing in FR-24 requires it to.)
3. **FR-24 is discharged once, at enumeration time**, instead of being re-checked at each
   consumer. Every KB gap feature-006 reports therefore inherits checkable provenance by
   construction: it names a node, and every node carries a `grep`-recoverable `evidence` string
   plus a `declared`/`derived` stamp.

**How it is enforced** — an invariant other features are told to trust must be mechanically held,
not merely asserted:

- **One emission path.** `scan-source.sh` writes `nodes.tsv` through a single writer function.
  That function rejects any row whose `evidence_provenance` is not `declared` or `derived` and
  exits non-zero: such a row would be a scanner bug, not a data condition, so it must abort rather
  than be filtered.
- **No promotion path exists.** `candidates.tsv` is the only channel from the rules to the agent
  pass (D6), and it is write-only from the scanner's side; nothing reads a candidate back into the
  node set.
- **Test.** `tests/canonical/test-graph-node-provenance.sh` asserts, on the fixture tree and on
  this repository, that field 6 of every `nodes.tsv` row is `declared` or `derived`, and that no
  `candidates.tsv` row with `candidate_kind` = `node` has a `subject` appearing as a `nodes.tsv`
  `node_id`. The scoping to `node` candidates matters: an **edge** candidate's subject legitimately
  involves enumerated nodes — an unresolvable *reference* between two real artifacts is exactly
  what `unresolved-reference` records — so asserting over all candidates would fail on correct
  output.
- **Downstream half.** Feature-005's pass 2 carries a closed-node-set bound — both endpoints of
  an inferred edge must already exist in `nodes.tsv` or `kb-nodes.tsv`, enforced by the merge and
  not by the prompt (its Feature Flow step 9). So the one non-deterministic stage in the pipeline
  cannot reintroduce an inferred node either.

**Scope, stated precisely so the invariant is not over-read.** It binds *nodes*. **Edges** may of
course be `inferred` — that is what pass 2 produces, and feature-003's `Provenance` enum has the
value for exactly that reason. An `inferred` *row* between two `declared`/`derived` *nodes* is
normal and expected.

#### D4. Exclusion filter (FR-22 / AC-16)

Exclusions are applied **before** significance, so an excluded path can never qualify by any
clause. Each class has a derivable test; the mechanisms marked *(precedent)* are the exact
invocations `build-project-index.sh` already uses in its "Scope refinement" block, which is
documented there as "DETERMINISTIC + git-native + machine-neutralized (byte-reproducible
cross-OS/AID-update)".

**Class 1 — generated / derived trees.** These are reproductions of a single source; including
them would multiply every node and every reported gap by the number of renderings (FR-22).

| Excluded | Why, verified |
|----------|---------------|
| `profiles/**` | render output of `canonical/`; `module-map.md` Invariants: "MUST be regenerated, never hand-edited" |
| `.claude/**`, `.cursor/**`, `.codex/**`, `.agent/**` | the dogfood/rendered install trees. `build-project-index.sh` prunes exactly these four with exactly this rationale ("the AID install itself, never target-project source … Pruning them keeps the harvest/index scoped to the target project and byte-reproducible across AID updates") |
| `.github/aid/**` | the copilot-cli install tree. Excluded **by subpath, not by pruning `.github/`** — `build-project-index.sh`'s own comment states why: "`.github` is a standard project dir with legitimate content, so it is not pruned wholesale". Pruning it would drop the five `workflow` nodes |
| `packages/npm/{bin/aid,bin/aid.ps1,bin/aid.cmd,lib/**,dashboard/**,VERSION}`, `packages/pypi/aid_installer/_vendor/**`, `packages/pypi/dist/**` | each is an explicit `.gitignore` entry labelled "vendored copies (generated … not committed)" |
| `site/dist/**` | `project-structure.md`: "built site output (generated)" |
| `.aid/generated/**` | gitignored discovery scratch |
| any file whose first two lines match `@generated`, `DO NOT EDIT`, or `DO NOT MODIFY` | *(precedent)* — the same two-line predicate `build-project-index.sh` applies |
| any path with `linguist-generated` set | *(precedent)* `git check-attr --stdin linguist-generated` |

**Class 2 — vendored third-party code.** "not the project's to document".

- `git check-attr --stdin linguist-vendored` set *(precedent)*.
- `**/node_modules/**` — gitignored; present under `site/` and
  `canonical/aid/scripts/summarize/` (which carries its own `package.json` +
  `package-lock.json`).
- `packages/*/_vendor/**`.

**Class 3 — ignore-listed paths.**

- `git -c core.excludesFile=/dev/null check-ignore --stdin` *(precedent)*. The
  `-c core.excludesFile=/dev/null` is load-bearing, not incidental: it neutralises the
  developer's global gitignore, which is what makes the exclusion set identical on every
  machine and therefore compatible with FR-32.
- **plus FR-22's ignore list in `.aid/settings.yml`.** This setting **does not exist today** —
  verified: neither `.aid/settings.yml` nor `canonical/aid/templates/settings.yml` declares an
  ignore list of any kind. This feature introduces it:

```yaml
graph:
  ignore:                          # repo-relative globs excluded from int: enumeration
    - examples/**
```

  It is read with `bash read-setting.sh --path graph.ignore --default ''`, which resolves a
  list-valued dotted key through `lookup_list` and returns the items comma-joined (documented
  in `read-setting.sh`'s own usage block and exercised there against `tools.installed`).
  `--default ''` means an absent section is not an error. `coding-standards.md` is explicit
  that settings are read only through this resolver and never hand-parsed. One limitation
  follows from the resolver's comma-joined output and is stated rather than discovered later:
  **an ignore pattern may not contain a comma.** Patterns are matched as repo-relative globs
  with bash `case` semantics, the same matching style `build-project-index.sh` uses for its
  `NOTABLE_PATH_PATTERNS`.

**Class 4 — the `.aid/` partition, and why it is not optional.** `.aid/**` is excluded from
`int:` enumeration with a single declared allowlist: `.aid/settings.yml` (a `settings-schema`
node; `project-structure.md` lists it in Key Files as "the authoritative settings other skills
read"). Three reasons, in order of importance:

1. `.aid/knowledge/**` is `kb:` territory. If a KB doc were also an `int:` node, it would
   appear on both sides of the coverage question — a doc could "document itself" and satisfy
   its own gap, or be reported as an undocumented source artifact. Either outcome corrupts the
   signal FR-20 exists to produce. **The `kb:` and `int:` node sets must be disjoint**; that is
   an invariant, and `test-graph-node-partition.sh` asserts it over `nodes.tsv`.
2. `.aid/works/**` is transient. The project's tracking-discipline rule states work folders
   "may be pruned once the work ships" and that no permanent artifact may depend on their
   contents. Enumerating them would put transient state into a committed artifact.
3. `.aid/generated/**`, `.aid/.temp/**`, `.aid/.trash/**`, `.aid/.heartbeat/**`,
   `.aid/.control/**`, `.aid/knowledge/.cache/**` are all gitignored (verified in the
   `.gitignore` "AID managed" block) and already fall to Class 3.

`.aid/connectors/*.md` is deliberately left out of the allowlist: the catalog is per-project
state, not project source, and `INDEX.md` there is generated by
`build-connectors-index.sh`. Recorded as an Open Item in case the owner wants connector
descriptors visible in the graph.

**Class 5 — the maintainer-tooling allowlist.** `.claude/skills/generate-profile/**` is
allow-listed back in from Class 1, because it is hand-authored maintainer tooling that happens
to live under `.claude/` rather than a render of `canonical/` (`module-map.md` places the
renderer there explicitly, and `test-landscape.md` lists its five `--self-test` entry points).
Excluding it would hide the single most load-bearing module in the render plane and manufacture
a false "no gap" for it.

#### D5. Observation record (feature-005's input)

`observations.tsv` — tab-separated, `LC_ALL=C`-sorted, LF-only. The scanner emits these while
walking; it does not interpret them.

| # | Field | Value space |
|---|-------|-------------|
| 1 | `from_id` | an `int:` node id — the artifact whose bytes contained the reference |
| 2 | `to_id` | an `int:` or `kb:` node id — the referenced artifact |
| 3 | `observation_kind` | `path-reference` \| `invocation` \| `dependency` \| `include` \| `convention` |
| 4 | `evidence` | the citing path plus the matched literal (a durable anchor, never a line number) |

Resolution of a reference to a `to_id` is deterministic and never guesses:

- A full repo-relative path that matches an enumerated node → that node.
- A **basename** that matches exactly one enumerated node after exclusions → that node. This
  works precisely because Class 1 removes the render copies: `build-kb-index.sh` exists at
  eight paths on disk (`canonical/`, five `profiles/`, `.claude/`, `.cursor/`), and excluding
  the seven copies leaves `canonical/aid/scripts/kb/build-kb-index.sh` as the unique survivor.
  The exclusion filter is therefore not just noise reduction — it is what makes basename
  resolution single-valued.
- A basename matching **more than one** surviving node, or **zero** → a `candidates.tsv` row
  with `drop_reason` `ambiguous-basename` or `unresolved-reference`. Never a guess, never a row.

`observation_kind` values and their literal triggers:

| Kind | Trigger |
|------|---------|
| `path-reference` | the bytes of one node contain another node's path or uniquely-resolving basename |
| `invocation` | `bash <p>`, `sh <p>`, `source <p>`, `. <p>`, `node <p>`, `python <p>`, `python3 <p>`, `pwsh -File <p>`, `powershell -File <p>`, `Import-Module <p>` |
| `dependency` | a manifest edge: `package.json` `bin`/`files`/`dependencies`; `pyproject.toml` entry points; `profiles/<tool>.toml`; `generated-files.txt` output ↔ build command; `shortcut-catalog.yml` row ↔ emitted doorway; `.aid/settings.yml` `knowledge.doc_set` ↔ the named KB doc (the one `dependency` that crosses to a `kb:` id) |
| `include` | the `{{include:agent-boilerplate}}` directive — present in all nine `canonical/agents/*/AGENT.md` files, and recorded in `module-map.md`'s dependency graph as `canonical/agents/* -> canonical/aid/templates/agent-boilerplate.md (include directive)` |
| `convention` | a rule-based structural edge, e.g. `canonical/skills/*` → `canonical/aid/templates/shortcut-engine.md` for a shortcut doorway |

#### D6. Candidate record

`candidates.tsv` — tab-separated, `LC_ALL=C`-sorted, LF-only:
`candidate_kind | subject | context | drop_reason`, where `candidate_kind` is `node` or `edge`.
This is the *only* channel by which anything the rules could not settle reaches feature-005's
agent pass, and it never carries a promotion path to a node (D3).

### Feature Flow

Inputs: the repository working tree; `.aid/settings.yml` (`graph.ignore`); git (for
`check-ignore`, `check-attr`, and `rev-parse --show-toplevel`). Outputs: the three streams in
`.aid/.temp/graph/`. `scan-source.sh` writes nothing else and modifies no source file (FR-10).

1. **Resolve the root.** `git rev-parse --show-toplevel`, as `kb-freshness-check.sh` does. Not
   a git repo → exit 2 with an actionable message: Classes 1–3 depend on `git check-ignore`
   and `git check-attr`, so a non-git checkout cannot produce a reproducible exclusion set.
2. **Collect candidate paths.** One `find` from the root with a directory-prune expression
   built the way `build-project-index.sh` builds `PRUNE_EXPR`, then `LC_ALL=C sort`. The prune
   set is the cheap, directory-shaped half of D4 (`.git`, `node_modules`, `profiles`,
   `.claude`, `.cursor`, `.codex`, `.agent`, `.aid`, `site/dist`, …); the remaining exclusions
   are path- and content-shaped and run in step 3.
3. **Apply the exclusion filter (D4)** in class order, as batched removals — one process per
   mechanism, never one per file: a single `git check-ignore --stdin`, a single
   `git check-attr --stdin`, a single batched two-line `awk` for the `@generated` header
   predicate, and one `case`-glob pass for `graph.ignore`. Batching is not an optimisation
   detail; `build-project-index.sh` records that per-file forks under Windows Git Bash / MSYS
   cost 0.5–1.8 s each and dominated its runtime. Then apply the Class 4 `.aid/` cut and the
   Class 5 allowlist. Removal-only, so the result is order-independent.
4. **Apply the granularity cut (FR-23 / AC-16).** Collapse `canonical/skills/<name>/**` to the
   directory id `int:canonical/skills/<name>/` and `canonical/agents/<name>/**` to
   `int:canonical/agents/<name>/`; suppress their member files. Every other node is
   file-level. No node id is ever narrowed to a symbol or a line range — the scanner has no
   code path that produces a `#` in an `int:` id, and feature-003's V7 re-checks the emitted
   table.
5. **Qualify by rule (first pass).** For each surviving path, evaluate the `declared` carriers
   (D3) then the `convention`-membership and `executable-header` mechanisms, in that fixed
   order, and stop at the first match. `declared` is tried before `derived` so a node's
   evidence is the strongest available. A path with no match is held for step 6.
6. **Settle `depended-upon` (second pass).** Scan the bytes of the nodes qualified in step 5
   for references (D5), emitting `observations.tsv`. A held path that receives at least one
   inbound reference qualifies as `depended-upon` with the citing path and matched literal as
   evidence. Iterate to a fixed point — a newly qualified node's own references can qualify
   another — bounded by the node count, which terminates because the qualified set only grows
   and is bounded by the candidate set. Fixed-point iteration is what makes the result
   independent of traversal order and therefore reproducible.
7. **Drop the residue.** Every still-unqualified path becomes a `candidates.tsv` row with
   `drop_reason` `no-rule-match`. **File existence alone never qualifies** — this step is
   where that requirement is actually enforced.
8. **Emit.** Write the three streams, each `LC_ALL=C`-sorted with LF endings. Print a
   one-line summary to stderr (`[scan] N nodes, M observations, K candidates`), the
   `[index]`-prefixed diagnostic style `build-project-index.sh` uses. Exit `0` on a successful
   scan, `1` on a write failure, `2` on a usage or environment error.

**Sanity check against A-5.** On this repository the rule yields roughly 111 skill directories
+ 9 agent directories + the 53 files under `canonical/aid/scripts/` + ~133 `tests/canonical/`
suites + 5 workflows + the installer/CLI/library/manifest set + the dashboard, site, and docs
modules — several hundred nodes, which is the band A-5 assumes and which the layout in
`module-map.md` and `test-landscape.md` corroborates. Nothing in the rule scales with line
count or function count, so the granularity cut is what holds the bound.

### Layers & Components

New files only. Authored in `canonical/`, then rendered by the FULL `run_generator.py` — never
hand-edited under `profiles/` or the dogfood `.claude/` (C-2; `module-map.md` Invariants).
`canonical/aid/scripts/` is a recognised asset kind in `canonical/EMISSION-MANIFEST.md`'s
"Asset Kinds" table, so a new `graph/` subdirectory renders into all five profiles with no
renderer change; the per-profile `emission-manifest.jsonl` records regenerate in the same run
and the render-drift CI job gates the result (C-3).

| Layer | Path | Purpose |
|-------|------|---------|
| Script (the walk) | `canonical/aid/scripts/graph/scan-source.sh` | the single traversal; owns exclusions, granularity, qualification, and the three output streams |
| Script library | `canonical/aid/scripts/graph/significance-rules.sh` | sourceable predicates — one function per D3 mechanism and per D4 class — so the scanner and its test suite exercise the *same* code, not two readings of the rule |
| Settings | `canonical/aid/templates/settings.yml` | seed the `graph:` section with a commented-out `ignore:` list |
| Test | `tests/canonical/test-source-enumeration.sh` | per-clause qualification, per-class exclusion, the granularity cut, fixed-point settling, and byte-identical re-run on an unchanged fixture tree |
| Test | `tests/canonical/test-graph-single-scanner.sh` | the seam guard — no second repository traversal under `canonical/aid/scripts/graph/` |
| Test | `tests/canonical/test-graph-node-partition.sh` | `kb:` and `int:` node sets are disjoint (D4 Class 4) |
| Test | `tests/canonical/test-graph-node-provenance.sh` | the `no-inferred-node` invariant (D3): every `nodes.tsv` row is `declared`/`derived`, and no dropped candidate appears as a node |
| Fixtures | `tests/canonical/fixtures/graph/tree/` | a self-built miniature repository containing one instance of every exclusion class and one of every qualifier clause |

Conventions honoured (`coding-standards.md` unless noted):

- `#!/usr/bin/env bash`; header block with Purpose / Usage / Exit codes; `-h|--help` re-printing
  a slice of it (`build-project-index.sh` uses `sed -n '2,17p' "$0"`).
- `set -euo pipefail` for the scanner (it writes files, so a failed step must abort);
  `set -eu` for the sourceable library, with no import-time side effects.
- Argument parsing via the `while [[ $# -gt 0 ]]; do case "$1" in … esac done` loop with
  `shift 2` per flag; unknown flag → stderr + exit 2.
- Settings read only through `read-setting.sh` — never a hand-parse of `settings.yml`
  (`module-map.md` Invariants).
- Portability probes before use (`stat --version` / `stat -f` style) if any file metadata is
  ever needed; today none is, which is itself the reproducibility choice.
- `LC_ALL=C` on every sort and comparison; batched processes, never per-file forks.
- Tests are discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob, so no runner
  edit is needed. The fixture tree is self-built and references nothing under `.aid/works/`,
  per A-6 and the project's transient-work-folder rule.

### Open Items

1. **`graph.ignore` and settings reconcile.** `.aid/settings.yml` declares `format_version: 3`.
   Whether adding a `graph:` section requires a `format_version` bump and a reconcile rule (the
   ground already covered by `/aid-config` and `tests/canonical/test-reconcile-scenarios.sh`)
   is a decision for the skill-wiring feature, not this one. This feature only requires that
   `graph.ignore` resolve through `read-setting.sh` and default to empty.
2. **`.aid/connectors/*.md` visibility.** Excluded by D4 Class 4 as per-project state. If the
   owner wants connector descriptors in the graph, they are one allowlist entry away.
3. **`site/` depth.** `site/src/**` is a large, conventionally-organised Astro tree with no
   AID-authored naming rule to key on, so most of it will qualify only via `depended-upon`.
   That is the correct conservative outcome, but it means the graph's site coverage is thinner
   than its toolkit coverage — worth stating before feature-006 reports it as a gap cluster.
