**Type:** CONFIGURE

**Source:** work-009-refactor -> delivery-001

**Depends on:** task-008

**Scope:**
- The `.aid/` layout version constant, bumped 3 -> 4 in all four documented lockstep carriers
  together (`SPEC.md § L-6` step 1): `bin/aid:116` (`readonly AID_SUPPORTED_FORMAT=3`),
  `bin/aid.ps1:157` (`AidSupportedFormat`), `lib/AidInstallCore.psm1:79`
  (`$script:_AidSupportedFormat`), and the `${AID_SUPPORTED_FORMAT:-3}` fallback in
  `lib/aid-install-core.sh:2124`.
- Two further hardcoded `${AID_SUPPORTED_FORMAT:-3}` fallbacks in `bin/aid`, bumped with them:
  `:2727` (`_aid_scaffold_bare_project`, which writes `format_version` into a fresh `settings.yml`)
  and `:2813` (`aid projects add`'s newer-format refusal). Both are unreachable in production --
  the `readonly` at `:116` wins -- but they exist for the extracted-function unit harnesses, which
  would otherwise compare a repo stamped 4 against a supported 3. The PowerShell side has no
  equivalent (every `bin/aid.ps1` and `lib/AidInstallCore.psm1` site reads the constant), so this
  is bash-only and complete at those two sites.
- The format-4 note is added to the same comment block that already documents formats 2 and 3,
  stating what the breaking layout change is (work-tree state files are YAML `STATE.yml`) and which
  migration step performs it -- the constant's own contract is that it is "bumped ONLY on a
  breaking layout change".
- No behavior change to `_aid_format_gate` (`bin/aid:1987`) itself: its three-way classify
  (repo newer -> refuse with a named error; repo older -> `WARN: ... Run: aid update`, suppressible
  with `AID_NO_MIGRATE=1`; equal -> silent) is already exactly what NFR-8 requires, and inventing a
  new diagnostic surface is out of scope.
- Idempotent by construction (`task-type-rules.md § CONFIGURE`): the constant is a fixed value, so
  applying the change twice yields the same files.
- OUT of this task: the conversion step itself (task-008); converting live works (task-010); the
  parity/migrate suites that assert the stamp (task-015); any release-version change (`VERSION`,
  package manifests) -- the format stamp is independent of the product version.

**Acceptance Criteria:**
- [ ] All four carriers declare 4 and no site still declares 3: a grep for
      `AID_SUPPORTED_FORMAT`, `AidSupportedFormat` and `_AidSupportedFormat` across `bin/` and
      `lib/` shows the value 4 at every site, including all three `${AID_SUPPORTED_FORMAT:-3}`
      fallback defaults (`lib/aid-install-core.sh:2124`, `bin/aid:2727`, `bin/aid:2813`) (SP-12).
- [ ] The format-history comment block documents format 4 alongside 2 and 3, naming the breaking
      change and the migration step that performs it.