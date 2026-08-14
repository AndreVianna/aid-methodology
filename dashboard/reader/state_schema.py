# dashboard/reader/state_schema.py
# STATE.yml whole-document read (work-009-refactor task-003).
#
# Responsibility:
#   - parse_state_document(text, *, allow_frontmatter_fence=False) -- THE
#     single hand-rolled parser for the SPEC.md (work-009-refactor) "§ D-3
#     permitted YAML subset": shapes S1-S5, the two § D-5 quoting/escape
#     modes, inline- and full-line-comment handling, and the § D-3 reject
#     list (each rejected construct yields a parse_warning naming
#     file/line/construct, skips exactly that key, and never raises). This is
#     the EXTENSION of what used to be `parse_frontmatter_scalars` -- a flat +
#     one-level-nested scalar scanner bound to a leading '---'-fenced
#     frontmatter block. By default (every state-file reader) it parses the
#     WHOLE input as one YAML-subset document (the STATE.yml shape -- no
#     `---` at all, § D-1); a state file that nonetheless opens with a `---`
#     is rejected by the strict engine as a second document, same as any
#     other reject-list violation. The CALLER, never the document's own
#     leading bytes, decides otherwise: passing `allow_frontmatter_fence=True`
#     opts in to the ORIGINAL fenced-frontmatter-only scan, UNCHANGED, for a
#     text that opens with a '---' line. That opt-in exists for exactly one
#     caller: `parsers.parse_kb_state`, for `.aid/knowledge/STATE.md`, which
#     stays markdown-with-frontmatter by design (out of scope for this work;
#     SPEC.md § D-6) and legitimately still carries constructs the strict
#     § D-3 subset would reject (e.g. a flow list `tags: [a, b]`) --
#     preserving its old, looser scan avoids inventing new parse_warnings for
#     a file this work does not touch.
#   - parse_bool_yesno(raw) -- normalizes yes/no/true/false (case-insensitive)
#     to a Python bool, closing the twin-parity landmine flagged in the
#     task-001 review (see docstring below).
#   - parse_header_bold_field(text, label) -- legacy-prose fallback scan of
#     the pre-first-"##" header-blockquote zone for a '**{label}:** value'
#     line (mirrors derivation.py's _parse_minimum_grade scan bound). Its
#     STATE.md call sites are retired by this task (state files no longer
#     carry a legacy-prose fallback); it survives because
#     `parsers.parse_kb_state` still calls it for the KB's own
#     `.aid/knowledge/STATE.md` header-blockquote fields (kb_status /
#     kb_grade / last_kb_review) -- a non-state, out-of-scope caller.
#   - resolve_kind(initiator) -- maps a pipeline.initiator skill name to a
#     human display verb via a static mirror of shortcut-catalog.yml.
#
# No write / no I/O side-effects (pure text -> value). Python 3.11+ stdlib
# only. Zero third-party deps -- no YAML library is introduced. The § D-3
# subset is deliberately restricted (five shapes, two quoting modes, an
# explicit reject list) so this hand-rolled scanner stands in for a real YAML
# parser (same posture as parsers.py's own parse_doc_frontmatter -- the
# per-KB-doc sources:/approved_at_commit: scanner -- and as
# .claude/skills/generate-profile/scripts/build-shortcut-skills.py's own
# hand-rolled shortcut-catalog.yml reader).
#
# Node twin: dashboard/server/reader.mjs defines the SAME functions inline
# (parseStateDocument / parseBoolYesno / parseHeaderBoldField / resolveKind /
# SHORTCUT_KIND_MAP) since the Node reader is a single file, not a package.
# Keep both in lockstep.

from __future__ import annotations

import re
from typing import Optional

# ---------------------------------------------------------------------------
# Generic scalar quoting/placeholder helpers (unchanged in behavior -- shared
# by both the strict § D-3 document engine below and the legacy fenced scan)
# ---------------------------------------------------------------------------

_RE_FM_FENCE = re.compile(r"^---\s*$")
_RE_TOPLEVEL_KV = re.compile(r"^([A-Za-z0-9_\-]+):\s*(.*)$")
_RE_NESTED_KV = re.compile(r"^[ \t]+([A-Za-z0-9_\-]+):\s*(.*)$")
_RE_SECTION_HEADER = re.compile(r"^##\s+")

# A '{...}' template token anywhere in the value (matching braces, no nested
# '}'). Every un-instantiated placeholder in a legacy header-blockquote
# markdown template carries one (e.g. "{YYYY-MM-DD}", "{grade or Pending}").
_RE_PLACEHOLDER_TOKEN = re.compile(r"\{[^}]*\}")

# Frontmatter/document keys whose value is human/skill free-text, NOT a closed
# enum. Their template placeholders always carry a '{...}' token, so the
# token rule still skips un-filled scaffold text -- but a REAL free-text value
# that merely contains ' | ' (e.g. a pause reason "waiting on A | else B") must
# NOT be mistaken for an enum-alternatives placeholder and discarded. Closed-
# enum fields (lifecycle/phase/path/delivery_state/...) never legitimately
# contain ' | ', so the ' | '-list rule below stays active for them.
_FREETEXT_FM_KEYS = frozenset({"pause_reason", "block_reason", "block_artifact", "notes"})


def _strip_scalar_quotes(raw: str) -> str:
    """Strip one layer of matching surrounding quotes from a YAML scalar.

    For a SINGLE-quoted scalar, also collapse YAML's ''-escaping (`''` -> `'`) --
    the exact inverse of the writer (writeback-state.sh emits a single-quoted
    scalar for any free-text value that needs quoting, doubling an embedded `'`).
    Without this, `notes: 'user''s reason'` would read back as `user''s reason`.
    Double-quoted scalars are stripped as-is here (no escape decoding -- see
    `_decode_double_quoted` for the § D-5 mode-3 five-escape subset, used only
    by the strict document engine below).
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

    Rollout safety net, still exercised by the legacy fenced-frontmatter path
    (a `.aid/knowledge/STATE.md` scaffolded from discovery-state-template.md,
    which stays markdown and can still carry un-filled '{...}' placeholder
    text). The current STATE.yml templates (work/delivery/task) ship with real
    example values, not '{...}' tokens, so this rule is a no-op on that path
    in practice -- but it is applied there too (uniformly, on every key-based
    scalar value) for defense-in-depth, at zero behavioral cost.

    Two markers, matching how the legacy markdown templates document
    placeholders:
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


# ---------------------------------------------------------------------------
# § D-5 quoted-scalar decoding
# ---------------------------------------------------------------------------

_DQ_ESCAPES = {'"': '"', "\\": "\\", "n": "\n", "r": "\r", "t": "\t"}


def _decode_double_quoted(inner: str, line_no: int, file_label: str, warnings: list[str]) -> str:
    """Decode the five-escape subset (`\\"`, `\\\\`, `\\n`, `\\r`, `\\t`) inside a
    double-quoted scalar's INNER text (quotes already stripped).

    Any other backslash escape (`\\uXXXX`, `\\x41`, ...) is REJECTED per § D-3:
    a parse_warning is emitted naming file/line, and the backslash + following
    character are kept LITERALLY (never raises, never drops the rest of the
    value). This is the one new quoting mode (§ D-5 mode 3) -- used only by
    the strict whole-document engine, never by the legacy fenced scan (the
    writer never emitted a backslash-escaped double-quoted scalar before this
    work, so no existing frontmatter block needs this path).
    """
    out: list[str] = []
    i = 0
    n = len(inner)
    while i < n:
        c = inner[i]
        if c == "\\" and i + 1 < n:
            nxt = inner[i + 1]
            mapped = _DQ_ESCAPES.get(nxt)
            if mapped is not None:
                out.append(mapped)
                i += 2
                continue
            warnings.append(
                f"{file_label}:{line_no}: unsupported double-quoted escape "
                f"'\\{nxt}' rejected; kept literally"
            )
            out.append(c)
            out.append(nxt)
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def _decode_scalar(v: str, line_no: int, file_label: str, warnings: list[str]) -> str:
    """Decode one already comment-stripped, already-trimmed scalar token.

    Double-quoted -> the § D-5 mode-3 five-escape subset (`_decode_double_quoted`).
    Single-quoted / bare -> `_strip_scalar_quotes` (unchanged helper; handles
    the `''`-doubling inverse and is a no-op pass-through for bare values).
    """
    if len(v) >= 2 and v[0] == '"' and v[-1] == '"':
        return _decode_double_quoted(v[1:-1], line_no, file_label, warnings)
    return _strip_scalar_quotes(v)


def _strip_inline_comment(scalar: str) -> str:
    """Strip a trailing inline '#' comment from a scalar value (D-3).

    Local mirror of the SAME idiom as parsers._strip_yaml_inline_comment
    (parsers.py:304) -- duplicated rather than imported to avoid a circular
    import (parsers.py imports FROM this module). Drops everything from the
    first '#' that is NOT inside a quoted string to end-of-line; handles
    single- and double-quoted values (naive single-occurrence quote-close
    scan, matching the existing idiom -- see its docstring for the accepted
    edge-case limitation with a `''`-doubled value immediately followed by a
    real trailing comment).
    """
    s = scalar
    if s and s[0] in ('"', "'"):
        quote = s[0]
        end = s.find(quote, 1)
        if end != -1:
            after = s[end + 1:].lstrip()
            if after.startswith("#"):
                s = s[:end + 1]
        return s
    idx = s.find("#")
    if idx != -1:
        s = s[:idx]
    return s


# ---------------------------------------------------------------------------
# Strict § D-3 whole-document engine (S1-S5 + reject list)
# ---------------------------------------------------------------------------

# A key: identifier chars only (matches every real key in the D-4 schemas,
# including S3 mapping-of-mappings ids like 'task-001').
_RE_KEY_LINE = re.compile(r"^([A-Za-z0-9_-]+):\s*(.*)$")

_MAX_LEVEL = 3  # S3 (3 mapping levels) / S5 (a sequence at the 2nd level)

_REJECT = object()  # sentinel: "skip this key/item entirely, emit no value"


def _tokenize(
    numbered: "list[tuple[int, str]]", warnings: list[str], file_label: str
) -> "list[dict]":
    """Pass 1: classify each line into a token, applying every non-value
    § D-3 reject rule that can be decided from indentation/shape alone (tabs,
    indent-not-multiple-of-two, nesting-too-deep, a second document marker,
    a line that is neither a 'key:' line nor a sequence entry). Full-line
    comments (any indentation) and blank lines are silently skipped (not a
    reject -- D-3 says these are normal, expected constructs).
    """
    tokens: list[dict] = []
    for line_no, raw in numbered:
        lead_len = len(raw) - len(raw.lstrip(" \t"))
        lead = raw[:lead_len]
        if "\t" in lead:
            warnings.append(
                f"{file_label}:{line_no}: tab indentation rejected; line skipped"
            )
            continue

        line = raw.rstrip("\r\n")
        if not line.strip():
            continue  # blank line

        indent = len(line) - len(line.lstrip(" "))
        content = line[indent:]

        if content.startswith("#"):
            continue  # full-line comment, any indentation (D-3)

        if indent % 2 != 0:
            warnings.append(
                f"{file_label}:{line_no}: indentation not a multiple of two; "
                f"line skipped"
            )
            continue

        level = indent // 2
        if level > _MAX_LEVEL:
            warnings.append(
                f"{file_label}:{line_no}: nesting deeper than S5; line skipped"
            )
            continue

        if content in ("---", "..."):
            warnings.append(
                f"{file_label}:{line_no}: a second document ('{content}') is "
                f"rejected; line skipped"
            )
            continue

        # A bare (non-'key:') directive/anchor/alias/tag line at column 0 or
        # deeper -- e.g. a YAML directive '%YAML 1.2'. None of these four
        # indicator characters can start a valid key (_RE_KEY_LINE's charset
        # is alnum/underscore/hyphen only), so this check is unambiguous and
        # must run BEFORE the key-line/malformed-line fallback below, which
        # would otherwise report it as a generic malformed line instead of
        # naming the specific rejected construct (D-3).
        if content[:1] in ("%", "&", "*", "!"):
            warnings.append(
                f"{file_label}:{line_no}: anchor/alias/tag/directive rejected"
            )
            continue

        if content == "-" or content.startswith("- "):
            body = content[2:] if content.startswith("- ") else ""
            m = _RE_KEY_LINE.match(body) if body else None
            if m:
                tokens.append({
                    "line_no": line_no, "level": level, "dash": True,
                    "key": m.group(1), "rest": m.group(2),
                })
            else:
                tokens.append({
                    "line_no": line_no, "level": level, "dash": True,
                    "key": None, "rest": body,
                })
            continue

        m = _RE_KEY_LINE.match(content)
        if not m:
            warnings.append(
                f"{file_label}:{line_no}: malformed line (neither a 'key:' "
                f"line nor a sequence entry); line skipped"
            )
            continue
        tokens.append({
            "line_no": line_no, "level": level, "dash": False,
            "key": m.group(1), "rest": m.group(2),
        })

    return tokens


def _finalize_value(
    raw_rest: str,
    tok: dict,
    file_label: str,
    warnings: list[str],
    *,
    key_name: Optional[str] = None,
    is_list_item: bool = False,
):
    """Turn a token's raw value text into a scalar str, [], {}, or _REJECT.

    Applies, in order: inline-comment stripping (D-3), the flow-collection /
    block-scalar / anchor-alias-tag-directive reject checks (D-3, each on
    first-character shape so a quoted value is never misdetected), § D-5
    scalar decoding, and -- for key-based values only, never for a bare
    sequence-of-scalars item -- the rollout-safety placeholder check.

    The placeholder check's ' | ' enum-alternatives rule is suppressed for
    any QUOTED value (single- or double-quoted), not only for the
    `_FREETEXT_FM_KEYS` set: § D-5 mode 2 exists precisely so a real value
    containing '|' round-trips (FR-4b) by being single-quoted, and every
    legacy placeholder that ever used ' | ' as an enum-alternatives marker
    was BARE/unquoted (a quoted legacy placeholder always carries a '{...}'
    token instead, e.g. "{short text} | --", which the token rule below still
    catches regardless of quoting). Without this, a real quoted '|'-bearing
    value read back through this same rule would be silently discarded.
    """
    v = _strip_inline_comment(raw_rest).strip()
    was_quoted = bool(v) and v[0] in ("'", '"')
    if v == "":
        decoded = ""
    else:
        first = v[0]
        if first in ("[", "{"):
            if v == "[]":
                return []
            if v == "{}":
                return {}
            warnings.append(
                f"{file_label}:{tok['line_no']}: flow collection rejected "
                f"(only the literal [] / {{}} is permitted)"
            )
            return _REJECT
        if first in ("|", ">"):
            warnings.append(
                f"{file_label}:{tok['line_no']}: block scalar rejected"
            )
            return _REJECT
        if first in ("&", "*", "!", "%"):
            warnings.append(
                f"{file_label}:{tok['line_no']}: anchor/alias/tag/directive "
                f"rejected"
            )
            return _REJECT
        decoded = _decode_scalar(v, tok["line_no"], file_label, warnings)

    if not is_list_item:
        is_freetext = was_quoted or (key_name in _FREETEXT_FM_KEYS if key_name else False)
        if _looks_like_unfilled_placeholder(decoded, is_freetext=is_freetext):
            return _REJECT

    return decoded


def _build_tree(tokens: "list[dict]", warnings: list[str], file_label: str) -> dict:
    """Pass 2: assemble the token stream into a nested dict/list tree.

    Uses a level-indexed stack of currently-open containers (level 0 == the
    root mapping; deeper levels are opened by a bare 'key:' mapping opener or
    by a dash-with-inline-key sequence item, and closed the moment a
    shallower-or-equal-level token arrives). A bare opener's dict-vs-list
    shape is decided by a single-token lookahead (its first child's dash-ness)
    -- defaulting to an empty mapping when it has no children at all (D-3:
    "an absent key is semantically identical to an empty collection ... the
    two [are treated] the same").

    Duplicate keys at the same mapping level: last value wins, and a
    parse_warning is emitted (D-3).
    """
    root: dict = {}
    stack: dict[int, object] = {0: root}
    stack_kind: dict[int, str] = {0: "map"}

    n = len(tokens)
    for i, tok in enumerate(tokens):
        level = tok["level"]

        for lvl in [l for l in stack if l > level]:
            del stack[lvl]
            del stack_kind[lvl]

        parent = stack.get(level)
        parent_kind = stack_kind.get(level)
        if parent is None:
            warnings.append(
                f"{file_label}:{tok['line_no']}: orphan line (no open parent "
                f"container at this indentation); line skipped"
            )
            continue

        if tok["dash"]:
            if parent_kind != "list":
                warnings.append(
                    f"{file_label}:{tok['line_no']}: sequence entry where a "
                    f"mapping key was expected; line skipped"
                )
                continue
            if tok["key"] is not None:
                item: dict = {}
                val = _finalize_value(
                    tok["rest"], tok, file_label, warnings, key_name=tok["key"]
                )
                if val is not _REJECT:
                    item[tok["key"]] = val
                parent.append(item)
                stack[level + 1] = item
                stack_kind[level + 1] = "map"
            else:
                val = _finalize_value(
                    tok["rest"], tok, file_label, warnings, is_list_item=True
                )
                if val is not _REJECT:
                    parent.append(val)
            continue

        # Plain 'key:' line
        if parent_kind != "map":
            warnings.append(
                f"{file_label}:{tok['line_no']}: mapping key where a sequence "
                f"entry was expected; line skipped"
            )
            continue

        key = tok["key"]
        rest = tok["rest"].strip()
        if rest == "":
            nxt = tokens[i + 1] if i + 1 < n else None
            if nxt is not None and nxt["level"] == level + 1 and nxt["dash"]:
                new_container: object = []
                new_kind = "list"
            else:
                new_container = {}
                new_kind = "map"
            if key in parent:
                warnings.append(
                    f"{file_label}:{tok['line_no']}: duplicate key '{key}'; "
                    f"last value wins"
                )
            parent[key] = new_container
            stack[level + 1] = new_container
            stack_kind[level + 1] = new_kind
            continue

        val = _finalize_value(rest, tok, file_label, warnings, key_name=key)
        if val is not _REJECT:
            if key in parent:
                warnings.append(
                    f"{file_label}:{tok['line_no']}: duplicate key '{key}'; "
                    f"last value wins"
                )
            parent[key] = val

    return root


def _parse_fenced_frontmatter_loose(text: str) -> dict[str, str]:
    """The ORIGINAL parse_frontmatter_scalars scan, UNCHANGED: tolerant flat +
    one-level-nested frontmatter scalar scan between the first pair of '---'
    lines. Never emits parse_warnings (matches the original contract). This
    is the path `.aid/knowledge/STATE.md` (out of scope, stays markdown, may
    legitimately carry constructs -- e.g. a flow list `tags: [a, b]` -- the
    strict § D-3 engine would reject) continues to use verbatim.

    Returns a flat dict:
      - top-level scalar keys map directly:      'started: 2026-07-10'
                                                  -> {'started': '2026-07-10'}
      - one level of nested mapping is dot-joined:
          'pipeline:\n  path: lite\n  initiator: aid-refactor\n'
          -> {'pipeline.path': 'lite', 'pipeline.initiator': 'aid-refactor'}

    Rollout safety: a value that _looks_like_unfilled_placeholder() (still
    carries the template's own '{...}' or ' | '-alternatives documentation
    text) is SKIPPED entirely -- the key is treated as absent.

    Never raises. Returns {} when no opening '---' fence is present.
    """
    result: dict[str, str] = {}
    in_fm = False
    fm_entered = False
    current_prefix: Optional[str] = None

    for line in text.splitlines():
        if _RE_FM_FENCE.match(line):
            if not fm_entered:
                in_fm = True
                fm_entered = True
                continue
            else:
                break

        if not in_fm:
            break

        if not line.strip():
            continue

        if line[:1] in (" ", "\t"):
            if current_prefix is None:
                continue
            m = _RE_NESTED_KV.match(line)
            if m:
                key, val = m.group(1), _strip_scalar_quotes(m.group(2))
                if val != "" and not _looks_like_unfilled_placeholder(
                    val, is_freetext=key in _FREETEXT_FM_KEYS
                ):
                    result[f"{current_prefix}.{key}"] = val
            continue

        m = _RE_TOPLEVEL_KV.match(line)
        if not m:
            current_prefix = None
            continue

        key, rest = m.group(1), m.group(2).strip()
        if rest == "":
            current_prefix = key
            continue

        current_prefix = None
        val = _strip_scalar_quotes(rest)
        if not _looks_like_unfilled_placeholder(val, is_freetext=key in _FREETEXT_FM_KEYS):
            result[key] = val

    return result


def parse_state_document(
    text: str,
    *,
    file_label: str = "STATE",
    allow_frontmatter_fence: bool = False,
) -> "tuple[dict, list[str]]":
    """Parse a STATE.yml document -- or, ONLY when the caller opts in, a
    legacy frontmatter block -- into a nested dict tree, plus a list of
    parse_warning strings.

    Dispatch is decided by the CALLER, via `allow_frontmatter_fence`, never
    by sniffing the document's own content. A prior revision of this
    function decided strict-vs-loose by checking whether `text`'s first line
    was a bare '---'; that made a malformed STATE.yml that happens to open
    with a fence (the exact construct § D-1/§ D-3 forbid: "one file, one
    document" / "a second document ... at column 0") silently take the LOOSE
    path instead of being rejected -- the one § D-3 reject-list construct
    that produced no warning at all. Content can decide WHAT is wrong with a
    document; it must never decide WHICH GRAMMAR is used to read it.

      - `allow_frontmatter_fence=False` (the default -- every state-file
        reader in this package uses this): the WHOLE text is parsed by the
        strict § D-3 subset engine: shapes S1-S5, both § D-5 quoting/escape
        modes, inline- and full-line-comment stripping, and the full reject
        list (tabs, non-literal flow collections, block scalars, anchors/
        aliases/tags/directives, a second document -- INCLUDING one at
        column 0, bad indentation, nesting deeper than S5, a malformed line,
        a duplicate key, a BOM). Every reject emits a parse_warning naming
        file/line/construct, skips exactly that key, and keeps parsing --
        never raises.

      - `allow_frontmatter_fence=True` (the ONE legitimate caller:
        `parsers.parse_kb_state`, for `.aid/knowledge/STATE.md`, which stays
        markdown-with-frontmatter by design and is out of scope for this
        work -- SPEC.md § D-6) -- a leading '---' fence on the text's very
        first line switches to the ORIGINAL, unchanged, flat + one-level-
        nested scan (`_parse_fenced_frontmatter_loose`), bounded to the
        region between the first and second '---' lines (or to EOF if no
        closing fence is found); this preserves that file's exact current
        behavior, including its tolerance for constructs the strict engine
        would reject (e.g. a flow list `tags: [a, b]`). This path emits no
        parse_warnings, exactly like the original function. If the caller
        passes `allow_frontmatter_fence=True` but the text does NOT open
        with a fence, the strict engine runs anyway (opting in to leniency
        never means opting OUT of it when the input doesn't ask for it).

    A leading byte-order mark is stripped and a parse_warning is emitted
    naming the file, in EITHER path, before fence detection runs.

    Returns (data, warnings):
      - data: nested dict tree in the strict path (S1 scalar keys map to
        str; S2/S3 mapping keys map to dict; S4/S5 sequence keys map to
        list); a FLAT dot-joined dict[str, str] in the fenced-legacy path
        (unchanged contract).
      - warnings: list[str] of parse_warning messages; always [] in the
        fenced-legacy path.

    Never raises (NFR7). No file I/O -- pure text -> value.
    """
    warnings: list[str] = []

    if text.startswith("﻿"):
        text = text[1:]
        warnings.append(f"{file_label}: byte-order mark (BOM) stripped")

    raw_lines = text.splitlines()

    if allow_frontmatter_fence and raw_lines and _RE_FM_FENCE.match(raw_lines[0]):
        # Legacy fenced-frontmatter shape -- unchanged loose scan, bounded to
        # the region between the first and second '---' lines. Reachable
        # ONLY when the caller opted in (parse_kb_state); every state-file
        # reader leaves allow_frontmatter_fence at its strict default, so a
        # state file opening with '---' falls through to the strict engine
        # below and is rejected as a second document, like any other one.
        body_lines: list[str] = []
        for ln in raw_lines[1:]:
            if _RE_FM_FENCE.match(ln):
                break
            body_lines.append(ln)
        fenced_text = "---\n" + "\n".join(body_lines) + "\n---\n"
        data = _parse_fenced_frontmatter_loose(fenced_text)
        return data, warnings

    numbered = [(i + 1, ln) for i, ln in enumerate(raw_lines)]
    tokens = _tokenize(numbered, warnings, file_label)
    data = _build_tree(tokens, warnings, file_label)
    return data, warnings


def parse_header_bold_field(text: str, label: str) -> Optional[str]:
    """Legacy-prose fallback: scan the pre-first-"##" header-blockquote zone
    for a '**{label}:** value' line (optionally '>'-prefixed blockquote),
    case-insensitive search (not anchored -- matches with or without a
    leading '>' blockquote marker). Mirrors derivation.py's
    _parse_minimum_grade scan bound (stop at the first '##' section header)
    so every header-blockquote field shares one convention.

    Retired for STATE.md (work/delivery/task): those state files no longer
    have a header-blockquote fallback at all (parse_state_document plus
    legacy-STATE.md detection replaces it). The sole surviving caller is
    `parsers.parse_kb_state`, for `.aid/knowledge/STATE.md`'s own
    '**Status:**' / '**Current Grade:**' / '**Last KB Review:**' lines -- a
    non-state, out-of-scope file (SPEC.md § D-6).

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
    twin uses a real YAML library here (both hand-parse via
    parse_state_document, which always returns the raw string regardless of
    literal form) -- but a THIRD-PARTY tool that loads+re-dumps a STATE.yml
    with PyYAML could rewrite 'yes'/'no' to 'true'/'false' on disk, or resolve
    an UNQUOTED bare 'no' to boolean before it ever reaches this reader.
    SPEC.md § D-5's implicit-type deny list is the write-side half of this fix
    (every yes/no/true/false/on/off/null-shaped token is ALWAYS quoted, never
    bare, so a spec-conformant STATE.yml never round-trips through that
    divergence at all); this helper is the read-side half, kept for a
    third-party-re-dumped file and accepting all four literals
    (case-insensitive) so both twins agree on the SAME logical boolean no
    matter which literal form ends up on disk.

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
# twin (reader.mjs SHORTCUT_KIND_MAP). Includes every catalogue row plus
# every historical name ever written into durable pipeline.initiator
# frontmatter -- the map is a strict superset of the current catalogue.
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
    "aid-create-test": ("create", "test"),
    "aid-create-document": ("create", "document"),
    "aid-create-dashboard": ("create", "dashboard"),
    "aid-create-diagram": ("create", "diagram"),
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
    "aid-add-test": ("create", "test"),
    "aid-add-document": ("create", "document"),
    "aid-add-dashboard": ("create", "dashboard"),
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
    "aid-change-test": ("change", "test"),
    "aid-change-document": ("change", "document"),
    "aid-change-dashboard": ("change", "dashboard"),
    "aid-refactor": ("refactor", ""),
    "aid-update": ("update", ""),
    "aid-update-api": ("update", "api"),
    "aid-update-ui": ("update", "ui"),
    "aid-update-theme": ("update", "theme"),
    "aid-update-cli": ("update", "cli"),
    "aid-update-data-model": ("update", "data-model"),
    "aid-update-data-pipeline": ("update", "data-pipeline"),
    "aid-update-messaging": ("update", "messaging"),
    "aid-update-integration": ("update", "integration"),
    "aid-update-job": ("update", "job"),
    "aid-update-config": ("update", "config"),
    "aid-update-infra": ("update", "infra"),
    "aid-update-test": ("update", "test"),
    "aid-update-document": ("update", "document"),
    "aid-update-dashboard": ("update", "dashboard"),
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
    "aid-design": ("design", ""),
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
# starts Describe -> Define -> Specify -> Plan -> Detail -> Execute, not a Lite
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
