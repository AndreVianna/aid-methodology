# Design Lifecycle Machinery

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md §5.2, FR-1, FR-3, FR-8, §8, C-4 | /aid-define |
| 2026-08-09 | Technical Specification authored | /aid-specify |
| 2026-08-09 | Rewritten against review round 1 (E+) | /aid-specify |
| 2026-08-09 | Rewritten whole against review round 2 (E, 12 recurred): bare `/aid-design` scoped out on correct grounds, seed naming rule for artifact-less skills, adopter acquisition of `.aid/design/`, class-scoping applied to full extent | /aid-specify |
| 2026-08-09 | Technical Specification rewritten whole against review round 4 (D, 24 findings, 15 recurred), and the acceptance criteria rewritten with them because finding 1's extent reaches AC-2. Adopter acquisition moves from an install-time seed to created-on-first-use (§2d records the rejected alternative and the seed-destruction hazard that motivates it); §3a's stage semantics is split by stage so the `design` invariant binds all 22 design-stage writers; class 2's definition corrected for the `document` pair; the region first-write rule rebuilt on REQUIREMENTS FR-1's populated-destination rule and AC-6b; every completeness claim either re-derived with its search command or dropped; every §7 oracle re-stated as a runnable command, a named suite, or a scoped diff | /aid-specify |
| 2026-08-09 | Closed review round 5 (17 findings, 1 CRITICAL, 4 HIGH, 3 recurred) against REQUIREMENTS **FR-11**, whose nine cross-feature contracts this spec now *refers to* rather than restating. Structural: §3a's `update` row gains the seed read + consumption (CC-3) and `create`'s terminator is split into realizing vs routing exits, so a routed seed has a consumer; the FR-1 `design`-Reads widening is recorded here by the contract's owner, and the 22-writer population is distinguished from CC-7's 22-row family; §3c's first-write table is rebuilt as a situation→action **dispatch** naming CC-5/CC-6 as authorities, with CC-1/CC-2/CC-4 explicitly not restated; §3f withdraws the "all in one suite" claim and hands `tests/canonical/check-skill-counts.mjs` to feature-006 §3 (plus DMR32, which feature-006 §4's table omits); §2d replaces the unresolvable `<agent-root>` with the canonical path the render-time `rewrite_install_paths` idiom already resolves; §3g gains the missing dispatch-tiering row (18 → 19) with a stated derivation; AC-11/G3/I1 stop denying the five `emission-manifest.jsonl` rewrites and the feature-006-owned render; G2 and B2 gain conjuncts that can fail; E3 retyped `review`; the §7 closing paragraph now accounts for all nine `review` rows; every path/line citation re-opened at its own line and **fifteen** corrected, plus feature-005's section anchors resequenced (§6a–6c → §7a–7c, §8 → §9) after its parallel rewrite | /aid-specify |

## Source

- REQUIREMENTS.md §4 (In Scope — `.aid/design/` as the artifact home)
- REQUIREMENTS.md §5.2 (two classes of skill), FR-1, FR-3, FR-6, FR-7, FR-8, FR-10
- REQUIREMENTS.md §6 NFR-2, NFR-3, NFR-4; §7 C-1, C-4, C-6
- REQUIREMENTS.md §9 AC-2, AC-6, AC-7, AC-8, AC-9

## Description

The shared foundation every lifecycle skill binds to, authored **once** rather than
restated 36 times — in the manner of the existing `shortcut-engine.md` plus its
per-family scaffolding documents.

Two parts.

**First, the artifact home.** `.aid/design/` is an existing, documented convention that
is not currently on `master` — it lives only on the `docs/graph-redesign-seed` branch,
carrying a `README.md` and one seed. This feature lands it, corrects its README, and —
because no installer, template, or ignore rule mentions it anywhere in the repo — gives
adopters a way to acquire it.

**Second, the contract.** A three-stage lifecycle whose verbs denote *stage*, not
direction: `design` develops an idea in `.aid/design/`; `create` realizes it; `update`
maintains what exists. The contract's hardest job is stating precisely **which of its
rules bind which skills**, because the 36 skills fall into classes with genuinely
different mechanics, and a rule stated universally is a rule that cannot be implemented
for two-thirds of them.

## User Stories

- As a **skill author**, I want the contract written down once, so that thirty-six
  skills cannot fork it.
- As an **adopter**, I want a place to develop an idea that is not yet a decision, so
  that unsettled thinking does not contaminate the Knowledge Base.
- As an **adopter running a `design` skill for the first time**, I want the folder and
  the convention that governs it to appear with my first seed, not only in the
  maintainer's own repo — and I want neither to appear if I never run one.
- As a **reviewer**, I want each destination region to have exactly one owning skill, so
  that two of the new skills cannot silently overwrite each other.

## Priority

Must

## Acceptance Criteria

Each criterion names the §7 oracle row that fails when it is not met. A criterion with
no failing oracle is a defect, not a criterion.

- [ ] **AC-1 — Folder landed and corrected.** `.aid/design/` is on `master` with both
      files. The landed `README.md` is byte-identical to
      `canonical/aid/templates/design-folder-readme.md`, names no `/aid-interview`,
      carries no *unqualified* deletion statement, presents **four** lifecycle entries
      (hand-written; skill-authored design artifacts; skill-authored code artifacts;
      exploratory), and routes no reader to a document AID does not install.
      *Oracles:* §7 A1–A6.
- [ ] **AC-2 — Adopters acquire it on first use, not at install.** The first
      `design`-stage skill run creates `.aid/design/` and, if `README.md` is absent,
      writes it from the installed template. A project that never runs a `design`-stage
      skill acquires neither. **No installer library changes** — §2d records the
      install-time alternative and why it is rejected. *Oracles:* §7 B1–B4.
- [ ] **AC-3 — Contract is class-scoped throughout.** §3g's binding table carries a row
      for **every** rule the contract states — §2d, §3a–§3f and §4, including §3a's stage
      semantics — and no rule binds a population that has no implementation site.
      *Oracles:* §7 C1 (row coverage), C2 (review).
- [ ] **AC-4 — Seed naming covers every writer.** The naming rule resolves a path for a
      writer whose catalog `artifact` is `""`, and `## Destination` is optional for such a
      writer. *Oracle:* §7 D1.
- [ ] **AC-5 — Readiness is detectable.** "`## Open questions` is non-empty" has a
      detection rule an implementer can apply without inventing one, including the
      placeholder convention it depends on. *Oracle:* §7 D2.
- [ ] **AC-6 — Region mechanics are complete *and* survive a populated destination.**
      The contract fixes the region's heading text, extent, insertion position, and write
      discipline; and per REQUIREMENTS FR-1 and AC-6b, `create` **never** refuses because
      its destination document exists or carries content — it refuses only when its own
      owned region already carries committed content, and then routes to `update`.
      *Oracles:* §7 E1–E3.
- [ ] **AC-7 — Skill shape includes the description contract and a defined verify
      depth.** §3e specifies the frontmatter fields, the negative-routing `description`
      obligation (NFR-4, AC-8), and what "full verify" consists of. *Oracle:* §7 F1.
- [ ] **AC-8 — Seed shape is anchorable.** §4 fixes literal heading text, heading level, and
      order — because §4's detection rule is anchored on the literal string `## Open questions`,
      and because three independent consumers read the one file shape (§4). *Oracle:* §7 D3.
- [ ] **AC-9 — Bare `/aid-design`'s behavior unchanged.** It keeps writing `DESIGN.md` to
      its work folder; the contract records why; the four in-skill sites that depend on
      that are untouched. Its frontmatter **does** change — `description` and
      `argument-hint`, both feature-005's edit (its SPEC §7a) — so the oracle is a **scoped**
      diff over the frontmatter block, not a whole-file exit-code diff. *Oracle:* §7 G1.
- [ ] **AC-10 — `phase:` untouched.** No enum value is added and the work/delivery/task
      hierarchy is unchanged, and the contract this feature ships positively instructs its
      readers not to drive `phase`. *Oracle:* §7 G2.
- [ ] **AC-11 — The feature's shipped footprint is three additive templates, and nothing
      else.** Outside `.aid/` this feature's diff **adds**
      `canonical/aid/templates/design-{lifecycle,seed,folder-readme}.md` and **modifies** no
      existing **shipped** file — no installer library, no engine, no scaffolding file, no
      `SKILL.md`. Two exclusions, both stated because a naive diff contradicts the claim:
      the fifteen `profiles/` renders (three files × five profiles) are produced by
      feature-006's single render, not by this feature's commits (§8); and that render also
      **rewrites** the five generated `profiles/*/emission-manifest.jsonl` build indexes,
      which are explicitly **not installed content**
      (`tests/canonical/test-aid-migrate.sh:1078`, `release.sh:245`) and are therefore
      outside "shipped file". *Oracles:* §7 G3 (the `canonical/` side, at this feature's
      close) and §7 I1 (the `profiles/` side, after feature-006's render).
- [ ] **AC-12 — The KB's `.aid/` tree is refreshed, not just flagged as stale.**
      `.aid/knowledge/project-structure.md`'s `.aid/` tree lists `design/`, so its own
      *"CONFIRMED by direct `find` traversal of each subtree"* line remains true.
      *Oracle:* §7 K1.

---

## Technical Specification

> **Section applicability.** Data Model, Feature Flow, and Layers & Components assume a
> code project; this feature produces templates and prose contracts. **N/A**. No
> conditional section auto-activates. §3 stands in for Feature Flow.

**Citation discipline for this revision.** Every path and line number below was opened at
that line while this section was written; nothing is carried forward from the previous
draft unchecked. Where a claim is a *negative* ("no X exists"), the search that produced it
is printed next to it, so a reviewer can re-run it rather than trust it.

### 1. Artifact Inventory

**1a. New canonical templates — the whole shipped footprint of this feature**

| File | Purpose | Read by |
|------|---------|---------|
| `canonical/aid/templates/design-lifecycle.md` | The three-stage contract (§3) | the 36 doorways authored in features 003/004/005 |
| `canonical/aid/templates/design-seed.md` | The `.aid/design/` seed shape (§4) | every `design`-stage skill; feature-005's engine read (`shortcut-engine.md` CAPTURE Step 2) and the two hand-authored `document` bodies read whole files in this shape |
| `canonical/aid/templates/design-folder-readme.md` | The `.aid/design/README.md` a project acquires on first use (§2d) | the first `design`-stage skill to run in a project |

Placing three files at the root of `canonical/aid/templates/` is count-neutral. The search that
establishes it is the **directory-enumeration idiom**, not the path literal — the previous draft
printed a path-literal grep and credited it with a result it does not return, because the
counting sites bind the directory to a *variable* and carry no literal on the `find` line:

```
grep -rnE "\-maxdepth 1 \-name '\*\.md'" tests/
grep -rn "TEMPLATES *=\|KB_DIR *=" tests/ site/scripts/     # resolve each variable
```

The first returns exactly **four** lines, and each resolves to `canonical/aid/templates/`'s
`knowledge-base/` **subdirectory** or to something else entirely:

| Site | Directory it enumerates |
|---|---|
| `tests/canonical/test-doc-set-read.sh:190` | `canonical/aid/templates/knowledge-base` (literal) |
| `tests/canonical/test-domain-doc-matrix.sh:142` | `$KB_TEMPLATES` = `…/templates/knowledge-base` (`:50`) |
| `tests/canonical/test-kb-template-authoring-standard.sh:50` (`AS06`, assertion `TEMPLATE_COUNT == 14` at `:56-57`) | `$KB_TEMPLATES` = `…/templates/knowledge-base` (`:42`) |
| `tests/canonical/test-describe-full-only.sh:147` | `$REFS_DIR` = `…/aid-describe/references` (`:43`) — not the templates tree |

On the `site/` side the one templates enumeration is `gen-reference.mjs:334`, over
`KB_DIR = canonical/aid/templates/knowledge-base` (`:39`).

**No site enumerates the templates tree root.** The authoring-standard suite's one
out-of-subdirectory assertion, `AS08` (`:140-143`), is bound to `feature-inventory.md` **by
name**, not by glob. Verified: `ls canonical/aid/templates/ | wc -l` = 41,
and each of the five profile mirrors (`profiles/{claude-code,codex,cursor,copilot-cli,
antigravity}/<root>/aid/templates/`) also holds 41 — so a new root template renders through
to every tool, which is what makes §2d's read path resolvable on all five profiles.

**1b. Landed from `docs/graph-redesign-seed`**

| File | Change |
|------|--------|
| `.aid/design/README.md` | Landed **as the instantiation of the new template**, not as a copy of the branch file (§2a–2c) |
| `.aid/design/knowledge-graph-redesign.md` | Landed byte-identical to the branch copy (§2e) |

`git ls-tree -r --name-only docs/graph-redesign-seed -- .aid/design/` returns exactly those
two paths; there is no third file to account for.

**1c. Repo files this feature edits**

| File | The edit |
|------|----------|
| `.aid/knowledge/project-structure.md` | The `.aid/` tree at `:131-136` gains one line, `├── design/  # design seeds under construction (.aid/design/README.md defines the convention)`, placed after `knowledge/`. The line at `:139` — *"CONFIRMED by direct `find` traversal of each subtree"* — is a claim about that tree, so leaving the tree stale falsifies it |

That is the entire KB edit — an *instruction*, not an observation, and §7 K1 is the oracle
that fails if it is skipped. No other `.aid/knowledge/` document is touched by this feature.

**1d. Explicitly unchanged — each with the oracle that would catch a violation**

| Left alone | Why | Oracle (§7) |
|------------|-----|-------------|
| `lib/aid-install-core.sh`, `lib/AidInstallCore.psm1` | §2d rejects the install-time seed | G3 |
| `_aid_gitignore_block` (`aid-install-core.sh:2152-2162`, list at `:2155-2160`) and `Get-AidGitignoreBlock` (`AidInstallCore.psm1:1618-1630`, list at `:1621-1626`) | §2f: `.aid/design/` is tracked **by absence** from that list; adding it would ignore it | G3 |
| `canonical/aid/templates/shortcut-engine.md` | FR-10's read is feature-005's (its §4a); this feature touches nothing in the engine | G3 |
| `canonical/aid/templates/shortcut-scaffolding/` | §1e | G3 |
| Every `SKILL.md` | The 36 doorways are features 003/004/005; bare `/aid-design` is §5 | G1, G3 |

**1e. No `shortcut-scaffolding/design.md` — on corrected grounds.**

The previous draft justified this by claiming the Family Scaffolding Consult is read only by
rows that enter the engine. That premise is false on disk. Two scaffolding files were
authored expressly for rows that never enter the engine:
`shortcut-scaffolding/prototype.md:3-9` (*"`prototype` is now a hand-authored collapse skill,
**no longer consulted by the shared engine** — instead the hand-authored `aid-prototype` body
reads this file"*) and `document.md:3-14` (the same construction for
`aid-create-document`/`aid-update-document`). A scaffolding file for a hand-authored family
is therefore **possible**; the question is only whether it is *wanted*.

It is not, for a content reason: `design-lifecycle.md` (§3) and `design-seed.md` (§4) **are**
that guidance. A `design.md` scaffolding file would be a second home for the same rules —
precisely the 36-way fork this feature exists to prevent. That is a scope decision, so §7
verifies it as scope (G3, a scoped diff over `shortcut-scaffolding/`), not as correctness.

The engine's verb→family table (`shortcut-engine.md:183-189`) gains no `design` row, and
that remains true for the mechanical reason: no `design` row enters the engine. But the
previous draft's supporting claim — *"the one existing precedent: `query`"* — is wrong. The
catalog carries **18 distinct verbs** (`grep -E '^    verb:' shortcut-catalog.yml | sed
's/.*verb: //' | sort -u` → create, deploy, deprecate, design, document, experiment, fix,
migrate, monitor, prototype, query, refactor, remove, report, research, review, test,
update). That table lists 8 of them, so **10** are absent, not one. Separately,
`ls canonical/aid/templates/shortcut-scaffolding/` returns 7 files, and four verbs —
`design`, `deploy`, `monitor`, `query` — have no scaffolding file at all. `design` joining
that set is unremarkable. Feature-005 §3c owns the comment-only edit that extends the
engine's `query` paragraph (`:191-194`) to name `design`; this feature does not make it.

**1f. This feature writes no skill file.** Bare `/aid-design`'s behavior is unchanged (§5);
its two frontmatter edits — `description` and `argument-hint` — belong to feature-005 (§7a
there).

### 2. Landing and correcting `.aid/design/`

**2a. One text, two locations.** The corrected README is authored **once**, as
`canonical/aid/templates/design-folder-readme.md`, and `.aid/design/README.md` is that file
byte-identical. Byte-identity is achievable because **neither render transform has a trigger
in this text**, and both triggers are narrow and enumerable rather than assumed:
`substitute_filenames` fires on exactly three placeholder keys — `{project_context_file}`,
`{reviewer_output_file}`, `{open_questions_file}` — and leaves every other `{…}` token alone
(`render_lib.py:108-116`); `rewrite_install_paths` fires on
`canonical/{scripts,templates,skills,agents,recipes}/…` prefixes (`:145-175`). The README's
only path references are `.aid/design/…` and `.aid/knowledge/…`, and it carries none of the
three keys. That is what gives §7 A1 a hard oracle (`diff`) instead of two prose copies
drifting apart — and it is a standing constraint on the README's *content*: the template must
never acquire a `canonical/…` path or one of those three keys. (Contrast
`design-lifecycle.md`, which deliberately does carry one such path and is therefore **not**
byte-identical across profiles — §2d, oracle B2.)

Consequence, stated because it is a real deletion: the branch README's closing **"Why this
file exists"** section is AID-repo history (*"The folder was used through mid-2026
(`aid-summarize-redesign.md`, `kb-skills-improvements.md`,
`cli-install-scope-and-migration.md`, …) and emptied itself as each seed shipped"*). It does
not land, in either location. An adopter must not be handed AID's own folder history as
their convention, and this repo does not need it — git holds it.

**2b. The corrections, enumerated.** The branch README is a 5-defect document, not a
2-defect one. Each row is a separate edit with its own oracle.

| # | Defect on the branch | Correction |
|---|---------------------|------------|
| 1 | Prose: a seed is written *"before `/aid-interview` picks it up"* | `/aid-describe` — no `/aid-interview` exists in the 76-skill roster (REQUIREMENTS §8) |
| 2 | Fence: `seed written  →  work scoped (/aid-interview)  →  work ships  →  SEED DELETED` | Replaced by the four-entry block in 2c |
| 3 | Body: *"**Delete the seed when the work ships.** … A seed left behind becomes a second, stale description of a system that has moved on."* | Qualified by entry — false for the 14 code artifacts, whose seeds persist (§3b) |
| 4 | Closing: *"the KB describes what **is**; a seed describes what **should be** and is deleted once it *is*."* | The first clause is kept (it is the governing distinction, REQUIREMENTS §8); the deletion half is qualified the same way |
| 5 | "What belongs here" table routes *"Conventions and gates that bind every future work"* to `.aid/knowledge/quality-gates.md` | Re-routed to `.aid/knowledge/coding-standards.md`. `quality-gates.md` is an AID-dogfood extension doc with **no template**: `ls canonical/aid/templates/knowledge-base/` returns 14 names and `quality-gates.md` is not among them, so an adopter following that row would be sent to a document AID never installs |

Defects 3, 4 and 5 are the three the previous draft missed. Its §2 enumerated defects 1 and 2
only, so the file landed on `master` would still have taught universal deletion in two places
(3 and 4) and still have routed an adopter to a document AID never installs (5). §7 A3 greps
for both deletion sentences; §7 A5 greps for the `quality-gates.md` route.

**2c. The lifecycle block — four entries, not two.** The previous draft's block covered 21
of the 22 seed-writing skills: `/aid-brainstorm` has no `create` counterpart at all
(REQUIREMENTS FR-7), so it has no realization event and no deletion trigger, and the block
was silent on it. Splitting the previous "Entry B" into its two classes makes the deletion
rule readable off the block instead of out of a footnote under it.

```
Entry A — hand-written
  seed written by hand  →  work scoped (/aid-describe)  →  work ships  →  seed deleted

Entry B — skill-authored, design artifacts (7)
  /aid-design-<artifact>   →  seed written / iterated in .aid/design/
  /aid-create-<artifact>   →  realized into a Knowledge Base document, then seed DELETED

Entry C — skill-authored, code artifacts (14)
  /aid-design-<artifact>   →  seed written / iterated in .aid/design/
  /aid-create-<artifact>   →  seed READ as prior context; it PERSISTS.
                              Delete it by hand when the artifact is built.

Entry D — exploratory
  /aid-brainstorm          →  seed written under a confirmed slug (§4)
                              No create counterpart. It persists until you promote it
                              into one of the entries above, or delete it by hand.
```

**Deletion is per-entry.** Automatic deletion at realization is true for A and B only. For C
it would require a *write* to `shortcut-engine.md`, and FR-10 grants that file exactly one
additive **read** (feature-005 §4a). For D there is no event to hang it on. A README that
states deletion universally documents a rule the system does not implement.

**2d. Adopter acquisition — created on first use, not seeded at install.**

*The gap is real.* `grep -rnI "\.aid/design" . --exclude-dir=.git`, filtered to exclude
`./.aid/works/work-006*` and `./.aid/.temp/`, returns **0 files**. Nothing in the installers,
the templates, the ignore machinery, or any skill mentions the path. Landing the folder on
`master` therefore gives it to this repo only, while REQUIREMENTS §3 names adopters the
primary beneficiary and all 36 new skills write into it.

*The mechanism.* A rule in `design-lifecycle.md`, binding every `design`-stage skill:

> Before writing a seed, ensure `.aid/design/` exists. If `README.md` is absent from it,
> copy `canonical/aid/templates/design-folder-readme.md` into it as `README.md`. If that
> template is missing from the bundle, write the seed anyway and warn once — a missing
> convention document must never block the user's actual work.

*Why the path needs no runtime root resolution, and why it must be written in the canonical
form.* The previous draft wrote `<agent-root>/aid/templates/…` and enumerated the five tool
roots without saying how a skill body chooses among them at runtime — a project may carry
more than one install, and a skill body has no tool argument (the installer's
`seed_settings_yml` gets its root from one: `root="$(_root_dir "$tool")"` at
`lib/aid-install-core.sh:2106`, spent at `:2109`
`tmpl="${target}/${root}/aid/templates/settings.yml"`). The resolution is not a runtime choice at all: it is
done **at render time**, by the same mechanism every shipped skill body already relies on.
`rewrite_install_paths` (`.claude/skills/generate-profile/scripts/render_lib.py:145-175`)
rewrites `canonical/aid/templates/…` → `<install_root>/aid/templates/…` for each profile, and
`render.py` applies it to every emitted body (`:342`, `:346`, `:559`, `:561`, `:638`). Shipped
precedent, verified on disk — and the closest one is a template in the very tree
`design-lifecycle.md` joins: `canonical/aid/templates/shortcut-engine.md:300` reads *"Copy
`canonical/aid/templates/work-state-template.md` to …"*, and its renders read
`.claude/aid/templates/work-state-template.md`
(`profiles/claude-code/.claude/aid/templates/shortcut-engine.md:300`) and
`.codex/aid/templates/…` (`profiles/codex/.codex/aid/templates/shortcut-engine.md:300`). The
same holds for skill bodies (`canonical/skills/aid-review/SKILL.md:110` →
`profiles/claude-code/.claude/skills/aid-review/SKILL.md:110`). So the
installed contract already names the running profile's own root, one root per bundle, with no
five-way choice for the agent to make — and writing the path in any other form would defeat
the rewriter and ship a dangling reference. §7 B2 is the oracle.

Three properties make this the right shape, and each is checkable:

| Property | Consequence |
|----------|-------------|
| **Created on first use** | A project that never designs acquires neither folder nor README. This is the same doctrine this work already adopted for `roadmap.md` and `backlog.md` — REQUIREMENTS FR-9, *"created on first use by its own `create` skill"*, and feature-001 SPEC §1a. Seeding at install would contradict, inside one work, the decision the other feature took after four review rounds |
| **Never overwrites** | An existing `README.md` is user data once written |
| **Warn, do not fail, on a missing template** | Mirrors `seed_settings_yml`'s own choice — the reasoning comment at `lib/aid-install-core.sh:2111-2113` (*"a silent skip re-triggers the 'no settings.yml' class this seed exists to fix, and the format gate would then warn forever"*) and the `WARN … ; return 0` it justifies at `:2114-2117` — with the failure mode inverted, because a design seed is worth more than its README |

*Considered and rejected: an install-time seed function.* This was the previous draft's
mechanism. It is rejected on four grounds, all verified on disk rather than reasoned from:

1. **It would break the existing uninstall symmetry, or inherit it.** `seed_settings_yml`'s
   header comment (`aid-install-core.sh:2096-2101`) says the file *"must survive `aid
   remove`/prune"* — and the same file contradicts that comment 400 lines later:
   `:2504-2517` runs `rm -f "${aid_meta_dir}/settings.yml"` when the last tool is removed,
   *"symmetric with `seed_settings_yml`"*. So the seed survives prune and a **partial**
   remove, but not a **full** uninstall. An implementer told to model a new function on that
   precedent "in its particulars" would mirror the symmetric deletion — and `.aid/design/`
   holds hand-authored user thinking, not a regenerable config file. The previous draft's
   property table had no uninstall row at all, so nothing stopped that.
2. **The parity guard it named cannot run.** `tests/canonical/test-install-parity.sh:4-13`
   records that its PAR01–PAR12 core scenarios were retired; its only surviving scenario is
   PAR13 (`:51-81`, and the file is 83 lines) — **two** `grep -qF "dashboard/MANIFEST"`
   checks against the two installers (PAR13a `:65`, PAR13b `:71`) plus one
   `grep -qxF "home.html"` against `dashboard/MANIFEST` itself (PAR13c `:77`). Three
   assertions, not four. It never sources `lib/aid-install-core.sh` and never imports
   `lib/AidInstallCore.psm1`. (The belief has a shipped source: `AidInstallCore.psm1:1657`
   still comments *"test-install-parity.sh diff -r covers .aid/settings.yml"*, which the
   PAR01–12 retirement made false. That stale comment is pre-existing and out of scope
   here.) The suites that *do* drive the provisioning functions are
   `tests/canonical/test-install-provisioning.sh` (bash; sources the core at `:24`, drives
   `seed_settings_yml` at `:73-97`, SE1–SE3b) and its twin
   `tests/windows/Test-InstallProvisioning.ps1` (`:59-79`, the same SE1–SE2 scenarios against
   `script:Initialize-AidSettingsFile`), wired into CI at
   `.github/workflows/installer-tests.yml:119` and `:135`.
3. **It costs a coverage re-bootstrap.** New assertion ids in the bash suite change the
   collected set, and the coverage-parity gate enforces once `tests/coverage-baseline.tsv`
   exists — it does (`.github/workflows/coverage-parity.yml:119-127`). The Windows twin is
   unaffected: the collector's suite set is `"$dir"/test-*.sh`
   (`tests/coverage-parity.sh:205`) with `dir` defaulting to
   `DEFAULT_DIR="${REPO_ROOT}/tests/canonical"` (`:82`, consumed by `cmd_collect` at `:277`),
   so no `tests/windows/` file is collected. (Not `:14`, as the previous draft cited — that
   line is about `run-all.sh`'s glob, a different consumer.)
4. **It would add a further adopter-facing change to C-6.** Editing both installer twins
   changes what every adopter's fresh install produces on all five profiles. REQUIREMENTS
   C-6 now lists three adopter-facing changes — none of them an installer change — so this
   would have been a fourth (§8 carries the accounting forward honestly rather than
   deferring it).

Under the chosen mechanism, none of the four applies: no installer library is touched, so
there is no twin to keep in parity, no uninstall path to make symmetric, no new bash
assertion, and no further C-6 item. The naming question the previous draft left unanswered —
the PowerShell module has no `seed_*` function; its analogue is
`function script:Initialize-AidSettingsFile` (`AidInstallCore.psm1:1636`), alongside
`script:Update-AidGitignore` (`:1674`), Verb-Noun throughout — becomes moot for the same
reason.

**2e. The inherited seed lands as-is.** `knowledge-graph-redesign.md`'s header reads
`**Status:** not started · **Seeded:** 2026-08-08 · **Predecessor:** work-005 (knowledge
graph, PR #178, merged)`. It is a **not-started successor**, not a description of work-005,
which shipped. The folder's own rule covers it: *"Seeds for work that was never started are
**kept** — that is the folder's whole purpose."* Its work references are permissible: the
no-work-names rule binds `.aid/knowledge/` only, and no hygiene gate reaches `.aid/design/`
(`.github/workflows/test.yml:155-225` scopes every KB check to `--root .aid/knowledge` or
`find .aid/knowledge -maxdepth 1`).

**2f. `.gitignore`: no change, and the reason it needs none.** The AID-managed region is
machine-regenerated from a hardcoded six-entry list (`aid-install-core.sh:2155-2160`, mirrored
at `AidInstallCore.psm1:1621-1626`; the markers' own comment at `aid-install-core.sh:2143-2145`:
*"The lines BETWEEN the markers are owned by the installer and
rewritten on every add/update"*), so it cannot record a decision — it can only ignore or not
ignore. `.aid/design/` is **tracked by absence** from that list. Verified for this repo:
`git check-ignore -v .aid/design/README.md` returns no match. The decision is recorded here
and in the folder's README, which is where a decision belongs.

### 3. The contract (`design-lifecycle.md`)

Free-form prose read by a dispatched agent, like any `state-*.md` reference.

**3a. Stage semantics, split by stage — because the two stages bind different populations.**

The previous draft titled this section "class 1" and put the contract's hardest invariant
inside it, which left the 14 class-2 `design` skills and `/aid-brainstorm` — the writers
most likely to violate it, since they design *code* — bound by nothing.

*The `design` stage binds all 22 design-stage writers* (the 7 class-1 `design` skills, the
14 class-2 `design` rows, and `/aid-brainstorm`):

| Reads | Writes | Terminates by |
|-------|--------|---------------|
| its seed if present, the KB, project source | its seed in `.aid/design/` **only** | Presenting; the user iterates by re-invoking |

> **A recorded deviation from REQUIREMENTS FR-1.** FR-1's table gives the `design` verb a
> `Reads` value of `.aid/design/` alone. The row above widens it to "its seed if present, the
> KB, project source". The widening is deliberate — a seed written without reading the KB
> would restate what the project already documents — but it is a departure from the
> requirement's own table, and it is recorded **here, by the contract's owner**, rather than
> only in the consuming spec. feature-003 §6a records the same deviation from the consuming
> side; both records describe one decision, not two.

> **The 22 is not FR-11 CC-7's 22.** CC-7 counts the `design` **family**'s catalog rows —
> bare `/aid-design` + 14 grid rows + 7 design artifacts — and puts `/aid-brainstorm` in a
> separate `brainstorm` family. The 22 above counts this work's **new `design`-stage
> writers**: 7 + 14 + `/aid-brainstorm`, with bare `/aid-design` out of scope (§5). The two
> sets differ by exactly one member and coincide in size by accident. Every count-bearing
> claim about the family uses CC-7's; this section's 22 is a binding population, not a
> family count.

> **`design` never writes `.aid/knowledge/` and never writes production code.**

That is the hardest invariant in the contract and the one an agent will most readily violate
by "helpfully" finishing the job. It binds all 22 without exception, and §3g gives it a row.

*The `create` and `update` stages bind class 1 only* (the 7 design artifacts) — class 2's
`create`/`update` doorways already exist and are not authored by this work (§3b):

| Verb | Reads | Writes | Terminates by |
|------|-------|--------|---------------|
| `create` | the seed, the KB, project source | its owned region of the destination document + any user-requested output | **On realization:** consuming (deleting) the seed. **On a routing exit** (§3c rows 2 and 4): naming the skill it routes to and stopping, having realized nothing and written nothing — the seed is **left in place** for that skill to consume. Consumption is not unconditional; it is the terminator of the realizing path only |
| `update` | the destination, previously-created outputs, **and its `.aid/design/` seed when one is present** (REQUIREMENTS FR-11 CC-3) | those same targets | Writing the revision — **and consuming (deleting) the seed if one was read**. `update` never *requires* a seed |

The `update` row's seed clause is REQUIREMENTS CC-3, referred to and not restated here. It is
what gives a **routed** seed a consumer: when `create` routes (§3c rows 2 and 4) it has
realized nothing, so the seed survives and the `update` run it routes to becomes the
realization event. Without it a routed seed only accumulates — the failure §5 warns about.
features 003 (§6b, §6c) and 004 both depend on this row.

**3b. The two classes — derived, not asserted.**

Class 2 is the 14 artifacts of REQUIREMENTS FR-5. The previous draft defined them as
*"pre-existing **generated** engine doorways (`shortcut-catalog.yml` rows with no
`repurpose` key)"*, which is false for one of the fourteen. Rather than patch the one
counterexample the review named, the whole class was re-derived: scan each of the 28
`create`/`update` rows for the 14 artifacts and read its `repurpose` key. Per-row form:

```
for v in create update; do for a in api ui theme cli data-model data-pipeline messaging \
    integration job config infra test document dashboard; do
  printf '%s-%s %s\n' "$v" "$a" \
    "$(grep -A7 "^  - name: aid-$v-$a\$" canonical/aid/templates/shortcut-catalog.yml \
       | grep -c 'repurpose: true')"
done; done
```

Both verbs, all fourteen artifacts, 28 rows — the previous draft printed only the `create`
half, so a reviewer could not re-derive the stated result from the printed form.

Result: exactly **two** of the 28 carry it — `aid-create-document`
(`shortcut-catalog.yml:459-466`) and `aid-update-document` (`:467-474`). Every other row,
including both `dashboard` rows (`:566-572`, `:573-579`) and both `test` rows, carries no
`repurpose` key and is a generated doorway. So class 2 has **two sub-cases**, and every
obligation delegated to "the engine" must say which:

| | class 2a — 13 artifacts | class 2b — `document` |
|---|---|---|
| `create`/`update` doorway | generated; runs `shortcut-engine.md` | hand-authored collapse skills; **never runs the engine** (`shortcut-scaffolding/document.md:3-14`: *"This file is **no longer consulted by the shared engine** … the collapse bodies own the actual state machine"*) |
| Seed reaches `create` via | feature-005 §4a's engine read at CAPTURE Step 2 | feature-005 §4b's two one-line reads, added directly to the two `SKILL.md` bodies |
| Readiness gate | **No** — the engine has no refusal state, and adding one would exceed FR-10's read-only grant | **No** — by parity with 2a; feature-005 §4b's read is explicitly non-mutating and additive |
| Verify depth on `create`/`update` | the engine's own GATE state governs; not this contract's to set | the collapse skills' own bodies govern; **there is no GATE state to delegate to** |
| Seed deleted at `create` | **No** — persists; deletion is manual (§2c Entry C) | **No** — same |

The distinction is not academic: the previous draft voided two obligations for `document` by
delegating them to a mechanism that does not run for it.

**`/aid-brainstorm` is a third case**, not a member of either class. Roster arithmetic:
7 design artifacts × 3 verbs = 21, plus `/aid-brainstorm` = 22, plus 14 class-2 `design`
rows = **36** (REQUIREMENTS FR-5 § *Roster arithmetic*, `:343-344`). It writes a seed and has no `create` counterpart,
so every `create`-stage rule is inapplicable rather than waived.

**3c. Region ownership — scope, then the first-write rule, then mechanics.**

*Scope.* This rule binds **the 36 new skills only**. It is not a claim about who may write
the destination documents in general, and the previous draft's closing sentence — *"Only
`/aid-discover` is the wholesale writer"* — is refuted by this work's own REQUIREMENTS FR-1
§ *KB write ownership (resolved)*, `:231-236`, which names four legitimate KB writers at
`:233-234`. At least two write wholesale:
`/aid-describe` DESCRIBE-SEED authors greenfield KB docs from nothing
(`canonical/skills/aid-describe/SKILL.md:25`, `:259-261`) and `/aid-graph` regenerates
`relationships.md` (`canonical/skills/aid-graph/SKILL.md:4-5`). The completeness claim is
therefore **dropped**; what survives is the narrower, verified pair it was built on: the two
*targeted-edit* skills bind themselves not to rewrite —
`canonical/skills/aid-update-kb/references/state-apply.md:252-258` (*"the sub-agent makes a
targeted in-place edit to the existing doc; it does not regenerate, restructure, or rewrite
the doc wholesale"*) and `canonical/skills/aid-housekeep/references/state-kb-delta.md:569`
(*"apply the user's choice exactly — no auto-resolution, no default rewrite"*). The new
skills adopt that same discipline for their own region.

*The first-write rule, rebuilt.* The previous draft said `/aid-create-mvp` "run first stops
and says so". That makes refusal the **default** path — REQUIREMENTS FR-9 makes `roadmap.md`
conditional and created on first use, feature-001 SPEC §1a records that neither document gets
a file under `canonical/aid/templates/` and that `synth_default_seed` is untouched, and its
AC-4 (*"Absent is fine"*) requires the doc-set presence check to exit 0 and name nothing
when `roadmap.md` is absent. It also
contradicts REQUIREMENTS AC-6, which requires `design → create → update` to complete for
each of the seven, `mvp` included.

**The rule itself is REQUIREMENTS FR-1's** (`:259-283`, the region-level statement and its
four bullets), **with the region-owning case settled as FR-11 CC-5.** Per FR-11 it is
**referred to, not restated** — the table below is the *situation-to-action dispatch* the
contract's readers need, and each row names the authority it dispatches on rather than
re-deriving it:

| Situation at `create` | Action | Authority |
|---|---|---|
| Destination document absent, this skill **owns the whole document** | Create the document, then write its content into it | FR-1 `:274-277`; FR-9's "created on first use". Applies to `/aid-create-roadmap`, `/aid-create-backlog`, and every foundation `create` skill (whose destination resolves by **concern**, per CC-6, not by a hardcoded filename) |
| Destination document absent, this skill **owns only a region** | Route to the document's owner, name it, leave the seed in place. Do **not** create the document | **CC-5.** Its only instance is `/aid-create-mvp` → `/aid-create-roadmap` (feature-003 §6b, oracle V16). The routed seed's consumer is the `update` run, per CC-3 (§3a) |
| Destination present and populated, owned region absent | Add the region — a populated destination is the normal case, not a refusal condition | FR-1 `:259-265`: four of the seven destinations are seed documents that exist in every project that has run `/aid-discover` |
| Owned region present and carrying committed content | Route the user to the corresponding `update` skill and stop | FR-1 `:271-273`. This is the contract's only *destination-side* refusal (§4's readiness gate is the other, and it is seed-side); it never halts with nothing done. The seed survives to the `update` run (CC-3) |
| *(not a situation — the standing constraint under all four)* Any other region of the document | Read, preserve byte-identical, never rewrite | This section's write discipline, below |

**Four situations, one standing constraint.** The last row is not a fifth branch: it holds in
every one of the four. feature-004 §6b resolves *"each of its four situations"* for the
foundation artifacts, and feature-003 §6b's three-column table does the same for `roadmap`,
`mvp` and `backlog`; both readings are correct against this table.

Two things this contract deliberately does **not** state, because FR-11 assigns them
elsewhere: the four registration surfaces a newly created conditional document must occupy
(**CC-4** — feature-001's, defined once there), and the `.aid/settings.yml` `doc_set` entry
a `create` writes when it creates one (**CC-1**, discharged as an effect of running the skill
per **CC-2**, in features 003 and 004). No row above may be read as authorizing a different
set.

REQUIREMENTS AC-6b is the check that keeps this honest: in **this repository as it stands**,
`/aid-design-architecture → /aid-create-architecture` must reach the realization event and
consume the seed even though `architecture.md` is populated.

*Mechanics,* for the one shared destination — `roadmap.md`, split between `/aid-*-mvp` and
`/aid-*-roadmap`:

| Question | Rule |
|----------|------|
| Region identity | The literal heading `## MVP`, matched exactly. Fixed **here** so both owning skills and feature-001's matrix rows agree on one token |
| Region extent | From that heading to the next heading of level 2 or shallower, or EOF. Deeper subsections belong to the region |
| Position when created | Immediately after the `## Contents` block, before the first content section — **not** "before the first other `##`", which would place the MVP above the document index and break KB layout order. feature-003 §3c owns the exact anchor and this row defers to it |
| Who may create the region | `/aid-create-mvp` and `/aid-update-mvp` only |
| Who may create the document | **`/aid-create-roadmap` only** — the application of **REQUIREMENTS FR-11 CC-5** to this destination, referred to rather than restated. `/aid-create-mvp` against an absent `roadmap.md` takes row 2 of the first-write rule above. feature-003 §3c and its V16 agree |
| Minimum document shape | Whatever feature-003 defines, which must place `## MVP` per the two rows above. feature-001 SPEC §3b (*"Shape belongs to feature-003, wholly"*) assigns document shape to feature-003 because no template exists |
| Write discipline | Read whole file → replace only the owned byte range → write back with every other region byte-identical. Never regenerate |

**3d. Derived outputs are resolved by asking (FR-8).** `update` asks the user which
previously-created outputs to update, **every run**. No frontmatter backlink, no manifest,
no registry, no state between runs. Stated explicitly because a manifest is the first thing
an implementer reaches for. Consumed by every `update` skill in features 003 and 004.

**3e. Skill shape.** Modeled on `canonical/skills/aid-design/SKILL.md`. It binds class 1's
21 skills, class 2's 14 new `design` rows, and `/aid-brainstorm` — with one carve-out, the
`create`/`update` verify depth, which class 2 and `/aid-brainstorm` have no site for. §3g
carries the per-rule detail.

*Frontmatter:* `name` (== directory name), `description`, `allowed-tools`, `argument-hint`.

*The `description` contract (NFR-4, AC-8).* Every description states what the skill does
**and names its nearest confusable neighbour as a negative route**, in the manner
`/aid-design` and `/aid-prototype` already point at each other
(`canonical/skills/aid-design/SKILL.md:11-12`). Specified here, once, because otherwise 36
descriptions get forked across three features — the exact failure this feature exists to
prevent. **Who writes which side of a confusable pair, and where the pair set is verified
whole, is REQUIREMENTS FR-11 CC-9** — referred to, not restated. Its application here:
feature-005 §7b–7c carries the per-skill neighbour assignments for the fifteen doorways it
ships (and §7a the five shipped descriptions it edits), and feature-003 §6d for its nine.

*States:* INTAKE → (DESIGN|CREATE|UPDATE) → VERIFY → PRESENT → DONE.

*Allocation:* follow `canonical/skills/aid-design/SKILL.md:45-53` — consult the Work
Initiation Gate (`canonical/aid/templates/work-initiation-gate.md`) by running
`bash canonical/aid/scripts/works/enumerate-works.sh`; on new work,
`bash canonical/aid/scripts/works/worktree-lifecycle.sh create <work-id> <name>`, stop on a
non-zero exit or empty path, else enter the resolved path; then allocate `pipeline.path:
lite`, `initiator: aid-<verb>-<artifact>`, `lifecycle: Running`, `active_skill: …`.
**`phase` is not driven** — that is what keeps NFR-3 and AC-10 true without touching the
enum. (REQUIREMENTS FR-3 `:290-292` — *"allocate a `work-NNN` folder, run single-shot, get
graded"* — makes work-folder allocation the shape *these* skills take; see §6 for the one
place a sibling feature previously disagreed.)

*Dispatch:* `aid-architect`, tiered by complexity; verifier tier ≥ producer tier.

*"Full verify" — defined, not invoked.* The term carries a normative obligation in four
cells of §3g's binding table and was previously defined nowhere in this spec, against §7 J1's
self-sufficiency bar. It means the three-step loop at
`canonical/skills/aid-design/SKILL.md:71-79`:

1. A mechanical grounding check with no dispatch — decisions cite the KB or source they
   build on.
2. Adversarial verification by a clean-context `aid-reviewer` dispatch, writing a
   review-quality ledger to `.aid/.temp/review-pending/<work>-verify.md`.
3. `bash canonical/aid/scripts/grade.sh --explain <ledger>`; not clean → loop to the
   producing state; circuit-breaker at 3 cycles → IMPEDIMENT + `lifecycle: Blocked`.

Contrast, so the term carries information: `/aid-prototype`'s **light** check is a single
clean-context dispatch with one return-to-BUILD and no loop
(`canonical/skills/aid-prototype/SKILL.md:71-78`).

**3f. Catalog row shape.** All 36 rows hand-authored: `repurpose: true`, so
`build-shortcut-skills.py` skips them (`shortcut-catalog.yml:105-109`). Required fields:
`name` (== directory), `verb`, `artifact`, `alias_of: null`, `group`, **`default_type`**
(closed 8-enum; the live `aid-design` row at `:441-448` uses `DESIGN`), `intent`,
`repurpose: true`.

*Count consequences handed to feature-006 — as a derivation, not a list.* The previous draft
asserted a five-item list was "the full set, not a sample"; it was neither, and asserting
completeness over a corpus that spans `docs/`, `site/`, the KB, and five rendered profiles is
not something a spec can do reliably. Feature-006 gets the search instead:

```
grep -rnEIl '(58[- ]row|58 rows|76 skill|76 on-disk|34 (verb-first|shortcut|engine-generated)|24 (hand-authored|repurpose|`repurpose`)|24 rows)' \
  --include='*.md' --include='*.mdx' --include='*.html' --include='*.yml' \
  --include='*.sh' --include='*.mjs' --include='*.py' --include='*.json' . \
  | grep -v '^./.aid/works/' | grep -v '^./.aid/.temp/'
```

Run on the current tree this returns **51 files**: `profiles/` 15, `site/` 10,
`.aid/knowledge/` 10, `docs/` 6, the dogfood mirrors `.claude/` 3 and `.cursor/` 2,
`canonical/` 2, `tests/` 2, and the root `README.md`. Classifying each hit as hand-edited
versus generated-and-therefore-following is part of feature-006's sweep — the 15 `profiles/`
and 5 dogfood hits include both kinds, since the rendered catalog and `state-classify.md`
mirrors follow their canonical source but `profiles/*/README.md` is not produced by
`run_generator.py` (no README handling exists in
`.claude/skills/generate-profile/scripts/`). The sweep's completion oracle is that re-running
the command after the change returns nothing (§7 H1).

Four specifics that the derivation alone will not tell feature-006, each verified here:

- **A live repo-wide count gate already exists, and it is the primary instrument — not this
  section's `grep`.** `tests/canonical/check-skill-counts.mjs` is a repo-rooted guard that
  derives every stated skill count and reports each disagreeing line with its file, line,
  quantity and expected value. Its header (`:2`) declares it a *"REPO-WIDE guard for every
  stated skill count"*, scoped (`:28-30`) to `README.md`, `docs/`, `.aid/knowledge/`,
  `canonical/`, the repo-local maintainer skills and `site/src/content/docs/` — the same
  corpus the 51-file sweep enumerates. It is executed by
  `tests/canonical/test-skill-counts.sh:49` (`node tests/canonical/check-skill-counts.mjs`).
  Run on the current tree it reports *"Files scanned : 520 / Claims checked: 175 / Marked
  history: 12 / All 175 stated skill counts agree with the derivation."*
  **feature-006 §3 (*"Count-bearing surfaces: run the guard, do not hunt"*) owns the sweep and
  is already built on this guard**, including the three of its own tables that need edits —
  `SUPERSEDED` (58 / 24 / 76 join their quantities once superseded, `:133-141`),
  `MARKER_CAP = 12` (`:319`), and `CLAIM_FLOOR = 120` (`:374`). This section's `grep` is a
  *cross-check on the surfaces the guard does not read* — `profiles/` and the dogfood mirrors,
  which it **excludes** deliberately because byte-identity covers them (`:31-35`), and
  `tests/` and `site/scripts/`, which sit on its **"NOT YET SCANNED"** list (`:36-39`). It is
  not a substitute for the guard. The previous draft asserted
  the hard assertions "are all in one suite" on the strength of a `*.sh`/`site/scripts` glob
  that structurally cannot see a `.mjs` file under `tests/canonical/`; that claim is
  **withdrawn**, and its replacement is the bullet below, stated over a search that can
  actually reach the file.
- **The hardcoded roster integers live in one file — but the search must include
  `tests/canonical/*.mjs`, and it does not return all of them.** Searched with
  `grep -rnE '(assert_eq|toBe|toHaveLength|-eq)[^0-9]*(58|76|34|24|94|112)' tests/canonical/*.sh tests/canonical/*.mjs tests/*.sh site/scripts/*.mjs site/scripts/__tests__/*.mjs`.
  It returns **seven** lines. The roster hits are all in
  `tests/canonical/test-deploy-monitor-repurpose.sh` — DMR30 `TOTAL_ROWS == 58` (`:319`),
  DMR31 `CANONICAL_ROWS == 58` (`:320`), DMR33 `REPURPOSE_ROWS == 24` (`:324`). The other
  **four** returned lines are **not** roster assertions, and are named so a reader does not
  chase them: `test-deploy-monitor-repurpose.sh:326` DMR34
  (`CANONICAL_ROWS + ALIAS_ROWS == TOTAL_ROWS` — derived, no literal), and
  `test-aid-cli-parity.sh:1188`/`:1190` plus `test-connector-consumption-linkage.sh:204`
  (`O24`/`DEL-24` identifiers, not counts). One roster assertion the search does **not**
  return, because its literal sits on the expected-value line rather than the `assert_eq` line:
  **DMR32**, the zero-alias assertion, opens at `:321` and pairs `0` against `58` in its
  expected-value string at `:322`. After this work: 94 / 94 / 0-of-94 / 60 — and DMR32's
  `58` must move to `94` with the rest, which feature-006 §4's table does not list. That is
  the one hand-off this bullet exists to make.
- **`test-catalog-dirs-parity.sh` holds no numeric assertion at all**, despite REQUIREMENTS
  AC-11 naming it. Its own header says so (`:22-27`, *"Count-AGNOSTIC BY DESIGN: this suite
  derives its row set from the catalog and holds NO expected total, so it passes at any row
  count"*), and `grep -E 'assert_eq .*"(58|76|34|24|18)"'` over it returns nothing. What it
  carries is comment **narration** (`:14`, `:22-27`) that must be refreshed — a doc edit, not
  a test edit. Handing it over as an assertion would send feature-006 looking for something
  that is not there.
- **`site/scripts/__tests__/gen-reference.test.mjs` needs no numeric edit either.** Its
  roster reconciliation is derivation-based (`:170-201`: catalog rows ∪ `CURATED_SKILL_NAMES`
  versus on-disk directories) and holds no skill-count literal. `grep -n 'toHaveLength'` over
  it returns **five** calls, none of them a roster count: `:250` and `:254` (agents, 9),
  `:260` and `:265` (KB docs, 14), and `:363` `expect(manifest.entries).toHaveLength(4)` (the
  generator's own manifest entry count). None of the three quantities moves in this work. The
  previous draft enumerated only the first four and presented that as covering the calls.
  `docs/diagram-content-reference.md:24`
  describes it as *"asserts 76 on-disk dirs"*, which is a stale description of a test that
  derives rather than asserts — feature-006 should correct the prose, not the test.

**3g. What binds which — one row per rule.** A blanket per-section statement is wrong,
because §4's seed *shape* is read by feature-005's engine read on behalf of the **class 2**
artifacts. The table is the checkable form of AC-3: every rule stated in §2d, §3 and §4
appears here exactly once.

*How the row set is derived, so C1 is re-runnable rather than recalled.* Enumerate the
italicised/bolded rule headings of §2d, §3a–§3f and §4 in file order:
§2d **1** (acquisition, with its never-overwrite and warn-do-not-fail clauses);
§3a **3** (`design` stage semantics, the `design` invariant, `create`/`update` stage
semantics); §3b **1** (seed deleted at `create`);
§3c **2** (region ownership + write discipline, the first-write rule);
§3d **1**; §3e **5** (skill shape incl. the `description` contract, allocation, **dispatch
tiering**, verify depth on `design`, verify depth on `create`/`update`);
§3f **1**; §4 **5** (seed shape/headings, `## Destination`, naming, readiness gate + detection
rule + placeholder convention, no `changelog:`). Total **19**. The dispatch-tiering row is the
one r5 found missing at r4's recurrence — it was stated in §3e and had no row.

| Rule | Class 1 (7) | Class 2 (14) | `/aid-brainstorm` |
|------|-------------|--------------|-------------------|
| §2d create `.aid/design/` + seed its `README.md` on first use (never overwrite an existing one; warn, do not fail, on a missing template) | Binds | Binds | Binds |
| §3a `design` stage: reads/writes/terminates | Binds | **Binds** | **Binds** |
| §3a **`design` never writes `.aid/knowledge/` or production code** | Binds | **Binds** | **Binds** |
| §3a `create`/`update` stage semantics, including `update`'s seed read + consumption (CC-3) | Binds | **No** — doorways pre-exist, not authored here | N/A (no counterpart) |
| §3b seed deleted at `create` — on the realizing path only; a routing exit leaves it for the skill it routes to (§3a, CC-3) | Binds | **No** — persists; deletion manual | N/A |
| §3c region ownership + write discipline | Binds | **No** — destination is a built artifact, not a document region | N/A |
| §3c first-write rule (four situations plus the standing preserve-other-regions constraint; the region-owning case is CC-5) | Binds | N/A | N/A |
| §3d derived outputs resolved by asking | Binds (`update`) | N/A | N/A |
| §3e skill shape: frontmatter fields, state list, `description` contract | Binds | Binds — its `design` row | Binds |
| §3e allocation via the Work Initiation Gate | Binds | Binds | Binds — but see §6 |
| §3e dispatch: `aid-architect`, tiered by complexity; verifier tier ≥ producer tier | Binds | Binds — its `design` row | Binds |
| §3e verify depth on `design` | Full verify | Full verify | Full verify |
| §3e verify depth on `create`/`update` | Full verify | **N/A** — 2a: the engine's GATE state; 2b: the collapse body (§3b) | N/A |
| §3f catalog row shape | Binds | Binds — its `design` row | Binds |
| §4 seed shape and literal headings | Binds | **Binds** — feature-005's read consumes it | Binds |
| §4 `## Destination` section | Required | Required | **Optional** (FR-7: no fixed destination) |
| §4 naming: `<token>` = `artifact` | Binds | Binds | **No** — confirmed slug (`artifact` is `""`) |
| §4 readiness gate + its detection rule + the `{…}` placeholder convention the rule depends on | Binds | **No** — neither 2a nor 2b has a refusal state | N/A (no `create` counterpart) |
| §4 no `changelog:` | Binds | Binds | Binds |

### 4. The seed template (`design-seed.md`)

**Naming.** `.aid/design/<token>.md`, where `<token>` is the row's `artifact` when it is
non-empty — which covers 35 of the 36 new skills. **One** of the 36 has an empty `artifact`:
`/aid-brainstorm` (REQUIREMENTS FR-7; feature-005 §5b's row shows `artifact: ""`). For an
artifact-less writer, `<token>` is a kebab-case slug derived from the subject and confirmed
with the user at INTAKE.

(The previous draft said "two of the 36", counting bare `/aid-design` — whose `artifact` is
indeed `""` (`shortcut-catalog.yml:441-448`) but which is a pre-existing row, out of scope
per §5, and therefore not one of the 36. The rule still covers it, should it ever come into
scope; the count was simply wrong.)

**Sections** — literal heading text, level 2, in this order. Fixed, not indicative, for two
reasons: §4's detection rule is a *machine* check anchored on the literal string
`## Open questions`; and three independent consumers read this one file shape — the 22
`design`-stage writers, feature-005 §4a's engine read at CAPTURE Step 2 (which reaches the
26 generated `create`/`update` doorways of the 13 non-`document` paired artifacts), and
feature-005 §4b's two hand-authored `document` bodies. One shape, or a private convention per
reader.

| # | Heading | Content | Required |
|---|---------|---------|----------|
| 1 | `## Problem` | What is unresolved, in the user's words | Yes |
| 2 | `## Options considered` | Including rejected ones and why | Yes |
| 3 | `## Current direction` | What the seed proposes; rewritten each iteration | Yes |
| 4 | `## Constraints` | What the design must not break | Yes |
| 5 | `## Open questions` | What is still undecided | Yes |
| 6 | `## Destination` | Which document or artifact `create` realizes this into | **Optional** — omitted by artifact-less writers whose destination is undecided |

**Placeholder convention.** Unfilled content in the shipped template is written as a
brace-delimited placeholder, `{like this}` — the convention already used across
`canonical/aid/templates/` (e.g. `work-state-template.md`: `{phase}`, `{skill}`,
`{short text}`; `knowledge-base/architecture.md`: `{project}`, `{ModuleA}`). Stated here
because the detection rule below depends on it, and the previous draft made the detection
rule rest on a convention it never established.

*One render interaction, checked rather than assumed.* `design-seed.md` is a canonical
template, so `substitute_filenames` runs over it — but it substitutes only the three keys
`{project_context_file}`, `{reviewer_output_file}` and `{open_questions_file}` and leaves
every other `{…}` token untouched (`render_lib.py:108-116`). **`{open_questions_file}` is a
real collision hazard** given §4's `## Open questions` heading: the template's placeholders
must not use that key (or the other two), or the rendered seed template would ship a resolved
filename where a placeholder belongs and the detection rule's "unfilled placeholder" clause
would misfire. Any other brace token — `{the problem}`, `{option A}` — is inert.

**No `changelog:` and no `## Change Log`.** Not because the seed is "transient by
construction" — §3b and §2c establish that class-2 seeds persist, so that reason was false
for two thirds of its users. The real reasons are two: `## Current direction` is *rewritten*
each iteration, so a changelog would be a lower-fidelity duplicate of git; and the repo
carries no change-log apparatus on any Knowledge-Base-adjacent artifact —
`grep -rln '^## Change Log' canonical/aid/templates/ .aid/knowledge/` returns four files,
all of them pipeline-artifact templates (`feature.md`, `requirements.md`,
`requirements/requirements-template.md`, `specs/spec-template.md`), and none under
`knowledge-base/`. A seed is neither a pipeline artifact nor a KB doc, and follows the
latter.

**Readiness rule (class 1 only — see §3g).** `create` refuses to consume the seed while
`## Open questions` is non-empty, unless the user explicitly overrides. This is the *seed*
gate; it is orthogonal to §3c's destination-region rule, and neither one lets `create` stop
because the destination file is populated.

**Detection rule.** *Non-empty* means: between the `## Open questions` heading and the next
level-2 heading (or EOF), there exists at least one non-blank line that is (a) not the
literal token `None` and (b) not an unfilled placeholder — a line consisting wholly of a
single `{…}` span, per the convention above. Stated because "non-empty" is otherwise
underdetermined — blank lines, a `None` token and an unfilled placeholder each read as
"empty" to a human and "non-empty" to a naive check — and this is the one gate the contract
calls machine-checkable.

### 5. Bare `/aid-design` — behavior unchanged, on one sufficient ground

The first draft scoped it out; round 1 refuted both reasons; round 2 refuted the
*conformance* argument that replaced them. The conclusion survives; the reasoning is one
argument, with two withdrawn ones recorded so they are not re-proposed.

**The reason it stays unchanged:** its `create` counterpart cannot consume a seed. Bare
`/aid-create` is a **generated** engine doorway — its catalog row carries no `repurpose` key
(verified by the §3b scan) and `canonical/skills/aid-create/SKILL.md:16` carries the
`GENERATED … DO NOT EDIT BY HAND` banner. It is not a member of either class — its `artifact` is `""`, so it is none of the 14 — but it is
a generated engine doorway of exactly class 2a's kind, so a seed it read would be advisory and
never consumed. Redirecting bare `/aid-design`'s output to `.aid/design/` would
produce a file with no consumer and no deletion path — a seed that only accumulates.

**CC-3 does not rescue it, and that is checked rather than assumed.** CC-3 gives a routed
seed a consumer by making `update` read and consume one. Bare `/aid-update` is, like bare
`/aid-create`, a **generated** engine doorway with no `repurpose` key and an `artifact` of
`""` — so it is neither a class-1 `update` (which consumes) nor authored by this work. The
seed would still have no consumer on either stage. The argument therefore survives FR-11
intact.

**Withdrawn — "it has no artifact token."** True that its `artifact` is `""`, but §4's naming
rule already handles artifact-less writers with a confirmed slug, and `/aid-brainstorm`
relies on exactly that rule. The argument would rule out `/aid-brainstorm` too, which is in
scope.

**Withdrawn — "keptness is its discriminator."** The claim was that a seed is transient by
construction, so seed-writing would dissolve FR-6's `design` = kept vs `prototype` =
throwaway rule. It self-refutes: `ui` — the very artifact FR-6 adjudicates — is class 2,
whose seeds persist (§3b, §2c Entry C).

**Consequence: no in-skill edits by this feature.** The four `DESIGN.md` sites in
`canonical/skills/aid-design/SKILL.md` — the DESIGN-state work-folder write (`:64`), the
VERIFY loop's subject (`:75`), PRESENT (`:87`), and DONE's "kept design record" (`:106`) —
are untouched, and §1f holds.

**What does change, and who owns it.** FR-6 requires narrowing bare `/aid-design`'s
frontmatter `description` to the catch-all. That string lives at
`canonical/skills/aid-design/SKILL.md:3-12`, the row is `repurpose: true` so the file is
hand-authored, and **feature-005 owns the edit** (its SPEC §7a, with a matching acceptance
criterion in its own list). Note that feature-005 §7a's current text edits **two** frontmatter
fields — the `description` at `:5` and the `argument-hint` at `:14`, since
`grep -c 'architecture sketch' canonical/skills/aid-design/SKILL.md` returns `2` — so G1's
scoped diff admits hunks anywhere in the YAML frontmatter block, not only in `description:`.
Because both features land on the same work branch, `git diff --exit-code` on that file is
unsatisfiable by construction — §7 G1 is a scoped diff naming the hunks instead.

### 6. Interface consumed by other features

Every consumer below also binds **§2 and §2d** — the landed folder and the first-use
acquisition rule — because §3g's first row binds all three populations without exception.
Stated once here rather than repeated per row, and matching feature-005 §9's own dependency
table, which names §2 and §2d explicitly.

| Consumer | Consumes (beyond §2/§2d) |
|----------|----------|
| feature-003 | §3a (both stage tables, incl. `update`'s CC-3 seed read), **§3b (class 1 — readiness gate, seed consumption, full verify; its §6 preamble binds it explicitly)**, §3c (scope, first-write rule, mechanics), §3d, §3e, §3f, §3g, §4 |
| feature-004 | §3a (both stage tables, incl. `update`'s CC-3 seed read), **§3b (class 1)**, **§3c (scope, first-write rule, write discipline — its §6b discharges each situation for a whole-document owner; it does *not* import §3c's `## MVP` byte-range mechanic)**, §3d, §3e, §3f, §3g, §4 |
| feature-005 | §3a (`design` stage only), §3b (the 14 and their 2a/2b split), §3e, §3f, §3g, §4 (the shape its read consumes), §5 (the description edit it owns) |
| feature-006 | §3f (the count derivation, the four specifics — including the `check-skill-counts.mjs` hand-off and DMR32 — and H1's completion oracle) |

§4 is **frozen once feature-005 starts** — its engine read and its two `document` doorway reads
consume seeds in that shape.

**A cross-feature conflict, surfaced here and since settled.** §3e binds every one of the
36 skills to allocate a `work-NNN` folder, because REQUIREMENTS FR-3 defines these skills
as taking *"the same shape `/aid-design` and `/aid-prototype` already have: allocate a
`work-NNN` folder, run single-shot, get graded"*, and NFR-5's grade floor presumes the
review gate a work folder carries. An earlier draft of feature-005 §5b said
`/aid-brainstorm` allocates none. Both could not hold; FR-3 was the tiebreaker and it says
allocate. **Feature-005 §5b now states allocation**, so the two specs agree on disk and
this contract binds all 36 without exception.

### 7. Verification

Every row is a **script** (a runnable command), a **suite** (a named existing test), or a
**review** (a judgement a human or reviewer makes). No row is a restatement of intent.

| # | Check | Oracle | Kind |
|---|---|---|---|
| A1 | The landed README is the template | `diff canonical/aid/templates/design-folder-readme.md .aid/design/README.md` → empty | script |
| A2 | No wrong skill name | `! grep -q 'aid-interview' .aid/design/README.md` | script |
| A3 | No unqualified deletion statement | `! grep -qF 'Delete the seed when the work ships' .aid/design/README.md` **and** `! grep -qF 'is deleted once it' .aid/design/README.md` | script |
| A4 | All four lifecycle entries present | `grep -c '^Entry [A-D] —' .aid/design/README.md` captured to a variable → `4` | script |
| A5 | No route to an uninstalled document | `! grep -q 'quality-gates.md' .aid/design/README.md` | script |
| A6 | Successor seed landed intact | `git show docs/graph-redesign-seed:.aid/design/knowledge-graph-redesign.md \| diff - .aid/design/knowledge-graph-redesign.md` → empty | script |
| B1 | Acquisition rule is stated, once | `grep -c 'design-folder-readme.md' canonical/aid/templates/design-lifecycle.md` captured to a variable → `1` — a second mention means the rule has already forked | script |
| B2 | Template is reachable at runtime on every profile, **at the path the rendered contract names** | Two parts. (a) `find profiles -path '*/aid/templates/design-folder-readme.md' \| wc -l` captured to a variable → `5`. (b) For each profile root `R` ∈ `.claude .codex .cursor .github .agent`: the rendered `design-lifecycle.md` under that profile contains the literal `R/aid/templates/design-folder-readme.md` and contains **no** occurrence of the string `canonical/aid/templates/design-folder-readme.md`. Part (b) is what fails if the acquisition rule is written in a form `rewrite_install_paths` cannot rewrite (§2d) — part (a) alone would pass on a dangling reference | script |
| B3 | First run creates folder + README | In a scratch project with no `.aid/design/`, run one `design`-stage skill → `.aid/design/README.md` exists and matches the template | review (manual run; the 36 skills do not exist until features 003–005) |
| B4 | Never-designed project acquires nothing | After a fresh install into a scratch target with no `design`-stage run: `test ! -d "$TARGET/.aid/design"` | script |
| C1 | Every rule has a binding row | Re-run §3g's stated derivation (its per-section rule tally) over §2d, §3a–§3f and §4; §3g's table has exactly one data row per rule, no duplicates and no orphans. At this revision that is **19** rows | review |
| C2 | No rule binds a population with no implementation site | For each `Binds` cell, the spec names where it is implemented | review |
| D1 | Artifact-less naming resolves | §4's rule yields a path for `artifact: ""` without inventing one | review |
| D2 | Readiness is machine-checkable | An implementer can code the detection rule from §4 alone, including the placeholder clause | review |
| D3 | Seed headings are fixed | §4's six headings match, byte for byte, what `design-seed.md` ships | script (`grep -c '^## '` on the template captured to a variable → `6`) + review |
| E1 | Absent document is routed, not refused and not created | `/aid-create-mvp` on a project with no `roadmap.md` names `/aid-create-roadmap` as the next step, leaves `roadmap.md` absent, and leaves `.aid/design/mvp.md` in place. It neither stops silently nor scaffolds a document it does not own (REQUIREMENTS CC-5). Same case as feature-003 V16 | review (behavioral; feature-003 owns the skill) |
| E2 | Populated destination does not refuse (AC-6b) | In **this** repo, `/aid-design-architecture` → `/aid-create-architecture` reaches realization and consumes the seed although `architecture.md` is populated | review (behavioral; feature-004 owns the skill) |
| E3 | Non-owned regions byte-identical | After `/aid-create-mvp` on a populated `roadmap.md`: `git diff -- .aid/knowledge/roadmap.md` shows hunks between the `## MVP` heading and the next level-2 heading **only**. The command is mechanical but the row is not runnable here — it requires *running* `/aid-create-mvp`, a skill this feature does not author (§1f) | review (behavioral; feature-003 owns the skill, as its V8) |
| F1 | "Full verify" is defined, not just named | All three of `grep -q 'grounding'`, `grep -q 'aid-reviewer'` and `grep -q 'grade.sh --explain'` succeed against `canonical/aid/templates/design-lifecycle.md` | script |
| G1 | Bare `/aid-design`'s **behavior** unchanged | `git diff master -- canonical/skills/aid-design/SKILL.md` shows hunks confined to the YAML frontmatter block (`:1-15` today, delimited by the two `---` lines) **and nowhere else** — in particular no hunk touching the four `DESIGN.md` sites, which `grep -n 'DESIGN.md' canonical/skills/aid-design/SKILL.md` locates (today `:64`, `:75`, `:87`, `:106`). The whole block, not `description:` alone: feature-005 §7a edits both `description` (`:5`) and `argument-hint` (`:14`), the two hits `grep -c 'architecture sketch'` returns. A whole-file `--exit-code` diff is wrong here: feature-005 edits this file on this branch | script |
| G2 | `phase:` untouched, **and the contract says so** | Two conjuncts, because the first alone cannot fail. (a) `git diff master -- canonical/aid/templates/work-state-template.md` → empty — kept because feature-004 AC-14 and feature-003 V23 both cite this form, but on its own it is vacuous here: no feature in this work edits that file, so it is empty whatever the 36 skills do. (b) The failing half, over what this feature actually ships: `grep -cF 'is not driven' canonical/aid/templates/design-lifecycle.md` captured to a variable → `1` (the allocation rule's *"`phase` is not driven"* clause, present exactly once), **and** `grep -nE '^[[:space:]]*phase:\|phase: *(Describe\|Define\|Specify\|Plan\|Detail\|Execute\|Design\|Brainstorm)' canonical/aid/templates/design-{lifecycle,seed,folder-readme}.md` returns nothing. A contract that omitted the clause, or that told its 36 readers to set a `phase:` value, fails (b) while passing (a) — which is the regression AC-10 exists to catch | script |
| G3 | Shipped footprint is additive only | Over the commit range this feature owns (`git diff --name-status <first-parent-before>..<last>`), restricted to `-- lib/ canonical/ install.sh install.ps1`: exactly three `A` entries — `canonical/aid/templates/design-{lifecycle,seed,folder-readme}.md` — and no `M` and no `D` entry at all. **`profiles/` is deliberately outside the path filter**, for two reasons verified on disk: the fifteen renders are produced by feature-006's single render run, not by this feature's commits (§8, I1); and that render also rewrites the five `profiles/*/emission-manifest.jsonl` build indexes, which are generated, are excluded from every install and release path (`release.sh:245`, `tests/canonical/test-aid-migrate.sh:1078`), and would otherwise make "no `M` entry at all" false by construction. The `profiles/` side is asserted by I1 instead. Run against the whole branch this row is meaningless: features 003–005 also write under `canonical/` | script |
| K1 | KB `.aid/` tree refreshed | In `.aid/knowledge/project-structure.md`, capture three line numbers with `grep -n` — the `.aid/` tree root line, the new `design/` line, and the `CONFIRMED by direct` line — and assert the `design/` line falls strictly between the other two. Position matters: a `design/` mention elsewhere in the doc would satisfy a bare `grep -q` while leaving the tree, and therefore the CONFIRMED claim beneath it, stale | script |
| H1 | Count sweep complete (feature-006) | §3f's `grep -rnEIl` command, re-run after the sweep, returns no file outside `.aid/works/` and `.aid/.temp/` | script |
| I1 | Render parity, **and this feature's three files reaching all five profiles** | Full `run_generator.py` + byte-identity gate, then resync the dogfood `.claude/` from `profiles/claude-code/` (feature-006). This is also where G3's deferred `profiles/` half is asserted: after that render, `git diff --name-status` over `-- profiles/` carries fifteen `A` entries for `design-{lifecycle,seed,folder-readme}.md` (three files × five profiles) and exactly five `M` entries, all of them `profiles/*/emission-manifest.jsonl`, each differing from its predecessor by exactly three added records | suite |
| J1 | Contract is self-sufficient | A reader can state both stage tables (including `update`'s CC-3 seed read), both classes and class 2's two sub-cases, the region mechanics and the first-write rule, the detection rule, "full verify", and the `description` contract without a second source | review |

The Kind column is the count; no total is restated here, because a restated total goes stale
the moment a row is added and has done so at every previous round. The `review` rows are not
soft spots to be traded away, and this paragraph accounts for **every** one of them rather
than a subset — the omission that recurred at r2, r3, r4 and r5. Nine rows carry Kind
`review`, and D3 pairs a script with a judgement. They fall into exactly two groups:

- **Judgements about this spec's own prose, which is this feature's product** — C1
  (row coverage), C2 (no orphan population), D1 (artifact-less naming resolves), D2
  (readiness is machine-checkable), J1 (self-sufficiency), and the review half of D3.
- **Behavioral checks whose subject skills are authored by features 003–005**, so they
  cannot run at this feature's own close — B3, E1, E2 and E3. They are stated here so those
  features inherit them (E1 ≡ feature-003 V16, E3 ≡ feature-003 V8, E2 ≡ feature-004's
  populated-destination case), not so they can be skipped.

5 + 4 = the nine `review` rows, with D3's script half and every other `script`/`suite` row
outside both groups.

### 8. Sequencing, dependencies, and shipped-behavior impact

**Internal order.** §2 (land + correct + wire the folder) → §4 (seed shape) → §3 (the
contract, which references the seed). §3g is written last, from the finished §3 and §4.

**Blocks features 003, 004, 005** — all bind §3 and §4.

**Depends on feature-001: no.** The previous draft claimed §3c's region contract depends on
feature-001's `roadmap.md` template. feature-001 has no template and says so
(SPEC §1a: *"No file under `canonical/aid/templates/` — that absence IS the mechanism"*;
§3b: *"Because there is no template, the structure of `roadmap.md` (including the `## MVP`
anchor) and `backlog.md` is defined by `/aid-create-roadmap` and `/aid-create-backlog`"*), and
its own dependency list states it is *"Independent of feature-002"*. The claim was also circular: it named as
a dependency the feature that feature-003 — which this feature *blocks* — owns. Corrected
direction: **this** feature fixes the `## MVP` token and the write mechanics (§3c);
**feature-003** places that anchor when it defines the document's shape. No ordering
constraint runs from feature-001 to this one.

**Feeds feature-006** — §3f's derivation, its four specifics (the `check-skill-counts.mjs`
hand-off and DMR32's `58` among them), and H1. **And depends on feature-006 for one oracle
half:** the render that puts this feature's three templates into the five profiles runs
**once, in feature-006** (feature-003 §9: *"the render is run **once**, in feature-006, not
per feature"*; feature-005 §9 *Boundaries* defers *"the full render, the byte-identity gate"*
there too). G3 is
therefore scoped to `canonical/` only and I1 carries the `profiles/` half, rather than
asserting fifteen `profiles/` additions inside a commit range that cannot contain them.

**Frozen after feature-005 starts:** §4.

**Shipped-behavior impact — stated, not denied.** The previous draft asserted *"Shipped-
behavior changes originating in this feature: none."* That is false in general and was
false for the mechanism the same draft prescribed. Precisely:

- This feature adds **three files** to every adopter's next `aid add` / `aid update`, because
  `canonical/aid/templates/*` renders into all five profiles and the installer copies the
  profile tree. What an install produces therefore changes, additively.
- It modifies **no existing shipped file**: no installer library (§2d), no engine, no
  scaffolding file, no `SKILL.md` (§1d, §1f, oracle G3).
- Bare `/aid-design`'s **behavior** is unchanged (§5); its `description` changes under
  feature-005.
- **The C-6 accounting, raised here and since corrected upstream.** This spec's three new
  templates are adopter-facing — they render to all five profiles, so every adopter acquires
  them on upgrade — while C-6 listed only two adopter-facing changes. **REQUIREMENTS C-6 now
  carries them as item 3**, described as additive and non-migration-bearing, which is what
  they are. Had §2d chosen the install-time seed, the item would have been materially
  larger; that is one of the four reasons it did not.

This feature makes no claim about the work's total roster arithmetic — REQUIREMENTS §7 C-6
and feature-006 own that accounting.
