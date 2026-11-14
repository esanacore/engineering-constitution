#!/usr/bin/env bash
set -euo pipefail

# Negative-case tests for scripts/check_session_summaries.sh.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
checker="$script_dir/check_session_summaries.sh"
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

good='# Session: Add rate limiting to the public API

- **Date:** 2026-03-04
- **Agent:** Example agent
- **Branch / PR:** feat/rate-limit, #12
- **Topics:** rate limiting, api, redis, 429
- **Related:** none

## Request

Stop one client from starving the others.

## Context

The requester had already tried a per-process counter.

## Decisions

- Token bucket in Redis (requester chose it over a fixed window).

## Discoveries

None.

## Outcome

Shipped in #12; 14 tests pass.

## Open Questions

None.'

# make_log <dir> [<file-name> <markdown>]...: a session log with an index
# linking every named entry.
make_log() {
  local d=$1; shift
  mkdir -p "$d/docs/sessions"
  printf '# Session Log\n\n| Date | Session | Topics |\n| --- | --- | --- |\n' > "$d/docs/sessions/README.md"
  while [ "$#" -ge 2 ]; do
    printf '%s\n' "$2" > "$d/docs/sessions/$1"
    printf '| x | [s](%s) | t |\n' "$1" >> "$d/docs/sessions/README.md"
    shift 2
  done
}

# expect_finding <dir> <fixed string> <description> [checker args...]: warn
# mode reports it and exits 0; --strict exits 1.
expect_finding() {
  local d=$1 want=$2 what=$3 status=0 out
  shift 3
  out=$("$checker" "$@" "$d") || status=$?
  [ "$status" -eq 0 ] || { echo "$out"; fail "$what: warn mode exited $status"; }
  grep -qF -- "$want" <<< "$out" || { echo "$out"; fail "$what: expected '$want'"; }
  grep -q '^WARN: ' <<< "$out" || { echo "$out"; fail "$what: warn mode printed no WARN line"; }
  status=0; "$checker" --strict "$@" "$d" >/dev/null || status=$?
  [ "$status" -eq 1 ] || fail "$what: --strict exited $status, expected 1"
}

echo "Test 1: a well-formed log passes under --strict, and the count is reported"
make_log "$tmp/good" 2026-03-04-rate-limiting.md "$good"
out=$("$checker" --strict "$tmp/good") || { echo "$out"; fail "well-formed log failed --strict"; }
grep -q 'OK       2026-03-04-rate-limiting.md' <<< "$out" || { echo "$out"; fail "entry not reported OK"; }
grep -q 'Checked 1 session summary; 0 finding(s).' <<< "$out" || { echo "$out"; fail "expected one summary, no findings"; }
echo "PASS"

echo "Test 2: a repository without a session log is skipped, even under --strict"
mkdir -p "$tmp/none"
out=$("$checker" --strict "$tmp/none") || fail "missing docs/sessions/ should not fail"
grep -q 'nothing to verify' <<< "$out" || { echo "$out"; fail "expected a skip note"; }
echo "PASS"

echo "Test 3: README.md and TEMPLATE.md are not entries; the shipped template log passes"
mkdir -p "$tmp/fresh/docs"
cp -R "$repo_root/templates/docs/sessions" "$tmp/fresh/docs/sessions"
out=$("$checker" --strict "$tmp/fresh") || { echo "$out"; fail "a freshly bootstrapped log failed --strict"; }
grep -q 'Checked 0 session summaries' <<< "$out" || { echo "$out"; fail "template files were counted as entries"; }
echo "PASS"

echo "Test 4: the shipped template, copied but not filled in, is caught"
make_log "$tmp/unfilled" 2026-03-05-copied.md "$(cat "$repo_root/templates/docs/sessions/TEMPLATE.md")"
expect_finding "$tmp/unfilled" 'still carries an HTML comment' "unfilled template (comment)"
expect_finding "$tmp/unfilled" 'still carries a <placeholder>' "unfilled template (placeholder)"
expect_finding "$tmp/unfilled" '"Request" section is empty' "unfilled template (empty section)"
expect_finding "$tmp/unfilled" 'does not match the file name' "unfilled template (date)"
echo "PASS"

echo "Test 5: badly named entries are caught"
for bad in notes.md 2026-3-4-short-date.md 2026-03-04-Upper-Case.md 2026-03-04.md "2026-03-04-has space.md"; do
  rm -rf "$tmp/name"
  make_log "$tmp/name" "$bad" "$good"
  expect_finding "$tmp/name" "$bad: not named YYYY-MM-DD-<lowercase-slug>.md" "bad name '$bad'"
done
echo "PASS"

echo "Test 6: missing or mismatched fields are caught"
make_log "$tmp/no-date" 2026-03-04-a.md "${good/- \*\*Date:\*\* 2026-03-04/}"
expect_finding "$tmp/no-date" 'has no **Date:** line' "no date"
make_log "$tmp/wrong-date" 2026-03-09-a.md "$good"
expect_finding "$tmp/wrong-date" '**Date:** "2026-03-04" does not match the file name (2026-03-09)' "wrong date"
make_log "$tmp/no-topics" 2026-03-04-a.md "${good/- \*\*Topics:\*\* rate limiting, api, redis, 429/}"
expect_finding "$tmp/no-topics" 'has no **Topics:** line' "no topics"
make_log "$tmp/empty-topics" 2026-03-04-a.md "${good/rate limiting, api, redis, 429/}"
expect_finding "$tmp/empty-topics" '**Topics:** is empty' "empty topics"
make_log "$tmp/no-title" 2026-03-04-a.md "${good/\# Session: Add rate limiting to the public API/Notes}"
expect_finding "$tmp/no-title" 'does not start with a "# " title' "no title"
echo "PASS"

echo "Test 7: a missing section and an empty section are caught, each by name"
make_log "$tmp/no-decisions" 2026-03-04-a.md "${good/\#\# Decisions/## Choices}"
expect_finding "$tmp/no-decisions" 'has no "Decisions" section' "missing section"
make_log "$tmp/empty-context" 2026-03-04-a.md "${good/The requester had already tried a per-process counter./}"
expect_finding "$tmp/empty-context" '"Context" section is empty' "empty section"
out=$("$checker" "$tmp/empty-context")
if grep -q '"Request" section' <<< "$out"; then echo "$out"; fail "a filled section was reported"; fi
echo "PASS"

echo "Test 8: fields and headings inside a fence or a comment do not count"
fenced='# Session: Fenced

```markdown
- **Date:** 2026-03-04
- **Topics:** hidden
## Request
## Context
## Decisions
## Outcome
```'
make_log "$tmp/fenced" 2026-03-04-a.md "$fenced"
expect_finding "$tmp/fenced" 'has no **Date:** line' "fenced fields"
expect_finding "$tmp/fenced" 'has no "Outcome" section' "fenced headings"
# A fenced block does count as a section's content (a command, a log excerpt).
with_code="${good/Shipped in #12; 14 tests pass./$'```\nmake test\n```'}"
make_log "$tmp/code" 2026-03-04-a.md "$with_code"
"$checker" --strict "$tmp/code" >/dev/null || fail "a section holding only a code block was reported empty"
echo "PASS"

echo "Test 9: the index must list every entry and link nothing that is missing"
make_log "$tmp/unlisted" 2026-03-04-a.md "$good"
printf '%s\n' "$good" > "$tmp/unlisted/docs/sessions/2026-03-04-b.md"
expect_finding "$tmp/unlisted" '2026-03-04-b.md: not linked from docs/sessions/README.md' "unlisted entry"
make_log "$tmp/dangling" 2026-03-04-a.md "$good"
printf '| x | [gone](2026-01-01-gone.md) | t |\n' >> "$tmp/dangling/docs/sessions/README.md"
expect_finding "$tmp/dangling" 'README.md links 2026-01-01-gone.md, which does not exist' "dangling index link"
make_log "$tmp/no-index" 2026-03-04-a.md "$good"
rm "$tmp/no-index/docs/sessions/README.md"
expect_finding "$tmp/no-index" 'docs/sessions/README.md is missing' "missing index"
echo "PASS"

echo "Test 10: CRLF line endings are accepted"
make_log "$tmp/crlf" 2026-03-04-a.md "$good"
sed 's/$/\r/' "$tmp/crlf/docs/sessions/2026-03-04-a.md" > "$tmp/crlf/x" && mv "$tmp/crlf/x" "$tmp/crlf/docs/sessions/2026-03-04-a.md"
"$checker" --strict "$tmp/crlf" >/dev/null || fail "a CRLF summary failed"
echo "PASS"

echo "Test 11: --dir checks a log kept somewhere else"
mkdir -p "$tmp/elsewhere"
make_log "$tmp/elsewhere-src" 2026-03-09-a.md "$good"
mkdir -p "$tmp/elsewhere/notes"
mv "$tmp/elsewhere-src/docs/sessions" "$tmp/elsewhere/notes/log"
expect_finding "$tmp/elsewhere" 'does not match the file name' "--dir" --dir notes/log
echo "PASS"

echo "Test 12: --base flags a diff with no session summary, and only then"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
repo="$tmp/repo"
make_log "$repo" 2026-03-04-a.md "$good"
git -C "$repo" init -q -b main
git -C "$repo" add -A && git -C "$repo" commit -q -m init
base=$(git -C "$repo" rev-parse HEAD)
"$checker" --strict --base "$base" "$repo" >/dev/null || fail "an empty diff was flagged"
echo 'x' > "$repo/app.txt"
git -C "$repo" add -A && git -C "$repo" commit -q -m "feat: app"
expect_finding "$repo" 'adds or updates no session summary' "source change without a summary" --base "$base"
# Touching only the index or the template is not a summary.
echo >> "$repo/docs/sessions/README.md"
git -C "$repo" add -A && git -C "$repo" commit -q -m "docs: index"
expect_finding "$repo" 'adds or updates no session summary' "index-only change" --base "$base"
printf '%s\n' "${good//2026-03-04/2026-03-10}" > "$repo/docs/sessions/2026-03-10-app.md"
printf '| x | [s](2026-03-10-app.md) | t |\n' >> "$repo/docs/sessions/README.md"
git -C "$repo" add -A && git -C "$repo" commit -q -m "docs: session summary"
"$checker" --strict --base "$base" "$repo" >/dev/null || fail "a diff carrying a new summary was flagged"
# A diff that touches only the log needs no further summary.
mid=$(git -C "$repo" rev-parse HEAD~1)
"$checker" --strict --base "$mid" "$repo" >/dev/null || fail "a log-only diff was flagged"
status=0; "$checker" --base no-such-ref "$repo" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "an unknown --base ref exited $status, expected 2"
echo "PASS"

echo "Test 13: usage errors exit 2"
status=0; "$checker" "$tmp/does-not-exist" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "a missing root exited $status, expected 2"
status=0; "$checker" --dir >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "--dir without a value exited $status, expected 2"
status=0; "$checker" a b >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "two roots exited $status, expected 2"
echo "PASS"

echo "Test 14: this repository's own session log passes --strict"
"$checker" --strict "$repo_root" >/dev/null || { "$checker" "$repo_root"; fail "the framework's own session log has findings"; }
echo "PASS"

echo "Test 15: markup named in inline code is neither a comment nor a placeholder"
inline="${good/Token bucket in Redis (requester chose it over a fixed window)./Dropped the \`<!--\` marker; the CLI takes \`<slug>\` and a \`<title>\` tag.}"
make_log "$tmp/inline" 2026-03-04-a.md "$inline"
out=$("$checker" --strict "$tmp/inline") || { echo "$out"; fail "inline-code markup was flagged"; }
echo "PASS"

echo "Test 16: every one of the six sections is required, and fields belong in the header"
for section in Request Context Decisions Discoveries Outcome "Open Questions"; do
  rm -rf "$tmp/six"
  make_log "$tmp/six" 2026-03-04-a.md "${good/\#\# $section/\#\# Other}"
  expect_finding "$tmp/six" "has no \"$section\" section" "missing $section"
done
late='# Session: Late fields

## Request

- **Date:** 2026-03-04
- **Topics:** hidden below the header'
make_log "$tmp/late" 2026-03-04-a.md "$late"
expect_finding "$tmp/late" 'has no **Date:** line above the first section' "fields below the header"
make_log "$tmp/alt" 2026-03-04-a.md "${good/\*\*Date:\*\*/**Date**:}"
"$checker" --strict "$tmp/alt" >/dev/null || fail "the **Date**: spelling was rejected"
echo "PASS"

echo "Test 17: impossible dates, trailing junk, punctuation-only topics, and hollow sections are caught"
make_log "$tmp/month" 2026-13-40-a.md "${good/2026-03-04/2026-13-40}"
expect_finding "$tmp/month" 'not named YYYY-MM-DD-<lowercase-slug>.md' "impossible date"
make_log "$tmp/junk" 2026-03-04-a.md "${good/\*\*Date:\*\* 2026-03-04/**Date:** 2026-03-04xyz}"
expect_finding "$tmp/junk" 'does not match the file name' "date with trailing junk"
make_log "$tmp/comma" 2026-03-04-a.md "${good/rate limiting, api, redis, 429/, ,}"
expect_finding "$tmp/comma" '**Topics:** is empty' "punctuation-only topics"
make_log "$tmp/hollow" 2026-03-04-a.md "${good/Shipped in \#12; 14 tests pass./$'```\n```\n\n---'}"
expect_finding "$tmp/hollow" '"Outcome" section is empty' "hollow section"
echo "PASS"

echo "Test 18: a longer fence may quote a shorter one"
nested="${good/Shipped in \#12; 14 tests pass./$'````markdown\n```bash\nmake test\n```\n````'}"
make_log "$tmp/nested" 2026-03-04-a.md "$nested"
out=$("$checker" --strict "$tmp/nested") || { echo "$out"; fail "a nested fence desynchronised the scan"; }
echo "PASS"

echo "Test 19: index links with ./ or a fragment count; prose and comments do not; strays are reported"
make_log "$tmp/idx" 2026-03-04-a.md "$good"
printf '# Session Log\n\n- [a](./2026-03-04-a.md#request)\n' > "$tmp/idx/docs/sessions/README.md"
"$checker" --strict "$tmp/idx" >/dev/null || fail "a ./ link with a fragment did not count as an index link"
printf '# Session Log\n\nsee (2026-03-04-a.md) later\n<!-- [a](2026-03-04-a.md) -->\n' > "$tmp/idx/docs/sessions/README.md"
expect_finding "$tmp/idx" '2026-03-04-a.md: not linked from docs/sessions/README.md' "prose or commented mention"
make_log "$tmp/stray" 2026-03-04-a.md "$good"
mkdir -p "$tmp/stray/docs/sessions/2026"
printf 'garbage\n' > "$tmp/stray/docs/sessions/2026/2026-03-05-b.md"
printf 'garbage\n' > "$tmp/stray/docs/sessions/2026-03-06-c.MD"
expect_finding "$tmp/stray" 'docs/sessions/2026/2026-03-05-b.md: summaries live directly in docs/sessions/' "summary in a subdirectory"
expect_finding "$tmp/stray" '2026-03-06-c.MD: not named' "upper-case extension"
echo "PASS"

echo "Test 20: --base is satisfied only by an added or changed summary"
repo="$tmp/repo2"
make_log "$repo" 2026-03-04-a.md "$good"
printf '%s\n' "${good//2026-03-04/2026-03-02}" > "$repo/docs/sessions/2026-03-02-old.md"
printf '| x | [s](2026-03-02-old.md) | t |\n' >> "$repo/docs/sessions/README.md"
git -C "$repo" init -q -b main
git -C "$repo" add -A && git -C "$repo" commit -q -m init
base=$(git -C "$repo" rev-parse HEAD)
echo x > "$repo/app.txt"; echo n > "$repo/docs/sessions/notes.txt"
mkdir -p "$repo/docs/sessions/img"; echo p > "$repo/docs/sessions/img/x.png"
git -C "$repo" rm -q docs/sessions/2026-03-02-old.md
grep -v 2026-03-02-old "$repo/docs/sessions/README.md" > "$repo/idx" && mv "$repo/idx" "$repo/docs/sessions/README.md"
git -C "$repo" add -A && git -C "$repo" commit -q -m "feat: app, stray files, a deleted summary"
expect_finding "$repo" 'adds or updates no session summary' "stray files and a deletion" --base "$base"
expect_finding "$repo" 'adds or updates no session summary' "--dir with a leading ./" --base "$base" --dir ./docs/sessions
echo "- later note" >> "$repo/docs/sessions/2026-03-04-a.md"
git -C "$repo" add -A && git -C "$repo" commit -q -m "docs: amend summary"
"$checker" --strict --base "$base" --dir ./docs/sessions "$repo" >/dev/null || fail "an updated summary did not satisfy --base"
echo "PASS"

echo "ALL TESTS PASSED"
