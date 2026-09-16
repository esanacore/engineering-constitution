#!/usr/bin/env bash
# GitHub Actions annotation helper, sourced by every scripts/check_*.sh.
#
# Checkers print human-readable reports to stdout. When they run inside GitHub
# Actions, the same finding should also surface in the pull request UI (the
# Checks tab and the Files changed view) instead of being buried in a job log.
# GitHub reads "workflow commands" of the form `::warning::message` and
# `::error::message` from stdout for exactly that purpose.
#
# Usage:
#   ci_annotate warning "undocumented dependencies (pass --strict to enforce)"
#   ci_annotate error   "undocumented dependencies (--strict)"
#   ci_annotate notice  "nothing to verify"
#
# Outside GitHub Actions (GITHUB_ACTIONS unset or not "true") this is a no-op,
# so local runs and the negative-case test suites see the plain report only.
# This file contains definitions only; it is sourced, never executed.

ci_annotate() {
  local level=$1
  shift
  if [ "${GITHUB_ACTIONS:-}" != "true" ]; then
    return 0
  fi
  case "$level" in
    warning|error|notice) ;;
    *) level=notice ;;
  esac
  # Newlines would terminate the workflow command early; GitHub expects %0A.
  local message
  message=$(printf '%s' "$*" | sed ':a;N;$!ba;s/\n/%0A/g')
  printf '::%s::%s\n' "$level" "$message"
}
