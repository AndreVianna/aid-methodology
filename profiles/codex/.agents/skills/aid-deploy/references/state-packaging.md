# State: PACKAGING

Release artifacts are produced, release notes generated, KB updates routed, and statuses updated across all six linear packaging steps.

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

**Advance:** Next state is `DONE` — when this state's work completes, router prints `Next: [State: DONE] — run /aid-deploy again` and exits.
