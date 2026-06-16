# Bootstrap Runbook: v1.0/v1.1 Repos -> New Model (per-repo, no scan)

**Scope:** work-001-cli-install-scope / delivery-003
**Applies to:** maintainers bootstrapping existing repos after a CLI upgrade to
the new install-scope model (feature-001 through feature-004 in effect).
**No production code ships here.** Bootstrap is composed from feature-003 (stamp)
and feature-004 (register); this document only covers the procedure.

---

## Background

Earlier CLI versions wrote migration state into a machine-wide marker
(`$AID_HOME/.migrated`) and discovered repos by walking `$HOME`. The new model
removes that scan entirely. Migration state now lives **in each repo**
(`format_version` in `.aid/settings.yml`), and repos are registered incrementally
as the maintainer visits them.

There is **no machine-wide filesystem scan, ever.** The maintainer chooses which
repos to visit and in what order.

---

## 1. How a Repo Gets Bootstrapped (on-encounter flow)

Every time you run any AID command inside a repo, the CLI reads `format_version`
from that repo's `.aid/settings.yml`. A missing or outdated stamp means the repo
needs migration.

**First touch (stamp absent or old):**

1. You `cd <repo>` and run any repo-command (bare `aid`, `aid status`, `aid update`,
   etc.).
2. The CLI detects the missing/old `format_version` and warns you that the repo
   needs migration.
3. You run `aid update` (or confirm when prompted).
4. `__migrate-repo` runs and writes `format_version: 1` into `.aid/settings.yml`.
5. The repo is registered in the registry. The effective path depends on install
   scope, both tiers writing to `$AID_STATE_HOME/registry.yml`:
   - **Per-user install** (`AID_STATE_HOME` == `~/.aid`): the tiers collapse to
     a single file (`~/.aid/registry.yml`); no elevation is needed or attempted.
   - **Global install** (`AID_STATE_HOME` == e.g. `/var/lib/aid`): the shared
     tier also targets `$AID_STATE_HOME/registry.yml`, but the write is guarded
     by an elevation probe. If elevation is declined or unavailable, the shared
     registration is skipped with a warning; the stamp is still written (see
     Note E below). The distinction between the tiers is the elevation probe,
     not a different file path.

**Subsequent touches (carry-forward):**

On every later visit, the CLI reads the current `format_version`, finds it matches
the supported version, and does nothing. There is no re-prompt and no re-write.
The lazy per-repo stamp is the only done-state record; the machine-marker re-prompt
loop cannot recur because there is no machine marker.

---

## 2. Manual First-Pass Recipe (dogfood machine)

This is the procedure for bootstrapping the known repos on the maintainer's own
machine after upgrading the CLI.

**Prerequisites:** the new CLI is installed and in effect (features 001-004 active).

**For each known repo, one at a time:**

1. Open a terminal.
2. Change into the repo directory:

   ```
   cd <repo>
   ```

3. Run the migration command:

   ```
   aid update
   ```

4. Confirm if prompted (the CLI may ask about the shared registry tier).
5. Verify the stamp was written:

   ```
   grep format_version .aid/settings.yml
   ```

   Expected output: `format_version: 1`

6. Move on to the next repo. Repeat from step 2.

**The maintainer chooses the order.** There is no required sequence and no
loop or glob to run. Visit repos one by one.

---

## 3. Dogfood-Machine Targets

On this machine, the repos that need bootstrapping fall into two groups:

**Group 1 -- home-directory projects** (`~/projects/*`):

These were reachable by the old `$HOME`-only scan, but the scan is now removed.
Visit each one using the recipe in section 2.

Example:

```
cd ~/projects/AID && aid update
cd ~/projects/some-other-project && aid update
```

**Group 2 -- shared projects** (`/srv/projects/*`, group `developers`):

These repos were **never seen** by the old scanner because the scan only walked
`$HOME`. They are first-class bootstrap targets under the new model. Visit each
one using the same recipe.

Example:

```
cd /srv/projects/team-tool && aid update
cd /srv/projects/another-repo && aid update
```

For repos outside `~` on a global install, the CLI will ask whether to register
the repo in the shared registry tier. Answer according to whether you want the
repo visible to all users on the machine.

---

## 4. External Upgraders

Upgraders who are not the AID maintainer follow the **identical per-repo
procedure**: for each of their AID-managed repos, run `cd <repo> && aid update`.
There is no separate upgrade path. The lazy stamp catches anything not yet visited
on the next encounter.

---

## 5. How `update self` Differs from the Manual First-Pass

`aid update self` (channel-aware CLI self-upgrade) also triggers migration, but it
operates differently from the manual per-repo recipe above.

| Aspect | Manual first-pass | `update self` |
|---|---|---|
| Scope | Any repo you `cd` into | Already-registered repos only |
| Discovery | You choose the repo | Reads user + shared registries |
| Confirmation | Per-command prompt when relevant | Per-repo confirmation (All / Yes / No / Cancel) |
| Unregistered repos | Stamped + registered on first touch | Not touched; caught lazily on next visit |

**Sequence after a CLI upgrade:**

1. `aid update self` runs the channel-appropriate package-manager command to
   install the new CLI version.
2. `update self` then iterates the repos already in the registries (user and
   shared) and offers per-repo migration with a confirmation prompt.
3. On a fresh upgrade, the registry may be empty -- nothing batch-migrates yet.
4. The maintainer then visits each known repo manually (section 2 above) to
   bootstrap repos that were not yet registered.

The manual first-pass (section 2) is the way to reach repos that were never
registered, including the `/srv/projects/*` group-developers repos that the old
scanner missed.

---

## 6. Edge-Case Notes

**Note A -- Repo with no git:**

AID operates in non-git directories. The stamp is written to `.aid/settings.yml`
normally, and the repo is registered as usual. The only difference is that `.aid/`
is not version-controlled, so the stamp file will not be tracked by git. This is a
note, not a blocker; bootstrap proceeds identically.

**Note B -- Repo with no `.aid/` directory:**

A directory without `.aid/` is not an AID project and is not a bootstrap target.
The CLI offers to initialize one (`aid add`). Do not attempt to bootstrap such a
directory; run `aid add` first if you want to bring it under AID management.

**Note C -- Mid-bootstrap interruption:**

If you stop partway through visiting your repos (power loss, cancellation, etc.),
no global state is corrupted. Each repo's `format_version` stamp is its own
done-state. Repos you have already visited are fully stamped and registered; repos
you have not yet visited are caught on their next encounter (the lazy per-repo
catch-all). Resume the manual first-pass from wherever you left off. A partial
pass is safe to resume at any time.

**Note D -- Already-stamped repo visited again:**

If you accidentally run `aid update` on a repo that is already stamped at the
current `format_version`, the CLI reads the stamp, finds it current, and does
nothing. This is safe and harmless. The stamp is not re-written.

**Note E -- Elevation declined during shared-registry registration:**

On a global install, registering a repo outside `~` into the shared registry may
require elevated privileges. If you decline elevation, or no TTY is available, the
shared registration is **skipped with a warning**. The `format_version` stamp is
still written into the repo's `.aid/settings.yml`; the repo is fully migrated. The
only consequence is that it will not appear in the shared registry (and therefore
not in the dashboard's shared repo list) until a registration is retried. The repo
remains usable immediately.
