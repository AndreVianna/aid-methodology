#!/usr/bin/env bash
# migrate-kb-frontmatter.sh -- idempotent KB frontmatter migration: intent -> objective/summary/sources.
#
# Migrates hand-authored primary/extension KB docs from the legacy `intent:` frontmatter
# field to the new f001 schema: objective, summary, sources, approved_at_commit.
#
# Two-pass propose->confirm flow (NFR-6/C4 human-gated ethos):
#   1. --propose  Write a worksheet (.aid/.temp/kb-migration-proposal.md) with seeded
#                 objective/summary and proposed sources candidates. Changes NO doc on disk.
#   2. --apply    Read the human-confirmed worksheet and write fields into each doc's
#                 frontmatter. Refuses with exit code 3 if the worksheet is absent.
#
# Idempotency: a doc carrying objective: AND summary: AND a sources: KEY (including
#   sources: []) is skipped. Re-run over a fully-migrated KB is a clean no-op.
#
# Scope discipline (SD-6): operates ONLY on the KB root passed as $1.
#   Never scans $HOME or other paths.
#   In-scope: kb-category in {primary, extension} AND source != generated.
#   Skipped: meta docs, source:generated docs.
#
# Safety (NFR-7):
#   --dry-run   Print every action it would take; write nothing.
#   --rollback  Restore all docs from the most recent backup tree; remove that tree.
#   APPLY backs up each doc to .aid/.temp/kb-migration-backup-<UTC>/<doc> before editing.
#   Verification pass shells out to lint-frontmatter.sh after APPLY; fails loud on any
#   lint finding, pointing at the backup.
#
# Usage:
#   migrate-kb-frontmatter.sh <kb-root> [--propose] [--dry-run]
#   migrate-kb-frontmatter.sh <kb-root> --apply [--dry-run]
#   migrate-kb-frontmatter.sh <kb-root> --rollback
#
# Exit codes:
#   0  success (migrated, propose worksheet written, or no-op)
#   1  bad or absent KB root
#   2  no in-scope docs found in KB root
#   3  --apply with no confirmed worksheet (run --propose first)
#   4  verification failure (lint-frontmatter.sh found issues; backup retained)

set -euo pipefail

SCRIPT_NAME="migrate-kb-frontmatter.sh"

# ---------------------------------------------------------------------------
# Globals
# ---------------------------------------------------------------------------
KB_ROOT=""
MODE="propose"      # propose | apply | rollback
DRY_RUN=0
WARNINGS=()

# ---------------------------------------------------------------------------
# Helpers: log/warn/die all write to stderr so stdout is clean for data.
# ---------------------------------------------------------------------------

log()  { echo "${SCRIPT_NAME}: $*" >&2; }
warn() { echo "${SCRIPT_NAME}: WARNING: $*" >&2; WARNINGS+=("$*"); }
die()  { echo "${SCRIPT_NAME}: ERROR: $*" >&2; exit "${2:-1}"; }

# ---------------------------------------------------------------------------
# Frontmatter helpers (pure awk/grep/sed -- no external deps beyond coreutils)
# ---------------------------------------------------------------------------

# fm_field FILE FIELD -- extract single-line scalar value from frontmatter.
# Returns empty string if field is absent.
fm_field() {
    local f="$1" field="$2"
    awk -v field="$field" '
        BEGIN { in_fm=0 }
        /^---$/ { in_fm = !in_fm; if (NR > 1 && !in_fm) exit; next }
        in_fm && $0 ~ "^"field":" {
            sub("^"field":[[:space:]]*", "")
            print
            exit
        }
    ' "$f"
}

# fm_field_present FILE FIELD -- print "1" if field key is present, "" if absent.
fm_field_present() {
    local f="$1" field="$2"
    awk -v field="$field" '
        BEGIN { in_fm=0; found=0 }
        /^---$/ { in_fm = !in_fm; if (NR > 1 && !in_fm) exit; next }
        in_fm && $0 ~ "^"field":" { found=1; exit }
        END { if (found) print "1" }
    ' "$f"
}

# fm_literal FILE FIELD -- extract multi-line YAML literal (|) block from frontmatter.
fm_literal() {
    local f="$1" field="$2"
    awk -v field="$field" '
        BEGIN { in_fm=0; in_field=0; indent=-1 }
        /^---$/ { in_fm = !in_fm; if (!in_fm) exit; next }
        in_fm && in_field {
            if (indent == -1 && /^[[:space:]]+/) {
                match($0, /^[[:space:]]+/)
                indent = RLENGTH
            }
            if (/^[^[:space:]-]/ || /^[a-zA-Z][a-zA-Z0-9_-]*:/) {
                exit
            }
            sub("^[[:space:]]{" indent "}", "")
            print
            next
        }
        in_fm && $0 ~ "^"field":[[:space:]]*\\|" {
            in_field = 1
            next
        }
    ' "$f"
}

# collapse_lines -- join lines with spaces, squeeze multiple spaces.
# Reads from stdin.
collapse_lines() {
    tr '\n' ' ' | sed 's/  */ /g; s/^ //; s/ $//'
}

# first_sentence -- extract first sentence using bounded predicate:
# [.!?] followed by (whitespace + uppercase ASCII) or end-of-string.
# Caps at 200 chars with ASCII "...". Reads from stdin.
first_sentence() {
    awk '
    {
        line = $0
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        if (length(line) == 0) { next }
        found = 0
        result = line
        n = length(line)
        for (i = 1; i <= n; i++) {
            c = substr(line, i, 1)
            if (c == "." || c == "!" || c == "?") {
                if (i == n) {
                    result = substr(line, 1, i)
                    found = 1
                    break
                }
                next_c = substr(line, i + 1, 1)
                if (next_c == " " || next_c == "\t") {
                    j = i + 1
                    while (j <= n && (substr(line, j, 1) == " " || substr(line, j, 1) == "\t")) {
                        j++
                    }
                    if (j <= n) {
                        after = substr(line, j, 1)
                        if (after >= "A" && after <= "Z") {
                            result = substr(line, 1, i)
                            found = 1
                            break
                        }
                    } else {
                        result = substr(line, 1, i)
                        found = 1
                        break
                    }
                }
            }
        }
        if (length(result) > 200) {
            result = substr(result, 1, 200) "..."
        }
        print result
    }
    '
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --propose)  MODE="propose";  shift ;;
            --apply)    MODE="apply";    shift ;;
            --rollback) MODE="rollback"; shift ;;
            --dry-run)  DRY_RUN=1;       shift ;;
            -h|--help)
                cat <<'HELP'
migrate-kb-frontmatter.sh -- idempotent KB frontmatter migration.

Migrates hand-authored primary/extension KB docs from intent: to the
new f001 schema: objective, summary, sources, approved_at_commit.

Usage:
  migrate-kb-frontmatter.sh <kb-root> [--propose] [--dry-run]
  migrate-kb-frontmatter.sh <kb-root> --apply [--dry-run]
  migrate-kb-frontmatter.sh <kb-root> --rollback

Flags:
  --propose   (default) Write worksheet; change no docs.
  --apply     Read confirmed worksheet; write docs.
  --rollback  Restore docs from most recent backup.
  --dry-run   Print actions; write nothing.

Exit codes:
  0  success
  1  bad/absent KB root
  2  no in-scope docs
  3  --apply with no confirmed worksheet
  4  verification failure (backup retained)
HELP
                exit 0
                ;;
            *)
                if [[ -z "$KB_ROOT" ]]; then
                    KB_ROOT="$1"; shift
                else
                    die "Unexpected argument: $1" 1
                fi
                ;;
        esac
    done

    if [[ -z "$KB_ROOT" ]]; then
        echo "Usage: ${SCRIPT_NAME} <kb-root> [--propose|--apply|--rollback] [--dry-run]" >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Scope selection: find in-scope docs.
# In-scope: kb-category in {primary,extension} AND source != generated.
# Skipped: meta docs, source:generated docs.
# Prints one absolute path per line to stdout; all log messages to stderr.
# ---------------------------------------------------------------------------

find_inscope_docs() {
    local root="$1"
    local f cat src

    while IFS= read -r f; do
        cat="$(fm_field "$f" "kb-category")"
        cat="${cat:-primary}"
        src="$(fm_field "$f" "source")"
        src="${src:-hand-authored}"

        # Skip meta docs
        if [[ "$cat" == "meta" ]]; then
            log "  SKIP (meta): $(basename "$f")"
            continue
        fi

        # Skip generated docs
        if [[ "$src" == "generated" ]]; then
            log "  SKIP (generated): $(basename "$f")"
            continue
        fi

        # Only primary and extension categories
        if [[ "$cat" != "primary" && "$cat" != "extension" ]]; then
            log "  SKIP (category=$cat): $(basename "$f")"
            continue
        fi

        # In-scope: source != generated and category in {primary,extension}
        printf '%s\n' "$f"
    done < <(find "$root" -maxdepth 1 -type f -name '*.md' ! -name '.*' | sort)
}

# ---------------------------------------------------------------------------
# Idempotency check: is a doc already migrated?
# A doc is migrated if it carries objective: AND summary: AND a sources: KEY
# (presence, including sources: []).
# ---------------------------------------------------------------------------

is_migrated() {
    local f="$1"
    local has_obj has_sum has_src
    has_obj="$(fm_field_present "$f" "objective")"
    has_sum="$(fm_field_present "$f" "summary")"
    has_src="$(fm_field_present "$f" "sources")"

    if [[ -n "$has_obj" && -n "$has_sum" && -n "$has_src" ]]; then
        return 0  # migrated
    fi
    return 1  # not migrated
}

# ---------------------------------------------------------------------------
# Candidate sources derivation: grep intent/contracts for path refs and URLs.
# Output goes to stdout; one candidate per line.
# ---------------------------------------------------------------------------

propose_sources_candidates() {
    local f="$1"
    local intent_text contracts_text combined

    # Extract intent (literal block)
    intent_text="$(fm_literal "$f" "intent")"
    # Extract contracts block
    contracts_text="$(awk '
        BEGIN { in_fm=0; in_field=0; indent=-1 }
        /^---$/ { in_fm = !in_fm; if (!in_fm) exit; next }
        in_fm && in_field {
            if (indent == -1 && /^[[:space:]]+/) {
                match($0, /^[[:space:]]+/)
                indent = RLENGTH
            }
            if (/^[^[:space:]-]/ || /^[a-zA-Z][a-zA-Z0-9_-]*:/) { exit }
            sub("^[[:space:]]{" indent "}", "")
            print
            next
        }
        in_fm && /^contracts:/ { in_field=1; next }
    ' "$f")"

    combined="${intent_text}"$'\n'"${contracts_text}"

    # (a) repo path refs: tokens with file extensions
    local path_refs
    path_refs="$(printf '%s' "$combined" | grep -oE '[a-zA-Z0-9_./-]+(\.sh|\.py|\.md|\.js|\.mjs|\.ts|\.yml|\.yaml|\.json|\.toml|\.txt|\.ps1|\.cmd)' 2>/dev/null | sort -u || true)"

    # Also grep for bare directory-looking refs
    local dir_refs
    dir_refs="$(printf '%s' "$combined" | grep -oE '(canonical|profiles|\.aid|tests|lib|bin|packages|dashboard|docs|\.github)/[a-zA-Z0-9_./-]+' 2>/dev/null | grep -v '\.$' | sort -u || true)"

    # (b) external URLs
    local urls
    urls="$(printf '%s' "$combined" | grep -oE 'https?://[a-zA-Z0-9_./?=#&%+:~-]+' 2>/dev/null | sort -u || true)"

    # Combine and deduplicate
    printf '%s\n%s\n%s\n' "$path_refs" "$dir_refs" "$urls" | grep -v '^[[:space:]]*$' | sort -u || true
}

# ---------------------------------------------------------------------------
# PROPOSE pass: write worksheet, change nothing.
# ---------------------------------------------------------------------------

run_propose() {
    local root="$1"

    # The worksheet lives at <project-aid>/.temp/kb-migration-proposal.md
    # KB root is typically <project>/.aid/knowledge/
    # So .aid/ is one level up from KB root
    local project_aid worksheet_dir worksheet
    project_aid="$(dirname "$root")"
    worksheet_dir="${project_aid}/.temp"
    worksheet="${worksheet_dir}/kb-migration-proposal.md"

    log "PROPOSE: scanning KB at $root"
    log "Worksheet will be written to: $worksheet"

    # Gather in-scope docs
    local -a inscope=()
    while IFS= read -r f; do
        [[ -n "$f" ]] && inscope+=("$f")
    done < <(find_inscope_docs "$root")

    if [[ "${#inscope[@]}" -eq 0 ]]; then
        die "No in-scope docs found in '$root'." 2
    fi

    log "In-scope docs: ${#inscope[@]}"

    # Count how many still need migration
    local -a to_migrate=()
    local f
    for f in "${inscope[@]}"; do
        if is_migrated "$f"; then
            log "  SKIP (already migrated): $(basename "$f")"
        else
            to_migrate+=("$f")
        fi
    done

    if [[ "${#to_migrate[@]}" -eq 0 ]]; then
        log "All in-scope docs are already migrated. No-op."
        exit 0
    fi

    log "Docs to propose: ${#to_migrate[@]}"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "DRY-RUN: would write worksheet to $worksheet"
        for f in "${to_migrate[@]}"; do
            log "DRY-RUN: would propose migration for $(basename "$f")"
        done
        return 0
    fi

    # Write worksheet
    mkdir -p "$worksheet_dir"
    {
        printf '# KB Migration Proposal Worksheet\n'
        printf '#\n'
        printf '# Generated by migrate-kb-frontmatter.sh --propose\n'
        printf '# Generated at: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        printf '# KB root: %s\n' "$root"
        printf '#\n'
        printf '# INSTRUCTIONS:\n'
        printf '# 1. Review each doc section below.\n'
        printf '# 2. Refine the seeded objective: (tighten to a noun-phrase).\n'
        printf '# 3. Refine the seeded summary: (one clean sentence).\n'
        printf '# 4. Confirm/correct the sources: list (add missing, remove false positives).\n'
        printf '#    Use "sources: []" for a pure-synthesis doc (no external/file sources).\n'
        printf '# 5. Save this file, then run: migrate-kb-frontmatter.sh <kb-root> --apply\n'
        printf '#\n'
        printf '# FIELD SEPARATOR: each doc section begins with "## <docname>" and ends with "---"\n'
        printf '\n'
    } > "$worksheet"

    for f in "${to_migrate[@]}"; do
        local doc intent_raw collapsed objective_seed summary_seed candidates candidate_list line
        doc="$(basename "$f")"

        # Seed objective from collapsed intent
        intent_raw="$(fm_literal "$f" "intent")"
        if [[ -n "$intent_raw" ]]; then
            collapsed="$(printf '%s' "$intent_raw" | collapse_lines)"
            objective_seed="$collapsed"
            summary_seed="$(printf '%s' "$collapsed" | first_sentence)"
        else
            objective_seed="(no intent: field found -- fill in manually)"
            summary_seed="(no intent: field found -- fill in manually)"
        fi

        # Propose sources candidates
        candidates="$(propose_sources_candidates "$f" || true)"
        candidate_list=""
        if [[ -n "$candidates" ]]; then
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                if printf '%s' "$line" | grep -qE '^https?://'; then
                    candidate_list="${candidate_list}  - ${line}  # external URL"$'\n'
                else
                    candidate_list="${candidate_list}  - ${line}  # from intent/contracts path ref"$'\n'
                fi
            done <<< "$candidates"
        fi

        {
            printf '## %s\n' "$doc"
            printf '\n'
            printf 'objective: %s\n' "$objective_seed"
            printf '\n'
            printf 'summary: %s\n' "$summary_seed"
            printf '\n'
            printf 'sources:\n'
            printf '# Proposed candidates (confirm/correct before running --apply):\n'
            printf '# Annotation: "from intent/contracts path ref" | "external URL" | "pure-synthesis -> sources: []"\n'
            if [[ -n "$candidate_list" ]]; then
                printf '%s' "$candidate_list"
            else
                printf '  []  # pure-synthesis -> sources: []\n'
            fi
            printf '\n'
            printf '%s\n' '---'
            printf '\n'
        } >> "$worksheet"

        log "  Proposed: $doc"
    done

    log "Worksheet written: $worksheet"
    log ""
    log "NEXT STEPS:"
    log "  1. Review and edit $worksheet"
    log "  2. Tighten each 'objective:' to a noun-phrase"
    log "  3. Refine each 'summary:' to a clean one-sentence scope"
    log "  4. Confirm/correct each 'sources:' list"
    log "  5. Run: ${SCRIPT_NAME} $(printf '%q' "$root") --apply"
}

# ---------------------------------------------------------------------------
# Worksheet reader: parse the proposal worksheet into per-doc fields.
# Prints lines to stdout: DOC<TAB>FIELD<TAB>VALUE
# ---------------------------------------------------------------------------

parse_worksheet() {
    local ws="$1"
    # Output format (one line per record):
    #   <doc>\tobjective\t<value>
    #   <doc>\tsummary\t<value>
    #   <doc>\tsource_item\t<item>   (one line per source item; empty-list: <doc>\tsource_item\t[])
    awk '
        function flush_doc(   i) {
            if (curdoc == "" || obj == "") return
            print curdoc "\tobjective\t" obj
            print curdoc "\tsummary\t" summ
            if (src_count == 0) {
                print curdoc "\tsource_item\t[]"
            } else {
                for (i = 1; i <= src_count; i++) {
                    print curdoc "\tsource_item\t" src_items[i]
                }
            }
        }
        /^## [a-zA-Z0-9_./-]+\.md$/ {
            flush_doc()
            curdoc = substr($0, 4)
            obj = ""; summ = ""; in_sources = 0; src_count = 0
            delete src_items
            next
        }
        curdoc != "" && /^---$/ {
            flush_doc()
            curdoc = ""; obj = ""; summ = ""; in_sources = 0; src_count = 0
            delete src_items
            next
        }
        curdoc != "" && /^objective: / {
            obj = substr($0, 12)
            in_sources = 0
            next
        }
        curdoc != "" && /^summary: / {
            summ = substr($0, 10)
            in_sources = 0
            next
        }
        curdoc != "" && /^sources:/ {
            in_sources = 1
            # Check for inline []
            rest = $0
            sub(/^sources:[[:space:]]*/, "", rest)
            if (rest ~ /^\[\]/) {
                in_sources = 0
                src_count = 0
            }
            next
        }
        curdoc != "" && in_sources {
            if (/^#/) { next }
            if (/^$/ || (/^[a-zA-Z]/ && !/^[[:space:]]/ && !/^-/)) {
                in_sources = 0
                next
            }
            line = $0
            # Strip inline comment
            sub(/#.*$/, "", line)
            # Strip trailing whitespace
            sub(/[[:space:]]+$/, "", line)
            # Strip leading "  - " or "- "
            sub(/^[[:space:]]*-[[:space:]]/, "", line)
            # Strip leading/trailing whitespace
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            # Handle "[]" (empty list)
            if (line == "[]") {
                in_sources = 0
                next
            }
            if (line != "") {
                src_count++
                src_items[src_count] = line
            }
            next
        }
        END { flush_doc() }
    ' "$ws"
}

# ---------------------------------------------------------------------------
# Frontmatter rewriter: write the new fields into a doc.
# Uses a temp file + mv for atomicity.
# Inserts objective/summary/sources/approved_at_commit in f001 canonical order
# above contracts/changelog; retires intent: literal block.
# ---------------------------------------------------------------------------

rewrite_doc() {
    local f="$1" objective="$2" summary_val="$3" sources_items="$4" commit_hash="$5"
    local tmp src_tmp
    tmp="${f}.migrate-tmp"
    src_tmp="${f}.sources-tmp"

    # Build sources block file (avoids newline-in-awk-variable issues)
    if [[ -z "$sources_items" ]] || [[ "$sources_items" == "[]" ]]; then
        printf 'sources: []\n' > "$src_tmp"
    else
        printf 'sources:\n' > "$src_tmp"
        while IFS= read -r item; do
            item="$(printf '%s' "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            [[ -z "$item" ]] || [[ "$item" == "[]" ]] && continue
            printf '  - %s\n' "$item" >> "$src_tmp"
        done <<< "$sources_items"
        # If no items were written beyond the header, reset to empty list
        if [[ "$(wc -l < "$src_tmp")" -le 1 ]]; then
            printf 'sources: []\n' > "$src_tmp"
        fi
    fi

    awk -v objective="$objective" \
        -v summary_val="$summary_val" \
        -v src_file="$src_tmp" \
        -v commit_hash="$commit_hash" \
    '
    function emit_new_fields(   line) {
        print "objective: " objective
        print "summary: " summary_val
        while ((getline line < src_file) > 0) { print line }
        close(src_file)
        print "approved_at_commit: " commit_hash
    }
    BEGIN {
        in_fm = 0
        in_intent = 0
        new_fields_written = 0
        closed = 0
    }

    /^---$/ {
        if (!in_fm && NR == 1) {
            in_fm = 1
            print
            next
        }
        if (in_fm && !closed) {
            # Closing ---: write new fields before closing if not yet written
            if (!new_fields_written) {
                emit_new_fields()
                new_fields_written = 1
            }
            closed = 1
            in_fm = 0
            print
            next
        }
        print
        next
    }

    in_fm {
        # Detect intent: | (literal block start)
        if (/^intent:[[:space:]]*\|[[:space:]]*$/) {
            in_intent = 1
            next
        }
        # Consume intent literal block body lines
        if (in_intent) {
            if (/^[[:space:]]/) {
                next
            } else {
                in_intent = 0
                # Fall through to process this line
            }
        }
        # Before contracts: or changelog: write the new fields
        if (!new_fields_written && /^(contracts:|changelog:)/) {
            emit_new_fields()
            new_fields_written = 1
        }
        print
        next
    }

    { print }
    ' "$f" > "$tmp"

    rm -f "$src_tmp"
    mv "$tmp" "$f"
}

# ---------------------------------------------------------------------------
# Append changelog row to a doc's changelog: list.
# ---------------------------------------------------------------------------

append_changelog_row() {
    local f="$1" note="$2"
    local today
    today="$(date -u +%Y-%m-%d)"
    local tmp
    tmp="${f}.changelog-tmp"

    awk -v note="$note" -v today="$today" '
    BEGIN { in_fm=0; in_cl=0; done=0; indent=2 }
    /^---$/ {
        if (!in_fm && NR == 1) { in_fm=1; print; next }
        if (in_fm) { in_fm=0; in_cl=0; print; next }
        print; next
    }
    in_fm && !done && /^changelog:/ {
        print
        in_cl = 1
        next
    }
    in_fm && in_cl && !done {
        # First line of changelog block
        if (/^[[:space:]]+-/) {
            # Prepend new row as the most-recent entry
            print "  - " today ": " note
            print
            done = 1
        } else if (/^[[:space:]]*$/ || /^[a-zA-Z]/) {
            # Empty changelog or next field: insert before
            print "  - " today ": " note
            in_cl = 0
            done = 1
            print
        } else {
            print
        }
        next
    }
    { print }
    END {
        if (!done) {
            print "  - " today ": " note
        }
    }
    ' "$f" > "$tmp"

    mv "$tmp" "$f"
}

# ---------------------------------------------------------------------------
# APPLY pass: read confirmed worksheet, write docs.
# ---------------------------------------------------------------------------

run_apply() {
    local root="$1"

    # Locate worksheet
    local project_aid worksheet
    project_aid="$(dirname "$root")"
    worksheet="${project_aid}/.temp/kb-migration-proposal.md"

    if [[ ! -f "$worksheet" ]]; then
        die "--apply requires a confirmed worksheet at '$worksheet'. Run --propose first." 3
    fi

    log "APPLY: reading worksheet from $worksheet"

    # Create backup timestamp
    local ts backup_dir
    ts="$(date -u +%Y%m%dT%H%M%SZ)"
    backup_dir="${project_aid}/.temp/kb-migration-backup-${ts}"

    # Gather in-scope docs
    local -a inscope=()
    while IFS= read -r f; do
        [[ -n "$f" ]] && inscope+=("$f")
    done < <(find_inscope_docs "$root")

    if [[ "${#inscope[@]}" -eq 0 ]]; then
        die "No in-scope docs found in '$root'." 2
    fi

    # Parse worksheet into per-doc data
    local ws_data
    ws_data="$(parse_worksheet "$worksheet")"

    # Get git commit hash
    local commit_hash
    commit_hash="$(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
    log "Commit hash for approved_at_commit: $commit_hash"

    # Process each in-scope doc
    local -a migrated_docs=()
    local f doc objective summary_val sources_items sources_block_arg

    for f in "${inscope[@]}"; do
        doc="$(basename "$f")"

        # Idempotency: skip already-migrated docs
        if is_migrated "$f"; then
            log "  SKIP (already migrated): $doc"
            continue
        fi

        # Look up this doc in the parsed worksheet
        objective="$(printf '%s\n' "$ws_data" | awk -F'\t' -v d="$doc" '$1 == d && $2 == "objective" { print $3; exit }')"
        summary_val="$(printf '%s\n' "$ws_data" | awk -F'\t' -v d="$doc" '$1 == d && $2 == "summary" { print $3; exit }')"
        # Collect all source_item lines for this doc (one per line, already-stripped)
        sources_items="$(printf '%s\n' "$ws_data" | awk -F'\t' -v d="$doc" '$1 == d && $2 == "source_item" { print $3 }')"

        # Build sources block string for rewrite_doc:
        #   "[]"                       -> sources: []
        #   one-or-more path/URL lines -> sources:\n  - item1\n  - item2
        if [[ -z "$sources_items" ]] || [[ "$sources_items" == "[]" ]]; then
            sources_block_arg="[]"
        else
            sources_block_arg="$sources_items"
        fi

        # Validate: refuse to retire intent if objective or summary are empty (degrade-safe)
        if [[ -z "$objective" ]] || [[ -z "$summary_val" ]]; then
            warn "Doc '$doc': objective or summary is empty in worksheet -- skipping (degrade-safe). Fill in and re-run."
            continue
        fi

        if [[ "$DRY_RUN" -eq 1 ]]; then
            log "DRY-RUN: would backup $doc to $backup_dir/$doc"
            log "DRY-RUN: would write objective/summary/sources/approved_at_commit to $doc"
            log "DRY-RUN: would retire intent: from $doc"
            log "DRY-RUN: would append changelog row to $doc"
            migrated_docs+=("$doc")
            continue
        fi

        # Backup before modifying
        mkdir -p "$backup_dir"
        cp "$f" "${backup_dir}/${doc}"
        log "  Backed up: $doc -> $backup_dir/$doc"

        # Rewrite frontmatter
        rewrite_doc "$f" "$objective" "$summary_val" "$sources_block_arg" "$commit_hash"
        log "  Rewrote frontmatter: $doc"

        # Append changelog row
        append_changelog_row "$f" "Migrated by migrate-kb-frontmatter.sh: intent retired, objective/summary/sources added"
        log "  Appended changelog: $doc"

        migrated_docs+=("$doc")
    done

    if [[ "${#migrated_docs[@]}" -eq 0 ]]; then
        log "No docs required migration. No-op."
        return 0
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "DRY-RUN: would have migrated ${#migrated_docs[@]} doc(s): ${migrated_docs[*]}"
        return 0
    fi

    # Verification pass: lint the entire KB root via lint-frontmatter.sh
    log ""
    log "Verification pass: linting migrated docs..."

    # Locate lint-frontmatter.sh relative to this script
    local lint_script script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    lint_script="${script_dir}/../kb/lint-frontmatter.sh"

    local verify_failed=0
    if [[ -f "$lint_script" ]]; then
        local lint_out lint_exit
        lint_exit=0
        lint_out="$(bash "$lint_script" --root "$root" 2>&1)" || lint_exit=$?
        printf '%s\n' "$lint_out" >&2
        if [[ "$lint_exit" -ne 0 ]]; then
            verify_failed=1
        else
            log "Lint verification: PASS"
        fi
    else
        warn "lint-frontmatter.sh not found at '$lint_script' -- skipping lint verification."
    fi

    if [[ "$verify_failed" -eq 1 ]]; then
        log ""
        log "FAIL: Verification failed. Backup retained at: $backup_dir"
        log "      Fix the issues and re-run, or restore with: ${SCRIPT_NAME} $(printf '%q' "$root") --rollback"
        exit 4
    fi

    # Summary
    log ""
    log "APPLY complete: migrated ${#migrated_docs[@]} doc(s)"
    log "  Backup: $backup_dir"
    log "  Migrated: ${migrated_docs[*]}"

    if [[ "${#WARNINGS[@]}" -gt 0 ]]; then
        log "  Warnings (${#WARNINGS[@]}):"
        local w
        for w in "${WARNINGS[@]}"; do
            log "    [WARNING] ${w}"
        done
    fi
}

# ---------------------------------------------------------------------------
# ROLLBACK: restore from most recent backup tree.
# ---------------------------------------------------------------------------

run_rollback() {
    local root="$1"
    local project_aid
    project_aid="$(dirname "$root")"

    # Find most recent backup tree
    local backup_dir
    backup_dir="$(find "${project_aid}/.temp" -maxdepth 1 -type d -name 'kb-migration-backup-*' 2>/dev/null | sort | tail -1 || true)"

    if [[ -z "$backup_dir" ]]; then
        die "No backup tree found under '${project_aid}/.temp/'. Cannot rollback." 1
    fi

    log "ROLLBACK: restoring from $backup_dir"

    local -a restored=()
    local f doc dst

    while IFS= read -r f; do
        doc="$(basename "$f")"
        dst="${root}/${doc}"

        if [[ "$DRY_RUN" -eq 1 ]]; then
            log "DRY-RUN: would restore $dst from $f"
            restored+=("$doc")
            continue
        fi

        if [[ -f "$dst" ]]; then
            cp "$f" "$dst"
            log "  Restored: $doc"
            restored+=("$doc")
        else
            warn "Backup doc '$f' has no corresponding file at '$dst' -- skipping."
        fi
    done < <(find "$backup_dir" -maxdepth 1 -type f -name '*.md' | sort)

    if [[ "${#restored[@]}" -eq 0 ]]; then
        log "No docs restored (backup tree was empty or no matching files found)."
        return 0
    fi

    if [[ "$DRY_RUN" -eq 0 ]]; then
        # Remove backup tree after successful restore
        rm -rf "$backup_dir"
        log "Removed backup tree: $backup_dir"
    fi

    log "ROLLBACK complete: restored ${#restored[@]} doc(s): ${restored[*]}"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    parse_args "$@"

    # Scope discipline (SD-6): resolve KB root to absolute path.
    KB_ROOT="$(cd "$KB_ROOT" 2>/dev/null && pwd)" || die "'$KB_ROOT' is not a directory." 1
    [[ -d "$KB_ROOT" ]] || die "'$KB_ROOT' is not a directory." 1

    log "KB root: $KB_ROOT"
    log "Mode: $MODE"
    [[ "$DRY_RUN" -eq 1 ]] && log "(DRY-RUN: no files will be written)"

    case "$MODE" in
        propose)  run_propose  "$KB_ROOT" ;;
        apply)    run_apply    "$KB_ROOT" ;;
        rollback) run_rollback "$KB_ROOT" ;;
        *) die "Unknown mode: $MODE" 1 ;;
    esac
}

main "$@"
