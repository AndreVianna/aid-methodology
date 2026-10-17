# Delivery-001 site search and reconciled edit list

This file is the output of task-001 (RESEARCH) of delivery-001. It re-runs the searches that
REQUIREMENTS.md § 11 Feature 001 `##### 5. Migration` states, gives every hit exactly one owner, and
reconciles the result with the task files of delivery-001 (task-002 to task-019). Each later task of
delivery-001 reads the rows this file assigns to it ("Findings" bullet of its task file).

## Contents

- [Base commit and conventions](#base-commit-and-conventions)
- [S0 Installed copies (supplement)](#s0-installed-copies-supplement)
- [S1 Triage sites](#s1-triage-sites)
- [S2 Orchestrator sites](#s2-orchestrator-sites)
- [S3 ticket_ref sites](#s3-ticket_ref-sites)
- [S4 skill-routing.md](#s4-skill-routingmd)
- [S5 Suites that assert the rules text](#s5-suites-that-assert-the-rules-text)
- [S6 The Q106 map](#s6-the-q106-map)
- [S7 Count checks](#s7-count-checks)
- [S8 Description checks](#s8-description-checks)
- [S9 The SG-04 exempt list](#s9-the-sg-04-exempt-list)
- [S10 Site page classes](#s10-site-page-classes)
- [Site fixtures (G11)](#site-fixtures-g11)
- [KB sources (G17)](#kb-sources-g17)
- [Site generator sources (G19)](#site-generator-sources-g19)
- [Suites that read deleted paths (G6 pre-run)](#suites-that-read-deleted-paths-g6-pre-run)
- [Skill owner table (G2)](#skill-owner-table-g2)
- [Delta](#delta)
- [Test step](#test-step)

## Base commit and conventions

- **Base commit:** `581a43353a3e0a621ef5cb0be92c5d7d98cee1e2` (`581a4335`, the `task-001: In Progress` commit on branch
  `work-003`). The working tree was clean at the base. Every command below names the base commit
  explicitly (`git grep ... 581a4335 -- ...`), so it reproduces the same hit list, line for line, from
  any later commit, run from the repository root.
- **Path set** (task-001 Scope), used by S1 to S4: `canonical/ site/ docs/ examples/ README.md .aid/knowledge/ .aid/design/ tests/ dashboard/ bin/ lib/ .claude/skills/generate-profile/`.
  The work folder `.aid/works/` is outside the set, so this file and the spec never count as hits.
- **Suite set** used by S5: `tests/ site/scripts/__tests__/ site/src/lib/__tests__/ site/src/data/__tests__/ dashboard/reader/tests/ dashboard/server/tests/`, minus every `fixtures/` folder (a fixture is input data,
  not a suite). S6 and S8 use the narrower runnable-suite set written in their commands.
- **Hit list** = the exact output of a command. Most commands use `git grep -n -o`, which prints one line
  per match, `581a4335:<path>:<line>:<match>`; that keeps the lists short and exact.
- **Hit row** = one row of an owner table: one file, or one set of lines of a file when its lines go to
  different owners. Every hit-list line falls in exactly one hit row, and the `Hits` column counts them.
- **Owner classes** (task-001 Scope): a task of delivery-001 (`task-002` to `task-019`);
  `installed copy (resync)` (`.claude/skills/aid-*`, `.agents/`, `.aid/runtime/`, `profiles/`, `.claude/agents/`,
  `.cursor/agents/`, `.aid/.aid-manifest.json`); `history, left as is` (`.aid/knowledge/release-tracking.md`,
  `tests/coverage-accepted-removals.tsv`, `.aid/knowledge/kb.html`); `baseline, re-recorded at the gate`
  (`tests/cost-baseline.tsv`, `tests/coverage-baseline.tsv`; no task edits a baseline, Q134 D11).
- **The owner of a hit** is the task whose scope changes the text the hit stands in. It makes the edit
  (or the regeneration) and runs the suites that assert it (Q106). "No edit expected" in a note means the
  owner only re-runs the suite.
- **Confidence.** Hit lists are CONFIRMED (command output). Owner assignments follow the task files and
  are CONFIRMED where a task file names the path; the rest are LIKELY and say why in the note. Judgement
  calls are listed in [Delta](#delta).

## S0 Installed copies (supplement)

Not one of S1 to S10: the path set excludes the installed trees. This supplement lists, for
completeness, the installed files that carry any of the S1 to S4 terms. Every row is owned by
`installed copy (resync)`: the delivery's resync rewrites them, and no task edits them.

```bash
git grep -l -e 'aid-triage' -e 'triage router' -e 'aid-orchestrator' -e 'ticket_ref' -e 'skill-routing' 581a4335 -- \
  .claude/skills/ .agents/ .aid/runtime/ profiles/ .claude/agents/ .cursor/agents/ .aid/.aid-manifest.json \
  ':!.claude/skills/generate-profile/'
```
```text
581a4335:.agents/skills/aid-describe/SKILL.md
581a4335:.agents/skills/aid-describe/references/elicitation-engine.md
581a4335:.agents/skills/aid-describe/references/state-first-run.md
581a4335:.agents/skills/aid-monitor/SKILL.md
581a4335:.agents/skills/aid-monitor/references/state-route.md
581a4335:.agents/skills/aid-plan/references/first-run-loop.md
581a4335:.agents/skills/aid-specify/references/state-initialize.md
581a4335:.agents/skills/aid-triage/SKILL.md
581a4335:.aid/.aid-manifest.json
581a4335:.aid/runtime/templates/agent-dispatch-tiering.md
581a4335:.aid/runtime/templates/connectors/consumption-protocol.md
581a4335:.aid/runtime/templates/delivery-state-template.yml
581a4335:.aid/runtime/templates/requirements/requirements-template.md
581a4335:.aid/runtime/templates/self-review-protocol.md
581a4335:.aid/runtime/templates/shortcut-catalog.yml
581a4335:.aid/runtime/templates/shortcut-engine.md
581a4335:.aid/runtime/templates/task-state-template.yml
581a4335:.aid/runtime/templates/work-state-template.yml
581a4335:.claude/agents/aid-orchestrator.md
581a4335:.claude/skills/aid-describe/SKILL.md
581a4335:.claude/skills/aid-describe/references/elicitation-engine.md
581a4335:.claude/skills/aid-describe/references/state-first-run.md
581a4335:.claude/skills/aid-monitor/SKILL.md
581a4335:.claude/skills/aid-monitor/references/state-route.md
581a4335:.claude/skills/aid-plan/references/first-run-loop.md
581a4335:.claude/skills/aid-specify/references/state-initialize.md
581a4335:.claude/skills/aid-triage/SKILL.md
581a4335:.cursor/agents/aid-orchestrator.md
581a4335:profiles/antigravity/.agent/agents/aid-orchestrator.md
581a4335:profiles/claude-code/.claude/agents/aid-orchestrator.md
581a4335:profiles/codex/.codex/agents/aid-orchestrator.toml
581a4335:profiles/copilot-cli/.github/agents/aid-orchestrator.md
581a4335:profiles/cursor/.cursor/agents/aid-orchestrator.md
```
Owner of all 33 files above: installed copy (resync). The installed `aid-triage` folders (`.claude/skills/aid-triage/`, `.agents/skills/aid-triage/`, three files each) and the seven `aid-orchestrator` agent files (`.claude/agents/`, `.cursor/agents/` and the five `profiles/<tool>/` renders) go at the resync: `run_generator.py` wipes and re-renders each `profiles/<tool>/` (CONFIRMED: its `clean profile wipe` step), then its dogfood sync refreshes the installed set (LIKELY removing the retired files through the install manifest); no task deletes them by hand.

## S1 Triage sites

Anchor: REQUIREMENTS.md § 11 Feature 001 `##### 5. Migration`, "Triage sites", and its final search for
`aid-triage`, `/aid-triage` and "triage router". `/aid-triage` is a substring of `aid-triage`, so the
first pattern finds both.

```bash
git grep -n -o -e 'aid-triage' -e 'triage router' 581a4335 -- \
  canonical/ site/ docs/ examples/ README.md .aid/knowledge/ .aid/design/ tests/ dashboard/ bin/ lib/ .claude/skills/generate-profile/
```
Hit list: 355 lines.

```text
581a4335:.aid/knowledge/architecture.md:190:aid-triage
581a4335:.aid/knowledge/architecture.md:208:aid-triage
581a4335:.aid/knowledge/architecture.md:209:aid-triage
581a4335:.aid/knowledge/architecture.md:209:aid-triage
581a4335:.aid/knowledge/architecture.md:241:aid-triage
581a4335:.aid/knowledge/architecture.md:244:aid-triage
581a4335:.aid/knowledge/architecture.md:250:aid-triage
581a4335:.aid/knowledge/architecture.md:262:aid-triage
581a4335:.aid/knowledge/architecture.md:420:aid-triage
581a4335:.aid/knowledge/architecture.md:423:aid-triage
581a4335:.aid/knowledge/capability-inventory.md:26:aid-triage
581a4335:.aid/knowledge/capability-inventory.md:57:aid-triage
581a4335:.aid/knowledge/capability-inventory.md:63:aid-triage
581a4335:.aid/knowledge/capability-inventory.md:70:aid-triage
581a4335:.aid/knowledge/capability-inventory.md:75:aid-triage
581a4335:.aid/knowledge/capability-inventory.md:125:aid-triage
581a4335:.aid/knowledge/capability-inventory.md:209:aid-triage
581a4335:.aid/knowledge/capability-inventory.md:211:aid-triage
581a4335:.aid/knowledge/capability-inventory.md:211:aid-triage
581a4335:.aid/knowledge/capability-inventory.md:295:aid-triage
581a4335:.aid/knowledge/capability-inventory.md:310:aid-triage
581a4335:.aid/knowledge/decisions.md:60:aid-triage
581a4335:.aid/knowledge/decisions.md:60:aid-triage
581a4335:.aid/knowledge/decisions.md:97:aid-triage
581a4335:.aid/knowledge/decisions.md:97:aid-triage
581a4335:.aid/knowledge/decisions.md:101:aid-triage
581a4335:.aid/knowledge/decisions.md:313:aid-triage
581a4335:.aid/knowledge/decisions.md:434:aid-triage
581a4335:.aid/knowledge/decisions.md:437:aid-triage
581a4335:.aid/knowledge/decisions.md:450:aid-triage
581a4335:.aid/knowledge/decisions.md:502:aid-triage
581a4335:.aid/knowledge/decisions.md:507:aid-triage
581a4335:.aid/knowledge/decisions.md:516:aid-triage
581a4335:.aid/knowledge/decisions.md:519:aid-triage
581a4335:.aid/knowledge/decisions.md:524:aid-triage
581a4335:.aid/knowledge/domain-glossary.md:13:aid-triage
581a4335:.aid/knowledge/domain-glossary.md:379:aid-triage
581a4335:.aid/knowledge/domain-glossary.md:389:aid-triage
581a4335:.aid/knowledge/domain-glossary.md:408:aid-triage
581a4335:.aid/knowledge/domain-glossary.md:443:aid-triage
581a4335:.aid/knowledge/domain-glossary.md:445:aid-triage
581a4335:.aid/knowledge/domain-glossary.md:446:aid-triage
581a4335:.aid/knowledge/domain-glossary.md:462:aid-triage
581a4335:.aid/knowledge/domain-glossary.md:463:aid-triage
581a4335:.aid/knowledge/domain-glossary.md:464:aid-triage
581a4335:.aid/knowledge/domain-glossary.md:502:aid-triage
581a4335:.aid/knowledge/kb.html:1357:aid-triage
581a4335:.aid/knowledge/kb.html:1415:aid-triage
581a4335:.aid/knowledge/kb.html:1496:aid-triage
581a4335:.aid/knowledge/kb.html:1922:aid-triage
581a4335:.aid/knowledge/kb.html:2094:aid-triage
581a4335:.aid/knowledge/kb.html:2139:aid-triage
581a4335:.aid/knowledge/kb.html:2202:aid-triage
581a4335:.aid/knowledge/kb.html:3126:aid-triage
581a4335:.aid/knowledge/kb.html:3178:aid-triage
581a4335:.aid/knowledge/module-map.md:251:aid-triage
581a4335:.aid/knowledge/pipeline-contracts.md:76:aid-triage
581a4335:.aid/knowledge/pipeline-contracts.md:80:aid-triage
581a4335:.aid/knowledge/pipeline-contracts.md:90:aid-triage
581a4335:.aid/knowledge/pipeline-contracts.md:220:aid-triage
581a4335:.aid/knowledge/pipeline-contracts.md:251:aid-triage
581a4335:.aid/knowledge/pipeline-contracts.md:259:aid-triage
581a4335:.aid/knowledge/pipeline-contracts.md:265:aid-triage
581a4335:.aid/knowledge/pipeline-contracts.md:334:aid-triage
581a4335:.aid/knowledge/pipeline-contracts.md:340:aid-triage
581a4335:.aid/knowledge/project-structure.md:195:aid-triage
581a4335:.aid/knowledge/release-tracking.md:163:aid-triage
581a4335:.aid/knowledge/tech-debt.md:92:aid-triage
581a4335:.aid/knowledge/test-landscape.md:183:aid-triage
581a4335:.aid/knowledge/test-landscape.md:326:aid-triage
581a4335:.claude/skills/generate-profile/SKILL.md:96:aid-triage
581a4335:.claude/skills/generate-profile/SKILL.md:107:aid-triage
581a4335:README.md:23:aid-triage
581a4335:README.md:35:aid-triage
581a4335:README.md:83:aid-triage
581a4335:README.md:191:aid-triage
581a4335:README.md:201:aid-triage
581a4335:README.md:209:aid-triage
581a4335:README.md:254:aid-triage
581a4335:README.md:254:aid-triage
581a4335:canonical/aid/templates/shortcut-catalog.yml:22:aid-triage
581a4335:canonical/aid/templates/shortcut-catalog.yml:903:aid-triage
581a4335:canonical/skills/aid-describe/SKILL.md:57:aid-triage
581a4335:canonical/skills/aid-describe/references/elicitation-engine.md:7:aid-triage
581a4335:canonical/skills/aid-describe/references/elicitation-engine.md:317:aid-triage
581a4335:canonical/skills/aid-describe/references/elicitation-engine.md:322:aid-triage
581a4335:canonical/skills/aid-describe/references/state-first-run.md:83:aid-triage
581a4335:canonical/skills/aid-monitor/SKILL.md:7:aid-triage
581a4335:canonical/skills/aid-monitor/SKILL.md:24:aid-triage
581a4335:canonical/skills/aid-monitor/references/state-route.md:20:aid-triage
581a4335:canonical/skills/aid-monitor/references/state-route.md:38:aid-triage
581a4335:canonical/skills/aid-monitor/references/state-route.md:40:aid-triage
581a4335:canonical/skills/aid-triage/SKILL.md:2:aid-triage
581a4335:canonical/skills/aid-triage/SKILL.md:30:aid-triage
581a4335:canonical/skills/aid-triage/SKILL.md:46:aid-triage
581a4335:canonical/skills/aid-triage/SKILL.md:59:aid-triage
581a4335:canonical/skills/aid-triage/SKILL.md:67:aid-triage
581a4335:canonical/skills/aid-triage/SKILL.md:111:aid-triage
581a4335:docs/aid-methodology.md:40:aid-triage
581a4335:docs/aid-methodology.md:78:aid-triage
581a4335:docs/aid-methodology.md:91:aid-triage
581a4335:docs/aid-methodology.md:122:aid-triage
581a4335:docs/aid-methodology.md:124:aid-triage
581a4335:docs/aid-methodology.md:126:aid-triage
581a4335:docs/aid-methodology.md:231:aid-triage
581a4335:docs/aid-methodology.md:403:aid-triage
581a4335:docs/aid-methodology.md:405:aid-triage
581a4335:docs/aid-methodology.md:410:aid-triage
581a4335:docs/aid-methodology.md:499:aid-triage
581a4335:docs/aid-methodology.md:551:aid-triage
581a4335:docs/aid-methodology.md:559:aid-triage
581a4335:docs/aid-methodology.md:584:aid-triage
581a4335:docs/aid-methodology.md:584:aid-triage
581a4335:docs/aid-methodology.md:764:aid-triage
581a4335:docs/aid-methodology.md:936:aid-triage
581a4335:docs/aid-methodology.md:972:aid-triage
581a4335:docs/aid-methodology.md:999:aid-triage
581a4335:docs/aid-methodology.md:999:aid-triage
581a4335:docs/aid-methodology.md:1077:aid-triage
581a4335:docs/aid-methodology.md:1258:aid-triage
581a4335:docs/aid-methodology.md:1369:aid-triage
581a4335:docs/aid-methodology.md:1401:aid-triage
581a4335:docs/aid-methodology.md:1404:aid-triage
581a4335:docs/aid-methodology.md:1446:aid-triage
581a4335:docs/aid-methodology.md:1457:aid-triage
581a4335:docs/aid-methodology.md:1464:aid-triage
581a4335:docs/aid-methodology.md:1491:aid-triage
581a4335:docs/diagram-content-reference.md:25:aid-triage
581a4335:docs/diagram-content-reference.md:46:aid-triage
581a4335:docs/diagram-content-reference.md:47:aid-triage
581a4335:docs/diagram-content-reference.md:52:aid-triage
581a4335:docs/diagram-content-reference.md:53:aid-triage
581a4335:docs/diagram-content-reference.md:56:aid-triage
581a4335:docs/diagram-content-reference.md:77:aid-triage
581a4335:docs/diagram-content-reference.md:125:aid-triage
581a4335:docs/diagram-content-reference.md:131:aid-triage
581a4335:docs/diagram-content-reference.md:140:aid-triage
581a4335:docs/diagram-content-reference.md:143:aid-triage
581a4335:docs/diagram-content-reference.md:146:aid-triage
581a4335:docs/diagram-content-reference.md:157:aid-triage
581a4335:docs/diagram-content-reference.md:159:aid-triage
581a4335:docs/faq.md:17:aid-triage
581a4335:docs/faq.md:91:aid-triage
581a4335:docs/faq.md:118:aid-triage
581a4335:docs/glossary.md:9:aid-triage
581a4335:docs/glossary.md:46:aid-triage
581a4335:docs/glossary.md:46:aid-triage
581a4335:docs/glossary.md:48:aid-triage
581a4335:docs/glossary.md:66:aid-triage
581a4335:docs/glossary.md:72:aid-triage
581a4335:docs/repository-structure.md:77:aid-triage
581a4335:docs/repository-structure.md:79:aid-triage
581a4335:site/scripts/.skills-manifest.json:353:aid-triage
581a4335:site/scripts/.skills-manifest.json:354:aid-triage
581a4335:site/scripts/.skills-manifest.json:545:aid-triage
581a4335:site/scripts/.skills-manifest.json:918:aid-triage
581a4335:site/scripts/.skills-manifest.json:919:aid-triage
581a4335:site/scripts/__tests__/flow-classify.test.mjs:6:aid-triage
581a4335:site/scripts/__tests__/flow-classify.test.mjs:173:aid-triage
581a4335:site/scripts/__tests__/flow-classify.test.mjs:175:aid-triage
581a4335:site/scripts/__tests__/flow-classify.test.mjs:176:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:34:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:47:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:48:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:67:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:77:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:79:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:81:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:153:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:156:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:251:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:252:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:254:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:415:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:438:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:441:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:646:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:648:aid-triage
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs:649:aid-triage
581a4335:site/scripts/__tests__/flow-graph.test.mjs:1328:aid-triage
581a4335:site/scripts/__tests__/flow-graph.test.mjs:1331:aid-triage
581a4335:site/scripts/__tests__/gen-reference.test.mjs:146:aid-triage
581a4335:site/scripts/__tests__/gen-skills-index.test.mjs:180:aid-triage
581a4335:site/scripts/__tests__/gen-skills-index.test.mjs:199:aid-triage
581a4335:site/scripts/__tests__/gen-skills-index.test.mjs:200:aid-triage
581a4335:site/scripts/__tests__/gen-skills-index.test.mjs:201:aid-triage
581a4335:site/scripts/__tests__/skill-counts.test.mjs:63:aid-triage
581a4335:site/scripts/__tests__/skill-counts.test.mjs:391:aid-triage
581a4335:site/scripts/__tests__/skills-groups.test.mjs:7:aid-triage
581a4335:site/scripts/__tests__/skills-groups.test.mjs:97:aid-triage
581a4335:site/scripts/__tests__/skills-groups.test.mjs:159:aid-triage
581a4335:site/scripts/__tests__/skills-groups.test.mjs:161:aid-triage
581a4335:site/scripts/__tests__/skills-groups.test.mjs:162:aid-triage
581a4335:site/scripts/__tests__/skills-groups.test.mjs:166:aid-triage
581a4335:site/scripts/__tests__/skills-groups.test.mjs:169:aid-triage
581a4335:site/scripts/__tests__/skills-groups.test.mjs:172:aid-triage
581a4335:site/scripts/__tests__/skills-groups.test.mjs:175:aid-triage
581a4335:site/scripts/__tests__/skills-groups.test.mjs:184:aid-triage
581a4335:site/scripts/__tests__/skills-render-index.test.mjs:205:aid-triage
581a4335:site/scripts/__tests__/skills-render-index.test.mjs:669:aid-triage
581a4335:site/scripts/__tests__/skills-render-index.test.mjs:676:aid-triage
581a4335:site/scripts/__tests__/skills-render-index.test.mjs:684:aid-triage
581a4335:site/scripts/__tests__/skills-render-index.test.mjs:692:aid-triage
581a4335:site/scripts/gen-reference.mjs:141:aid-triage
581a4335:site/scripts/gen-reference.mjs:221:aid-triage
581a4335:site/scripts/gen-reference.mjs:232:aid-triage
581a4335:site/scripts/skills/curated-roster.mjs:56:aid-triage
581a4335:site/scripts/skills/groups.mjs:36:aid-triage
581a4335:site/scripts/skills/groups.mjs:68:aid-triage
581a4335:site/scripts/skills/render-index.mjs:173:aid-triage
581a4335:site/scripts/skills/skill-counts.mjs:26:aid-triage
581a4335:site/scripts/skills/skill-counts.mjs:30:aid-triage
581a4335:site/scripts/skills/skill-counts.mjs:37:aid-triage
581a4335:site/scripts/skills/skill-counts.mjs:43:aid-triage
581a4335:site/src/content/docs/concepts/faq.md:21:aid-triage
581a4335:site/src/content/docs/concepts/faq.md:95:aid-triage
581a4335:site/src/content/docs/concepts/faq.md:122:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:44:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:82:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:95:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:126:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:128:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:130:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:235:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:407:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:409:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:414:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:503:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:555:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:563:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:588:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:588:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:768:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:940:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:976:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:1003:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:1003:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:1081:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:1262:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:1373:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:1405:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:1408:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:1450:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:1461:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:1468:aid-triage
581a4335:site/src/content/docs/concepts/methodology.md:1495:aid-triage
581a4335:site/src/content/docs/get-started/first-work.mdx:80:aid-triage
581a4335:site/src/content/docs/get-started/lite-path.mdx:22:aid-triage
581a4335:site/src/content/docs/get-started/lite-path.mdx:23:aid-triage
581a4335:site/src/content/docs/get-started/lite-path.mdx:24:aid-triage
581a4335:site/src/content/docs/get-started/lite-path.mdx:53:aid-triage
581a4335:site/src/content/docs/get-started/lite-path.mdx:108:aid-triage
581a4335:site/src/content/docs/get-started/lite-path.mdx:114:aid-triage
581a4335:site/src/content/docs/guides/pipeline.mdx:28:aid-triage
581a4335:site/src/content/docs/guides/pipeline.mdx:47:aid-triage
581a4335:site/src/content/docs/guides/pipeline.mdx:50:aid-triage
581a4335:site/src/content/docs/guides/pipeline.mdx:57:aid-triage
581a4335:site/src/content/docs/guides/pipeline.mdx:110:aid-triage
581a4335:site/src/content/docs/guides/pipeline.mdx:219:aid-triage
581a4335:site/src/content/docs/guides/pipeline.mdx:232:aid-triage
581a4335:site/src/content/docs/index.mdx:38:aid-triage
581a4335:site/src/content/docs/index.mdx:77:aid-triage
581a4335:site/src/content/docs/index.mdx:80:aid-triage
581a4335:site/src/content/docs/index.mdx:94:aid-triage
581a4335:site/src/content/docs/reference/artifacts.md:17:aid-triage
581a4335:site/src/content/docs/reference/artifacts.md:36:aid-triage
581a4335:site/src/content/docs/reference/glossary.md:13:aid-triage
581a4335:site/src/content/docs/reference/glossary.md:50:aid-triage
581a4335:site/src/content/docs/reference/glossary.md:50:aid-triage
581a4335:site/src/content/docs/reference/glossary.md:52:aid-triage
581a4335:site/src/content/docs/reference/glossary.md:70:aid-triage
581a4335:site/src/content/docs/reference/glossary.md:76:aid-triage
581a4335:site/src/content/docs/reference/overview.md:16:aid-triage
581a4335:site/src/content/docs/reference/repository-structure.md:81:aid-triage
581a4335:site/src/content/docs/reference/repository-structure.md:83:aid-triage
581a4335:site/src/content/docs/reference/skills.md:23:aid-triage
581a4335:site/src/content/docs/skills/aid-monitor.md:12:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:2:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:4:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:7:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:11:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:16:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:16:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:50:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:54:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:54:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:54:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:54:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:58:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:62:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:62:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:62:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:62:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:66:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:70:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:70:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:70:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:70:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:74:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:78:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:78:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:78:aid-triage
581a4335:site/src/content/docs/skills/aid-triage.md:78:aid-triage
581a4335:site/src/content/docs/skills/index.md:13:aid-triage
581a4335:site/src/content/docs/skills/index.md:19:aid-triage
581a4335:site/src/content/docs/skills/index.md:19:aid-triage
581a4335:site/src/data/skill-flows/aid-describe.flow.json:27:aid-triage
581a4335:site/src/data/skill-flows/aid-monitor.flow.json:71:aid-triage
581a4335:site/src/data/skill-flows/aid-monitor.flow.json:71:aid-triage
581a4335:site/src/data/skill-flows/aid-monitor.flow.json:71:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:2:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:6:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:16:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:23:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:38:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:45:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:60:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:67:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:85:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:92:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:96:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:108:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:122:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:136:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:151:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:152:aid-triage
581a4335:site/src/data/skill-flows/aid-triage.flow.json:153:aid-triage
581a4335:tests/canonical/test-cutover-no-dangling.sh:88:aid-triage
581a4335:tests/canonical/test-deploy-monitor-repurpose.sh:13:aid-triage
581a4335:tests/canonical/test-deploy-monitor-repurpose.sh:77:aid-triage
581a4335:tests/canonical/test-deploy-monitor-repurpose.sh:82:aid-triage
581a4335:tests/canonical/test-deploy-monitor-repurpose.sh:83:aid-triage
581a4335:tests/canonical/test-deploy-monitor-repurpose.sh:88:aid-triage
581a4335:tests/canonical/test-deploy-monitor-repurpose.sh:89:aid-triage
581a4335:tests/canonical/test-deploy-monitor-repurpose.sh:95:aid-triage
581a4335:tests/canonical/test-deploy-monitor-repurpose.sh:95:aid-triage
581a4335:tests/canonical/test-deploy-monitor-repurpose.sh:118:aid-triage
581a4335:tests/canonical/test-deploy-monitor-repurpose.sh:118:aid-triage
581a4335:tests/canonical/test-deploy-monitor-repurpose.sh:354:aid-triage
581a4335:tests/canonical/test-triage-routing.sh:3:aid-triage
581a4335:tests/canonical/test-triage-routing.sh:5:aid-triage
581a4335:tests/canonical/test-triage-routing.sh:16:aid-triage
581a4335:tests/canonical/test-triage-routing.sh:36:aid-triage
581a4335:tests/canonical/test-triage-routing.sh:42:aid-triage
581a4335:tests/canonical/test-triage-routing.sh:44:aid-triage
581a4335:tests/canonical/test-triage-routing.sh:72:aid-triage
581a4335:tests/canonical/test-triage-routing.sh:76:aid-triage
581a4335:tests/canonical/test-triage-routing.sh:78:aid-triage
581a4335:tests/canonical/test-triage-routing.sh:294:aid-triage
581a4335:tests/cost-baseline.tsv:99:aid-triage
581a4335:tests/cost-baseline.tsv:210:aid-triage
581a4335:tests/cost-baseline.tsv:321:aid-triage
581a4335:tests/cost-baseline.tsv:432:aid-triage
581a4335:tests/cost-baseline.tsv:543:aid-triage
581a4335:tests/coverage-accepted-removals.tsv:24:aid-triage
```
Owners: 63 hit rows, 355 hit-list lines, 0 empty owner cells.

| # | File | Lines (hit-list entries) | Hits | Class (S10) | Owner | Note |
|---|---|---|---|---|---|---|
| 1 | `.aid/knowledge/architecture.md` | 190, 208, 209, 241, 244, 250, 262, 420, 423 | 10 | -- | task-013 |  |
| 2 | `.aid/knowledge/capability-inventory.md` | 26, 57, 63, 70, 75, 125, 209, 211, 295, 310 | 11 | -- | task-013 |  |
| 3 | `.aid/knowledge/decisions.md` | 60, 97, 101, 313, 434, 437, 450, 502, 507, 516, 519, 524 | 14 | -- | task-012 | D21 and D25 (Superseded), D14 pointer to D21 |
| 4 | `.aid/knowledge/domain-glossary.md` | 13, 379, 389, 408, 443, 445, 446, 462, 463, 464, 502 | 11 | -- | task-013 |  |
| 5 | `.aid/knowledge/kb.html` | 1357, 1415, 1496, 1922, 2094, 2139, 2202, 3126, 3178 | 9 | -- | history, left as is | Regenerated by the KB build or update, never hand-edited (F001 § 5, Left as they are) |
| 6 | `.aid/knowledge/module-map.md` | 251 | 1 | -- | task-013 |  |
| 7 | `.aid/knowledge/pipeline-contracts.md` | 76, 80, 90, 220, 251, 259, 265, 334, 340 | 9 | -- | task-013 |  |
| 8 | `.aid/knowledge/project-structure.md` | 195 | 1 | -- | task-013 |  |
| 9 | `.aid/knowledge/release-tracking.md` | 163 | 1 | -- | history, left as is | Shipped history (F001 § 5, Left as they are) |
| 10 | `.aid/knowledge/tech-debt.md` | 92 | 1 | -- | task-012 | Row W1-6 (the `aid-triage` roster entry) |
| 11 | `.aid/knowledge/test-landscape.md` | 183, 326 | 2 | -- | task-018 | Names `test-triage-routing.sh`, which task-009 deletes |
| 12 | `.claude/skills/generate-profile/SKILL.md` | 96, 107 | 2 | -- | task-009 | Line 96: the curated count that includes the triage router; line 107: history prose naming `aid-triage` |
| 13 | `README.md` | 23, 35, 83, 191, 201, 209, 254 | 8 | -- | task-011 | Prose; the count phrases are S7's |
| 14 | `canonical/aid/templates/shortcut-catalog.yml` | 22, 903 | 2 | -- | task-009 | Comments at lines 22 and 903 only; no row changes |
| 15 | `canonical/skills/aid-describe/SKILL.md` | 57 | 1 | -- | task-009 |  |
| 16 | `canonical/skills/aid-describe/references/elicitation-engine.md` | 7, 317, 322 | 3 | -- | task-009 |  |
| 17 | `canonical/skills/aid-describe/references/state-first-run.md` | 83 | 1 | -- | task-009 |  |
| 18 | `canonical/skills/aid-monitor/SKILL.md` | 7, 24 | 2 | -- | task-008 |  |
| 19 | `canonical/skills/aid-monitor/references/state-route.md` | 20, 38, 40 | 3 | -- | task-008 |  |
| 20 | `canonical/skills/aid-triage/SKILL.md` | 2, 30, 46, 59, 67, 111 | 6 | -- | task-009 | Deleted with the folder (its `references/state-classify.md` and `state-suggest.md` carry no hit and go too). task-006 first moves its question shortcut, work-type heuristic and scope judgement into `aid-orchestrate` |
| 21 | `docs/aid-methodology.md` | 40, 78, 91, 122, 124, 126, 231, 403, 405, 410, 499, 551, 559, 584, 764, 936, 972, 999, 1077, 1258, 1369, 1401, 1404, 1446, 1457, 1464, 1491 | 29 | -- | task-011 |  |
| 22 | `docs/diagram-content-reference.md` | 25, 46, 47, 52, 53, 56, 77, 125, 131, 140, 143, 146, 157, 159 | 14 | -- | task-011 |  |
| 23 | `docs/faq.md` | 17, 91, 118 | 3 | -- | task-011 |  |
| 24 | `docs/glossary.md` | 9, 46, 48, 66, 72 | 6 | -- | task-011 |  |
| 25 | `docs/repository-structure.md` | 77, 79 | 2 | -- | task-011 | Prose (line 77 also holds counts, which are S7's) |
| 26 | `site/scripts/.skills-manifest.json` | 353, 354, 545, 918, 919 | 5 | generated (gen-skills.mjs) | task-009 | Generated: regenerated by `gen:skills` after the deletion |
| 27 | `site/scripts/__tests__/flow-classify.test.mjs` | 6, 173, 175, 176 | 4 | hand-written (site test) | task-009 |  |
| 28 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | 34, 47, 48, 67, 77, 79, 81, 153, 156, 251, 252, 254, 415, 438, 441, 646, 648, 649 | 18 | hand-written (site test) | task-009 |  |
| 29 | `site/scripts/__tests__/flow-graph.test.mjs` | 1328, 1331 | 2 | hand-written (site test) | task-009 |  |
| 30 | `site/scripts/__tests__/gen-reference.test.mjs` | 146 | 1 | hand-written (site test) | task-009 |  |
| 31 | `site/scripts/__tests__/gen-skills-index.test.mjs` | 180, 199, 200, 201 | 4 | hand-written (site test) | task-009 |  |
| 32 | `site/scripts/__tests__/skill-counts.test.mjs` | 63, 391 | 2 | hand-written (site test) | task-009 |  |
| 33 | `site/scripts/__tests__/skills-groups.test.mjs` | 7, 97, 159, 161, 162, 166, 169, 172, 175, 184 | 10 | hand-written (site test) | task-009 |  |
| 34 | `site/scripts/__tests__/skills-render-index.test.mjs` | 205, 669, 676, 684, 692 | 5 | hand-written (site test) | task-009 |  |
| 35 | `site/scripts/gen-reference.mjs` | 141, 221, 232 | 3 | hand-written (generator source) | task-009 | Lines 141 and 232 comments, line 221 rendered sentence (G19) |
| 36 | `site/scripts/skills/curated-roster.mjs` | 56 | 1 | hand-written (generator source) | task-009 |  |
| 37 | `site/scripts/skills/groups.mjs` | 36, 68 | 2 | hand-written (generator source) | task-009 |  |
| 38 | `site/scripts/skills/render-index.mjs` | 173 | 1 | hand-written (generator source) | task-009 |  |
| 39 | `site/scripts/skills/skill-counts.mjs` | 26, 30, 37, 43 | 4 | hand-written (generator source) | task-009 | `NON_CLASSIC_CURATED` names `aid-triage`; `skill-counts.test.mjs` asserts curated minus classic is 2 |
| 40 | `site/src/content/docs/concepts/faq.md` | 21, 95, 122 | 3 | synced (sync-docs.mjs) | task-011 | Synced from `docs/faq.md` |
| 41 | `site/src/content/docs/concepts/methodology.md` | 44, 82, 95, 126, 128, 130, 235, 407, 409, 414, 503, 555, 563, 588, 768, 940, 976, 1003, 1081, 1262, 1373, 1405, 1408, 1450, 1461, 1468, 1495 | 29 | synced (sync-docs.mjs) | task-011 | Synced from `docs/aid-methodology.md`: edit the source, then `sync:docs` |
| 42 | `site/src/content/docs/get-started/first-work.mdx` | 80 | 1 | hand-written (page) | task-011 |  |
| 43 | `site/src/content/docs/get-started/lite-path.mdx` | 22, 23, 24, 53, 108, 114 | 6 | hand-written (page) | task-011 |  |
| 44 | `site/src/content/docs/guides/pipeline.mdx` | 28, 47, 50, 57, 110, 219, 232 | 7 | hand-written (page) | task-011 |  |
| 45 | `site/src/content/docs/index.mdx` | 38, 77, 80, 94 | 4 | hand-written (page) | task-011 |  |
| 46 | `site/src/content/docs/reference/artifacts.md` | 17, 36 | 2 | hand-written (page) | task-011 |  |
| 47 | `site/src/content/docs/reference/glossary.md` | 13, 50, 52, 70, 76 | 6 | synced (sync-docs.mjs) | task-011 | Synced from `docs/glossary.md` |
| 48 | `site/src/content/docs/reference/overview.md` | 16 | 1 | hand-written (page) | task-011 |  |
| 49 | `site/src/content/docs/reference/repository-structure.md` | 81, 83 | 2 | synced (sync-docs.mjs) | task-011 | Synced from `docs/repository-structure.md` |
| 50 | `site/src/content/docs/reference/skills.md` | 23 | 1 | generated (gen-reference.mjs) | task-009 | Generated by `gen-reference.mjs`; the sentence comes from `gen-reference.mjs` line 221, so the generator source changes first (G19) |
| 51 | `site/src/content/docs/skills/aid-monitor.md` | 12 | 1 | generated (gen-skills.mjs) | task-008 | Generated: the `aid-monitor` description; regenerated after the `aid-monitor` edit (task-010 regenerates it again) |
| 52 | `site/src/content/docs/skills/aid-triage.md` | 2, 4, 7, 11, 16, 50, 54, 58, 62, 66, 70, 74, 78 | 26 | generated (gen-skills.mjs) | task-009 | Generated page of the retired skill: `git rm` before regenerating (G18) |
| 53 | `site/src/content/docs/skills/index.md` | 13, 19 | 3 | generated (gen-skills.mjs) | task-009 | Generated roster page; regenerated |
| 54 | `site/src/data/skill-flows/aid-describe.flow.json` | 27 | 1 | generated (gen-skills.mjs) | task-009 | Generated: the § 1d monitor-routed seed in `aid-describe/references/state-first-run.md` |
| 55 | `site/src/data/skill-flows/aid-monitor.flow.json` | 71 | 3 | generated (gen-skills.mjs) | task-008 | Generated from `aid-monitor/SKILL.md` and `references/state-route.md` |
| 56 | `site/src/data/skill-flows/aid-triage.flow.json` | 2, 6, 16, 23, 38, 45, 60, 67, 85, 92, 96, 108, 122, 136, 151, 152, 153 | 17 | generated (gen-skills.mjs) | task-009 | Generated flow of the retired skill: `git rm` before regenerating (G18) |
| 57 | `tests/canonical/test-cutover-no-dangling.sh` | 88 | 1 | -- | task-009 | Comment only (line 88); no assertion names `aid-triage` |
| 58 | `tests/canonical/test-deploy-monitor-repurpose.sh` | 13, 77, 82, 83, 88, 89, 95 | 8 | -- | task-008 | DMR01b, DMR02b, DMR03b and two comments (CR -> `/aid-triage`) |
| 59 | `tests/canonical/test-deploy-monitor-repurpose.sh` | 118 | 2 | -- | task-013 | DMR05c reads `pipeline-contracts.md` L10 |
| 60 | `tests/canonical/test-deploy-monitor-repurpose.sh` | 354 | 1 | -- | task-009 | DMR36 standalone list (task-006 adds `aid-orchestrate` to it first) |
| 61 | `tests/canonical/test-triage-routing.sh` | 3, 5, 16, 36, 42, 44, 72, 76, 78, 294 | 10 | -- | task-009 | Suite deleted by task-009 |
| 62 | `tests/cost-baseline.tsv` | 99, 210, 321, 432, 543 | 5 | -- | baseline, re-recorded at the gate | `aid-triage` cost rows; re-recorded at the gate |
| 63 | `tests/coverage-accepted-removals.tsv` | 24 | 1 | -- | history, left as is | History of removals; only appended to |

## S2 Orchestrator sites

Anchor: REQUIREMENTS.md § 11 Feature 001 `##### 5. Migration`, "Orchestrator sites". Two searches:
S2a finds the agent's name; S2b finds the bare word "orchestrator" on every other line, which is then
screened for lines that name the agent.

### S2a `aid-orchestrator`

```bash
git grep -n -o -e 'aid-orchestrator' 581a4335 -- \
  canonical/ site/ docs/ examples/ README.md .aid/knowledge/ .aid/design/ tests/ dashboard/ bin/ lib/ .claude/skills/generate-profile/
```
Hit list: 39 lines.

```text
581a4335:.aid/knowledge/architecture.md:327:aid-orchestrator
581a4335:.aid/knowledge/architecture.md:333:aid-orchestrator
581a4335:canonical/agents/aid-orchestrator/AGENT.md:2:aid-orchestrator
581a4335:canonical/aid/templates/agent-dispatch-tiering.md:48:aid-orchestrator
581a4335:canonical/aid/templates/self-review-protocol.md:9:aid-orchestrator
581a4335:canonical/skills/aid-monitor/SKILL.md:20:aid-orchestrator
581a4335:canonical/skills/aid-monitor/SKILL.md:221:aid-orchestrator
581a4335:docs/aid-methodology.md:808:aid-orchestrator
581a4335:docs/aid-methodology.md:830:aid-orchestrator
581a4335:examples/brownfield-full-path/README.md:331:aid-orchestrator
581a4335:examples/brownfield-full-path/README.md:342:aid-orchestrator
581a4335:site/src/content/docs/concepts/methodology.md:812:aid-orchestrator
581a4335:site/src/content/docs/concepts/methodology.md:834:aid-orchestrator
581a4335:site/src/content/docs/reference/agents.md:51:aid-orchestrator
581a4335:site/src/content/docs/reference/agents.md:57:aid-orchestrator
581a4335:site/src/content/docs/reference/agents.md:57:aid-orchestrator
581a4335:site/src/content/docs/skills/aid-monitor.md:66:aid-orchestrator
581a4335:site/src/data/skill-flows/aid-monitor.flow.json:64:aid-orchestrator
581a4335:tests/canonical/test-deploy-monitor-repurpose.sh:38:aid-orchestrator
581a4335:tests/canonical/test-deploy-monitor-repurpose.sh:146:aid-orchestrator
581a4335:tests/cost-baseline.tsv:6:aid-orchestrator
581a4335:tests/coverage-accepted-removals.tsv:119:aid-orchestrator
581a4335:tests/coverage-accepted-removals.tsv:296:aid-orchestrator
581a4335:tests/coverage-baseline.tsv:1389:aid-orchestrator
581a4335:tests/coverage-baseline.tsv:1440:aid-orchestrator
581a4335:tests/windows/Test-AidInstaller.ps1:2198:aid-orchestrator
581a4335:tests/windows/Test-AidInstaller.ps1:2201:aid-orchestrator
581a4335:tests/windows/Test-AidInstaller.ps1:2205:aid-orchestrator
581a4335:tests/windows/Test-AidInstaller.ps1:2225:aid-orchestrator
581a4335:tests/windows/Test-AidInstaller.ps1:2237:aid-orchestrator
581a4335:tests/windows/Test-AidInstaller.ps1:2247:aid-orchestrator
581a4335:tests/windows/Test-AidInstaller.ps1:2248:aid-orchestrator
581a4335:tests/windows/Test-AidInstaller.ps1:2249:aid-orchestrator
581a4335:tests/windows/Test-AidInstaller.ps1:2290:aid-orchestrator
581a4335:tests/windows/Test-AidInstaller.ps1:2291:aid-orchestrator
581a4335:tests/windows/Test-AidInstaller.ps1:2522:aid-orchestrator
581a4335:tests/windows/Test-AidInstaller.ps1:2548:aid-orchestrator
581a4335:tests/windows/Test-AidInstaller.ps1:2549:aid-orchestrator
581a4335:tests/windows/Test-AidInstaller.ps1:2580:aid-orchestrator
```
Owners (S2a): 16 hit rows, 39 hit-list lines, 0 empty owner cells.

| # | File | Lines (hit-list entries) | Hits | Class (S10) | Owner | Note |
|---|---|---|---|---|---|---|
| 1 | `.aid/knowledge/architecture.md` | 327, 333 | 2 | -- | task-013 | Agent roster (327) and Medium tier row (333) |
| 2 | `canonical/agents/aid-orchestrator/AGENT.md` | 2 | 1 | -- | task-008 | Deleted with the folder (Files and layout) |
| 3 | `canonical/aid/templates/agent-dispatch-tiering.md` | 48 | 1 | -- | task-008 | § Per-agent defaults row |
| 4 | `canonical/aid/templates/self-review-protocol.md` | 9 | 1 | -- | task-008 | "pure coordinators (`aid-orchestrator`)" |
| 5 | `canonical/skills/aid-monitor/SKILL.md` | 20, 221 | 2 | -- | task-008 | Default executor (line 20) and ROUTE dispatch row (line 221) |
| 6 | `docs/aid-methodology.md` | 808, 830 | 2 | -- | task-011 | Agent-tier diagram node (808) and the Medium tier list (830); the tier counts `Medium tier — 7 default` (804) and `Medium (7 default)` (830) go to 6 (S7e) |
| 7 | `examples/brownfield-full-path/README.md` | 331, 342 | 2 | -- | task-011 | "The `aid-orchestrator` agent reads the task file ..." |
| 8 | `site/src/content/docs/concepts/methodology.md` | 812, 834 | 2 | synced (sync-docs.mjs) | task-011 | Synced from `docs/aid-methodology.md` (its tier labels 808 and 834 are S7e rows) |
| 9 | `site/src/content/docs/reference/agents.md` | 51, 57 | 3 | generated (gen-reference.mjs) | task-008 | Generated by `gen-reference.mjs` from `canonical/agents/*/AGENT.md` |
| 10 | `site/src/content/docs/skills/aid-monitor.md` | 66 | 1 | generated (gen-skills.mjs) | task-008 | Generated (Dispatch table ROUTE row) |
| 11 | `site/src/data/skill-flows/aid-monitor.flow.json` | 64 | 1 | generated (gen-skills.mjs) | task-008 | Generated (Dispatch table ROUTE row) |
| 12 | `tests/canonical/test-deploy-monitor-repurpose.sh` | 38, 146 | 2 | -- | task-008 | Line 38 comment; line 146 the ROUTE-row assertion |
| 13 | `tests/cost-baseline.tsv` | 6 | 1 | -- | baseline, re-recorded at the gate | `agent aid-orchestrator/AGENT.md` row |
| 14 | `tests/coverage-accepted-removals.tsv` | 119, 296 | 2 | -- | history, left as is | History |
| 15 | `tests/coverage-baseline.tsv` | 1389, 1440 | 2 | -- | baseline, re-recorded at the gate | Two `test-aid-migrate.sh` rows naming the legacy `aid-orchestrator.md` fixture file; unchanged by this delivery |
| 16 | `tests/windows/Test-AidInstaller.ps1` | 2198, 2201, 2205, 2225, 2237, 2247, 2248, 2249, 2290, 2291, 2522, 2548, 2549, 2580 | 14 | -- | task-008 | Legacy file name in the T49/T52 fixture: kept as it is (F001 § 5; task-008 criterion: its diff stays empty) |

### S2b the word "orchestrator" on lines without `aid-orchestrator`

```bash
git grep -c -i -w -e orchestrator --and --not -e aid-orchestrator 581a4335 -- \
  canonical/ site/ docs/ examples/ README.md .aid/knowledge/ .aid/design/ tests/ dashboard/ bin/ lib/ .claude/skills/generate-profile/
```
Hit list: 73 files, 202 lines (count per file).

```text
581a4335:.aid/knowledge/STATE.md:7
581a4335:.aid/knowledge/artifact-schemas.md:1
581a4335:.aid/knowledge/authoring-conventions.md:1
581a4335:.aid/knowledge/module-map.md:1
581a4335:.aid/knowledge/quality-gates.md:12
581a4335:.aid/knowledge/release-tracking.md:1
581a4335:.aid/knowledge/tech-debt.md:1
581a4335:canonical/agents/aid-architect/AGENT.md:1
581a4335:canonical/agents/aid-developer/AGENT.md:3
581a4335:canonical/agents/aid-interviewer/AGENT.md:1
581a4335:canonical/agents/aid-operator/AGENT.md:4
581a4335:canonical/agents/aid-orchestrator/AGENT.md:1
581a4335:canonical/agents/aid-researcher/AGENT.md:2
581a4335:canonical/agents/aid-reviewer/AGENT.md:2
581a4335:canonical/agents/aid-tech-writer/AGENT.md:2
581a4335:canonical/aid/rules.md:2
581a4335:canonical/aid/scripts/execute/write-control-signal.sh:1
581a4335:canonical/aid/scripts/kb/discover-preflight.sh:2
581a4335:canonical/aid/scripts/kb/kb-citation-lint.sh:1
581a4335:canonical/aid/scripts/summarize/grade-summary.sh:1
581a4335:canonical/aid/templates/agent-boilerplate.md:1
581a4335:canonical/aid/templates/dispatch-protocol-checklist.md:1
581a4335:canonical/aid/templates/kb-authoring/review-rubric.md:1
581a4335:canonical/aid/templates/knowledge-summary/section-templates/agentic-pipeline.md:1
581a4335:canonical/aid/templates/knowledge-summary/section-templates/data-pipeline.md:1
581a4335:canonical/aid/templates/long-wait-protocol.md:8
581a4335:canonical/aid/templates/reviewer-dispatch.md:4
581a4335:canonical/aid/templates/reviewer-ledger-schema.md:14
581a4335:canonical/aid/templates/rough-time-hints.md:1
581a4335:canonical/aid/templates/state-machine-chaining.md:5
581a4335:canonical/aid/templates/subagent-heartbeat-protocol.md:11
581a4335:canonical/aid/templates/task-detail-template.md:2
581a4335:canonical/aid/templates/task-state-template.yml:2
581a4335:canonical/aid/templates/work-state-template.yml:1
581a4335:canonical/skills/aid-define/references/reviewer-brief.md:1
581a4335:canonical/skills/aid-discover/SKILL.md:6
581a4335:canonical/skills/aid-discover/references/agent-prompts.md:3
581a4335:canonical/skills/aid-discover/references/path-config.md:1
581a4335:canonical/skills/aid-discover/references/reviewer-prompt-actback.md:2
581a4335:canonical/skills/aid-discover/references/reviewer-prompt-anatomy.md:3
581a4335:canonical/skills/aid-discover/references/reviewer-prompt-correctness.md:1
581a4335:canonical/skills/aid-discover/references/reviewer-prompt-teachback.md:2
581a4335:canonical/skills/aid-discover/references/reviewer-prompt.md:2
581a4335:canonical/skills/aid-discover/references/state-closure.md:2
581a4335:canonical/skills/aid-discover/references/state-elicit.md:2
581a4335:canonical/skills/aid-discover/references/state-fix.md:2
581a4335:canonical/skills/aid-discover/references/state-generate.md:3
581a4335:canonical/skills/aid-discover/references/state-q-and-a.md:1
581a4335:canonical/skills/aid-discover/references/state-review.md:3
581a4335:canonical/skills/aid-execute/SKILL.md:2
581a4335:canonical/skills/aid-execute/references/reviewer-brief.md:1
581a4335:canonical/skills/aid-execute/references/state-execute.md:16
581a4335:canonical/skills/aid-execute/references/state-fix.md:1
581a4335:canonical/skills/aid-execute/references/state-review.md:4
581a4335:canonical/skills/aid-summarize/references/state-validate.md:1
581a4335:canonical/skills/aid-update-kb/SKILL.md:3
581a4335:canonical/skills/aid-update-kb/references/state-analyze.md:2
581a4335:dashboard/scripts/write-control-signal.sh:1
581a4335:docs/aid-methodology.md:4
581a4335:site/scripts/__tests__/flow-advance.test.mjs:1
581a4335:site/scripts/__tests__/flow-graph-doorways.test.mjs:2
581a4335:site/src/content/docs/concepts/methodology.md:4
581a4335:site/src/data/skill-flows/aid-discover.flow.json:5
581a4335:site/src/data/skill-flows/aid-execute.flow.json:3
581a4335:site/src/data/skill-flows/aid-summarize.flow.json:1
581a4335:site/src/data/skill-flows/aid-update-kb.flow.json:1
581a4335:tests/canonical/fixtures/kb-essence/teachback/pass-kb/knowledge/domain-glossary.md:1
581a4335:tests/canonical/test-disjoint-merge.sh:2
581a4335:tests/canonical/test-doc-set-mapping.sh:6
581a4335:tests/canonical/test-doc-set-propose-confirm.sh:2
581a4335:tests/canonical/test-doc-set-read.sh:1
581a4335:tests/canonical/test-update-kb-scope-fidelity.sh:3
581a4335:tests/windows/Test-AidInstaller.ps1:1
```
**Screening.** The task asks for "orchestrator" where it names that agent. Each line was read
(`git grep -n -i -w -e orchestrator --and --not -e aid-orchestrator 581a4335 -- <file>`). Three files
carry lines that name the agent; they are hit rows. Every other line uses "orchestrator" as the role of
whoever dispatches -- the running skill or the main conversation ("the main/orchestrator agent", "the
orchestrator runs `grade.sh`", "report to Orchestrator" in the sub-agent files) -- which stays true once
the host agent orchestrates (FR-13), so those lines are not hits and need no edit (LIKELY; see Delta,
Judgement calls).

| # | File | Lines | Hits | Owner | Note |
|---|---|---|---|---|---|
| 1 | `canonical/agents/aid-orchestrator/AGENT.md` | 8 | 1 | task-008 | "You are the Orchestrator": the agent's own body; deleted with the folder |
| 2 | `.aid/knowledge/module-map.md` | 86 | 1 | task-013 | Line 86: `canonical/agents/*` (9) roster, "Roles: ... orchestrator ..." |
| 3 | `tests/windows/Test-AidInstaller.ps1` | 2226 | 1 | task-008 | Line 2226: fixture text "old codex orchestrator skill" in the legacy `aid-orchestrator.md` fixture; kept as it is |

## S3 ticket_ref sites

Anchor: REQUIREMENTS.md § 11 Feature 001 `##### 5. Migration`, "`ticket_ref` sites".

```bash
git grep -n -o -e 'ticket_ref' 581a4335 -- \
  canonical/ site/ docs/ examples/ README.md .aid/knowledge/ .aid/design/ tests/ dashboard/ bin/ lib/ .claude/skills/generate-profile/
```
Hit list: 213 lines.

```text
581a4335:.aid/knowledge/artifact-schemas.md:143:ticket_ref
581a4335:.aid/knowledge/artifact-schemas.md:174:ticket_ref
581a4335:.aid/knowledge/artifact-schemas.md:202:ticket_ref
581a4335:.aid/knowledge/infrastructure.md:275:ticket_ref
581a4335:.aid/knowledge/release-tracking.md:110:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:55:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:57:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:61:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:66:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:71:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:73:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:74:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:83:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:85:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:85:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:86:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:86:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:91:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:93:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:103:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:112:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:126:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:131:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:132:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:133:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:134:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:140:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:144:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:149:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:150:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:152:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:154:ticket_ref
581a4335:canonical/aid/templates/connectors/consumption-protocol.md:166:ticket_ref
581a4335:canonical/aid/templates/delivery-state-template.yml:11:ticket_ref
581a4335:canonical/aid/templates/delivery-state-template.yml:21:ticket_ref
581a4335:canonical/aid/templates/delivery-state-template.yml:24:ticket_ref
581a4335:canonical/aid/templates/delivery-state-template.yml:58:ticket_ref
581a4335:canonical/aid/templates/delivery-state-template.yml:59:ticket_ref
581a4335:canonical/aid/templates/requirements/requirements-template.md:127:ticket_ref
581a4335:canonical/aid/templates/requirements/requirements-template.md:132:ticket_ref
581a4335:canonical/aid/templates/shortcut-engine.md:435:ticket_ref
581a4335:canonical/aid/templates/shortcut-engine.md:440:ticket_ref
581a4335:canonical/aid/templates/task-state-template.yml:22:ticket_ref
581a4335:canonical/aid/templates/task-state-template.yml:29:ticket_ref
581a4335:canonical/aid/templates/task-state-template.yml:59:ticket_ref
581a4335:canonical/aid/templates/task-state-template.yml:60:ticket_ref
581a4335:canonical/aid/templates/work-state-template.yml:67:ticket_ref
581a4335:canonical/aid/templates/work-state-template.yml:71:ticket_ref
581a4335:canonical/aid/templates/work-state-template.yml:128:ticket_ref
581a4335:canonical/aid/templates/work-state-template.yml:129:ticket_ref
581a4335:canonical/skills/aid-describe/references/state-first-run.md:96:ticket_ref
581a4335:canonical/skills/aid-describe/references/state-first-run.md:102:ticket_ref
581a4335:canonical/skills/aid-plan/references/first-run-loop.md:130:ticket_ref
581a4335:canonical/skills/aid-plan/references/first-run-loop.md:133:ticket_ref
581a4335:canonical/skills/aid-specify/references/state-initialize.md:108:ticket_ref
581a4335:dashboard/server/tests/test_task033_execution_control_round_trips.py:366:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-api.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-api.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-cli.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-cli.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-config.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-config.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-dashboard.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-dashboard.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-data-model.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-data-model.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-data-pipeline.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-data-pipeline.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-infra.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-infra.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-integration.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-integration.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-job.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-job.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-messaging.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-messaging.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-test.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-test.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-theme.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-theme.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-ui.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create-ui.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-create.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-deprecate.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-deprecate.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-describe.flow.json:27:ticket_ref
581a4335:site/src/data/skill-flows/aid-describe.flow.json:27:ticket_ref
581a4335:site/src/data/skill-flows/aid-experiment.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-experiment.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-fix.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-fix.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-migrate.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-migrate.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-plan.flow.json:27:ticket_ref
581a4335:site/src/data/skill-flows/aid-plan.flow.json:27:ticket_ref
581a4335:site/src/data/skill-flows/aid-refactor.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-refactor.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-remove.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-remove.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-specify.flow.json:27:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-api.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-api.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-cli.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-cli.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-config.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-config.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-dashboard.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-dashboard.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-data-model.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-data-model.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-data-pipeline.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-data-pipeline.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-infra.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-infra.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-integration.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-integration.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-job.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-job.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-messaging.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-messaging.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-test.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-test.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-theme.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-theme.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-ui.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update-ui.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update.flow.json:84:ticket_ref
581a4335:site/src/data/skill-flows/aid-update.flow.json:84:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:3:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:6:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:14:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:19:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:21:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:24:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:43:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:73:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:79:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:80:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:106:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:112:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:113:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:115:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:116:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:117:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:119:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:120:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:121:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:123:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:128:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:130:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:134:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:158:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:160:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:161:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:163:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:164:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:166:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:167:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:169:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:170:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:173:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:174:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:175:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:176:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:177:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:178:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:179:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:180:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:185:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:186:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:188:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:189:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:191:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:194:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:200:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:203:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:206:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:211:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:217:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:220:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:223:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:231:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:234:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:238:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:245:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:249:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:281:ticket_ref
581a4335:tests/canonical/test-connector-consumption-linkage.sh:305:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:40:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:41:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:92:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:94:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:360:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:360:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:381:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:382:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:387:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:387:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:388:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:388:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:389:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:389:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:391:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:392:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:421:ticket_ref
581a4335:tests/canonical/test-ticket-retirement-structural.sh:422:ticket_ref
581a4335:tests/coverage-baseline.tsv:6173:ticket_ref
581a4335:tests/coverage-baseline.tsv:6187:ticket_ref
581a4335:tests/coverage-baseline.tsv:6188:ticket_ref
581a4335:tests/coverage-baseline.tsv:6189:ticket_ref
581a4335:tests/coverage-baseline.tsv:6191:ticket_ref
581a4335:tests/coverage-rehome-allowlist.tsv:35:ticket_ref
```
Owners: 56 hit rows, 213 hit-list lines, 0 empty owner cells.

| # | File | Lines (hit-list entries) | Hits | Class (S10) | Owner | Note |
|---|---|---|---|---|---|---|
| 1 | `.aid/knowledge/artifact-schemas.md` | 143, 174, 202 | 3 | -- | task-012 | Pipeline State, Delivery Lifecycle and Task State rows |
| 2 | `.aid/knowledge/infrastructure.md` | 275 | 1 | -- | task-012 | The `ticket_ref` traceability sentence |
| 3 | `.aid/knowledge/release-tracking.md` | 110 | 1 | -- | history, left as is | Shipped history |
| 4 | `canonical/aid/templates/connectors/consumption-protocol.md` | 55, 57, 61, 66, 71, 73, 74, 83, 85, 86, 91, 93, 103, 112, 126, 131, 132, 133, 134, 140, 144, 149, 150, 152, 154, 166 | 28 | -- | task-007 | § Multi-level `ticket_ref` linkage, rewritten for the one `sources:` list |
| 5 | `canonical/aid/templates/delivery-state-template.yml` | 11, 21, 24, 58, 59 | 5 | -- | task-003 | Key and notes removed |
| 6 | `canonical/aid/templates/requirements/requirements-template.md` | 127, 132 | 2 | -- | task-003 | Feature `**Ticket:**` line and its `ticket_ref` comment removed |
| 7 | `canonical/aid/templates/shortcut-engine.md` | 435, 440 | 2 | -- | task-007 | Step 4b: write a `sources:` entry instead |
| 8 | `canonical/aid/templates/task-state-template.yml` | 22, 29, 59, 60 | 4 | -- | task-003 | Key and notes removed |
| 9 | `canonical/aid/templates/work-state-template.yml` | 67, 71, 128, 129 | 4 | -- | task-003 | Key and note removed; `intent:`, `sources:`, `write_backs:` added |
| 10 | `canonical/skills/aid-describe/references/state-first-run.md` | 96, 102 | 2 | -- | task-007 | Step 3b |
| 11 | `canonical/skills/aid-plan/references/first-run-loop.md` | 130, 133 | 2 | -- | task-007 | The deliverable `ticket_ref` step |
| 12 | `canonical/skills/aid-specify/references/state-initialize.md` | 108 | 1 | -- | task-007 | Step 3b |
| 13 | `dashboard/server/tests/test_task033_execution_control_round_trips.py` | 366 | 1 | -- | task-003 | Fixture line `ticket_ref: --` (line 366) |
| 14 | `site/src/data/skill-flows/aid-create-api.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 15 | `site/src/data/skill-flows/aid-create-cli.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 16 | `site/src/data/skill-flows/aid-create-config.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 17 | `site/src/data/skill-flows/aid-create-dashboard.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 18 | `site/src/data/skill-flows/aid-create-data-model.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 19 | `site/src/data/skill-flows/aid-create-data-pipeline.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 20 | `site/src/data/skill-flows/aid-create-infra.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 21 | `site/src/data/skill-flows/aid-create-integration.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 22 | `site/src/data/skill-flows/aid-create-job.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 23 | `site/src/data/skill-flows/aid-create-messaging.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 24 | `site/src/data/skill-flows/aid-create-test.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 25 | `site/src/data/skill-flows/aid-create-theme.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 26 | `site/src/data/skill-flows/aid-create-ui.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 27 | `site/src/data/skill-flows/aid-create.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 28 | `site/src/data/skill-flows/aid-deprecate.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 29 | `site/src/data/skill-flows/aid-describe.flow.json` | 27 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`state-first-run.md`) |
| 30 | `site/src/data/skill-flows/aid-experiment.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 31 | `site/src/data/skill-flows/aid-fix.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 32 | `site/src/data/skill-flows/aid-migrate.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 33 | `site/src/data/skill-flows/aid-plan.flow.json` | 27 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`first-run-loop.md`) |
| 34 | `site/src/data/skill-flows/aid-refactor.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 35 | `site/src/data/skill-flows/aid-remove.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 36 | `site/src/data/skill-flows/aid-specify.flow.json` | 27 | 1 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`state-initialize.md`) |
| 37 | `site/src/data/skill-flows/aid-update-api.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 38 | `site/src/data/skill-flows/aid-update-cli.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 39 | `site/src/data/skill-flows/aid-update-config.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 40 | `site/src/data/skill-flows/aid-update-dashboard.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 41 | `site/src/data/skill-flows/aid-update-data-model.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 42 | `site/src/data/skill-flows/aid-update-data-pipeline.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 43 | `site/src/data/skill-flows/aid-update-infra.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 44 | `site/src/data/skill-flows/aid-update-integration.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 45 | `site/src/data/skill-flows/aid-update-job.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 46 | `site/src/data/skill-flows/aid-update-messaging.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 47 | `site/src/data/skill-flows/aid-update-test.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 48 | `site/src/data/skill-flows/aid-update-theme.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 49 | `site/src/data/skill-flows/aid-update-ui.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 50 | `site/src/data/skill-flows/aid-update.flow.json` | 84 | 2 | generated (gen-skills.mjs) | task-007 | Generated; regenerated by `gen:skills` after the source edit (`shortcut-engine.md` Step 4b excerpt) |
| 51 | `tests/canonical/test-connector-consumption-linkage.sh` | 3, 6, 14, 19, 21, 24, 43, 73, 79, 80, 128, 130, 134, 158, 160, 161, 163, 164, 166, 167, 169, 170, 173, 174, 175, 176, 177, 178, 179, 180, 185, 186, 188, 189, 191, 194, 200, 203, 206, 211, 217, 220, 223, 231, 234, 238, 245, 249, 281, 305 | 50 | -- | task-007 | CL01 to CL42: the consumption-protocol assertions and the scripted resolution |
| 52 | `tests/canonical/test-connector-consumption-linkage.sh` | 106, 112, 113, 115, 116, 117, 119, 120, 121, 123 | 10 | -- | task-003 | CL08c to CL08f: the template assertions (lines 106 to 123) |
| 53 | `tests/canonical/test-ticket-retirement-structural.sh` | 40, 41, 92, 94, 381, 382, 387, 388, 389 | 12 | -- | task-003 | T087 to T089 and their comments (the templates) |
| 54 | `tests/canonical/test-ticket-retirement-structural.sh` | 360, 391, 392, 421, 422 | 6 | -- | task-007 | T073, T091, T092, T097, T098 (consumption-protocol, state-first-run, state-initialize, shortcut-engine) |
| 55 | `tests/coverage-baseline.tsv` | 6173, 6187, 6188, 6189, 6191 | 5 | -- | baseline, re-recorded at the gate | T073, T087 to T089, T091 rows |
| 56 | `tests/coverage-rehome-allowlist.tsv` | 35 | 1 | -- | task-003 | Line 35: the T090 rehome rule for the feature `**Ticket:**` line, which task-003 removes |

## S4 skill-routing.md

Two commands: inbound references to the file in the path set, and the file itself.

First command (inbound references):

```bash
git grep -n -o -e 'skill-routing' 581a4335 -- \
  canonical/ site/ docs/ examples/ README.md .aid/knowledge/ .aid/design/ tests/ dashboard/ bin/ lib/ .claude/skills/generate-profile/
```
```text
(no output)
```

Second command (the file itself):

```bash
git ls-tree -r --name-only 581a4335 -- .aid/design/
```
```text
.aid/design/README.md
.aid/design/knowledge-graph-redesign.md
.aid/design/skill-routing.md
```

| # | File | Lines | Hits | Owner | Note |
|---|---|---|---|---|---|
| 1 | `.aid/design/skill-routing.md` | (the file) | 1 | task-008 | Deleted. No file in the path set refers to it; `.aid/design/README.md` does not mention it, so task-008's "remove any mention of it in `.aid/design/README.md`" has nothing to remove |

## S5 Suites that assert the rules text

Anchor: REQUIREMENTS.md § 11 Feature 001 `##### 5. Migration`, "Suites that assert the rules text". The
patterns are the summary markers, a distinctive phrase of each of the seven summary bullets, the
"seven bullets" wording, the KI-001 wording, and the eight `## ` headings of `canonical/aid/rules.md` at
the base.

```bash
git grep -n -o -F -e 'AID:SUMMARY' -e 'Record every state change' -e 'are transient: nothing permanent' \
  -e 'Never name a work id' -e 'Consult the Knowledge Base (' -e 'resolve and follow its review criteria' \
  -e 'Review output uses the 7-column ledger' -e 'Write only inside the project directory' -e 'seven bullets' \
  -e 'FULL or the LITE path' -e '## Summary' -e '## Tracking discipline' -e '## Knowledge Base' -e '## Connectors' \
  -e '## Workflow' -e '## Review criteria' -e '## Review output format' -e '## Permissions' 581a4335 -- \
  tests/ site/scripts/__tests__/ site/src/lib/__tests__/ site/src/data/__tests__/ dashboard/reader/tests/ dashboard/server/tests/ ':!**/fixtures/**'
```
Hit list: 109 lines.

```text
581a4335:site/scripts/__tests__/gen-skills.test.mjs:1175:## Knowledge Base
581a4335:tests/canonical/test-aid-cli-parity.sh:6150:AID:SUMMARY
581a4335:tests/canonical/test-aid-cli-parity.sh:6150:AID:SUMMARY
581a4335:tests/canonical/test-aid-cli-parity.sh:6198:## Workflow
581a4335:tests/canonical/test-aid-cli-parity.sh:6250:## Workflow
581a4335:tests/canonical/test-aid-cli-parity.sh:6253:## Workflow
581a4335:tests/canonical/test-aid-cli-parity.sh:6253:## Workflow
581a4335:tests/canonical/test-aid-migrate.sh:565:AID:SUMMARY
581a4335:tests/canonical/test-aid-migrate.sh:565:AID:SUMMARY
581a4335:tests/canonical/test-connector-skills-structural.sh:6:## Connectors
581a4335:tests/canonical/test-connector-skills-structural.sh:42:## Connectors
581a4335:tests/canonical/test-connector-skills-structural.sh:205:## Connectors
581a4335:tests/canonical/test-connector-skills-structural.sh:205:## Connectors
581a4335:tests/canonical/test-connector-skills-structural.sh:216:## Connectors
581a4335:tests/canonical/test-connector-skills-structural.sh:216:## Connectors
581a4335:tests/canonical/test-connector-skills-structural.sh:217:## Connectors
581a4335:tests/canonical/test-dogfood-byte-identity.sh:262:AID:SUMMARY
581a4335:tests/canonical/test-dogfood-byte-identity.sh:262:AID:SUMMARY
581a4335:tests/canonical/test-harvest-coined-terms.sh:364:## Summary
581a4335:tests/canonical/test-harvest-coined-terms.sh:365:## Summary
581a4335:tests/canonical/test-install-core-primitives.sh:47:AID:SUMMARY
581a4335:tests/canonical/test-install-core-primitives.sh:47:AID:SUMMARY
581a4335:tests/canonical/test-install-core-primitives.sh:52:seven bullets
581a4335:tests/canonical/test-install-core-primitives.sh:69:## Summary
581a4335:tests/canonical/test-install-core-primitives.sh:73:AID:SUMMARY
581a4335:tests/canonical/test-install-core-primitives.sh:73:AID:SUMMARY
581a4335:tests/canonical/test-install-core-primitives.sh:75:AID:SUMMARY
581a4335:tests/canonical/test-install-core-primitives.sh:77:AID:SUMMARY
581a4335:tests/canonical/test-install-core-primitives.sh:77:AID:SUMMARY
581a4335:tests/canonical/test-install-core-primitives.sh:213:## Summary
581a4335:tests/canonical/test-install-core-primitives.sh:213:AID:SUMMARY
581a4335:tests/canonical/test-install-core-primitives.sh:213:AID:SUMMARY
581a4335:tests/canonical/test-install-core-primitives.sh:213:AID:SUMMARY
581a4335:tests/canonical/test-install-core-primitives.sh:213:AID:SUMMARY
581a4335:tests/canonical/test-install-core-primitives.sh:213:AID:SUMMARY
581a4335:tests/canonical/test-install-provisioning.sh:194:## Workflow
581a4335:tests/canonical/test-install-provisioning.sh:200:## Tracking discipline
581a4335:tests/canonical/test-install-provisioning.sh:202:## Knowledge Base
581a4335:tests/canonical/test-install-provisioning.sh:204:## Workflow
581a4335:tests/canonical/test-install-provisioning.sh:206:## Review output format
581a4335:tests/canonical/test-install-provisioning.sh:208:## Permissions
581a4335:tests/canonical/test-install-provisioning.sh:212:## Workflow
581a4335:tests/canonical/test-install-provisioning.sh:217:## Workflow
581a4335:tests/canonical/test-install-provisioning.sh:219:## Permissions
581a4335:tests/canonical/test-install-provisioning.sh:225:## Workflow
581a4335:tests/canonical/test-install-provisioning.sh:225:## Workflow
581a4335:tests/canonical/test-install-provisioning.sh:230:## Connectors
581a4335:tests/canonical/test-install-provisioning.sh:231:## Connectors
581a4335:tests/canonical/test-install-provisioning.sh:239:## Tracking discipline
581a4335:tests/canonical/test-install-provisioning.sh:241:## Knowledge Base
581a4335:tests/canonical/test-install-provisioning.sh:243:## Connectors
581a4335:tests/canonical/test-install-provisioning.sh:245:## Workflow
581a4335:tests/canonical/test-install-provisioning.sh:247:## Review output format
581a4335:tests/canonical/test-install-provisioning.sh:249:## Permissions
581a4335:tests/canonical/test-install-provisioning.sh:253:## Connectors
581a4335:tests/canonical/test-install-provisioning.sh:258:## Connectors
581a4335:tests/canonical/test-install-provisioning.sh:260:## Permissions
581a4335:tests/canonical/test-install-provisioning.sh:266:## Connectors
581a4335:tests/canonical/test-install-provisioning.sh:266:## Connectors
581a4335:tests/canonical/test-recon-classify.sh:105:## Summary
581a4335:tests/canonical/test-recon-classify.sh:156:## Summary
581a4335:tests/canonical/test-release-install-e2e.sh:141:AID:SUMMARY
581a4335:tests/canonical/test-release-install-e2e.sh:141:AID:SUMMARY
581a4335:tests/canonical/test-shared-install.sh:60:AID:SUMMARY
581a4335:tests/canonical/test-shared-install.sh:60:AID:SUMMARY
581a4335:tests/canonical/test-shared-install.sh:161:Write only inside the project directory
581a4335:tests/canonical/test-shared-install.sh:161:Write only inside the project directory
581a4335:tests/canonical/test-shared-install.sh:166:Write only inside the project directory
581a4335:tests/canonical/test-shared-install.sh:167:Write only inside the project directory
581a4335:tests/canonical/test-shared-install.sh:172:AID:SUMMARY
581a4335:tests/canonical/test-shared-install.sh:222:## Workflow
581a4335:tests/canonical/test-shared-install.sh:227:## Workflow
581a4335:tests/canonical/test-shared-layout-sources.sh:131:AID:SUMMARY
581a4335:tests/canonical/test-shared-layout-sources.sh:131:AID:SUMMARY
581a4335:tests/canonical/test-shared-layout-sources.sh:132:AID:SUMMARY
581a4335:tests/canonical/test-shared-layout-sources.sh:132:AID:SUMMARY
581a4335:tests/canonical/test-shared-layout-sources.sh:133:AID:SUMMARY
581a4335:tests/canonical/test-shared-layout-sources.sh:133:AID:SUMMARY
581a4335:tests/canonical/test-shared-layout-sources.sh:133:seven bullets
581a4335:tests/canonical/test-shared-remove.sh:250:AID:SUMMARY
581a4335:tests/canonical/test-shared-remove.sh:250:AID:SUMMARY
581a4335:tests/coverage-baseline.tsv:4427:## Summary
581a4335:tests/coverage-baseline.tsv:4577:## Workflow
581a4335:tests/windows/Test-AidInstaller.ps1:633:## Tracking discipline
581a4335:tests/windows/Test-AidInstaller.ps1:633:## Knowledge Base
581a4335:tests/windows/Test-AidInstaller.ps1:633:## Review output format
581a4335:tests/windows/Test-AidInstaller.ps1:633:## Permissions
581a4335:tests/windows/Test-AidInstaller.ps1:663:## Tracking discipline
581a4335:tests/windows/Test-InstallProvisioning.ps1:129:## Workflow
581a4335:tests/windows/Test-InstallProvisioning.ps1:131:## Tracking discipline
581a4335:tests/windows/Test-InstallProvisioning.ps1:131:## Knowledge Base
581a4335:tests/windows/Test-InstallProvisioning.ps1:131:## Workflow
581a4335:tests/windows/Test-InstallProvisioning.ps1:131:## Review output format
581a4335:tests/windows/Test-InstallProvisioning.ps1:131:## Permissions
581a4335:tests/windows/Test-InstallProvisioning.ps1:133:## Workflow
581a4335:tests/windows/Test-InstallProvisioning.ps1:133:## Permissions
581a4335:tests/windows/Test-InstallProvisioning.ps1:139:## Workflow
581a4335:tests/windows/Test-InstallProvisioning.ps1:139:## Workflow
581a4335:tests/windows/Test-InstallProvisioning.ps1:143:## Connectors
581a4335:tests/windows/Test-InstallProvisioning.ps1:147:## Tracking discipline
581a4335:tests/windows/Test-InstallProvisioning.ps1:147:## Knowledge Base
581a4335:tests/windows/Test-InstallProvisioning.ps1:147:## Connectors
581a4335:tests/windows/Test-InstallProvisioning.ps1:147:## Workflow
581a4335:tests/windows/Test-InstallProvisioning.ps1:147:## Review output format
581a4335:tests/windows/Test-InstallProvisioning.ps1:147:## Permissions
581a4335:tests/windows/Test-InstallProvisioning.ps1:149:## Connectors
581a4335:tests/windows/Test-InstallProvisioning.ps1:149:## Permissions
581a4335:tests/windows/Test-InstallProvisioning.ps1:155:## Connectors
581a4335:tests/windows/Test-InstallProvisioning.ps1:155:## Connectors
```
Owners: 16 hit rows, 109 hit-list lines, 0 empty owner cells. No suite asserts the KI-001 wording ("FULL or the LITE path", `work-NNN-*/STATE.md`), so task-002's KI-001 fix breaks no assertion.

| # | File | Lines (hit-list entries) | Hits | Owner | Note |
|---|---|---|---|---|---|
| 1 | `site/scripts/__tests__/gen-skills.test.mjs` | 1175 | 1 | task-002 | Line 1175: the `## Knowledge Base Maintenance` roster group, not the rules (no edit) |
| 2 | `tests/canonical/test-aid-cli-parity.sh` | 6150, 6198, 6250, 6253 | 6 | task-002 | FIX-D8 (lines 6198, 6250, 6253): `## Workflow` -> `## Handling a request` (edit); line 6150 reads the summary at run time |
| 3 | `tests/canonical/test-aid-migrate.sh` | 565 | 2 | task-002 | Reads the summary at run time (no edit) |
| 4 | `tests/canonical/test-connector-skills-structural.sh` | 6, 42, 205, 216, 217 | 7 | task-002 | ST31 to ST38: `## Connectors` and its connector wording in `canonical/aid/rules.md` and the installed `.aid/runtime/rules.md`; keep the section (no edit). Copy-reading |
| 5 | `tests/canonical/test-dogfood-byte-identity.sh` | 262 | 2 | task-002 | Reads the summary at run time; copy-reading (no edit) |
| 6 | `tests/canonical/test-harvest-coined-terms.sh` | 364, 365 | 2 | task-002 | Its own output's `## Summary` heading, not the rules (no edit) |
| 7 | `tests/canonical/test-install-core-primitives.sh` | 47, 52, 69, 73, 75, 77, 213 | 15 | task-002 | Line 52: physical line count 8 -> the new count (edit). Lines 69-77 and 213: synthetic bad-rules fixtures (no edit) |
| 8 | `tests/canonical/test-install-provisioning.sh` | 194, 200, 202, 204, 206, 208, 212, 217, 219, 225, 230, 231, 239, 241, 243, 245, 247, 249, 253, 258, 260, 266 | 24 | task-002 | Own synthetic `## Workflow` / `## Connectors` fixtures; copies the real `rules.md` only as runtime payload (no edit) |
| 9 | `tests/canonical/test-recon-classify.sh` | 105, 156 | 2 | task-002 | Its own fixture's `## Summary` heading, not the rules (no edit) |
| 10 | `tests/canonical/test-release-install-e2e.sh` | 141 | 2 | task-002 | Reads the summary from a clone at run time; copy-reading (no edit) |
| 11 | `tests/canonical/test-shared-install.sh` | 60, 161, 166, 167, 172, 222, 227 | 9 | task-002 | Reads the summary at run time (no edit). Lines 161-167 sed-edit the bullet `- Write only inside the project directory.`: keep that bullet's text byte for byte. Lines 222-227: a user `## Workflow` fixture |
| 12 | `tests/canonical/test-shared-layout-sources.sh` | 131, 132, 133 | 7 | task-002 | Line 133 "rules summary block carries the seven bullets" -> 8 (edit). Lines 131-132: no tool folder, no `canonical/` path, one summary block (keep true) |
| 13 | `tests/canonical/test-shared-remove.sh` | 250 | 2 | task-002 | Reads the summary at run time (no edit) |
| 14 | `tests/coverage-baseline.tsv` | 4427, 4577 | 2 | baseline, re-recorded at the gate | Assertion-name rows (T10b, C1) |
| 15 | `tests/windows/Test-AidInstaller.ps1` | 633, 663 | 5 | task-002 | Lines 633 and 663: synthetic user `CLAUDE.md` content (no edit) |
| 16 | `tests/windows/Test-InstallProvisioning.ps1` | 129, 131, 133, 139, 143, 147, 149, 155 | 21 | task-002 | Own synthetic fixtures (no edit) |

## S6 The Q106 map

For every file on delivery-001's edit list (the F001 spec's Files and layout and Migration lists, and
the task files), the suites that read it by path or name. The search runs over the runnable suites:
`tests/canonical/test-*.sh`, `tests/canonical/*.ps1`, `tests/canonical/*.mjs`, `tests/windows/`,
`tests/lib/`, `tests/run-all.sh`, `tests/coverage-parity.sh`, `tests/cost-meter.py`, the site tests
(`site/scripts/__tests__/`, `site/src/lib/__tests__/`, `site/src/data/__tests__/`) and the dashboard tests
(`dashboard/reader/tests/`, `dashboard/server/tests/`, fixtures excluded). Baselines (`tests/*.tsv`) are
not suites; S1 to S3 list their rows.

### S6a Command

Save as a script and run it from the repository root (it is not committed anywhere; the text below is
the whole of it):

```bash
#!/usr/bin/env bash
# S6 -- suites that read a delivery-001 edit-list file by path or name (run from the repo root).
B=581a4335
SUITES=(tests/canonical/test-*.sh tests/canonical/*.ps1 tests/canonical/*.mjs tests/windows/ tests/lib/
        tests/run-all.sh tests/coverage-parity.sh tests/cost-meter.py
        site/scripts/__tests__/ site/src/lib/__tests__/ site/src/data/__tests__/
        dashboard/reader/tests/ dashboard/server/tests/ ':!dashboard/**/fixtures/**')
while IFS='|' read -r id key; do
  [ -z "$id" ] && continue
  printf '### %s  /%s/\n' "$id" "$key"
  git grep -l -E -e "$key" "$B" -- "${SUITES[@]}" | sed "s/^$B://"
done <<'KEYS'
T01 rules.md|aid/rules\.md|runtime/rules\.md
T02 work-state-template.yml|work-state-template
T03 delivery-state-template.yml|delivery-state-template
T04 task-state-template.yml|task-state-template
T05 requirements-template.md|requirements-template
T06 consumption-protocol.md|consumption-protocol
T07 shortcut-engine.md|shortcut-engine
T08 aid-specify state-initialize.md|state-initialize
T09 aid-plan first-run-loop.md|first-run-loop
T10 aid-describe state-first-run.md|state-first-run
T11 aid-describe SKILL.md|skills/aid-describe|DESCRIBE_(SKILL|DIR)
T12 aid-describe elicitation-engine.md|elicitation-engine
T13 aid-update-ticket SKILL.md|aid-update-ticket
T14 aid-monitor SKILL.md|aid-monitor
T15 aid-monitor state-route.md|state-route
T16 agent-dispatch-tiering.md|agent-dispatch-tiering
T17 self-review-protocol.md|self-review-protocol
T18 aid-orchestrator AGENT.md|aid-orchestrator
T19 .aid/design/|\.aid/design|skill-routing
T20 shortcut-catalog.yml|shortcut-catalog
T21 aid-triage/|aid-triage
T22 generate-profile SKILL.md|generate-profile/SKILL\.md
T23 site/scripts/skills/ roster files|curated-roster|skills/groups|skill-counts|render-index
T24 site/scripts/gen-reference.mjs|gen-reference
T25 test-triage-routing.sh|test-triage-routing
T26 build-shortcut-skills.py|build-shortcut-skills
T27 docs/ files|docs/(aid-methodology|diagram-content-reference|faq|glossary|repository-structure|install)\.md
T28 examples/brownfield-full-path/README.md|brownfield-full-path
T29 installer-tests.yml|installer-tests\.yml
T30 KB docs (delivery-001)|knowledge/(architecture|artifact-schemas|backlog|capability-inventory|decisions|domain-glossary|infrastructure|integration-map|module-map|pipeline-contracts|project-structure|tech-debt|test-landscape|INDEX)\.md
T31 hand-written site pages|content/docs/(index\.mdx|guides/pipeline\.mdx|get-started/(first-work|lite-path)\.mdx|reference/(artifacts|overview)\.md|guides/maintainer\.mdx)
T32 generated site pages|content/docs/(skills/|reference/(skills|agents)\.md)|skill-flows|skills-manifest
T33 synced site pages|concepts/(methodology|faq)\.md|reference/(glossary|repository-structure)\.md
T34 root README.md|ROOT\}?/README\.md|REPO\}?/README\.md|'README\.md'|"README\.md"
KEYS
```
Hit list (`### <target> /<pattern>/`, then one suite per line):

```text
### T01 rules.md  /aid/rules\.md|runtime/rules\.md/
tests/canonical/test-aid-cli-parity.sh
tests/canonical/test-aid-migrate.sh
tests/canonical/test-aid-status-drift.sh
tests/canonical/test-connector-skills-structural.sh
tests/canonical/test-dogfood-byte-identity.sh
tests/canonical/test-install-core-primitives.sh
tests/canonical/test-install-provisioning.sh
tests/canonical/test-layout-format-guard.sh
tests/canonical/test-release-install-e2e.sh
tests/canonical/test-release.sh
tests/canonical/test-shared-install.sh
tests/canonical/test-shared-layout-sources.sh
tests/canonical/test-shared-remove.sh
tests/windows/Test-AidInstaller.ps1
tests/windows/Test-InstallProvisioning.ps1
### T02 work-state-template.yml  /work-state-template/
dashboard/reader/tests/test_integration.py
dashboard/reader/tests/test_reader.py
tests/canonical/test-connector-consumption-linkage.sh
tests/canonical/test-cutover-no-dangling.sh
tests/canonical/test-delivery-gate-aggregate.sh
tests/canonical/test-describe-full-only.sh
tests/canonical/test-kb-html-claims-check.sh
tests/canonical/test-state-review-surface.sh
tests/canonical/test-task-state-transitions.sh
tests/canonical/test-ticket-retirement-structural.sh
tests/canonical/test-work-state-template.sh
tests/canonical/test-writeback-state.sh
### T03 delivery-state-template.yml  /delivery-state-template/
tests/canonical/test-connector-consumption-linkage.sh
tests/canonical/test-disjoint-merge.sh
tests/canonical/test-ticket-retirement-structural.sh
tests/canonical/test-work-state-template.sh
tests/canonical/test-writeback-state.sh
### T04 task-state-template.yml  /task-state-template/
tests/canonical/test-connector-consumption-linkage.sh
tests/canonical/test-delivery-gate-aggregate.sh
tests/canonical/test-ticket-retirement-structural.sh
tests/canonical/test-work-state-template.sh
tests/canonical/test-writeback-state.sh
### T05 requirements-template.md  /requirements-template/
tests/canonical/test-connector-consumption-linkage.sh
tests/canonical/test-ticket-retirement-structural.sh
### T06 consumption-protocol.md  /consumption-protocol/
tests/canonical/test-connector-consumption-linkage.sh
tests/canonical/test-connector-skills-structural.sh
tests/canonical/test-ticket-retirement-structural.sh
### T07 shortcut-engine.md  /shortcut-engine/
site/scripts/__tests__/flow-classify.test.mjs
site/scripts/__tests__/flow-compose.test.mjs
site/scripts/__tests__/flow-engine-core.test.mjs
site/scripts/__tests__/flow-extract-engine.test.mjs
site/scripts/__tests__/flow-graph-doorways.test.mjs
site/scripts/__tests__/flow-graph.test.mjs
site/scripts/__tests__/gen-reference.test.mjs
site/scripts/__tests__/provenance-appender.test.mjs
site/scripts/__tests__/skills-render-index.test.mjs
site/src/lib/__tests__/feature-006-head-gate.test.ts
tests/canonical/test-artifact-discipline.sh
tests/canonical/test-catalog-dirs-parity.sh
tests/canonical/test-change-refactor-family-scaffold.sh
tests/canonical/test-connector-consumption-linkage.sh
tests/canonical/test-create-family-scaffold.sh
tests/canonical/test-deploy-monitor-repurpose.sh
tests/canonical/test-describe-full-only.sh
tests/canonical/test-document-family-scaffold.sh
tests/canonical/test-downstream-worktree-entry.sh
tests/canonical/test-fix-family-scaffold.sh
tests/canonical/test-prototype-family-scaffold.sh
tests/canonical/test-shortcut-engine-contract.sh
tests/canonical/test-state-review-surface.sh
tests/canonical/test-test-experiment-family-scaffold.sh
tests/canonical/test-ticket-retirement-structural.sh
tests/canonical/test-triage-routing.sh
tests/canonical/test-work-initiation-gate.sh
### T08 aid-specify state-initialize.md  /state-initialize/
tests/canonical/test-pipeline-status-walkthrough.sh
tests/canonical/test-ticket-retirement-structural.sh
### T09 aid-plan first-run-loop.md  /first-run-loop/
tests/canonical/test-pipeline-status-walkthrough.sh
tests/canonical/test-ticket-retirement-structural.sh
### T10 aid-describe state-first-run.md  /state-first-run/
tests/canonical/test-describe-full-only.sh
tests/canonical/test-ticket-retirement-structural.sh
tests/canonical/test-work-state-template.sh
### T11 aid-describe SKILL.md  /skills/aid-describe|DESCRIBE_(SKILL|DIR)/
site/scripts/__tests__/flow-extract-dispatch.test.mjs
tests/canonical/test-cutover-no-dangling.sh
tests/canonical/test-describe-full-only.sh
tests/canonical/test-pipeline-status-walkthrough.sh
tests/canonical/test-ticket-retirement-structural.sh
tests/canonical/test-triage-routing.sh
tests/canonical/test-work-initiation-gate.sh
tests/canonical/test-work-state-template.sh
### T12 aid-describe elicitation-engine.md  /elicitation-engine/
tests/canonical/test-describe-full-only.sh
### T13 aid-update-ticket SKILL.md  /aid-update-ticket/
site/scripts/__tests__/flow-extract-residual.test.mjs
site/scripts/__tests__/gen-reference.test.mjs
tests/canonical/test-ticket-retirement-structural.sh
tests/canonical/test-ticket-skills-structural.sh
### T14 aid-monitor SKILL.md  /aid-monitor/
site/scripts/__tests__/flow-extract-dispatch.test.mjs
site/scripts/__tests__/gen-reference.test.mjs
site/scripts/__tests__/gen-skills-index.test.mjs
site/scripts/__tests__/skills-catalog.test.mjs
site/scripts/__tests__/skills-groups.test.mjs
site/scripts/__tests__/skills-render-index.test.mjs
tests/canonical/test-catalog-dirs-parity.sh
tests/canonical/test-deploy-monitor-repurpose.sh
tests/canonical/test-document-family-scaffold.sh
tests/canonical/test-ticket-retirement-structural.sh
### T15 aid-monitor state-route.md  /state-route/
tests/canonical/test-deploy-monitor-repurpose.sh
tests/canonical/test-ticket-retirement-structural.sh
### T16 agent-dispatch-tiering.md  /agent-dispatch-tiering/
### T17 self-review-protocol.md  /self-review-protocol/
tests/cost-meter.py
### T18 aid-orchestrator AGENT.md  /aid-orchestrator/
tests/canonical/test-deploy-monitor-repurpose.sh
tests/windows/Test-AidInstaller.ps1
### T19 .aid/design/  /\.aid/design|skill-routing/
tests/canonical/test-shared-install.sh
tests/canonical/test-shared-remove.sh
### T20 shortcut-catalog.yml  /shortcut-catalog/
dashboard/reader/tests/test_shortcut_kind_map_cross_runtime_parity.py
dashboard/reader/tests/test_work003_state_schema.py
site/scripts/__tests__/flow-classify.test.mjs
site/scripts/__tests__/flow-compose.test.mjs
site/scripts/__tests__/gen-reference.test.mjs
site/scripts/__tests__/gen-skills-index.test.mjs
site/scripts/__tests__/gen-skills.test.mjs
site/scripts/__tests__/skill-counts.test.mjs
site/scripts/__tests__/skills-catalog.test.mjs
site/scripts/__tests__/skills-render-index.test.mjs
site/src/lib/__tests__/feature-006-head-gate.test.ts
site/src/lib/__tests__/skill-node-panel.test.ts
tests/canonical/test-catalog-dirs-parity.sh
tests/canonical/test-change-refactor-family-scaffold.sh
tests/canonical/test-connector-skills-structural.sh
tests/canonical/test-create-family-scaffold.sh
tests/canonical/test-deploy-monitor-repurpose.sh
tests/canonical/test-doc-counts.sh
tests/canonical/test-document-family-scaffold.sh
tests/canonical/test-fix-family-scaffold.sh
tests/canonical/test-prototype-family-scaffold.sh
tests/canonical/test-shortcut-builder-invariants.sh
tests/canonical/test-shortcut-engine-contract.sh
tests/canonical/test-test-experiment-family-scaffold.sh
tests/canonical/test-triage-routing.sh
### T21 aid-triage/  /aid-triage/
site/scripts/__tests__/flow-classify.test.mjs
site/scripts/__tests__/flow-extract-dispatch.test.mjs
site/scripts/__tests__/flow-graph.test.mjs
site/scripts/__tests__/gen-reference.test.mjs
site/scripts/__tests__/gen-skills-index.test.mjs
site/scripts/__tests__/skill-counts.test.mjs
site/scripts/__tests__/skills-groups.test.mjs
site/scripts/__tests__/skills-render-index.test.mjs
tests/canonical/test-cutover-no-dangling.sh
tests/canonical/test-deploy-monitor-repurpose.sh
tests/canonical/test-triage-routing.sh
### T22 generate-profile SKILL.md  /generate-profile/SKILL\.md/
tests/canonical/test-dogfood-byte-identity.sh
### T23 site/scripts/skills/ roster files  /curated-roster|skills/groups|skill-counts|render-index/
site/scripts/__tests__/flow-extract-residual.test.mjs
site/scripts/__tests__/gen-reference.test.mjs
site/scripts/__tests__/gen-skills-index.test.mjs
site/scripts/__tests__/gen-skills.test.mjs
site/scripts/__tests__/skill-counts.test.mjs
site/scripts/__tests__/skills-groups.test.mjs
site/scripts/__tests__/skills-render-index.test.mjs
site/scripts/__tests__/sync-docs.test.mjs
### T24 site/scripts/gen-reference.mjs  /gen-reference/
site/scripts/__tests__/gen-reference.test.mjs
site/scripts/__tests__/gen-skills-index.test.mjs
site/scripts/__tests__/gen-skills.test.mjs
site/scripts/__tests__/skill-counts.test.mjs
site/scripts/__tests__/skills-paths.test.mjs
site/scripts/__tests__/skills-render-index.test.mjs
### T25 test-triage-routing.sh  /test-triage-routing/
tests/canonical/test-triage-routing.sh
### T26 build-shortcut-skills.py  /build-shortcut-skills/
site/scripts/__tests__/flow-classify.test.mjs
site/scripts/__tests__/flow-facade.test.mjs
site/scripts/__tests__/flow-graph.test.mjs
tests/canonical/test-catalog-dirs-parity.sh
tests/canonical/test-change-refactor-family-scaffold.sh
tests/canonical/test-create-family-scaffold.sh
tests/canonical/test-deploy-monitor-repurpose.sh
tests/canonical/test-shortcut-builder-invariants.sh
tests/canonical/test-shortcut-engine-contract.sh
### T27 docs/ files  /docs/(aid-methodology|diagram-content-reference|faq|glossary|repository-structure|install)\.md/
site/scripts/__tests__/skills-render-index.test.mjs
site/scripts/__tests__/sync-docs.test.mjs
tests/canonical/test-diagram-content.sh
tests/canonical/test-doc-counts.sh
tests/canonical/test-ps51-compat.sh
tests/windows/Test-AidInstaller.ps1
### T28 examples/brownfield-full-path/README.md  /brownfield-full-path/
### T29 installer-tests.yml  /installer-tests\.yml/
tests/canonical/test-aid-cli-parity.sh
tests/canonical/test-ascii-only.sh
tests/canonical/test-ps51-compat.sh
tests/windows/Test-AidInstaller.ps1
### T30 KB docs (delivery-001)  /knowledge/(architecture|artifact-schemas|backlog|capability-inventory|decisions|domain-glossary|infrastructure|integration-map|module-map|pipeline-contracts|project-structure|tech-debt|test-landscape|INDEX)\.md/
tests/canonical/test-build-kb-index.sh
tests/canonical/test-chat-node-wake.sh
tests/canonical/test-closure-batching.sh
tests/canonical/test-conformance-lane-semantics.sh
tests/canonical/test-deploy-monitor-repurpose.sh
tests/canonical/test-essence-capture.sh
tests/canonical/test-housekeep-classify.sh
tests/canonical/test-kb-freshness-check.sh
tests/canonical/test-kb-html-claims-check.sh
tests/canonical/test-summarize-preflight.sh
tests/canonical/test-teachback-fixtures.sh
### T31 hand-written site pages  /content/docs/(index\.mdx|guides/pipeline\.mdx|get-started/(first-work|lite-path)\.mdx|reference/(artifacts|overview)\.md|guides/maintainer\.mdx)/
### T32 generated site pages  /content/docs/(skills/|reference/(skills|agents)\.md)|skill-flows|skills-manifest/
site/scripts/__tests__/flow-extract-inline.test.mjs
site/scripts/__tests__/gen-reference.test.mjs
site/scripts/__tests__/gen-skills-index.test.mjs
site/scripts/__tests__/gen-skills.test.mjs
site/scripts/__tests__/provenance-render-list.test.mjs
site/scripts/__tests__/skill-node-panel-panel.test.mjs
site/scripts/__tests__/skills-discover.test.mjs
site/scripts/__tests__/skills-paths.test.mjs
site/scripts/__tests__/skills-render-page.test.mjs
site/src/lib/__tests__/skill-node-panel.test.ts
### T33 synced site pages  /concepts/(methodology|faq)\.md|reference/(glossary|repository-structure)\.md/
site/scripts/__tests__/skill-counts.test.mjs
site/scripts/__tests__/sync-docs.test.mjs
### T34 root README.md  /ROOT\}?/README\.md|REPO\}?/README\.md|'README\.md'|"README\.md"/
dashboard/reader/tests/test_reader.py
site/scripts/__tests__/gen-reference.test.mjs
tests/canonical/test-chat-node-manifest.sh
tests/canonical/test-dashboard-manifest.sh
tests/canonical/test-kb-freshness-check.sh
tests/canonical/test-spine-depth-coverage.sh
tests/canonical/test-version-sync.sh
```
### S6b Owners

`Kind`: **reads** = code lines name the file (N = lines); **comment only** = only comment lines name it;
**synthetic** = the name is a fixture the suite builds itself, not the repository file. The owner is the
task that changes the target, so the suite is updated in that task (Q106) when the change breaks it.

| # | Target | Suite | Kind | Owner | Also changed by (dependent) | Note |
|---|---|---|---|---|---|---|
| 1 | T01 rules.md | `tests/canonical/test-aid-cli-parity.sh` | reads (4) | task-002 | -- | Edit: FIX-D8 heading (S5) |
| 2 | T01 rules.md | `tests/canonical/test-aid-migrate.sh` | reads (14) | task-002 | -- |  |
| 3 | T01 rules.md | `tests/canonical/test-aid-status-drift.sh` | synthetic | task-002 | -- |  |
| 4 | T01 rules.md | `tests/canonical/test-connector-skills-structural.sh` | reads (7) | task-002 | -- | ST31-ST38 keep `## Connectors`; also read by task-007 (T06): see Delta |
| 5 | T01 rules.md | `tests/canonical/test-dogfood-byte-identity.sh` | reads (7) | task-002 | -- |  |
| 6 | T01 rules.md | `tests/canonical/test-install-core-primitives.sh` | reads (17) | task-002 | -- | Edit: see S5 |
| 7 | T01 rules.md | `tests/canonical/test-install-provisioning.sh` | reads (2) | task-002 | -- |  |
| 8 | T01 rules.md | `tests/canonical/test-layout-format-guard.sh` | synthetic | task-002 | -- |  |
| 9 | T01 rules.md | `tests/canonical/test-release-install-e2e.sh` | reads (3) | task-002 | -- |  |
| 10 | T01 rules.md | `tests/canonical/test-release.sh` | reads (2) | task-002 | -- | RL02: staged `runtime/rules.md` equals `canonical/aid/rules.md`; copy-reading (no edit) |
| 11 | T01 rules.md | `tests/canonical/test-shared-install.sh` | reads (12) | task-002 | -- | See S5 |
| 12 | T01 rules.md | `tests/canonical/test-shared-layout-sources.sh` | reads (1) | task-002 | -- | Edit: 7 -> 8 bullets (S5) |
| 13 | T01 rules.md | `tests/canonical/test-shared-remove.sh` | reads (13) | task-002 | -- |  |
| 14 | T01 rules.md | `tests/windows/Test-AidInstaller.ps1` | reads (3) | task-002 | -- |  |
| 15 | T01 rules.md | `tests/windows/Test-InstallProvisioning.ps1` | reads (2) | task-002 | -- |  |
| 16 | T02 work-state-template.yml | `dashboard/reader/tests/test_integration.py` | reads (2) | task-003 | -- | Seeds a scratch work from the real template; run by `test-dashboard-reader.sh` in `run-all.sh` |
| 17 | T02 work-state-template.yml | `dashboard/reader/tests/test_reader.py` | comment only | task-003 | -- |  |
| 18 | T02 work-state-template.yml | `tests/canonical/test-connector-consumption-linkage.sh` | reads (3) | task-003 | -- |  |
| 19 | T02 work-state-template.yml | `tests/canonical/test-cutover-no-dangling.sh` | reads (4) | task-003 | -- | CND12 reads the real template (no top-level `triage:` key); no edit expected |
| 20 | T02 work-state-template.yml | `tests/canonical/test-delivery-gate-aggregate.sh` | comment only | task-003 | -- |  |
| 21 | T02 work-state-template.yml | `tests/canonical/test-describe-full-only.sh` | comment only | task-003 | -- |  |
| 22 | T02 work-state-template.yml | `tests/canonical/test-kb-html-claims-check.sh` | comment only | task-003 | -- |  |
| 23 | T02 work-state-template.yml | `tests/canonical/test-state-review-surface.sh` | synthetic | task-003 | -- |  |
| 24 | T02 work-state-template.yml | `tests/canonical/test-task-state-transitions.sh` | comment only | task-003 | -- |  |
| 25 | T02 work-state-template.yml | `tests/canonical/test-ticket-retirement-structural.sh` | reads (2) | task-003 | -- |  |
| 26 | T02 work-state-template.yml | `tests/canonical/test-work-state-template.sh` | reads (12) | task-003 | -- | Edit (task-003 scope) |
| 27 | T02 work-state-template.yml | `tests/canonical/test-writeback-state.sh` | reads (2) | task-003 | -- | Line 1749 copies the real template into a work file and writes it: the new `intent:` block must stay writable |
| 28 | T03 delivery-state-template.yml | `tests/canonical/test-connector-consumption-linkage.sh` | reads (3) | task-003 | -- |  |
| 29 | T03 delivery-state-template.yml | `tests/canonical/test-disjoint-merge.sh` | comment only | task-003 | -- |  |
| 30 | T03 delivery-state-template.yml | `tests/canonical/test-ticket-retirement-structural.sh` | reads (2) | task-003 | -- |  |
| 31 | T03 delivery-state-template.yml | `tests/canonical/test-work-state-template.sh` | reads (4) | task-003 | -- |  |
| 32 | T03 delivery-state-template.yml | `tests/canonical/test-writeback-state.sh` | comment only | task-003 | -- |  |
| 33 | T04 task-state-template.yml | `tests/canonical/test-connector-consumption-linkage.sh` | reads (3) | task-003 | -- |  |
| 34 | T04 task-state-template.yml | `tests/canonical/test-delivery-gate-aggregate.sh` | comment only | task-003 | -- |  |
| 35 | T04 task-state-template.yml | `tests/canonical/test-ticket-retirement-structural.sh` | reads (2) | task-003 | -- |  |
| 36 | T04 task-state-template.yml | `tests/canonical/test-work-state-template.sh` | reads (4) | task-003 | -- |  |
| 37 | T04 task-state-template.yml | `tests/canonical/test-writeback-state.sh` | comment only | task-003 | -- |  |
| 38 | T05 requirements-template.md | `tests/canonical/test-connector-consumption-linkage.sh` | reads (1) | task-003 | -- | CL08f asserts the `**Ticket:**` line: removed |
| 39 | T05 requirements-template.md | `tests/canonical/test-ticket-retirement-structural.sh` | reads (1) | task-003 | -- | T090 asserts the `**Ticket:**` line: removed with a `coverage-accepted-removals.tsv` row |
| 40 | T06 consumption-protocol.md | `tests/canonical/test-connector-consumption-linkage.sh` | reads (4) | task-007 | -- |  |
| 41 | T06 consumption-protocol.md | `tests/canonical/test-connector-skills-structural.sh` | reads (3) | task-007 | -- |  |
| 42 | T06 consumption-protocol.md | `tests/canonical/test-ticket-retirement-structural.sh` | reads (25) | task-007 | -- |  |
| 43 | T07 shortcut-engine.md | `site/scripts/__tests__/flow-classify.test.mjs` | reads (5) | task-007 | -- |  |
| 44 | T07 shortcut-engine.md | `site/scripts/__tests__/flow-compose.test.mjs` | reads (5) | task-007 | -- |  |
| 45 | T07 shortcut-engine.md | `site/scripts/__tests__/flow-engine-core.test.mjs` | reads (9) | task-007 | -- |  |
| 46 | T07 shortcut-engine.md | `site/scripts/__tests__/flow-extract-engine.test.mjs` | reads (2) | task-007 | -- |  |
| 47 | T07 shortcut-engine.md | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | reads (5) | task-007 | -- |  |
| 48 | T07 shortcut-engine.md | `site/scripts/__tests__/flow-graph.test.mjs` | reads (4) | task-007 | -- |  |
| 49 | T07 shortcut-engine.md | `site/scripts/__tests__/gen-reference.test.mjs` | reads (2) | task-007 | -- |  |
| 50 | T07 shortcut-engine.md | `site/scripts/__tests__/provenance-appender.test.mjs` | reads (4) | task-007 | -- |  |
| 51 | T07 shortcut-engine.md | `site/scripts/__tests__/skills-render-index.test.mjs` | reads (1) | task-007 | -- |  |
| 52 | T07 shortcut-engine.md | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | reads (1) | task-007 | -- |  |
| 53 | T07 shortcut-engine.md | `tests/canonical/test-artifact-discipline.sh` | reads (2) | task-007 | -- |  |
| 54 | T07 shortcut-engine.md | `tests/canonical/test-catalog-dirs-parity.sh` | reads (1) | task-007 | -- |  |
| 55 | T07 shortcut-engine.md | `tests/canonical/test-change-refactor-family-scaffold.sh` | comment only | task-007 | -- |  |
| 56 | T07 shortcut-engine.md | `tests/canonical/test-connector-consumption-linkage.sh` | comment only | task-007 | -- |  |
| 57 | T07 shortcut-engine.md | `tests/canonical/test-create-family-scaffold.sh` | reads (2) | task-007 | -- |  |
| 58 | T07 shortcut-engine.md | `tests/canonical/test-deploy-monitor-repurpose.sh` | reads (2) | task-007 | -- |  |
| 59 | T07 shortcut-engine.md | `tests/canonical/test-describe-full-only.sh` | comment only | task-007 | -- |  |
| 60 | T07 shortcut-engine.md | `tests/canonical/test-document-family-scaffold.sh` | comment only | task-007 | -- |  |
| 61 | T07 shortcut-engine.md | `tests/canonical/test-downstream-worktree-entry.sh` | reads (2) | task-007 | -- |  |
| 62 | T07 shortcut-engine.md | `tests/canonical/test-fix-family-scaffold.sh` | comment only | task-007 | -- |  |
| 63 | T07 shortcut-engine.md | `tests/canonical/test-prototype-family-scaffold.sh` | comment only | task-007 | -- |  |
| 64 | T07 shortcut-engine.md | `tests/canonical/test-shortcut-engine-contract.sh` | reads (2) | task-007 | -- |  |
| 65 | T07 shortcut-engine.md | `tests/canonical/test-state-review-surface.sh` | reads (5) | task-007 | -- |  |
| 66 | T07 shortcut-engine.md | `tests/canonical/test-test-experiment-family-scaffold.sh` | comment only | task-007 | -- |  |
| 67 | T07 shortcut-engine.md | `tests/canonical/test-ticket-retirement-structural.sh` | reads (5) | task-007 | -- |  |
| 68 | T07 shortcut-engine.md | `tests/canonical/test-triage-routing.sh` | comment only | task-007 | -- |  |
| 69 | T07 shortcut-engine.md | `tests/canonical/test-work-initiation-gate.sh` | reads (3) | task-007 | -- |  |
| 70 | T08 aid-specify state-initialize.md | `tests/canonical/test-pipeline-status-walkthrough.sh` | reads (2) | task-007 | task-010 (description) |  |
| 71 | T08 aid-specify state-initialize.md | `tests/canonical/test-ticket-retirement-structural.sh` | reads (5) | task-007 | task-010 (description) |  |
| 72 | T09 aid-plan first-run-loop.md | `tests/canonical/test-pipeline-status-walkthrough.sh` | reads (2) | task-007 | task-010 (description) |  |
| 73 | T09 aid-plan first-run-loop.md | `tests/canonical/test-ticket-retirement-structural.sh` | reads (8) | task-007 | task-010 (description) |  |
| 74 | T10 aid-describe state-first-run.md | `tests/canonical/test-describe-full-only.sh` | reads (4) | task-007 | task-009 (triage mention) |  |
| 75 | T10 aid-describe state-first-run.md | `tests/canonical/test-ticket-retirement-structural.sh` | reads (5) | task-007 | task-009 (triage mention) |  |
| 76 | T10 aid-describe state-first-run.md | `tests/canonical/test-work-state-template.sh` | reads (7) | task-007 | task-009 (triage mention) |  |
| 77 | T11 aid-describe SKILL.md | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | reads (2) | task-009 | task-007 (references) |  |
| 78 | T11 aid-describe SKILL.md | `tests/canonical/test-cutover-no-dangling.sh` | comment only | task-009 | task-007 (references) |  |
| 79 | T11 aid-describe SKILL.md | `tests/canonical/test-describe-full-only.sh` | reads (4) | task-009 | task-007 (references) |  |
| 80 | T11 aid-describe SKILL.md | `tests/canonical/test-pipeline-status-walkthrough.sh` | reads (1) | task-009 | task-007 (references) |  |
| 81 | T11 aid-describe SKILL.md | `tests/canonical/test-ticket-retirement-structural.sh` | reads (4) | task-009 | task-007 (references) |  |
| 82 | T11 aid-describe SKILL.md | `tests/canonical/test-triage-routing.sh` | reads (1) | task-009 | task-007 (references) |  |
| 83 | T11 aid-describe SKILL.md | `tests/canonical/test-work-initiation-gate.sh` | reads (3) | task-009 | task-007 (references) |  |
| 84 | T11 aid-describe SKILL.md | `tests/canonical/test-work-state-template.sh` | reads (1) | task-009 | task-007 (references) |  |
| 85 | T12 aid-describe elicitation-engine.md | `tests/canonical/test-describe-full-only.sh` | reads (6) | task-009 | -- |  |
| 86 | T13 aid-update-ticket SKILL.md | `site/scripts/__tests__/flow-extract-residual.test.mjs` | reads (2) | task-007 | -- |  |
| 87 | T13 aid-update-ticket SKILL.md | `site/scripts/__tests__/gen-reference.test.mjs` | reads (1) | task-007 | -- |  |
| 88 | T13 aid-update-ticket SKILL.md | `tests/canonical/test-ticket-retirement-structural.sh` | reads (10) | task-007 | -- |  |
| 89 | T13 aid-update-ticket SKILL.md | `tests/canonical/test-ticket-skills-structural.sh` | reads (25) | task-007 | -- | T54 part enum; T14 folded `description: >` |
| 90 | T14 aid-monitor SKILL.md | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | reads (1) | task-008 | task-010 (description) | Reads the real `aid-monitor` body (D1 corpus) |
| 91 | T14 aid-monitor SKILL.md | `site/scripts/__tests__/gen-reference.test.mjs` | reads (1) | task-008 | task-010 (description) |  |
| 92 | T14 aid-monitor SKILL.md | `site/scripts/__tests__/gen-skills-index.test.mjs` | reads (7) | task-008 | task-010 (description) |  |
| 93 | T14 aid-monitor SKILL.md | `site/scripts/__tests__/skills-catalog.test.mjs` | reads (2) | task-008 | task-010 (description) |  |
| 94 | T14 aid-monitor SKILL.md | `site/scripts/__tests__/skills-groups.test.mjs` | reads (8) | task-008 | task-010 (description) |  |
| 95 | T14 aid-monitor SKILL.md | `site/scripts/__tests__/skills-render-index.test.mjs` | reads (2) | task-008 | task-010 (description) |  |
| 96 | T14 aid-monitor SKILL.md | `tests/canonical/test-catalog-dirs-parity.sh` | comment only | task-008 | task-010 (description) |  |
| 97 | T14 aid-monitor SKILL.md | `tests/canonical/test-deploy-monitor-repurpose.sh` | reads (14) | task-008 | task-010 (description) | DMR01b-DMR03b, ROUTE row |
| 98 | T14 aid-monitor SKILL.md | `tests/canonical/test-document-family-scaffold.sh` | reads (1) | task-008 | task-010 (description) |  |
| 99 | T14 aid-monitor SKILL.md | `tests/canonical/test-ticket-retirement-structural.sh` | reads (10) | task-008 | task-010 (description) |  |
| 100 | T15 aid-monitor state-route.md | `tests/canonical/test-deploy-monitor-repurpose.sh` | reads (7) | task-008 | -- |  |
| 101 | T15 aid-monitor state-route.md | `tests/canonical/test-ticket-retirement-structural.sh` | reads (1) | task-008 | -- |  |
| 102 | T17 self-review-protocol.md | `tests/cost-meter.py` | reads (1) | task-008 | -- |  |
| 103 | T18 aid-orchestrator AGENT.md | `tests/canonical/test-deploy-monitor-repurpose.sh` | reads (1) | task-008 | -- |  |
| 104 | T18 aid-orchestrator AGENT.md | `tests/windows/Test-AidInstaller.ps1` | reads (10) | task-008 | -- |  |
| 105 | T19 .aid/design/ | `tests/canonical/test-shared-install.sh` | synthetic | task-008 | -- |  |
| 106 | T19 .aid/design/ | `tests/canonical/test-shared-remove.sh` | synthetic | task-008 | -- |  |
| 107 | T20 shortcut-catalog.yml | `dashboard/reader/tests/test_shortcut_kind_map_cross_runtime_parity.py` | reads (5) | task-009 | -- |  |
| 108 | T20 shortcut-catalog.yml | `dashboard/reader/tests/test_work003_state_schema.py` | reads (1) | task-009 | -- |  |
| 109 | T20 shortcut-catalog.yml | `site/scripts/__tests__/flow-classify.test.mjs` | reads (2) | task-009 | -- |  |
| 110 | T20 shortcut-catalog.yml | `site/scripts/__tests__/flow-compose.test.mjs` | reads (1) | task-009 | -- |  |
| 111 | T20 shortcut-catalog.yml | `site/scripts/__tests__/gen-reference.test.mjs` | reads (2) | task-009 | -- |  |
| 112 | T20 shortcut-catalog.yml | `site/scripts/__tests__/gen-skills-index.test.mjs` | comment only | task-009 | -- |  |
| 113 | T20 shortcut-catalog.yml | `site/scripts/__tests__/gen-skills.test.mjs` | reads (4) | task-009 | -- |  |
| 114 | T20 shortcut-catalog.yml | `site/scripts/__tests__/skill-counts.test.mjs` | reads (1) | task-009 | -- |  |
| 115 | T20 shortcut-catalog.yml | `site/scripts/__tests__/skills-catalog.test.mjs` | reads (2) | task-009 | -- |  |
| 116 | T20 shortcut-catalog.yml | `site/scripts/__tests__/skills-render-index.test.mjs` | reads (2) | task-009 | -- |  |
| 117 | T20 shortcut-catalog.yml | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | reads (2) | task-009 | -- |  |
| 118 | T20 shortcut-catalog.yml | `site/src/lib/__tests__/skill-node-panel.test.ts` | reads (1) | task-009 | -- |  |
| 119 | T20 shortcut-catalog.yml | `tests/canonical/test-catalog-dirs-parity.sh` | reads (2) | task-009 | -- |  |
| 120 | T20 shortcut-catalog.yml | `tests/canonical/test-change-refactor-family-scaffold.sh` | reads (2) | task-009 | -- |  |
| 121 | T20 shortcut-catalog.yml | `tests/canonical/test-connector-skills-structural.sh` | reads (3) | task-009 | -- |  |
| 122 | T20 shortcut-catalog.yml | `tests/canonical/test-create-family-scaffold.sh` | reads (2) | task-009 | -- |  |
| 123 | T20 shortcut-catalog.yml | `tests/canonical/test-deploy-monitor-repurpose.sh` | reads (2) | task-009 | -- |  |
| 124 | T20 shortcut-catalog.yml | `tests/canonical/test-doc-counts.sh` | reads (1) | task-009 | -- |  |
| 125 | T20 shortcut-catalog.yml | `tests/canonical/test-document-family-scaffold.sh` | reads (2) | task-009 | -- |  |
| 126 | T20 shortcut-catalog.yml | `tests/canonical/test-fix-family-scaffold.sh` | reads (2) | task-009 | -- |  |
| 127 | T20 shortcut-catalog.yml | `tests/canonical/test-prototype-family-scaffold.sh` | reads (2) | task-009 | -- |  |
| 128 | T20 shortcut-catalog.yml | `tests/canonical/test-shortcut-builder-invariants.sh` | reads (4) | task-009 | -- | Comment-only catalog edit; no edit expected |
| 129 | T20 shortcut-catalog.yml | `tests/canonical/test-shortcut-engine-contract.sh` | reads (2) | task-009 | -- |  |
| 130 | T20 shortcut-catalog.yml | `tests/canonical/test-test-experiment-family-scaffold.sh` | reads (2) | task-009 | -- |  |
| 131 | T20 shortcut-catalog.yml | `tests/canonical/test-triage-routing.sh` | reads (4) | task-009 | -- |  |
| 132 | T21 aid-triage/ | `site/scripts/__tests__/flow-classify.test.mjs` | reads (2) | task-009 | task-006 (moves its heuristics out first) |  |
| 133 | T21 aid-triage/ | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | reads (14) | task-009 | task-006 (moves its heuristics out first) |  |
| 134 | T21 aid-triage/ | `site/scripts/__tests__/flow-graph.test.mjs` | reads (1) | task-009 | task-006 (moves its heuristics out first) |  |
| 135 | T21 aid-triage/ | `site/scripts/__tests__/gen-reference.test.mjs` | reads (1) | task-009 | task-006 (moves its heuristics out first) |  |
| 136 | T21 aid-triage/ | `site/scripts/__tests__/gen-skills-index.test.mjs` | reads (3) | task-009 | task-006 (moves its heuristics out first) |  |
| 137 | T21 aid-triage/ | `site/scripts/__tests__/skill-counts.test.mjs` | reads (2) | task-009 | task-006 (moves its heuristics out first) |  |
| 138 | T21 aid-triage/ | `site/scripts/__tests__/skills-groups.test.mjs` | reads (8) | task-009 | task-006 (moves its heuristics out first) |  |
| 139 | T21 aid-triage/ | `site/scripts/__tests__/skills-render-index.test.mjs` | reads (4) | task-009 | task-006 (moves its heuristics out first) |  |
| 140 | T21 aid-triage/ | `tests/canonical/test-cutover-no-dangling.sh` | comment only | task-009 | task-006 (moves its heuristics out first) |  |
| 141 | T21 aid-triage/ | `tests/canonical/test-deploy-monitor-repurpose.sh` | reads (8) | task-009 | task-006 (moves its heuristics out first) |  |
| 142 | T21 aid-triage/ | `tests/canonical/test-triage-routing.sh` | reads (5) | task-009 | task-006 (moves its heuristics out first) | Deleted |
| 143 | T22 generate-profile SKILL.md | `tests/canonical/test-dogfood-byte-identity.sh` | reads (1) | task-009 | -- | DBI-SURV: the file survives the resync; copy-reading |
| 144 | T23 site/scripts/skills/ roster files | `site/scripts/__tests__/flow-extract-residual.test.mjs` | comment only | task-009 | task-006 (adds `aid-orchestrate` to the roster) |  |
| 145 | T23 site/scripts/skills/ roster files | `site/scripts/__tests__/gen-reference.test.mjs` | reads (2) | task-009 | task-006 (adds `aid-orchestrate` to the roster) |  |
| 146 | T23 site/scripts/skills/ roster files | `site/scripts/__tests__/gen-skills-index.test.mjs` | reads (1) | task-009 | task-006 (adds `aid-orchestrate` to the roster) |  |
| 147 | T23 site/scripts/skills/ roster files | `site/scripts/__tests__/gen-skills.test.mjs` | reads (1) | task-009 | task-006 (adds `aid-orchestrate` to the roster) |  |
| 148 | T23 site/scripts/skills/ roster files | `site/scripts/__tests__/skill-counts.test.mjs` | reads (4) | task-009 | task-006 (adds `aid-orchestrate` to the roster) |  |
| 149 | T23 site/scripts/skills/ roster files | `site/scripts/__tests__/skills-groups.test.mjs` | reads (1) | task-009 | task-006 (adds `aid-orchestrate` to the roster) |  |
| 150 | T23 site/scripts/skills/ roster files | `site/scripts/__tests__/skills-render-index.test.mjs` | reads (6) | task-009 | task-006 (adds `aid-orchestrate` to the roster) |  |
| 151 | T23 site/scripts/skills/ roster files | `site/scripts/__tests__/sync-docs.test.mjs` | comment only | task-009 | task-006 (adds `aid-orchestrate` to the roster) |  |
| 152 | T24 site/scripts/gen-reference.mjs | `site/scripts/__tests__/gen-reference.test.mjs` | reads (13) | task-009 | task-008 (the hard-coded agent count) | Also asserts 9 agent sections (task-008, S7) |
| 153 | T24 site/scripts/gen-reference.mjs | `site/scripts/__tests__/gen-skills-index.test.mjs` | comment only | task-009 | task-008 (the hard-coded agent count) |  |
| 154 | T24 site/scripts/gen-reference.mjs | `site/scripts/__tests__/gen-skills.test.mjs` | reads (3) | task-009 | task-008 (the hard-coded agent count) |  |
| 155 | T24 site/scripts/gen-reference.mjs | `site/scripts/__tests__/skill-counts.test.mjs` | reads (3) | task-009 | task-008 (the hard-coded agent count) |  |
| 156 | T24 site/scripts/gen-reference.mjs | `site/scripts/__tests__/skills-paths.test.mjs` | comment only | task-009 | task-008 (the hard-coded agent count) |  |
| 157 | T24 site/scripts/gen-reference.mjs | `site/scripts/__tests__/skills-render-index.test.mjs` | comment only | task-009 | task-008 (the hard-coded agent count) |  |
| 158 | T25 test-triage-routing.sh | `tests/canonical/test-triage-routing.sh` | comment only | task-009 | -- |  |
| 159 | T26 build-shortcut-skills.py | `site/scripts/__tests__/flow-classify.test.mjs` | reads (2) | task-010 | -- |  |
| 160 | T26 build-shortcut-skills.py | `site/scripts/__tests__/flow-facade.test.mjs` | reads (1) | task-010 | -- |  |
| 161 | T26 build-shortcut-skills.py | `site/scripts/__tests__/flow-graph.test.mjs` | reads (3) | task-010 | -- |  |
| 162 | T26 build-shortcut-skills.py | `tests/canonical/test-catalog-dirs-parity.sh` | reads (4) | task-010 | -- |  |
| 163 | T26 build-shortcut-skills.py | `tests/canonical/test-change-refactor-family-scaffold.sh` | comment only | task-010 | -- |  |
| 164 | T26 build-shortcut-skills.py | `tests/canonical/test-create-family-scaffold.sh` | comment only | task-010 | -- |  |
| 165 | T26 build-shortcut-skills.py | `tests/canonical/test-deploy-monitor-repurpose.sh` | reads (1) | task-010 | -- | Only the GENERATED marker constant (line 339); no edit expected |
| 166 | T26 build-shortcut-skills.py | `tests/canonical/test-shortcut-builder-invariants.sh` | reads (1) | task-010 | -- | SBI05 (edit if the template change moves its counts) |
| 167 | T26 build-shortcut-skills.py | `tests/canonical/test-shortcut-engine-contract.sh` | comment only | task-010 | -- |  |
| 168 | T27 docs/ files | `site/scripts/__tests__/skills-render-index.test.mjs` | reads (1) | task-011 | task-006, task-008, task-009 (count phrases only) |  |
| 169 | T27 docs/ files | `site/scripts/__tests__/sync-docs.test.mjs` | reads (10) | task-011 | task-006, task-008, task-009 (count phrases only) | The sync manifest of the four synced docs |
| 170 | T27 docs/ files | `tests/canonical/test-diagram-content.sh` | comment only | task-011 | task-006, task-008, task-009 (count phrases only) |  |
| 171 | T27 docs/ files | `tests/canonical/test-doc-counts.sh` | reads (16) | task-011 | task-006, task-008, task-009 (count phrases only) | Count phrases (S7) |
| 172 | T27 docs/ files | `tests/canonical/test-ps51-compat.sh` | comment only | task-011 | task-006, task-008, task-009 (count phrases only) |  |
| 173 | T27 docs/ files | `tests/windows/Test-AidInstaller.ps1` | comment only | task-011 | task-006, task-008, task-009 (count phrases only) |  |
| 174 | T29 installer-tests.yml | `tests/canonical/test-aid-cli-parity.sh` | comment only | task-015 | -- | Comment only: the suite does not read `installer-tests.yml` (see Delta) |
| 175 | T29 installer-tests.yml | `tests/canonical/test-ascii-only.sh` | comment only | task-015 | -- | Comment only: scans shipped scripts, not the workflow (see Delta) |
| 176 | T29 installer-tests.yml | `tests/canonical/test-ps51-compat.sh` | comment only | task-015 | -- | Comment only (see Delta) |
| 177 | T29 installer-tests.yml | `tests/windows/Test-AidInstaller.ps1` | comment only | task-015 | -- | Comment only (see Delta) |
| 178 | T30 KB docs (delivery-001) | `tests/canonical/test-build-kb-index.sh` | synthetic | task-013 | -- | Names a KB file only inside its own fixture KB; the repository document is not read (no edit expected) |
| 179 | T30 KB docs (delivery-001) | `tests/canonical/test-chat-node-wake.sh` | reads (1) | task-012 | -- | Reads `decisions.md` § D31 up to the next `\n## `; a new decision must not split D31 |
| 180 | T30 KB docs (delivery-001) | `tests/canonical/test-closure-batching.sh` | synthetic | task-013 | -- | Names a KB file only inside its own fixture KB; the repository document is not read (no edit expected) |
| 181 | T30 KB docs (delivery-001) | `tests/canonical/test-conformance-lane-semantics.sh` | synthetic | task-013 | -- | Names a KB file only inside its own fixture KB; the repository document is not read (no edit expected) |
| 182 | T30 KB docs (delivery-001) | `tests/canonical/test-deploy-monitor-repurpose.sh` | reads (1) | task-013 | -- | DMR05c reads `pipeline-contracts.md` L10 |
| 183 | T30 KB docs (delivery-001) | `tests/canonical/test-essence-capture.sh` | synthetic | task-013 | -- | Names a KB file only inside its own fixture KB; the repository document is not read (no edit expected) |
| 184 | T30 KB docs (delivery-001) | `tests/canonical/test-housekeep-classify.sh` | synthetic | task-013 | -- | Names a KB file only inside its own fixture KB; the repository document is not read (no edit expected) |
| 185 | T30 KB docs (delivery-001) | `tests/canonical/test-kb-freshness-check.sh` | synthetic | task-018 | -- | Names a KB file only inside its own fixture KB; the repository document is not read (no edit expected) |
| 186 | T30 KB docs (delivery-001) | `tests/canonical/test-kb-html-claims-check.sh` | synthetic | task-013 | -- | Names a KB file only inside its own fixture KB; the repository document is not read (no edit expected) |
| 187 | T30 KB docs (delivery-001) | `tests/canonical/test-summarize-preflight.sh` | synthetic | task-013 | -- | Names a KB file only inside its own fixture KB; the repository document is not read (no edit expected) |
| 188 | T30 KB docs (delivery-001) | `tests/canonical/test-teachback-fixtures.sh` | synthetic | task-013 | -- | Names a KB file only inside its own fixture KB; the repository document is not read (no edit expected) |
| 189 | T32 generated site pages | `site/scripts/__tests__/flow-extract-inline.test.mjs` | comment only | task-007 | task-006, task-008, task-009, task-010 regenerate them too (one dependent chain) |  |
| 190 | T32 generated site pages | `site/scripts/__tests__/gen-reference.test.mjs` | reads (2) | task-007 | task-006, task-008, task-009, task-010 regenerate them too (one dependent chain) |  |
| 191 | T32 generated site pages | `site/scripts/__tests__/gen-skills-index.test.mjs` | reads (4) | task-007 | task-006, task-008, task-009, task-010 regenerate them too (one dependent chain) |  |
| 192 | T32 generated site pages | `site/scripts/__tests__/gen-skills.test.mjs` | reads (14) | task-007 | task-006, task-008, task-009, task-010 regenerate them too (one dependent chain) |  |
| 193 | T32 generated site pages | `site/scripts/__tests__/provenance-render-list.test.mjs` | comment only | task-007 | task-006, task-008, task-009, task-010 regenerate them too (one dependent chain) |  |
| 194 | T32 generated site pages | `site/scripts/__tests__/skill-node-panel-panel.test.mjs` | comment only | task-007 | task-006, task-008, task-009, task-010 regenerate them too (one dependent chain) |  |
| 195 | T32 generated site pages | `site/scripts/__tests__/skills-discover.test.mjs` | reads (4) | task-007 | task-006, task-008, task-009, task-010 regenerate them too (one dependent chain) |  |
| 196 | T32 generated site pages | `site/scripts/__tests__/skills-paths.test.mjs` | reads (4) | task-007 | task-006, task-008, task-009, task-010 regenerate them too (one dependent chain) |  |
| 197 | T32 generated site pages | `site/scripts/__tests__/skills-render-page.test.mjs` | reads (1) | task-007 | task-006, task-008, task-009, task-010 regenerate them too (one dependent chain) |  |
| 198 | T32 generated site pages | `site/src/lib/__tests__/skill-node-panel.test.ts` | reads (2) | task-007 | task-006, task-008, task-009, task-010 regenerate them too (one dependent chain) |  |
| 199 | T33 synced site pages | `site/scripts/__tests__/skill-counts.test.mjs` | reads (through `join(DOCS, ...)`) | task-011 | task-006, task-009 (count phrases in the `docs/` sources) | `CLAIM_PAGES` holds the four synced pages (S7c); the path match itself is in comments |
| 200 | T33 synced site pages | `site/scripts/__tests__/sync-docs.test.mjs` | reads (4) | task-011 | task-006, task-009 (count phrases in the `docs/` sources) |  |
| 201 | T34 root README.md | `dashboard/reader/tests/test_reader.py` | synthetic | task-011 | -- |  |
| 202 | T34 root README.md | `site/scripts/__tests__/gen-reference.test.mjs` | synthetic | task-011 | -- |  |
| 203 | T34 root README.md | `tests/canonical/test-chat-node-manifest.sh` | synthetic | task-011 | -- |  |
| 204 | T34 root README.md | `tests/canonical/test-dashboard-manifest.sh` | synthetic | task-011 | -- |  |
| 205 | T34 root README.md | `tests/canonical/test-kb-freshness-check.sh` | synthetic | task-011 | -- |  |
| 206 | T34 root README.md | `tests/canonical/test-spine-depth-coverage.sh` | synthetic | task-011 | -- |  |
| 207 | T34 root README.md | `tests/canonical/test-version-sync.sh` | reads (1) | task-011 | -- | Reads the root README's version strings; no edit expected |

207 hit rows over 90 distinct suites, 0 empty owner cells. T28 (examples), T31 (hand-written site pages, by path) and T16 (`agent-dispatch-tiering.md`) have no suite hit; T31's pages are read by `skill-counts.test.mjs` through `join(DOCS, ...)` (S7).

### S6c Tree walkers

Suites that walk `canonical/skills/` or `canonical/agents/` as a whole see every skill or agent that is
added or removed (task-006 adds `aid-orchestrate`, task-008 removes `aid-orchestrator`, task-009 removes
`aid-triage`) and every description (task-010). Owner: task-006, the first task whose change they see;
task-008, task-009 and task-010 re-run them in that order (one dependent chain, no edit expected unless
noted).

```bash
SUITES=(tests/canonical/test-*.sh tests/canonical/*.ps1 tests/canonical/*.mjs tests/windows/ tests/lib/
        tests/run-all.sh tests/coverage-parity.sh tests/cost-meter.py
        site/scripts/__tests__/ site/src/lib/__tests__/ site/src/data/__tests__/
        dashboard/reader/tests/ dashboard/server/tests/ ':!dashboard/**/fixtures/**')
git grep -l -E -e 'find [^|]*canonical/(skills|agents)' -e 'SKILLS_ROOT' -e 'CANONICAL_SKILLS_DIR' -e '(SKILLS|AGENTS)_DIR\b' \
  -e 'canonical/(skills|agents)/\*' -e "'canonical', 'skills'" -e '"canonical" / "skills"' \
  -e 'skills_match "\$REPO/canonical/skills"' -e '\{REPO_ROOT\}/canonical/(skills|agents)"' -e 'canonical/skills -> ' \
  581a4335 -- "${SUITES[@]}"
```
```text
581a4335:dashboard/reader/tests/test_feature009.py
581a4335:site/scripts/__tests__/flow-facade.test.mjs
581a4335:site/scripts/__tests__/flow-graph-doorways.test.mjs
581a4335:site/scripts/__tests__/gen-reference.test.mjs
581a4335:site/scripts/__tests__/gen-skills-index.test.mjs
581a4335:site/scripts/__tests__/gen-skills.test.mjs
581a4335:site/scripts/__tests__/provenance-verify.test.mjs
581a4335:site/scripts/__tests__/provenance.test.mjs
581a4335:site/scripts/__tests__/skill-counts.test.mjs
581a4335:site/scripts/__tests__/skills-body.test.mjs
581a4335:site/scripts/__tests__/skills-discover.test.mjs
581a4335:site/scripts/__tests__/skills-frontmatter.test.mjs
581a4335:site/scripts/__tests__/skills-groups.test.mjs
581a4335:site/scripts/__tests__/skills-paths.test.mjs
581a4335:site/scripts/__tests__/skills-render-index.test.mjs
581a4335:site/scripts/__tests__/skills-render-value.test.mjs
581a4335:site/scripts/__tests__/skills-summary.test.mjs
581a4335:site/src/lib/__tests__/feature-006-head-gate.test.ts
581a4335:site/src/lib/__tests__/skill-node-panel.test.ts
581a4335:tests/canonical/test-aid-migrate.sh
581a4335:tests/canonical/test-artifact-discipline.sh
581a4335:tests/canonical/test-catalog-dirs-parity.sh
581a4335:tests/canonical/test-change-refactor-family-scaffold.sh
581a4335:tests/canonical/test-create-family-scaffold.sh
581a4335:tests/canonical/test-criterion-oracles.sh
581a4335:tests/canonical/test-deploy-monitor-repurpose.sh
581a4335:tests/canonical/test-doc-counts.sh
581a4335:tests/canonical/test-document-family-scaffold.sh
581a4335:tests/canonical/test-dogfood-byte-identity.sh
581a4335:tests/canonical/test-fix-family-scaffold.sh
581a4335:tests/canonical/test-prototype-family-scaffold.sh
581a4335:tests/canonical/test-release.sh
581a4335:tests/canonical/test-shared-install.sh
581a4335:tests/canonical/test-shared-layout-sources.sh
581a4335:tests/canonical/test-shortcut-builder-invariants.sh
581a4335:tests/canonical/test-test-experiment-family-scaffold.sh
581a4335:tests/cost-meter.py
```
| # | Suite | Owner | Note |
|---|---|---|---|
| 1 | `dashboard/reader/tests/test_feature009.py` | task-006 | Re-run only |
| 2 | `site/scripts/__tests__/flow-facade.test.mjs` | task-006 | Re-run only |
| 3 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-006 | Re-run only |
| 4 | `site/scripts/__tests__/gen-reference.test.mjs` | task-006 | Agent sections equal `canonical/agents/` and are 9 (S7): task-008 edits it |
| 5 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-006 | Re-run only |
| 6 | `site/scripts/__tests__/gen-skills.test.mjs` | task-006 | Re-run only |
| 7 | `site/scripts/__tests__/provenance-verify.test.mjs` | task-006 | Re-run only |
| 8 | `site/scripts/__tests__/provenance.test.mjs` | task-006 | Re-run only |
| 9 | `site/scripts/__tests__/skill-counts.test.mjs` | task-006 | Derives the counts (S7); task-009 edits it |
| 10 | `site/scripts/__tests__/skills-body.test.mjs` | task-006 | Re-run only |
| 11 | `site/scripts/__tests__/skills-discover.test.mjs` | task-006 | Re-run only |
| 12 | `site/scripts/__tests__/skills-frontmatter.test.mjs` | task-006 | Re-run only |
| 13 | `site/scripts/__tests__/skills-groups.test.mjs` | task-006 | Re-run only |
| 14 | `site/scripts/__tests__/skills-paths.test.mjs` | task-006 | Re-run only |
| 15 | `site/scripts/__tests__/skills-render-index.test.mjs` | task-006 | Re-run only |
| 16 | `site/scripts/__tests__/skills-render-value.test.mjs` | task-006 | Corpus sweep of folded descriptions (S8) |
| 17 | `site/scripts/__tests__/skills-summary.test.mjs` | task-006 | Corpus sweep: the summary of every `description:` (S8) |
| 18 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | task-006 | Re-run only |
| 19 | `site/src/lib/__tests__/skill-node-panel.test.ts` | task-006 | Re-run only |
| 20 | `tests/canonical/test-aid-migrate.sh` | task-006 | Installed skills equal `canonical/skills/`; copy-reading |
| 21 | `tests/canonical/test-artifact-discipline.sh` | task-006 | Re-run only |
| 22 | `tests/canonical/test-catalog-dirs-parity.sh` | task-006 | Generated doorways need a catalog row; `aid-orchestrate` is neither, so it passes |
| 23 | `tests/canonical/test-change-refactor-family-scaffold.sh` | task-006 | Re-run only |
| 24 | `tests/canonical/test-create-family-scaffold.sh` | task-006 | Re-run only |
| 25 | `tests/canonical/test-criterion-oracles.sh` | task-006 | Re-run only |
| 26 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-006 | DMR36 standalone list: task-006 adds `aid-orchestrate`, task-009 drops `aid-triage` |
| 27 | `tests/canonical/test-doc-counts.sh` | task-006 | Derives the skill and agent counts (S7) |
| 28 | `tests/canonical/test-document-family-scaffold.sh` | task-006 | Re-run only |
| 29 | `tests/canonical/test-dogfood-byte-identity.sh` | task-006 | `canonical/skills` equals `.agents/skills` and `.claude/skills`; copy-reading (stale until the resync, so it runs in the scratch half) |
| 30 | `tests/canonical/test-fix-family-scaffold.sh` | task-006 | Re-run only |
| 31 | `tests/canonical/test-prototype-family-scaffold.sh` | task-006 | Re-run only |
| 32 | `tests/canonical/test-release.sh` | task-006 | RL staged skills equal `canonical/skills/`; copy-reading |
| 33 | `tests/canonical/test-shared-install.sh` | task-006 | AC-3 installed skills equal `canonical/skills/`; copy-reading |
| 34 | `tests/canonical/test-shared-layout-sources.sh` | task-006 | AC-6 walks every `SKILL.md`: `allowed-tools:` without commas, a `Bash` entry only with the "Bash Shell Terminal" phrase, no `context:` or `agent:` key. Binds the new `aid-orchestrate/SKILL.md` |
| 35 | `tests/canonical/test-shortcut-builder-invariants.sh` | task-006 | SBI on a copied tree; task-010's template change |
| 36 | `tests/canonical/test-test-experiment-family-scaffold.sh` | task-006 | Re-run only |
| 37 | `tests/cost-meter.py` | task-006 | Not run by `run-all.sh`; feeds the cost baseline re-recorded at the gate |

## S7 Count checks

Two suites derive counts from the trees; one more hard-codes the agent count.

### S7a The derivations

```bash
git grep -n -E -e 'find canonical/(skills|agents) -mindepth 1 -maxdepth 1' -e 'deriveSkillCounts\(REPO_ROOT\)' \
  -e '(agentDirs|sections)\)\.toHaveLength\(9\)' 581a4335 -- tests/canonical/ site/scripts/__tests__/
```
```text
581a4335:site/scripts/__tests__/gen-reference.test.mjs:251:    expect(agentDirs).toHaveLength(9);
581a4335:site/scripts/__tests__/gen-reference.test.mjs:255:    expect(sections).toHaveLength(9);
581a4335:site/scripts/__tests__/skill-counts.test.mjs:25:const counts = deriveSkillCounts(REPO_ROOT);
581a4335:tests/canonical/test-doc-counts.sh:44:SKILLS=$(find canonical/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
581a4335:tests/canonical/test-doc-counts.sh:45:AGENTS=$(find canonical/agents -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
```
At the base: 112 skill directories, 9 agent directories, 94 catalog rows (60 `repurpose`), 34 emitting
shortcuts, 21 curated skills of which 18 have no catalog row (`curatedOnly`), 19 classic. Measured with the
suites' own code: `find` as in `test-doc-counts.sh`, and `deriveSkillCounts()` from
`site/scripts/skills/skill-counts.mjs` run under `node` at the base.

**The arithmetic of this delivery.** task-006 adds `aid-orchestrate` (a curated skill with no catalog
row): skills 112 -> 113, curated-only 18 -> 19. task-008 deletes `aid-orchestrator`: agents 9 -> 8.
task-009 deletes `aid-triage` (curated, no row): skills 113 -> 112, curated-only 19 -> 18. So the skill
numbers end where they started, but each of task-006 and task-009 must re-sync them for its own test step
(Q134 D5); the agent number changes for good.

| # | Suite | Lines | Owner | What it asserts, and the edit |
|---|---|---|---|---|
| 1 | `tests/canonical/test-doc-counts.sh` | 44, 45 | task-006 | DC02 needles `${SKILLS} skills`, `${AGENTS} agents`, `${SKILLS} skill definitions`, `${AGENTS} agent definitions`, `${SKILLS} skill directories`, `${SKILLS} skills total`, ``${SKILLS} `aid-`-prefixed skill``, ``${AGENTS} `aid-`-prefixed agent`` (plus row and shortcut needles that do not move). Derived, so the suite itself needs no edit; the phrases in S7b change in task-006 (skills +1), task-008 (agents -1) and task-009 (skills -1) |
| 2 | `site/scripts/__tests__/skill-counts.test.mjs` | 25 | task-006 | `CLAIM_PATTERNS` on the seven `CLAIM_PAGES` (S7c) against the derivation; "classic is curated minus exactly the router and the Q&A alias" (`curated - classic == 2`, `curatedNames` contains `aid-triage`). task-006 re-syncs the S7c numbers; task-009 re-syncs them back and edits the `aid-triage` assertions (line 63) and `NON_CLASSIC_CURATED` in `site/scripts/skills/skill-counts.mjs` |
| 3 | `site/scripts/__tests__/gen-reference.test.mjs` | 251, 255 | task-008 | "exactly 9 agent sections": `toHaveLength(9)` twice -> 8, with the regenerated `reference/agents.md` |

### S7b The `test-doc-counts.sh` phrases that move

```bash
git grep -n -o -F -e '112 skills' -e '9 agents' -e '112 skill definitions' -e '9 agent definitions' \
  -e '112 skill directories' -e '112 `aid-`-prefixed skill' -e '9 `aid-`-prefixed agent' 581a4335 -- \
  README.md docs/repository-structure.md docs/aid-methodology.md docs/glossary.md docs/diagram-content-reference.md docs/install.md
```
```text
581a4335:README.md:209:112 skills
581a4335:README.md:268:9 agents
581a4335:docs/aid-methodology.md:78:112 skill directories
581a4335:docs/aid-methodology.md:100:112 skill directories
581a4335:docs/aid-methodology.md:100:9 agents
581a4335:docs/aid-methodology.md:875:9 agents
581a4335:docs/diagram-content-reference.md:24:112 skills
581a4335:docs/diagram-content-reference.md:28:9 agents
581a4335:docs/diagram-content-reference.md:105:112 skills
581a4335:docs/diagram-content-reference.md:106:9 agents
581a4335:docs/diagram-content-reference.md:136:9 agents
581a4335:docs/glossary.md:9:112 skills
581a4335:docs/install.md:442:112 `aid-`-prefixed skill
581a4335:docs/install.md:470:9 `aid-`-prefixed agent
581a4335:docs/repository-structure.md:22:112 skill definitions
581a4335:docs/repository-structure.md:23:9 agent definitions
581a4335:docs/repository-structure.md:77:112 skill definitions
581a4335:docs/repository-structure.md:78:9 agent definitions
```
| # | File | Line | Phrase | Owner | Note |
|---|---|---|---|---|---|
| 1 | `README.md` | 209 | `112 skills` | task-006 | Skills 112 -> 113 in task-006, back to 112 in task-009 |
| 2 | `README.md` | 268 | `9 agents` | task-008 | Agents 9 -> 8 (for good) |
| 3 | `docs/aid-methodology.md` | 78 | `112 skill directories` | task-006 | Skills 112 -> 113 in task-006, back to 112 in task-009 |
| 4 | `docs/aid-methodology.md` | 100 | `112 skill directories` | task-006 | Skills 112 -> 113 in task-006, back to 112 in task-009 |
| 5 | `docs/aid-methodology.md` | 100 | `9 agents` | task-008 | Agents 9 -> 8 (for good) |
| 6 | `docs/aid-methodology.md` | 875 | `9 agents` | task-008 | Agents 9 -> 8 (for good) |
| 7 | `docs/diagram-content-reference.md` | 24 | `112 skills` | task-006 | Skills 112 -> 113 in task-006, back to 112 in task-009 |
| 8 | `docs/diagram-content-reference.md` | 28 | `9 agents` | task-008 | Agents 9 -> 8 (for good) |
| 9 | `docs/diagram-content-reference.md` | 105 | `112 skills` | task-006 | Skills 112 -> 113 in task-006, back to 112 in task-009 |
| 10 | `docs/diagram-content-reference.md` | 106 | `9 agents` | task-008 | Agents 9 -> 8 (for good) |
| 11 | `docs/diagram-content-reference.md` | 136 | `9 agents` | task-008 | Agents 9 -> 8 (for good) |
| 12 | `docs/glossary.md` | 9 | `112 skills` | task-006 | Skills 112 -> 113 in task-006, back to 112 in task-009 |
| 13 | `docs/install.md` | 442 | `` 112 `aid-`-prefixed skill `` | task-006 | Skills 112 -> 113 in task-006, back to 112 in task-009; `docs/install.md` is on no spec list (see Delta) |
| 14 | `docs/install.md` | 470 | `` 9 `aid-`-prefixed agent `` | task-008 | Agents 9 -> 8 (for good); `docs/install.md` is on no spec list (see Delta) |
| 15 | `docs/repository-structure.md` | 22 | `112 skill definitions` | task-006 | Skills 112 -> 113 in task-006, back to 112 in task-009 |
| 16 | `docs/repository-structure.md` | 23 | `9 agent definitions` | task-008 | Agents 9 -> 8 (for good) |
| 17 | `docs/repository-structure.md` | 77 | `112 skill definitions` | task-006 | Skills 112 -> 113 in task-006, back to 112 in task-009 |
| 18 | `docs/repository-structure.md` | 78 | `9 agent definitions` | task-008 | Agents 9 -> 8 (for good) |

(`112 skills` also matches inside `112 skills total` at `docs/glossary.md` line 9; the needle is a
substring match, as in the suite.)

### S7c The `skill-counts.test.mjs` claims that move

```bash
git grep -n -o -E '\b(112|18) (AID )?(skills|skill directories|skill definitions|curated)\b' 581a4335 -- \
  site/src/content/docs/index.mdx site/src/content/docs/reference/overview.md site/src/content/docs/reference/glossary.md \
  site/src/content/docs/reference/repository-structure.md site/src/content/docs/concepts/methodology.md \
  site/src/content/docs/concepts/faq.md site/src/content/docs/guides/maintainer.mdx
```
```text
581a4335:site/src/content/docs/concepts/methodology.md:82:112 skill directories
581a4335:site/src/content/docs/concepts/methodology.md:104:112 skill directories
581a4335:site/src/content/docs/concepts/methodology.md:104:18 curated
581a4335:site/src/content/docs/concepts/methodology.md:106:18 curated
581a4335:site/src/content/docs/guides/maintainer.mdx:237:112 skills
581a4335:site/src/content/docs/index.mdx:76:112 skills
581a4335:site/src/content/docs/index.mdx:76:18 curated
581a4335:site/src/content/docs/index.mdx:92:112 skills
581a4335:site/src/content/docs/index.mdx:92:18 curated
581a4335:site/src/content/docs/reference/glossary.md:13:112 skills
581a4335:site/src/content/docs/reference/glossary.md:13:18 curated
581a4335:site/src/content/docs/reference/glossary.md:58:18 curated
581a4335:site/src/content/docs/reference/overview.md:16:112 AID skills
581a4335:site/src/content/docs/reference/overview.md:16:18 curated
581a4335:site/src/content/docs/reference/repository-structure.md:26:112 skill definitions
581a4335:site/src/content/docs/reference/repository-structure.md:26:18 curated
581a4335:site/src/content/docs/reference/repository-structure.md:81:112 skill definitions
581a4335:site/src/content/docs/reference/repository-structure.md:81:18 curated
```
| # | File | Line | Claim | Class (S10) | Owner | Note |
|---|---|---|---|---|---|---|
| 1 | `site/src/content/docs/concepts/methodology.md` | 82 | `112 skill directories` | synced (sync-docs.mjs) | task-006 | Edit the source `docs/aid-methodology.md`, then `sync:docs`; +1 in task-006, -1 in task-009 |
| 2 | `site/src/content/docs/concepts/methodology.md` | 104 | `112 skill directories` | synced (sync-docs.mjs) | task-006 | Edit the source `docs/aid-methodology.md`, then `sync:docs`; +1 in task-006, -1 in task-009 |
| 3 | `site/src/content/docs/concepts/methodology.md` | 104 | `18 curated` | synced (sync-docs.mjs) | task-006 | Edit the source `docs/aid-methodology.md`, then `sync:docs`; +1 in task-006, -1 in task-009 |
| 4 | `site/src/content/docs/concepts/methodology.md` | 106 | `18 curated` | synced (sync-docs.mjs) | task-006 | Edit the source `docs/aid-methodology.md`, then `sync:docs`; +1 in task-006, -1 in task-009 |
| 5 | `site/src/content/docs/guides/maintainer.mdx` | 237 | `112 skills` | hand-written (page) | task-006 | Edit the page; +1 in task-006, -1 in task-009; hand-written claim page outside `test-doc-counts.sh` (see Delta) |
| 6 | `site/src/content/docs/index.mdx` | 76 | `112 skills` | hand-written (page) | task-006 | Edit the page; +1 in task-006, -1 in task-009; hand-written claim page outside `test-doc-counts.sh` (see Delta) |
| 7 | `site/src/content/docs/index.mdx` | 76 | `18 curated` | hand-written (page) | task-006 | Edit the page; +1 in task-006, -1 in task-009; hand-written claim page outside `test-doc-counts.sh` (see Delta) |
| 8 | `site/src/content/docs/index.mdx` | 92 | `112 skills` | hand-written (page) | task-006 | Edit the page; +1 in task-006, -1 in task-009; hand-written claim page outside `test-doc-counts.sh` (see Delta) |
| 9 | `site/src/content/docs/index.mdx` | 92 | `18 curated` | hand-written (page) | task-006 | Edit the page; +1 in task-006, -1 in task-009; hand-written claim page outside `test-doc-counts.sh` (see Delta) |
| 10 | `site/src/content/docs/reference/glossary.md` | 13 | `112 skills` | synced (sync-docs.mjs) | task-006 | Edit the source `docs/glossary.md`, then `sync:docs`; +1 in task-006, -1 in task-009 |
| 11 | `site/src/content/docs/reference/glossary.md` | 13 | `18 curated` | synced (sync-docs.mjs) | task-006 | Edit the source `docs/glossary.md`, then `sync:docs`; +1 in task-006, -1 in task-009 |
| 12 | `site/src/content/docs/reference/glossary.md` | 58 | `18 curated` | synced (sync-docs.mjs) | task-006 | Edit the source `docs/glossary.md`, then `sync:docs`; +1 in task-006, -1 in task-009 |
| 13 | `site/src/content/docs/reference/overview.md` | 16 | `112 AID skills` | hand-written (page) | task-006 | Edit the page; +1 in task-006, -1 in task-009; hand-written claim page outside `test-doc-counts.sh` (see Delta) |
| 14 | `site/src/content/docs/reference/overview.md` | 16 | `18 curated` | hand-written (page) | task-006 | Edit the page; +1 in task-006, -1 in task-009; hand-written claim page outside `test-doc-counts.sh` (see Delta) |
| 15 | `site/src/content/docs/reference/repository-structure.md` | 26 | `112 skill definitions` | synced (sync-docs.mjs) | task-006 | Edit the source `docs/repository-structure.md`, then `sync:docs`; +1 in task-006, -1 in task-009 |
| 16 | `site/src/content/docs/reference/repository-structure.md` | 26 | `18 curated` | synced (sync-docs.mjs) | task-006 | Edit the source `docs/repository-structure.md`, then `sync:docs`; +1 in task-006, -1 in task-009 |
| 17 | `site/src/content/docs/reference/repository-structure.md` | 81 | `112 skill definitions` | synced (sync-docs.mjs) | task-006 | Edit the source `docs/repository-structure.md`, then `sync:docs`; +1 in task-006, -1 in task-009 |
| 18 | `site/src/content/docs/reference/repository-structure.md` | 81 | `18 curated` | synced (sync-docs.mjs) | task-006 | Edit the source `docs/repository-structure.md`, then `sync:docs`; +1 in task-006, -1 in task-009 |

### S7d Agent-count prose that no suite asserts

The agent count changes for good (9 -> 8), so these phrases go stale even though no suite fails. The
regex allows up to two words between the number and "agent(s)" ("9 AID pipeline agents", "9 canonical
agents", "nine-agents" in an anchor), and also matches `(9)` and "9 directories". The paths include
`.claude/skills/generate-profile/`.

```bash
git grep -n -o -i -E '\b(9|nine)[ -]+([a-z-]+[ -]+){0,2}agents?\b|<- 9 agent|\(9\)|\b9 directories\b' 581a4335 -- \
  README.md docs/ examples/ site/src/content/ site/scripts/gen-reference.mjs .aid/knowledge/ .claude/skills/generate-profile/ \
  ':!.aid/knowledge/release-tracking.md' ':!.aid/knowledge/kb.html'
```
```text
581a4335:.aid/knowledge/architecture.md:116:9 agent
581a4335:.aid/knowledge/architecture.md:326:9 agents
581a4335:.aid/knowledge/decisions.md:54:Nine agents
581a4335:.aid/knowledge/decisions.md:54:nine-agents
581a4335:.aid/knowledge/decisions.md:91:9 agents
581a4335:.aid/knowledge/decisions.md:319:Nine agents
581a4335:.aid/knowledge/decisions.md:321:9 specialist agents
581a4335:.aid/knowledge/module-map.md:86:(9)
581a4335:.aid/knowledge/pipeline-contracts.md:446:(9)
581a4335:.claude/skills/generate-profile/SKILL.md:127:9 canonical agents
581a4335:.claude/skills/generate-profile/SKILL.md:132:9 directories
581a4335:.claude/skills/generate-profile/SKILL.md:295:9 agents
581a4335:README.md:268:9 agents
581a4335:docs/aid-methodology.md:100:9 agents
581a4335:docs/aid-methodology.md:821:9 specialist agents
581a4335:docs/aid-methodology.md:823:9 specialist agents
581a4335:docs/aid-methodology.md:875:9 agents
581a4335:docs/aid-methodology.md:1398:9 specialist agents
581a4335:docs/diagram-content-reference.md:28:9 agents
581a4335:docs/diagram-content-reference.md:106:9 agents
581a4335:docs/diagram-content-reference.md:111:(9)
581a4335:docs/diagram-content-reference.md:136:9 agents
581a4335:docs/repository-structure.md:23:<- 9 agent
581a4335:docs/repository-structure.md:78:9 agent
581a4335:site/scripts/gen-reference.mjs:7:9 agents
581a4335:site/scripts/gen-reference.mjs:299:9 specialized agents
581a4335:site/scripts/gen-reference.mjs:324:9 AID pipeline agents
581a4335:site/src/content/docs/concepts/methodology.md:104:9 agents
581a4335:site/src/content/docs/concepts/methodology.md:825:9 specialist agents
581a4335:site/src/content/docs/concepts/methodology.md:827:9 specialist agents
581a4335:site/src/content/docs/concepts/methodology.md:879:9 agents
581a4335:site/src/content/docs/concepts/methodology.md:1402:9 specialist agents
581a4335:site/src/content/docs/concepts/overview.md:26:nine specialist agents
581a4335:site/src/content/docs/reference/agents.md:3:9 AID pipeline agents
581a4335:site/src/content/docs/reference/agents.md:9:9 specialized agents
581a4335:site/src/content/docs/reference/overview.md:18:9 AID pipeline agents
581a4335:site/src/content/docs/reference/repository-structure.md:27:<- 9 agent
581a4335:site/src/content/docs/reference/repository-structure.md:82:9 agent
```
| # | File | Line | Phrase | Owner | Note |
|---|---|---|---|---|---|
| 1 | `.aid/knowledge/architecture.md` | 116 | `9 agent` | task-013 | KB prose |
| 2 | `.aid/knowledge/architecture.md` | 326 | `9 agents` | task-013 | KB prose |
| 3 | `.aid/knowledge/decisions.md` | 54 | `Nine agents` | task-012 | D15 amendment (the agent count) |
| 4 | `.aid/knowledge/decisions.md` | 54 | `nine-agents` | task-012 | The table-of-contents anchor of D15's heading (`#d15--nine-agents-...`): it follows the heading if the D15 amendment retitles it |
| 5 | `.aid/knowledge/decisions.md` | 91 | `9 agents` | task-012 | D15 amendment (the agent count) |
| 6 | `.aid/knowledge/decisions.md` | 319 | `Nine agents` | task-012 | D15 amendment (the agent count) |
| 7 | `.aid/knowledge/decisions.md` | 321 | `9 specialist agents` | task-012 | D15 amendment (the agent count) |
| 8 | `.aid/knowledge/module-map.md` | 86 | `(9)` | task-013 | The `canonical/agents/*` (9) row, also an S2b hit |
| 9 | `.aid/knowledge/pipeline-contracts.md` | 446 | `(9)` | task-013 | KB prose |
| 10 | `.claude/skills/generate-profile/SKILL.md` | 127 | `9 canonical agents` | task-008 | Completeness step 2 "All 9 canonical agents exist": the generator's own completeness check; maintainer-facing, not rendered |
| 11 | `.claude/skills/generate-profile/SKILL.md` | 132 | `9 directories` | task-008 | Its expected output "Expected: 9 directories." (the `ls canonical/agents/ \| wc -l` check): the generator's own completeness check; maintainer-facing, not rendered |
| 12 | `.claude/skills/generate-profile/SKILL.md` | 295 | `9 agents` | task-008 | Checklist "Also: 9 agents": the generator's own completeness check; maintainer-facing, not rendered |
| 13 | `README.md` | 268 | `9 agents` | task-008 | Also an S7b needle line: the count changes with task-008 |
| 14 | `docs/aid-methodology.md` | 100 | `9 agents` | task-008 | Also an S7b needle line: the count changes with task-008 |
| 15 | `docs/aid-methodology.md` | 821 | `9 specialist agents` | task-011 | Prose, not asserted |
| 16 | `docs/aid-methodology.md` | 823 | `9 specialist agents` | task-011 | Prose, not asserted |
| 17 | `docs/aid-methodology.md` | 875 | `9 agents` | task-008 | Also an S7b needle line: the count changes with task-008 |
| 18 | `docs/aid-methodology.md` | 1398 | `9 specialist agents` | task-011 | Prose, not asserted |
| 19 | `docs/diagram-content-reference.md` | 28 | `9 agents` | task-008 | Also an S7b needle line: the count changes with task-008 |
| 20 | `docs/diagram-content-reference.md` | 106 | `9 agents` | task-008 | Also an S7b needle line: the count changes with task-008 |
| 21 | `docs/diagram-content-reference.md` | 111 | `(9)` | task-011 | "agent count = `ls -1d canonical/agents/*/ \| wc -l` (9)": prose |
| 22 | `docs/diagram-content-reference.md` | 136 | `9 agents` | task-008 | Also an S7b needle line: the count changes with task-008 |
| 23 | `docs/repository-structure.md` | 23 | `<- 9 agent` | task-008 | Also an S7b needle line: the count changes with task-008 |
| 24 | `docs/repository-structure.md` | 78 | `9 agent` | task-008 | Also an S7b needle line: the count changes with task-008 |
| 25 | `site/scripts/gen-reference.mjs` | 7 | `9 agents` | task-008 | Header comment |
| 26 | `site/scripts/gen-reference.mjs` | 299 | `9 specialized agents` | task-008 | Rendered body sentence of `reference/agents.md` (line 9 there) |
| 27 | `site/scripts/gen-reference.mjs` | 324 | `9 AID pipeline agents` | task-008 | Rendered frontmatter `description:` of `reference/agents.md` (line 3 there) |
| 28 | `site/src/content/docs/concepts/methodology.md` | 104 | `9 agents` | task-008 | Synced: follows its `docs/` source |
| 29 | `site/src/content/docs/concepts/methodology.md` | 825 | `9 specialist agents` | task-011 | Synced: follows its `docs/` source |
| 30 | `site/src/content/docs/concepts/methodology.md` | 827 | `9 specialist agents` | task-011 | Synced: follows its `docs/` source |
| 31 | `site/src/content/docs/concepts/methodology.md` | 879 | `9 agents` | task-008 | Synced: follows its `docs/` source |
| 32 | `site/src/content/docs/concepts/methodology.md` | 1402 | `9 specialist agents` | task-011 | Synced: follows its `docs/` source |
| 33 | `site/src/content/docs/concepts/overview.md` | 26 | `nine specialist agents` | task-011 | Hand-written page on no spec list (see Delta) |
| 34 | `site/src/content/docs/reference/agents.md` | 3 | `9 AID pipeline agents` | task-008 | Generated from `gen-reference.mjs` line 324; regenerated, never hand-edited |
| 35 | `site/src/content/docs/reference/agents.md` | 9 | `9 specialized agents` | task-008 | Generated from `gen-reference.mjs` line 299; regenerated, never hand-edited |
| 36 | `site/src/content/docs/reference/overview.md` | 18 | `9 AID pipeline agents` | task-011 | Hand-written page (its line 16 is an S1 and S7c hit); "All 9 AID pipeline agents". Agent-count prose on hand-written pages is task-011's, as for `concepts/overview.md` |
| 37 | `site/src/content/docs/reference/repository-structure.md` | 27 | `<- 9 agent` | task-008 | Synced: follows its `docs/` source |
| 38 | `site/src/content/docs/reference/repository-structure.md` | 82 | `9 agent` | task-008 | Synced: follows its `docs/` source |

### S7e Tier labels that count the orchestrator

The orchestrator is a Medium-tier agent, so every Medium-tier count drops from 7 to 6. The search covers
the S7d paths plus `canonical/`.

```bash
git grep -n -o -i -E 'medium[^|]{0,12}\b(7|seven)\b[^|]{0,9}|\b(7|seven) (default|medium)' 581a4335 -- \
  README.md docs/ examples/ site/src/content/ site/scripts/gen-reference.mjs .aid/knowledge/ .claude/skills/generate-profile/ canonical/ \
  ':!.aid/knowledge/release-tracking.md' ':!.aid/knowledge/kb.html'
```
```text
581a4335:.aid/knowledge/architecture.md:333:Medium (7) 
581a4335:docs/aid-methodology.md:804:Medium tier — 7 default 
581a4335:docs/aid-methodology.md:830:Medium (7 default)
581a4335:site/src/content/docs/concepts/methodology.md:808:Medium tier — 7 default 
581a4335:site/src/content/docs/concepts/methodology.md:834:Medium (7 default)
```
| # | File | Line | Label | Owner | Note |
|---|---|---|---|---|---|
| 1 | `.aid/knowledge/architecture.md` | 333 | `Medium (7)` | task-013 | Tier table row `Medium (7)`, also an S2a hit (the `aid-orchestrator` entry) |
| 2 | `docs/aid-methodology.md` | 804 | `Medium tier — 7 default` | task-011 | Agent-tier diagram subgraph label "Medium tier — 7 default"; the `aid-orchestrator` node it holds is line 808 (S2a) |
| 3 | `docs/aid-methodology.md` | 830 | `Medium (7 default)` | task-011 | Tier list `Medium (7 default)`, also an S2a hit |
| 4 | `site/src/content/docs/concepts/methodology.md` | 808 | `Medium tier — 7 default` | task-011 | Synced copy of `docs/aid-methodology.md` line 804 |
| 5 | `site/src/content/docs/concepts/methodology.md` | 834 | `Medium (7 default)` | task-011 | Synced copy of `docs/aid-methodology.md` line 830 |

No Large or Small tier count changes (the orchestrator is Medium in `canonical/aid/templates/agent-dispatch-tiering.md` § Per-agent defaults).

### S7f The same wide check on the skill-count paragraphs

The S7b and S7c phrases were re-checked with the S7d shape: up to two words between the number and the
noun, a label before the number (`skills/` — 112, `curated` ... 18), and `(112)`.

```bash
git grep -n -o -i -E '\b(112|18)[ -]+([a-z`/-]+[ -]+){0,2}(skills?|skill directories|skill definitions|curated)\b|(skills|curated)[^|0-9]{0,12}\b(112|18)\b|\(112\)' \
  581a4335 -- README.md docs/ examples/ site/src/content/ site/scripts/gen-reference.mjs .aid/knowledge/ .claude/skills/generate-profile/ \
  ':!.aid/knowledge/release-tracking.md' ':!.aid/knowledge/kb.html'
```
```text
581a4335:.aid/knowledge/architecture.md:116:skills/` (112
581a4335:.aid/knowledge/architecture.md:189:112 skill
581a4335:.aid/knowledge/architecture.md:190:18 curated
581a4335:.aid/knowledge/architecture.md:451:skills/` has **112
581a4335:.aid/knowledge/architecture.md:451:18 curated
581a4335:.aid/knowledge/architecture.md:554:skills/` (the 112
581a4335:.aid/knowledge/capability-inventory.md:309:112 skill directories
581a4335:.aid/knowledge/capability-inventory.md:309:skills/`: **18
581a4335:.aid/knowledge/module-map.md:85:skills/*` (112
581a4335:.aid/knowledge/module-map.md:85:18 curated
581a4335:.aid/knowledge/module-map.md:220:112 skill directories
581a4335:.aid/knowledge/module-map.md:220:18 curated
581a4335:.aid/knowledge/pipeline-contracts.md:436:112 skill directories
581a4335:.aid/knowledge/pipeline-contracts.md:436:skills/`: 18
581a4335:.aid/knowledge/project-structure.md:101:112 skill definitions
581a4335:.aid/knowledge/project-structure.md:101:18 curated
581a4335:README.md:209:112 skills
581a4335:docs/aid-methodology.md:78:112 skill directories
581a4335:docs/aid-methodology.md:100:112 skill directories
581a4335:docs/aid-methodology.md:100:18 curated
581a4335:docs/aid-methodology.md:102:18 curated skills
581a4335:docs/diagram-content-reference.md:24:18 curated
581a4335:docs/diagram-content-reference.md:24:112 skills
581a4335:docs/diagram-content-reference.md:24:18 curated skill
581a4335:docs/diagram-content-reference.md:105:skills/` **112
581a4335:docs/diagram-content-reference.md:105:skills** — 18
581a4335:docs/diagram-content-reference.md:110:(112)
581a4335:docs/glossary.md:9:112 skills
581a4335:docs/glossary.md:9:18 curated
581a4335:docs/glossary.md:54:18 curated
581a4335:docs/install.md:442:skills/` holds 112
581a4335:docs/install.md:442:18 curated
581a4335:docs/repository-structure.md:22:112 skill definitions
581a4335:docs/repository-structure.md:22:18 curated
581a4335:docs/repository-structure.md:77:skills/` — 112
581a4335:docs/repository-structure.md:77:18 curated skills
581a4335:site/src/content/docs/concepts/methodology.md:82:112 skill directories
581a4335:site/src/content/docs/concepts/methodology.md:104:112 skill directories
581a4335:site/src/content/docs/concepts/methodology.md:104:18 curated
581a4335:site/src/content/docs/concepts/methodology.md:106:18 curated skills
581a4335:site/src/content/docs/guides/maintainer.mdx:237:skills/`, all 112
581a4335:site/src/content/docs/index.mdx:76:112 skills
581a4335:site/src/content/docs/index.mdx:76:18 curated pipeline/on-demand/router skills
581a4335:site/src/content/docs/index.mdx:92:112 skills
581a4335:site/src/content/docs/index.mdx:92:18 curated skills
581a4335:site/src/content/docs/reference/glossary.md:13:112 skills
581a4335:site/src/content/docs/reference/glossary.md:13:18 curated
581a4335:site/src/content/docs/reference/glossary.md:58:18 curated
581a4335:site/src/content/docs/reference/overview.md:16:112 AID skills
581a4335:site/src/content/docs/reference/overview.md:16:18 curated
581a4335:site/src/content/docs/reference/repository-structure.md:26:112 skill definitions
581a4335:site/src/content/docs/reference/repository-structure.md:26:18 curated
581a4335:site/src/content/docs/reference/repository-structure.md:81:skills/` — 112
581a4335:site/src/content/docs/reference/repository-structure.md:81:18 curated skills
581a4335:site/src/content/docs/skills/index.md:11:112 skill directories
```
| # | File | Line | Match | Owner | Note |
|---|---|---|---|---|---|
| 1 | `.aid/knowledge/architecture.md` | 116 | `` skills/` (112 `` | task-013 | KB count prose; no suite asserts it and the delivery ends at 112 / 18 again, so no edit is expected |
| 2 | `.aid/knowledge/architecture.md` | 189 | `112 skill` | task-013 | KB count prose; no suite asserts it and the delivery ends at 112 / 18 again, so no edit is expected |
| 3 | `.aid/knowledge/architecture.md` | 190 | `18 curated` | task-013 | KB count prose; no suite asserts it and the delivery ends at 112 / 18 again, so no edit is expected |
| 4 | `.aid/knowledge/architecture.md` | 451 | `` skills/` has **112 `` | task-013 | KB count prose; no suite asserts it and the delivery ends at 112 / 18 again, so no edit is expected |
| 5 | `.aid/knowledge/architecture.md` | 451 | `18 curated` | task-013 | KB count prose; no suite asserts it and the delivery ends at 112 / 18 again, so no edit is expected |
| 6 | `.aid/knowledge/architecture.md` | 554 | `` skills/` (the 112 `` | task-013 | KB count prose; no suite asserts it and the delivery ends at 112 / 18 again, so no edit is expected |
| 7 | `.aid/knowledge/capability-inventory.md` | 309 | `112 skill directories` | task-013 | KB count prose; no suite asserts it and the delivery ends at 112 / 18 again, so no edit is expected |
| 8 | `.aid/knowledge/capability-inventory.md` | 309 | `` skills/`: **18 `` | task-013 | KB count prose; no suite asserts it and the delivery ends at 112 / 18 again, so no edit is expected |
| 9 | `.aid/knowledge/module-map.md` | 85 | `` skills/*` (112 `` | task-013 | KB count prose; no suite asserts it and the delivery ends at 112 / 18 again, so no edit is expected |
| 10 | `.aid/knowledge/module-map.md` | 85 | `18 curated` | task-013 | KB count prose; no suite asserts it and the delivery ends at 112 / 18 again, so no edit is expected |
| 11 | `.aid/knowledge/module-map.md` | 220 | `112 skill directories` | task-013 | KB count prose; no suite asserts it and the delivery ends at 112 / 18 again, so no edit is expected |
| 12 | `.aid/knowledge/module-map.md` | 220 | `18 curated` | task-013 | KB count prose; no suite asserts it and the delivery ends at 112 / 18 again, so no edit is expected |
| 13 | `.aid/knowledge/pipeline-contracts.md` | 436 | `112 skill directories` | task-013 | KB count prose; no suite asserts it and the delivery ends at 112 / 18 again, so no edit is expected |
| 14 | `.aid/knowledge/pipeline-contracts.md` | 436 | `` skills/`: 18 `` | task-013 | KB count prose; no suite asserts it and the delivery ends at 112 / 18 again, so no edit is expected |
| 15 | `.aid/knowledge/project-structure.md` | 101 | `112 skill definitions` | task-013 | KB count prose; no suite asserts it and the delivery ends at 112 / 18 again, so no edit is expected |
| 16 | `.aid/knowledge/project-structure.md` | 101 | `18 curated` | task-013 | KB count prose; no suite asserts it and the delivery ends at 112 / 18 again, so no edit is expected |
| 17 | `README.md` | 209 | `112 skills` | task-006 | Already an S7b row |
| 18 | `docs/aid-methodology.md` | 78 | `112 skill directories` | task-006 | Already an S7b row |
| 19 | `docs/aid-methodology.md` | 100 | `112 skill directories` | task-006 | Already an S7b row |
| 20 | `docs/aid-methodology.md` | 100 | `18 curated` | task-006 | `docs/` source of a synced claim page (S7c): +1 in task-006, -1 in task-009, then `sync:docs` |
| 21 | `docs/aid-methodology.md` | 102 | `18 curated skills` | task-006 | `docs/` source of a synced claim page (S7c): +1 in task-006, -1 in task-009, then `sync:docs` |
| 22 | `docs/diagram-content-reference.md` | 24 | `18 curated` | task-006 | Not asserted; it sits on a line whose asserted skill count task-006 and task-009 move, so move it with that count to keep the sentence's sum true (net zero) |
| 23 | `docs/diagram-content-reference.md` | 24 | `112 skills` | task-006 | Already an S7b row |
| 24 | `docs/diagram-content-reference.md` | 24 | `18 curated skill` | task-006 | Not asserted; it sits on a line whose asserted skill count task-006 and task-009 move, so move it with that count to keep the sentence's sum true (net zero) |
| 25 | `docs/diagram-content-reference.md` | 105 | `` skills/` **112 `` | task-006 | Already an S7b row |
| 26 | `docs/diagram-content-reference.md` | 105 | `skills** — 18` | task-006 | Not asserted; it sits on a line whose asserted skill count task-006 and task-009 move, so move it with that count to keep the sentence's sum true (net zero) |
| 27 | `docs/diagram-content-reference.md` | 110 | `(112)` | task-011 | "skill count = `ls -1d canonical/skills/*/ \| wc -l` (112)": prose, net zero, no edit expected |
| 28 | `docs/glossary.md` | 9 | `112 skills` | task-006 | Already an S7b row |
| 29 | `docs/glossary.md` | 9 | `18 curated` | task-006 | `docs/` source of a synced claim page (S7c): +1 in task-006, -1 in task-009, then `sync:docs` |
| 30 | `docs/glossary.md` | 54 | `18 curated` | task-006 | `docs/` source of a synced claim page (S7c): +1 in task-006, -1 in task-009, then `sync:docs` |
| 31 | `docs/install.md` | 442 | `` skills/` holds 112 `` | task-006 | Already an S7b row |
| 32 | `docs/install.md` | 442 | `18 curated` | task-006 | Not asserted; it sits on a line whose asserted skill count task-006 and task-009 move, so move it with that count to keep the sentence's sum true (net zero) |
| 33 | `docs/repository-structure.md` | 22 | `112 skill definitions` | task-006 | Already an S7b row |
| 34 | `docs/repository-structure.md` | 22 | `18 curated` | task-006 | `docs/` source of a synced claim page (S7c): +1 in task-006, -1 in task-009, then `sync:docs` |
| 35 | `docs/repository-structure.md` | 77 | `` skills/` — 112 `` | task-006 | Already an S7b row |
| 36 | `docs/repository-structure.md` | 77 | `18 curated skills` | task-006 | `docs/` source of a synced claim page (S7c): +1 in task-006, -1 in task-009, then `sync:docs` |
| 37 | `site/src/content/docs/concepts/methodology.md` | 82 | `112 skill directories` | task-006 | Already an S7c row |
| 38 | `site/src/content/docs/concepts/methodology.md` | 104 | `112 skill directories` | task-006 | Already an S7c row |
| 39 | `site/src/content/docs/concepts/methodology.md` | 104 | `18 curated` | task-006 | Already an S7c row |
| 40 | `site/src/content/docs/concepts/methodology.md` | 106 | `18 curated skills` | task-006 | Already an S7c row |
| 41 | `site/src/content/docs/guides/maintainer.mdx` | 237 | `` skills/`, all 112 `` | task-006 | Already an S7c row |
| 42 | `site/src/content/docs/index.mdx` | 76 | `112 skills` | task-006 | Already an S7c row |
| 43 | `site/src/content/docs/index.mdx` | 76 | `18 curated pipeline/on-demand/router skills` | task-006 | Already an S7c row |
| 44 | `site/src/content/docs/index.mdx` | 92 | `112 skills` | task-006 | Already an S7c row |
| 45 | `site/src/content/docs/index.mdx` | 92 | `18 curated skills` | task-006 | Already an S7c row |
| 46 | `site/src/content/docs/reference/glossary.md` | 13 | `112 skills` | task-006 | Already an S7c row |
| 47 | `site/src/content/docs/reference/glossary.md` | 13 | `18 curated` | task-006 | Already an S7c row |
| 48 | `site/src/content/docs/reference/glossary.md` | 58 | `18 curated` | task-006 | Already an S7c row |
| 49 | `site/src/content/docs/reference/overview.md` | 16 | `112 AID skills` | task-006 | Already an S7c row |
| 50 | `site/src/content/docs/reference/overview.md` | 16 | `18 curated` | task-006 | Already an S7c row |
| 51 | `site/src/content/docs/reference/repository-structure.md` | 26 | `112 skill definitions` | task-006 | Already an S7c row |
| 52 | `site/src/content/docs/reference/repository-structure.md` | 26 | `18 curated` | task-006 | Already an S7c row |
| 53 | `site/src/content/docs/reference/repository-structure.md` | 81 | `` skills/` — 112 `` | task-006 | Already an S7c row |
| 54 | `site/src/content/docs/reference/repository-structure.md` | 81 | `18 curated skills` | task-006 | Already an S7c row |
| 55 | `site/src/content/docs/skills/index.md` | 11 | `112 skill directories` | task-006 | Generated by `gen:skills`; regenerated in task-006 and task-009 |

The skill numbers end the delivery where they started (S7a), so the only edits S7f adds are the
`18 curated` phrases in the `docs/` sources of synced claim pages and on lines task-006 already moves.
A further sweep for `(N)`, `— N` and `: N` labels (`git grep -n -o -E '\((112|18|9|7)\)|— (112|18|9|7)\b|: (112|18|9)\b'`
over the same paths) found no agent or tier count beyond S7d and S7e: its other hits are skill counts
listed above, PowerShell versions (`pwsh` (7)), a task count in `examples/greenfield/samples/PLAN.md`, and
an edge count in `tech-debt.md`.

## S8 Description checks

### S8a Suites and site tests that read a `SKILL.md` `description:`

```bash
git grep -c -E -e '\^description:|description: >|skillSummary\(|description_chars|AID_READ_TICKET_DESCRIPTION|description frontmatter|key === .description.' \
  581a4335 -- "${SUITES[@]}"   # SUITES as in S6c
```
```text
581a4335:site/scripts/__tests__/gen-skills-index.test.mjs:6
581a4335:site/scripts/__tests__/gen-skills.test.mjs:3
581a4335:site/scripts/__tests__/skills-discover.test.mjs:4
581a4335:site/scripts/__tests__/skills-render-index.test.mjs:6
581a4335:site/scripts/__tests__/skills-render-page.test.mjs:1
581a4335:site/scripts/__tests__/skills-render-value.test.mjs:8
581a4335:site/scripts/__tests__/skills-summary.test.mjs:20
581a4335:tests/canonical/test-cost-meter.sh:2
581a4335:tests/canonical/test-ticket-skills-structural.sh:3
581a4335:tests/cost-meter.py:3
```
| # | Suite | Owner | Note |
|---|---|---|---|
| 1 | `site/scripts/__tests__/gen-skills.test.mjs` | task-010 | Lines 424-438 read the real `aid-read-ticket` `description:` and require the code span `` `aid-read-ticket [<connector>:]<ticket-id>` `` to survive rendering: keep that span in the rewritten description, or re-point the test in task-010 |
| 2 | `site/scripts/__tests__/skills-render-value.test.mjs` | task-010 | A verbatim copy of `aid-read-ticket`'s description (AC-1 fixture, line 192) and a corpus sweep that reads only folded `description: >` values: update the copy if the rewrite should stay mirrored; keep descriptions folded |
| 3 | `site/scripts/__tests__/skills-summary.test.mjs` | task-010 | Corpus sweep: every summary (first sentence, cap `SUMMARY_CAP`) is non-empty and within the cap; its parser reads only `description: >` folded blocks. Keep every description folded and its first sentence within the cap |
| 4 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-010 | Assertion 11: each card's intent equals `skillSummary(record)` and the page's `description:` frontmatter; regenerate (`gen:skills`) |
| 5 | `site/scripts/__tests__/skills-render-index.test.mjs` | task-010 | Real detail pages' `description:` equals the summary; regenerate |
| 6 | `site/scripts/__tests__/skills-discover.test.mjs` | task-010 | Synthetic records plus the real corpus walk; no edit expected |
| 7 | `site/scripts/__tests__/skills-render-page.test.mjs` | task-010 | Synthetic fields (its comment states the real corpus is all folded); no edit expected |
| 8 | `tests/canonical/test-ticket-skills-structural.sh` | task-010 | T02 (`aid-read-ticket`), T08 (`aid-create-ticket`), T14 (`aid-update-ticket`) require a folded `description: >`; T54 the `aid-update-ticket` part enum (task-007). Only `aid-read-ticket` is rewritten here (the other two are S9-exempt) |
| 9 | `tests/canonical/test-cost-meter.sh` | task-010 | Guards the meter with a planted fixture; no edit expected |
| 10 | `tests/cost-meter.py` | task-010 | `description_chars` feeds the always-on `skill-descriptions` row of `tests/cost-baseline.tsv`, re-recorded at the gate; not run by `run-all.sh` |

No suite asserts the doorway description text itself (`git grep -n -E "Use this skill when|plans and stops|reviewable tasks in a single pass" 581a4335 -- tests/ site/scripts/__tests__ site/src/lib/__tests__ site/src/data/__tests__ ':!**/fixtures/**' ':!tests/*.tsv'` prints nothing). The doorways are checked by `build-shortcut-skills.py --check` inside `test-catalog-dirs-parity.sh` and `test-shortcut-builder-invariants.sh` SBI05.

### S8b The doorway builder's template

```bash
git grep -n -A5 -e 'description = (' 581a4335 -- .claude/skills/generate-profile/scripts/build-shortcut-skills.py
```
```text
581a4335:.claude/skills/generate-profile/scripts/build-shortcut-skills.py:262:    description = (
581a4335:.claude/skills/generate-profile/scripts/build-shortcut-skills.py-263-        f"{intent} Use this skill when you already know what to {verb} and want it scoped, "
581a4335:.claude/skills/generate-profile/scripts/build-shortcut-skills.py-264-        "specified, and broken into reviewable tasks in a single pass, with no requirements "
581a4335:.claude/skills/generate-profile/scripts/build-shortcut-skills.py-265-        "interview. You approve the resulting plan before anything is built: this skill "
581a4335:.claude/skills/generate-profile/scripts/build-shortcut-skills.py-266-        "plans and stops, so run `/aid-execute` to carry the plan out."
581a4335:.claude/skills/generate-profile/scripts/build-shortcut-skills.py-267-    )
```
| # | File | Lines | Owner | Note |
|---|---|---|---|---|
| 1 | `.claude/skills/generate-profile/scripts/build-shortcut-skills.py` | 262-267 | task-010 | `{intent}` plus a long "Use this skill when ..." sentence today; becomes the catalog row's `intent:` plus one "Use when ..." sentence. Then the builder regenerates all 34 doorways; `--check` stays green |

## S9 The SG-04 exempt list

Every skill whose deletion or rename a later feature's `##### 1. Files and layout` states (Q134 D4).
Rows that delete only some `references/` of a skill (Feature 005 line 3080, Feature 006 line 3642,
Feature 007 line 4247) keep the skill's name, so they exempt nothing. Skills a later feature rebuilds under
the same name are not exempt (`aid-brainstorm`, `aid-specify`, `aid-plan`, `aid-execute`, and the
doorways `aid-create`, `aid-update`, `aid-fix`, `aid-refactor` that Feature 009 rewrites). `aid-triage`
is not exempt either: task-009 deletes it before task-014 adds SG-04.

### S9a Command

```bash
awk -F'|' '/^```/{f=!f} !f && /^### Feature [0-9]+/{feat=$0; sub(/ —.*/,"",feat); sub(/^### /,"",feat)} \
  !f && /^##### /{sec=$0} !f && sec ~ /^##### 1\. Files and layout/ && feat != "Feature 001" && $2 ~ /^ *(Delete|Move)/ \
  && $3 ~ /canonical\/skills\// {gsub(/^ +| +$/,"",$2); gsub(/^ +| +$/,"",$3); print NR": "feat": "$2": "$3}' \
  .aid/works/work-003-full-aid-restructure/REQUIREMENTS.md
ls canonical/skills/*/SKILL.md   # the skills on disk, matched against the rows above
```
Hit list (first command; the second is the 112-line listing that the skill owner table reproduces):

```text
1774: Feature 003: Delete: `canonical/skills/aid-describe/`
1775: Feature 003: Delete: `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`
2236: Feature 004: Move + rewrite: `canonical/skills/aid-discover/` -> `canonical/skills/aid-kb-build/`
2237: Feature 004: Move + rewrite: `canonical/skills/aid-update-kb/` -> `canonical/skills/aid-kb-update/`
2238: Feature 004: Move + edit: `canonical/skills/aid-ask/` -> `canonical/skills/aid-kb-query/`
2240: Feature 004: Delete: `canonical/skills/aid-summarize/`, `canonical/skills/aid-housekeep/`
2241: Feature 004: Delete: `canonical/skills/aid-create-*/` and `canonical/skills/aid-update-*/` for `architecture`, `stack`, `testing-strategy`, `cicd`, `roadmap`, `backlog`, `mvp`
3080: Feature 005: Delete: `canonical/skills/aid-specify/references/` `state-initialize.md`, `state-continue.md`, `state-review.md`, `state-spike.md`, `state-blocked.md`, `state-done.md`, `handling-outcomes.md`, `known-issues-scope.md`
3081: Feature 005: Delete: `canonical/skills/aid-define/`
3642: Feature 006: Delete: `canonical/skills/aid-plan/references/` `first-run-loop.md`, `review-deliverables.md`
3643: Feature 006: Delete: `canonical/skills/aid-detail/`
4247: Feature 007: Delete: `canonical/skills/aid-execute/references/` `state-execute.md`, `state-execute-drilldown.md`, `state-review.md`, `state-fix.md`, `state-re-run.md`, `state-delivery-gate.md`, `reviewer-guide.md`
5654: Feature 009: Move + edit: `canonical/skills/aid-config/` -> `canonical/skills/aid-configure/`
5658: Feature 009: Delete: every `canonical/skills/aid-create-*/` and `aid-update-*/` still on disk (the code kinds, `test`, `dashboard`, `document`, `diagram`, `ticket`), every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`
```
The REQUIREMENTS.md command reads the work folder, which is fine for this transient research file; the
static suite (task-014) holds the resulting names, not the path. The line numbers are those of
REQUIREMENTS.md at the base commit.

### S9b The list

| # | Skill | Kind | Deleted or renamed by (anchor) |
|---|---|---|---|
| 1 | `aid-ask` | hand-authored (catalog `repurpose` row) | F004 `##### 1. Files and layout`, row "Move + edit `aid-ask/` -> `aid-kb-query/`" (line 2238) |
| 2 | `aid-config` | hand-authored (curated, no catalog row) | F009 `##### 1. Files and layout`, row "Move + edit `aid-config/` -> `aid-configure/`" (line 5654) |
| 3 | `aid-create-api` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 4 | `aid-create-architecture` | hand-authored (catalog `repurpose` row) | F004 `##### 1. Files and layout`, row "Delete `aid-create-*/` and `aid-update-*/` for architecture, stack, testing-strategy, cicd, roadmap, backlog, mvp" (line 2241) |
| 5 | `aid-create-backlog` | hand-authored (catalog `repurpose` row) | F004 `##### 1. Files and layout`, row "Delete `aid-create-*/` and `aid-update-*/` for architecture, stack, testing-strategy, cicd, roadmap, backlog, mvp" (line 2241) |
| 6 | `aid-create-cicd` | hand-authored (catalog `repurpose` row) | F004 `##### 1. Files and layout`, row "Delete `aid-create-*/` and `aid-update-*/` for architecture, stack, testing-strategy, cicd, roadmap, backlog, mvp" (line 2241) |
| 7 | `aid-create-cli` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 8 | `aid-create-config` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 9 | `aid-create-dashboard` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 10 | `aid-create-data-model` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 11 | `aid-create-data-pipeline` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 12 | `aid-create-diagram` | hand-authored (catalog `repurpose` row) | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 13 | `aid-create-document` | hand-authored (catalog `repurpose` row) | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 14 | `aid-create-infra` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 15 | `aid-create-integration` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 16 | `aid-create-job` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 17 | `aid-create-messaging` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 18 | `aid-create-mvp` | hand-authored (catalog `repurpose` row) | F004 `##### 1. Files and layout`, row "Delete `aid-create-*/` and `aid-update-*/` for architecture, stack, testing-strategy, cicd, roadmap, backlog, mvp" (line 2241) |
| 19 | `aid-create-roadmap` | hand-authored (catalog `repurpose` row) | F004 `##### 1. Files and layout`, row "Delete `aid-create-*/` and `aid-update-*/` for architecture, stack, testing-strategy, cicd, roadmap, backlog, mvp" (line 2241) |
| 20 | `aid-create-stack` | hand-authored (catalog `repurpose` row) | F004 `##### 1. Files and layout`, row "Delete `aid-create-*/` and `aid-update-*/` for architecture, stack, testing-strategy, cicd, roadmap, backlog, mvp" (line 2241) |
| 21 | `aid-create-test` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 22 | `aid-create-testing-strategy` | hand-authored (catalog `repurpose` row) | F004 `##### 1. Files and layout`, row "Delete `aid-create-*/` and `aid-update-*/` for architecture, stack, testing-strategy, cicd, roadmap, backlog, mvp" (line 2241) |
| 23 | `aid-create-theme` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 24 | `aid-create-ticket` | hand-authored (curated, no catalog row) | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 25 | `aid-create-ui` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 26 | `aid-define` | hand-authored (curated, no catalog row) | F005 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-define/`" (line 3081) |
| 27 | `aid-deprecate` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 28 | `aid-describe` | hand-authored (curated, no catalog row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-describe/`" (REQUIREMENTS.md line 1774) |
| 29 | `aid-design-api` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 30 | `aid-design-architecture` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 31 | `aid-design-backlog` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 32 | `aid-design-cicd` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 33 | `aid-design-cli` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 34 | `aid-design-config` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 35 | `aid-design-dashboard` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 36 | `aid-design-data-model` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 37 | `aid-design-data-pipeline` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 38 | `aid-design-document` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 39 | `aid-design-infra` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 40 | `aid-design-integration` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 41 | `aid-design-job` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 42 | `aid-design-messaging` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 43 | `aid-design-mvp` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 44 | `aid-design-roadmap` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 45 | `aid-design-stack` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 46 | `aid-design-test` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 47 | `aid-design-testing-strategy` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 48 | `aid-design-theme` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 49 | `aid-design-ui` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 50 | `aid-design` | hand-authored (catalog `repurpose` row) | F003 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-design/` and every `canonical/skills/aid-design-*/`" (line 1775) |
| 51 | `aid-detail` | hand-authored (curated, no catalog row) | F006 `##### 1. Files and layout`, row "Delete `canonical/skills/aid-detail/`" (line 3643) |
| 52 | `aid-discover` | hand-authored (curated, no catalog row) | F004 `##### 1. Files and layout`, row "Move + rewrite `aid-discover/` -> `aid-kb-build/`" (line 2236) |
| 53 | `aid-document-architecture` | hand-authored (catalog `repurpose` row) | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 54 | `aid-document-changelog` | hand-authored (catalog `repurpose` row) | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 55 | `aid-document-decision` | hand-authored (catalog `repurpose` row) | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 56 | `aid-document-guideline` | hand-authored (catalog `repurpose` row) | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 57 | `aid-document-runbook` | hand-authored (catalog `repurpose` row) | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 58 | `aid-document-standard` | hand-authored (catalog `repurpose` row) | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 59 | `aid-document-tutorial` | hand-authored (catalog `repurpose` row) | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 60 | `aid-experiment` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 61 | `aid-housekeep` | hand-authored (curated, no catalog row) | F004 `##### 1. Files and layout`, row "Delete `aid-summarize/`, `aid-housekeep/`" (line 2240) |
| 62 | `aid-migrate` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 63 | `aid-prototype-ui` | hand-authored (catalog `repurpose` row) | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 64 | `aid-remove` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 65 | `aid-summarize` | hand-authored (curated, no catalog row) | F004 `##### 1. Files and layout`, row "Delete `aid-summarize/`, `aid-housekeep/`" (line 2240) |
| 66 | `aid-test-data-quality` | hand-authored (catalog `repurpose` row) | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 67 | `aid-test-performance` | hand-authored (catalog `repurpose` row) | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 68 | `aid-test-security` | hand-authored (catalog `repurpose` row) | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 69 | `aid-update-api` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 70 | `aid-update-architecture` | hand-authored (catalog `repurpose` row) | F004 `##### 1. Files and layout`, row "Delete `aid-create-*/` and `aid-update-*/` for architecture, stack, testing-strategy, cicd, roadmap, backlog, mvp" (line 2241) |
| 71 | `aid-update-backlog` | hand-authored (catalog `repurpose` row) | F004 `##### 1. Files and layout`, row "Delete `aid-create-*/` and `aid-update-*/` for architecture, stack, testing-strategy, cicd, roadmap, backlog, mvp" (line 2241) |
| 72 | `aid-update-cicd` | hand-authored (catalog `repurpose` row) | F004 `##### 1. Files and layout`, row "Delete `aid-create-*/` and `aid-update-*/` for architecture, stack, testing-strategy, cicd, roadmap, backlog, mvp" (line 2241) |
| 73 | `aid-update-cli` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 74 | `aid-update-config` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 75 | `aid-update-dashboard` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 76 | `aid-update-data-model` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 77 | `aid-update-data-pipeline` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 78 | `aid-update-document` | hand-authored (catalog `repurpose` row) | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 79 | `aid-update-infra` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 80 | `aid-update-integration` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 81 | `aid-update-job` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 82 | `aid-update-kb` | hand-authored (curated, no catalog row) | F004 `##### 1. Files and layout`, row "Move + rewrite `aid-update-kb/` -> `aid-kb-update/`" (line 2237) |
| 83 | `aid-update-messaging` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 84 | `aid-update-mvp` | hand-authored (catalog `repurpose` row) | F004 `##### 1. Files and layout`, row "Delete `aid-create-*/` and `aid-update-*/` for architecture, stack, testing-strategy, cicd, roadmap, backlog, mvp" (line 2241) |
| 85 | `aid-update-roadmap` | hand-authored (catalog `repurpose` row) | F004 `##### 1. Files and layout`, row "Delete `aid-create-*/` and `aid-update-*/` for architecture, stack, testing-strategy, cicd, roadmap, backlog, mvp" (line 2241) |
| 86 | `aid-update-stack` | hand-authored (catalog `repurpose` row) | F004 `##### 1. Files and layout`, row "Delete `aid-create-*/` and `aid-update-*/` for architecture, stack, testing-strategy, cicd, roadmap, backlog, mvp" (line 2241) |
| 87 | `aid-update-test` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 88 | `aid-update-testing-strategy` | hand-authored (catalog `repurpose` row) | F004 `##### 1. Files and layout`, row "Delete `aid-create-*/` and `aid-update-*/` for architecture, stack, testing-strategy, cicd, roadmap, backlog, mvp" (line 2241) |
| 89 | `aid-update-theme` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 90 | `aid-update-ticket` | hand-authored (curated, no catalog row) | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |
| 91 | `aid-update-ui` | generated doorway | F009 `##### 1. Files and layout`, row "Delete every `aid-create-*/` and `aid-update-*/` still on disk ..., every `aid-document-*/` and `aid-test-*/`, `aid-prototype-ui/`, `aid-remove/`, `aid-deprecate/`, `aid-migrate/`, `aid-experiment/`" (line 5658) |

91 exempt skills; 21 skills on disk are not exempt (20 that keep their name through v4.0.0, plus `aid-triage`, which this delivery deletes).

## S10 Site page classes

Every site file that carries an S1 to S3 term, plus the two site pages that only S7 finds. Class:
**generated** by `site/scripts/gen-skills.mjs` (skill pages, `skills/index.md`, `src/data/skill-flows/`,
`scripts/.skills-manifest.json`) or `site/scripts/gen-reference.mjs` (`reference/skills.md`,
`reference/agents.md`, `reference/kb.md`, `reference/settings.md`); **synced** by
`site/scripts/sync-docs.mjs` from `docs/` (`concepts/methodology.md` <- `docs/aid-methodology.md`,
`concepts/faq.md` <- `docs/faq.md`, `reference/repository-structure.md` <- `docs/repository-structure.md`,
`reference/glossary.md` <- `docs/glossary.md`); or **hand-written** (pages, generator sources, tests). A
generated page is never edited by hand: its owner changes the source and regenerates. A synced page is
never edited by hand: its owner edits the `docs/` source and runs `sync:docs`.

```bash
git grep -l -e 'aid-triage' -e 'triage router' -e 'aid-orchestrator' -e 'ticket_ref' 581a4335 -- site/
```
```text
581a4335:site/scripts/.skills-manifest.json
581a4335:site/scripts/__tests__/flow-classify.test.mjs
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs
581a4335:site/scripts/__tests__/flow-graph.test.mjs
581a4335:site/scripts/__tests__/gen-reference.test.mjs
581a4335:site/scripts/__tests__/gen-skills-index.test.mjs
581a4335:site/scripts/__tests__/skill-counts.test.mjs
581a4335:site/scripts/__tests__/skills-groups.test.mjs
581a4335:site/scripts/__tests__/skills-render-index.test.mjs
581a4335:site/scripts/gen-reference.mjs
581a4335:site/scripts/skills/curated-roster.mjs
581a4335:site/scripts/skills/groups.mjs
581a4335:site/scripts/skills/render-index.mjs
581a4335:site/scripts/skills/skill-counts.mjs
581a4335:site/src/content/docs/concepts/faq.md
581a4335:site/src/content/docs/concepts/methodology.md
581a4335:site/src/content/docs/get-started/first-work.mdx
581a4335:site/src/content/docs/get-started/lite-path.mdx
581a4335:site/src/content/docs/guides/pipeline.mdx
581a4335:site/src/content/docs/index.mdx
581a4335:site/src/content/docs/reference/agents.md
581a4335:site/src/content/docs/reference/artifacts.md
581a4335:site/src/content/docs/reference/glossary.md
581a4335:site/src/content/docs/reference/overview.md
581a4335:site/src/content/docs/reference/repository-structure.md
581a4335:site/src/content/docs/reference/skills.md
581a4335:site/src/content/docs/skills/aid-monitor.md
581a4335:site/src/content/docs/skills/aid-triage.md
581a4335:site/src/content/docs/skills/index.md
581a4335:site/src/data/skill-flows/aid-create-api.flow.json
581a4335:site/src/data/skill-flows/aid-create-cli.flow.json
581a4335:site/src/data/skill-flows/aid-create-config.flow.json
581a4335:site/src/data/skill-flows/aid-create-dashboard.flow.json
581a4335:site/src/data/skill-flows/aid-create-data-model.flow.json
581a4335:site/src/data/skill-flows/aid-create-data-pipeline.flow.json
581a4335:site/src/data/skill-flows/aid-create-infra.flow.json
581a4335:site/src/data/skill-flows/aid-create-integration.flow.json
581a4335:site/src/data/skill-flows/aid-create-job.flow.json
581a4335:site/src/data/skill-flows/aid-create-messaging.flow.json
581a4335:site/src/data/skill-flows/aid-create-test.flow.json
581a4335:site/src/data/skill-flows/aid-create-theme.flow.json
581a4335:site/src/data/skill-flows/aid-create-ui.flow.json
581a4335:site/src/data/skill-flows/aid-create.flow.json
581a4335:site/src/data/skill-flows/aid-deprecate.flow.json
581a4335:site/src/data/skill-flows/aid-describe.flow.json
581a4335:site/src/data/skill-flows/aid-experiment.flow.json
581a4335:site/src/data/skill-flows/aid-fix.flow.json
581a4335:site/src/data/skill-flows/aid-migrate.flow.json
581a4335:site/src/data/skill-flows/aid-monitor.flow.json
581a4335:site/src/data/skill-flows/aid-plan.flow.json
581a4335:site/src/data/skill-flows/aid-refactor.flow.json
581a4335:site/src/data/skill-flows/aid-remove.flow.json
581a4335:site/src/data/skill-flows/aid-specify.flow.json
581a4335:site/src/data/skill-flows/aid-triage.flow.json
581a4335:site/src/data/skill-flows/aid-update-api.flow.json
581a4335:site/src/data/skill-flows/aid-update-cli.flow.json
581a4335:site/src/data/skill-flows/aid-update-config.flow.json
581a4335:site/src/data/skill-flows/aid-update-dashboard.flow.json
581a4335:site/src/data/skill-flows/aid-update-data-model.flow.json
581a4335:site/src/data/skill-flows/aid-update-data-pipeline.flow.json
581a4335:site/src/data/skill-flows/aid-update-infra.flow.json
581a4335:site/src/data/skill-flows/aid-update-integration.flow.json
581a4335:site/src/data/skill-flows/aid-update-job.flow.json
581a4335:site/src/data/skill-flows/aid-update-messaging.flow.json
581a4335:site/src/data/skill-flows/aid-update-test.flow.json
581a4335:site/src/data/skill-flows/aid-update-theme.flow.json
581a4335:site/src/data/skill-flows/aid-update-ui.flow.json
581a4335:site/src/data/skill-flows/aid-update.flow.json
```
| # | Site file | Class | Owners, by search |
|---|---|---|---|
| 1 | `site/scripts/.skills-manifest.json` | generated (gen-skills.mjs) | S1 task-009 |
| 2 | `site/scripts/__tests__/flow-classify.test.mjs` | hand-written (site test) | S1 task-009 |
| 3 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | hand-written (site test) | S1 task-009 |
| 4 | `site/scripts/__tests__/flow-graph.test.mjs` | hand-written (site test) | S1 task-009 |
| 5 | `site/scripts/__tests__/gen-reference.test.mjs` | hand-written (site test) | S1 task-009 |
| 6 | `site/scripts/__tests__/gen-skills-index.test.mjs` | hand-written (site test) | S1 task-009 |
| 7 | `site/scripts/__tests__/skill-counts.test.mjs` | hand-written (site test) | S1 task-009 |
| 8 | `site/scripts/__tests__/skills-groups.test.mjs` | hand-written (site test) | S1 task-009 |
| 9 | `site/scripts/__tests__/skills-render-index.test.mjs` | hand-written (site test) | S1 task-009 |
| 10 | `site/scripts/gen-reference.mjs` | hand-written (generator source) | S1 task-009 |
| 11 | `site/scripts/skills/curated-roster.mjs` | hand-written (generator source) | S1 task-009 |
| 12 | `site/scripts/skills/groups.mjs` | hand-written (generator source) | S1 task-009 |
| 13 | `site/scripts/skills/render-index.mjs` | hand-written (generator source) | S1 task-009 |
| 14 | `site/scripts/skills/skill-counts.mjs` | hand-written (generator source) | S1 task-009 |
| 15 | `site/src/content/docs/concepts/faq.md` | synced (sync-docs.mjs) | S1 task-011 |
| 16 | `site/src/content/docs/concepts/methodology.md` | synced (sync-docs.mjs) | S1 task-011, S2 task-011 |
| 17 | `site/src/content/docs/get-started/first-work.mdx` | hand-written (page) | S1 task-011 |
| 18 | `site/src/content/docs/get-started/lite-path.mdx` | hand-written (page) | S1 task-011 |
| 19 | `site/src/content/docs/guides/pipeline.mdx` | hand-written (page) | S1 task-011 |
| 20 | `site/src/content/docs/index.mdx` | hand-written (page) | S1 task-011 |
| 21 | `site/src/content/docs/reference/agents.md` | generated (gen-reference.mjs) | S2 task-008; S7 task-008 |
| 22 | `site/src/content/docs/reference/artifacts.md` | hand-written (page) | S1 task-011 |
| 23 | `site/src/content/docs/reference/glossary.md` | synced (sync-docs.mjs) | S1 task-011 |
| 24 | `site/src/content/docs/reference/overview.md` | hand-written (page) | S1 task-011 |
| 25 | `site/src/content/docs/reference/repository-structure.md` | synced (sync-docs.mjs) | S1 task-011 |
| 26 | `site/src/content/docs/reference/skills.md` | generated (gen-reference.mjs) | S1 task-009 |
| 27 | `site/src/content/docs/skills/aid-monitor.md` | generated (gen-skills.mjs) | S1 task-008, S2 task-008 |
| 28 | `site/src/content/docs/skills/aid-triage.md` | generated (gen-skills.mjs) | S1 task-009 |
| 29 | `site/src/content/docs/skills/index.md` | generated (gen-skills.mjs) | S1 task-009 |
| 30 | `site/src/data/skill-flows/aid-create-api.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 31 | `site/src/data/skill-flows/aid-create-cli.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 32 | `site/src/data/skill-flows/aid-create-config.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 33 | `site/src/data/skill-flows/aid-create-dashboard.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 34 | `site/src/data/skill-flows/aid-create-data-model.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 35 | `site/src/data/skill-flows/aid-create-data-pipeline.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 36 | `site/src/data/skill-flows/aid-create-infra.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 37 | `site/src/data/skill-flows/aid-create-integration.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 38 | `site/src/data/skill-flows/aid-create-job.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 39 | `site/src/data/skill-flows/aid-create-messaging.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 40 | `site/src/data/skill-flows/aid-create-test.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 41 | `site/src/data/skill-flows/aid-create-theme.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 42 | `site/src/data/skill-flows/aid-create-ui.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 43 | `site/src/data/skill-flows/aid-create.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 44 | `site/src/data/skill-flows/aid-deprecate.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 45 | `site/src/data/skill-flows/aid-describe.flow.json` | generated (gen-skills.mjs) | S1 task-009, S3 task-007 |
| 46 | `site/src/data/skill-flows/aid-experiment.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 47 | `site/src/data/skill-flows/aid-fix.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 48 | `site/src/data/skill-flows/aid-migrate.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 49 | `site/src/data/skill-flows/aid-monitor.flow.json` | generated (gen-skills.mjs) | S1 task-008, S2 task-008 |
| 50 | `site/src/data/skill-flows/aid-plan.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 51 | `site/src/data/skill-flows/aid-refactor.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 52 | `site/src/data/skill-flows/aid-remove.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 53 | `site/src/data/skill-flows/aid-specify.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 54 | `site/src/data/skill-flows/aid-triage.flow.json` | generated (gen-skills.mjs) | S1 task-009 |
| 55 | `site/src/data/skill-flows/aid-update-api.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 56 | `site/src/data/skill-flows/aid-update-cli.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 57 | `site/src/data/skill-flows/aid-update-config.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 58 | `site/src/data/skill-flows/aid-update-dashboard.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 59 | `site/src/data/skill-flows/aid-update-data-model.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 60 | `site/src/data/skill-flows/aid-update-data-pipeline.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 61 | `site/src/data/skill-flows/aid-update-infra.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 62 | `site/src/data/skill-flows/aid-update-integration.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 63 | `site/src/data/skill-flows/aid-update-job.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 64 | `site/src/data/skill-flows/aid-update-messaging.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 65 | `site/src/data/skill-flows/aid-update-test.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 66 | `site/src/data/skill-flows/aid-update-theme.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 67 | `site/src/data/skill-flows/aid-update-ui.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 68 | `site/src/data/skill-flows/aid-update.flow.json` | generated (gen-skills.mjs) | S3 task-007 |
| 69 | `site/src/content/docs/guides/maintainer.mdx` | hand-written (page) | S7 task-006 (count claims, then task-009) |
| 70 | `site/src/content/docs/concepts/overview.md` | hand-written (page) | S7 task-011 (agent count) |

68 files from the command plus 2 from S7. Counts by class: generated (gen-reference.mjs): 2; generated (gen-skills.mjs): 43; hand-written (generator source): 5; hand-written (page): 8; hand-written (site test): 8; synced (sync-docs.mjs): 4.

## Site fixtures (G11)

Site tests that read a real skill or template by path or by name. The command lists every quoted
`aid-*` name and every `canonical/skills/` or `canonical/aid/templates/` path in the two site test
folders (844 lines; most name synthetic fixtures or skills this delivery does not
change).

```bash
git grep -nE "'aid-[a-z-]+'|canonical/(skills|aid/templates)/" 581a4335 -- site/scripts/__tests__ site/src/lib/__tests__
```
The full output is long and mostly irrelevant, so it is not copied here. This reduction keeps only
the names whose files this delivery changes, and its output is the hit list of the table below (test,
name, distinct lines):

```bash
N='aid-triage|aid-monitor|aid-describe|aid-update-ticket|aid-specify|aid-plan|aid-brainstorm|aid-chat|aid-deploy|aid-document|aid-execute|aid-prototype|aid-read-ticket|aid-report|aid-research|aid-review|aid-set-connector|aid-test|aid-unset-connector|aid-create|aid-update|aid-fix|aid-refactor|aid-deprecate|aid-experiment|aid-migrate|aid-remove|aid-(create|update)-(api|cli|config|dashboard|data-model|data-pipeline|infra|integration|job|messaging|test|theme|ui)'
git grep -noE "'($N)'|canonical/skills/($N)/|canonical/aid/templates/(shortcut-engine\.md|shortcut-catalog\.yml)" 581a4335 -- site/scripts/__tests__ site/src/lib/__tests__ \
  | sed -E "s/^581a4335://; s#:'#:#; s#'\$##; s#:canonical/skills/#:#; s#/\$##; s#:canonical/aid/templates/#:#" \
  | sort -u | awk -F: '{c[$1" "$3]++} END{for(k in c) print k, c[k]}' | LC_ALL=C sort
```
```text
site/scripts/__tests__/flow-advance.test.mjs aid-test 5
site/scripts/__tests__/flow-classify.test.mjs aid-create 1
site/scripts/__tests__/flow-classify.test.mjs aid-review 2
site/scripts/__tests__/flow-classify.test.mjs aid-test 3
site/scripts/__tests__/flow-classify.test.mjs aid-triage 1
site/scripts/__tests__/flow-classify.test.mjs shortcut-engine.md 4
site/scripts/__tests__/flow-compose.test.mjs aid-create-api 10
site/scripts/__tests__/flow-compose.test.mjs aid-document 1
site/scripts/__tests__/flow-compose.test.mjs aid-fix 4
site/scripts/__tests__/flow-compose.test.mjs aid-test 1
site/scripts/__tests__/flow-compose.test.mjs shortcut-engine.md 5
site/scripts/__tests__/flow-engine-core.test.mjs shortcut-engine.md 2
site/scripts/__tests__/flow-extract-dispatch.test.mjs aid-deploy 1
site/scripts/__tests__/flow-extract-dispatch.test.mjs aid-describe 12
site/scripts/__tests__/flow-extract-dispatch.test.mjs aid-execute 3
site/scripts/__tests__/flow-extract-dispatch.test.mjs aid-monitor 1
site/scripts/__tests__/flow-extract-dispatch.test.mjs aid-plan 1
site/scripts/__tests__/flow-extract-dispatch.test.mjs aid-specify 2
site/scripts/__tests__/flow-extract-dispatch.test.mjs aid-triage 9
site/scripts/__tests__/flow-extract-engine.test.mjs aid-create-api 6
site/scripts/__tests__/flow-extract-engine.test.mjs aid-fix 1
site/scripts/__tests__/flow-extract-engine.test.mjs shortcut-engine.md 2
site/scripts/__tests__/flow-extract-inline.test.mjs aid-prototype 1
site/scripts/__tests__/flow-extract-inline.test.mjs aid-report 1
site/scripts/__tests__/flow-extract-inline.test.mjs aid-research 1
site/scripts/__tests__/flow-extract-inline.test.mjs aid-review 2
site/scripts/__tests__/flow-extract-inline.test.mjs aid-test 2
site/scripts/__tests__/flow-extract-residual.test.mjs aid-create 1
site/scripts/__tests__/flow-extract-residual.test.mjs aid-deprecate 1
site/scripts/__tests__/flow-extract-residual.test.mjs aid-document 1
site/scripts/__tests__/flow-extract-residual.test.mjs aid-read-ticket 1
site/scripts/__tests__/flow-extract-residual.test.mjs aid-set-connector 1
site/scripts/__tests__/flow-extract-residual.test.mjs aid-unset-connector 1
site/scripts/__tests__/flow-extract-residual.test.mjs aid-update-api 1
site/scripts/__tests__/flow-extract-residual.test.mjs aid-update-ticket 1
site/scripts/__tests__/flow-extract-sibling.test.mjs aid-create 1
site/scripts/__tests__/flow-extract-sibling.test.mjs aid-document 1
site/scripts/__tests__/flow-extract-sibling.test.mjs aid-test 20
site/scripts/__tests__/flow-facade.test.mjs aid-create 4
site/scripts/__tests__/flow-facade.test.mjs aid-describe 6
site/scripts/__tests__/flow-facade.test.mjs aid-review 14
site/scripts/__tests__/flow-graph-doorways.test.mjs aid-create 1
site/scripts/__tests__/flow-graph-doorways.test.mjs aid-create-api 13
site/scripts/__tests__/flow-graph-doorways.test.mjs aid-document 1
site/scripts/__tests__/flow-graph-doorways.test.mjs aid-fix 2
site/scripts/__tests__/flow-graph-doorways.test.mjs aid-test 1
site/scripts/__tests__/flow-graph-doorways.test.mjs shortcut-engine.md 3
site/scripts/__tests__/flow-graph.test.mjs aid-describe 1
site/scripts/__tests__/flow-graph.test.mjs aid-review 3
site/scripts/__tests__/flow-graph.test.mjs aid-test 65
site/scripts/__tests__/flow-graph.test.mjs shortcut-engine.md 2
site/scripts/__tests__/flow-render-mermaid.test.mjs aid-test 1
site/scripts/__tests__/flow-validate.test.mjs aid-test 7
site/scripts/__tests__/gen-reference.test.mjs aid-chat 1
site/scripts/__tests__/gen-reference.test.mjs aid-deploy 1
site/scripts/__tests__/gen-reference.test.mjs aid-describe 1
site/scripts/__tests__/gen-reference.test.mjs aid-execute 1
site/scripts/__tests__/gen-reference.test.mjs aid-monitor 1
site/scripts/__tests__/gen-reference.test.mjs aid-plan 1
site/scripts/__tests__/gen-reference.test.mjs aid-read-ticket 1
site/scripts/__tests__/gen-reference.test.mjs aid-set-connector 1
site/scripts/__tests__/gen-reference.test.mjs aid-specify 1
site/scripts/__tests__/gen-reference.test.mjs aid-triage 1
site/scripts/__tests__/gen-reference.test.mjs aid-unset-connector 1
site/scripts/__tests__/gen-reference.test.mjs aid-update-ticket 1
site/scripts/__tests__/gen-reference.test.mjs shortcut-catalog.yml 1
site/scripts/__tests__/gen-reference.test.mjs shortcut-engine.md 1
site/scripts/__tests__/gen-skills-index.test.mjs aid-deploy 3
site/scripts/__tests__/gen-skills-index.test.mjs aid-describe 1
site/scripts/__tests__/gen-skills-index.test.mjs aid-monitor 3
site/scripts/__tests__/gen-skills-index.test.mjs aid-plan 1
site/scripts/__tests__/gen-skills-index.test.mjs aid-specify 1
site/scripts/__tests__/gen-skills-index.test.mjs aid-triage 1
site/scripts/__tests__/gen-skills.test.mjs aid-execute 1
site/scripts/__tests__/gen-skills.test.mjs aid-read-ticket 2
site/scripts/__tests__/gen-skills.test.mjs shortcut-catalog.yml 4
site/scripts/__tests__/provenance-appender.test.mjs aid-create-api 3
site/scripts/__tests__/provenance-appender.test.mjs aid-review 9
site/scripts/__tests__/provenance-appender.test.mjs shortcut-engine.md 3
site/scripts/__tests__/provenance-deep-link.test.mjs aid-create-api 1
site/scripts/__tests__/provenance-render-list.test.mjs aid-test 7
site/scripts/__tests__/provenance.test.mjs aid-review 5
site/scripts/__tests__/provenance.test.mjs aid-test 2
site/scripts/__tests__/skill-counts.test.mjs aid-triage 1
site/scripts/__tests__/skills-body.test.mjs aid-create-api 1
site/scripts/__tests__/skills-body.test.mjs aid-review 2
site/scripts/__tests__/skills-catalog.test.mjs aid-deploy 3
site/scripts/__tests__/skills-catalog.test.mjs aid-fix 1
site/scripts/__tests__/skills-catalog.test.mjs aid-monitor 1
site/scripts/__tests__/skills-catalog.test.mjs shortcut-catalog.yml 1
site/scripts/__tests__/skills-discover.test.mjs aid-test 46
site/scripts/__tests__/skills-groups.test.mjs aid-deploy 7
site/scripts/__tests__/skills-groups.test.mjs aid-describe 2
site/scripts/__tests__/skills-groups.test.mjs aid-monitor 4
site/scripts/__tests__/skills-groups.test.mjs aid-plan 8
site/scripts/__tests__/skills-groups.test.mjs aid-specify 1
site/scripts/__tests__/skills-groups.test.mjs aid-triage 4
site/scripts/__tests__/skills-paths.test.mjs aid-create-api 5
site/scripts/__tests__/skills-render-index.test.mjs aid-deploy 1
site/scripts/__tests__/skills-render-index.test.mjs aid-monitor 1
site/scripts/__tests__/skills-render-index.test.mjs aid-triage 2
site/scripts/__tests__/skills-render-index.test.mjs shortcut-catalog.yml 2
site/scripts/__tests__/skills-render-page.test.mjs aid-create-api 2
site/scripts/__tests__/skills-render-page.test.mjs aid-review 3
site/scripts/__tests__/skills-render-value.test.mjs aid-read-ticket 1
site/scripts/__tests__/skills-summary.test.mjs aid-test 10
site/src/lib/__tests__/feature-006-head-gate.test.ts shortcut-catalog.yml 2
site/src/lib/__tests__/feature-006-head-gate.test.ts shortcut-engine.md 1
site/src/lib/__tests__/skill-node-panel.test.ts aid-execute 1
site/src/lib/__tests__/skill-node-panel.test.ts aid-plan 4
site/src/lib/__tests__/skill-node-panel.test.ts shortcut-catalog.yml 1
```
The kept names: `aid-triage` (deleted), `aid-monitor`, `aid-describe`, `aid-update-ticket`,
`aid-specify`, `aid-plan` (bodies), the 16 hand-authored skills and 34 doorways whose `description:`
task-010 rewrites or regenerates, `shortcut-engine.md` and `shortcut-catalog.yml`. Names of skills this
delivery leaves alone (`aid-update-kb`, `aid-create-ticket`, `aid-create-document`, `aid-document-*`,
`aid-test-*`, `aid-define`, `aid-detail`, ...) and synthetic names (`aid-foo`, `aid-x`, ...) are dropped.

A name hit is not always a body read. The owner re-runs the test, and edits or re-points it only where it
reads the part that changes. The known body reads: `flow-classify.test.mjs` (`readRealBody('aid-triage')`),
`flow-extract-dispatch.test.mjs` (the D1 corpus: `aid-describe`, `aid-monitor`, `aid-plan`, `aid-specify`,
`aid-triage`, `aid-execute`, `aid-deploy` bodies), `flow-graph-doorways.test.mjs` and
`flow-extract-engine.test.mjs` (live doorway charts of `aid-create-api` and `aid-fix`),
`gen-skills.test.mjs` and `skills-render-value.test.mjs` (`aid-read-ticket`'s description, S8).

| # | Test | Name or template | Distinct lines | Owner | Why |
|---|---|---|---|---|---|
| 1 | `site/scripts/__tests__/flow-advance.test.mjs` | `aid-test` | 5 | task-010 | description only |
| 2 | `site/scripts/__tests__/flow-classify.test.mjs` | `aid-create` | 1 | task-010 | description only |
| 3 | `site/scripts/__tests__/flow-classify.test.mjs` | `aid-review` | 2 | task-010 | description only |
| 4 | `site/scripts/__tests__/flow-classify.test.mjs` | `aid-test` | 3 | task-010 | description only |
| 5 | `site/scripts/__tests__/flow-classify.test.mjs` | `aid-triage` | 1 | task-009 | folder deleted |
| 6 | `site/scripts/__tests__/flow-classify.test.mjs` | `shortcut-engine.md` | 4 | task-007 | `ticket_ref` Step 4b -> `sources:` |
| 7 | `site/scripts/__tests__/flow-compose.test.mjs` | `aid-create-api` | 10 | task-010 | description through the builder (generated doorway) |
| 8 | `site/scripts/__tests__/flow-compose.test.mjs` | `aid-document` | 1 | task-010 | description only |
| 9 | `site/scripts/__tests__/flow-compose.test.mjs` | `aid-fix` | 4 | task-010 | description only |
| 10 | `site/scripts/__tests__/flow-compose.test.mjs` | `aid-test` | 1 | task-010 | description only |
| 11 | `site/scripts/__tests__/flow-compose.test.mjs` | `shortcut-engine.md` | 5 | task-007 | `ticket_ref` Step 4b -> `sources:` |
| 12 | `site/scripts/__tests__/flow-engine-core.test.mjs` | `shortcut-engine.md` | 2 | task-007 | `ticket_ref` Step 4b -> `sources:` |
| 13 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `aid-deploy` | 1 | task-010 | description only |
| 14 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `aid-describe` | 12 | task-009 | body: triage mentions; task-007 edits `references/state-first-run.md` first |
| 15 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `aid-execute` | 3 | task-010 | description only |
| 16 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `aid-monitor` | 1 | task-008 | body: Default executor, ROUTE row, routing; description later by task-010 |
| 17 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `aid-plan` | 1 | task-007 | `references/first-run-loop.md`; description later by task-010 |
| 18 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `aid-specify` | 2 | task-007 | `references/state-initialize.md`; description later by task-010 |
| 19 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `aid-triage` | 9 | task-009 | folder deleted |
| 20 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | `aid-create-api` | 6 | task-010 | description through the builder (generated doorway) |
| 21 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | `aid-fix` | 1 | task-010 | description only |
| 22 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | `shortcut-engine.md` | 2 | task-007 | `ticket_ref` Step 4b -> `sources:` |
| 23 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `aid-prototype` | 1 | task-010 | description only |
| 24 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `aid-report` | 1 | task-010 | description only |
| 25 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `aid-research` | 1 | task-010 | description only |
| 26 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `aid-review` | 2 | task-010 | description only |
| 27 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `aid-test` | 2 | task-010 | description only |
| 28 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `aid-create` | 1 | task-010 | description only |
| 29 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `aid-deprecate` | 1 | task-010 | description through the builder (generated doorway) |
| 30 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `aid-document` | 1 | task-010 | description only |
| 31 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `aid-read-ticket` | 1 | task-010 | description only |
| 32 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `aid-set-connector` | 1 | task-010 | description only |
| 33 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `aid-unset-connector` | 1 | task-010 | description only |
| 34 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `aid-update-api` | 1 | task-010 | description through the builder (generated doorway) |
| 35 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `aid-update-ticket` | 1 | task-007 | body: `attachment` part |
| 36 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `aid-create` | 1 | task-010 | description only |
| 37 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `aid-document` | 1 | task-010 | description only |
| 38 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `aid-test` | 20 | task-010 | description only |
| 39 | `site/scripts/__tests__/flow-facade.test.mjs` | `aid-create` | 4 | task-010 | description only |
| 40 | `site/scripts/__tests__/flow-facade.test.mjs` | `aid-describe` | 6 | task-009 | body: triage mentions; task-007 edits `references/state-first-run.md` first |
| 41 | `site/scripts/__tests__/flow-facade.test.mjs` | `aid-review` | 14 | task-010 | description only |
| 42 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `aid-create` | 1 | task-010 | description only |
| 43 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `aid-create-api` | 13 | task-010 | description through the builder (generated doorway) |
| 44 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `aid-document` | 1 | task-010 | description only |
| 45 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `aid-fix` | 2 | task-010 | description only |
| 46 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `aid-test` | 1 | task-010 | description only |
| 47 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `shortcut-engine.md` | 3 | task-007 | `ticket_ref` Step 4b -> `sources:` |
| 48 | `site/scripts/__tests__/flow-graph.test.mjs` | `aid-describe` | 1 | task-009 | body: triage mentions; task-007 edits `references/state-first-run.md` first |
| 49 | `site/scripts/__tests__/flow-graph.test.mjs` | `aid-review` | 3 | task-010 | description only |
| 50 | `site/scripts/__tests__/flow-graph.test.mjs` | `aid-test` | 65 | task-010 | description only |
| 51 | `site/scripts/__tests__/flow-graph.test.mjs` | `shortcut-engine.md` | 2 | task-007 | `ticket_ref` Step 4b -> `sources:` |
| 52 | `site/scripts/__tests__/flow-render-mermaid.test.mjs` | `aid-test` | 1 | task-010 | description only |
| 53 | `site/scripts/__tests__/flow-validate.test.mjs` | `aid-test` | 7 | task-010 | description only |
| 54 | `site/scripts/__tests__/gen-reference.test.mjs` | `aid-chat` | 1 | task-010 | description only |
| 55 | `site/scripts/__tests__/gen-reference.test.mjs` | `aid-deploy` | 1 | task-010 | description only |
| 56 | `site/scripts/__tests__/gen-reference.test.mjs` | `aid-describe` | 1 | task-009 | body: triage mentions; task-007 edits `references/state-first-run.md` first |
| 57 | `site/scripts/__tests__/gen-reference.test.mjs` | `aid-execute` | 1 | task-010 | description only |
| 58 | `site/scripts/__tests__/gen-reference.test.mjs` | `aid-monitor` | 1 | task-008 | body: Default executor, ROUTE row, routing; description later by task-010 |
| 59 | `site/scripts/__tests__/gen-reference.test.mjs` | `aid-plan` | 1 | task-007 | `references/first-run-loop.md`; description later by task-010 |
| 60 | `site/scripts/__tests__/gen-reference.test.mjs` | `aid-read-ticket` | 1 | task-010 | description only |
| 61 | `site/scripts/__tests__/gen-reference.test.mjs` | `aid-set-connector` | 1 | task-010 | description only |
| 62 | `site/scripts/__tests__/gen-reference.test.mjs` | `aid-specify` | 1 | task-007 | `references/state-initialize.md`; description later by task-010 |
| 63 | `site/scripts/__tests__/gen-reference.test.mjs` | `aid-triage` | 1 | task-009 | folder deleted |
| 64 | `site/scripts/__tests__/gen-reference.test.mjs` | `aid-unset-connector` | 1 | task-010 | description only |
| 65 | `site/scripts/__tests__/gen-reference.test.mjs` | `aid-update-ticket` | 1 | task-007 | body: `attachment` part |
| 66 | `site/scripts/__tests__/gen-reference.test.mjs` | `shortcut-catalog.yml` | 1 | task-009 | two comment lines only (22, 903) |
| 67 | `site/scripts/__tests__/gen-reference.test.mjs` | `shortcut-engine.md` | 1 | task-007 | `ticket_ref` Step 4b -> `sources:` |
| 68 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `aid-deploy` | 3 | task-010 | description only |
| 69 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `aid-describe` | 1 | task-009 | body: triage mentions; task-007 edits `references/state-first-run.md` first |
| 70 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `aid-monitor` | 3 | task-008 | body: Default executor, ROUTE row, routing; description later by task-010 |
| 71 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `aid-plan` | 1 | task-007 | `references/first-run-loop.md`; description later by task-010 |
| 72 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `aid-specify` | 1 | task-007 | `references/state-initialize.md`; description later by task-010 |
| 73 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `aid-triage` | 1 | task-009 | folder deleted |
| 74 | `site/scripts/__tests__/gen-skills.test.mjs` | `aid-execute` | 1 | task-010 | description only |
| 75 | `site/scripts/__tests__/gen-skills.test.mjs` | `aid-read-ticket` | 2 | task-010 | description only |
| 76 | `site/scripts/__tests__/gen-skills.test.mjs` | `shortcut-catalog.yml` | 4 | task-009 | two comment lines only (22, 903) |
| 77 | `site/scripts/__tests__/provenance-appender.test.mjs` | `aid-create-api` | 3 | task-010 | description through the builder (generated doorway) |
| 78 | `site/scripts/__tests__/provenance-appender.test.mjs` | `aid-review` | 9 | task-010 | description only |
| 79 | `site/scripts/__tests__/provenance-appender.test.mjs` | `shortcut-engine.md` | 3 | task-007 | `ticket_ref` Step 4b -> `sources:` |
| 80 | `site/scripts/__tests__/provenance-deep-link.test.mjs` | `aid-create-api` | 1 | task-010 | description through the builder (generated doorway) |
| 81 | `site/scripts/__tests__/provenance-render-list.test.mjs` | `aid-test` | 7 | task-010 | description only |
| 82 | `site/scripts/__tests__/provenance.test.mjs` | `aid-review` | 5 | task-010 | description only |
| 83 | `site/scripts/__tests__/provenance.test.mjs` | `aid-test` | 2 | task-010 | description only |
| 84 | `site/scripts/__tests__/skill-counts.test.mjs` | `aid-triage` | 1 | task-009 | folder deleted |
| 85 | `site/scripts/__tests__/skills-body.test.mjs` | `aid-create-api` | 1 | task-010 | description through the builder (generated doorway) |
| 86 | `site/scripts/__tests__/skills-body.test.mjs` | `aid-review` | 2 | task-010 | description only |
| 87 | `site/scripts/__tests__/skills-catalog.test.mjs` | `aid-deploy` | 3 | task-010 | description only |
| 88 | `site/scripts/__tests__/skills-catalog.test.mjs` | `aid-fix` | 1 | task-010 | description only |
| 89 | `site/scripts/__tests__/skills-catalog.test.mjs` | `aid-monitor` | 1 | task-008 | body: Default executor, ROUTE row, routing; description later by task-010 |
| 90 | `site/scripts/__tests__/skills-catalog.test.mjs` | `shortcut-catalog.yml` | 1 | task-009 | two comment lines only (22, 903) |
| 91 | `site/scripts/__tests__/skills-discover.test.mjs` | `aid-test` | 46 | task-010 | description only |
| 92 | `site/scripts/__tests__/skills-groups.test.mjs` | `aid-deploy` | 7 | task-010 | description only |
| 93 | `site/scripts/__tests__/skills-groups.test.mjs` | `aid-describe` | 2 | task-009 | body: triage mentions; task-007 edits `references/state-first-run.md` first |
| 94 | `site/scripts/__tests__/skills-groups.test.mjs` | `aid-monitor` | 4 | task-008 | body: Default executor, ROUTE row, routing; description later by task-010 |
| 95 | `site/scripts/__tests__/skills-groups.test.mjs` | `aid-plan` | 8 | task-007 | `references/first-run-loop.md`; description later by task-010 |
| 96 | `site/scripts/__tests__/skills-groups.test.mjs` | `aid-specify` | 1 | task-007 | `references/state-initialize.md`; description later by task-010 |
| 97 | `site/scripts/__tests__/skills-groups.test.mjs` | `aid-triage` | 4 | task-009 | folder deleted |
| 98 | `site/scripts/__tests__/skills-paths.test.mjs` | `aid-create-api` | 5 | task-010 | description through the builder (generated doorway) |
| 99 | `site/scripts/__tests__/skills-render-index.test.mjs` | `aid-deploy` | 1 | task-010 | description only |
| 100 | `site/scripts/__tests__/skills-render-index.test.mjs` | `aid-monitor` | 1 | task-008 | body: Default executor, ROUTE row, routing; description later by task-010 |
| 101 | `site/scripts/__tests__/skills-render-index.test.mjs` | `aid-triage` | 2 | task-009 | folder deleted |
| 102 | `site/scripts/__tests__/skills-render-index.test.mjs` | `shortcut-catalog.yml` | 2 | task-009 | two comment lines only (22, 903) |
| 103 | `site/scripts/__tests__/skills-render-page.test.mjs` | `aid-create-api` | 2 | task-010 | description through the builder (generated doorway) |
| 104 | `site/scripts/__tests__/skills-render-page.test.mjs` | `aid-review` | 3 | task-010 | description only |
| 105 | `site/scripts/__tests__/skills-render-value.test.mjs` | `aid-read-ticket` | 1 | task-010 | description only |
| 106 | `site/scripts/__tests__/skills-summary.test.mjs` | `aid-test` | 10 | task-010 | description only |
| 107 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | `shortcut-catalog.yml` | 2 | task-009 | two comment lines only (22, 903) |
| 108 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | `shortcut-engine.md` | 1 | task-007 | `ticket_ref` Step 4b -> `sources:` |
| 109 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `aid-execute` | 1 | task-010 | description only |
| 110 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `aid-plan` | 4 | task-007 | `references/first-run-loop.md`; description later by task-010 |
| 111 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `shortcut-catalog.yml` | 1 | task-009 | two comment lines only (22, 903) |

111 hit rows, 0 empty owner cells.

## KB sources (G17)

Every `.aid/knowledge/` line that cites a file or folder this delivery deletes, moves or renames
(`canonical/skills/aid-triage/`, `canonical/agents/aid-orchestrator/`, `.aid/design/skill-routing.md`,
`tests/canonical/test-triage-routing.sh`, and the retired skill's page and flow). Only a frontmatter
`sources:` entry is fixed by the deleting task (AD14 of `test-artifact-discipline.sh`); prose lines are the
delivery's DOCUMENT tasks'.

```bash
git grep -n -e 'canonical/skills/aid-triage' -e 'canonical/agents/aid-orchestrator' -e '.aid/design/skill-routing.md' \
  -e 'tests/canonical/test-triage-routing.sh' -e 'site/src/content/docs/skills/aid-triage.md' \
  -e 'site/src/data/skill-flows/aid-triage.flow.json' 581a4335 -- .aid/knowledge/
```
```text
581a4335:.aid/knowledge/architecture.md:244:CONFIRMED in `canonical/aid/templates/shortcut-engine.md`, `canonical/skills/aid-triage/SKILL.md`,
581a4335:.aid/knowledge/capability-inventory.md:211:`/aid-triage` (`canonical/skills/aid-triage/SKILL.md`) is a **stateless, write-free,
581a4335:.aid/knowledge/decisions.md:97:| D21 | `/aid-triage` extracted as a suggest-only router | Accepted | `canonical/skills/aid-triage/SKILL.md`; feature-014 |
581a4335:.aid/knowledge/decisions.md:437:  standalone `canonical/skills/aid-triage/SKILL.md` — a **stateless, write-free, suggest-only**
581a4335:.aid/knowledge/decisions.md:450:- **Status:** Accepted. CONFIRMED `canonical/skills/aid-triage/SKILL.md` and
581a4335:.aid/knowledge/domain-glossary.md:13:  - canonical/skills/aid-triage/SKILL.md
581a4335:.aid/knowledge/domain-glossary.md:446:(`canonical/skills/aid-triage/SKILL.md`) — a **stateless, write-free, suggest-only** entry helper
581a4335:.aid/knowledge/domain-glossary.md:462:- `canonical/skills/aid-triage/SKILL.md` ("Suggest-only router", "State machine: INTAKE -> CLASSIFY -> SUGGEST -> HALT")
581a4335:.aid/knowledge/pipeline-contracts.md:80:  `canonical/aid/templates/shortcut-engine.md`; `canonical/skills/aid-triage/SKILL.md`;
```
| # | File | Line | Where | Owner | Note |
|---|---|---|---|---|---|
| 1 | `.aid/knowledge/architecture.md` | 244 | prose | task-013 | Re-pointed by the DOCUMENT task |
| 2 | `.aid/knowledge/capability-inventory.md` | 211 | prose | task-013 | Re-pointed by the DOCUMENT task |
| 3 | `.aid/knowledge/decisions.md` | 97 | prose | task-012 | Re-pointed by the DOCUMENT task |
| 4 | `.aid/knowledge/decisions.md` | 437 | prose | task-012 | Re-pointed by the DOCUMENT task |
| 5 | `.aid/knowledge/decisions.md` | 450 | prose | task-012 | Re-pointed by the DOCUMENT task |
| 6 | `.aid/knowledge/domain-glossary.md` | 13 | frontmatter `sources:` | task-009 | Remove the entry in the task that deletes the folder (AD14); the prose stays for task-013 |
| 7 | `.aid/knowledge/domain-glossary.md` | 446 | prose | task-013 | Re-pointed by the DOCUMENT task |
| 8 | `.aid/knowledge/domain-glossary.md` | 462 | prose | task-013 | Re-pointed by the DOCUMENT task |
| 9 | `.aid/knowledge/pipeline-contracts.md` | 80 | prose | task-013 | Re-pointed by the DOCUMENT task |

The `canonical/agents/aid-orchestrator/` and `.aid/design/skill-routing.md` patterns find no KB line; no `sources:` entry cites them.

## Site generator sources (G19)

Site script sources outside `__tests__` that name the skill this delivery retires. No skill is renamed in
this delivery, and no site script names the `aid-orchestrator` agent (`git grep -nE 'aid-orchestrator([^a-z-]|$)' 581a4335 -- site/scripts/ ':!site/scripts/__tests__'` prints nothing).

```bash
git grep -nE 'aid-triage([^a-z-]|$)' 581a4335 -- site/scripts/ ':!site/scripts/__tests__'
```
```text
581a4335:site/scripts/.skills-manifest.json:353:      "src": "canonical/skills/aid-triage/SKILL.md",
581a4335:site/scripts/.skills-manifest.json:354:      "dest": "site/src/content/docs/skills/aid-triage.md"
581a4335:site/scripts/.skills-manifest.json:545:    "site/src/content/docs/skills/aid-triage.md",
581a4335:site/scripts/.skills-manifest.json:918:      "src": "canonical/skills/aid-triage/SKILL.md",
581a4335:site/scripts/.skills-manifest.json:919:      "dest": "site/src/data/skill-flows/aid-triage.flow.json"
581a4335:site/scripts/gen-reference.mjs:141:// /aid-triage's benefit; the maintainer build helper skips generating a
581a4335:site/scripts/gen-reference.mjs:221:    `user-initiated run after approval. Not sure which shortcut fits your change? \`/aid-triage\` reads ` +
581a4335:site/scripts/gen-reference.mjs:232:  // Expected skill-directory set = the curated skills (which include `aid-triage`, plus
581a4335:site/scripts/skills/curated-roster.mjs:56:      { name: 'aid-triage' },
581a4335:site/scripts/skills/groups.mjs:36://   - aid-triage is Support (first in group), NOT Definition.
581a4335:site/scripts/skills/groups.mjs:68:      'aid-triage',
581a4335:site/scripts/skills/render-index.mjs:173:  // still groups `aid-triage` under Definition, and is still what docs/aid-methodology.md
581a4335:site/scripts/skills/skill-counts.mjs:26: * `/aid-triage` is the suggest-only router and `/aid-ask` is the standalone Q&A skill
581a4335:site/scripts/skills/skill-counts.mjs:30: * the README and methodology framing of "N classic + /aid-triage + /aid-ask".
581a4335:site/scripts/skills/skill-counts.mjs:37:const NON_CLASSIC_CURATED = ['aid-triage', 'aid-ask'];
581a4335:site/scripts/skills/skill-counts.mjs:43: * @property {number}   classic      Curated minus `/aid-triage` and `/aid-ask`.
```
| # | File | Lines | Owner | Note |
|---|---|---|---|---|
| 1 | `site/scripts/.skills-manifest.json` | 353, 354, 545, 918, 919 | task-009 | Generated: regenerated after the deletion (not hand-edited) |
| 2 | `site/scripts/gen-reference.mjs` | 141, 221, 232 | task-009 | Line 221 renders the `/aid-triage` sentence of `reference/skills.md`; 141 and 232 are comments |
| 3 | `site/scripts/skills/curated-roster.mjs` | 56 | task-009 | The roster entry; `aid-orchestrate` takes the first Support place (Q134 D6) |
| 4 | `site/scripts/skills/groups.mjs` | 36, 68 | task-009 | Support group membership and its comment |
| 5 | `site/scripts/skills/render-index.mjs` | 173 | task-009 | Comment |
| 6 | `site/scripts/skills/skill-counts.mjs` | 26, 30, 37, 43 | task-009 | `NON_CLASSIC_CURATED` and its comments |

## Suites that read deleted paths (G6 pre-run)

task-008 and task-009 each re-run this at their own base; this is the result at task-001's base, so
they can compare.

```bash
for p in canonical/agents/aid-orchestrator .aid/design/skill-routing.md canonical/skills/aid-triage \
         tests/canonical/test-triage-routing.sh site/src/content/docs/skills/aid-triage.md \
         site/src/data/skill-flows/aid-triage.flow.json; do
  echo "## $p"; git grep -l -e "$p" -e "$p/" 581a4335 -- tests/ site/
done
```
```text
## canonical/agents/aid-orchestrator
581a4335:site/src/content/docs/reference/agents.md
## .aid/design/skill-routing.md
## canonical/skills/aid-triage
581a4335:site/scripts/.skills-manifest.json
581a4335:site/scripts/__tests__/flow-extract-dispatch.test.mjs
581a4335:site/src/content/docs/skills/aid-triage.md
581a4335:site/src/data/skill-flows/aid-triage.flow.json
581a4335:tests/canonical/test-triage-routing.sh
## tests/canonical/test-triage-routing.sh
581a4335:tests/canonical/test-triage-routing.sh
## site/src/content/docs/skills/aid-triage.md
581a4335:site/scripts/.skills-manifest.json
## site/src/data/skill-flows/aid-triage.flow.json
581a4335:site/scripts/.skills-manifest.json
```
| # | Deleted path | Reader | Owner | Note |
|---|---|---|---|---|
| 1 | `canonical/agents/aid-orchestrator` | `site/src/content/docs/reference/agents.md` | task-008 | Generated; regenerated by `gen:reference` |
| 2 | `canonical/skills/aid-triage` | `site/scripts/.skills-manifest.json` | task-009 | Generated |
| 3 | `canonical/skills/aid-triage` | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-009 | Reads the real body (line 649 asserts the source path) |
| 4 | `canonical/skills/aid-triage` | `site/src/content/docs/skills/aid-triage.md` | task-009 | `git rm` (G18) |
| 5 | `canonical/skills/aid-triage` | `site/src/data/skill-flows/aid-triage.flow.json` | task-009 | `git rm` (G18) |
| 6 | `canonical/skills/aid-triage` | `tests/canonical/test-triage-routing.sh` | task-009 | Deleted |
| 7 | `tests/canonical/test-triage-routing.sh` | `tests/canonical/test-triage-routing.sh` | task-009 | Itself |
| 8 | `site/src/content/docs/skills/aid-triage.md` | `site/scripts/.skills-manifest.json` | task-009 | Generated |
| 9 | `site/src/data/skill-flows/aid-triage.flow.json` | `site/scripts/.skills-manifest.json` | task-009 | Generated |

The by-path search misses suites that build the path from the name (`'aid-triage'` with
`join(...)`, `readRealBody('aid-triage')`); S1 and the G11 table list them. `tests/coverage-baseline.tsv`
also holds the `test-triage-routing.sh` TR rows (lines 6287 to 6321), class baseline.

## Skill owner table (G2)

Built from the full listing `ls canonical/skills/*/SKILL.md` at the base (112 lines), one row per skill,
in the order `ls` printed (the shell's collation). `Kind` comes from the `GENERATED by generate-profile/scripts/build-shortcut-skills.py`
marker and the `shortcut-catalog.yml` rows. `Owner` names the task of this delivery that owns the
skill's edits; where a second task also edits it, `Also edited by` says so. `aid-orchestrate` is not on
disk at the base; task-006 creates it with the description REQUIREMENTS.md § 11 Feature 001
`##### 3. Components` gives verbatim, which already has the what/when shape.

```bash
ls canonical/skills/*/SKILL.md | wc -l    # 112 at the base
```
| # | Skill | Kind | S9-exempt | `description:` in this delivery | Owner | Also edited by |
|---|---|---|---|---|---|---|
| 1 | `aid-ask` | hand-authored (catalog `repurpose` row) | yes (F004c) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 2 | `aid-brainstorm` | hand-authored (catalog `repurpose` row) | no | task-010 rewrites it to the what/when shape | task-010 | -- |
| 3 | `aid-chat` | hand-authored (curated, no catalog row) | no | task-010 rewrites it to the what/when shape | task-010 | -- |
| 4 | `aid-config` | hand-authored (curated, no catalog row) | yes (F009a) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 5 | `aid-create-api` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 6 | `aid-create-architecture` | hand-authored (catalog `repurpose` row) | yes (F004e) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 7 | `aid-create-backlog` | hand-authored (catalog `repurpose` row) | yes (F004e) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 8 | `aid-create-cicd` | hand-authored (catalog `repurpose` row) | yes (F004e) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 9 | `aid-create-cli` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 10 | `aid-create-config` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 11 | `aid-create-dashboard` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 12 | `aid-create-data-model` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 13 | `aid-create-data-pipeline` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 14 | `aid-create-diagram` | hand-authored (catalog `repurpose` row) | yes (F009b) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 15 | `aid-create-document` | hand-authored (catalog `repurpose` row) | yes (F009b) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 16 | `aid-create-infra` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 17 | `aid-create-integration` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 18 | `aid-create-job` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 19 | `aid-create-messaging` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 20 | `aid-create-mvp` | hand-authored (catalog `repurpose` row) | yes (F004e) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 21 | `aid-create-roadmap` | hand-authored (catalog `repurpose` row) | yes (F004e) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 22 | `aid-create-stack` | hand-authored (catalog `repurpose` row) | yes (F004e) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 23 | `aid-create-test` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 24 | `aid-create-testing-strategy` | hand-authored (catalog `repurpose` row) | yes (F004e) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 25 | `aid-create-theme` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 26 | `aid-create-ticket` | hand-authored (curated, no catalog row) | yes (F009b) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 27 | `aid-create-ui` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 28 | `aid-create` | generated doorway | no | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited | task-010 | -- |
| 29 | `aid-define` | hand-authored (curated, no catalog row) | yes (F005) | S9-exempt: F005 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 30 | `aid-deploy` | hand-authored (catalog `repurpose` row) | no | task-010 rewrites it to the what/when shape | task-010 | -- |
| 31 | `aid-deprecate` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 32 | `aid-describe` | hand-authored (curated, no catalog row) | yes (F003a) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | task-009 | task-007 (`references/state-first-run.md` Step 3b, `ticket_ref` -> `sources:`) |
| 33 | `aid-design-api` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 34 | `aid-design-architecture` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 35 | `aid-design-backlog` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 36 | `aid-design-cicd` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 37 | `aid-design-cli` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 38 | `aid-design-config` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 39 | `aid-design-dashboard` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 40 | `aid-design-data-model` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 41 | `aid-design-data-pipeline` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 42 | `aid-design-document` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 43 | `aid-design-infra` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 44 | `aid-design-integration` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 45 | `aid-design-job` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 46 | `aid-design-messaging` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 47 | `aid-design-mvp` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 48 | `aid-design-roadmap` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 49 | `aid-design-stack` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 50 | `aid-design-test` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 51 | `aid-design-testing-strategy` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 52 | `aid-design-theme` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 53 | `aid-design-ui` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 54 | `aid-design` | hand-authored (catalog `repurpose` row) | yes (F003b) | S9-exempt: F003 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 55 | `aid-detail` | hand-authored (curated, no catalog row) | yes (F006) | S9-exempt: F006 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 56 | `aid-discover` | hand-authored (curated, no catalog row) | yes (F004a) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 57 | `aid-document-architecture` | hand-authored (catalog `repurpose` row) | yes (F009b) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 58 | `aid-document-changelog` | hand-authored (catalog `repurpose` row) | yes (F009b) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 59 | `aid-document-decision` | hand-authored (catalog `repurpose` row) | yes (F009b) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 60 | `aid-document-guideline` | hand-authored (catalog `repurpose` row) | yes (F009b) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 61 | `aid-document-runbook` | hand-authored (catalog `repurpose` row) | yes (F009b) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 62 | `aid-document-standard` | hand-authored (catalog `repurpose` row) | yes (F009b) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 63 | `aid-document-tutorial` | hand-authored (catalog `repurpose` row) | yes (F009b) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 64 | `aid-document` | hand-authored (catalog `repurpose` row) | no | task-010 rewrites it to the what/when shape | task-010 | -- |
| 65 | `aid-execute` | hand-authored (curated, no catalog row) | no | task-010 rewrites it to the what/when shape | task-010 | -- |
| 66 | `aid-experiment` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 67 | `aid-fix` | generated doorway | no | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited | task-010 | -- |
| 68 | `aid-housekeep` | hand-authored (curated, no catalog row) | yes (F004d) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 69 | `aid-migrate` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 70 | `aid-monitor` | hand-authored (catalog `repurpose` row) | no | task-010 rewrites it to the what/when shape | task-010 | task-008 (Default executor, ROUTE row, routing targets; `references/state-route.md`) |
| 71 | `aid-plan` | hand-authored (curated, no catalog row) | no | task-010 rewrites it to the what/when shape | task-010 | task-007 (`references/first-run-loop.md`) |
| 72 | `aid-prototype-ui` | hand-authored (catalog `repurpose` row) | yes (F009b) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 73 | `aid-prototype` | hand-authored (catalog `repurpose` row) | no | task-010 rewrites it to the what/when shape | task-010 | -- |
| 74 | `aid-read-ticket` | hand-authored (curated, no catalog row) | no | task-010 rewrites it to the what/when shape | task-010 | -- |
| 75 | `aid-refactor` | generated doorway | no | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited | task-010 | -- |
| 76 | `aid-remove` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 77 | `aid-report` | hand-authored (catalog `repurpose` row) | no | task-010 rewrites it to the what/when shape | task-010 | -- |
| 78 | `aid-research` | hand-authored (catalog `repurpose` row) | no | task-010 rewrites it to the what/when shape | task-010 | -- |
| 79 | `aid-review` | hand-authored (catalog `repurpose` row) | no | task-010 rewrites it to the what/when shape | task-010 | -- |
| 80 | `aid-set-connector` | hand-authored (curated, no catalog row) | no | task-010 rewrites it to the what/when shape | task-010 | -- |
| 81 | `aid-specify` | hand-authored (curated, no catalog row) | no | task-010 rewrites it to the what/when shape | task-010 | task-007 (`references/state-initialize.md` Step 3b) |
| 82 | `aid-summarize` | hand-authored (curated, no catalog row) | yes (F004d) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 83 | `aid-test-data-quality` | hand-authored (catalog `repurpose` row) | yes (F009b) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 84 | `aid-test-performance` | hand-authored (catalog `repurpose` row) | yes (F009b) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 85 | `aid-test-security` | hand-authored (catalog `repurpose` row) | yes (F009b) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 86 | `aid-test` | hand-authored (catalog `repurpose` row) | no | task-010 rewrites it to the what/when shape | task-010 | -- |
| 87 | `aid-triage` | hand-authored (curated, no catalog row) | no | none: retired in this delivery (not exempt; it is gone before SG-04 lands) | task-009 | -- |
| 88 | `aid-unset-connector` | hand-authored (curated, no catalog row) | no | task-010 rewrites it to the what/when shape | task-010 | -- |
| 89 | `aid-update-api` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 90 | `aid-update-architecture` | hand-authored (catalog `repurpose` row) | yes (F004e) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 91 | `aid-update-backlog` | hand-authored (catalog `repurpose` row) | yes (F004e) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 92 | `aid-update-cicd` | hand-authored (catalog `repurpose` row) | yes (F004e) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 93 | `aid-update-cli` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 94 | `aid-update-config` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 95 | `aid-update-dashboard` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 96 | `aid-update-data-model` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 97 | `aid-update-data-pipeline` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 98 | `aid-update-document` | hand-authored (catalog `repurpose` row) | yes (F009b) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 99 | `aid-update-infra` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 100 | `aid-update-integration` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 101 | `aid-update-job` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 102 | `aid-update-kb` | hand-authored (curated, no catalog row) | yes (F004b) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 103 | `aid-update-messaging` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 104 | `aid-update-mvp` | hand-authored (catalog `repurpose` row) | yes (F004e) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 105 | `aid-update-roadmap` | hand-authored (catalog `repurpose` row) | yes (F004e) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 106 | `aid-update-stack` | hand-authored (catalog `repurpose` row) | yes (F004e) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 107 | `aid-update-test` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 108 | `aid-update-testing-strategy` | hand-authored (catalog `repurpose` row) | yes (F004e) | S9-exempt: F004 `##### 1. Files and layout` deletes or renames it | no change needed here: S9-exempt, and no delivery-001 task edits it | -- |
| 109 | `aid-update-theme` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 110 | `aid-update-ticket` | hand-authored (curated, no catalog row) | yes (F009b) | S9-exempt: F009 `##### 1. Files and layout` deletes or renames it | task-007 | -- |
| 111 | `aid-update-ui` | generated doorway | yes (F009b) | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited; S9-exempt all the same | task-010 | -- |
| 112 | `aid-update` | generated doorway | no | task-010 regenerates it with `build-shortcut-skills.py` (new `description = (` template); never hand-edited | task-010 | -- |

112 rows, 0 unowned. Owners: no change needed here: 59; task-007: 1; task-009: 2; task-010: 50.

## Delta

Reconciliation of the hit lists above with REQUIREMENTS.md § 11 Feature 001 `##### 5. Migration` (and
`##### 1. Files and layout`) and with the task files of delivery-001.

### D1 Hits the spec's lists omit

| # | Search | Hit | Owner | Why it matters |
|---|---|---|---|---|
| 1 | S1 | `.aid/knowledge/architecture.md`, `capability-inventory.md`, `domain-glossary.md`, `module-map.md`, `pipeline-contracts.md`, `project-structure.md` | task-013 | Not on the "Triage sites" list; the spec's KB bullet covers them, and task-013's file names them |
| 2 | S1 | `.aid/knowledge/decisions.md` (D21, D25, D14) | task-012 | As row 1: in the KB bullet, not the triage list |
| 3 | S1 | `.aid/knowledge/test-landscape.md` (names `test-triage-routing.sh`) | task-018 | As row 1 |
| 4 | S1, G6 | `tests/coverage-baseline.tsv` lines 6287 to 6321 (`test-triage-routing.sh` TR rows; no `aid-triage` string) | baseline, re-recorded at the gate | The removed TR assertions also need their `tests/coverage-accepted-removals.tsv` rows (task-009, Q106 rule) |
| 5 | S2a | `canonical/agents/aid-orchestrator/AGENT.md` | task-008 | In Files and layout (Delete), not in the Migration list |
| 6 | S2a | `site/src/data/skill-flows/aid-monitor.flow.json` line 64 (the ROUTE row) | task-008 | Implied by "the site's ... `aid-monitor` pages"; it is the generated flow, not a page |
| 7 | S2a | `tests/coverage-accepted-removals.tsv` lines 119, 296 | history, left as is | Not named on the orchestrator list |
| 8 | S2b | `.aid/knowledge/module-map.md` line 86 (`canonical/agents/*` (9), "Roles: ... orchestrator ...") | task-013 | Names the agent without the `aid-` prefix |
| 9 | S2b | `tests/windows/Test-AidInstaller.ps1` line 2226 | task-008 | Part of the fixture the spec keeps; no edit |
| 10 | S3, S6 | `tests/canonical/test-ticket-retirement-structural.sh` T090 (the `**Ticket:**` line; no `ticket_ref` string) and `test-connector-consumption-linkage.sh` CL08f | task-003 | Asserts the line task-003 removes |
| 11 | S5 | `tests/canonical/test-connector-skills-structural.sh` ST31 to ST38 | task-002 | Asserts `## Connectors` and its wording, including the pointer to `.aid/runtime/templates/connectors/consumption-protocol.md` (ST35); task-002 must keep them |
| 12 | S5 | `tests/canonical/test-shared-install.sh` lines 161 to 167 (AC-14(a)) | task-002 | sed-edits the summary bullet `- Write only inside the project directory.`; keep that bullet's text byte for byte |
| 13 | S6 | `tests/canonical/test-release.sh` RL02, `test-aid-status-drift.sh`, `test-layout-format-guard.sh` | task-002 | Read or byte-compare `rules.md`; no edit expected (RL02 is copy-reading: `release.sh`) |
| 14 | S7 | `docs/install.md` lines 442 (``112 `aid-`-prefixed skill``) and 470 (``9 `aid-`-prefixed agent``) | task-006 and task-009 (442), task-008 (470) | `test-doc-counts.sh` asserts both. `docs/install.md` is on no spec list and named by no task file; task-006, task-008 and task-009 reach it only through "the phrases `test-doc-counts.sh` asserts in `docs/`" |
| 15 | S7 | `site/src/content/docs/index.mdx` 76, 92; `reference/overview.md` 16; `guides/maintainer.mdx` 237 | task-006, then task-009 | `skill-counts.test.mjs` claim pages. task-006's and task-009's count re-sync names `README.md` and `docs/` only; these hand-written pages need the same +1 / -1. `guides/maintainer.mdx` is on no spec list at all |
| 16 | S7 | `site/scripts/__tests__/gen-reference.test.mjs` lines 251, 255 (`toHaveLength(9)`) | task-008 | task-008's file names the generator's hard-coded count, not this test |
| 17 | S7 | `site/src/content/docs/concepts/overview.md` line 26 ("nine specialist agents") | task-011 | Hand-written page on no list; the agent count changes for good |
| 17a | S7d | `site/src/content/docs/reference/overview.md` line 18 ("All 9 AID pipeline agents") | task-011 | Hand-written page; S1 and S7c give it to task-011 and task-006 for line 16 only. No suite checks agent counts on site pages |
| 17b | S7d | `.claude/skills/generate-profile/SKILL.md` lines 127 ("All 9 canonical agents exist"), 132 ("Expected: 9 directories.") and 295 ("Also: 9 agents") | task-008 | The generator's completeness check would expect 9 agents after task-008 leaves 8. task-009 edits this file only for the curated count (line 96) |
| 17c | S7d | `site/scripts/gen-reference.mjs` line 324 (frontmatter `description: 'All 9 AID pipeline agents ...'`), rendered as `site/src/content/docs/reference/agents.md` line 3 | task-008 | The generator's drift check passes on a stale number, because page and generator agree |
| 17d | S7d | `.aid/knowledge/decisions.md` line 54, the D15 anchor `nine-agents` | task-012 | Follows D15's heading if the amendment retitles it |
| 18 | S7 | `docs/aid-methodology.md` 821, 823, 1398 ("9 specialist agents"), 804 (`Medium tier — 7 default`, the diagram subgraph label) and 830 (`Medium (7 default)`); `docs/diagram-content-reference.md` 111; their synced copies (`concepts/methodology.md` 808, 834, ...) | task-011 | Agent-count and tier-count prose no suite asserts (S7d, S7e) |
| 18a | S7f | The `18 curated` phrases in the `docs/` sources of synced claim pages (`docs/aid-methodology.md` 100, 102; `docs/glossary.md` 9, 54; `docs/repository-structure.md` 22, 77) and on lines task-006 already moves (`docs/diagram-content-reference.md` 24, 105; `docs/install.md` 442) | task-006, then task-009 | S7b listed only the `test-doc-counts.sh` needles on these lines; the synced pages' `18 curated` claims (S7c) come from these sources |
| 19 | S7 | KB agent counts: `architecture.md` 116, 326, 333; `module-map.md` 86; `pipeline-contracts.md` 446 | task-013 | Not named by the KB bullet, which names only D15's count |
| 20 | S7 | `.aid/knowledge/decisions.md` 54, 91, 319, 321 | task-012 | The D15 amendment (agent count) plus the summary row and the other two mentions |
| 21 | S8 | `site/scripts/__tests__/gen-skills.test.mjs` lines 424 to 438 | task-010 | Requires `aid-read-ticket`'s description to keep `` `aid-read-ticket [<connector>:]<ticket-id>` `` |
| 22 | S8 | `skills-summary.test.mjs`, `skills-render-value.test.mjs` | task-010 | Corpus invariants: every `description:` is a folded `description: >` block, and its first sentence fits `SUMMARY_CAP` |
| 23 | S6 | `tests/canonical/test-chat-node-wake.sh` line 507 | task-012 | Reads `decisions.md` from `## D31` to the next `\n## `; the new decision must not land inside D31 |
| 24 | S6 | `tests/canonical/test-writeback-state.sh` line 1749 | task-003 | Copies the real work-state template into a work file and writes it |
| 25 | S6 | `dashboard/reader/tests/test_integration.py` | task-003 | Seeds a scratch work from the real template; `run-all.sh` runs it through `tests/canonical/test-dashboard-reader.sh` (unittest discovery of `dashboard/reader/tests/`) |
| 26 | S6 | `site/scripts/__tests__/skills-render-index.test.mjs` lines 232 to 268 | task-011 | Reads `docs/aid-methodology.md` and checks how it files skills into groups against the index page |
| 27 | S6c | `tests/canonical/test-shared-layout-sources.sh` AC-6 | task-006 | The new `aid-orchestrate/SKILL.md`: no comma in `allowed-tools:`, no `context:` / `agent:` key |
| 28 | G17 | `.aid/knowledge/domain-glossary.md` line 13 (frontmatter `sources:`) | task-009 | AD14 fails once the folder is gone unless the entry goes in the same task |
| 29 | S1 | `.claude/skills/generate-profile/SKILL.md` line 107 | task-009 | History prose naming `aid-triage`; the spec names only the curated count (line 96) |

### D2 Spec-listed or task-listed paths with no hit

| # | Listed path | Listed by | Result | Owner |
|---|---|---|---|---|
| 1 | `.aid/design/README.md` (its mention of `skill-routing.md`) | task-008 | No mention exists (S4): nothing to remove | task-008 |
| 2 | `tests/canonical/test-ascii-only.sh`, `test-ps51-compat.sh`, `test-aid-cli-parity.sh` "where they assert the workflow's text" | task-015 | None reads `installer-tests.yml`; each names it in a comment only (S6 T29). No edit expected; task-015 still runs them. The only suite that reads `.github/workflows/` as a whole is `test-shared-layout-sources.sh` AC-19 (no retired per-tool tree path), so the new `SUITES` entry must not name one | task-015 |
| 3 | `tests/canonical/test-cutover-no-dangling.sh` (Triage sites) | F001 § 5, task-009 | One comment line (88) only; no assertion names `aid-triage`. It also reads `work-state-template.yml` (CND12, S6 T02) | task-009 |
| 4 | `.aid/design/skill-routing.md` inbound references | F001 § 1 | None in the path set (S4); only work-folder files name it | task-008 |
| 5 | `canonical/aid/templates/agent-dispatch-tiering.md` readers | F001 § 5 | No suite reads it (S6 T16); `tests/cost-baseline.tsv` lists it | task-008 |

Every other path the spec's Migration lists name (Triage, Orchestrator and `ticket_ref` sites; the
rules-text suites) has at least one hit above.

### D3 Suites assigned to two tasks that do not depend on each other

Computed from every owner table above (S1 to S8, G11) against the delivery-001 execution graph
(transitive `Depends on` closure). Eight suites have such a pair:

| # | Suite | Independent pair | What each owns there | Order to run |
|---|---|---|---|---|
| 1 | `tests/canonical/test-connector-skills-structural.sh` | task-002, task-007 | task-002: ST31-ST38 (`## Connectors`, ST35 pointer) in `rules.md`; task-007: reads `consumption-protocol.md` (and lists the `connectors/` templates, line 191). No edit expected from either | task-002 (wave 2) first, task-007 (wave 3) re-runs it |
| 2 | `site/scripts/__tests__/gen-skills.test.mjs` | task-002, task-007 | task-002: a false-positive heading match (S5, line 1175), no edit; task-007: regenerated pages | task-002 first, then task-007 (waves 2, 3) |
| 3 | `site/scripts/__tests__/skills-render-index.test.mjs` | task-010, task-011 | task-010: regenerated index cards and descriptions; task-011: `docs/aid-methodology.md` group filing it cross-checks (lines 232-268) | Both are wave 7. Run task-010 first; task-011 runs `(cd site && npm test)` after task-010 has landed |
| 4 | `site/scripts/__tests__/gen-reference.test.mjs` | task-010, task-011 | task-010: skill-name hits (G11); task-011: a synthetic `'README.md'` filter (no edit) | task-010 first, then task-011 (wave 7) |
| 5 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-010, task-013 | task-010: the GENERATED marker constant only (no edit); task-013: DMR05c (edit) | task-010 first, then task-013 (wave 7) |
| 6 | `tests/canonical/test-kb-freshness-check.sh` | task-011, task-018 | Both synthetic (own fixture KB); no edit | task-011 (wave 7) before task-018 (wave 10) |
| 7 | `tests/canonical/test-ps51-compat.sh` | task-011, task-015 | Comment mentions only; no edit | task-011 (wave 7) before task-015 (wave 9) |
| 8 | `tests/windows/Test-AidInstaller.ps1` | task-011, task-015 | Comment mentions only (`docs/install.md`, `installer-tests.yml`); no edit. Its real owners are task-002 (none) and task-008 (keep as is) | task-011 (wave 7) before task-015 (wave 9) |

Tree-wide guards that no owner table assigns, but that every writing task re-runs: `test-artifact-discipline.sh`
(KB frontmatter AD02, AD11, AD14) for task-012, task-013 and task-018; `test-shared-layout-sources.sh`
AC-19 (no retired per-tool tree path in `README.md`, `docs/`, `.github/workflows/`, `.aid/knowledge/`,
`site/`) for task-011, task-012, task-013 and task-015. task-011, task-012 and task-013 share wave 7 with
no dependency among them: run them in task order (011, 012, 013) and re-run the two guards after each.

### D4 Judgement calls

| # | Call | Confidence | Alternative |
|---|---|---|---|
| 1 | S2b: "orchestrator" as the role of whoever dispatches (sub-agent files' "report to Orchestrator", "the main/orchestrator agent", "the orchestrator runs `grade.sh`") is not the agent and needs no edit | LIKELY | Treat the capitalised "Orchestrator" in the seven sub-agent files (`aid-architect`, `aid-developer`, `aid-interviewer`, `aid-operator`, `aid-researcher`, `aid-reviewer`, `aid-tech-writer`) as the agent; then task-008 owns those lines |
| 2 | `aid-config` is S9-exempt: Feature 009 renames it to `aid-configure` | CONFIRMED by F009 line 5654 | REQUIREMENTS.md Feature 002 line 1674 lists `aid-config` among skills "no later feature rebuilds or retires"; that table is about question coverage, and D4 exempts renames. If the maintainer reads it otherwise, `aid-config` moves to task-010 |
| 3 | `aid-update-ticket` and `aid-create-ticket` are S9-exempt: Feature 009 deletes every `aid-update-*` / `aid-create-*` "still on disk" including `ticket` | CONFIRMED by F009 line 5658 | task-007 still edits `aid-update-ticket` (the `attachment` part) in this delivery |
| 4 | The 30 exempt doorways are regenerated by task-010's builder anyway, because the template is shared | CONFIRMED (`build-shortcut-skills.py` has one template) | -- |
| 5 | G11 name hits are owned by the task that changes the named file even where the test only names it | LIKELY | The owner re-runs and edits only where the test reads the changed part |
| 6 | `.aid/knowledge/kb.html` hits are history, left as is (regenerated by the KB build) | CONFIRMED by F001 § 5 "Left as they are" | -- |

## Test step

- **Spawn-free checks:** no `.sh`, `.py` or `.mjs` file changed, so there is nothing to check.
- **Selection, scratch half, live half, site and dashboard runs:** skipped. Every change of this task lies
  under `.aid/works/` (this one file), so the work-folder-only rule applies: no suite and no site or
  dashboard test runs (PLAN.md § "Testing before the resync", "A task that changes only the work folder
  runs no suite"). `select-suites.sh` was not run for it.
- **Result:** no failure; 0 suites run.
