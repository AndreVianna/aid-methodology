# State: SUGGEST

Emits the NFR-7 reflect-back straw-man turn proposing the inferred entry for
user confirmation -- extracted from aid-describe's former TRIAGE state (its Step 3,
the proven UX shape), retargeted from a recipe confirmation to a shortcut-vs-full-path
confirmation. This is the one-turn NFR -- the common case resolves here with no further
back-and-forth. Present the inference and wait for the user's response **on this same
turn**.

---

## Case A -- single clear winner (scope: single well-scoped change)

```
Looks like a {workType} -- best entry: /{best-row.name} ({best-row.intent}).

[1] Proceed -- I'll run /{best-row.name} next
[2] A different shortcut
[3] Full path via /aid-describe instead
```

If the user picks `[2]`, ask which family fits better (name a group or a
concrete artifact) and re-run Step 3 of `state-classify.md` scoped to that
hint; if still no confident match, fall through to Case C.

---

## Case B -- several plausible (scope: single well-scoped change)

```
Looks like a {workType}, but a few shortcuts could fit:

[1] /{row-1.name} -- {row-1.intent}
[2] /{row-2.name} -- {row-2.intent}
[3] Full path via /aid-describe instead
```

(List at most 2 runner-up rows, per `state-classify.md` Step 4. If a third
plausible row exists, fold it into the `Why:` context rather than adding a
`[4]` -- keep the menu at three options.)

---

## Case C -- no candidate matches, or scope is broad / multi-activity / ambiguous

```
This looks broad or ambiguous for a single direct-entry shortcut.

[1] Full path via /aid-describe (recommended)
[2] See the shortcut catalog anyway
```

If the user picks `[2]`, list up to 3 loosely-plausible catalog rows (by
`workType`-narrowed group, per `state-classify.md` Step 3's narrowing table)
with a one-line disclaimer that none confidently matched.

---

## Response mapping (all cases)

| User choice | Result carried to HALT |
|---|---|
| `[1]` accept a proposed shortcut (Case A/B) | `{name}` = the accepted row's `name`; print its shortcut invocation |
| pick a listed alternate shortcut -- `[2]` in Case B directly, or a numbered pick from Case C's catalog sub-list (after choosing `[2]` there) | `{name}` = the chosen row's `name`; print its shortcut invocation |
| `[3]` full path (Case A/B) or `[1]` full path (Case C) | print the `/aid-describe` invocation |
| user rejects every option offered | print the `/aid-describe` invocation (conservative default -- mirrors aid-describe's former TRIAGE state's Step 4 rule: "any signal short of one confident match routes to full") |

The rule is intentionally conservative: any signal short of one confident,
user-confirmed single shortcut routes to the full path.

**Advance:** **CHAIN** -> [State: HALT] (continue inline).
