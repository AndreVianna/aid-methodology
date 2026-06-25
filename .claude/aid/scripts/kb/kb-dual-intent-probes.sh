#!/usr/bin/env bash
# kb-dual-intent-probes.sh -- Dual-intent probe-derivation helper.
#
# Derives the two probe sets used by the Dual-Intent KB Self-Evaluation (feature-016 D-015):
#
#   Work probes   (Intent 1 / assertiveness limb / Blind Work-Simulation):
#     K representative tasks derived from the C9 capability/what-it-does doc + the domain.
#     Each probe is "add / modify / extend <<a real capability>>" shaped to exercise the
#     load-bearing spine dimensions (C5 data/contracts, C3 conventions, C2 parts, C6
#     quality).  Reuses D-014's C9-derived selector (_dim_of_filename + dimension-aware
#     priority) as the deterministic seed.  One work probe per load-bearing dimension
#     present in the doc-set (minimum K=1, scaled by triage size).
#
#   Essence probes (Intent 2 / essence limb / Blind Reconstruction + Source Confrontation):
#     "what is X / how does Y work / why Z" probes over the project's load-bearing
#     concepts.  Seeded from the C4 vocabulary doc (terms), the C9 capability doc
#     (capability names), and the D decisions doc (decision topics).  Domain-general:
#     derives from the project's own docs, no hardcoded per-domain probe list.
#
# Both probe sets are:
#   - Deterministic: same doc-set + same C9/C4/D docs -> byte-identical output (NFR-3).
#   - Spine-keyed: each probe is tagged with the dimensions it exercises.
#   - Spread across spine dimensions with a minimum count.
#   - Cacheable: a PROBE-CACHE sentinel is emitted; re-run checks the cache file and
#     skips re-derivation when the cache is fresh (cost mitigation, feature-016 SS8).
#   - Human-confirm/extend hook: a "PROBE-EXTEND" section is emitted at the gate for
#     the human reviewer to confirm or extend the probe set (no-assumptions pattern).
#
# Usage:
#   kb-dual-intent-probes.sh work    --doc-set PATH [--kb-dir PATH] [--output PATH]
#                                    [--triage-size small|medium|large]
#   kb-dual-intent-probes.sh essence --doc-set PATH [--kb-dir PATH] [--output PATH]
#                                    [--triage-size small|medium|large]
#   kb-dual-intent-probes.sh both    --doc-set PATH [--kb-dir PATH] [--output PATH]
#                                    [--triage-size small|medium|large]
#   kb-dual-intent-probes.sh check-cache --cache PATH --doc-set PATH [--output PATH]
#
#   Subcommands:
#     work         -- emit work probes (Intent 1) only
#     essence      -- emit essence probes (Intent 2) only
#     both         -- emit work probes then essence probes (default)
#     check-cache  -- check whether a prior probe file (--cache) is still valid for
#                     the given doc-set; exits 0 if valid (use cached), 1 if stale
#
#   --doc-set PATH   TSV file: filename<TAB>owner<TAB>presence (one row per doc).
#                    Same format consumed by kb-actback-task.sh.
#   --kb-dir PATH    Directory containing the KB docs (default: .aid/knowledge).
#                    Used to extract terms from C4/C9/D docs.
#   --output PATH    Write output to this file instead of stdout.
#   --triage-size    small (K=1 per dimension), medium (K=2), large (K=3).
#                    Default: medium.
#   --cache PATH     (check-cache only) path to the prior probe output file.
#
# Exit codes:
#   0  success
#   1  input error (required file/dir not found)
#   2  usage error
#
# Probe output format (plain text, sections delimited by ## headers):
#
#   ## Work Probes (Intent 1 -- Assertiveness / Blind Work-Simulation)
#   ...
#   [PROBE-CACHE] doc-set:<sha256> kb-dir:<sha256>
#   [PROBE-EXTEND] Confirm or extend the probe set at the review gate.
#
#   ## Essence Probes (Intent 2 -- Essence / Blind Reconstruction + Source Confrontation)
#   ...
#
# Probe format per item:
#   WP-NNN [dims:C5,C3,C2,C6] Add a <capability name> to <capability>: <step instructions>
#   EP-NNN [dims:C4]           What is <term>?
#   EP-NNN [dims:C9]           How does <capability> work?
#   EP-NNN [dims:D]            Why was <decision> made?
#
# Invocation path convention (canonical/aid/scripts/kb/kb-dual-intent-probes.sh):
#   state-review.md render-token convention; full path form.
#   Do NOT drop the aid/ segment.
#
# Coreutils only (grep/awk/sort/tr/cut/wc/mktemp/sha256sum).
# No LLM, no embedding, no python3, no pwsh.
# ASCII-only (C2; test-ascii-only.sh allow-list entry required).
# Byte-reproducible: LC_ALL=C, sorted, no timestamps (NFR-3).
#
# Implementation note -- sharing with kb-actback-task.sh:
#   _dim_of_filename and _parse_docset are replicated here (not sourced from
#   kb-actback-task.sh) to keep each script self-contained per the single-script
#   deployment contract.  Both copies MUST stay in sync with domain-doc-matrix.md.
#   Do not edit independently.

set -euo pipefail
LC_ALL=C
export LC_ALL

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
SUBCMD=""
DOC_SET_ARG=""
KB_DIR_ARG=""
OUTPUT_ARG=""
TRIAGE_SIZE="medium"
CACHE_ARG=""

if [[ $# -lt 1 ]]; then
  echo "kb-dual-intent-probes.sh: subcommand required (work|essence|both|check-cache)" >&2
  exit 2
fi

case "$1" in
  work|essence|both|check-cache)
    SUBCMD="$1"
    shift
    ;;
  -h|--help)
    sed -n '2,60p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    echo "kb-dual-intent-probes.sh: unknown subcommand: $1 (expected work|essence|both|check-cache)" >&2
    exit 2
    ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --doc-set)      DOC_SET_ARG="$2";    shift 2 ;;
    --kb-dir)       KB_DIR_ARG="$2";     shift 2 ;;
    --output)       OUTPUT_ARG="$2";     shift 2 ;;
    --triage-size)  TRIAGE_SIZE="$2";    shift 2 ;;
    --cache)        CACHE_ARG="$2";      shift 2 ;;
    -h|--help)
      sed -n '2,60p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "kb-dual-intent-probes.sh: unknown flag: $1" >&2
      exit 2
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
resolve_abs() {
  local p="$1"
  case "$p" in
    /*) echo "$p" ;;
    *)  echo "$PWD/$p" ;;
  esac
}

KB_DIR="${KB_DIR_ARG:-.aid/knowledge}"
KB_DIR="$(resolve_abs "$KB_DIR")"

if [[ -n "$DOC_SET_ARG" ]]; then
  DOC_SET="$(resolve_abs "$DOC_SET_ARG")"
else
  DOC_SET=""
fi

if [[ -n "$OUTPUT_ARG" ]]; then
  OUTPUT_ARG="$(resolve_abs "$OUTPUT_ARG")"
fi

if [[ -n "$CACHE_ARG" ]]; then
  CACHE_ARG="$(resolve_abs "$CACHE_ARG")"
fi

# ---------------------------------------------------------------------------
# Triage-size -> K (probes per load-bearing dimension)
# ---------------------------------------------------------------------------
case "$TRIAGE_SIZE" in
  small)  K=1 ;;
  medium) K=2 ;;
  large)  K=3 ;;
  *)
    echo "kb-dual-intent-probes.sh: unknown triage-size: $TRIAGE_SIZE (expected small|medium|large)" >&2
    exit 2
    ;;
esac

# ---------------------------------------------------------------------------
# Input validation (for subcommands that need doc-set)
# ---------------------------------------------------------------------------
_require_doc_set() {
  if [[ -z "$DOC_SET" ]]; then
    echo "kb-dual-intent-probes.sh: --doc-set is required" >&2
    exit 2
  fi
  if [[ ! -f "$DOC_SET" ]]; then
    echo "kb-dual-intent-probes.sh: --doc-set file not found: $DOC_SET" >&2
    exit 1
  fi
  if [[ ! -d "$KB_DIR" ]]; then
    echo "kb-dual-intent-probes.sh: --kb-dir not found: $KB_DIR" >&2
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# FILENAME -> SPINE-DIMENSION RESOLVER
# Single source: domain-doc-matrix.md (canonical/aid/templates/kb-authoring/).
# Covers every matrix-emittable filename across all 8 curated domains.
# Unknown/custom filenames return "" -> no owning-table rows (safe degradation).
# Do not edit independently of domain-doc-matrix.md.
#
# _dim_of_filename FILENAME
#   Returns the spine dimension (C0..C9, D, meta) for a known filename.
#   Returns "" for unknown/custom filenames.
# ---------------------------------------------------------------------------
_dim_of_filename() {
  local fn="$1"
  case "$fn" in
    # C0 Technology / medium
    technology-stack.md|tooling-stack.md) echo "C0" ;;
    # C1 Build & shape
    project-structure.md|architecture.md|design-system.md|\
    information-architecture.md|methodology.md|platform-topology.md|\
    process-architecture.md) echo "C1" ;;
    # C2 Parts & connections
    module-map.md|integration-map.md|pipeline-contracts.md|\
    component-inventory.md|content-map.md|data-pipeline.md|\
    deployment-map.md|evidence-map.md|workflow-map.md) echo "C2" ;;
    # C3 Conventions
    coding-standards.md|analysis-conventions.md|authoring-conventions.md|\
    design-principles.md|ops-conventions.md|style-guide.md) echo "C3" ;;
    # C4 Vocabulary
    domain-glossary.md|glossary.md) echo "C4" ;;
    # C5 Data & contracts
    schemas.md|artifact-schemas.md|config-schemas.md|content-model.md|\
    data-schemas.md|design-tokens.md|evidence-sources.md) echo "C5" ;;
    # C6 Quality & checking
    test-landscape.md|accessibility-landscape.md|editorial-process.md|\
    evaluation-landscape.md|quality-gates.md|runbook-landscape.md|\
    validation-landscape.md) echo "C6" ;;
    # C7 Risk & debt
    tech-debt.md|limitations.md) echo "C7" ;;
    # C8 Shipping & operation
    infrastructure.md|delivery-pipeline.md|dissemination.md|\
    publishing-pipeline.md) echo "C8" ;;
    # C9 What it does for users
    feature-inventory.md|capability-inventory.md|content-inventory.md|\
    design-overview.md|model-cards.md|repo-presentation.md|\
    research-questions.md|service-inventory.md) echo "C9" ;;
    # D Decisions & rationale
    decisions.md|experiment-log.md|findings-log.md) echo "D" ;;
    # meta Orientation / cross-cutting
    external-sources.md|README.md) echo "meta" ;;
    # Unknown / custom filenames: safe degradation
    *) echo "" ;;
  esac
}

# ---------------------------------------------------------------------------
# Parse the doc-set TSV into a sorted list of filenames.
# TSV format: filename<TAB>owner<TAB>presence (three fields; no concern column).
# Skips blank lines and comment lines.
# ---------------------------------------------------------------------------
_parse_docset() {
  local tsv="$1"
  awk -F'\t' '
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*#/ { next }
    NF >= 1 {
      fn = $1
      sub(/^[[:space:]]+/, "", fn)
      sub(/[[:space:]]+$/, "", fn)
      if (fn != "" && fn != "filename") print fn
    }
  ' "$tsv" | sort -u
}

# ---------------------------------------------------------------------------
# Extract the first-line headings from a KB doc section.
# Used to seed probe nouns from C9/C4/D docs.
#
# _extract_section_items DOC_PATH HEADING_LEVEL SECTION_HEADING
#   Prints lines from the given section (up to the next same-level heading).
#   HEADING_LEVEL: "##" or "###".
#   SECTION_HEADING: the exact section title (e.g. "Features", "Capabilities").
#   Falls back to printing all headings at HEADING_LEVEL if the named section
#   is not found.
# ---------------------------------------------------------------------------
_extract_section_items() {
  local doc_path="$1"
  local level="$2"

  if [[ ! -f "$doc_path" ]]; then
    return
  fi

  # Extract every heading at the given level (## or ###) from the doc.
  # Strips the leading '#' characters and spaces to get just the heading text.
  local level_len="${#level}"
  awk -v level="$level" -v llen="$level_len" '
    /^#{1,6} / {
      # Count the leading # chars
      heading = $0
      n = 0
      while (substr(heading, 1, 1) == "#") { n++; heading = substr(heading, 2) }
      if (n == llen) {
        # Strip leading space
        sub(/^[[:space:]]+/, "", heading)
        # Strip trailing whitespace
        sub(/[[:space:]]+$/, "", heading)
        if (heading != "" && heading != level) print heading
      }
    }
  ' "$doc_path" | sort -u
}

# ---------------------------------------------------------------------------
# Extract terms from a C4 vocabulary doc (domain-glossary.md / glossary.md).
# Looks for bold-or-backtick terms in definition lists and ## headings.
#
# _extract_glossary_terms DOC_PATH
#   Prints one term per line; sorted; max 20 terms for determinism.
# ---------------------------------------------------------------------------
_extract_glossary_terms() {
  local doc_path="$1"

  if [[ ! -f "$doc_path" ]]; then
    return
  fi

  # Strategy (in priority order):
  # 1. Lines of the form "**Term**" or "**Term** :" or "**`Term`**" at line start.
  # 2. Bold terms "**Term**" inline.
  # 3. Heading lines "### Term" or "## Term" (glossary-style).
  # Emit sorted, unique, max 20.
  {
    # Bold-at-start: **Term** or **Term** : or **`Term`**
    grep -oE '^\*\*`?[A-Za-z][A-Za-z0-9 _/-]*`?\*\*' "$doc_path" 2>/dev/null \
      | sed 's/^\*\*`\?//; s/`\?\*\*$//' || true

    # Heading-style glossary entries: ## Term or ### Term (skip metadata headings)
    awk '/^#{2,3} / {
      h = $0
      sub(/^#{2,3}[[:space:]]+/, "", h)
      sub(/[[:space:]]+$/, "", h)
      # Skip common non-term headings
      if (h !~ /^(Change Log|Overview|Summary|Table|Introduction|References|Notes|See Also|Index)/) {
        print h
      }
    }' "$doc_path" 2>/dev/null || true
  } | sort -u | head -20
}

# ---------------------------------------------------------------------------
# Compute a short, stable fingerprint for the doc-set.
# Used as the PROBE-CACHE sentinel value.
# Fingerprint: sha256 of the sorted TSV filenames (the stable logical identity).
# Does NOT include the physical kb-dir path (which varies across machines/runs)
# or doc content (which is read separately and is cost-free for probe derivation).
# Same TSV row set -> same fingerprint (NFR-3).
# ---------------------------------------------------------------------------
_docset_fingerprint() {
  local tsv="$1"
  # kb_dir ($2) intentionally NOT included: physical paths vary across environments.

  _parse_docset "$tsv" | sha256sum | cut -c1-16
}

# ---------------------------------------------------------------------------
# Work-probe verb + noun selection (dimension-aware, C9-seeded).
#
# Each load-bearing dimension (C5, C3, C2, C6) in the doc-set generates a
# distinct work probe shaped to exercise that dimension.
#
# Probe shape per dimension:
#   C5 (Data & contracts):  "Add a new field / token / entry to <C5 doc noun>"
#   C3 (Conventions):       "Make a change that must follow the project's conventions"
#   C2 (Parts & connections): "Wire a new <module/pipeline/component> into the system"
#   C6 (Quality & checking): "Add or extend a test / validation / quality check"
#
# When a C9 doc is present its heading list is used to seed the capability noun
# (making the probe "add X to <real capability>" instead of a generic placeholder).
# Same doc-set -> same probe set (NFR-3).
# ---------------------------------------------------------------------------

# _work_probe_for_dim DIM C9_DOC C9_HEADINGS_FILE PROBE_IDX
#   Emits a single work probe line:
#   WP-NNN [dims:DIM,...]  Task: <verb> <noun>
_work_probe_for_dim() {
  local dim="$1"
  local c9_doc="$2"
  local c9_headings_file="$3"
  local idx="$4"
  local padded_idx
  padded_idx="$(printf '%03d' "$idx")"

  # Pick a capability noun from the C9 headings (if available), otherwise generic.
  # For determinism: pick the Nth heading where N = (idx % line_count) + 1.
  local c9_noun=""
  if [[ -s "$c9_headings_file" ]]; then
    local line_count
    line_count="$(wc -l < "$c9_headings_file")"
    if [[ "$line_count" -gt 0 ]]; then
      local pick_line=$(( (idx % line_count) + 1 ))
      c9_noun="$(awk -v n="$pick_line" 'NR==n { print; exit }' "$c9_headings_file")"
    fi
  fi
  if [[ -z "$c9_noun" ]] && [[ -n "$c9_doc" ]]; then
    # Use the doc basename (strip .md) as noun if no headings extracted
    c9_noun="$(basename "$c9_doc" .md | sed 's/[-_]/ /g')"
  fi
  if [[ -z "$c9_noun" ]]; then
    c9_noun="the project"
  fi

  case "$dim" in
    C5)
      echo "WP-${padded_idx} [dims:C5,C3,C2,C6] Task: Add a new data contract field or schema entry to ${c9_noun}."
      echo "  1. Identify which contract/schema/token set the new field belongs to (from the KB C5 doc)."
      echo "  2. State the field name, type, constraints, and any invariants it must satisfy."
      echo "  3. List all downstream consumers of the contract that must be updated (from the KB)."
      echo "  4. State the naming and typing conventions for the new field (from the KB C3 doc)."
      echo "  5. Note any quality/validation requirements the KB describes for new fields (C6 doc)."
      echo "  6. Flag every step where the KB did not provide sufficient guidance (STATED / ASSUMED / REACH)."
      ;;
    C3)
      echo "WP-${padded_idx} [dims:C3,C2,C6] Task: Make a convention-following change to ${c9_noun}."
      echo "  1. Identify the relevant convention(s) the change must follow (from the KB C3 doc)."
      echo "  2. State the exact steps to make the change in a convention-compliant way."
      echo "  3. List any invariants the change must satisfy (from the KB)."
      echo "  4. Identify any quality/checking requirements (from the KB C6 doc)."
      echo "  5. Flag every step where the KB did not provide sufficient guidance (STATED / ASSUMED / REACH)."
      ;;
    C2)
      echo "WP-${padded_idx} [dims:C2,C3,C5] Task: Wire a new component or pipeline stage into ${c9_noun}."
      echo "  1. Identify the correct location and naming convention for the new part (from KB C2 + C3 docs)."
      echo "  2. Describe how to register/connect the new part to the existing system (following KB conventions)."
      echo "  3. List the data contracts the new part must satisfy or extend (from KB C5 doc)."
      echo "  4. Identify any invariants and gotchas the KB warns about."
      echo "  5. Flag every step where the KB did not provide sufficient guidance (STATED / ASSUMED / REACH)."
      ;;
    C6)
      echo "WP-${padded_idx} [dims:C6,C3,C5] Task: Add or extend a quality check for ${c9_noun}."
      echo "  1. Identify the quality/validation mechanism to extend (from KB C6 doc)."
      echo "  2. State the quality bar and the criterion the new check must satisfy (from KB)."
      echo "  3. Describe the steps to add the check in the project's own conventions (C3 doc)."
      echo "  4. List any contracts the check must respect (C5 doc)."
      echo "  5. Flag every step where the KB did not provide sufficient guidance (STATED / ASSUMED / REACH)."
      ;;
    C9)
      echo "WP-${padded_idx} [dims:C9,C3,C5,C6] Task: Add a new capability to ${c9_noun}."
      echo "  1. Identify how the new capability fits into the existing capability inventory (KB C9 doc)."
      echo "  2. State the conventions for implementing and exposing the capability (KB C3 doc)."
      echo "  3. Identify the contracts the capability must satisfy or extend (KB C5 doc)."
      echo "  4. Note any quality/testing expectations for new capabilities (KB C6 doc)."
      echo "  5. Flag every step where the KB did not provide sufficient guidance (STATED / ASSUMED / REACH)."
      ;;
    *)
      # Generic fallback for any other dimension in the doc-set
      echo "WP-${padded_idx} [dims:${dim}] Task: Add or extend an element governed by the ${dim} dimension of ${c9_noun}."
      echo "  1. Identify the relevant KB doc for dimension ${dim} and find the relevant section."
      echo "  2. State the steps for the change following the KB's guidance."
      echo "  3. Flag every step where the KB did not provide sufficient guidance (STATED / ASSUMED / REACH)."
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Function (1): Work-probe derivation (Intent 1)
#
# Derives K representative work probes from the resolved doc-set, spanning the
# load-bearing dimensions (C5 -> C3 -> C2 -> C6 -> C9, in coverage priority).
# Each probe is tagged with the dimensions it exercises.
# Deterministic: same doc-set -> same probe set (NFR-3).
# ---------------------------------------------------------------------------
_run_work_probes() {
  local tsv="$1"
  local kb_dir="$2"

  # Parse filenames from TSV (sorted for determinism)
  local files_tmp
  files_tmp="$(mktemp)"
  _parse_docset "$tsv" > "$files_tmp"

  # Resolve each filename to its dimension; track which load-bearing dims are present
  # and the first (LC_ALL=C-sorted) C9 doc for noun seeding.
  local has_C5=0 has_C2=0 has_C3=0 has_C6=0 has_C9=0
  local c9_doc=""
  local c5_doc="" c3_doc="" c2_doc="" c6_doc=""

  while IFS= read -r fname; do
    local dim
    dim="$(_dim_of_filename "$fname")"
    case "$dim" in
      C5) has_C5=1; [[ -z "$c5_doc" ]] && c5_doc="$fname" ;;
      C2) has_C2=1; [[ -z "$c2_doc" ]] && c2_doc="$fname" ;;
      C3) has_C3=1; [[ -z "$c3_doc" ]] && c3_doc="$fname" ;;
      C6) has_C6=1; [[ -z "$c6_doc" ]] && c6_doc="$fname" ;;
      C9) has_C9=1; [[ -z "$c9_doc" ]] && c9_doc="$fname" ;;
    esac
  done < "$files_tmp"
  rm -f "$files_tmp"

  # Extract C9 headings for capability-noun seeding (sorted, stable)
  local c9_headings_tmp
  c9_headings_tmp="$(mktemp)"
  if [[ -n "$c9_doc" ]] && [[ -f "${kb_dir}/${c9_doc}" ]]; then
    _extract_section_items "${kb_dir}/${c9_doc}" "##" > "$c9_headings_tmp"
    # If no ## headings found, try ### headings
    if [[ ! -s "$c9_headings_tmp" ]]; then
      _extract_section_items "${kb_dir}/${c9_doc}" "###" > "$c9_headings_tmp"
    fi
  fi

  # Build ordered dimension list for coverage priority (C5->C2->C3->C6->C9).
  # Only include dims present in the doc-set.
  local dims_ordered=""
  [[ $has_C5 -eq 1 ]] && dims_ordered="${dims_ordered} C5"
  [[ $has_C2 -eq 1 ]] && dims_ordered="${dims_ordered} C2"
  [[ $has_C3 -eq 1 ]] && dims_ordered="${dims_ordered} C3"
  [[ $has_C6 -eq 1 ]] && dims_ordered="${dims_ordered} C6"
  [[ $has_C9 -eq 1 ]] && dims_ordered="${dims_ordered} C9"
  # Trim leading space
  dims_ordered="${dims_ordered# }"

  # Compute the cache fingerprint
  local fp
  fp="$(_docset_fingerprint "$tsv" "$kb_dir")"

  echo "## Work Probes (Intent 1 -- Assertiveness / Blind Work-Simulation)"
  echo ""
  echo "Each probe below is a representative task shaped to exercise the load-bearing"
  echo "spine dimensions of this project's doc-set. A clean-context, KB-only agent should"
  echo "be able to plan each task step-by-step in the project's own conventions, tagging"
  echo "each step STATED / ASSUMED / REACH."
  echo ""
  echo "**Scoring:** Any load-bearing ASSUMED or REACH step = [HIGH] [ACTBACK] insufficiency."
  echo "A plan that would work but violates the project's conventions or quality bars = quality FAIL."
  echo "PASS = complete, correct, convention-honoring plan with zero load-bearing insufficiencies."
  echo ""

  if [[ -z "$dims_ordered" ]]; then
    # No load-bearing dimensions found: emit a single generic probe
    echo "WP-001 [dims:generic] Task: Add a new element to the project."
    echo "  1. Identify the correct location and naming for the new element (from the KB)."
    echo "  2. State the steps to add it following the project's conventions."
    echo "  3. Flag every step where the KB did not provide sufficient guidance (STATED / ASSUMED / REACH)."
    echo ""
    echo "[PROBE-CACHE] doc-set:${fp} triage:${TRIAGE_SIZE}"
    echo ""
    echo "[PROBE-EXTEND] Human reviewer: confirm these probes cover load-bearing scenarios,"
    echo "or append additional probes below this line before running the assertiveness limb."
    rm -f "$c9_headings_tmp"
    return
  fi

  # Emit K probes per dimension, cycling through the ordered dimension list.
  # For K=1: one probe per dimension (covers all dims once).
  # For K=2: two probes per dimension (second probe uses next c9_heading).
  # For K=3: three probes per dimension.
  local probe_idx=1
  local k_iter

  for k_iter in $(seq 1 "$K"); do
    local dim
    for dim in $dims_ordered; do
      _work_probe_for_dim "$dim" "$c9_doc" "$c9_headings_tmp" "$probe_idx"
      echo ""
      probe_idx=$(( probe_idx + 1 ))
    done
  done

  echo "[PROBE-CACHE] doc-set:${fp} triage:${TRIAGE_SIZE}"
  echo ""
  echo "[PROBE-EXTEND] Human reviewer: confirm these probes cover load-bearing scenarios,"
  echo "or append additional probes below this line before running the assertiveness limb."

  rm -f "$c9_headings_tmp"
}

# ---------------------------------------------------------------------------
# Essence-probe noun extraction helpers
#
# _essence_terms_from_C4 DOC_PATH    -- glossary term "What is X?" probes
# _essence_caps_from_C9  DOC_PATH    -- capability "How does X work?" probes
# _essence_decs_from_D   DOC_PATH    -- decision "Why was X chosen?" probes
# ---------------------------------------------------------------------------

_essence_terms_from_C4() {
  local doc_path="$1"
  if [[ ! -f "$doc_path" ]]; then
    return
  fi
  _extract_glossary_terms "$doc_path" | head -10
}

_essence_caps_from_C9() {
  local doc_path="$1"
  if [[ ! -f "$doc_path" ]]; then
    return
  fi
  # Extract capability names from ## headings; max 8 for spread
  _extract_section_items "$doc_path" "##" | head -8
}

_essence_decs_from_D() {
  local doc_path="$1"
  if [[ ! -f "$doc_path" ]]; then
    return
  fi
  # Extract decision titles from ## or ### headings; max 6
  _extract_section_items "$doc_path" "##" | head -6
}

# ---------------------------------------------------------------------------
# Function (2): Essence-probe derivation (Intent 2)
#
# Derives "what is X / how does Y work / why Z" probes over the project's
# load-bearing concepts, seeded from:
#   - C4 vocabulary doc: "What is X?" for each glossary term
#   - C9 capability doc: "How does X work?" for each capability
#   - D decisions doc:   "Why was X decided?" for each decision
# Plus a fixed "what/how/why" narrative probe.
#
# Deterministic: same docs -> same probe set (sorted, bounded, NFR-3).
# ---------------------------------------------------------------------------
_run_essence_probes() {
  local tsv="$1"
  local kb_dir="$2"

  # Parse filenames from TSV (sorted for determinism)
  local files_tmp
  files_tmp="$(mktemp)"
  _parse_docset "$tsv" > "$files_tmp"

  # Find the first C4, C9, and D docs (LC_ALL=C-sorted -> deterministic)
  local c4_doc="" c9_doc="" d_doc=""

  while IFS= read -r fname; do
    local dim
    dim="$(_dim_of_filename "$fname")"
    case "$dim" in
      C4) [[ -z "$c4_doc" ]] && c4_doc="$fname" ;;
      C9) [[ -z "$c9_doc" ]] && c9_doc="$fname" ;;
      D)  [[ -z "$d_doc"  ]] && d_doc="$fname" ;;
    esac
  done < "$files_tmp"
  rm -f "$files_tmp"

  # Compute cache fingerprint
  local fp
  fp="$(_docset_fingerprint "$tsv" "$kb_dir")"

  echo "## Essence Probes (Intent 2 -- Essence / Blind Reconstruction + Source Confrontation)"
  echo ""
  echo "Each probe below is answered first by a clean-context, KB-only agent (reconstruct),"
  echo "then verified by a source-grounded agent (confront). Two failure classes:"
  echo "  [HIGH] [FIDELITY]   -- KB-only answer is WRONG vs the source (Divergence)."
  echo "  [MED]  [ESSENCE-GAP] -- A load-bearing source fact could not be supplied (Omission)."
  echo ""
  echo "PASS = no Divergence + load-bearing essence-coverage >= threshold."
  echo ""

  local probe_idx=1
  local padded_idx

  # Fixed narrative probe (always emitted; exercises all dimensions)
  padded_idx="$(printf '%03d' "$probe_idx")"
  echo "EP-${padded_idx} [dims:C0,C1,C2,C3,C4,C5,C6,C7,C8,C9,D] What is this project, how does it work, and why is it shaped the way it is?"
  echo "  Reconstruct: using ONLY the KB, write a coherent what/why/how narrative."
  echo "  Confront: compare the KB-only narrative against the actual project source."
  echo "  Flag: Divergence (wrong) = [HIGH] [FIDELITY]; Omission (missing load-bearing fact) = [MED] [ESSENCE-GAP]."
  echo ""
  probe_idx=$(( probe_idx + 1 ))

  # C4 vocabulary probes: "What is X?" for each glossary term
  local c4_path="${kb_dir}/${c4_doc}"
  if [[ -n "$c4_doc" ]]; then
    local terms_tmp
    terms_tmp="$(mktemp)"
    _essence_terms_from_C4 "$c4_path" > "$terms_tmp"

    if [[ -s "$terms_tmp" ]]; then
      local max_c4=$(( K * 3 ))
      local count=0
      while IFS= read -r term && [[ $count -lt $max_c4 ]]; do
        padded_idx="$(printf '%03d' "$probe_idx")"
        echo "EP-${padded_idx} [dims:C4] What is \"${term}\" in this project?"
        echo "  Reconstruct: answer from KB only (${c4_doc} + any KB doc that defines this term)."
        echo "  Confront: verify the definition matches how the term is actually used in the source."
        echo ""
        probe_idx=$(( probe_idx + 1 ))
        count=$(( count + 1 ))
      done < "$terms_tmp"
    else
      # C4 doc present but no terms extracted: emit a generic C4 probe
      padded_idx="$(printf '%03d' "$probe_idx")"
      echo "EP-${padded_idx} [dims:C4] What are the core vocabulary terms of this project, and how are they defined?"
      echo "  Reconstruct: answer from KB only (${c4_doc})."
      echo "  Confront: verify definitions match actual source usage."
      echo ""
      probe_idx=$(( probe_idx + 1 ))
    fi
    rm -f "$terms_tmp"
  fi

  # C9 capability probes: "How does X work?" for each capability heading
  local c9_path="${kb_dir}/${c9_doc}"
  if [[ -n "$c9_doc" ]]; then
    local caps_tmp
    caps_tmp="$(mktemp)"
    _essence_caps_from_C9 "$c9_path" > "$caps_tmp"

    local max_c9=$(( K * 2 ))
    local count=0

    if [[ -s "$caps_tmp" ]]; then
      while IFS= read -r cap && [[ $count -lt $max_c9 ]]; do
        padded_idx="$(printf '%03d' "$probe_idx")"
        echo "EP-${padded_idx} [dims:C9,C2,C5] How does \"${cap}\" work in this project?"
        echo "  Reconstruct: answer from KB only (${c9_doc} + any KB doc describing this capability)."
        echo "  Confront: verify the reconstruction matches the actual implementation in the source."
        echo ""
        probe_idx=$(( probe_idx + 1 ))
        count=$(( count + 1 ))
      done < "$caps_tmp"
    else
      # Generic C9 probe
      padded_idx="$(printf '%03d' "$probe_idx")"
      echo "EP-${padded_idx} [dims:C9] What are the key capabilities of this project and how does each work?"
      echo "  Reconstruct: answer from KB only (${c9_doc})."
      echo "  Confront: verify against actual source capabilities."
      echo ""
      probe_idx=$(( probe_idx + 1 ))
    fi
    rm -f "$caps_tmp"
  fi

  # D decisions probes: "Why was X decided?" for each decision heading
  local d_path="${kb_dir}/${d_doc}"
  if [[ -n "$d_doc" ]]; then
    local decs_tmp
    decs_tmp="$(mktemp)"
    _essence_decs_from_D "$d_path" > "$decs_tmp"

    local max_d=$(( K * 2 ))
    local count=0

    if [[ -s "$decs_tmp" ]]; then
      while IFS= read -r dec && [[ $count -lt $max_d ]]; do
        padded_idx="$(printf '%03d' "$probe_idx")"
        echo "EP-${padded_idx} [dims:D] Why was \"${dec}\" decided, and what was the rejected alternative?"
        echo "  Reconstruct: answer from KB only (${d_doc})."
        echo "  Confront: verify rationale and rejected alternatives match the source record."
        echo ""
        probe_idx=$(( probe_idx + 1 ))
        count=$(( count + 1 ))
      done < "$decs_tmp"
    else
      # Generic D probe
      padded_idx="$(printf '%03d' "$probe_idx")"
      echo "EP-${padded_idx} [dims:D] What are the key decisions made in this project, why were they made, and what was rejected?"
      echo "  Reconstruct: answer from KB only (${d_doc})."
      echo "  Confront: verify rationale and rejected alternatives match the source record."
      echo ""
      probe_idx=$(( probe_idx + 1 ))
    fi
    rm -f "$decs_tmp"
  fi

  # If none of C4/C9/D are present: emit spine-dimension coverage probes for whatever is there
  if [[ -z "$c4_doc" ]] && [[ -z "$c9_doc" ]] && [[ -z "$d_doc" ]]; then
    padded_idx="$(printf '%03d' "$probe_idx")"
    echo "EP-${padded_idx} [dims:C0,C1,C2,C3,C5,C6,C7,C8] What is this project's structure, conventions, and key contracts?"
    echo "  Reconstruct: answer from KB only."
    echo "  Confront: verify against the actual project source."
    echo ""
    probe_idx=$(( probe_idx + 1 ))
  fi

  echo "[PROBE-CACHE] doc-set:${fp} triage:${TRIAGE_SIZE}"
  echo ""
  echo "[PROBE-EXTEND] Human reviewer: confirm these probes cover the load-bearing essence"
  echo "of this project, or append additional probes below this line before running"
  echo "the essence limb."
}

# ---------------------------------------------------------------------------
# check-cache subcommand
#
# Reads a prior probe output file (--cache) and checks whether the embedded
# [PROBE-CACHE] sentinel matches the current doc-set + triage-size.
# Exits 0 if the cache is still valid (re-use it); exits 1 if stale (re-derive).
# ---------------------------------------------------------------------------
_run_check_cache() {
  local cache_file="$1"
  local tsv="$2"

  if [[ -z "$cache_file" ]]; then
    echo "kb-dual-intent-probes.sh: --cache is required for check-cache" >&2
    exit 2
  fi
  if [[ ! -f "$cache_file" ]]; then
    # No cache file -> stale
    exit 1
  fi

  local fp
  fp="$(_docset_fingerprint "$tsv" "$KB_DIR")"

  local expected_sentinel="[PROBE-CACHE] doc-set:${fp} triage:${TRIAGE_SIZE}"

  if grep -qF "$expected_sentinel" "$cache_file" 2>/dev/null; then
    exit 0
  else
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Main dispatch
# ---------------------------------------------------------------------------
_main() {
  local subcmd="$1"

  if [[ "$subcmd" == "check-cache" ]]; then
    if [[ -z "$DOC_SET" ]]; then
      echo "kb-dual-intent-probes.sh: --doc-set is required" >&2
      exit 2
    fi
    if [[ ! -f "$DOC_SET" ]]; then
      echo "kb-dual-intent-probes.sh: --doc-set file not found: $DOC_SET" >&2
      exit 1
    fi
    _run_check_cache "$CACHE_ARG" "$DOC_SET"
    return
  fi

  _require_doc_set

  local out_tmp
  out_tmp="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '$out_tmp'" EXIT

  case "$subcmd" in
    work)
      _run_work_probes "$DOC_SET" "$KB_DIR" > "$out_tmp"
      ;;
    essence)
      _run_essence_probes "$DOC_SET" "$KB_DIR" > "$out_tmp"
      ;;
    both)
      _run_work_probes "$DOC_SET" "$KB_DIR" > "$out_tmp"
      echo "" >> "$out_tmp"
      _run_essence_probes "$DOC_SET" "$KB_DIR" >> "$out_tmp"
      ;;
  esac

  if [[ -n "$OUTPUT_ARG" ]]; then
    mkdir -p "$(dirname "$OUTPUT_ARG")"
    cp "$out_tmp" "$OUTPUT_ARG"
    echo "[kb-dual-intent-probes] Wrote output to $OUTPUT_ARG" >&2
  else
    cat "$out_tmp"
  fi
}

_main "$SUBCMD"
echo "[kb-dual-intent-probes] Done." >&2
