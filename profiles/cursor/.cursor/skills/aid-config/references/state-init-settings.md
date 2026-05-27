# aid-config — State: INIT-SETTINGS (existing project gaining settings.yml)

```
[State: INIT-SETTINGS] — Writing .aid/settings.yml defaults; existing .aid/ untouched.
aid-config  ▸ you are here
  [● INIT-SETTINGS ] → [ VIEW ] → [ UPDATE ] → [ PERSIST ] → [ DONE ]
```

Entered when `.aid/` exists (an older AID project) but `.aid/settings.yml` does
NOT exist yet. Writes defaults so subsequent skill invocations have a settings
source to read from.

**This is a non-conversational state — no questions asked. Defaults are written silently.**

---

## Step 1: Write `.aid/settings.yml` from canonical defaults

Copy `.cursor/templates/settings.yml` to `.aid/settings.yml` verbatim.
**No substitution** — placeholder values (`<project-name>`, etc.) remain in
the file. The user can update via subsequent VIEW → UPDATE cycles.

The placeholders signal "this needs your attention" — VIEW state highlights
keys whose value is `<...>` so the user knows to set them.

---

## Step 2: Print summary

```
✅ .aid/settings.yml written with defaults.

Some keys still have placeholder values (<project-name>, <project-description>).
Run /aid-config to view + update them.

Note: this skill did NOT touch .aid/knowledge/ or any other existing AID artifacts.
Per policy decision, settings migration from legacy STATE.md is deferred — old
keys in STATE.md are simply ignored by the new pipeline; the active source of
truth is now .aid/settings.yml.
```

---

## Advance

Print:
```
Next: [State: VIEW] — run /aid-config again to view + update settings.
```

Exit.
