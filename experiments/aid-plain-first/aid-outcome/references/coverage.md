# Outcome coverage record

The reviewer's outcome trace may be recorded in JSON for the optional structural
check. Copy every outcome ID and description from the one current requirements
document; verify the list against that document after any scope change. This
record is evidence for a review, not another source of requirements.

```json
{
  "outcomes": [
    {"id": "O1", "description": "The user can export the report"},
    {"id": "O2", "description": "Existing saved data stays intact"}
  ],
  "results": [
    {"id": "O1", "status": "verified", "evidence": ["tests/export.py and its run output"]},
    {"id": "O2", "status": "unverified", "evidence": ["No saved-data check was available"]}
  ]
}
```

In a project with the trial installed, run
`python3 .agents/skills/aid-outcome/scripts/outcome_coverage.py coverage.json`.
For a source-tree trial, use `python3 experiments/aid-plain-first/outcome_coverage.py coverage.json`.
Each outcome needs a unique nonempty ID and description. A result has an ID,
status (`verified`, `failed` or `unverified`) and a nonempty evidence list:
references for verified/failed results or the reason an outcome is unverified.
An omitted result is unverified. The
command exits 0 if all listed outcomes are marked verified, 1 if any are failed
or unverified, and 2 for malformed or contradictory input. It does not read the
requirements file, verify referenced evidence, prove reviewer independence or
establish completeness. An outdated or incomplete outcome list can therefore
produce exit 0; the reviewer must check the full list and actual evidence.

Keep the outcome trace and the existing grade distinct. `grade.sh` reports a
grade from countable ledger findings; even A+ does not prove every requirement
was verified. Missing browser access, reviewer access or other required evidence
must remain visible as unverified.
