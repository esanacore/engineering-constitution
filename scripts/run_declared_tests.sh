#!/usr/bin/env bash
set -euo pipefail

# Run the test command an adopting repository declares in docs/TEST_PLAN.md,
# so "run all automated tests" is enforced in CI instead of depending on an
# agent remembering to run them locally.
#
# This is governance tooling: a silent bug here would let CI report green
# while never actually running anything (see constitution TESTING.md,
# "Governance Tooling Must Be Tested").
#
# The constitution is language/stack-agnostic, so it cannot hardcode a test
# runner. Instead it reads the one line adopters already fill in under
# docs/TEST_PLAN.md's "How to Run Tests" section:
#
#   - Full suite: `<command>`
#
# That command is expected to run the full suite (unit, integration, e2e —
# whatever the project's own tooling aggregates).
#
# Exit status:
#   0  the declared command ran and succeeded, OR nothing is declared yet
#      (default mode only)
#   1  the declared command ran and failed (always enforced, regardless of
#      --strict), OR nothing is declared yet and --strict was passed
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  run_declared_tests.sh [--strict] [project-root]

Description:
  Extract the "Full suite" command from docs/TEST_PLAN.md and run it. A
  declared command is always enforced: if it fails, this script fails, with
  or without --strict. --strict only changes what happens when no command
  has been declared yet (still the `<command>` placeholder, or the file/line
  is missing): default mode warns and exits 0 so adopting the new CI
  template doesn't immediately break every repo that hasn't filled this in
  yet; --strict makes that case a failure too.

Arguments:
  project-root   Path to the repository root to check. Default: current directory.

Options:
  --strict    Fail (exit 1) when no test command has been declared yet.
  -h, --help  Show this help.
USAGE
}

strict=false
root=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --strict)
      strict=true
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
      if [ -n "$root" ]; then
        echo "Unexpected extra argument: $1" >&2
        exit 2
      fi
      root=$1
      shift
      ;;
  esac
done

root=${root:-.}

if [ ! -d "$root" ]; then
  echo "Project root not found or not a directory: $root" >&2
  exit 2
fi

root=$(CDPATH= cd -- "$root" && pwd)
test_plan="$root/docs/TEST_PLAN.md"

not_declared() {
  local reason=$1
  echo "$reason"
  if [ "$strict" = "true" ]; then
    echo "No test command declared and --strict was passed."
    exit 1
  fi
  echo "Not failing (pass --strict to enforce this once docs/TEST_PLAN.md is filled in)."
  exit 0
}

if [ ! -f "$test_plan" ]; then
  not_declared "No docs/TEST_PLAN.md found under: $root"
fi

# Match: - Full suite: `<the command>`
line=$(grep -E '^-[[:space:]]*Full suite:' "$test_plan" | head -n 1 || true)
if [ -z "$line" ]; then
  not_declared "docs/TEST_PLAN.md has no 'Full suite' line under 'How to Run Tests'."
fi

command=$(printf '%s' "$line" | sed -E 's/^-[[:space:]]*Full suite:[[:space:]]*`([^`]*)`.*/\1/')
if [ -z "$command" ] || [ "$command" = "<command>" ] || [ "$command" = "<add here>" ]; then
  not_declared "docs/TEST_PLAN.md's 'Full suite' command is still a placeholder: $line"
fi

echo "Running declared test command: $command"
set +e
(cd "$root" && bash -c "$command")
status=$?
set -e

if [ "$status" -eq 0 ]; then
  echo "Declared test command succeeded."
  exit 0
fi

echo "Declared test command failed (exit $status)." >&2
exit 1
