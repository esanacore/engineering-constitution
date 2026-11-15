#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/build_session_index.sh, which rebuilds the session log's
# index table from the entries.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
builder="$script_dir/build_session_index.sh"
checker="$script_dir/check_session_summaries.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

repo="$tmp/repo"
log="$repo/docs/sessions"

# entry <name> <title line> <topics line>
entry() {
  mkdir -p "$log"
  {
    printf '%s\n\n- **Date:** %s\n- **Agent:** test\n- **Branch / PR:** main\n%s\n- **Related:** none\n\n' "$2" "${1:0:10}" "$3"
    for s in Request Context Decisions Discoveries Outcome "Open Questions"; do
      printf '## %s\n\nSomething real.\n\n' "$s"
    done
  } > "$log/$1"
}
readme() {
  mkdir -p "$log"
  printf '# Session Log\n\nIntro prose.\n\n## Index\n\nNewest first.\n\n| Date | Session | Topics |\n| --- | --- | --- |\n%s' "${1:-}" > "$log/README.md"
}
rows() { grep -E '^\| [0-9]{4}-' "$log/README.md" || true; }

echo "Test 1: rows are built from the entries, newest first, same day in file-name order"
readme
entry 2026-01-05-login-timeouts.md "# Session: Login timeouts" "- **Topics:** auth, timeout"
entry 2026-03-15-b-second.md "# Session: Second that day" "- **Topics:** beta"
entry 2026-03-15-a-first.md "# First that day" "- **Topics**: alpha"
entry 2025-12-31-year-end.md "# Session: Year end" "- **Topics:** closing"
printf '# Session: <title>\n' > "$log/TEMPLATE.md"
out=$("$builder" "$repo")
expected='| 2026-03-15 | [First that day](2026-03-15-a-first.md) | alpha |
| 2026-03-15 | [Second that day](2026-03-15-b-second.md) | beta |
| 2026-01-05 | [Login timeouts](2026-01-05-login-timeouts.md) | auth, timeout |
| 2025-12-31 | [Year end](2025-12-31-year-end.md) | closing |'
[ "$(rows)" = "$expected" ] || { cat "$log/README.md"; fail "unexpected rows"; }
grep -q 'Rebuilt .* (4 session summaries)' <<< "$out" || fail "count not reported: $out"
echo "PASS"

echo "Test 2: text around the table is preserved and the header appears once"
grep -q '^Intro prose\.$' "$log/README.md" || fail "introduction lost"
grep -q '^Newest first\.$' "$log/README.md" || fail "prose under the heading lost"
[ "$(grep -c '^| Date | Session | Topics |$' "$log/README.md")" = 1 ] || fail "table header duplicated"
echo "PASS"

echo "Test 3: the result satisfies check_session_summaries.sh --strict"
"$checker" --strict "$repo" > /dev/null || fail "checker rejects the generated index"
echo "PASS"

echo "Test 4: a second run changes nothing"
before=$(cksum < "$log/README.md")
out=$("$builder" "$repo")
[ "$(cksum < "$log/README.md")" = "$before" ] || fail "second run rewrote the index"
grep -q 'is current' <<< "$out" || fail "did not report current: $out"
echo "PASS"

echo "Test 5: --check passes when current, fails without writing when stale"
"$builder" --check "$repo" > /dev/null || fail "--check failed on a current index"
entry 2026-04-01-new-work.md "# Session: New work" "- **Topics:** new"
before=$(cksum < "$log/README.md")
status=0; "$builder" --check "$repo" > /dev/null 2>&1 || status=$?
[ "$status" = 1 ] || fail "--check exit $status on a stale index, expected 1"
[ "$(cksum < "$log/README.md")" = "$before" ] || fail "--check wrote the file"
echo "PASS"

echo "Test 6: hand-edited and stale rows are replaced; content after the table survives"
readme '| 2020-01-01 | [Gone](2020-01-01-gone.md) | stale |
| 2026-01-05 | [Wrong title](2026-01-05-login-timeouts.md) | wrong |

## Notes

Kept.
'
"$builder" "$repo" > /dev/null
! grep -q 'Gone\|Wrong title' "$log/README.md" || fail "old rows survived"
[ "$(rows | wc -l)" -eq 5 ] || fail "expected 5 rows, got $(rows | wc -l)"
grep -q '^## Notes$' "$log/README.md" && grep -q '^Kept\.$' "$log/README.md" || fail "content after the table lost"
[ "$(grep -n '^## Notes$' "$log/README.md" | cut -d: -f1)" -gt "$(grep -n 'new-work' "$log/README.md" | cut -d: -f1)" ] || fail "table written after the next section"
echo "PASS"

echo "Test 7: an index heading with no table gets one"
printf '# Session Log\n\n## Index\n\nNewest first.\n' > "$log/README.md"
"$builder" "$repo" > /dev/null
[ "$(rows | wc -l)" -eq 5 ] || fail "table not created"
grep -q '^| Date | Session | Topics |$' "$log/README.md" || fail "header not created"
"$builder" --check "$repo" > /dev/null || fail "not stable after creating the table"
echo "PASS"

echo "Test 8: a pipe in a title or topic cannot break the row; a missing Topics line leaves the cell empty"
entry 2026-05-01-pipes.md "# Session: a | b" "- **Topics:** x|y"
entry 2026-05-02-no-topics.md "# Session: No topics" "- **Note:** none"
"$builder" "$repo" > /dev/null
grep -qF '| 2026-05-01 | [a \| b](2026-05-01-pipes.md) | x\|y |' "$log/README.md" || { rows; fail "pipe not escaped"; }
grep -qF '| 2026-05-02 | [No topics](2026-05-02-no-topics.md) |  |' "$log/README.md" || { rows; fail "missing Topics not handled"; }
echo "PASS"

echo "Test 9: files that are not dated entries are not indexed"
printf '# Notes\n' > "$log/notes.md"
"$builder" "$repo" > /dev/null
! grep -q 'notes.md\|TEMPLATE.md' <<< "$(rows)" || fail "non-entry file indexed"
echo "PASS"

echo "Test 10: an empty log yields an empty table"
rm -f "$log"/2*.md
"$builder" "$repo" > /dev/null
[ -z "$(rows)" ] || fail "rows left in an empty log"
grep -q '^| --- | --- | --- |$' "$log/README.md" || fail "table header missing"
echo "PASS"

echo "Test 11: usage errors exit 2"
for args in "--bogus" "--dir" "$repo $repo" "$tmp/missing"; do
  status=0
  # shellcheck disable=SC2086
  "$builder" $args > /dev/null 2>&1 || status=$?
  [ "$status" = 2 ] || fail "'$args' exited $status, expected 2"
done
mkdir -p "$tmp/bare"
status=0; "$builder" "$tmp/bare" > /dev/null 2>&1 || status=$?
[ "$status" = 2 ] || fail "no session log exited $status, expected 2"
mkdir -p "$tmp/noindex/docs/sessions"; printf '# Session Log\n' > "$tmp/noindex/docs/sessions/README.md"
status=0; "$builder" "$tmp/noindex" > /dev/null 2>&1 || status=$?
[ "$status" = 2 ] || fail "README without an Index heading exited $status, expected 2"
"$builder" --help | grep -q '^Usage:' || fail "--help prints no usage"
echo "PASS"

echo "Test 12: --dir selects another log directory"
mkdir -p "$tmp/alt/notes/log"
log="$tmp/alt/notes/log"
readme
entry 2026-06-01-alt.md "# Session: Alt" "- **Topics:** alt"
"$builder" --dir notes/log "$tmp/alt" > /dev/null
grep -qF '[Alt](2026-06-01-alt.md)' "$log/README.md" || fail "--dir not honored"
echo "PASS"

echo "Test 13: a CRLF README keeps its line endings, inside and outside the table"
log="$repo/docs/sessions"
entry 2026-07-01-crlf.md "# Session: Crlf" "- **Topics:** endings"
printf '# Session Log\r\n\r\nIntro.\r\n\r\n## Index\r\n\r\n| Date | Session | Topics |\r\n| --- | --- | --- |\r\n\r\nAfter.\r\n' > "$log/README.md"
"$builder" "$repo" > /dev/null
[ "$(grep -c $'\r$' "$log/README.md")" = "$(wc -l < "$log/README.md")" ] || { od -c "$log/README.md" | head -20; fail "line endings are mixed after a rebuild"; }
grep -q $'^Intro\\.\r$' "$log/README.md" && grep -q $'^After\\.\r$' "$log/README.md" || fail "text outside the table changed"
grep -qF '[Crlf](2026-07-01-crlf.md)' "$log/README.md" || fail "row missing in CRLF README"
"$builder" --check "$repo" > /dev/null || fail "CRLF README not stable"
echo "PASS"

echo "Test 14: an unreadable log directory is an error, not an empty index"
if [ "$(id -u)" != 0 ]; then
  before=$(cksum < "$log/README.md")
  chmod 300 "$log"
  status=0; "$builder" "$repo" > /dev/null 2>&1 || status=$?
  chmod 700 "$log"
  [ "$status" = 2 ] || fail "unreadable directory exited $status, expected 2"
  [ "$(cksum < "$log/README.md")" = "$before" ] || fail "index rewritten after a failed listing"
  echo "PASS"
else
  echo "SKIP (running as root; permissions are not enforced)"
fi

echo "All build_session_index.sh tests passed."
