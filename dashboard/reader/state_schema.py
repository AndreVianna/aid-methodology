# dashboard/reader/state_schema.py
# STATE YAML-frontmatter dual-format read (work-003-state-schema task-002).
#
# Responsibility:
#   - parse_frontmatter_scalars(text) -- generic flat + one-level-nested scalar
#     frontmatter scanner shared by every STATE.md parser in this package
#     (work / delivery / task / discovery). Frontmatter-first, legacy-prose
#     fallback is implemented by the CALLERS (parsers.py); this module only
#     supplies the parse primitive + two small semantic helpers below.
#   - parse_bool_yesno(raw) -- normalizes yes/no/true/false (case-insensitive)
#     to a Python bool, closing the twin-parity landmine flagged in the
#     task-001 review (see docstring below).
#   - parse_header_bold_field(text, label) -- legacy-prose fallback scan of
#     the pre-first-"##" header-blockquote zone for a '**{label}:** value'
#     line (mirrors derivation.py's _parse_minimum_grade scan bound).
#   - resolve_kind(initiator) -- maps a pipeline.initiator skill name to a
#     human display verb via a static mirror of shortcut-catalog.yml.
#
# No write / no I/O side-effects (pure text -> value). Python 3.11+ stdlib
# only. Zero third-party deps -- no YAML library is introduced; every STATE.md
# frontmatter block encountered by this reader is a deliberately restricted
# subset (flat scalars + one level of nesting, no lists, no multi-line block
# scalars), so a small hand-rolled scanner stands in for a real YAML parser
# (same posture as parsers.py's own parse_doc_frontmatter -- the per-KB-doc
# sources:/approved_at_commit: scanner -- and as
# .claude/skills/generate-profile/scripts/build-shortcut-skills.py's own
# hand-rolled shortcut-catalog.yml reader).
#
# Node twin: dashboard/server/reader.mjs defines the SAME functions inline
# (parseFrontmatterScalars / parseBoolYesno / parseHeaderBoldField /
# resolveKind / SHORTCUT_KIND_MAP) since the Node reader is a single file,
# not a package. Keep both in lockstep.

from __future__ import annotations

import re
from typing import Optional

# ---------------------------------------------------------------------------
# Generic frontmatter scalar scanner
# ---------------------------------------------------------------------------

_RE_FM_FENCE = re.compile(r"^---\s*$")
_RE_TOPLEVEL_KV = re.compile(r"^([A-Za-z0-9_\-]+):\s*(.*)$")
_RE_NESTED_KV = re.compile(r"^[ \t]+([A-Za-z0-9_\-]+):\s*(.*)$")
_RE_SECTION_HEADER = re.compile(r"^##\s+")

# A '{...}' template token anywhere in the value (matching braces, no nested
# '}'). Every un-instantiated placeholder in the 4 STATE templates carries one
# (e.g. "{YYYY-MM-DD}", "{grade or Pending}", "aid-{skill} | none").
_RE_PLACEHOLDER_TOKEN = re.compile(r"\{[^}]*\}")

# Frontmatter keys whose value is human/skill free-text, NOT a closed enum.
# Their template placeholders always carry a '{...}' token, so the token rule
# still skips un-filled scaffold text -- but a REAL free-text value that merely
# contains ' | ' (e.g. a pause reason "waiting on A | else B") must NOT be
# mistaken for an enum-alternatives placeholder and discarded. Closed-enum
# fields (lifecycle/phase/path/delivery_state/...) never legitimately contain
# ' | ', so the ' | '-list rule below stays active for them.
_FREETEXT_FM_KEYS = frozenset({"pause_reason", "block_reason", "block_artifact", "notes"})


def _strip_scalar_quotes(raw: str) -> str:
    """Strip one layer of matching surrounding quotes from a YAML scalar.

    For a SINGLE-quoted scalar, also collapse YAML's ''-escaping (`''` -> `'`) --
    the exact inverse of the frontmatter writer (task-004 emits a single-quoted
    scalar for any free-text value that needs quoting, doubling an embedded `'`).
    Without this, `notes: 'user''s reason'` would read back as `user''s reason`.
    Double-quoted scalars are stripped as-is (the writer never emits a
    backslash-escaped double-quoted scalar -- single-quote style is used instead).
    """
    val = raw.strip()
    if len(val) >= 2 and val[0] == val[-1] and val[0] in ("'", '"'):
        inner = val[1:-1]
        if val[0] == "'":
            inner = inner.replace("''", "'")
        return inner
    return val


def _looks_like_unfilled_placeholder(val: str, *, is_freetext: bool = False) -> bool:
    """True if val is un-instantiated TEMPLATE placeholder text, not real data.

    Rollout safety (BLUEPRINT gate criteria #6, "no status regression during
    rollout"): a STATE.md freshly scaffolded from work-state-template.md (or
    any of the other 3 templates) BEFORE the writers are migrated (task-004)
    carries the frontmatter block VERBATIM from the template -- e.g.
    `phase: Interview | Specify | Plan | Detail | Execute | Deploy | Monitor`
    or `started: "{YYYY-MM-DD}"` -- while the REAL value lives in the legacy
    prose bullets the not-yet-migrated writer DOES update. Treating that
    verbatim placeholder text as authored data would silently clobber the
    correct prose-derived value (this exact regression was caught by
    test_integration.py's producer<->consumer round-trip, which seeds a
    scratch repo from the real templates).

    Two markers, matching how the 4 templates document placeholders:
      - a '{...}' token anywhere -- every free-text and scalar placeholder
        carries one ('{YYYY-MM-DD}', '{grade or Pending}', 'aid-{skill} | none',
        '{short text} | --'); always a placeholder.
      - a ' | ' enum-alternatives list -- but ONLY for closed-enum fields. A
        closed-enum field's real value is a single member ('Execute'), never a
        ' | '-list, so ' | ' reliably marks the unfilled template line. A
        FREE-TEXT field (`is_freetext`), however, can legitimately contain
        ' | ' in a real value, so the ' | ' rule is suppressed for it; its own
        template placeholder is still caught by the '{...}' token rule above.
        (`is_freetext` keys: see _FREETEXT_FM_KEYS.)
    """
    if _RE_PLACEHOLDER_TOKEN.search(val):
        return True
    if not is_freetext and " | " in val:
        return True
    return False


def parse_frontmatter_scalars(text: str) -> dict[str, str]:
    """Tolerant flat + one-level-nested frontmatter scalar scan.

    Reads only the YAML frontmatter block (between the first pair of '---'
    lines). Returns a flat dict:
      - top-level scalar keys map directly:      'started: 2026-07-10'
                                                  -> {'started': '2026-07-10'}
      - one level of nested mapping is dot-joined:
          'pipeline:\n  path: lite\n  initiator: aid-refactor\n'
          -> {'pipeline.path': 'lite', 'pipeline.initiator': 'aid-refactor'}

    Block/inline LIST values are not needed by any STATE.md scalar field and
    are intentionally NOT captured here (parsers.py's parse_doc_frontmatter
    already covers the KB-doc 'sources:' list case for the per-doc freshness
    scan).

    Rollout safety: a value that _looks_like_unfilled_placeholder() (still
    carries the template's own '{...}' or ' | '-alternatives documentation
    text, e.g. a STATE.md scaffolded from work-state-template.md before the
    writers are migrated) is SKIPPED entirely -- the key is treated as absent,
    so callers fall through to their legacy-prose fallback instead of
    clobbering a real prose-derived value with un-instantiated template text.
    The ' | ' marker is applied per-key: it is suppressed for the free-text
    keys in _FREETEXT_FM_KEYS (whose real values may legitimately contain
    ' | '); those keys' own placeholders still carry a '{...}' token.

    Never raises (NFR7). No file I/O -- pure text -> dict. Returns {} when no
    opening '---' fence is present (legacy-prose-only file).
    """
    result: dict[str, str] = {}
    in_fm = False
    fm_entered = False
    current_prefix: Optional[str] = None

    for line in text.splitlines():
        if _RE_FM_FENCE.match(line):
            if not fm_entered:
                # Opening fence
                in_fm = True
                fm_entered = True
                continue
            else:
                # Closing fence
                break

        if not in_fm:
            # No opening fence yet -- not in frontmatter (or no frontmatter at all)
            break

        if not line.strip():
            continue

        # Nested continuation line (indented under a bare 'key:' mapping opener)
        if line[:1] in (" ", "\t"):
            if current_prefix is None:
                continue  # orphan indented line under no active mapping; ignore
            m = _RE_NESTED_KV.match(line)
            if m:
                key, val = m.group(1), _strip_scalar_quotes(m.group(2))
                if val != "" and not _looks_like_unfilled_placeholder(
                    val, is_freetext=key in _FREETEXT_FM_KEYS
                ):
                    result[f"{current_prefix}.{key}"] = val
            continue

        # Top-level line
        m = _RE_TOPLEVEL_KV.match(line)
        if not m:
            current_prefix = None
            continue

        key, rest = m.group(1), m.group(2).strip()
        if rest == "":
            # Bare 'key:' with nothing after -- a nested mapping follows
            current_prefix = key
            continue

        current_prefix = None
        val = _strip_scalar_quotes(rest)
        if not _looks_like_unfilled_placeholder(val, is_freetext=key in _FREETEXT_FM_KEYS):
            result[key] = val

    return result


def parse_header_bold_field(text: str, label: str) -> Optional[str]:
    """Legacy-prose fallback: scan the pre-first-"##" header-blockquote zone
    for a '**{label}:** value' line (optionally '>'-prefixed blockquote),
    case-insensitive search (not anchored -- matches with or without a
    leading '>' blockquote marker). Mirrors derivation.py's
    _parse_minimum_grade scan bound (stop at the first '##' section header)
    so every header-blockquote field shares one convention.

    Returns the trimmed raw value, or None if absent. Never raises. Callers
    apply their own null-sentinel ("-"/"--"/em-dash) and enum/bool parsing.
    """
    pattern = re.compile(r"\*\*" + re.escape(label) + r":\*\*\s*(.+)", re.IGNORECASE)
    for line in text.splitlines():
        if _RE_SECTION_HEADER.match(line):
            break
        m = pattern.search(line)
        if m:
            return m.group(1).strip()
    return None


# ---------------------------------------------------------------------------
# yes/no/true/false -> bool normalization (twin-parity landmine fix)
# ---------------------------------------------------------------------------

def parse_bool_yesno(raw: Optional[str]) -> Optional[bool]:
    """Normalize a yes/no/true/false (case-insensitive) scalar to bool.

    Twin-parity landmine (flagged in the task-001 review): PyYAML's default
    (1.1) resolver coerces bare yes/no/on/off to Python bool at LOAD time;
    js-yaml's default (1.2 core schema) does NOT -- it keeps 'yes'/'no' as
    literal strings, only 'true'/'false' resolve to boolean. Neither reader
    twin here uses a real YAML library for STATE.md (both hand-parse via
    parse_frontmatter_scalars, which always returns the raw string
    regardless of literal form) -- but a THIRD-PARTY tool that loads+re-dumps
    the frontmatter with PyYAML could rewrite 'yes'/'no' to 'true'/'false' on
    disk. This helper accepts all four literals (case-insensitive) so both
    twins agree on the SAME logical boolean no matter which literal form ends
    up on disk.

    Returns None when raw is None or an unrecognized token (never raises;
    None is the "absent/unparseable" sentinel, distinct from False).
    """
    if raw is None:
        return None
    v = raw.strip().lower()
    if v in ("yes", "true"):
        return True
    if v in ("no", "false"):
        return False
    return None


# ---------------------------------------------------------------------------
# pipeline.initiator -> display kind (shortcut-catalog.yml mapping)
#
# Static mirror of canonical/aid/templates/shortcut-catalog.yml's
# {name: (verb, artifact)} rows -- NOT read from disk at runtime. The reader
# operates against an arbitrary DOWNSTREAM repo (installed via pip/npm/
# curl|bash across 5 possible tool profiles: .claude/, .codex/, .cursor/,
# .github/, .agent/), so there is no single well-known relative path to the
# rendered shortcut-catalog.yml the way there is for .aid/settings.yml or
# .aid/knowledge/ -- and vendoring a copy of the catalog into dashboard/ is
# out of this task's scope (task-002 edits dashboard/ only; task-003 is the
# vendoring/ship task). A static table mirrors the existing SD2_RANK
# precedent in reader.py: an authoritative ordering "encoded once here" with
# an explicit comment that the true source of truth is a canonical/ file the
# maintainer keeps in lockstep by hand.
#
# Any change to shortcut-catalog.yml MUST be mirrored here AND in the Node
# twin (reader.mjs SHORTCUT_KIND_MAP). Includes every row (canonical + alias
# + repurpose) since pipeline.initiator may name any of them.
# ---------------------------------------------------------------------------

SHORTCUT_KIND_MAP: dict[str, tuple[str, str]] = {
    "aid-fix": ("fix", ""),
    "aid-create": ("create", ""),
    "aid-create-api": ("create", "api"),
    "aid-create-ui": ("create", "ui"),
    "aid-create-theme": ("create", "theme"),
    "aid-create-cli": ("create", "cli"),
    "aid-create-data-model": ("create", "data-model"),
    "aid-create-data-pipeline": ("create", "data-pipeline"),
    "aid-create-messaging": ("create", "messaging"),
    "aid-create-integration": ("create", "integration"),
    "aid-create-job": ("create", "job"),
    "aid-create-config": ("create", "config"),
    "aid-create-infra": ("create", "infra"),
    "aid-add": ("create", ""),
    "aid-add-api": ("create", "api"),
    "aid-add-ui": ("create", "ui"),
    "aid-add-theme": ("create", "theme"),
    "aid-add-cli": ("create", "cli"),
    "aid-add-data-model": ("create", "data-model"),
    "aid-add-data-pipeline": ("create", "data-pipeline"),
    "aid-add-messaging": ("create", "messaging"),
    "aid-add-integration": ("create", "integration"),
    "aid-add-job": ("create", "job"),
    "aid-add-config": ("create", "config"),
    "aid-add-infra": ("create", "infra"),
    "aid-change": ("change", ""),
    "aid-change-api": ("change", "api"),
    "aid-change-ui": ("change", "ui"),
    "aid-change-theme": ("change", "theme"),
    "aid-change-cli": ("change", "cli"),
    "aid-change-data-model": ("change", "data-model"),
    "aid-change-data-pipeline": ("change", "data-pipeline"),
    "aid-change-messaging": ("change", "messaging"),
    "aid-change-integration": ("change", "integration"),
    "aid-change-job": ("change", "job"),
    "aid-change-config": ("change", "config"),
    "aid-change-infra": ("change", "infra"),
    "aid-refactor": ("refactor", ""),
    "aid-update": ("change", ""),
    "aid-update-api": ("change", "api"),
    "aid-update-ui": ("change", "ui"),
    "aid-update-theme": ("change", "theme"),
    "aid-update-cli": ("change", "cli"),
    "aid-update-data-model": ("change", "data-model"),
    "aid-update-data-pipeline": ("change", "data-pipeline"),
    "aid-update-messaging": ("change", "messaging"),
    "aid-update-integration": ("change", "integration"),
    "aid-update-job": ("change", "job"),
    "aid-update-config": ("change", "config"),
    "aid-update-infra": ("change", "infra"),
    "aid-remove": ("remove", ""),
    "aid-delete": ("remove", ""),
    "aid-deprecate": ("deprecate", ""),
    "aid-migrate": ("migrate", ""),
    "aid-test": ("test", ""),
    "aid-test-security": ("test", "security"),
    "aid-test-performance": ("test", "performance"),
    "aid-test-data-quality": ("test", "data-quality"),
    "aid-experiment": ("experiment", ""),
    "aid-prototype": ("prototype", ""),
    "aid-prototype-ui": ("prototype", "ui"),
    "aid-document": ("document", ""),
    "aid-document-decision": ("document", "decision"),
    "aid-document-architecture": ("document", "architecture"),
    "aid-document-guideline": ("document", "guideline"),
    "aid-document-standard": ("document", "standard"),
    "aid-document-runbook": ("document", "runbook"),
    "aid-document-tutorial": ("document", "tutorial"),
    "aid-document-changelog": ("document", "changelog"),
    "aid-report": ("report", ""),
    "aid-show-dashboard": ("show-dashboard", ""),
    "aid-review": ("review", ""),
    "aid-audit": ("review", ""),
    "aid-research": ("research", ""),
    "aid-investigate": ("research", ""),
    "aid-spike": ("research", ""),
    "aid-deploy": ("deploy", ""),
    "aid-monitor": ("monitor", ""),
    "aid-query-kb": ("query", ""),
    "aid-ask": ("query", ""),
}

# The FULL-pipeline starting skill -- never a shortcut-catalog.yml row (it
# starts Interview -> Specify -> Plan -> Detail -> Execute, not a Lite
# shortcut). Resolved to a distinct literal so callers/tests can special-case
# it explicitly rather than silently falling through to "unknown".
_FULL_PATH_INITIATOR = "aid-describe"
_FULL_PATH_KIND = "full path"


def resolve_kind(initiator: Optional[str]) -> Optional[str]:
    """Resolve a pipeline.initiator skill name to a human display verb.

    Examples: 'aid-refactor' -> 'Refactor'; 'aid-create-api' -> 'Create api';
    'aid-create-data-model' -> 'Create data model'; 'aid-describe' ->
    'full path' (the FULL-pipeline starting skill).

    Unknown/absent initiator -> None (caller drops the redundant word instead
    of rendering a literal "Unknown"/"Lite"). Never raises.
    """
    if not initiator:
        return None
    initiator = initiator.strip()
    if not initiator:
        return None
    if initiator == _FULL_PATH_INITIATOR:
        return _FULL_PATH_KIND

    entry = SHORTCUT_KIND_MAP.get(initiator)
    if entry is None:
        return None

    verb, artifact = entry
    label = verb.replace("-", " ")
    if label:
        label = label[0].upper() + label[1:]
    if artifact:
        label = f"{label} {artifact.replace('-', ' ')}"
    return label
