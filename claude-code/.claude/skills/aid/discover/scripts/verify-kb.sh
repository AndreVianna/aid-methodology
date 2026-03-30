#!/usr/bin/env bash
# Verify all 16 expected KB files exist in the given knowledge directory.
#
# Usage: verify-kb.sh <path-to-knowledge-dir>
# Example: verify-kb.sh .aid/knowledge/
#
# Agent-to-file mapping for re-dispatch:
#   discovery-scout:      project-structure.md, external-sources.md
#   discovery-architect:  architecture.md, technology-stack.md, ui-architecture.md
#   discovery-analyst:    module-map.md, coding-standards.md, data-model.md
#   discovery-integrator: api-contracts.md, integration-map.md, domain-glossary.md
#   discovery-quality:    test-landscape.md, security-model.md, tech-debt.md, infrastructure.md

set -euo pipefail

KB_DIR="${1:-.aid/knowledge}"

if [ ! -d "$KB_DIR" ]; then
  echo "❌ Directory not found: $KB_DIR"
  exit 1
fi

EXPECTED_FILES=(
  project-structure.md
  external-sources.md
  architecture.md
  technology-stack.md
  module-map.md
  coding-standards.md
  data-model.md
  api-contracts.md
  integration-map.md
  domain-glossary.md
  test-landscape.md
  security-model.md
  tech-debt.md
  infrastructure.md
  ui-architecture.md
  feature-inventory.md
)

missing=0
present=0

for f in "${EXPECTED_FILES[@]}"; do
  if [ -f "$KB_DIR/$f" ]; then
    echo "✅ $f"
    ((present++))
  else
    echo "❌ $f MISSING"
    ((missing++))
  fi
done

echo ""
echo "[$present/16] files present, $missing missing."

if [ "$missing" -gt 0 ]; then
  exit 1
fi
