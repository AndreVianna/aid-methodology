#!/usr/bin/env bash
# fetch-mermaid.sh — fetches the latest Mermaid library and caches it.
# Usage: fetch-mermaid.sh
# Outputs (stdout, last line): VERSION=x.y.z PATH=.aid/knowledge/.cache/mermaid.min.js SHA256=...
# Re-uses cache if version hasn't changed.

set -eu

CACHE_DIR=".aid/knowledge/.cache"
CACHE_FILE="$CACHE_DIR/mermaid.min.js"
META_FILE="$CACHE_DIR/mermaid.min.js.meta"

mkdir -p "$CACHE_DIR"

# Get latest version from npm registry
LATEST=$(curl -sSf --max-time 30 "https://registry.npmjs.org/mermaid/latest" \
    | sed -nE 's/.*"version":"([^"]+)".*/\1/p' \
    | head -1)

if [ -z "$LATEST" ]; then
    echo "❌ Failed to determine latest Mermaid version from npm registry." >&2
    exit 1
fi

echo "ℹ️  Latest Mermaid version: $LATEST"

# Check cache
CACHED_VERSION=""
if [ -f "$META_FILE" ]; then
    CACHED_VERSION=$(grep -m1 '^version=' "$META_FILE" | cut -d= -f2)
fi

if [ -f "$CACHE_FILE" ] && [ "$CACHED_VERSION" = "$LATEST" ]; then
    SHA=$(grep -m1 '^sha256=' "$META_FILE" | cut -d= -f2)
    echo "✅ Cache hit: mermaid@$LATEST (sha256: ${SHA:0:12}...)"
    echo "VERSION=$LATEST PATH=$CACHE_FILE SHA256=$SHA"
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

# Compute sha256
if command -v sha256sum >/dev/null 2>&1; then
    SHA=$(sha256sum "$CACHE_FILE" | cut -d' ' -f1)
elif command -v shasum >/dev/null 2>&1; then
    SHA=$(shasum -a 256 "$CACHE_FILE" | cut -d' ' -f1)
else
    SHA="unknown"
fi

# Write meta
cat > "$META_FILE" <<EOF
version=$LATEST
sha256=$SHA
fetched_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
url=$URL
EOF

SIZE=$(wc -c < "$CACHE_FILE" | tr -d ' ')
echo "✅ Cached mermaid@$LATEST ($SIZE bytes, sha256: ${SHA:0:12}...)"
echo "VERSION=$LATEST PATH=$CACHE_FILE SHA256=$SHA"
