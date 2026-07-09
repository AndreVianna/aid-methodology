# State: ELICIT

ELICIT captures the project's external sources and tool integrations before GENERATE runs; it
is selected when `## Discovery Elicitation` is absent from `.aid/knowledge/STATE.md`, or present
with `**Resolved:** no` (`SKILL.md` State Detection, **State 0**). Once the block carries
`**Resolved:** yes`, State Detection falls through to States 1–6 for the rest of this cycle —
ELICIT runs exactly once per cycle (`--reset` clears the block to re-run it).

**Worker:** inline (orchestrator-driven), matching the other interactive states in the Dispatch
table (`Q-AND-A`, `APPROVAL`) — ELICIT is a user dialogue, not a sub-agent analysis.

> **P7 exemption.** ELICIT is the one `aid-discover` state exempted from the read-only P7
> principle (`canonical/aid/templates/kb-authoring/principles.md` P7 — "Exception (connector
> sub-phase)"). In addition to the usual `.aid/knowledge/` / `.aid/generated/` / `.aid/.temp/`
> write zone, it may write ONLY within `.aid/connectors/` (this state, below) — the **single**
> P7-exempt write target (STATE.md Q10: AID writes, wires, and manages no host tool's MCP
> configuration, so there is no other write target). GENERATE / REVIEW / Q-AND-A / FIX / APPROVAL
> / DONE remain fully P7-bound; this exemption does not extend to them.

Sources and tools are two differentiated kinds of thing, each with its own shape and its own
home: **sources** are reference knowledge (docs, vendor specs, reference URLs) that land in the
existing `.aid/knowledge/external-sources.md`; **tools** are connectable integrations that land
in the net-new `.aid/connectors/` registry (feature-001's frozen contract). Both branches are
skippable — a project with neither writes only the tracking record below, nothing empty.

**Entry trace** (print once on entry, mirroring the GENERATE Step 0 banner):

```
[ELICIT] Capturing the project's external sources and tool integrations.
         Both branches are SKIPPABLE — a project with none moves past cleanly.
  [E1] External SOURCES  (docs / specs / URLs -> external-sources.md)   -> you confirm  (PAUSE)
  [E2] Tool INTEGRATIONS (connectors -> .aid/connectors/)               -> you confirm  (PAUSE)
  [E3] Record + chain into GENERATE                                     (mechanical)
```

## Step E0: Idempotent re-entry

Before prompting, read the `## Discovery Elicitation` block in `.aid/knowledge/STATE.md`:

```bash
resolved="$(grep -m1 '^\*\*Resolved:\*\*' .aid/knowledge/STATE.md 2>/dev/null \
  | sed 's/^\*\*Resolved:\*\* *//' | tr -d '[:space:]')"
```

- **Block absent** (no `## Discovery Elicitation` heading at all): first pass this cycle —
  nothing has been captured yet. Print the entry trace (above) and proceed to **Step E1**.
- **Block present, `Resolved: no`** (a prior run paused mid-flow — the only mid-pause point is
  E2; E1 always resolves the instant it is answered, in the same pass that then presents E2 and
  pauses there): show what was already captured (`Sources: <value>`) and resume directly at
  **Step E2**, re-presenting its prompt. Re-entry always **overwrites** the block, never appends.
- **Block present, `Resolved: yes`:** unreachable in practice — `SKILL.md` State Detection
  (State 0) already routes past ELICIT once `Resolved: yes`, so the orchestrator would not enter
  this reference doc. Reopening a resolved cycle's elicitation to add/update/remove sources or
  tools is feature-006's reconcile contract (a later delivery), not this state's job; `--reset`
  is the only way this state re-runs after resolving.

## Step E1: External SOURCES branch (PAUSE-FOR-USER-DECISION)

Sources are **reference knowledge** (docs, vendor specs, reference URLs) — distinct from tool
integrations (E2). Present:

```
External sources
----------------
List the external documentation this project depends on — local doc paths, directories, or
reference URLs (vendor specs, API docs). These are catalogued so agents find them before
fetching. This is separate from tool integrations (asked next).

Reply with one entry per line as:  <path-or-url> | file|directory|url | <one-line purpose>
  — or type `skip` if the project has no external sources.
```

**This is a genuine PAUSE-FOR-USER-DECISION.** Stop after presenting; emit the pipeline pause
signal per `canonical/aid/templates/state-machine-chaining.md` §4. Do **not** write the
`## Discovery Elicitation` block yet — nothing has been captured.

**Advance:** Stop here. Re-run `/aid-discover` after answering to continue processing Step E1's
reply (below).

### On resume — process the reply

- **`skip` or empty:** this cycle's `Sources` value is `none`. Write **nothing** to
  `## External Documentation` and do **not** touch `external-sources.md` — it keeps whatever it
  already has (its scaffolded "none provided" baseline on a first cycle). Proceed to "Write the
  mid-pause record" below.
- **Entries provided:** for each line, split on `|` into `path-or-url`, `type`, `purpose`.
  - **Validate `type`** is exactly one of `file` | `directory` | `url` (case-insensitive). A line
    that does not split into exactly three pipe-delimited fields, or whose `type` is anything
    else, or whose path/URL cannot be classified with confidence, is **never guessed** — per the
    skill PRIME DIRECTIVE, write it as a `## Q&A (Pending)` entry (Category `Source`, Impact
    `Medium`, citing the raw line as Context) and exclude it from the rows below until Q-AND-A
    resolves it.
  - **Read the CURRENT `## External Documentation` rows first**, before overwriting, so the
    "did the set change" comparison below has a prior baseline (illustrative):
    ```bash
    prior_paths="$(awk '/^## External Documentation/{f=1;next} /^## /{f=0} f' \
      .aid/knowledge/STATE.md | grep '^|' | tail -n +3 \
      | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2}')"
    ```
  - Write/overwrite the `## External Documentation` table with one row per validated entry:
    `Path` (the `path-or-url`), `Type` (`file`/`directory`/`url`), `Accessible` (`—` — GENERATE
    Step 0b is the sole writer of this column), `Notes` (the one-line purpose).
  - **`external-sources.md` does not exist yet** (the common first-cycle case — `aid-config`
    never creates `.aid/knowledge/`; ELICIT always runs before the first GENERATE): there is
    nothing to reset. GENERATE Step 1 already treats an absent file as needing the pre-scan, so
    the newly-declared sources are picked up on the next run with no action here.
  - **`external-sources.md` already exists** (a later cycle — a prior GENERATE run populated
    it): **compare the new `Path` set against `prior_paths`.** If it differs (any addition,
    removal, or change of path), **reset** the file so the next GENERATE run's pre-scan
    re-inventories it with the new paths: overwrite its body with the `❌ Pending` placeholder —
    the exact marker `state-generate.md` Step 1's content-aware skip already treats as missing
    (KI-008). The precise placeholder shape does not matter beyond containing that marker; Scout
    fully rewrites the doc (including frontmatter) on its next pass regardless. If the set is
    unchanged from the prior cycle, leave the file as-is — nothing to re-inventory.
  - This cycle's `Sources` value is `<N> declared` (N = validated row count).

`ELICIT` never writes `external-sources.md` directly — Scout remains its single writer (STATE.md
Q7 item 4). ELICIT only supplies `## External Documentation` and, on change, the `Pending`
re-inventory signal that Scout's now content-aware Step-1 skip honours.

### Write the mid-pause record, then present E2

In the **same pass** (no re-run needed — this is a CHAIN internal to processing E1's answer),
write the mid-pause shape of `## Discovery Elicitation` (overwrite if present):

```markdown
## Discovery Elicitation

- **Sources:** none | <N> declared
- **Tools:** pending
- **Tools step:** pending
- **Skipped:** none | sources
- **Resolved:** no
- **Elicited:** <date> (run N, paused at E2)
```

Then present **Step E2**'s prompt and PAUSE there.

## Step E2: Tool INTEGRATIONS branch (PAUSE-FOR-USER-DECISION)

Tools are **connectable integrations**, captured into `.aid/connectors/` per feature-001's frozen
contract (`.aid/work-002-external_sources/features/feature-001-integration-store-placement/SPEC.md`
Data Model). Present:

```
Tool integrations
------------------
Declare a tool the project's agents should be able to reach (issue tracker, chat, CI, source
host, docs, container runtime). Pick a preset for sensible defaults, or declare a custom tool.

Presets (from the catalog):  github  gitlab  jira  slack  confluence  notion  jenkins  docker
Reply per tool with:  <preset-id>            (use a preset, then confirm/adjust its fields)
                 or:  custom                 (declare a generic descriptor)
  — type `none` if you have zero tool integrations to declare (an explicit, recorded answer)
  — or type `skip` to bypass this step for now (nothing about tools is recorded either way)
```

**This is a genuine PAUSE-FOR-USER-DECISION.** Stop after presenting.

**Advance:** Stop here. Re-run `/aid-discover` after answering to continue to Step E3.

### The `skip` / `none` distinction (Q9 marker)

E2 offers **three** distinct outcomes, not two — this closes the feature-002 ↔ feature-006 seam
`aid-detail` found (work STATE.md Q9): a bare "skip or empty ⇒ `tools: none`" cannot tell
reconcile (a later delivery, feature-006/task-018) whether it is safe to touch the registry.

| User reply | `Tools step` marker | Meaning | Reconcile (feature-006, later delivery) |
|---|---|---|---|
| `skip` | `SKIPPED` | The step was **not engaged** this cycle — the user said nothing about tools. | Declared-set is **undefined** → **no-op**, registry untouched (the safe default). |
| `none` | `DECLARED-EMPTY` | The step **was engaged** and the user affirmatively declared **zero** tools. | Declared-set = `{}` → **REMOVE** all persisted connectors (purge the local secret for aid-managed connectors + delete the descriptor; no unwire step — Q10 amends Q9/supersedes Q8). |
| `<preset-id>` / `custom` (one or more) | `ENGAGED` | The step was engaged; N ≥ 1 tools declared. | Declared-set = the N tools. |

This state only ever produces the marker — reconcile's branching on it is out of this state's
scope (feature-006, a later delivery).

### On resume — branch per reply

- **`skip`:** `**Tools:** none`, `**Tools step:** SKIPPED`. Create **nothing** under
  `.aid/connectors/` (no `.gitignore`, no `.secrets/`, no descriptor, no `INDEX.md`). Proceed to
  **Step E3**.
- **`none`:** `**Tools:** none`, `**Tools step:** DECLARED-EMPTY`. Also create **nothing** under
  `.aid/connectors/` this cycle — there is nothing to write for zero tools; the `DECLARED-EMPTY`
  marker exists for a *later* reconcile cycle to act on, not for this state to act on now.
  Proceed to **Step E3**.
- **One or more `<preset-id>` / `custom` declarations:** `**Tools step:** ENGAGED`; process each
  declared tool per "Descriptor write sequence" below, then set `**Tools:** <N> declared`.
  Proceed to **Step E3**.

### Preset vs. custom declaration

- **Preset (`<preset-id>`):** read the matching row of
  `canonical/aid/templates/connectors/preset-catalog.md` (LLM-read, as Step 0d reads the domain
  doc matrix) and pre-fill `name`, `connection_type`, `endpoint` (from `endpoint-template`),
  `auth_method`, the `secret_reference` FORM (from `secret_reference-form`, **aid-managed presets
  only** — a tool-managed preset row carries no form), and `preset: <preset-id>`. Present the
  pre-filled descriptor; the user confirms or adjusts and supplies instance specifics (their
  org/host/domain, the env-var name for `secret_reference` when the form is `env:`). An id not
  found in the catalog is **not** guessed as a near match — treat it as `custom`, or raise a Q&A
  entry if the resulting attribute set is unclear.
- **Custom (`custom`):** capture `name`, `connection_type` (validated against the closed enum
  `mcp | api | ssh | url | cli` — a value outside the set is **refused, not coerced**; `db` is
  not a value), `endpoint`/target, and, for an **aid-managed** `connection_type`
  (`api | ssh | url | cli`), `auth_method` (from `none | token | pat | oauth | ssh-key`) and, when
  `auth_method != none`, the `secret_reference` form (default
  `file:.aid/connectors/.secrets/<connector>`). Set `preset: custom`. (A `mcp` custom declaration
  captures no `auth_method` / `secret_reference` here — see the management-mode branch below.)

**`tags` / `audience` — auto-derived, never prompted.** When the preset row declares a `tags`
column value, use it verbatim (it already encodes `connector` + the connection type + any
preset-specific specialization, e.g. `[connector, mcp, source-host]` for `github`). When the
preset omits `tags` (or the declaration is `custom`), derive `[connector, <connection_type>]`.
No preset row overrides `audience` (`preset-catalog.md` "Columns" note) — always default to
`[developer, architect]`.

Any tool attribute an agent could not act on (an endpoint with no resolvable scheme, an auth
method the preset does not cover) is **never guessed** — write it as a `## Q&A (Pending)` entry
(Category `Integration`, Impact `Medium`) and exclude that tool from this cycle's descriptor
writes until it is resolved.

### Management-mode branch (STATE.md Q10 — derived from `connection_type`)

After `connection_type` is set (preset or custom), branch on the **derived management mode**
(feature-001 / feature-004) — this decides whether a secret is captured at all:

- **Tool-managed (`connection_type: mcp`):** the host tool provides its own MCP server/plugin for
  the target. Force `auth_method: none` and write **no** `secret_reference` — AID stores no
  credential. Do **NOT** prompt for a secret and do **NOT** invoke feature-003's
  `connector-secret` twin. Record in the descriptor body that the connection is **available via
  the host tool's own MCP/plugin** and that the agent must **request it from the tool** (the tool
  handles auth). There is **no** wiring step — AID neither writes nor triggers any host MCP
  configuration.
- **Aid-managed (`connection_type: api | ssh | url | cli`):** proceed with the `auth_method` /
  `secret_reference` form already captured above (preset or custom); unchanged from today.

### Descriptor write sequence (binds feature-001's ordering guarantee)

The **first time** this ELICIT cycle touches `.aid/connectors/`, its **first action** — before
creating `.secrets/`, before writing any descriptor, before any secret byte is written — is:

```bash
mkdir -p .aid/connectors
if [ ! -f .aid/connectors/.gitignore ]; then
  printf '%s\n' '.secrets/' > .aid/connectors/.gitignore
fi
```

Then, **per confirmed tool** (in declaration order):

1. **Derive `<connector>`** = slugified `name` — the connector's unique key (feature-001);
   illustrative: lowercase, non-alphanumeric runs collapsed to `-`, no leading/trailing `-`
   (`echo "$name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'`).
2. **Write `.aid/connectors/<connector>.md`** with the frontmatter fields from feature-001's
   Data Model plus a short human body, branching by the management mode (above):
   - **Tool-managed (`mcp`):** `name`, `connection_type: mcp`, `endpoint` (informational),
     `auth_method: none`, **no `secret_reference` field**, `preset`, `objective`, `summary`,
     `tags`, `audience`. Body mirrors feature-001's worked `github.md` example: a `# <Name>`
     heading, a `> Connection: mcp · Mode: tool-managed · Auth: handled by the host tool (no AID
     credential)` summary line, and one or two lines of human-readable purpose that instruct the
     agent to **request the connection from the host tool's own MCP/plugin** — AID stores no
     credential for it.
   - **Aid-managed (`api | ssh | url | cli`):** `name`, `connection_type`, `endpoint`,
     `auth_method`, `secret_reference` (when `auth_method != none`), `preset`, `objective`,
     `summary`, `tags`, `audience`. Body mirrors feature-001's worked `m365.md` example: a
     `# <Name>` heading, a `> Connection: <type> · Mode: aid-managed · Auth: <auth_method>
     (reference: <secret_reference>)` summary line, and one or two lines of human-readable
     purpose. The descriptor carries **only** the `secret_reference` — never a value.
3. **Secret capture is aid-managed-only (Q10).** For a **tool-managed (`mcp`)** connector, **no
   secret is captured** — no prompt is presented and feature-003's `connector-secret` twin is
   **never invoked** (there is no `secret_reference` to fill). For an **aid-managed
   (`api|ssh|url|cli`)** connector, **hand the secret VALUE to feature-003's twin — never capture
   it here.** When `secret_reference` uses the `file:` form (the default), invoke:
   ```bash
   bash canonical/aid/scripts/connectors/connector-secret.sh write <connector> --root .aid/connectors
   ```
   (PowerShell twin: `connector-secret.ps1`.) The script owns the no-echo capture and the
   exact-bytes, owner-only write to `.aid/connectors/.secrets/<connector>`; ELICIT never reads,
   holds, or echoes the value — it only supplies `<connector>` and lets the script prompt.
   **Never construct the invocation with the literal secret text inlined** in a bash command,
   `STATE.md`, the KB, or the conversation transcript — the script's own stdin capture (or a
   piped shell *variable*, per its header's automation example) is the only sanctioned path.
   For `env:` / `keychain:` reference forms, **do not** invoke `connector-secret.sh write` — no
   local value is stored by AID for those forms (resolved externally at use-time).
4. **No wiring step (Q10).** Tool-managed (`mcp`) connectors require no wiring: AID writes no
   host MCP config and triggers no host-tool action here — the agent requests the connection from
   the host tool itself at use-time (feature-005's consumption contract).
5. **After all of this cycle's descriptor writes, trigger the connectors INDEX rebuild:**
   ```bash
   bash canonical/aid/scripts/connectors/build-connectors-index.sh \
     --root .aid/connectors --output .aid/connectors/INDEX.md
   ```
   (PowerShell twin: `build-connectors-index.ps1`.) The builder is deterministic (no run
   timestamp — KI-010), so triggering it even when nothing changed produces no diff.

## Step E3: Record and chain

Write (overwrite) the resolved `## Discovery Elicitation` block in `.aid/knowledge/STATE.md`:

```markdown
## Discovery Elicitation

- **Sources:** none | <N> declared
- **Tools:** none | <N> declared
- **Tools step:** SKIPPED | DECLARED-EMPTY | ENGAGED
- **Skipped:** none | sources
- **Resolved:** yes
- **Elicited:** <date> (run N)
```

Field notes:

- **`Tools step`** (the Q9 marker) is deliberately **distinct** from `Sources`, `Tools`, and
  `Resolved` — it is the field task-018's reconcile R0 branches on: `SKIPPED` = tool step not
  engaged (declared-set undefined, reconcile no-op); `DECLARED-EMPTY` = engaged, zero declared
  (declared-set = `{}`, reconcile removes all); `ENGAGED` = ≥1 tool declared (declared-set = the
  N tools). It only ever takes one of these three closed values in a resolved record (the
  transient `pending` value is mid-pause-only — see Step E1).
- **`Skipped`** now only ever reads `none` or `sources` — the tools branch's skip-vs-empty
  distinction lives entirely in `Tools step` above, not here (kept `Skipped` from also trying to
  carry a `tools` value would recreate the exact ambiguity Q9 raised).

Once `Resolved: yes`, `SKILL.md` State Detection (State 0) falls through to States 1–6 for the
rest of this cycle; ELICIT is not re-asked until `--reset` clears the block.

The connectors registry ELICIT produced this cycle is committed and rides through
GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE unchanged — it is **not** graded by the
REVIEW panel and **not** scanned by `kb-citation-lint` (it lives outside `.aid/knowledge/` —
KI-003, feature-001).

Print: `[State: ELICIT] complete -- sources: {Sources}; tools: {Tools} ({Tools step}).`
Print: `[State: ELICIT] complete.`

**Advance:** **CHAIN** → [State: GENERATE] (continue inline).

## Greenfield interaction (Step 0f HALT)

ELICIT (State 0) always runs before GENERATE, including on a greenfield repo — where GENERATE
itself signposts and HALTs at Step 0f, **before** the Step 1 Scout pre-scan
(`state-generate.md` Step 0f greenfield branch). The two branches degrade differently, both
safely:

- **Tools** complete normally — descriptor writes to `.aid/connectors/` have no Scout dependency,
  so a greenfield project can still declare and register its toolchain.
- **Sources** are recorded to `## External Documentation` as usual, but the **populate into
  `external-sources.md` is deferred** to the first brownfield cycle, once code exists and Scout
  runs. No empty `external-sources.md` is created on greenfield — the file is simply not written
  until Scout first runs. The deferral is safe precisely because of the content-aware Step-1
  skip: when code later lands, `external-sources.md` is absent (or still `Pending`), so Scout
  fires and inventories the already-recorded sources.
