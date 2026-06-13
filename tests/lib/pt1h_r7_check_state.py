#!/usr/bin/env python3
# pt1h_r7_check_state.py -- R7 escaping check for raw_state.text in details map (task-072).
#
# Verifies that the raw JSON responses from both runtimes (for ?detail= requests):
#   1. Do NOT contain raw U+2028 (0xe2 0x80 0xa8) or U+2029 (0xe2 0x80 0xa9) bytes
#      inside the 'raw_state.text' field of any entry in the 'details' map.
#   2. DO contain the escaped forms \\u2028 and \\u2029 (ASCII sequences) somewhere
#      in the raw response bytes (the fixture STATE.md has these characters).
#
# The pt1h-detail-repo fixture STATE.md has literal U+2028 and U+2029 in the
# ## Triage section, so raw_state.text will carry them -- and they MUST be
# escaped in the DM-3 canonical wire form.
#
# Usage: python3 pt1h_r7_check_state.py PYTHON_RAW_JSON NODE_RAW_JSON
# Exit 0 = all checks pass; exit 1 = one or more checks fail.
import json
import sys

if len(sys.argv) < 3:
    sys.stderr.write("usage: pt1h_r7_check_state.py PY_JSON NODE_JSON\n")
    sys.exit(1)

py_file = sys.argv[1]
node_file = sys.argv[2]

try:
    with open(py_file, "rb") as f:
        raw_py = f.read()
    with open(node_file, "rb") as f:
        raw_node = f.read()
except OSError as e:
    sys.stderr.write("R7 state check: cannot open files: %s\n" % e)
    sys.exit(1)

LS_RAW = b"\xe2\x80\xa8"   # UTF-8 encoding of U+2028
PS_RAW = b"\xe2\x80\xa9"   # UTF-8 encoding of U+2029
LS_ESC = b"\\u2028"         # ASCII escaped form (6 bytes)
PS_ESC = b"\\u2029"         # ASCII escaped form (6 bytes)

failures = []

# Check 1: raw bytes must NOT appear anywhere in the JSON wire bytes.
# (DM-3 requires the canonical form to escape these characters.)
if LS_RAW in raw_py:
    failures.append("python output contains raw U+2028 bytes (not escaped) in wire bytes")
if LS_RAW in raw_node:
    failures.append("node output contains raw U+2028 bytes (not escaped) in wire bytes")
if PS_RAW in raw_py:
    failures.append("python output contains raw U+2029 bytes (not escaped) in wire bytes")
if PS_RAW in raw_node:
    failures.append("node output contains raw U+2029 bytes (not escaped) in wire bytes")

# Check 2: escaped form MUST appear in the raw bytes.
# The fixture STATE.md embeds literal U+2028/U+2029, so after DM-3 post-processing
# they MUST appear as \\u2028/\\u2029 in the wire JSON.
if LS_ESC not in raw_py:
    failures.append("python output missing escaped \\u2028 in wire bytes (DM-3 post-process absent?)")
if LS_ESC not in raw_node:
    failures.append("node output missing escaped \\u2028 in wire bytes (DM-3 post-process absent?)")
if PS_ESC not in raw_py:
    failures.append("python output missing escaped \\u2029 in wire bytes (DM-3 post-process absent?)")
if PS_ESC not in raw_node:
    failures.append("node output missing escaped \\u2029 in wire bytes (DM-3 post-process absent?)")

# Check 3: parse both and verify the raw_state.text fields in the details map
# do NOT carry the raw characters at the Python object level (they should have
# been escaped in the wire JSON and the unicode escape will remain when parsed).
# We check the WIRE form (Checks 1 and 2) -- that is the definitive test.
# This extra check confirms the 'details' key is present and has at least one
# entry with a non-null raw_state.
for label, raw_bytes in [("python", raw_py), ("node", raw_node)]:
    try:
        data = json.loads(raw_bytes.decode("utf-8"))
        details = data.get("details", None)
        if details is None:
            failures.append("%s: 'details' key absent in response (expected for ?detail= request)" % label)
            continue
        if not isinstance(details, dict) or len(details) == 0:
            failures.append("%s: 'details' is empty or not a dict" % label)
            continue
        # At least one entry must have a non-null raw_state
        has_raw_state = any(
            isinstance(v, dict) and v.get("raw_state") is not None
            for v in details.values()
        )
        if not has_raw_state:
            failures.append("%s: no entry in 'details' has a non-null raw_state" % label)
    except Exception as e:
        failures.append("%s: parse error: %s" % (label, e))

if failures:
    for msg in failures:
        sys.stderr.write("  R7-state FAIL: %s\n" % msg)
    sys.exit(1)

sys.exit(0)
