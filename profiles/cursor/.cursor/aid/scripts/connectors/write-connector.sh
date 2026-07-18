#!/usr/bin/env bash
# write-connector.sh -- non-interactive writer for the `.aid/connectors/` registry; the
# dashboard-dispatchable counterpart to the `aid-set-connector` / `aid-unset-connector`
# skills, which the LLM-free dashboard server cannot invoke directly (`aid-set-connector`
# requires `AskUserQuestion`, SKILL.md line 12 -- SEC-4). Reproduces the skills'
# non-interactive EFFECT -- deterministic descriptor authoring + the same
# secret-purge/INDEX-rebuild plumbing -- with no LLM prose composition anywhere
# (feature-007-connectors-list, work-017 task-018).
#
# Bash-only -- a deliberate departure from the connectors-area Bash+PowerShell-twins
# convention (module-map.md, Script Modules by Area, connectors row): this writer is
# invoked ONLY by the LLM-free dashboard server via feature-001's child-process dispatch,
# never on the Windows-PowerShell CLI path the twins exist to serve (flagged as a KB
# follow-up, not a defect).
#
# Two subcommands:
#
#   set --root <dir> --name <N> --type <mcp|api|ssh|url|cli>
#       [--endpoint <E>] [--auth <none|token|pat|oauth|ssh-key>] [--secret-ref <R>]
#     Derives <stem> from --name via the skills' EXACT slug rule (SKILL.md Step 1:
#     `tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'`), so
#     dashboard- and skill-authored stems are byte-identical. Atomically (temp-file + mv)
#     authors/overwrites exactly ONE `<root>/<stem>.md` -- upsert semantics, matching the
#     skill's single-stem UPDATE. NEVER a wholesale registry rewrite (Q7/KI-005 ownership
#     model: the dashboard is a subordinate atomic single-entry maintainer; discovery/Scout
#     stays authoritative).
#
#     Per-type normalize + fail-closed enforcement (question-sets.md
#     Sec-mcp / Sec-api-url / Sec-ssh / Sec-cli):
#       mcp          -> auth_method forced 'none'; secret_reference dropped; endpoint
#                       is informational (optional)
#       ssh          -> auth_method forced 'ssh-key'; --endpoint REQUIRED
#       api|url|cli  -> --endpoint AND --auth both REQUIRED
#     A missing required field for the resolved type fail-closes (exit 5) rather than
#     persisting a descriptor the skill would never author.
#
#     secret_reference: a credentialed connector (ssh always -- auth_method is forced
#     ssh-key; api|url|cli when auth != none) MUST carry one
#     (artifact-schemas.md "yes iff aid-managed AND auth_method != none"). When
#     --secret-ref is omitted, the default is the skill's own
#     `file:.aid/connectors/.secrets/<stem>` form (never a fabricated VALUE). `mcp` / any
#     `auth_method: none` result carries none (dropped even when --secret-ref was given).
#     Reference FORM only -- this script never accepts, echoes, prompts for, or stores a
#     secret VALUE.
#
#     Ensures the `.secrets/` gitignore precondition (mirrors `aid-set-connector` Step 4)
#     BEFORE the descriptor write, so a later out-of-band `connector-secret.sh write`
#     never fail-closes. When the result is `mcp` / `auth_method: none`, purges any
#     orphaned secret via `connector-secret.sh purge <stem>` (mirrors Step 5b's purge
#     branch). Ends by rebuilding `INDEX.md`.
#
#   remove --root <dir> --stem <STEM>
#     A 1:1 non-interactive port of `aid-unset-connector` Steps 2-3: purge the secret,
#     `rm -f` the descriptor, rebuild `INDEX.md`. Idempotent -- an already-absent stem is
#     a clean no-op (exit 0).
#
# Both subcommands finish by invoking the deterministic `build-connectors-index.sh`
# builder (no run timestamp / dated field -- see that script's own header), so two runs
# over an identical descriptor set produce a byte-identical `INDEX.md` (AC2 idempotence).
# This script self-locates its two siblings (`connector-secret.sh`,
# `build-connectors-index.sh`) from its OWN directory; it never invokes the read-only
# `connector-registry.sh`.
#
# Usage:
#   write-connector.sh set    --root <dir> --name <N> --type <T> [--endpoint <E>] [--auth <A>] [--secret-ref <R>]
#   write-connector.sh remove --root <dir> --stem <STEM>
#
# Exit codes -- feature-001's shared alphabet VERBATIM (so the dashboard's generic
# OP_TABLE dispatcher maps exit -> HTTP with no per-op remapping). NEVER 1 (not-found) or
# 2 (busy / lock-contention) -- both feature-001-reserved. Helper native codes
# (connector-secret.sh's 2/usage and 3/path-confinement; any build-connectors-index.sh
# failure) are normalized into this alphabet, never propagated raw:
#   0 -- success
#   4 -- invalid value (bad enum / bad value / path-confinement bad stem)
#   5 -- missing required argument
#   3 -- runtime / I-O failure / unverifiable write / INDEX rebuild failed
#
# Output:
#   stdout: one `OK: ...` trace line on success (plus build-connectors-index.sh's own
#           trace line). Never a secret value.
#   stderr: diagnostics only.

set -euo pipefail

SCRIPT_NAME="write-connector.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
CONNECTOR_SECRET_SH="${SCRIPT_DIR}/connector-secret.sh"
BUILD_INDEX_SH="${SCRIPT_DIR}/build-connectors-index.sh"

die() {
    echo "${SCRIPT_NAME}: $1" >&2
    exit "$2"
}

usage() {
    cat <<'HELP'
write-connector.sh -- non-interactive writer for the .aid/connectors/ registry (the
aid-set-connector / aid-unset-connector skill counterpart the LLM-free dashboard server
can dispatch; SEC-4).

Usage:
  write-connector.sh set    --root <dir> --name <N> --type <mcp|api|ssh|url|cli>
                             [--endpoint <E>] [--auth <none|token|pat|oauth|ssh-key>]
                             [--secret-ref <env:VAR|file:PATH|keychain:KEY>]
  write-connector.sh remove --root <dir> --stem <STEM>

Per-type normalize (fail-closed -- a missing required field for the resolved type
exits 5):
  mcp          -> auth_method forced 'none'; no secret_reference; endpoint informational
  ssh          -> auth_method forced 'ssh-key'; --endpoint REQUIRED
  api|url|cli  -> --endpoint and --auth both REQUIRED

A credentialed result (ssh always; api|url|cli when auth != none) with --secret-ref
omitted defaults to file:.aid/connectors/.secrets/<stem>. Never accepts, echoes, or
stores a secret VALUE.

Exit codes (feature-001's shared alphabet -- never 1 or 2):
  0  success
  4  invalid value (bad enum / bad value / path-confinement bad stem)
  5  missing required argument
  3  runtime / I-O failure / unverifiable write / INDEX rebuild failed
HELP
}

# ---------------------------------------------------------------------------
# reject_unsafe FLAG VALUE -- charset guard for free-text fields that end up inside a
# double-quoted YAML scalar in the descriptor (mirrors write-setting.sh's KI-001 guard):
# a newline or an embedded double-quote is rejected outright.
# ---------------------------------------------------------------------------
reject_unsafe() {
    local flag="$1" value="$2"
    if [[ "$value" == *$'\n'* ]]; then
        die "--${flag} must not contain a newline" 4
    fi
    if [[ "$value" == *'"'* ]]; then
        die "--${flag} must not contain a double-quote (\")" 4
    fi
}

# ---------------------------------------------------------------------------
# validate_secret_ref REF -- structural check for the three reference forms
# (artifact-schemas.md "secret_reference value format"). Never validates or touches a
# secret VALUE -- reference form only.
# ---------------------------------------------------------------------------
validate_secret_ref() {
    local ref="$1" var rest
    case "$ref" in
        env:*)
            var="${ref#env:}"
            [[ "$var" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] \
                || die "invalid --secret-ref '$ref': 'env:' form requires a valid environment-variable name" 4
            ;;
        file:*|keychain:*)
            rest="${ref#*:}"
            [[ -n "$rest" ]] || die "invalid --secret-ref '$ref': missing value after prefix" 4
            if [[ "$rest" == *$'\n'* || "$rest" == *'|'* || "$rest" == *'"'* ]]; then
                die "invalid --secret-ref '$ref': must not contain a newline, '|', or '\"'" 4
            fi
            ;;
        *)
            die "invalid --secret-ref '$ref' (expected env:<VAR> | file:<path> | keychain:<key>)" 4
            ;;
    esac
}

# ---------------------------------------------------------------------------
# purge_secret STEM ROOT -- normalize connector-secret.sh's native exit codes into this
# script's alphabet (never propagate 1/2/3 raw): usage (2) / path-confinement (3) ->
# invalid value (4); anything else non-zero -> runtime failure (3).
# ---------------------------------------------------------------------------
purge_secret() {
    local stem="$1" root="$2" rc=0
    bash "$CONNECTOR_SECRET_SH" purge "$stem" --root "$root" && rc=0 || rc=$?
    case "$rc" in
        0) return 0 ;;
        2|3) die "connector-secret.sh purge rejected stem '$stem' (exit $rc)" 4 ;;
        *) die "connector-secret.sh purge failed for stem '$stem' (exit $rc)" 3 ;;
    esac
}

# ---------------------------------------------------------------------------
# rebuild_index ROOT -- regenerate INDEX.md; any non-zero exit normalizes to 3.
# ---------------------------------------------------------------------------
rebuild_index() {
    local root="$1" rc=0
    bash "$BUILD_INDEX_SH" --root "$root" --output "${root%/}/INDEX.md" && rc=0 || rc=$?
    [[ "$rc" -eq 0 ]] || die "build-connectors-index.sh failed (exit $rc)" 3
}

# ---------------------------------------------------------------------------
# Top-level dispatch
# ---------------------------------------------------------------------------
if [[ $# -eq 0 ]]; then
    echo "${SCRIPT_NAME}: missing operation (set|remove)" >&2
    exit 5
fi

case "$1" in
    -h|--help)
        usage
        exit 0
        ;;
    set)
        OP="set"; shift
        ;;
    remove)
        OP="remove"; shift
        ;;
    *)
        echo "${SCRIPT_NAME}: unknown operation: $1 (expected set|remove)" >&2
        exit 5
        ;;
esac

if [[ "$OP" == "set" ]]; then
    ROOT=""; HAS_ROOT=0
    NAME=""; HAS_NAME=0
    TYPE=""; HAS_TYPE=0
    ENDPOINT=""
    AUTH=""
    SECRET_REF=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --root)       [[ $# -ge 2 ]] || die "--root requires a value" 5; ROOT="$2"; HAS_ROOT=1; shift 2 ;;
            --name)       [[ $# -ge 2 ]] || die "--name requires a value" 5; NAME="$2"; HAS_NAME=1; shift 2 ;;
            --type)       [[ $# -ge 2 ]] || die "--type requires a value" 5; TYPE="$2"; HAS_TYPE=1; shift 2 ;;
            --endpoint)   [[ $# -ge 2 ]] || die "--endpoint requires a value" 5; ENDPOINT="$2"; shift 2 ;;
            --auth)       [[ $# -ge 2 ]] || die "--auth requires a value" 5; AUTH="$2"; shift 2 ;;
            --secret-ref) [[ $# -ge 2 ]] || die "--secret-ref requires a value" 5; SECRET_REF="$2"; shift 2 ;;
            -h|--help)    usage; exit 0 ;;
            *) die "unknown flag: $1" 5 ;;
        esac
    done

    [[ "$HAS_ROOT" -eq 1 ]] || die "--root is required" 5
    [[ "$HAS_NAME" -eq 1 ]] || die "--name is required" 5
    [[ "$HAS_TYPE" -eq 1 ]] || die "--type is required" 5

    reject_unsafe name "$NAME"
    reject_unsafe endpoint "$ENDPOINT"

    case "$TYPE" in
        mcp|api|ssh|url|cli) ;;
        *) die "invalid --type '$TYPE' (expected one of: mcp, api, ssh, url, cli)" 4 ;;
    esac

    if [[ -n "$AUTH" ]]; then
        case "$AUTH" in
            none|token|pat|oauth|ssh-key) ;;
            *) die "invalid --auth '$AUTH' (expected one of: none, token, pat, oauth, ssh-key)" 4 ;;
        esac
    fi

    # --- derive stem (skills' EXACT slug rule, verbatim -- SKILL.md Step 1) ---
    STEM="$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
    [[ -n "$STEM" ]] || die "computed an empty stem from --name '$NAME'" 4
    [[ "$STEM" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "computed stem '$STEM' is not a valid bare slug" 4

    # --- per-type normalize + fail-closed enforcement ---
    case "$TYPE" in
        mcp)
            FINAL_AUTH="none"
            ;;
        ssh)
            [[ -n "$ENDPOINT" ]] || die "--endpoint is required for type 'ssh'" 5
            FINAL_AUTH="ssh-key"
            ;;
        api|url|cli)
            [[ -n "$ENDPOINT" ]] || die "--endpoint is required for type '$TYPE'" 5
            [[ -n "$AUTH" ]] || die "--auth is required for type '$TYPE'" 5
            FINAL_AUTH="$AUTH"
            ;;
    esac

    # --- secret_reference resolution (credentialed connectors only) ---
    FINAL_SECRET=""
    if [[ "$FINAL_AUTH" != "none" ]]; then
        if [[ -n "$SECRET_REF" ]]; then
            validate_secret_ref "$SECRET_REF"
            FINAL_SECRET="$SECRET_REF"
        else
            FINAL_SECRET="file:.aid/connectors/.secrets/${STEM}"
        fi
    fi

    # --- .secrets/ gitignore precondition -- BEFORE any descriptor write ---
    mkdir -p -- "$ROOT" 2>/dev/null || die "cannot create root directory: $ROOT" 3
    if [[ ! -f "${ROOT%/}/.gitignore" ]]; then
        printf '%s\n' '.secrets/' > "${ROOT%/}/.gitignore" 2>/dev/null \
            || die "cannot write ${ROOT%/}/.gitignore" 3
    fi

    if [[ -f "${ROOT%/}/${STEM}.md" ]]; then CLASS="UPDATE"; else CLASS="ADD"; fi

    # --- deterministic body composition (no LLM prose) ---
    if [[ "$TYPE" == "mcp" ]]; then
        MODE_LABEL="tool-managed"
        AUTH_LINE="handled by the host tool (no AID credential)"
        OBJECTIVE="Connect to ${NAME} via its host tool's own MCP/plugin; AID stores no credential."
        SUMMARY="${NAME} (mcp) -- request via the host tool's MCP/plugin."
        BODY_GUIDANCE="Request this connection from the host tool's own MCP/plugin at use-time; AID stores no credential for it."
    else
        MODE_LABEL="aid-managed"
        if [[ "$FINAL_AUTH" == "none" ]]; then
            AUTH_LINE="none"
            BODY_GUIDANCE="Connects directly with no stored credential."
        else
            AUTH_LINE="${FINAL_AUTH} (reference: ${FINAL_SECRET})"
            BODY_GUIDANCE="Resolve the credential via \`${FINAL_SECRET}\` at use-time; AID never stores the secret value in this descriptor."
        fi
        OBJECTIVE="Connect to ${NAME} via ${TYPE} at ${ENDPOINT}."
        SUMMARY="${NAME} (${TYPE}) -- auth: ${FINAL_AUTH}."
    fi

    # --- atomic single-entry write (temp-file + mv) ---
    TMP_DESC="$(mktemp "${ROOT%/}/.write-connector.XXXXXX" 2>/dev/null)" \
        || die "cannot create a temp file under $ROOT" 3
    trap 'rm -f -- "$TMP_DESC"' EXIT

    {
        echo '---'
        printf 'name: "%s"\n' "$NAME"
        printf 'connection_type: %s\n' "$TYPE"
        printf 'endpoint: "%s"\n' "$ENDPOINT"
        printf 'auth_method: %s\n' "$FINAL_AUTH"
        if [[ -n "$FINAL_SECRET" ]]; then
            printf 'secret_reference: "%s"\n' "$FINAL_SECRET"
        fi
        printf 'preset: custom\n'
        printf 'objective: "%s"\n' "$OBJECTIVE"
        printf 'summary: "%s"\n' "$SUMMARY"
        printf 'tags: [connector, %s]\n' "$TYPE"
        printf 'audience: [developer, architect]\n'
        echo '---'
        echo ''
        printf '# %s\n' "$NAME"
        echo ''
        printf '> Connection: %s · Mode: %s · Auth: %s\n' "$TYPE" "$MODE_LABEL" "$AUTH_LINE"
        echo ''
        printf '%s\n' "$BODY_GUIDANCE"
    } > "$TMP_DESC"

    mv -- "$TMP_DESC" "${ROOT%/}/${STEM}.md" \
        || die "failed to move descriptor into place: ${ROOT%/}/${STEM}.md" 3

    SECRET_ACTION="unchanged"
    if [[ "$FINAL_AUTH" == "none" ]]; then
        purge_secret "$STEM" "$ROOT"
        SECRET_ACTION="purged"
    fi

    rebuild_index "$ROOT"

    echo "OK: ${ROOT%/}/${STEM}.md ${CLASS} (${TYPE}); secret ${SECRET_ACTION}; INDEX regenerated."
    exit 0
fi

# ---------------------------------------------------------------------------
# remove
# ---------------------------------------------------------------------------
ROOT=""; HAS_ROOT=0
STEM=""; HAS_STEM=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --root) [[ $# -ge 2 ]] || die "--root requires a value" 5; ROOT="$2"; HAS_ROOT=1; shift 2 ;;
        --stem) [[ $# -ge 2 ]] || die "--stem requires a value" 5; STEM="$2"; HAS_STEM=1; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown flag: $1" 5 ;;
    esac
done

[[ "$HAS_ROOT" -eq 1 ]] || die "--root is required" 5
[[ "$HAS_STEM" -eq 1 ]] || die "--stem is required" 5

[[ "$STEM" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "invalid --stem '$STEM' (expected ^[a-z0-9][a-z0-9-]*\$)" 4

purge_secret "$STEM" "$ROOT"
rm -f -- "${ROOT%/}/${STEM}.md" || die "failed to remove descriptor: ${ROOT%/}/${STEM}.md" 3
rebuild_index "$ROOT"

echo "OK: ${STEM} removed from ${ROOT} (secret purged if present); INDEX regenerated."
exit 0
