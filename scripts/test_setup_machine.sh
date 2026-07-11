#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/setup-machine.sh
#
# Exercises real code paths against local fixtures (fixture git repos,
# fixture installer scripts served over file://) rather than mocking
# functions -- consistent with this repo's testing philosophy (see
# TESTING.md "Governance Tooling Must Be Tested"). The real upstream
# network installs (bun.sh, garrytan/gstack, aaif-goose/*) are
# intentionally never hit by this suite; every source is overridden via
# this script's own env vars pointing at fixtures under the test's temp
# directory.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target_script="$script_dir/setup-machine.sh"

test_dir=$(mktemp -d)
echo "Running tests in: $test_dir"

cleanup() {
  rm -rf "$test_dir"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

# ─── Fixture builders ──────────────────────────────────────────────────

# A fake `bun`/`goose` executable that just prints a version string.
make_fake_binary() {
  local path=$1
  local version_output=$2
  mkdir -p "$(dirname "$path")"
  printf '#!/bin/sh\necho "%s"\n' "$version_output" > "$path"
  chmod +x "$path"
}

# A fixture "gstack" repo: a git repo whose ./setup just marks itself done.
make_gstack_fixture_repo() {
  local repo=$1
  mkdir -p "$repo"
  cat > "$repo/setup" <<'EOF'
#!/usr/bin/env bash
set -e
mkdir -p "$(dirname "$0")/bin"
touch "$(dirname "$0")/bin/gstack-team-init"
echo "fixture gstack setup ran"
EOF
  chmod +x "$repo/setup"
  ( cd "$repo" && git init -q && git config user.email t@example.com \
      && git config user.name "Test" && git add -A \
      && git commit -q -m "fixture gstack" )
}

# A fixture "gstack" repo whose ./setup fails in the specific way a
# too-new Linux distro fails Playwright's browser download, to exercise
# the PLAYWRIGHT_HOST_PLATFORM_OVERRIDE retry path.
make_gstack_fixture_repo_playwright_fail() {
  local repo=$1
  mkdir -p "$repo/browse"
  # Git doesn't track empty directories -- without a file inside, browse/
  # wouldn't survive the fixture commit, and the real script's `cd
  # "$GSTACK_DIR/browse"` (in its Playwright-fallback retry) would fail.
  touch "$repo/browse/.gitkeep"
  cat > "$repo/setup" <<'EOF'
#!/usr/bin/env bash
mkdir -p "$(dirname "$0")/bin"
touch "$(dirname "$0")/bin/gstack-team-init"
echo "Error: ERROR: Playwright does not support chromium on fakedistro99.99-x64"
exit 0
EOF
  chmod +x "$repo/setup"
  ( cd "$repo" && git init -q && git config user.email t@example.com \
      && git config user.name "Test" && git add -A \
      && git commit -q -m "fixture gstack (playwright-fail)" )
}

# A fixture `bunx` that just records its arguments. Must land on PATH
# (setup-machine.sh invokes plain `bunx`, resolved via PATH, not a path
# relative to the cloned gstack repo).
make_fake_bunx() {
  local path=$1
  mkdir -p "$(dirname "$path")"
  cat > "$path" <<'EOF'
#!/usr/bin/env bash
echo "fixture bunx invoked: $* (PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=${PLAYWRIGHT_HOST_PLATFORM_OVERRIDE:-unset})"
exit 0
EOF
  chmod +x "$path"
}

# A fixture goose CLI installer script (mimics download_cli.sh's contract
# loosely: writes a fake `goose` binary, honors CONFIGURE=false quietly).
make_goose_installer_fixture() {
  local script=$1
  local bin_dir=$2
  mkdir -p "$(dirname "$script")"
  cat > "$script" <<EOF
#!/usr/bin/env bash
set -e
mkdir -p "$bin_dir"
printf '#!/bin/sh\necho 9.9.9-fixture\n' > "$bin_dir/goose"
chmod +x "$bin_dir/goose"
echo "fixture goose installer ran (CONFIGURE=\${CONFIGURE:-unset})"
EOF
  chmod +x "$script"
}

# A fixture bun installer script.
make_bun_installer_fixture() {
  local script=$1
  mkdir -p "$(dirname "$script")"
  cat > "$script" <<'EOF'
#!/usr/bin/env bash
echo "fixture bun installer ran"
exit 0
EOF
  chmod +x "$script"
}

# A fixture "goosetown" repo: just needs a `goose` file to satisfy the
# installed-check.
make_goosetown_fixture_repo() {
  local repo=$1
  mkdir -p "$repo"
  printf '#!/bin/sh\necho fixture goosetown\n' > "$repo/goose"
  chmod +x "$repo/goose"
  ( cd "$repo" && git init -q && git config user.email t@example.com \
      && git config user.name "Test" && git add -A \
      && git commit -q -m "fixture goosetown" )
}

# ─── Tests ──────────────────────────────────────────────────────────────

test_help() {
  echo "Testing --help..."
  out=$("$target_script" --help)
  echo "$out" | grep -q "^Usage:" || fail "help text missing Usage: header"
  echo "PASS: --help"
}

test_unknown_option() {
  echo "Testing unknown option..."
  set +e
  out=$("$target_script" --nonsense 2>&1)
  status=$?
  set -e
  [ "$status" -eq 2 ] || fail "expected exit 2 for unknown option, got $status"
  echo "$out" | grep -q "Unknown option" || fail "expected 'Unknown option' message"
  echo "PASS: unknown option -> exit 2"
}

test_all_already_present() {
  echo "Testing all-four-already-present (skip path, no network)..."
  local sandbox="$test_dir/already-present"
  mkdir -p "$sandbox/fake-bin"
  make_fake_binary "$sandbox/fake-bin/bun" "1.9.9-fixture"
  make_fake_binary "$sandbox/fake-bin/goose" "9.9.9-fixture"

  local gstack_dir="$sandbox/gstack"
  mkdir -p "$gstack_dir/bin"

  local goosetown_dir="$sandbox/goosetown"
  mkdir -p "$goosetown_dir"
  printf '#!/bin/sh\n' > "$goosetown_dir/goose"
  chmod +x "$goosetown_dir/goose"

  set +e
  out=$(PATH="$sandbox/fake-bin:$PATH" \
        GSTACK_DIR="$gstack_dir" \
        GOOSETOWN_DIR="$goosetown_dir" \
        "$target_script" 2>&1)
  status=$?
  set -e

  [ "$status" -eq 0 ] || { echo "$out"; fail "expected exit 0 when everything present, got $status"; }
  echo "$out" | grep -q "Bun already installed" || { echo "$out"; fail "expected Bun already-installed message"; }
  echo "$out" | grep -q "gstack already installed" || fail "expected gstack already-installed message"
  echo "$out" | grep -q "goose already installed" || fail "expected goose already-installed message"
  echo "$out" | grep -q "goosetown already cloned" || fail "expected goosetown already-cloned message"
  # No install should have been attempted -- fixture repos were never
  # referenced, so nothing beyond the marker dirs we created should exist.
  echo "PASS: all four already present -> skip path, exit 0"
}

test_skip_flags() {
  echo "Testing --skip-* flags bypass even when nothing is installed..."
  local sandbox="$test_dir/skip-flags"
  mkdir -p "$sandbox/empty-bin"
  local gstack_dir="$sandbox/gstack-missing"
  local goosetown_dir="$sandbox/goosetown-missing"

  set +e
  out=$(PATH="$sandbox/empty-bin:/usr/bin:/bin" \
        GSTACK_DIR="$gstack_dir" \
        GOOSETOWN_DIR="$goosetown_dir" \
        "$target_script" --skip-bun --skip-gstack --skip-goose --skip-goosetown 2>&1)
  status=$?
  set -e

  [ "$status" -eq 0 ] || { echo "$out"; fail "expected exit 0 when everything skipped via flags, got $status"; }
  echo "$out" | grep -q -- "--skip-bun" || fail "expected Bun skip-flag message"
  echo "$out" | grep -q -- "--skip-gstack" || fail "expected gstack skip-flag message"
  echo "$out" | grep -q -- "--skip-goose)" || fail "expected goose skip-flag message"
  echo "$out" | grep -q -- "--skip-goosetown" || fail "expected goosetown skip-flag message"
  [ ! -e "$gstack_dir" ] || fail "gstack dir should not have been created when skipped"
  [ ! -e "$goosetown_dir" ] || fail "goosetown dir should not have been created when skipped"
  echo "PASS: --skip-* flags bypass cleanly"
}

test_gstack_requires_bun() {
  echo "Testing gstack install is refused (not crashed) when Bun is absent..."
  local sandbox="$test_dir/no-bun"
  mkdir -p "$sandbox/empty-bin"
  local gstack_dir="$sandbox/gstack"

  set +e
  out=$(PATH="$sandbox/empty-bin:/usr/bin:/bin" \
        GSTACK_DIR="$gstack_dir" \
        "$target_script" --skip-bun --skip-goose --skip-goosetown 2>&1)
  status=$?
  set -e

  [ "$status" -eq 1 ] || { echo "$out"; fail "expected exit 1 (gstack failed, no Bun), got $status"; }
  echo "$out" | grep -qi "requires Bun" || fail "expected a 'requires Bun' warning"
  [ ! -e "$gstack_dir" ] || fail "gstack dir should not exist when Bun was missing"
  echo "PASS: gstack refuses cleanly without Bun (exit 1, no partial clone)"
}

test_real_install_paths_via_fixtures() {
  echo "Testing the real (not-yet-installed) install paths against local fixtures..."
  local sandbox="$test_dir/fresh-install"
  mkdir -p "$sandbox/fake-bin"
  make_fake_binary "$sandbox/fake-bin/bun" "1.9.9-fixture"

  local gstack_repo="$sandbox/fixtures/gstack-repo"
  make_gstack_fixture_repo "$gstack_repo"

  local goose_installer="$sandbox/fixtures/goose-install.sh"
  local goose_bin_dir="$sandbox/fake-bin"
  make_goose_installer_fixture "$goose_installer" "$goose_bin_dir"

  local goosetown_repo="$sandbox/fixtures/goosetown-repo"
  make_goosetown_fixture_repo "$goosetown_repo"

  local gstack_dir="$sandbox/install/gstack"
  local goosetown_dir="$sandbox/install/goosetown"

  set +e
  out=$(PATH="$sandbox/fake-bin:/usr/bin:/bin" \
        GSTACK_DIR="$gstack_dir" \
        GOOSETOWN_DIR="$goosetown_dir" \
        GSTACK_REPO_URL="$gstack_repo" \
        GOOSE_INSTALLER_URL="file://$goose_installer" \
        GOOSETOWN_REPO_URL="$goosetown_repo" \
        "$target_script" --skip-bun 2>&1)
  status=$?
  set -e

  [ "$status" -eq 0 ] || { echo "$out"; fail "expected exit 0 for a clean fixture install, got $status"; }
  [ -d "$gstack_dir/bin" ] || { echo "$out"; fail "gstack fixture 'install' did not create bin/"; }
  [ -x "$goosetown_dir/goose" ] || { echo "$out"; fail "goosetown fixture clone missing goose wrapper"; }
  echo "$out" | grep -q "fixture gstack setup ran" || fail "gstack fixture ./setup did not run"
  echo "$out" | grep -q "fixture goose installer ran" || fail "goose fixture installer did not run"
  echo "$out" | grep -q "CONFIGURE=false" || fail "goose installer should see CONFIGURE=false"
  echo "PASS: real install code paths work end-to-end against local fixtures"
}

test_playwright_fallback_retry() {
  echo "Testing the Playwright too-new-distro fallback retry..."
  local sandbox="$test_dir/playwright-fallback"
  mkdir -p "$sandbox/fake-bin"
  make_fake_binary "$sandbox/fake-bin/bun" "1.9.9-fixture"
  make_fake_bunx "$sandbox/fake-bin/bunx"

  local gstack_repo="$sandbox/fixtures/gstack-repo-pwfail"
  make_gstack_fixture_repo_playwright_fail "$gstack_repo"

  local gstack_dir="$sandbox/install/gstack"

  set +e
  out=$(PATH="$sandbox/fake-bin:/usr/bin:/bin" \
        GSTACK_DIR="$gstack_dir" \
        GSTACK_REPO_URL="$gstack_repo" \
        PLAYWRIGHT_FALLBACK_PLATFORM="fakefallback99-x64" \
        "$target_script" --skip-bun --skip-goose --skip-goosetown 2>&1)
  status=$?
  set -e

  [ "$status" -eq 0 ] || { echo "$out"; fail "expected exit 0 (setup itself reports success), got $status"; }
  echo "$out" | grep -q "doesn't recognize this distro" || { echo "$out"; fail "expected fallback-detection message"; }
  echo "$out" | grep -q "fixture bunx invoked:.*fakefallback99-x64" || fail "expected fallback retry to invoke bunx with the override platform"
  echo "PASS: Playwright too-new-distro fallback retry fires correctly"
}

test_help
test_unknown_option
test_all_already_present
test_skip_flags
test_gstack_requires_bun
test_real_install_paths_via_fixtures
test_playwright_fallback_retry

echo
echo "All setup-machine.sh tests passed."
