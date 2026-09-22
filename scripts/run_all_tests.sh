#!/usr/bin/env bash
set -euo pipefail

# Run every test suite in scripts/ (scripts/test_*.sh) and report one summary.
#
# This is the framework's own "Full suite" command, declared in
# docs/TEST_PLAN.md and run by .github/workflows/tests.yml on every pull
# request and push. Before it existed, the twenty-odd suites passed only because
# someone remembered to run them by hand before a release — the exact gap
# TESTING.md's "Governance Tooling Must Be Tested" standard warns about.
#
# Exit status:
#   0  every suite passed
#   1  at least one suite failed (each failing suite is named in the summary)
#   2  usage error, or no suites were found (a runner that finds nothing and
#      passes would advertise a guarantee it does not deliver)

usage() {
  cat <<'USAGE'
Usage:
  run_all_tests.sh [--quiet] [--dir <directory>] [-h|--help]

Description:
  Run every executable test suite named test_*.sh in the given directory
  (default: the scripts/ directory this runner lives in) and print a
  PASS/FAIL line per suite plus a final summary.

Options:
  --quiet          Suppress each suite's own output; show only the per-suite
                   PASS/FAIL lines and the summary. A failing suite's output is
                   always replayed so the failure is never hidden.
  --dir <path>     Directory to scan for test_*.sh files. Default: scripts/.
  -h, --help       Show this help.
USAGE
}

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -f "$script_dir/lib/ci_annotations.sh" ]; then
  # shellcheck source=lib/ci_annotations.sh
  . "$script_dir/lib/ci_annotations.sh"
else
  ci_annotate() { :; }
fi

quiet=false
dir="$script_dir"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --quiet)
      quiet=true
      shift
      ;;
    --dir)
      if [ "$#" -lt 2 ]; then
        echo "--dir requires a directory argument" >&2
        exit 2
      fi
      dir=$2
      shift 2
      ;;
    --dir=*)
      dir=${1#--dir=}
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      echo "Unexpected argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ ! -d "$dir" ]; then
  echo "Test directory not found: $dir" >&2
  exit 2
fi
dir=$(CDPATH= cd -- "$dir" && pwd)

suites=()
while IFS= read -r suite; do
  suites+=("$suite")
done < <(find "$dir" -maxdepth 1 -type f -name 'test_*.sh' | sort)

if [ "${#suites[@]}" -eq 0 ]; then
  echo "No test suites (test_*.sh) found in $dir" >&2
  ci_annotate error "run_all_tests.sh found no test suites in $dir"
  exit 2
fi

passed=0
failed=0
failed_names=()
start_all=$(date +%s)

for suite in "${suites[@]}"; do
  name=$(basename "$suite")
  start=$(date +%s)
  if [ "$quiet" = "true" ]; then
    if output=$(bash "$suite" 2>&1); then
      status=0
    else
      status=$?
    fi
  else
    echo "=== $name"
    if bash "$suite"; then
      status=0
    else
      status=$?
    fi
    output=""
  fi
  elapsed=$(( $(date +%s) - start ))
  if [ "$status" -eq 0 ]; then
    echo "PASS  $name (${elapsed}s)"
    passed=$((passed + 1))
  else
    echo "FAIL  $name (exit $status, ${elapsed}s)"
    if [ "$quiet" = "true" ] && [ -n "$output" ]; then
      printf '%s\n' "$output" | sed 's/^/      /'
    fi
    failed=$((failed + 1))
    failed_names+=("$name")
  fi
done

elapsed_all=$(( $(date +%s) - start_all ))
echo
echo "Suites: ${#suites[@]}; passed: $passed; failed: $failed (${elapsed_all}s)"

if [ "$failed" -gt 0 ]; then
  echo "FAIL: ${failed_names[*]}"
  ci_annotate error "run_all_tests.sh: $failed of ${#suites[@]} suites failed: ${failed_names[*]}"
  exit 1
fi

echo "ALL SUITES PASSED"
exit 0
