# task-009: GENERATE source-populate path

**Type:** IMPLEMENT

**Source:** work-002-external_sources -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Edit `canonical/skills/aid-discover/references/state-generate.md` Step 0b: add a best-effort URL `Accessible` annotation using AID's existing Python (`urllib.request` with a short timeout — zero new dependency), recording `yes` / `unverified` / `unknown`, and WRITE the result back into the `## External Documentation` `Accessible` column; never gate Scout on it (all `url` rows pass through). Local `file` / `directory` `test -r` behavior unchanged.
- Edit Step 1: make the Scout pre-scan skip content-aware — skip only when `project-structure.md` and `external-sources.md` both exist WITH real content; a `Pending`-only `external-sources.md` is treated as missing (KI-008).
- Edit `canonical/skills/aid-discover/references/agent-prompts.md` `## Scout`: extend the prompt to fetch and inventory `url`-type sources (not only file/directory), catalogue every declared URL regardless of fetch outcome, and refresh the `external-sources.md` frontmatter `summary:` / `sources:` (self-heals KI-004/KI-005). Renders to all 5 profiles.

**Acceptance Criteria:**
- [ ] Step 0b annotates each `url` row `yes` / `unverified` / `unknown` via in-toolchain `urllib` (no hard `curl` dependency), writes it back to the `Accessible` column, and never drops a URL on `unverified` / `unknown`
- [ ] Step 1 skips Scout only when both foundation docs exist with real content; a `Pending` `external-sources.md` forces re-inventory
- [ ] The Scout prompt fetches/inventories `url` sources and catalogues every declared URL (records URL + purpose when a fetch is not possible), refreshing the frontmatter `summary:` / `sources:`
- [ ] The changes render identically into all 5 profiles; existing aid-discover suites + dogfood checks pass; build/render passes
- [ ] All §6 quality gates pass
