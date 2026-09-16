#!/usr/bin/env bash
set -euo pipefail

# Tests that the MCP server (mcp-server/index.js) cannot drift behind the
# repository: it must expose every root standards document as a resource,
# report the framework's VERSION rather than a hardcoded one, and keep its
# package manifests' version aligned with VERSION.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
index="$repo_root/mcp-server/index.js"
fail() { echo "FAIL: $*"; exit 1; }

echo "Test 1: every root standards document is an MCP resource"
standards=(CONSTITUTION.md AI_WORKFLOW.md INTEGRATION.md TESTING.md DOCUMENTATION.md SECURITY.md OPERATIONS.md ARCHITECTURE.md RELEASES.md CODE_STYLE.md TODO_GUIDELINES.md KNOWLEDGE_SOURCES.md sources/STYLE_GUIDES.md)
for doc in "${standards[@]}"; do
  [ -f "$repo_root/$doc" ] || fail "$doc does not exist in the repository (update this test's list)"
  grep -qF "path: \"$doc\"" "$index" || fail "mcp-server/index.js does not expose $doc"
done
echo "PASS (${#standards[@]} documents)"

echo "Test 2: every resource path points at a file that exists"
while IFS= read -r p; do
  [ -f "$repo_root/$p" ] || fail "index.js exposes $p, which does not exist"
done < <(grep -oE 'path: "[^"]+"' "$index" | sed -E 's/path: "([^"]+)"/\1/')
echo "PASS"

echo "Test 3: the server version comes from VERSION, not a literal"
grep -q 'readFrameworkVersion' "$index" || fail "index.js does not read the VERSION file"
grep -q 'version: FRAMEWORK_VERSION' "$index" || fail "server version is not FRAMEWORK_VERSION"
if grep -qE 'version: "[0-9]+\.[0-9]+\.[0-9]+"' "$index"; then fail "index.js still carries a hardcoded server version"; fi
echo "PASS"

echo "Test 4: package.json and package-lock.json versions equal VERSION"
expected=$(tr -d '\r\n' < "$repo_root/VERSION")
for f in package.json package-lock.json; do
  grep -qF "\"version\": \"$expected\"" "$repo_root/mcp-server/$f" || fail "mcp-server/$f version is not $expected"
done
echo "PASS"

echo "ALL TESTS PASSED"
