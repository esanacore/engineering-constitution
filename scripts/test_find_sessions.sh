#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/find_sessions.sh, the session-log search helper.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
finder="$script_dir/find_sessions.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

# entry <name> <title> <topics> <body>
entry() {
  mkdir -p "$tmp/repo/docs/sessions"
  printf '# Session: %s\n\n- **Date:** %s\n- **Topics:** %s\n\n## Request\n\n%s\n' \
    "$2" "${1:0:10}" "$3" "$4" > "$tmp/repo/docs/sessions/$1"
}
entry 2026-01-05-login-timeouts.md "Login timeouts" "auth, session cookie, timeout" "Users were logged out after five minutes."
entry 2026-02-10-billing-export.md "Billing export" "billing, csv" "Export invoices; the auth middleware was mentioned in passing."
entry 2026-03-15-auth-refactor.md "Auth refactor" "auth, middleware" "Split src/auth/token.py out of the handler."
printf '# Session Log\n' > "$tmp/repo/docs/sessions/README.md"
printf '# Session: <title>\n\n- **Topics:** auth\n' > "$tmp/repo/docs/sessions/TEMPLATE.md"

run() { out=$("$finder" --root "$tmp/repo" "$@"); }
# order: the result file names, in the order printed.
order() { grep -o '^docs/sessions/[^ ]*' <<< "$out" | sed 's#.*/##' | tr '\n' ' '; }

echo "Test 1: a term is matched case-insensitively; title and Topics matches rank first, newest first"
run AUTH
[ "$(order)" = "2026-03-15-auth-refactor.md 2026-01-05-login-timeouts.md 2026-02-10-billing-export.md " ] || { echo "$out"; fail "unexpected order: $(order)"; }
grep -q '    Session: Auth refactor' <<< "$out" || { echo "$out"; fail "title not shown"; }
grep -q '    Topics: auth, middleware' <<< "$out" || { echo "$out"; fail "Topics line not shown"; }
grep -q '^3 matching session summaries' <<< "$out" || { echo "$out"; fail "count not reported"; }
echo "PASS"

echo "Test 2: several terms must all match; --any matches either"
run auth middleware
[ "$(order)" = "2026-03-15-auth-refactor.md 2026-02-10-billing-export.md " ] || { echo "$out"; fail "AND search: $(order)"; }
run --any csv cookie
[ "$(order)" = "2026-02-10-billing-export.md 2026-01-05-login-timeouts.md " ] || { echo "$out"; fail "--any search: $(order)"; }
echo "PASS"

echo "Test 3: a path fragment is literal text, not a pattern"
run src/auth/token.py
[ "$(order)" = "2026-03-15-auth-refactor.md " ] || { echo "$out"; fail "path search: $(order)"; }
run 'a.th'
grep -q 'No session summaries in docs/sessions/ mention: a.th' <<< "$out" || { echo "$out"; fail "a regex metacharacter was treated as a pattern"; }
echo "PASS"

echo "Test 4: README.md and TEMPLATE.md are never results"
run --list
[ "$(order)" = "2026-03-15-auth-refactor.md 2026-02-10-billing-export.md 2026-01-05-login-timeouts.md " ] || { echo "$out"; fail "--list: $(order)"; }
echo "PASS"

echo "Test 5: --limit truncates and says so"
run --limit 1 auth
[ "$(order)" = "2026-03-15-auth-refactor.md " ] || { echo "$out"; fail "--limit: $(order)"; }
grep -q 'Showing 1 of 3 matching session summaries' <<< "$out" || { echo "$out"; fail "truncation not reported"; }
echo "PASS"

echo "Test 6: no log, an empty log, and no match all exit 0 with a note"
mkdir -p "$tmp/bare" "$tmp/empty/docs/sessions"
out=$("$finder" --root "$tmp/bare" x) || fail "no log should exit 0"
grep -q 'keeps no session log yet' <<< "$out" || fail "no-log note missing"
out=$("$finder" --root "$tmp/empty" x) || fail "empty log should exit 0"
grep -q 'No session summaries in docs/sessions/ yet' <<< "$out" || fail "empty-log note missing"
echo "PASS"

echo "Test 7: usage errors exit 2; --help exits 0"
for args in "" "--list auth" "--limit x auth" "--nope" "--root $tmp/missing auth" "--limit"; do
  status=0
  # shellcheck disable=SC2086
  "$finder" $args >/dev/null 2>&1 || status=$?
  [ "$status" -eq 2 ] || fail "'$args' exited $status, expected 2"
done
"$finder" --help | grep -q '^Usage:' || fail "--help printed no Usage: block"
status=0; "$finder" --root "$tmp/repo" "" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "an empty term exited $status, expected 2"
status=0; "$finder" --root "$tmp/repo" $'auth\nzzz' >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "a multi-line term exited $status, expected 2"
out=$("$finder" --root "$tmp/repo" -- --strict) || fail "a dash-leading term after -- should be searched"
grep -q 'mention: --strict' <<< "$out" || { echo "$out"; fail "the dash-leading term was not searched literally"; }
echo "PASS"

echo "ALL TESTS PASSED"
