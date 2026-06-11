#!/usr/bin/env python3
# pt1_r7_check.py -- R7 escaping check for PT-1 parity test (feature-003, task-018).
#
# Verifies that /api/model raw responses from both runtimes:
#   1. Do NOT contain raw U+2028 (0xe2 0x80 0xa8) or U+2029 (0xe2 0x80 0xa9) bytes.
#   2. DO contain the escaped forms \\u2028 and \\u2029 (ASCII sequences).
#
# The fixture manifest has literal U+2028/U+2029 in aid_version, so the check
# is meaningful: if a server omits the post-process step, check 1 fails.
#
# Usage: python3 pt1_r7_check.py PYTHON_RAW_JSON NODE_RAW_JSON
# Exit 0 = all checks pass; exit 1 = one or more checks fail.
import sys

if len(sys.argv) < 3:
    sys.stderr.write("usage: pt1_r7_check.py PY_JSON NODE_JSON\n")
    sys.exit(1)

py_file = sys.argv[1]
node_file = sys.argv[2]

try:
    with open(py_file, "rb") as f:
        raw_py = f.read()
    with open(node_file, "rb") as f:
        raw_node = f.read()
except OSError as e:
    sys.stderr.write("R7 check: cannot open files: %s\n" % e)
    sys.exit(1)

LS_RAW = b"\xe2\x80\xa8"   # UTF-8 encoding of U+2028
PS_RAW = b"\xe2\x80\xa9"   # UTF-8 encoding of U+2029
LS_ESC = b"\\u2028"         # ASCII escaped form (6 bytes)
PS_ESC = b"\\u2029"         # ASCII escaped form (6 bytes)

failures = []

# Check 1: raw bytes must NOT appear
if LS_RAW in raw_py:
    failures.append("python output contains raw U+2028 bytes (not escaped)")
if LS_RAW in raw_node:
    failures.append("node output contains raw U+2028 bytes (not escaped)")
if PS_RAW in raw_py:
    failures.append("python output contains raw U+2029 bytes (not escaped)")
if PS_RAW in raw_node:
    failures.append("node output contains raw U+2029 bytes (not escaped)")

# Check 2: escaped form MUST appear (fixture has U+2028/U+2029 in aid_version)
if LS_ESC not in raw_py:
    failures.append("python output missing escaped \\u2028 (post-process absent?)")
if LS_ESC not in raw_node:
    failures.append("node output missing escaped \\u2028 (post-process absent?)")
if PS_ESC not in raw_py:
    failures.append("python output missing escaped \\u2029 (post-process absent?)")
if PS_ESC not in raw_node:
    failures.append("node output missing escaped \\u2029 (post-process absent?)")

if failures:
    for msg in failures:
        sys.stderr.write("  R7 FAIL: %s\n" % msg)
    sys.exit(1)

sys.exit(0)
