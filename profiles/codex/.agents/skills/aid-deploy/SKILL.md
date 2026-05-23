---
name: aid-deploy
description: >
  Package completed deliveries into a release. Selects eligible deliveries,
  verifies the combined build, packages according to project infrastructure,
  generates release notes, and updates artifact statuses. Use when deliveries
  are complete and ready to ship.
allowed-tools: Read, Glob, Grep, Bash, Write
---

# Package & Ship

Package completed deliveries into a release.

## Agents Involved

- **Default executor:** `operator` (orchestrates the release: verifies build, packages artifacts, updates statuses).
- **Specialist consults (optional):** `tech-writer` for release notes / changelog, `devops` if CI/CD configuration changes are needed during release, `reviewer` for final pre-release verification.

## Argument-Hint

```
/aid-deploy work-NNN
```

Required: work ID. If only one work exists, auto-select it.

## Workspace

```
.aid/
  knowledge/
    STATE.md                   ← minimum grade, Q&A (Pending)
.aid/{work}/
  STATE.md                     ← § Deploy Status (current operation status, history)
  packages/                    ← product (one file per release)
    package-001-{name}.md
    package-002-{name}.md
  PLAN.md                      ← deliveries and sequencing
  tasks/                       ← task files with statuses
  features/                    ← feature SPECs
```

## Pre-flight

1. Verify `.aid/` workspace exists.
2. Resolve work directory (same routing as other skills).
3. Read work `STATE.md` `## Deploy Status` section (or create it if absent).
4. Read `PLAN.md` — identify deliveries and their statuses.
5. Check work `STATE.md` `## Tasks Status` — check statuses and grades.
6. If Deploy Status shows an active package → resume from that step (see State Detection).

## State Detection

Read work `STATE.md` `## Deploy Status`:
- **Status: Idle** → Start new package (Step 1)
- **Status: Selecting** → Resume delivery selection (Step 2)
- **Status: Verifying** → Resume verification (Step 3)
- **Status: Packaging** → Resume packaging (Step 4)
- **Status: Done** → Re-run mode (see Re-run section)

Print the state-entry line and "you are here" map:

**IDLE / first run:**
```
[State: IDLE] — No active release; begin assessing eligible deliveries.
aid-deploy  ▸ you are here
  [● IDLE ] → [ SELECTING ] → [ VERIFYING ] → [ PACKAGING ] → [ DONE ]
```

**SELECTING:**
```
[State: SELECTING] — Presenting eligible deliveries for user to include in this release.
aid-deploy  ▸ you are here
  [✓ IDLE ] → [● SELECTING ] → [ VERIFYING ] → [ PACKAGING ] → [ DONE ]
```

**VERIFYING:**
```
[State: VERIFYING] — Running full build, tests, and lint against selected deliveries.
aid-deploy  ▸ you are here
  [✓ IDLE ] → [✓ SELECTING ] → [● VERIFYING ] → [ PACKAGING ] → [ DONE ]
```

**PACKAGING:**
```
[State: PACKAGING] — Producing release artifacts per infrastructure.md § Deployment.
aid-deploy  ▸ you are here
  [✓ IDLE ] → [✓ SELECTING ] → [✓ VERIFYING ] → [● PACKAGING ] → [ DONE ]
```

**DONE:**
```
[State: DONE] — Release complete; all deliveries and tasks marked Shipped.
aid-deploy  ▸ you are here
  [✓ IDLE ] → [✓ SELECTING ] → [✓ VERIFYING ] → [✓ PACKAGING ] → [● DONE ]
```

## Inputs

- `.aid/{work}/PLAN.md` — deliveries, sequencing, success criteria
- `.aid/{work}/tasks/task-*.md` — task statuses and scope
- `.aid/{work}/features/*/SPEC.md` — what was specified
- Work `STATE.md` `## Tasks Status` table — review grades per task
- `known-issues.md` — if exists, check for Critical/High blockers
- **KB via INDEX.md** — Read `.aid/knowledge/INDEX.md`, pull:
  - `infrastructure.md` § Deployment — how to package, where to publish
  - `infrastructure.md` § Source Control — VCS commands, branching strategy
  - `technology-stack.md` § Commands — build, lint, test commands
  - Any other docs INDEX summaries indicate are relevant

## Process

### Step 1: Assess

Read all inputs. Build a picture:
- Which deliveries are complete (all tasks done, all grades ≥ minimum)?
- Which deliveries are partially complete?
- Which deliveries are already shipped (from prior packages)?
- What does infrastructure.md § Deployment say about packaging?
  - Build output type (executable, container, package, library, static site, installer)
  - Target (app store, registry, cloud, on-prem, CDN)
  - CI/CD pipeline (if any)
  - Versioning scheme (semver, calver, custom)
  - Environment details (runtime, config, secrets, dependencies)

If infrastructure.md has no Deployment section or it's a placeholder:
→ Ask the user how this project gets packaged and deployed.
→ Write a Q&A entry to `.aid/knowledge/STATE.md` `## Q&A (Pending)` to capture the answer.

Update work `STATE.md` `## Deploy Status`: Status → Selecting.

### Step 2: Select Deliveries

Present eligible deliveries to the user:

```
Ready to ship:
  ✅ delivery-001: User Authentication (4 tasks, all A or above)
  ✅ delivery-002: API Rate Limiting (3 tasks, all A-)

Already shipped:
  📦 delivery-003: Core Models (in package-001-mvp)

Not ready:
  ⏳ delivery-004: Reporting Dashboard (2/5 tasks complete)

Which deliveries should be in this release? [all ready / select / cancel]
```

If user selects "all ready" → include all eligible.
If user selects specific ones → include only those.
If user cancels → reset work `STATE.md` `## Deploy Status` to Idle, stop.

Ask for:
- Version/tag name (suggest based on versioning scheme from KB)
- Package name slug (for the filename: `package-NNN-{slug}.md`)

Create the package file from template (`../../templates/package.md`):
- Fill in: deliveries, deployment type/target from KB, environment from KB
- Determine package number (next sequential after existing packages)
- Save to `.aid/{work}/packages/package-NNN-{slug}.md`

Update work `STATE.md` `## Deploy Status`: Status → Verifying, Active Package → package-NNN.

### Step 3: Verify

Run full verification against the COMBINED scope of all selected deliveries:

1. **Full build** (not incremental) — using commands from `technology-stack.md § Commands`
2. **Full test suite** — ALL tests, not just ones added by selected deliveries
3. **Lint/format check** — zero warnings

All three must pass. Record results in the package file (Verification section).

▶ full build + test suite + lint starting (~30 s – 5 min depending on project)
If any fails:
- Show the failure clearly
- Ask user: fix here (minor) or loop back to aid-execute (non-trivial)?
- If fixing here: fix → re-verify (max 3 attempts, then must loop to execute)
- If looping back: set work `STATE.md` `## Deploy Status` → Idle, keep package file as Draft
✓ verification done (record actual time) — or ✗ verification failed: {reason}

Update work `STATE.md` `## Deploy Status`: Status → Packaging.

### Step 4: Package

Follow what infrastructure.md § Deployment prescribes. This step varies by project type.

**The agent adapts to what the KB says. Examples:**
- **PR-based:** Create pull request with structured description
- **Container:** Build image, tag with version, push to registry
- **Package/Library:** Build package, publish to registry (npm, NuGet, Maven, PyPI)
- **Installer:** Build installer (MSIX, DMG, deb), sign if configured
- **Static site:** Build, deploy to CDN/hosting
- **Multiple outputs:** Some projects produce more than one — follow KB

Record what was produced in the package file (Deployment section).

If the project type isn't clear from KB → ask the user, route answer to `.aid/knowledge/STATE.md` `## Q&A (Pending)`.

**PR description format (when applicable):**
```markdown
## Release: {version}

### Deliveries
- delivery-NNN: {name} ({task count} tasks)

### Verification
- Build: ✅
- Tests: ✅ {count} pass ({new} new)
- Lint: ✅

### Changes
- Files changed: {count}
- Lines: +{add} / -{del}
```

### Step 5: Release Notes

Generate release notes in the package file (Release Notes section):

```markdown
## What's New
{For each delivery: one paragraph summarizing user-visible changes}

## Technical Changes
{Significant architecture/infrastructure changes, if any}

## Known Issues
{From known-issues.md — anything deferred or unresolved}
```

### Step 6: KB Updates

Check if implementation revealed anything that should update the Knowledge Base:
- New conventions → flag for coding-standards.md
- Architecture changes → flag for architecture.md
- New integrations → flag for integration-map.md
- Tech debt created or resolved → flag for tech-debt.md
- Data model changes → flag for data-model.md
- Deployment process changes → flag for infrastructure.md

For each KB update needed:
→ Write a Q&A entry to `.aid/knowledge/STATE.md` `## Q&A (Pending)`
→ The next aid-discover run will process these
- New features shipped → add to feature-inventory.md (route through `.aid/knowledge/STATE.md` Q&A with category: Features)

⚠️ Do NOT directly edit KB docs from deploy — route through Discovery.

### Step 7: Update Statuses

- Package file → Status: Shipped, add date
- Each included delivery in PLAN.md → add `Shipped in: package-NNN` and date
- Work `STATE.md` `## Tasks Status` rows for included tasks → Status: Shipped
- Work `STATE.md` `## Deploy Status` → Status: Done, Active Package: —
- Work `STATE.md` `## Deploy Status` History → add entry with package name, date, delivery count

### Step 8: Project Management Sync (conditional)

If `infrastructure.md § Project Management` defines a tool:
- Create a Release in the PM tool corresponding to this package
- Update tickets for shipped tasks → mark as Done/Closed
- Link the release to the corresponding Epic (work)

If no PM tool → skip this step.

### Step 9: Summary

Print what was done:
```
📦 package-NNN: {version}
   Deliveries: {count} ({list})
   Tasks: {total count}
   Verification: ✅ Build + Tests + Lint
   Output: {what was produced}
   Package file: .aid/{work}/packages/package-NNN-{slug}.md
   KB updates: {count} Q&A entries routed to .aid/knowledge/STATE.md
```

## Re-run

When work `STATE.md` `## Deploy Status` is Done:

```
[State: RE-RUN] — Prior release found; confirming whether to start a new release or review.
aid-deploy  ▸ you are here
  [✓ IDLE ] → [✓ SELECTING ] → [✓ VERIFYING ] → [✓ PACKAGING ] → [✓ DONE ] → [● RE-RUN ]
```

1. Show package history (from work `STATE.md` `## Deploy Status` History section).
2. Ask: **[1] New release** or **[2] Review package-NNN**?
3. If [1] → reset Status to Idle, proceed with Step 1 (only unshipped deliveries eligible).
4. If [2] → read the package file, compare against current state of tasks/deliveries,
   flag any discrepancies (tasks modified after shipping, new known issues).
   Offer to regenerate release notes if content changed.

## Quality Checklist

- [ ] All selected deliveries have all tasks complete
- [ ] All task grades meet minimum (from `.aid/knowledge/STATE.md` `**Minimum Grade:**`)
- [ ] No Critical/High known-issues unresolved
- [ ] Full build passes (not incremental)
- [ ] Full test suite passes
- [ ] Lint/format clean
- [ ] Package created per infrastructure.md § Deployment
- [ ] Package file saved with all sections filled
- [ ] Release notes generated in package file
- [ ] KB updates routed to `.aid/knowledge/STATE.md` `## Q&A (Pending)` (not direct edits)
- [ ] Delivery and task statuses updated to Shipped in work STATE.md
- [ ] Work STATE.md `## Deploy Status` updated (Done + History entry)
