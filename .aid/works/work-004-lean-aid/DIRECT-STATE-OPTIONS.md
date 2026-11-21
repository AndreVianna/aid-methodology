# Direct-work state: remaining design choice

The direct lane avoids an interview and a specification for a small change.
The current work template nevertheless records an interview in progress and a pending
specification, and the current resume route sends executing work to
`aid-execute`. Initializing that template faster would preserve those wrong
signals; it would not make direct work truthful or resumable.

## Smallest safe direction to investigate

- Keep reusing a genuinely related active work when one already exists.
- For a new direct work, define an explicit direct-work marker and a compact
  state that records the real work, owner, status, checks and review. Omit
  interview and delivery information that does not apply; do not mark either
  completed or infer user approval.
- Make direct-work resume return to `aid-change` and preserve its real state;
  completed, canceled, blocked and paused work must retain their existing
  boundaries. Existing lite and full works must keep their current behavior.
- Update the work-state schema, writer and dashboard readers together where
  necessary. Test Python, JavaScript and shell agreement, real resume routing,
  exclusive creation, failure recovery, and old-work compatibility before
  shipping. The direct path still needs its tests, safeguard and independent
  whole-result review.

This is a proposed architectural change, not an implemented format. A new
marker alone is insufficient: the current readers classify `pipeline.path`
as lite or full, and the existing resume route sends Execute work to
`aid-execute`. No initialization helper should claim compatibility until the
consumer contract is specified and tested. A full cross-cutting refactor may
cost more than the process it saves, so keep the format and migration surface
small and measure the outcome before treating it as an efficiency win.

## Concrete alternatives

- **Compact direct state:** add a third, explicit `direct` path alongside
  existing `lite` and `full` paths. Its work state would contain the goal,
  actual status and evidence, with no interview or delivery invented. This
  requires coordinated changes to the state writer, Python and JavaScript
  readers, dashboard display, work-resume routing, and `aid-change` resume
  behavior. Old paths must retain their current meaning. This is more initial
  implementation, with a potentially simpler small-task path afterward.
- **Reuse existing active work only:** keep the existing format and record a
  related follow-up in its existing work. This has a smaller implementation
  surface, but does not solve the misleading cold-start state for a new direct
  change. Unrelated, completed or canceled work cannot be reused.

For either direction, a resume must distinguish actual completed checks and
reviews from steps still to do; an interruption must not silently replay a
failed write or create an approval. No option is implemented by this document.

For the compact option, the smallest safe implementation is one coordinated
slice: a declared state contract and exclusive initializer; work-level writer
support that rejects inapplicable task/delivery operations; real direct resume;
explicit Python, JavaScript and dashboard handling; and installed-runtime and
old-work compatibility checks. Updating only the initializer would create
state that existing consumers can misinterpret. No migration of existing
lite/full records is proposed.
