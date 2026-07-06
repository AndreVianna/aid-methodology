#!/usr/bin/env bash
# test-kb-review-surface.sh -- work-012. The `list_reviewable` accessor
# (canonical/skills/aid-discover/references/doc-set-resolve.md) computes the "reviewed
# knowledge surface" consumed by the M3 (Essence) and M4 (Assertiveness) keystone gates.
# It MUST yield exactly the hand-authored knowledge docs -- kb-category != meta AND
# source != generated -- so meta process/ledger docs (STATE.md, README.md,
# external-sources.md) and generated docs (INDEX.md) can't poison the keystone gates
# (which force grade <= D). primary/extension docs are kept; a doc with no frontmatter
# defaults to reviewable (the surface never shrinks below the primary docs).
#
#   RS01 primary + hand-authored kept
#   RS02 extension kept
#   RS03 meta ledgers excluded (STATE.md, README.md, external-sources.md)
#   RS04 generated docs excluded (INDEX.md)
#   RS05 no-frontmatter doc defaults to reviewable (surface never shrinks)
#   RS06 deterministic across runs
#
# Auto-discovered by tests/run-all.sh. Usage: bash test-kb-review-surface.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u
VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
RESOLVE_DOC="${REPO}/canonical/skills/aid-discover/references/doc-set-resolve.md"
source "${SCRIPT_DIR}/../lib/assert.sh"
echo "== test-kb-review-surface.sh =="
[[ -f "$RESOLVE_DOC" ]] || { echo "FATAL: doc-set-resolve.md not found at $RESOLVE_DOC" >&2; exit 2; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Extract the CANONICAL list_reviewable() definition from the reference doc and source it,
# so this test guards against drift between the doc and the asserted behavior.
WRAP="$TMP/list_reviewable.sh"
{ echo '#!/usr/bin/env bash'
  awk '/^list_reviewable\(\) \{/{p=1} p{print} p && /^\}/{exit}' "$RESOLVE_DOC"
} > "$WRAP"
# shellcheck source=/dev/null
source "$WRAP"
if ! declare -F list_reviewable >/dev/null; then
  fail "RS00 could not extract list_reviewable() from doc-set-resolve.md"
  test_summary; exit 1
fi

# Build a KB fixture with every (category, source) combination.
KB="$TMP/knowledge"; mkdir -p "$KB"
printf -- '---\nkb-category: primary\nsource: hand-authored\n---\nbody\n'   > "$KB/architecture.md"
printf -- '---\nkb-category: extension\nsource: hand-authored\n---\nbody\n' > "$KB/decisions.md"
printf -- '---\nkb-category: meta\nsource: hand-authored\n---\nbody\n'      > "$KB/STATE.md"
printf -- '---\nkb-category: meta\nsource: hand-authored\n---\nbody\n'      > "$KB/README.md"
printf -- '---\nkb-category: meta\nsource: hand-authored\n---\nbody\n'      > "$KB/external-sources.md"
printf -- '---\nkb-category: primary\nsource: generated\n---\nbody\n'       > "$KB/INDEX.md"
printf -- 'no frontmatter here at all\n'                                    > "$KB/nofm.md"

OUT="$(list_reviewable "$KB")"
[[ "$VERBOSE" -eq 1 ]] && { echo "--- list_reviewable output ---"; printf '%s\n' "$OUT"; }
has() { printf '%s\n' "$OUT" | grep -q "/$1$"; }

has architecture.md && pass "RS01 keeps primary+hand-authored (architecture.md)" \
                    || fail "RS01 dropped primary doc architecture.md"

has decisions.md && pass "RS02 keeps extension (decisions.md)" \
                 || fail "RS02 dropped extension doc decisions.md"

if has STATE.md || has README.md || has external-sources.md; then
  fail "RS03 meta ledger leaked into the review surface (STATE.md / README.md / external-sources.md)"
else
  pass "RS03 excludes meta ledgers (STATE.md, README.md, external-sources.md)"
fi

has INDEX.md && fail "RS04 generated INDEX.md leaked into the review surface" \
             || pass "RS04 excludes generated docs (INDEX.md, source: generated)"

has nofm.md && pass "RS05 no-frontmatter doc defaults to reviewable (surface never shrinks)" \
            || fail "RS05 dropped a no-frontmatter doc -- surface shrank below primary"

OUT2="$(list_reviewable "$KB")"
[[ "$OUT" == "$OUT2" ]] && pass "RS06 deterministic across runs (sorted, LC_ALL=C)" \
                        || fail "RS06 non-deterministic output"

test_summary
