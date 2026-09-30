#!/usr/bin/env bash
set -euo pipefail

# GitHub Actions annotations (a no-op everywhere else); see scripts/lib/ci_annotations.sh.
if [ -f "$(dirname -- "$0")/lib/ci_annotations.sh" ]; then
  # shellcheck source=lib/ci_annotations.sh
  . "$(dirname -- "$0")/lib/ci_annotations.sh"
else
  ci_annotate() { :; }
fi

# Verify that a Markdown file ends its work with a well-formed Next Steps
# procedure, per AI_WORKFLOW.md's "Next Steps Procedure": a "Next Steps"
# heading, then a numbered checklist in which every step names who acts
# (HUMAN, AGENT, AUTOMATED), every HUMAN step says why a person is needed and
# how they know they are done, and the steps waiting on a person are called
# out up front in a "Human action required" line.
#
# The point of the format is that a reader can tell at a glance what is
# waiting on them — hardware, credentials, UI-only settings, approvals — and
# then do it without having read the session. A checker can see the shape of
# that; whether the steps are the right ones stays a review question.
#
# By default the file is docs/AGENT_HANDOFF.md (the procedure's durable copy).
# `--file -` reads standard input, so a pull request body can be piped in.
# HTML comments and fenced code blocks are ignored, so a documented example
# never counts as the real procedure.
#
# This is governance tooling: a silent bug here removes the guarantee it appears
# to provide (see constitution TESTING.md, "Governance Tooling Must Be Tested").
#
# Exit status:
#   0  the procedure is well-formed (or, without --strict, findings were
#      warnings), or the default handoff file does not exist
#   1  at least one finding and --strict was passed
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_next_steps.sh [--strict] [--file <path>|-] [project-root]

Description:
  Check the "Next Steps" section of a Markdown file against AI_WORKFLOW.md's
  "Next Steps Procedure": a numbered checklist ("1. [ ]"), steps numbered in
  order, every step tagged **HUMAN**, **AGENT**, or **AUTOMATED**, every
  HUMAN step carrying "Why a human" and "Done when", and a "Human action
  required" line naming exactly the HUMAN steps. At least one step is
  required. HTML comments and fenced code blocks are ignored.

Arguments:
  project-root   Repository root. Default: current directory.

Options:
  --file <path>  File to check, relative to the root (or absolute), or - for
                 standard input. Default: docs/AGENT_HANDOFF.md, which is
                 skipped with a note when absent.
  --strict       Treat findings as failures instead of warnings.
  -h, --help     Show this help.
USAGE
}

strict=false
root=""
file=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --strict) strict=true; shift ;;
    --file)
      if [ "$#" -lt 2 ]; then echo "--file requires a value" >&2; exit 2; fi
      file=$2; shift 2 ;;
    --file=*) file=${1#--file=}; shift ;;
    --) shift; break ;;
    -?*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      if [ -n "$root" ]; then echo "Unexpected extra argument: $1" >&2; exit 2; fi
      root=$1; shift ;;
  esac
done

root=${root:-.}
if [ ! -d "$root" ]; then
  echo "Project root not found or not a directory: $root" >&2
  exit 2
fi
root=$(CDPATH= cd -- "$root" && pwd)

label=""
input=""
if [ "$file" = "-" ]; then
  label="standard input"
  input=$(cat)
elif [ -n "$file" ]; then
  case "$file" in /*) path=$file ;; *) path="$root/$file" ;; esac
  if [ ! -f "$path" ]; then
    echo "File not found: $file" >&2
    exit 2
  fi
  label=$file
  input=$(cat -- "$path")
else
  label="docs/AGENT_HANDOFF.md"
  if [ ! -f "$root/$label" ]; then
    echo "No $label; nothing to verify."
    exit 0
  fi
  input=$(cat -- "$root/$label")
fi

echo "Next Steps procedure check: $label"
echo

# One awk pass prints "<kind>\t<detail>" findings and a final "STEPS\t<n>\t<h>"
# summary line. POSIX awk only (mawk, gawk, BSD awk).
scan=$(printf '%s\n' "$input" | awk '
  function finish_step() {
    if (cur == 0) return
    if (human[cur]) {
      b = tolower(body)
      if (b !~ /why a human/) print "human\tstep " cur " is HUMAN but does not say why (add **Why a human:**)"
      if (b !~ /done when/)   print "human\tstep " cur " is HUMAN but does not say when it is done (add **Done when:**)"
    }
    body = ""
  }
  {
    sub(/\r$/, "")
    line = $0
    # HTML comments, including multi-line ones.
    if (in_comment) {
      e = index(line, "-->"); if (e == 0) next
      line = substr(line, e + 3); in_comment = 0
    }
    while ((c = index(line, "<!--")) > 0) {
      rest = substr(line, c + 4); e = index(rest, "-->")
      if (e == 0) { line = substr(line, 1, c - 1); in_comment = 1; break }
      line = substr(line, 1, c - 1) substr(rest, e + 3)
    }
    # Fenced code blocks.
    if (line ~ /^[ \t]*(```|~~~)/) { in_fence = !in_fence; next }
    if (in_fence) next

    if (match(line, /^#+[ \t]/)) {
      level = RLENGTH - 1
      title = tolower(line); sub(/^#+[ \t]+/, "", title); sub(/[ \t#]+$/, "", title)
      if (state == "in" && level <= sec_level) { finish_step(); state = "done" }
      if (state == "" && title == "next steps") { state = "in"; sec_level = level; found = 1; next }
    }
    if (state != "in") next

    if (match(line, /^ ? ? ?[0-9]+\.[ \t]/)) {
      finish_step()
      n++
      num = line; sub(/^[ \t]*/, "", num); sub(/\..*/, "", num)
      if (num + 0 != n) print "order\tstep " n " is numbered " num " (number steps 1, 2, 3, ... in order)"
      cur = n
      rest = line; sub(/^[ \t]*[0-9]+\.[ \t]+/, "", rest)
      if (rest !~ /^\[[ xX]\][ \t]/) print "checkbox\tstep " n " has no checkbox (write \"" n ". [ ] ...\")"
      sub(/^\[[ xX]\][ \t]+/, "", rest)
      if (match(rest, /^\*\*(HUMAN|AGENT|AUTOMATED)\*\*/)) {
        human[n] = (substr(rest, 3, 5) == "HUMAN")
        if (human[n]) hcount++
      } else {
        print "actor\tstep " n " does not start with **HUMAN**, **AGENT**, or **AUTOMATED**"
      }
      body = line
      next
    }
    if (cur > 0) { body = body "\n" line; next }
    if (tolower(line) ~ /human action required/) { summary = tolower(line); has_summary = 1 }
  }
  END {
    if (state == "in") finish_step()
    if (!found) { print "section\tno \"Next Steps\" heading"; print "STEPS\t0\t0"; exit }
    if (n == 0) print "empty\tthe Next Steps section has no numbered steps (offer at least one, marked _(suggestion)_ if optional)"

    # The "Human action required" line must name exactly the HUMAN steps.
    listed = ""
    if (has_summary) {
      t = summary; sub(/.*human action required[^a-z0-9]*/, "", t)
      sub(/[.(].*/, "", t)   # "steps 1 and 3 (by 10am)." names 1 and 3 only
      while (match(t, /[0-9]+/)) {
        k = substr(t, RSTART, RLENGTH) + 0; t = substr(t, RSTART + RLENGTH)
        named[k] = 1; listed = listed " " k
        if (!human[k]) print "summary\t\"Human action required\" names step " k ", which is not a HUMAN step"
      }
    }
    for (k = 1; k <= n; k++) {
      if (!human[k] || named[k]) continue
      if (has_summary) print "summary\tstep " k " is HUMAN but the \"Human action required\" line does not name it"
    }
    if (hcount > 0 && !has_summary)
      print "summary\tno \"**Human action required:** steps ...\" line under the heading, though " hcount " step(s) are HUMAN"
    print "STEPS\t" n "\t" hcount + 0
  }
')

findings=0
steps=0
human_steps=0
while IFS=$'\t' read -r kind a b; do
  [ -n "$kind" ] || continue
  if [ "$kind" = "STEPS" ]; then steps=$a; human_steps=$b; continue; fi
  echo "  PROBLEM  $kind: $a"
  findings=$((findings + 1))
done <<< "$scan"

if [ "$findings" -eq 0 ]; then
  echo "  OK       $steps step(s), $human_steps waiting on a person"
  echo
  echo "The Next Steps procedure is well-formed."
  exit 0
fi

echo
echo "$findings finding(s) against AI_WORKFLOW.md's \"Next Steps Procedure\"."
if [ "$strict" = "true" ]; then
  echo "FAIL: malformed Next Steps procedure (--strict)."
  ci_annotate error "check_next_steps.sh: $findings finding(s) in the Next Steps procedure of $label"
  exit 1
fi
echo "WARN: malformed Next Steps procedure (pass --strict to enforce)."
ci_annotate warning "check_next_steps.sh: $findings finding(s) in the Next Steps procedure of $label (pass --strict to enforce)"
exit 0
