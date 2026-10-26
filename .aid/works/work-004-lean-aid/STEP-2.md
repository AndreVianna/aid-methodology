# Step 2: the direct lane (goal card, draft)

**Goal:** a small task typed as a skill (`/aid-fix`, `/aid-create`, any doorway) costs close to the same request asked
in plain words, and still ends correct: a test for the change, the project checks passing, the user's yes before the
commit. Today a typed `/aid-fix` ran more than 31 minutes, cost about $24 and changed no code.

**How:** the shortcut engine gets a first state, SIZE: a short written test (few files, one capability, no schema,
data, security, dependency or public-API change). Small goes to DIRECT, the six steps of `DESIGN.md` § B, run by the
main agent itself. Anything else goes to today's path, which step 3 replaces.

**Out of scope:** the planned lane (step 3); hooks (step 3); removing today's engine states.

| # | Criterion | How it is checked |
|---|---|---|
| C1 | `/aid-fix` on the measurement fixture: tests pass, at most 2 user turns, 0 helper agents, no work folder, cost at most 2 times the plain request (plain today $0.22) | `tests/measure/measure.py --scenario fix-skill` |
| C2 | `/aid-create` for the small feature: the same bar (plain today $0.09) | `measure.py --scenario feature-skill` |
| C3 | For a bug, a failing test comes before the fix; the change ends with the project's checks run and shown | the fix run's transcript: a test file changes and the tests run before the source edit |
| C4 | A request that fails the size test (for example a schema change) goes to the existing path, not DIRECT | one routing scenario in `measure.py` |
| C5 | Tracking binds works: a direct-lane change has no work folder and no STATE file; its commit is its record | `rules.md` says so; static check |
| C6 | The engine does not grow: SIZE and DIRECT together are at most about 60 lines, and the engine's total line count does not rise | static check |

**Budget:** about one day of agent time; one independent review of the whole change; measurement runs about $3.
