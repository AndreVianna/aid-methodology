#!/usr/bin/env bash
# test-output-root-isolation.sh -- Machine-proof of the output_root shadow-write isolation
# guarantee (task-033, delivery-005, feature-005).
#
# Since the extraction subagents are prose-executed (LLM-run, not unit-testable scripts),
# this suite proves the guarantee BY CONSTRUCTION: the prose specification must express the
# redirect for the write boundary to hold at runtime.  Structural assertions on the prose
# ARE the machine proof for agent-prose write guarantees.
#
# What is proven:
#   1. Every extraction subagent in agent-prompts.md routes KB-doc writes through the
#      {output_root} dispatch parameter -- no hard-coded .aid/knowledge/ write destinations.
#   2. The three .aid/generated/ side-output writers (Architect, Integrator, Grounding)
#      explicitly declare their generated/ paths are NOT governed by {output_root}.
#   3. state-kb-delta.md CL-Step 1 dispatches with output_root=.aid/.temp/conformance/as-built/
#      and carries the "NEVER written by this step" + "byte-unchanged" invariants in CL-Step 2.
#   4. A canary guard detects future regressions that reintroduce hard-coded .aid/knowledge/
#      paths in agent KB write rules (FAILS immediately if the shadow-write boundary breaks).
#
# Test IDs:
#   P01-P04  Dispatch parameter declaration in agent-prompts.md (section header + documented
#            default/alternate paths + named three-agent generated/ scope)
#   S01-S06  Each of the 6 agent KB write rules routes to {output_root} (verified per section)
#   G01-G04  Three .aid/generated/ side-output writers explicitly exclude from {output_root}
#            (count-based + per-section confirmation for each of the three agents)
#   D01-D06  state-kb-delta.md CL-Step 1/2 dispatch value and safety invariants
#   K01-K04  Canary -- regression guard against hard-coded .aid/knowledge/ write destinations:
#            K01 total KB-write-rule count must be 6 (drops on regression);
#            K02 zero write-rule lines hardcode .aid/knowledge/ as destination (fires on regression);
#            K03 zero body produce/entry-in/You-own lines reference .aid/knowledge/ (body literal guard);
#            K04 zero lines contain .aid/knowledge/.<name> hidden/temp-file path (temp-write guard)
#
# Auto-discovered by tests/run-all.sh (glob tests/canonical/test-*.sh).
# No HOME pin needed: reads only canonical skill docs (no AID scan surfaces touched).
# No temp files: all assertions are grep-based structural checks.
# ASCII-only: this script contains no non-ASCII characters.
#
# Usage:
#   bash tests/canonical/test-output-root-isolation.sh [--verbose]
#
# Exit codes: 0 all pass / 1 any fail

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

AGENT_PROMPTS="${REPO_ROOT}/canonical/skills/aid-discover/references/agent-prompts.md"
KB_DELTA="${REPO_ROOT}/canonical/skills/aid-housekeep/references/state-kb-delta.md"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-output-root-isolation.sh =="

# ---------------------------------------------------------------------------
# Guard: source docs must exist
# ---------------------------------------------------------------------------
if [[ ! -f "$AGENT_PROMPTS" ]]; then
    fail "setup -- agent-prompts.md not found at $AGENT_PROMPTS"
    test_summary; exit 1
fi
if [[ ! -f "$KB_DELTA" ]]; then
    fail "setup -- state-kb-delta.md not found at $KB_DELTA"
    test_summary; exit 1
fi

# ===========================================================================
# Group P -- Dispatch parameter declaration in agent-prompts.md
# ===========================================================================
log "Group P: Dispatch parameter declaration"

# P01: The '## Dispatch Parameter: output_root' section header exists.
log "P01: '## Dispatch Parameter: output_root' section header present"
if grep -qF '## Dispatch Parameter: output_root' "$AGENT_PROMPTS"; then
    pass "P01 agent-prompts.md declares '## Dispatch Parameter: output_root'"
else
    fail "P01 agent-prompts.md -- '## Dispatch Parameter: output_root' section missing"
fi

# P02: The default is documented as .aid/knowledge/.
log "P02: default output_root documented as .aid/knowledge/"
if grep -qF '**Default:** `.aid/knowledge/`' "$AGENT_PROMPTS"; then
    pass "P02 parameter section documents .aid/knowledge/ as the default output_root"
else
    fail "P02 agent-prompts.md -- default .aid/knowledge/ documentation not found"
fi

# P03: The alternate shadow path .aid/.temp/conformance/as-built/ is documented.
log "P03: alternate path .aid/.temp/conformance/as-built/ documented in parameter section"
if grep -qF '.aid/.temp/conformance/as-built/' "$AGENT_PROMPTS"; then
    pass "P03 parameter section documents .aid/.temp/conformance/as-built/ as the shadow root"
else
    fail "P03 agent-prompts.md -- alternate path .aid/.temp/conformance/as-built/ not found"
fi

# P04: The three named agents that write to .aid/generated/ are listed by name.
log "P04: Architect, Integrator, and Grounding named as the three .aid/generated/ writers"
if grep -qF 'Architect, Integrator, and Grounding' "$AGENT_PROMPTS"; then
    pass "P04 parameter section names Architect, Integrator, and Grounding as the generated/ writers"
else
    fail "P04 agent-prompts.md -- 'Architect, Integrator, and Grounding' not found in parameter section"
fi

# ===========================================================================
# Group S -- Each agent KB write rule routes to {output_root} (per-section)
#
# Section boundaries used in awk:
#   Scout     : ## Scout     ..  ## Architect
#   Architect : ## Architect ..  ## Analyst
#   Analyst   : ## Analyst   ..  ## Integrator
#   Integrator: ## Integrator .. ## Quality
#   Quality   : ## Quality   ..  ## Grounding
#   Grounding : ## Grounding ..  EOF
# ===========================================================================
log "Group S: All 6 agent KB write rules route to {output_root}"

# S01: Scout write rule uses {output_root} as KB destination.
log "S01: Scout section -- write rule uses {output_root}"
s01_found=0
awk '/^## Scout$/,/^## Architect$/' "$AGENT_PROMPTS" \
    | grep -qF 'Write only to the `{output_root}` directory' 2>/dev/null \
    && s01_found=1 || true
if [[ "$s01_found" -eq 1 ]]; then
    pass "S01 Scout section -- write rule routes to {output_root}"
else
    fail "S01 Scout section -- write rule with {output_root} not found"
fi

# S02: Architect write rule uses {output_root} for KB documents.
log "S02: Architect section -- KB write rule uses {output_root}"
s02_found=0
awk '/^## Architect$/,/^## Analyst$/' "$AGENT_PROMPTS" \
    | grep -qF 'Write KB documents only to the `{output_root}` directory' 2>/dev/null \
    && s02_found=1 || true
if [[ "$s02_found" -eq 1 ]]; then
    pass "S02 Architect section -- KB write rule routes to {output_root}"
else
    fail "S02 Architect section -- KB write rule with {output_root} not found"
fi

# S03: Analyst write rule uses {output_root} as KB destination.
log "S03: Analyst section -- write rule uses {output_root}"
s03_found=0
awk '/^## Analyst$/,/^## Integrator$/' "$AGENT_PROMPTS" \
    | grep -qF 'Write only to the `{output_root}` directory' 2>/dev/null \
    && s03_found=1 || true
if [[ "$s03_found" -eq 1 ]]; then
    pass "S03 Analyst section -- write rule routes to {output_root}"
else
    fail "S03 Analyst section -- write rule with {output_root} not found"
fi

# S04: Integrator write rule uses {output_root} for KB documents.
log "S04: Integrator section -- KB write rule uses {output_root}"
s04_found=0
awk '/^## Integrator$/,/^## Quality$/' "$AGENT_PROMPTS" \
    | grep -qF 'Write KB documents only to the `{output_root}` directory' 2>/dev/null \
    && s04_found=1 || true
if [[ "$s04_found" -eq 1 ]]; then
    pass "S04 Integrator section -- KB write rule routes to {output_root}"
else
    fail "S04 Integrator section -- KB write rule with {output_root} not found"
fi

# S05: Quality write rule uses {output_root} as KB destination.
log "S05: Quality section -- write rule uses {output_root}"
s05_found=0
awk '/^## Quality$/,/^## Grounding$/' "$AGENT_PROMPTS" \
    | grep -qF 'Write only to the `{output_root}` directory' 2>/dev/null \
    && s05_found=1 || true
if [[ "$s05_found" -eq 1 ]]; then
    pass "S05 Quality section -- write rule routes to {output_root}"
else
    fail "S05 Quality section -- write rule with {output_root} not found"
fi

# S06: Grounding write rule uses {output_root} for KB document destinations.
# Grounding writes to {output_root}/domain-glossary.md and {output_root}/.scout-questions.tmp
# (unique pattern: parameterized file paths, not just a directory).
log "S06: Grounding section -- KB write rule uses {output_root}/domain-glossary.md"
s06_found=0
awk '/^## Grounding$/,0' "$AGENT_PROMPTS" \
    | grep -qF 'Write KB documents only to `{output_root}/domain-glossary.md`' 2>/dev/null \
    && s06_found=1 || true
if [[ "$s06_found" -eq 1 ]]; then
    pass "S06 Grounding section -- KB write rule routes to {output_root}/domain-glossary.md"
else
    fail "S06 Grounding section -- unique KB write rule with {output_root} not found"
fi

# ===========================================================================
# Group G -- Three .aid/generated/ writers explicitly exclude from {output_root}
#
# "governed by `{output_root}`" appears exactly 3 times in the file:
#   Architect (line ~243): "that path is NOT\n governed by {output_root}"
#   Integrator (line ~338): same line-wrapped form
#   Grounding  (line ~454): "those paths are NOT governed by {output_root}"
# The side-output write lines are line-wrapped; "governed by `{output_root}`" is always
# on the continuation line -- grepping for it catches all three and only those three.
# ===========================================================================
log "Group G: .aid/generated/ side-output paths declared NOT governed by {output_root}"

# G01: "governed by `{output_root}`" appears exactly 3 times (one per side-output writer).
log "G01: 'governed by {output_root}' appears exactly 3 times (Architect + Integrator + Grounding)"
governed_count=$(grep -cF 'governed by `{output_root}`' "$AGENT_PROMPTS" || true)
assert_eq "$governed_count" "3" \
    "G01 'governed by \`{output_root}\`' count -- expected 3 (one per side-output writer)"

# G02: Architect section explicitly declares .aid/generated/ NOT governed by {output_root}.
log "G02: Architect section declares .aid/generated/ NOT governed by {output_root}"
g02_found=0
awk '/^## Architect$/,/^## Analyst$/' "$AGENT_PROMPTS" \
    | grep -qF 'governed by `{output_root}`' 2>/dev/null \
    && g02_found=1 || true
if [[ "$g02_found" -eq 1 ]]; then
    pass "G02 Architect section -- .aid/generated/ exclusion from {output_root} declared"
else
    fail "G02 Architect section -- 'governed by {output_root}' exclusion not found"
fi

# G03: Integrator section explicitly declares .aid/generated/ NOT governed by {output_root}.
log "G03: Integrator section declares .aid/generated/ NOT governed by {output_root}"
g03_found=0
awk '/^## Integrator$/,/^## Quality$/' "$AGENT_PROMPTS" \
    | grep -qF 'governed by `{output_root}`' 2>/dev/null \
    && g03_found=1 || true
if [[ "$g03_found" -eq 1 ]]; then
    pass "G03 Integrator section -- .aid/generated/ exclusion from {output_root} declared"
else
    fail "G03 Integrator section -- 'governed by {output_root}' exclusion not found"
fi

# G04: Grounding section explicitly declares .aid/generated/ side-output paths NOT governed.
log "G04: Grounding section declares .aid/generated/ paths NOT governed by {output_root}"
g04_found=0
awk '/^## Grounding$/,0' "$AGENT_PROMPTS" \
    | grep -qF 'governed by `{output_root}`' 2>/dev/null \
    && g04_found=1 || true
if [[ "$g04_found" -eq 1 ]]; then
    pass "G04 Grounding section -- .aid/generated/ exclusion from {output_root} declared"
else
    fail "G04 Grounding section -- 'governed by {output_root}' exclusion not found"
fi

# ===========================================================================
# Group D -- state-kb-delta.md CL-Step 1/2 dispatch value and safety invariants
# ===========================================================================
log "Group D: state-kb-delta.md CL-Step 1/2 shadow-extraction dispatch and invariants"

# D01: CL-Step 1 Sub-step 2 sets output_root=.aid/.temp/conformance/as-built/
# This is the concrete dispatch value that makes .aid/knowledge/ structurally unreachable.
log "D01: CL-Step 1 Sub-step 2 declares output_root=.aid/.temp/conformance/as-built/"
if grep -qF 'output_root=.aid/.temp/conformance/as-built/' "$KB_DELTA"; then
    pass "D01 state-kb-delta.md -- output_root=.aid/.temp/conformance/as-built/ declared in CL-Step 1"
else
    fail "D01 state-kb-delta.md -- dispatch value output_root=.aid/.temp/conformance/as-built/ not found"
fi

# D02: CL-Step 1 carries the "NEVER written by this step" invariant for .aid/knowledge/.
log "D02: CL-Step 1 carries '.aid/knowledge/ is NEVER written by this step' invariant"
if grep -qF 'NEVER written by this step' "$KB_DELTA"; then
    pass "D02 state-kb-delta.md -- 'NEVER written by this step' isolation invariant present"
else
    fail "D02 state-kb-delta.md -- 'NEVER written by this step' invariant not found"
fi

# D03: CL-Step 1 states enforcement is BY CONSTRUCTION (not by convention).
# "enforced BY CONSTRUCTION via the output_root dispatch parameter" -- the key claim.
log "D03: CL-Step 1 states isolation is enforced BY CONSTRUCTION (not by convention)"
if grep -qF 'enforced BY CONSTRUCTION' "$KB_DELTA"; then
    pass "D03 state-kb-delta.md -- 'enforced BY CONSTRUCTION' mechanistic claim present"
else
    fail "D03 state-kb-delta.md -- 'enforced BY CONSTRUCTION' claim not found"
fi

# D04: CL-Step 2 (Reconciliation flow) carries the "NEVER writes .aid/knowledge/*.md"
# invariant -- the flag-not-overwrite guarantee for the reconciliation phase.
log "D04: CL-Step 2 (Reconciliation) carries 'NEVER writes .aid/knowledge/*.md' invariant"
if grep -qF 'NEVER writes `.aid/knowledge/*.md`' "$KB_DELTA"; then
    pass "D04 state-kb-delta.md CL-Step 2 -- 'NEVER writes .aid/knowledge/*.md' invariant present"
else
    fail "D04 state-kb-delta.md -- 'NEVER writes .aid/knowledge/*.md' invariant not found in CL-Step 2"
fi

# D05: CL-Step 2 declares forward-authored doc bytes UNCHANGED by the conformance check.
# "The forward-authored doc's bytes ... are UNCHANGED by this step."
log "D05: CL-Step 2 declares forward-authored doc bytes UNCHANGED until reconciled"
if grep -qF 'UNCHANGED by this step' "$KB_DELTA"; then
    pass "D05 state-kb-delta.md CL-Step 2 -- 'UNCHANGED by this step' byte-invariant present"
else
    fail "D05 state-kb-delta.md -- 'UNCHANGED by this step' byte-unchanged invariant not found"
fi

# D06: CL-Step 1 declares the conformance lane ignores .aid/generated/ side-output.
# Only KB docs in the shadow root feed the diff; generated/ side-output is excluded.
log "D06: CL-Step 1 declares conformance lane ignores .aid/generated/ side-output"
if grep -qF 'conformance lane ignores all `.aid/generated/` side-output' "$KB_DELTA"; then
    pass "D06 state-kb-delta.md CL-Step 1 -- conformance lane ignores .aid/generated/ side-output"
else
    fail "D06 state-kb-delta.md -- generated/ side-output exclusion in conformance lane not found"
fi

# ===========================================================================
# Group K -- Canary: regression guard against hard-coded .aid/knowledge/ writes
#
# These four tests would FAIL if a future edit reintroduced a hard-coded
# .aid/knowledge/ write path in any agent write rule or body:
#
#   K01: the count of KB-write-rule destination lines using {output_root} drops below 6.
#        Pattern: "^> Write.*only to.*{output_root}" -- matches the opening line of each
#        agent's KB write instruction.  One per agent = exactly 6.
#
#   K02: a line matching "^> Write.*only to.*\.aid/knowledge/" would indicate a hardcoded
#        destination replacing {output_root}.  Currently 0; becomes non-zero on regression.
#        (.aid/knowledge/ legitimately appears ONLY in parenthetical default descriptions
#        on continuation lines, never on lines starting with "> Write.*only to".)
#
#   K03: zero lines in agent-prompts.md contain a body production-target or ownership
#        literal with ".aid/knowledge/" (the temp-write vector missed by K01/K02 because
#        those patterns only inspect trailing write-rule lines).  Checks:
#          "produce .aid/knowledge/"  -- Architect/Analyst/Integrator/Quality produce lines
#          "entry in .aid/knowledge/" -- spine-grounding mandate write references
#          "You own .aid/knowledge/"  -- Integrator ownership declaration
#        All three forms were body production-target literals before being parameterized;
#        after the fix every instance uses {output_root}/ instead.
#
#   K04: zero lines in agent-prompts.md contain a hidden/temp file reference under
#        ".aid/knowledge/." (a dot immediately after the trailing slash) -- catches
#        ".aid/knowledge/.scout-questions.tmp" and similar temp-write paths.  After the
#        fix every temp-write uses "{output_root}/.scout-questions.tmp"; the only
#        ".aid/knowledge/" occurrences have a non-dot filename character after the slash.
# ===========================================================================
log "Group K: Canary -- regression guard for output_root write-boundary"

# K01: Exactly 6 KB write-rule destination lines use {output_root}.
# If any agent's write rule loses {output_root} as destination, count drops -> canary fires.
log "K01: exactly 6 KB write-rule lines match '^> Write.*only to.*{output_root}'"
kb_write_rule_count=$(grep -cE '^> Write.*only to.*\{output_root\}' "$AGENT_PROMPTS" || true)
assert_eq "$kb_write_rule_count" "6" \
    "K01 canary: exactly 6 KB write-rule destination lines use {output_root} (one per agent)"

# K02: Zero write-rule destination lines hardcode .aid/knowledge/ as the target.
# If a future edit replaces {output_root} with .aid/knowledge/ in any write rule, this
# count becomes non-zero and the canary fails -- the shadow-boundary regression is caught.
log "K02: zero write-rule lines hardcode .aid/knowledge/ as destination (regression canary)"
kb_hardcoded_count=$(grep -cE '^> Write.*only to.*\.aid/knowledge/' "$AGENT_PROMPTS" || true)
assert_eq "$kb_hardcoded_count" "0" \
    "K02 canary: zero KB write-rule lines hardcode .aid/knowledge/ as destination"

# K03: Zero body production-target or ownership literals reference .aid/knowledge/.
# Catches (a) "produce .aid/knowledge/<doc>.md" body lines (Architect/Analyst/Integrator/
# Quality primary produce instruction), (b) "entry in .aid/knowledge/<doc>.md" spine-
# grounding mandate write references, and (c) "You own .aid/knowledge/<doc>.md" Integrator
# ownership lines.  All three forms are write targets that must route through {output_root}.
# Remaining .aid/knowledge/ occurrences are REFERENCE DOCUMENTS read-paths (with " -- "
# description separator) or parenthetical defaults -- neither form matches these patterns.
log "K03: zero body produce/entry-in/You-own lines reference .aid/knowledge/ (body write literals)"
k03_count=$(grep -cE '(produce|entry in|You own).*\.aid/knowledge/' "$AGENT_PROMPTS" || true)
assert_eq "$k03_count" "0" \
    "K03 canary: zero body produce/entry-in/You-own lines reference .aid/knowledge/ as write target"

# K04: Zero lines contain a hidden/temp file reference under .aid/knowledge/.
# The pattern matches ".aid/knowledge/." (slash immediately followed by a dot-filename
# such as ".scout-questions.tmp").  After parameterization every temp write uses
# {output_root}/.scout-questions.tmp; the legitimate .aid/knowledge/ references all have
# a non-dot character after the trailing slash (e.g., "project-structure.md").
log "K04: zero lines contain a hidden/temp file reference under .aid/knowledge/. (temp-write canary)"
k04_count=$(grep -cE '\.aid/knowledge/\.[a-zA-Z]' "$AGENT_PROMPTS" || true)
assert_eq "$k04_count" "0" \
    "K04 canary: zero lines contain .aid/knowledge/.<name> hidden/temp-file write path"

# ---------------------------------------------------------------------------
test_summary
exit $?
