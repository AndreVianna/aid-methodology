# aid-config — State: PERSIST

```
[State: PERSIST] — Atomically writing staged change to .aid/settings.yml.
aid-config  ▸ you are here
  [✓ INIT ] → [✓ VIEW ] → [✓ UPDATE ] → [● PERSIST ] → [ DONE ]
```

Apply the staged change from `.aid/.temp/aid-config-staged.txt` to
`.aid/settings.yml`. Atomic write (temp file + rename). On success, delete
the staging file and advance to VIEW (so the user sees the updated state).

---

## Step 1: Read the staged change

Read `.aid/.temp/aid-config-staged.txt`. Extract:
- `key:` (dotted path, e.g., `review.minimum_grade`)
- `new_value:` (the validated new value)

If the staging file is missing, this state was entered in error. Print:
```
❌ No staged change found. Returning to VIEW.
```
And advance to VIEW.

---

## Step 2: Read + parse current settings

Read `.aid/settings.yml`. Parse as YAML. Locate the key per the dotted path.

For per-skill overrides (`<skill>.minimum_grade` where `<skill>` is a top-level
key not present in the canonical schema), the parser may need to CREATE the
top-level key (e.g., add `discover:` section if not present).

For `new_value: remove` on a per-skill override, DELETE the entire
`<skill>:` top-level key (not just its `minimum_grade` child).

---

## Step 3: Apply the change in-memory

Update the parsed YAML object with the new value.

---

## Step 4: Validate the resulting document

Before writing, re-validate the WHOLE settings.yml as YAML + against the schema:
- All required top-level sections present (project, tools, review, execution, traceability)
- `project.type` is `brownfield` or `greenfield`
- `tools.installed` non-empty
- All `minimum_grade` values match `^[A-F][+-]?$`
- All `interval` / `max_*` values are positive integers

If validation fails, abort the write + print error + leave staging file intact
so the user can retry. Advance to VIEW (next run can re-render).

---

## Step 5: Atomic write (inline recipe)

Write the updated YAML to a temp file, then atomically rename to
`.aid/settings.yml`. There is no separate `persist-setting.sh` helper —
the inline recipe below is the canonical implementation.

```bash
# Acquire sentinel lock (best-effort; cheap mutex against concurrent
# /aid-config in another terminal). 5-second retry budget.
LOCK=".aid/.temp/aid-config.lock"
mkdir -p .aid/.temp
attempts=0
until mkdir "$LOCK" 2>/dev/null; do
  attempts=$((attempts + 1))
  if [ "$attempts" -ge 5 ]; then
    echo "❌ Lock contention on $LOCK after 5s — another /aid-config running?"
    exit 1
  fi
  sleep 1
done
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

# Atomic write: temp file in same dir + rename (POSIX atomicity guarantee).
TMP=".aid/settings.yml.tmp.$$"
cat > "$TMP" <<'YAML'
<rewritten yaml body here>
YAML
mv -f "$TMP" .aid/settings.yml
```

Atomic rename ensures the file is never partially written (an interrupted
write leaves the old content intact, not a half-file). The lock prevents two
concurrent `/aid-config` runs from clobbering each other (rare, but possible
across terminal sessions).

If a future PR ships `.cursor/scripts/config/persist-setting.sh`, this
inline recipe should be replaced with a call to it — but until then, the
inline form is the spec.

---

## Step 6: Delete the staging file

```
rm -f .aid/.temp/aid-config-staged.txt
```

---

## Step 7: Confirm

Print:
```
✅ Updated <key-path>: <old-value> → <new-value>
   Written to .aid/settings.yml.
```

---

## Advance

```
Next: [State: VIEW] — run /aid-config again to view updated settings or make further changes.
```

Exit.

---

## Why atomic write + lock?

Other AID skills read `.aid/settings.yml` at invocation time. A non-atomic
write (e.g., truncate + sequential append) could leave the file in a partial
state if interrupted, breaking concurrent reads. Atomic rename (Step 5's
`mv -f` from a same-directory temp file) is the standard fix — POSIX
guarantees same-filesystem rename is atomic.

The sentinel lock (the `mkdir` mutex in Step 5) prevents two `/aid-config`
invocations from clobbering each other (rare, but happens if the user runs
two terminal sessions). The lock directory is `.aid/.temp/aid-config.lock`.
