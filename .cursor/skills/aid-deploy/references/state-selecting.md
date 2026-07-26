# State: SELECTING

Eligible deliveries are presented to the user for inclusion in this release; a package file is created.

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
If user cancels → reset work `STATE.md` `## Deploy State` to Idle, stop.

Ask for:
- Version/tag name (suggest based on versioning scheme from KB)
- Package name slug (for the filename: `package-NNN-{slug}.md`)

Create the package file from template (`../../templates/package.md`):
- Fill in: deliveries, deployment type/target from KB, environment from KB
- Determine package number (next sequential after existing packages)
- Save to `.aid/works/{work}/packages/package-NNN-{slug}.md`

Update work `STATE.md` `## Deploy State`: Status → Verifying, Active Package → package-NNN.

**Advance:** **CHAIN** → [State: VERIFYING] (continue inline).
