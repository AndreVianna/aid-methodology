# State: DONE

DONE confirms discovery is complete and user-approved; it is selected when the KB meets minimum grade and `**User Approved:** yes` is present in STATE.md.

Print: _"Discovery is complete and approved (Grade: {grade}). Do you want to reopen it for review?"_

- User confirms → set state to REVIEW
- User has specific concern → record as context for reviewer
- User says no → `✅ Discovery complete. Grade: {grade}. Minimum: {minimum}. KB approved and ready for the Interview phase.`

### Ledger cleanup

Delete the review ledger:
```bash
rm -f .aid/.temp/review-pending/discovery.md
rmdir --ignore-fail-on-non-empty .aid/.temp/review-pending/ 2>/dev/null || true
```

After printing the success message, also suggest the optional visual summary:

```
💡 Optional: run /aid-summarize to generate a visual HTML summary of the
   Knowledge Base — a single offline file with diagrams, light/dark theme,
   click-to-expand lightbox, and breadcrumb scrollspy. Idempotent: re-running
   it later on an unchanged KB is a no-op; it auto-detects when discovery has
   added new entries to ## Review History and regenerates accordingly.
```

Print: `[State: DONE] complete.`

**Advance:** → halt
