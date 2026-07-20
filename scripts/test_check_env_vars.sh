#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
check_script="$script_dir/check_env_vars.sh"

test_dir=$(mktemp -d)
echo "Running tests in: $test_dir"

cleanup() {
  rm -rf "$test_dir"
}
trap cleanup EXIT

pass_count=0
fail_count=0

run_test() {
  local name=$1
  local expected_exit=$2
  local dir=$3
  local args=${4:-}

  echo "Test: $name"
  set +e
  output=$(bash "$check_script" $args "$dir" 2>&1)
  local actual_exit=$?
  set -e

  if [ "$actual_exit" -eq "$expected_exit" ]; then
    echo "  PASS (exit $actual_exit)"
    pass_count=$((pass_count + 1))
  else
    echo "  FAIL (expected $expected_exit, got $actual_exit)"
    echo "  Output:"
    echo "$output" | sed 's/^/    /'
    fail_count=$((fail_count + 1))
  fi
}

# ---------------------------------------------------------------------------

d="$test_dir/no-vars"
mkdir -p "$d/docs"
run_test "No manifests" 0 "$d"

d="$test_dir/missing-contract-warn"
mkdir -p "$d"
echo "API_KEY=123" > "$d/.env.example"
run_test "Missing contract (warn default)" 0 "$d"

d="$test_dir/missing-contract-strict"
mkdir -p "$d"
echo "API_KEY=123" > "$d/.env.example"
run_test "Missing contract (--strict)" 1 "$d" "--strict"

d="$test_dir/all-documented"
mkdir -p "$d/docs"
cat <<'EOF' > "$d/.env.example"
# A comment
API_KEY=123
  PORT = 8080 
EOF
cat <<'EOF' > "$d/docker-compose.yml"
services:
  app:
    environment:
      - DATABASE_URL=postgres://
      - DEBUG
      REDIS_URL: redis://
EOF
cat <<'EOF' > "$d/docs/ENV_VARS.md"
| Variable | Description |
| :--- | :--- |
| `API_KEY` | foo |
| PORT | bar |
| DATABASE_URL | baz |
| DEBUG | |
| `REDIS_URL` | |
EOF
run_test "All documented" 0 "$d" "--strict"

d="$test_dir/missing-var-warn"
mkdir -p "$d/docs"
echo "API_KEY=123" > "$d/.env.example"
echo "SECRET=456" >> "$d/.env.example"
cat <<'EOF' > "$d/docs/ENV_VARS.md"
| Variable |
| --- |
| API_KEY |
EOF
run_test "Missing var (warn default)" 0 "$d"

d="$test_dir/missing-var-strict"
mkdir -p "$d/docs"
echo "API_KEY=123" > "$d/.env.example"
echo "SECRET=456" >> "$d/.env.example"
cat <<'EOF' > "$d/docs/ENV_VARS.md"
| Variable |
| --- |
| API_KEY |
EOF
run_test "Missing var (--strict)" 1 "$d" "--strict"

echo
if [ "$fail_count" -eq 0 ]; then
  echo "ALL $pass_count TESTS PASSED"
  exit 0
else
  echo "$fail_count TESTS FAILED"
  exit 1
fi
