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

## Case D -- QUESTION (v2.1.0 coverage-gap follow-on; `state-classify.md` Step 0
short-circuited -- `{description}` asks for information, not a change)

**Intended exception, not a violation, of the "canonical names only" rule
(SKILL.md Constraints; `state-classify.md` Step 3):** this case suggests the
alias `/aid-ask` directly rather than its canonical form `/aid-query-kb`.
The rule exists to stop a thin, `build-shortcut-skills.py`-generated doorway
alias from being suggested in place of its canonical mirror; `aid-ask` is not
that -- it is a `repurpose: true`, hand-authored, user-facing Q&A entry point
that the catalog registers purely so /aid-triage recognizes it, and its
canonical form `aid-query-kb` is an equivalent hand-authored skill, not a
generated doorway. There is no doorway-duplication concern, so surfacing the
friendlier name here is deliberate.

```
This reads like a question about the project, not a change request.

-> /aid-ask "{description}"

[1] Run it now
[2] Treat this as a task instead (continue triage as a change request)
```

If the user picks `[2]`, fall through to `state-classify.md` Step 1 (infer
`workType` from `{description}` as normal, i.e. the Step 0 short-circuit does
not fire twice for the same run) and continue triage from there.

---

## Response mapping (all cases)

| User choice | Result carried to HALT |
|---|---|
| `[1]` accept a proposed shortcut (Case A/B) | `{name}` = the accepted row's `name`; print its shortcut invocation |
| pick a listed alternate shortcut -- `[2]` in Case B directly, or a numbered pick from Case C's catalog sub-list (after choosing `[2]` there) | `{name}` = the chosen row's `name`; print its shortcut invocation |
| `[3]` full path (Case A/B) or `[1]` full path (Case C) | print the `/aid-describe` invocation |
| `[1]` run it now (Case D) | `{name}` = `aid-ask`; print `/aid-ask "{description}"` |
| `[2]` treat as a task instead (Case D) | fall through to `state-classify.md` Step 1 and continue triage; no HALT yet |
| user rejects every option offered | print the `/aid-describe` invocation (conservative default -- mirrors aid-describe's former TRIAGE state's Step 4 rule: "any signal short of one confident match routes to full") |

The rule is intentionally conservative: any signal short of one confident,
user-confirmed single shortcut routes to the full path.

**Advance:** **CHAIN** -> [State: HALT] (continue inline).
