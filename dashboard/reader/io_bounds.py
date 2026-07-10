# dashboard/reader/io_bounds.py
# Security hardening (v2.1.0, FIX-3 MEDIUM): shared bounded-read helper.
#
# Problem: the reader read every STATE.md / DETAIL.md / BLUEPRINT.md / PLAN.md /
# delivery-NNN-issues.md / KB doc fully into memory with no size cap. A very
# large (or maliciously large) file at any of these well-known paths could
# exhaust process memory (DoS) -- every reader read site called Path.read_bytes()
# directly with no bound.
#
# Fix: every content-read site in the reader routes through read_bytes_bounded()
# instead of Path.read_bytes(). Behavior:
#   - stat() first;
#   - size <= MAX_READ_BYTES  -> read the whole file (byte-identical to
#     Path.read_bytes() for every real-world file -- existing behavior and the
#     Python<->Node parity contract are unchanged for the common case);
#   - size >  MAX_READ_BYTES  -> read only the first MAX_READ_BYTES bytes
#     (bounded read). The file is NEVER skipped -- the reader's markdown/YAML
#     line-scanners tolerate a truncated tail (a cut-off line simply fails its
#     regex match); this matches the reader's no-throw / never-skip posture
#     (NFR7): degrade gracefully, don't fail closed.
#
# Twin: dashboard/server/reader.mjs readFileBounded() (byte-parity minded --
# both cap at 5 MB and both return the first N bytes of an oversized file).
#
# Read-only by construction: only Path.stat() / Path.read_bytes() / Path.open("rb").
# Python 3.11+ stdlib only. Zero third-party deps.

from __future__ import annotations

from pathlib import Path

# 5 MiB read cap (security hardening v2.1.0, FIX-3). Comfortably exceeds any
# legitimate STATE.md/DETAIL.md/PLAN.md/KB-doc size while bounding worst-case
# per-file memory use for the whole reader pass.
MAX_READ_BYTES = 5 * 1024 * 1024  # 5 MB


def read_bytes_bounded(path: Path, max_bytes: int = MAX_READ_BYTES) -> bytes:
    """Read up to max_bytes from path (stat-then-bounded-read).

    Byte-identical to path.read_bytes() when the file is <= max_bytes (the
    common case for every real repo file -- parity and existing behavior
    unchanged). For a file larger than max_bytes, returns only the first
    max_bytes bytes (never skips the file -- degrade gracefully, not fail-closed).

    Raises OSError on stat/open/read failure, exactly like Path.read_bytes()
    would -- every existing call site already wraps the read in
    try/except OSError, so this is a drop-in replacement.
    """
    size = path.stat().st_size
    if size <= max_bytes:
        return path.read_bytes()
    with path.open("rb") as f:
        return f.read(max_bytes)
