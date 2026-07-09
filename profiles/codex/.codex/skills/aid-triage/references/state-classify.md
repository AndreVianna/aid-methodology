# State: CLASSIFY

From `{description}` (captured at INTAKE), infer **three things** in prose --
agent inference, no script.

Extracted from `aid-describe`'s former TRIAGE state (its workType heuristic, unchanged,
and its recipe-match step, **rewritten**: the now-deleted recipe catalog's `summary:`
field is replaced by `shortcut-catalog.yml`'s `intent:` field as the semantic-match
target).

---

## Step 1: Infer workType

Assign one of the three internal work-type labels (never shown as a menu to
the user):

| Heuristic | `workType` |
|-----------|-----------|
| Broken / observed-wrong behaviour; something worked before | `bug-fix` |
| Net-new capability or net-new artifact (incl. new docs, reports, ADRs) | `new-feature` |
| Change / rename / improve an existing working artifact (incl. editing existing docs) | `refactor` |

`workType` is a coarse first-pass signal only -- it narrows which catalog
groups are worth checking first (Step 3) and feeds the reflect-back turn's
"Looks like a {workType}" framing (`references/state-suggest.md`). It is not
itself a routing target (there is no `LITE-BUG-FIX`/`LITE-REFACTOR`/
`LITE-FEATURE` sub-path here -- that lite-path machinery was retired with the
recipe catalog).

---

## Step 2: Judge scope

Decide whether `{description}` names a **single, well-scoped change** or is
**broad / multi-activity / sprawling**:

| Signal | Judgment |
|--------|----------|
| One concrete target artifact (an endpoint, entity, class, rule, doc, page, dataset...) and one clear action on it | Single well-scoped change |
| Multiple unrelated targets, a whole subsystem, "and" chains of distinct activities, or no concrete target named at all | Broad / multi-activity / ambiguous |

This is the same full-vs-lite scope judgment aid-describe's former TRIAGE state's
Signal #1 used to make (Move 5: Backbone-first + walking-skeleton) -- here it decides
full-path-vs-shortcut instead of full-vs-lite. **Broad or ambiguous always
recommends the full path** (`/aid-describe`) regardless of what Step 3 finds
below -- this conservative rule short-circuits Step 3 when it fires.

---

## Step 3: Match against the shortcut catalog

Skip this step entirely if Step 2 judged the work **broad / multi-activity /
ambiguous** -- go straight to SUGGEST with no candidate (full-path
recommendation).

Otherwise, read `.codex/aid/templates/shortcut-catalog.yml` (relative to
the AID installation root -- the same directory that contains
`.codex/skills/`). This is a plain read of a shipped, static file -- no
script is invoked.

**Candidate set** -- every row whose `alias_of` field is `null` (canonical
rows only; an alias row's `intent` carries no semantic content of its own --
just `"Alias of <name>."` -- so it never wins a semantic match and does not
need to be filtered out by hand).

**Narrow by `workType` first** (a light filter, not an exclusion -- if
nothing in the narrowed set fits, widen to the full candidate set before
concluding "no match"):

| `workType` | Groups to check first |
|------------|------------------------|
| `bug-fix` | G6 (`aid-fix`) |
| `refactor` | G5 (`aid-change[-artifact]`, `aid-refactor`) |
| `new-feature` | G4 (`aid-create[-artifact]`), G3 (`aid-prototype[-ui]`), G7 (`aid-test*`, `aid-experiment`), G8 (`aid-document[-artifact]`), G11 (`aid-report`, `aid-show-dashboard`) |

Within the (narrowed, then widened-if-empty) candidate set, read each row's
`intent:` field and pick the row whose intent text best matches
`{description}` (semantic match on the intent string -- agent inference, no
script; this is the direct successor of the former TRIAGE state's recipe-`summary:`
match). Use the row's `{verb, artifact}` identity -- the concrete target
named in `{description}` (an endpoint, entity, class, rule, doc...) --
exactly as the former TRIAGE state's gap-inventory signal #3 ("Target
artifact identity") did, to break ties between rows sharing a `verb`.

Produce:

- **best row** (the clearest single match), AND
- **confidence judgment:** `single clear winner` | `several plausible` | `none`.

If the candidate set (narrowed or widened) is empty, or no row's intent
plausibly fits, confidence = `none`.

---

## Step 4: Hand off to SUGGEST

Pass forward to `references/state-suggest.md`:

- `{workType}` (Step 1)
- scope judgment (Step 2): single-well-scoped | broad-ambiguous
- `{best-row}` (`name`, `verb`, `artifact`, `intent`) and `{confidence}`
  (Step 3), when scope is single-well-scoped
- up to 2 runner-up rows, when `{confidence}` is `several plausible`

**Advance:** **CHAIN** -> [State: SUGGEST] (continue inline).
