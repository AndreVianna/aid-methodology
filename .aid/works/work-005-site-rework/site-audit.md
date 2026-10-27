# Site audit

The record of the site rework: every page checked against the repository, the corrections made, and the
figures the acceptance criteria compare against. Method and rules: REQUIREMENTS.md § 11, Feature 001,
Technical Specification. Run every command below from `site/` unless a row says otherwise.

## Baseline figures

| Measure | Before | After | Target |
|---|---|---|---|
| AC-4 line total (command below) | 53944 lines in 138 files (commit `71b16c35f`, measured 2026-10-26) | pending | at most 21577 lines (60% below the before figure) |
| AC-4 line total with `tests` added to the folder list (NFR-3 counts all tests; command below) | 53944 lines in 138 files (no `tests/` folder at the baseline; re-measured by Feature 005 at the same commit) | pending | at most 21577 lines |
| AC-4 file count in `scripts/` (`find scripts -type f \| wc -l`) | 79 | pending | at most 2, each at most 300 lines |
| Test files (`find . -name '*.test.*' -not -path './node_modules/*' \| wc -l`) | 50 | pending | only the FR-8 group files named in Feature 005 |
| AC-2 skill pages (`ls ../canonical/skills \| wc -l`) | 37 | pending | equal to the number of `dist/skills/*/index.html` |

AC-4 command, unchanged from REQUIREMENTS.md § 9:

```
find scripts src/lib src/data src/scripts src/components public -type f \( -name '*.mjs' -o -name '*.js' -o -name '*.ts' -o -name '*.astro' -o -name '*.css' -o -name '*.json' \) -not -name 'package*.json' | xargs wc -l
```

The same command with `tests` added, because the new tests live in `site/tests/` (Feature 005). After the cut,
`find` prints "No such file or directory" for folders that no longer exist; read the `total` line.

```
find scripts src/lib src/data src/scripts src/components public tests -type f \( -name '*.mjs' -o -name '*.js' -o -name '*.ts' -o -name '*.astro' -o -name '*.css' -o -name '*.json' \) -not -name 'package*.json' | xargs wc -l
```

## Sources of truth

Each page row names the sources it is checked against, by these codes.

| Code | Source in the repository |
|---|---|
| SK | `canonical/skills/<name>/SKILL.md` and its `references/` |
| AG | `canonical/agents/*/AGENT.md` |
| SC | `canonical/aid/templates/shortcut-catalog.yml` and `canonical/aid/templates/shortcut-engine.md` |
| ST | `canonical/aid/templates/settings.yml` |
| TPL | `canonical/aid/templates/` (work-state, task-state, delivery-state, requirements, task-detail and `knowledge-base/` templates) |
| RULES | `canonical/aid/rules.md` |
| CLI | output of `bash bin/aid -h` and `bash bin/aid <command> -h`, run from the repo root |
| INS | `install.sh`, `install.ps1`, `docs/install.md`, `packages/npm/package.json`, `packages/pypi/pyproject.toml` |
| REL | `docs/release.md`, `release.sh`, `.claude/skills/release-aid/SKILL.md` |
| GEN | `.claude/skills/generate-profile/SKILL.md` |
| DASH | `dashboard/README.md` and `bash bin/aid dashboard -h` |
| DOC | the `docs/<file>.md` the page was copied from (a starting text, not the truth) |
| REPO | the repo-root layout (`git ls-files`) and `.aid/knowledge/project-structure.md` |
| VER | the repo-root `VERSION` file |
| FACTS | a page written by `scripts/gen-facts.mjs`; verified by `node scripts/gen-facts.mjs --check` |

## Pages

Verdict is `ok` (no change needed), `corrected` (the Correction cell says what changed), `removed`
(the Correction cell names the redirect target) or `new` (created by this work). `pending` means not yet audited.

| Page | Source of truth | Verdict | Correction |
|---|---|---|---|
| `src/content/docs/index.mdx` (/) | SK, SC, RULES, CLI, INS, VER | corrected | Removed the hand-written skill, shortcut-catalog and family counts (rule P4; SK, SC: `canonical/skills/`, `shortcut-catalog.yml`). Replaced the claim that `/aid-config` scaffolds the Knowledge Base: SK `aid-config` only views or changes settings, and `/aid-discover` builds the Knowledge Base (SK `aid-discover`). Replaced the claim that `aid add` drops in a Knowledge Base scaffold: INS lists the skills, agents, runtime and root regions only, and says the CLI never writes the Knowledge Base. Rewrote the phase list from the SK descriptions and RULES § Workflow, and dropped "six core phases" because RULES names seven phases. Fixed the card texts: the Reference card no longer lists skills (they have their own pages), and the Guides and Concepts cards match the sidebar. Install tabs, version badge and D1 diagram untouched. |
| `src/content/docs/get-started/index.md` (/get-started/) | none (redirect stub) | removed | redirects to /get-started/overview/ |
| `src/content/docs/get-started/overview.md` (/get-started/overview/) | SK, RULES, INS | corrected | Removed "TRIAGE routes the work": SK `aid-triage` only suggests and writes nothing. Removed "four groups and six numbered phases": RULES § Workflow names seven phases and no groups. Replaced "drops in the right profile": INS shows `aid add <tool>` adds the shared skills and runtime plus that tool's agents, and the five tool names match INS. Removed the hand-written counts (P4). Frontmatter: label "What is AID?", order 1, description is the P1 sentence. |
| `src/content/docs/get-started/install.md` (/get-started/install/) | INS, CLI | corrected | Install commands, channel names and requirements (Node 22 or later, Python 3.8 or later, PowerShell 5.1 or later) re-checked against `docs/install.md`, `install.sh`, `install.ps1`, `packages/npm/package.json` and `packages/pypi/pyproject.toml`: unchanged. Added the `aid add claude-code` step (CLI `aid -h`, INS). The page now states the install facts once and links to the Installation guide for the full steps (P9). Frontmatter: label "Install", order 2, description is the P1 sentence. |
| `src/content/docs/get-started/first-work.mdx` (/get-started/first-work/) | SK (aid-config to aid-execute), TPL, RULES; DOC `docs/aid-methodology.md` § 10 | corrected | Replaced "`/aid-config` scaffolds the `.aid/` Knowledge Base root" with what it does: it shows settings and copies the template to `.aid/settings.yml` on first run (SK `aid-config`). Replaced "six-phase pipeline" and the missing Define step with the seven phases in order (RULES § Workflow, SK `aid-define`). Moved `REQUIREMENTS.md` and `PLAN.md` from `.aid/` to `.aid/works/work-NNN-name/` (SK `aid-describe`, `aid-plan`). Removed "Discover is mandatory for existing codebases" and the Discover approval-summary detail: SK `aid-discover` says only to use it when code has no Knowledge Base yet and that it asks for approval. Replaced "grades its own output" with review until the minimum grade, one task per run (SK `aid-execute`). Dropped the Adopting Incrementally table, whose phase-skipping claims no SK states; replaced by a short list of steps each SK supports. Kept the brownfield and greenfield starts (SK `aid-describe` DESCRIBE-SEED, `aid-housekeep` conformance lane) and removed the repeated shortcut text in favour of a link to the shortcuts page (P9). Frontmatter: label "Your first work", order 3, description is the P1 sentence. |
| `src/content/docs/get-started/lite-path.mdx` (/get-started/lite-path/) | SC, SK (aid-triage and the shortcut doorways) | corrected | Removed the hand-written counts (34 shortcuts, 8 doorways, 94 rows, 19 family rows; P4). Removed "each shortcut invocation allocates a brand-new work": the engine first asks new or continuation when works exist (`shortcut-engine.md` § Design Notes). Moved the work folder from `.aid/work-NNN-name/` to `.aid/works/work-NNN-name/` (`shortcut-engine.md` INTAKE Step 4). Added the shortcut default minimum grade A+ (`shortcut-engine.md` § GATE Step 1). Removed the "no longer triages" sentence about `/aid-describe` (P5). Kept the eight doorway names (SC: the non-repurpose family rows). The engine text of the removed `reference/skills.md` duplicated this page and now appears once. Lead settled: no change-history wording or internal ids remain outside code. Frontmatter: label "Small changes with shortcuts", order 4, description is the P1 sentence. |
| `src/content/docs/guides/installation.mdx` (/guides/installation/) | INS, CLI, VER | pending | |
| `src/content/docs/guides/pipeline.mdx` (/guides/pipeline/) | SK (phase skills), TPL, RULES | pending | |
| `src/content/docs/guides/dashboard.mdx` (/guides/dashboard/) | DASH, CLI | pending | |
| `src/content/docs/guides/maintainer.mdx` (/guides/maintainer/) | REL, GEN | pending | |
| `src/content/docs/concepts/index.md` (/concepts/) | none (redirect stub) | removed | redirects to /concepts/methodology/ |
| `src/content/docs/concepts/overview.md` (/concepts/overview/) | none (section index) | removed | redirects to /concepts/methodology/ |
| `src/content/docs/concepts/methodology.mdx` (/concepts/methodology/) | DOC `docs/aid-methodology.md`; SK, AG, SC, TPL, RULES | pending | planned: renamed from `concepts/methodology.md` (it hosts a diagram); becomes the Concepts landing page plus philosophy; other sections move to the new pages below |
| `src/content/docs/concepts/pipeline.mdx` (/concepts/pipeline/) | SK, SC, RULES | new (planned) | split from methodology §§ 1 and 4 |
| `src/content/docs/concepts/knowledge-base.mdx` (/concepts/knowledge-base/) | SK (aid-discover, aid-housekeep, aid-update-kb), TPL `knowledge-base/`, ST | new (planned) | split from methodology § 3 |
| `src/content/docs/concepts/agents.mdx` (/concepts/agents/) | AG, SK (Dispatch tables), `canonical/aid/templates/agent-dispatch-tiering.md` | new (planned) | split from methodology § 5 |
| `src/content/docs/concepts/feedback-loops.mdx` (/concepts/feedback-loops/) | SK, `canonical/aid/templates/feedback-artifacts/` | new (planned) | split from methodology § 6 |
| `src/content/docs/concepts/case-studies.md` (/concepts/case-studies/) | DOC `docs/aid-methodology.md` § 8 | new (planned) | split from methodology § 8 |
| `src/content/docs/concepts/aid-and-sdd.mdx` (/concepts/aid-and-sdd/) | DOC `docs/aid-methodology.md` § 9 | new (planned) | split from methodology § 9 |
| `src/content/docs/concepts/faq.md` (/concepts/faq/) | DOC `docs/faq.md`; SK, CLI, INS | pending | |
| `src/content/docs/reference/index.md` (/reference/) | none (redirect stub) | removed | redirects to /reference/overview/ |
| `src/content/docs/reference/overview.md` (/reference/overview/) | the Reference pages themselves | pending | |
| `src/content/docs/reference/cli.mdx` (/reference/cli/) | CLI, INS | pending | |
| `src/content/docs/reference/skills.md` (/reference/skills/) | SC | removed | redirects to /skills/; text merged into /get-started/lite-path/ |
| `src/content/docs/reference/agents.md` (/reference/agents/) | FACTS; AG | pending | |
| `src/content/docs/reference/kb.md` (/reference/kb/) | TPL `knowledge-base/`, ST | pending | planned: hand-written |
| `src/content/docs/reference/settings.md` (/reference/settings/) | FACTS; ST | pending | |
| `src/content/docs/reference/artifacts.md` (/reference/artifacts/) | TPL, SK (aid-define, aid-plan, aid-detail, aid-execute) | pending | planned: absorbs methodology § 7 |
| `src/content/docs/reference/repository-structure.md` (/reference/repository-structure/) | DOC `docs/repository-structure.md`; REPO | pending | |
| `src/content/docs/reference/glossary.md` (/reference/glossary/) | DOC `docs/glossary.md`; SK, SC, TPL | corrected | Terms are now `###` headings with anchors and the page lists groups only in its table of contents. P4: the hand-written skill, shortcut, catalog-row, doorway, document and task-type counts are gone (`canonical/skills/`, `shortcut-catalog.yml`). P5: change-history wording is gone ("Formerly", "retired", "replaced", "no longer", "Post-FR2"). Deleted term "Determinism Test": no skill, template or process doc defines it. Deleted term "TRIAGE": only history of a state that moved to `/aid-triage`; the `/aid-triage` term keeps the current behaviour (`aid-triage/SKILL.md`). "aid-config" no longer claims to ask greenfield or brownfield or to scaffold `.aid/knowledge/`; the skill only shows or changes `.aid/settings.yml` (`aid-config/SKILL.md`). "aid-summarize" builds `kb.html`, not `knowledge-summary.html` (`aid-summarize/SKILL.md`). "STATE.md" is now "STATE file": work, delivery and task state are `STATE.yml`, only the KB keeps `STATE.md` (`work-state-template.yml`, `aid-plan/SKILL.md`); the feature-level `STATE.md` claim is removed because no source shows it. "DETAIL.md" no longer says the per-task `STATE.md` or the old flat `tasks/task-NNN.md` form. "Install channel" listed three channels as four: now curl, irm, npm and PyPI, plus the offline bundle (`docs/install.md`). "Greenfield" no longer says "Init first" or "Phase 2a" (`aid-describe/SKILL.md` DESCRIBE-SEED). "Design seed" says only the realizing `create` deletes the seed (`design-lifecycle.md`). The "Phase Gate" quote "OK?" and the "Grading" line on domain-specific checks in REQUIREMENTS.md § 9 are removed: no source states them. "Knowledge Base" drops the meta-document role and concern-axis paragraph. |
| `src/content/docs/contact/site-issue.mdx` (/contact/site-issue/) | the form's GitHub link | pending | |
| `src/content/docs/contact/methodology-bug.mdx` (/contact/methodology-bug/) | the form's GitHub link | pending | |
| `src/content/docs/contact/feedback.mdx` (/contact/feedback/) | the form's GitHub link | pending | |
| `src/content/docs/contact/contact-request.mdx` (/contact/contact-request/) | the form's mailto link | pending | |
| `src/pages/releases/changelog.astro` (/releases/changelog/) | VER | pending | planned: replaced by `src/content/docs/releases/changelog.mdx`, same URL |
| `src/content/docs/releases/changelog.mdx` (/releases/changelog/) | VER | new (planned) | |
| `src/content/docs/skills/index.md` (/skills/) | FACTS; SK, SC | pending | |
| `src/content/docs/skills/aid-ask.md` (/skills/aid-ask/) | FACTS; SK `aid-ask` | pending | |
| `src/content/docs/skills/aid-brainstorm.md` (/skills/aid-brainstorm/) | FACTS; SK `aid-brainstorm` | pending | |
| `src/content/docs/skills/aid-chat.md` (/skills/aid-chat/) | FACTS; SK `aid-chat` | pending | |
| `src/content/docs/skills/aid-config.md` (/skills/aid-config/) | FACTS; SK `aid-config` | pending | |
| `src/content/docs/skills/aid-create.md` (/skills/aid-create/) | FACTS; SK `aid-create` | pending | |
| `src/content/docs/skills/aid-create-ticket.md` (/skills/aid-create-ticket/) | FACTS; SK `aid-create-ticket` | pending | |
| `src/content/docs/skills/aid-define.md` (/skills/aid-define/) | FACTS; SK `aid-define` | pending | |
| `src/content/docs/skills/aid-deploy.md` (/skills/aid-deploy/) | FACTS; SK `aid-deploy` | pending | |
| `src/content/docs/skills/aid-deprecate.md` (/skills/aid-deprecate/) | FACTS; SK `aid-deprecate` | pending | |
| `src/content/docs/skills/aid-describe.md` (/skills/aid-describe/) | FACTS; SK `aid-describe` | pending | |
| `src/content/docs/skills/aid-design.md` (/skills/aid-design/) | FACTS; SK `aid-design` | pending | |
| `src/content/docs/skills/aid-detail.md` (/skills/aid-detail/) | FACTS; SK `aid-detail` | pending | |
| `src/content/docs/skills/aid-discover.md` (/skills/aid-discover/) | FACTS; SK `aid-discover` | pending | |
| `src/content/docs/skills/aid-document.md` (/skills/aid-document/) | FACTS; SK `aid-document` | pending | |
| `src/content/docs/skills/aid-execute.md` (/skills/aid-execute/) | FACTS; SK `aid-execute` | pending | |
| `src/content/docs/skills/aid-experiment.md` (/skills/aid-experiment/) | FACTS; SK `aid-experiment` | pending | |
| `src/content/docs/skills/aid-fix.md` (/skills/aid-fix/) | FACTS; SK `aid-fix` | pending | |
| `src/content/docs/skills/aid-housekeep.md` (/skills/aid-housekeep/) | FACTS; SK `aid-housekeep` | pending | |
| `src/content/docs/skills/aid-migrate.md` (/skills/aid-migrate/) | FACTS; SK `aid-migrate` | pending | |
| `src/content/docs/skills/aid-monitor.md` (/skills/aid-monitor/) | FACTS; SK `aid-monitor` | pending | |
| `src/content/docs/skills/aid-plan.md` (/skills/aid-plan/) | FACTS; SK `aid-plan` | pending | |
| `src/content/docs/skills/aid-prototype.md` (/skills/aid-prototype/) | FACTS; SK `aid-prototype` | pending | |
| `src/content/docs/skills/aid-read-ticket.md` (/skills/aid-read-ticket/) | FACTS; SK `aid-read-ticket` | pending | |
| `src/content/docs/skills/aid-refactor.md` (/skills/aid-refactor/) | FACTS; SK `aid-refactor` | pending | |
| `src/content/docs/skills/aid-remove.md` (/skills/aid-remove/) | FACTS; SK `aid-remove` | pending | |
| `src/content/docs/skills/aid-report.md` (/skills/aid-report/) | FACTS; SK `aid-report` | pending | |
| `src/content/docs/skills/aid-research.md` (/skills/aid-research/) | FACTS; SK `aid-research` | pending | |
| `src/content/docs/skills/aid-review.md` (/skills/aid-review/) | FACTS; SK `aid-review` | pending | |
| `src/content/docs/skills/aid-set-connector.md` (/skills/aid-set-connector/) | FACTS; SK `aid-set-connector` | pending | |
| `src/content/docs/skills/aid-specify.md` (/skills/aid-specify/) | FACTS; SK `aid-specify` | pending | |
| `src/content/docs/skills/aid-summarize.md` (/skills/aid-summarize/) | FACTS; SK `aid-summarize` | pending | |
| `src/content/docs/skills/aid-test.md` (/skills/aid-test/) | FACTS; SK `aid-test` | pending | |
| `src/content/docs/skills/aid-triage.md` (/skills/aid-triage/) | FACTS; SK `aid-triage` | pending | |
| `src/content/docs/skills/aid-unset-connector.md` (/skills/aid-unset-connector/) | FACTS; SK `aid-unset-connector` | pending | |
| `src/content/docs/skills/aid-update.md` (/skills/aid-update/) | FACTS; SK `aid-update` | pending | |
| `src/content/docs/skills/aid-update-kb.md` (/skills/aid-update-kb/) | FACTS; SK `aid-update-kb` | pending | |
| `src/content/docs/skills/aid-update-ticket.md` (/skills/aid-update-ticket/) | FACTS; SK `aid-update-ticket` | pending | |

## Redirects

Every removed or renamed URL, as configured in `astro.config.mjs` `redirects`.

| Old URL | New URL | Status |
|---|---|---|
| /get-started/ | /get-started/overview/ | done |
| /concepts/ | /concepts/methodology/ | done |
| /concepts/overview/ | /concepts/methodology/ | done |
| /reference/ | /reference/overview/ | done |
| /reference/skills/ | /skills/ | done |

## Kept site functions (FR-9)

| Function | How it is checked | Status |
|---|---|---|
| Search (Pagefind) | `dist/pagefind/pagefind.js` exists (build test) | pending |
| Sitemap | `dist/sitemap-index.xml` exists (build test) | pending |
| Favicon | `dist/favicon.svg` exists (build test) | pending |
| `CNAME` | `dist/CNAME` reads `aid.casuloailabs.com` (build test) | pending |
| `robots.txt` | `dist/robots.txt` exists (build test) | pending |
| Version display | `dist/releases/changelog/index.html` shows `v` plus the `VERSION` value (build test) | pending |
| Contact pages | the four `dist/contact/*/index.html` exist and each holds a `<form>` (build test) | pending |
| Release banner | not in FR-9; removed with the release-data fetch | pending |

## Scripts on built pages (AC-15)

Output of `grep -rho '<script[^>]*src="[^"]*"' dist --include='*.html' | sort -u`, one row per script.

| Script | Purpose |
|---|---|
| pending | |

## Keyboard check (AC-9)

| Page | Tab order observed | Focus ring visible each step | Result |
|---|---|---|---|
| / | pending | pending | pending |
| /skills/aid-define/ | pending | pending | pending |

## Screenshots (AC-11)

| Page | 320 px light | 320 px dark | 1280 px light | 1280 px dark |
|---|---|---|---|---|
| / | pending | pending | pending | pending |
| /skills/aid-define/ | pending | pending | pending | pending |

## Knowledge Base documents edited (FR-10)

| Document | Statement made true | Status |
|---|---|---|
| pending | | |

## Leads found at Specify

Checked against the repository on 2026-10-26; each is confirmed or dismissed during the audit and then
recorded in its page row above.

| Page | Lead |
|---|---|
| /reference/settings/ | Built from the dogfood `.aid/settings.yml`, not from ST; every Description cell is empty or reads "Installed AI host tools". |
| /reference/overview/ | Hand-written skill and catalog counts (rule P4 bans them). |
| /concepts/methodology/ | Says a task's review history lives in its own `STATE.md`; the Execute skill files name `STATE.yml` for the task state. Confirm against SK `aid-execute` and TPL `task-state-template.yml`. |
| /guides/pipeline/, /guides/maintainer/, /reference/artifacts/, /concepts/methodology/ | Matches for change-history wording or internal ids ("no longer", "formerly", `feature-NNN`, `task-NNN`, `delivery-NNN`, `FR-N`, `KI-NNN`). Rule P5 bans them, but an example argument in a command (`/aid-execute work-001 task-001`) is allowed. |
| /skills/aid-experiment/ | The `description` in `canonical/skills/aid-experiment/SKILL.md` is a folded block that breaks `/aid-` and `execute` across two lines, so the page reads "/aid- execute". A source defect in `canonical/` (out of scope, §4): record it in the page row as a finding for the owner. |
| /contact/* | The form works only with JavaScript (its button is `type="button"`); see Feature 005 for the no-script form. |
