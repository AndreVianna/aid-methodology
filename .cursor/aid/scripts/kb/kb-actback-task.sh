#!/usr/bin/env bash
# kb-actback-task.sh -- representative-task selector + operational-structure presence check.
#
# Two functions:
#
#   Function (1) -- Representative-task selection.
#     Reads the machine-readable doc-set TSV (filename<TAB>owner<TAB>presence, three fields
#     only -- no concern column; see doc-set-resolve.md).  Emits a fixed, reproducible
#     "do this change" representative-task spec keyed to the project's own KB shape.
#
#     Task shape is selected by a dimension-aware, C9-seeded selector
#     (priority C5->C2->C3->C9, first present dimension wins).  Same doc-set ->
#     byte-identical output.
#
#   Function (2) -- Operational-structure presence check.
#     For each doc in the doc-set TSV, grep for the named operational sections and emit:
#       doc | class | present|absent
#     SCOPED PER THE OWNING-TABLE in concern-model.md (canonical/aid/templates/kb-authoring/):
#       each doc is checked ONLY for the classes its SPINE DIMENSION is expected to carry.
#       dimension-keyed: _dim_owns_class(dim, class) replaces _doc_expects_class(doc, class).
#       domain-glossary.md (C4 -> owns Invariants, not Contracts) is NOT reported
#       "## Contracts absent".
#     Stable-sorted (LC_ALL=C), byte-reproducible.
#
# Usage:
#   kb-actback-task.sh task   --doc-set PATH [--kb-dir PATH] [--output PATH]
#   kb-actback-task.sh check  --doc-set PATH [--kb-dir PATH] [--output PATH]
#   kb-actback-task.sh both   --doc-set PATH [--kb-dir PATH] [--output PATH]
#
#   Subcommands:
#     task   -- emit the representative-task spec (function 1)
#     check  -- emit the operational-structure presence table (function 2)
#     both   -- emit task spec followed by presence table (default)
#
#   --doc-set PATH   TSV file: filename<TAB>owner<TAB>presence (one row per doc).
#                    Accepts the synth_default_seed TSV or a file derived from settings.yml.
#   --kb-dir PATH    Directory containing the KB docs (default: .aid/knowledge).
#   --output PATH    Write output to this file instead of stdout.
#
# Exit codes:
#   0  success (findings are data, not errors)
#   1  input error (required file/dir not found)
#   2  usage error
#
# Invocation path convention (canonical/aid/scripts/kb/kb-actback-task.sh):
#   state-generate.md / state-closure.md render-token convention; full path form.
#   Do NOT drop the aid/ segment.
#
# Coreutils only (grep/awk/sort/tr/cut/wc/mktemp).
# No LLM, no embedding, no python3, no pwsh.
# ASCII-only (C2; test-ascii-only.sh allow-list entry required).
# Byte-reproducible: LC_ALL=C, sorted, no timestamps.

set -euo pipefail
LC_ALL=C
export LC_ALL

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
SUBCMD="both"
DOC_SET_ARG=""
KB_DIR_ARG=""
OUTPUT_ARG=""

if [[ $# -lt 1 ]]; then
  echo "kb-actback-task.sh: subcommand required (task|check|both)" >&2
  exit 2
fi

case "$1" in
  task|check|both)
    SUBCMD="$1"
    shift
    ;;
  -h|--help)
    sed -n '2,60p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    echo "kb-actback-task.sh: unknown subcommand: $1 (expected task|check|both)" >&2
    exit 2
    ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --doc-set)  DOC_SET_ARG="$2"; shift 2 ;;
    --kb-dir)   KB_DIR_ARG="$2";  shift 2 ;;
    --output)   OUTPUT_ARG="$2";  shift 2 ;;
    -h|--help)
      sed -n '2,60p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "kb-actback-task.sh: unknown flag: $1" >&2
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

# ---------------------------------------------------------------------------
# Input validation
# ---------------------------------------------------------------------------
if [[ -z "$DOC_SET" ]]; then
  echo "kb-actback-task.sh: --doc-set is required" >&2
  exit 2
fi

if [[ ! -f "$DOC_SET" ]]; then
  echo "kb-actback-task.sh: --doc-set file not found: $DOC_SET" >&2
  exit 1
fi

if [[ ! -d "$KB_DIR" ]]; then
  echo "kb-actback-task.sh: --kb-dir not found: $KB_DIR" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# OWNING-TABLE (dimension-keyed). Single source: concern-model.md
# "The four operational-guidance classes" owning-table, INVERTED to dimension->classes.
# MUST mirror that table + document-expectations.md "Owns named section(s)".
# Do not edit independently.
#   C1 -> Invariants
#   C2 -> Conventions, Invariants, Contracts
#   C3 -> Conventions
#   C4 -> Invariants
#   C5 -> Conventions, Contracts
#   C7 -> Gotchas
#   (all others -> none of the four classes)
#
# _dim_owns_class DIM CLASS
#   Returns 0 (true) if the owning-table maps DIM as an expected owner of CLASS.
#   Returns 1 (false) otherwise.
#   This prevents over-reporting: a dim not mapped for class X is NOT checked for X.
# ---------------------------------------------------------------------------
_dim_owns_class() {
  local dim="$1"
  local class="$2"

  case "$dim" in
    C1) case "$class" in Invariants) return 0 ;; esac ;;
    C2) case "$class" in Conventions|Invariants|Contracts) return 0 ;; esac ;;
    C3) case "$class" in Conventions) return 0 ;; esac ;;
    C4) case "$class" in Invariants) return 0 ;; esac ;;
    C5) case "$class" in Conventions|Contracts) return 0 ;; esac ;;
    C7) case "$class" in Gotchas) return 0 ;; esac ;;
  esac
  return 1
}

# ---------------------------------------------------------------------------
# FILENAME -> SPINE-DIMENSION RESOLVER
# Single source: domain-doc-matrix.md (canonical/aid/templates/kb-authoring/).
# Covers every matrix-emittable filename across all 8 curated domains.
# Unknown/custom filenames return "" -> no owning-table rows (safe degradation).
# Opt-in auto-detect still fires for any section physically present.
# Do not edit independently of domain-doc-matrix.md.
#
# _dim_of_filename FILENAME
#   Sets the global _DIM to the spine dimension (C0..C9, D, meta) for a known
#   filename, or "" for unknown/custom filenames.  Assigns a global variable
#   (rather than echoing) so callers avoid a command-substitution fork per doc
#   -- each fork costs ~1s on Windows Git Bash.  Every case arm (including the
#   catch-all) sets _DIM, so it is always defined after a call.
# ---------------------------------------------------------------------------
_DIM=""
_dim_of_filename() {
  local fn="$1"
  case "$fn" in
    # C0 Technology / medium
    technology-stack.md|tooling-stack.md) _DIM="C0" ;;
    # C1 Build & shape
    project-structure.md|architecture.md|design-system.md|\
    information-architecture.md|methodology.md|platform-topology.md|\
    process-architecture.md) _DIM="C1" ;;
    # C2 Parts & connections
    module-map.md|integration-map.md|pipeline-contracts.md|\
    component-inventory.md|content-map.md|data-pipeline.md|\
    deployment-map.md|evidence-map.md|workflow-map.md) _DIM="C2" ;;
    # C3 Conventions
    coding-standards.md|analysis-conventions.md|authoring-conventions.md|\
    design-principles.md|ops-conventions.md|style-guide.md) _DIM="C3" ;;
    # C4 Vocabulary
    domain-glossary.md|glossary.md) _DIM="C4" ;;
    # C5 Data & contracts
    schemas.md|artifact-schemas.md|config-schemas.md|content-model.md|\
    data-schemas.md|design-tokens.md|evidence-sources.md) _DIM="C5" ;;
    # C6 Quality & checking
    test-landscape.md|accessibility-landscape.md|editorial-process.md|\
    evaluation-landscape.md|quality-gates.md|runbook-landscape.md|\
    validation-landscape.md) _DIM="C6" ;;
    # C7 Risk & debt
    tech-debt.md|limitations.md) _DIM="C7" ;;
    # C8 Shipping & operation
    infrastructure.md|delivery-pipeline.md|dissemination.md|\
    publishing-pipeline.md) _DIM="C8" ;;
    # C9 What it does for users
    feature-inventory.md|capability-inventory.md|content-inventory.md|\
    design-overview.md|model-cards.md|repo-presentation.md|\
    research-questions.md|service-inventory.md) _DIM="C9" ;;
    # D Decisions & rationale
    decisions.md|experiment-log.md|findings-log.md) _DIM="D" ;;
    # meta Orientation / cross-cutting
    external-sources.md|README.md) _DIM="meta" ;;
    # Unknown / custom filenames: safe degradation
    *) _DIM="" ;;
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
# Function (1): Representative-task selection (dimension-aware + C9-seeded)
#
# Parse the doc-set TSV; resolve each filename to its spine dimension via
# _dim_of_filename; pick a task shape from the load-bearing dimensions present
# (priority C5->C2->C3->C9, first match wins); seed the task noun from the
# C9 doc (if present).  Same doc-set -> byte-identical output.
#
# Priority rationale (mirrors concern-model.md owning-table + today's contract>module
# ordering): C5 (data/contracts) beats C2 (parts/connections) beats C3 (conventions)
# beats C9 (capabilities).  "endpoint" is only reachable when none of these four
# dimensions are present -- software always has all of them.
# ---------------------------------------------------------------------------
_run_task() {
  local tsv="$1"
  local kb_dir="$2"

  # Parse filenames from TSV (sorted for determinism)
  local files_tmp
  files_tmp="$(mktemp)"
  _parse_docset "$tsv" > "$files_tmp"

  # Resolve each filename to its spine dimension and track which load-bearing
  # dimensions are present, plus the first (LC_ALL=C-sorted) C9 doc name.
  local has_C5=0 has_C2=0 has_C3=0 has_C9=0
  local c9_doc=""

  while IFS= read -r fname; do
    local dim
    _dim_of_filename "$fname"
    dim="$_DIM"
    case "$dim" in
      C5) has_C5=1 ;;
      C2) has_C2=1 ;;
      C3) has_C3=1 ;;
      C9)
        has_C9=1
        # Pick the LC_ALL=C-first C9 doc for determinism (files_tmp is already sorted).
        # Because _parse_docset emits sorted output, the first C9 we encounter is the
        # LC_ALL=C-minimal one -- set only on first encounter.
        if [[ -z "$c9_doc" ]]; then
          c9_doc="$fname"
        fi
        ;;
    esac
  done < "$files_tmp"

  # Task-shape: dimension-aware + C9-seeded (priority C5->C2->C3->C9).
  local task_type="endpoint"
  if [[ $has_C5 -eq 1 ]]; then
    task_type="contract"
  elif [[ $has_C2 -eq 1 ]]; then
    task_type="module"
  elif [[ $has_C3 -eq 1 ]]; then
    task_type="component"
  elif [[ $has_C9 -eq 1 ]]; then
    task_type="feature"
  fi

  # Emit the representative-task spec (fixed, labelled block -- byte-reproducible)
  echo "## Representative Task Spec"
  echo ""
  echo "**Act-back mandate (M4) -- clean-context operational probe**"
  echo ""
  echo "Using ONLY the KB docs provided, perform the following representative task"
  echo "for this project.  Produce a correct plan/outline for the change in the"
  echo "project's own conventions, AND flag every point where the KB was insufficient"
  echo "(every assumption made, every invariant guessed, every convention missing,"
  echo "every contract not stated)."
  echo ""
  echo "**Task shape: ${task_type}**"
  echo ""

  case "$task_type" in
    contract)
      # C5 present: data/contracts doc is the seed.
      echo "**Task:** Add a new field to a data contract or schema."
      echo ""
      echo "Specifically:"
      echo "1. Identify which contract/schema the new field belongs to, using the KB."
      echo "2. Describe the exact steps to add the field: name, type, validation,"
      echo "   and any invariants it must satisfy."
      echo "3. List all downstream consumers of the contract that must be updated,"
      echo "   as described in the KB."
      echo "4. State the conventions for naming and typing the new field (from the KB)."
      echo "5. Flag every point where the KB did not provide the necessary guidance"
      echo "   and you had to assume or guess."
      ;;
    module)
      # C2 present (no C5): parts/connections doc is the seed.
      echo "**Task:** Wire a new module into the system."
      echo ""
      echo "Specifically:"
      echo "1. Identify the correct location and naming convention for the new module,"
      echo "   using the KB."
      echo "2. Describe how to register/connect the module to the existing system"
      echo "   (following the project's conventions, as stated in the KB)."
      echo "3. List the invariants the new module must satisfy."
      echo "4. Identify any gotchas or non-obvious steps the KB warns about."
      echo "5. Flag every point where the KB did not provide the necessary guidance"
      echo "   and you had to assume or guess."
      ;;
    component)
      # C3 present (no C5/C2): conventions doc is the seed.
      echo "**Task:** Make a change that must follow the project's conventions."
      echo ""
      echo "Specifically:"
      echo "1. Identify the relevant convention(s) the change must follow, using the KB."
      echo "2. Describe the exact steps to make the change in a convention-compliant way"
      echo "   (naming, registration, wiring -- as stated in the KB)."
      echo "3. List any invariants the change must satisfy."
      echo "4. Identify any gotchas or non-obvious steps the KB warns about."
      echo "5. Flag every point where the KB did not provide the necessary guidance"
      echo "   and you had to assume or guess."
      ;;
    feature)
      # C9 present (no C5/C2/C3): capabilities doc is the seed.
      if [[ -n "$c9_doc" ]]; then
        echo "**Task:** Add a new capability of the kind catalogued in ${c9_doc}."
      else
        echo "**Task:** Add a new user-facing capability to the project."
      fi
      echo ""
      echo "Specifically:"
      if [[ -n "$c9_doc" ]]; then
        echo "1. Using ${c9_doc}, pick one representative existing capability and describe"
        echo "   how a new, similar capability would be added to the project."
      else
        echo "1. Describe how a new capability fits into the project's existing inventory,"
        echo "   using the KB."
      fi
      echo "2. List the conventions for implementing and exposing the capability"
      echo "   (from the KB)."
      echo "3. Identify the contracts (schemas, interfaces) the capability must satisfy"
      echo "   or extend."
      echo "4. Note any quality/testing expectations the KB describes for new capabilities."
      echo "5. Flag every point where the KB did not provide the necessary guidance"
      echo "   and you had to assume or guess."
      ;;
    endpoint|*)
      # No C5/C2/C3/C9 present: fallback only (e.g. a doc-set of only C7 docs).
      echo "**Task:** Add a new entry point to the project."
      echo ""
      echo "Specifically:"
      echo "1. Identify the correct location and naming convention for the new entry point,"
      echo "   using the KB."
      echo "2. Describe the registration/wiring steps following the project's conventions"
      echo "   (as stated in the KB)."
      echo "3. List the contracts (request/response shape, invariants) the entry point must"
      echo "   satisfy, as described in the KB."
      echo "4. Note any gotchas or non-obvious steps the KB warns about."
      echo "5. Flag every point where the KB did not provide the necessary guidance"
      echo "   and you had to assume or guess."
      ;;
  esac

  echo ""
  echo "**Scoring:**"
  echo "- PASS: a correct, executable plan is producible from the KB alone, with no"
  echo "  insufficiency flags."
  echo "- FAIL: the plan cannot be produced correctly from the KB, OR any insufficiency"
  echo "  flag is raised.  Each flag is a [HIGH] [ACTBACK] finding."
  echo ""
  echo "**Doc set used for this task (machine-readable substrate):**"
  # Emit sorted filename list (from already-sorted files_tmp)
  while IFS= read -r fn; do
    echo "- ${fn}"
  done < "$files_tmp"

  rm -f "$files_tmp"
}

# ---------------------------------------------------------------------------
# Function (2): Operational-structure presence check (dimension-keyed)
#
# For each doc in the doc-set TSV:
#   - Resolve the doc's spine dimension via _dim_of_filename.
#   - Determine which operational classes the doc is EXPECTED to carry
#     (via the dimension-keyed owning-table _dim_owns_class).
#   - Also auto-detect: if a doc (known or custom) carries a section, it is
#     reported as present (opt-in ownership -- dimension-independent).
#   - Grep for the named section headings: ## Conventions / ## Invariants /
#     ## Gotchas / ## Contracts.
#   - Emit: doc | class | present|absent
#     ONLY for expected classes (prevents over-reporting legitimate absences).
#
# Output: stable-sorted (LC_ALL=C sort), byte-reproducible.
# Table format mirrors closure-check.sh's coverage-table shape.
# ---------------------------------------------------------------------------
_run_check() {
  local tsv="$1"
  local kb_dir="$2"

  echo "## Operational-Structure Presence Check"
  echo ""
  echo "| doc | class | status |"
  echo "|-----|-------|--------|"

  # Build rows in a temp file for stable sorting
  local rows_tmp
  rows_tmp="$(mktemp)"

  local files_tmp
  files_tmp="$(mktemp)"
  _parse_docset "$tsv" > "$files_tmp"

  # Substrates for the O(1)-spawn presence scan.  The old body spawned one
  # `grep -qE` per (doc x class) -- O(4N) forks at ~1s each on Windows Git Bash.
  # We now (1) build the EXPECTED (owning-table) rows in pure bash (no spawns),
  # and (2) detect PRESENT sections for the whole doc set in a SINGLE awk pass.
  # The emitted row set is the UNION of expected and present (status "present"
  # iff the section is physically there) -- identical per-cell semantics to the
  # old loop -- and is stable-sorted below, so output is byte-identical.
  local expected_tmp pathmap_tmp present_tmp
  expected_tmp="$(mktemp)"
  pathmap_tmp="$(mktemp)"
  present_tmp="$(mktemp)"
  : > "$expected_tmp"
  : > "$pathmap_tmp"
  : > "$present_tmp"

  # Doc paths that physically exist (become the awk args for the presence pass).
  local _docpaths=()

  while IFS= read -r fname; do
    local doc_path="${kb_dir}/${fname}"

    # Resolve the spine dimension for this filename (empty for unknown/custom docs).
    # (_dim_of_filename sets the global _DIM -- no command-substitution fork.)
    local dim
    _dim_of_filename "$fname"
    dim="$_DIM"

    # (1) EXPECTED rows: owning-table marks this doc's dimension as a class owner.
    #     (May be absent on disk -> reported "absent" below; pure-bash, no spawns.)
    local class
    for class in Conventions Invariants Gotchas Contracts; do
      if [[ -n "$dim" ]] && _dim_owns_class "$dim" "$class"; then
        printf '%s\t%s\n' "$fname" "$class" >> "$expected_tmp"
      fi
    done

    # (2) Register existing docs for the single-pass presence scan.
    if [[ -f "$doc_path" ]]; then
      printf '%s\t%s\n' "$doc_path" "$fname" >> "$pathmap_tmp"
      _docpaths+=("$doc_path")
    fi
  done < "$files_tmp"

  rm -f "$files_tmp"

  # PRESENT sections: ONE awk pass over every existing doc (was O(4N) grep forks).
  # Reproduces the old per-class `grep -qE "^## ${class}([[:space:]].*)?$"` EXACTLY:
  # the heading must be a clean IDENTIFIER with an OPTIONAL whitespace-led suffix --
  # "## Conventions", "## Conventions (Recurring-Change Checklist)", "## Conventions
  # ..." all count, but "## Conventionsfoo" does not (class name must be followed by
  # whitespace or EOL).  (Same heading-idempotency rule as the
  # closure checker.)  LC_ALL=C is exported, so [[:space:]] is byte-wise like grep.
  # The path->filename map (first awk file) keys presence rows by the doc's filename.
  if [[ ${#_docpaths[@]} -gt 0 ]]; then
    awk -F'\t' '
      FNR==NR { fnof[$1]=$2; next }
      FNR==1  { curfn = fnof[FILENAME] }
      /^## Conventions([[:space:]].*)?$/ { seen[curfn "\tConventions"]=1 }
      /^## Invariants([[:space:]].*)?$/  { seen[curfn "\tInvariants"]=1 }
      /^## Gotchas([[:space:]].*)?$/     { seen[curfn "\tGotchas"]=1 }
      /^## Contracts([[:space:]].*)?$/   { seen[curfn "\tContracts"]=1 }
      END { for (k in seen) print k }
    ' "$pathmap_tmp" "${_docpaths[@]}" > "$present_tmp"
  fi

  # Emit rows = UNION(expected, present); status "present" iff in the present set.
  #   (a) the owning-table marks this doc's dimension as an expected owner
  #       (may be absent -> finding), OR
  #   (b) the section is actually present (auto-detect opt-in ownership -> present).
  # This prevents false-absent for non-owner dims (e.g. C4/domain-glossary.md for
  # Contracts) while still surfacing opt-in sections carried outside the default set.
  awk -F'\t' -v pf="$present_tmp" '
    BEGIN {
      while ((getline line < pf) > 0) {
        n = split(line, a, "\t")
        if (n >= 2) {
          k = a[1] "\t" a[2]
          present[k] = 1; key[k] = 1; ff[k] = a[1]; cc[k] = a[2]
        }
      }
      close(pf)
    }
    {
      k = $1 "\t" $2
      key[k] = 1; ff[k] = $1; cc[k] = $2
    }
    END {
      for (k in key) {
        st = (k in present) ? "present" : "absent"
        print "| " ff[k] " | " cc[k] " | " st " |"
      }
    }
  ' "$expected_tmp" >> "$rows_tmp"

  rm -f "$expected_tmp" "$pathmap_tmp" "$present_tmp"

  # Stable sort for byte-reproducibility (LC_ALL=C already exported)
  sort "$rows_tmp"
  rm -f "$rows_tmp"
}

# ---------------------------------------------------------------------------
# Main dispatch
# ---------------------------------------------------------------------------
_main() {
  local subcmd="$1"
  local tsv="$2"
  local kb_dir="$3"
  local output="$4"

  local out_tmp
  out_tmp="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '$out_tmp'" EXIT

  case "$subcmd" in
    task)
      _run_task "$tsv" "$kb_dir" > "$out_tmp"
      ;;
    check)
      _run_check "$tsv" "$kb_dir" > "$out_tmp"
      ;;
    both)
      _run_task "$tsv" "$kb_dir" > "$out_tmp"
      echo "" >> "$out_tmp"
      _run_check "$tsv" "$kb_dir" >> "$out_tmp"
      ;;
  esac

  if [[ -n "$output" ]]; then
    mkdir -p "$(dirname "$output")"
    cp "$out_tmp" "$output"
    echo "[kb-actback-task] Wrote output to $output" >&2
  else
    cat "$out_tmp"
  fi
}

_main "$SUBCMD" "$DOC_SET" "$KB_DIR" "$OUTPUT_ARG"
echo "[kb-actback-task] Done." >&2
