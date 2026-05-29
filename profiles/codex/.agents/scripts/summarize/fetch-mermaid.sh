#!/usr/bin/env bash
# fetch-mermaid.sh — fetches the pinned Mermaid library and caches it.
# Usage: fetch-mermaid.sh
# Outputs (stdout, last line): VERSION=x.y.z PATH=.aid/knowledge/.cache/mermaid.min.js SHA256=...
# Re-uses cache if version matches and SHA256 is valid.

set -eu

# === HOW TO BUMP THE MERMAID VERSION ===
#
# 1. Find the new version on npmjs: https://www.npmjs.com/package/mermaid
# 2. Compute the new SHA256:
#      curl -sS https://cdn.jsdelivr.net/npm/mermaid@<new-ver>/dist/mermaid.min.js | sha256sum
# 3. Update BOTH constants below atomically (PINNED_VERSION + EXPECTED_SHA256).
#    Don't update one without the other — the script will reject the cached
#    file on first run after a half-update.
# 4. Verify locally: `bash tests/canonical/fetch-mermaid.sh` must pass.
# =====================================

PINNED_VERSION="v11.15.0"
EXPECTED_SHA256="70137e77bb273bb2ef972b86e8b0400cca8be53cb25bfc45911a186dc98665de"

CACHE_DIR=".aid/knowledge/.cache"
CACHE_FILE="$CACHE_DIR/mermaid.min.js"
META_FILE="$CACHE_DIR/mermaid.min.js.meta"

mkdir -p "$CACHE_DIR"

# Derive LATEST from pinned version constant (no npm registry query)
LATEST="${PINNED_VERSION#v}"

echo "ℹ️  Pinned Mermaid version: $LATEST"

# Helper: compute sha256 of a file
compute_sha256() {
    local file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | cut -d' ' -f1
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | cut -d' ' -f1
    else
        echo "unknown"
    fi
}

# Check cache
CACHED_VERSION=""
if [ -f "$META_FILE" ]; then
    CACHED_VERSION=$(grep -m1 '^version=' "$META_FILE" | cut -d= -f2)
fi

if [ -f "$CACHE_FILE" ] && [ "$CACHED_VERSION" = "$LATEST" ]; then
    # Cache-hit path: verify SHA before trusting cached file
    ACTUAL_SHA=$(compute_sha256 "$CACHE_FILE")
    if [ "$ACTUAL_SHA" != "$EXPECTED_SHA256" ]; then
        echo "SHA256 mismatch for cached mermaid.min.js — refusing to use" >&2
        echo "  computed: $ACTUAL_SHA" >&2
        rm -f "$CACHE_FILE" "$META_FILE"
        exit 1
    fi
    echo "✅ Cache hit: mermaid@$LATEST (sha256: ${ACTUAL_SHA:0:12}...)"
    echo "VERSION=$LATEST PATH=$CACHE_FILE SHA256=$ACTUAL_SHA"
    exit 0
fi

# Download
URL="https://cdn.jsdelivr.net/npm/mermaid@${LATEST}/dist/mermaid.min.js"
echo "ℹ️  Downloading $URL"
if ! curl -sSf --max-time 120 -o "$CACHE_FILE.tmp" "$URL"; then
    echo "❌ Download failed: $URL" >&2
    rm -f "$CACHE_FILE.tmp"
    exit 1
fi

# Verify non-empty
if [ ! -s "$CACHE_FILE.tmp" ]; then
    echo "❌ Downloaded file is empty." >&2
    rm -f "$CACHE_FILE.tmp"
    exit 1
fi

mv "$CACHE_FILE.tmp" "$CACHE_FILE"

# Post-download path: verify SHA before accepting downloaded file
ACTUAL_SHA=$(compute_sha256 "$CACHE_FILE")
if [ "$ACTUAL_SHA" != "$EXPECTED_SHA256" ]; then
    echo "SHA256 mismatch for downloaded mermaid.min.js — refusing to use" >&2
    echo "  computed: $ACTUAL_SHA" >&2
    rm -f "$CACHE_FILE" "$META_FILE"
    exit 1
fi

# Write meta
cat > "$META_FILE" <<EOF
version=$LATEST
sha256=$ACTUAL_SHA
fetched_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
url=$URL
EOF

SIZE=$(wc -c < "$CACHE_FILE" | tr -d ' ')
echo "✅ Cached mermaid@$LATEST ($SIZE bytes, sha256: ${ACTUAL_SHA:0:12}...)"
echo "VERSION=$LATEST PATH=$CACHE_FILE SHA256=$ACTUAL_SHA"
