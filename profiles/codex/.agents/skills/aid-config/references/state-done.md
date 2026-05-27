# aid-config — State: DONE

```
[State: DONE] — Settings unchanged or update applied; exiting.
aid-config  ▸ you are here
  [✓ INIT ] → [✓ VIEW ] → [✓ UPDATE ] → [✓ PERSIST ] → [● DONE ]
```

Terminal state. Reached when the user typed `exit` from VIEW state, OR when
the user's update sequence has been persisted.

---

## Print summary

If reached from VIEW `exit`:
```
✅ No changes. Run /aid-config any time to view or update settings.
```

If reached from a completed update sequence (PERSIST → VIEW → DONE):
```
✅ Settings updated. Active configuration is in .aid/settings.yml.

   Other AID skills (/aid-discover, /aid-execute, etc.) will read the new
   values on their next invocation.
```

---

## Exit

Print nothing further. Skill terminates.

The user may re-invoke `/aid-config` any time to view + update again.
