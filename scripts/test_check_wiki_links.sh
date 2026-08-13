#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/check_wiki_links.sh
#
# Governance tooling must prove it fails when it should (TESTING.md, "Governance
# Tooling Must Be Tested"): a dangling link and an orphan page must each be
# caught, while the resolution rules (Display|Target, spaces->hyphens,
# case-insensitive, external-link skip) must not produce false positives.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
check_script="$script_dir/check_wiki_links.sh"

test_dir=$(mktemp -d)
echo "Running tests in: $test_dir"
cleanup() { rm -rf "$test_dir"; }
trap cleanup EXIT

run_check() {
  set +e
  output=$("$check_script" "$@" 2>&1)
  status=$?
  set -e
}

# ---------------------------------------------------------------------------
# 1. A clean wiki: Home links both pages, both exist -> OK, exit 0 even
#    under --strict.
# ---------------------------------------------------------------------------
repo="$test_dir/1"; mkdir -p "$repo/wiki"
cat > "$repo/wiki/Home.md" <<'MD'
# Home
- [[Alpha]]
- [[Beta Page]]
MD
echo "# Alpha" > "$repo/wiki/Alpha.md"
echo "# Beta" > "$repo/wiki/Beta-Page.md"

run_check --strict "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(1): clean wiki should pass, got $status"; exit 1; }
echo "$output" | grep -q "no dangling links, no orphans" || { echo "FAIL(1): expected clean summary"; exit 1; }
echo "SUCCESS(1): a clean wiki passes even under --strict (spaces->hyphens resolved)."

# ---------------------------------------------------------------------------
# 2. A dangling link -> warn/exit 0 default; --strict exit 1; target named.
# ---------------------------------------------------------------------------
repo="$test_dir/2"; mkdir -p "$repo/wiki"
cat > "$repo/wiki/Home.md" <<'MD'
# Home
- [[Nonexistent]]
MD
run_check "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(2): expected exit 0 by default, got $status"; exit 1; }
echo "$output" | grep -q "Dangling wiki links" || { echo "FAIL(2): dangling section missing"; exit 1; }
echo "$output" | grep -q "Nonexistent" || { echo "FAIL(2): dangling target not named"; exit 1; }
run_check --strict "$repo"
[ "$status" -eq 1 ] || { echo "FAIL(2): expected exit 1 under --strict, got $status"; exit 1; }
echo "SUCCESS(2): a dangling link warns by default and fails under --strict."

# ---------------------------------------------------------------------------
# 3. An orphan page (no page links to it) -> flagged; special pages never are.
# ---------------------------------------------------------------------------
repo="$test_dir/3"; mkdir -p "$repo/wiki"
cat > "$repo/wiki/Home.md" <<'MD'
# Home
- [[Linked]]
MD
echo "# Linked" > "$repo/wiki/Linked.md"
echo "# Lonely" > "$repo/wiki/Lonely.md"
echo "nav" > "$repo/wiki/_Sidebar.md"   # special, unlinked, must NOT be an orphan
run_check --strict "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(3): expected exit 1 for an orphan under --strict, got $status"; exit 1; }
echo "$output" | grep -q "Orphan pages" || { echo "FAIL(3): orphan section missing"; exit 1; }
echo "$output" | grep -q "Lonely.md" || { echo "FAIL(3): orphan page not named"; exit 1; }
echo "$output" | grep -q "_Sidebar" && { echo "FAIL(3): special page _Sidebar wrongly flagged as orphan"; exit 1; }
echo "SUCCESS(3): an orphan page is flagged; special pages are exempt."

# ---------------------------------------------------------------------------
# 4. Resolution rules do not false-positive: Display|Target, external links,
#    and case-insensitive matching.
# ---------------------------------------------------------------------------
repo="$test_dir/4"; mkdir -p "$repo/wiki"
cat > "$repo/wiki/Home.md" <<'MD'
# Home
- [[Show this text|Target Page]]
- [[GETTING started]]
- [[GitHub|https://github.com]]
MD
echo "# Target" > "$repo/wiki/Target-Page.md"
echo "# GS" > "$repo/wiki/Getting-Started.md"
run_check --strict "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(4): resolution rules should yield no findings, got $status"; exit 1; }
echo "SUCCESS(4): Display|Target, case-insensitive names, and external links resolve without false positives."

# ---------------------------------------------------------------------------
# 5. No wiki directory -> OK, exit 0 (a repo without a wiki is not failed).
# ---------------------------------------------------------------------------
repo="$test_dir/5"; mkdir -p "$repo"
run_check --strict "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(5): missing wiki dir should pass, got $status"; exit 1; }
echo "$output" | grep -q "No wiki/ directory" || { echo "FAIL(5): expected missing-dir message"; exit 1; }
echo "SUCCESS(5): a repository with no wiki directory is not failed."

# ---------------------------------------------------------------------------
# 6. Custom --wiki-dir is honored.
# ---------------------------------------------------------------------------
repo="$test_dir/6"; mkdir -p "$repo/documentation/wiki"
cat > "$repo/documentation/wiki/Home.md" <<'MD'
# Home
- [[Missing]]
MD
run_check --strict --wiki-dir documentation/wiki "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(6): expected --wiki-dir to be scanned and fail on the dangling link, got $status"; exit 1; }
echo "$output" | grep -q "Missing" || { echo "FAIL(6): dangling target not named under custom wiki dir"; exit 1; }
echo "SUCCESS(6): --wiki-dir is honored."

# ---------------------------------------------------------------------------
# 7. A [[Link]] that appears only inside inline code or a fenced code block is
#    not a real link (GitHub's wiki does not render it), so it must not be
#    reported as dangling. A page documenting the [[Page]] syntax by example
#    must stay clean.
# ---------------------------------------------------------------------------
repo="$test_dir/7"; mkdir -p "$repo/wiki"
cat > "$repo/wiki/Home.md" <<'MD'
# Home

Wiki pages cross-link with `[[Some Page]]` syntax, for example:

```
[[Another Missing Page]]
```

- [[Real]]
MD
echo "# Real" > "$repo/wiki/Real.md"
run_check --strict "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(7): [[links]] inside code must not be treated as real links, got $status"; exit 1; }
echo "$output" | grep -q "Some Page\|Another Missing Page" && { echo "FAIL(7): a code-span/fenced [[link]] was wrongly flagged"; exit 1; }
echo "SUCCESS(7): [[links]] inside inline code and fenced blocks are ignored."

# ---------------------------------------------------------------------------
# 8. Usage error (unknown option) -> exit 2.
# ---------------------------------------------------------------------------
run_check --nope "$test_dir/1"
[ "$status" -eq 2 ] || { echo "FAIL(8): expected exit 2 for an unknown option, got $status"; exit 1; }
echo "SUCCESS(8): usage errors report exit 2."

echo
echo "All check_wiki_links.sh tests passed."
