# Formal3 static cost attribution

Commit 34f54b72619cede492f96fe10dffceaf482a32b6; historical baseline d3777c36ed33313d56e0dba85282745ef7bf5fde. No collection repeated and no baseline/tolerance changed.

Always-on: 54,546 -> 53,977 characters (delta -569); skill descriptions50,944 -> 50,375, context files1,801 each and skill count112 unchanged.

| Metric group | Grew | Shrank | Net delta | Unit |
|---|---:|---:|---:|---|
| always-on | 0 | 1 | -569 | characters |
| dependency file count | 9 | 0 | 35 | files |
| KB dependency reach | 11 | 0 | 34105 | characters |
| canonical skill reference aggregate | 3 | 6 | 4941 | characters |
| direct canonical skill | 49 | 1 | 54027 | characters |
| direct shared canonical template | 9 | 0 | 15033 | characters |

Direct canonical growth (largest first):
- canonical/skills/aid-config/SKILL.md: +5998 characters.
- canonical/skills/aid-review/SKILL.md: +5342 characters.
- canonical/aid/templates/question-protocol.md: +5335 characters.
- canonical/skills/aid-set-connector/SKILL.md: +5169 characters.
- canonical/skills/aid-research/SKILL.md: +4829 characters.
- canonical/skills/aid-report/SKILL.md: +4529 characters.
- canonical/aid/templates/work-initiation-gate.md: +2855 characters.
- canonical/aid/templates/skill-steps.md: +2122 characters.
- canonical/aid/templates/design-lifecycle.md: +1834 characters.
- canonical/aid/templates/shortcut-engine.md: +1448 characters.
- canonical/skills/aid-update-testing-strategy/SKILL.md: +1260 characters.
- canonical/skills/aid-update-architecture/SKILL.md: +1248 characters.

Dependency reach is overlapping exposure, not independent source bytes. File counts are not character sizes. All81 growing metrics and exact before/after values are in the companion JSON.
