# State: DONE

DONE confirms the summarization is complete and the Summarization History has been updated; it is selected after WRITEBACK succeeds or (as DONE-IDEMPOTENT) when STALE-CHECK finds the HTML is already up-to-date and approved.

**Normal completion (after WRITEBACK):**

Print:
```
✓ .aid/knowledge/STATE.md updated:
    ## Summarization History → entry #{N} added ({date}, grade {grade})
✓ ## Knowledge Summary Status → User Approved: yes

[State: DONE]

Open .aid/knowledge/knowledge-summary.html in a browser to view the summary.
```

Exit with success.

---

**Idempotent completion (DONE-IDEMPOTENT — when STALE-CHECK finds nothing to do):**

Print:
```
✅ knowledge-summary.html is already up-to-date with the current KB.
   Last summary: {date} (grade {grade})
   Last KB review: {date}
   Nothing to do. Re-run with --reset to force regeneration.

[State: DONE]
```

Exit with success. `.aid/knowledge/STATE.md` `## Knowledge Summary Status` and `## Summarization History` are NOT modified.

---

**Advance:** → halt
