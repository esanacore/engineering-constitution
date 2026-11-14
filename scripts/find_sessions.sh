#!/usr/bin/env bash
set -euo pipefail

# Search the session log (docs/sessions/) for earlier sessions that touched a
# topic, so an agent starting work can read what was asked, decided, and
# learned last time instead of rediscovering it (AI_WORKFLOW.md, Required
# Workflow steps 9-10; DOCUMENTATION.md, "Session Summaries").
#
# This is a convenience over grep, not a checker: it prints each matching
# summary's path, title, date, and Topics line, strongest match first, so the
# agent can decide which ones to open. A session whose title or Topics line
# carries the term ranks above one that only mentions it in passing.
#
# Exit status:
#   0  search ran (matches or not), or the list was printed
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  find_sessions.sh [--any] [--limit <n>] [--dir <path>] [--root <path>] <term>...
  find_sessions.sh --list [--limit <n>] [--dir <path>] [--root <path>]

Description:
  Print the session summaries that mention every <term> (case-insensitive,
  literal text; a path fragment such as scripts/bootstrap works as well as a
  keyword). Matches in a summary's title or **Topics:** line rank first, then
  newer sessions before older ones. Each result shows the file, its title,
  and its Topics line. Open the files that look relevant and read them.

  Put -- before a term that starts with a dash:
  find_sessions.sh -- --strict

Options:
  --any          Match summaries mentioning any term instead of all of them.
  --list         List every summary, newest first, without searching.
  --limit <n>    Print at most n results. Default: 10 (0 for no limit).
  --dir <path>   Session log directory, relative to the root.
                 Default: docs/sessions.
  --root <path>  Repository root. Default: current directory.
  -h, --help     Show this help.
USAGE
}

any=false
list=false
limit=10
dir="docs/sessions"
root="."
terms=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --any) any=true; shift ;;
    --list) list=true; shift ;;
    --limit|--dir|--root)
      if [ "$#" -lt 2 ]; then echo "$1 requires a value" >&2; exit 2; fi
      case "$1" in
        --limit) limit=$2 ;;
        --dir) dir=$2 ;;
        --root) root=$2 ;;
      esac
      shift 2 ;;
    --limit=*) limit=${1#--limit=}; shift ;;
    --dir=*) dir=${1#--dir=}; shift ;;
    --root=*) root=${1#--root=}; shift ;;
    --) shift; while [ "$#" -gt 0 ]; do terms+=("$1"); shift; done ;;
    -?*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) terms+=("$1"); shift ;;
  esac
done

if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
  echo "--limit must be a non-negative integer: $limit" >&2
  exit 2
fi
if [ "$list" = "false" ] && [ "${#terms[@]}" -eq 0 ]; then
  echo "Give at least one search term, or --list." >&2
  usage >&2
  exit 2
fi
for t in ${terms[@]+"${terms[@]}"}; do
  if [ -z "$t" ] || [[ "$t" == *$'\n'* ]]; then
    echo "Search terms must be non-empty, single-line text." >&2
    exit 2
  fi
done
if [ "$list" = "true" ] && [ "${#terms[@]}" -gt 0 ]; then
  echo "--list takes no search terms." >&2
  exit 2
fi
if [ ! -d "$root" ]; then
  echo "Project root not found or not a directory: $root" >&2
  exit 2
fi
root=$(CDPATH= cd -- "$root" && pwd)
dir=${dir%/}

if [ ! -d "$root/$dir" ]; then
  echo "No $dir/; this repository keeps no session log yet."
  exit 0
fi

files=()
while IFS= read -r f; do
  files+=("$f")
done < <(find "$root/$dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' ! -name 'TEMPLATE.md' | LC_ALL=C sort -r)

if [ "${#files[@]}" -eq 0 ]; then
  echo "No session summaries in $dir/ yet."
  exit 0
fi

# Title ("# ..." first heading) and Topics line of a summary.
title_of() { sed -n 's/^# \{1,\}//p' "$1" | head -n 1 | tr -d '\r'; }
topics_of() {
  grep -i -m 1 -E '^[[:space:]]*([-*][[:space:]]+)?\*\*Topics:\*\*' "$1" 2>/dev/null \
    | sed -E 's/^[[:space:]]*([-*][[:space:]]+)?\*\*[Tt]opics:\*\*[[:space:]]*//' | tr -d '\r' || true
}

# Each candidate becomes "<score> <file>"; files are already newest first, and
# the sort below is stable on score alone, so recency breaks ties.
results=()
for f in "${files[@]}"; do
  if [ "$list" = "true" ]; then
    results+=("0 $f")
    continue
  fi
  head_text=$(printf '%s\n%s\n' "$(title_of "$f")" "$(topics_of "$f")")
  matched=0
  score=0
  for t in "${terms[@]}"; do
    if grep -qiF -- "$t" "$f"; then
      matched=$((matched + 1))
      score=$((score + 1))
      if grep -qiF -- "$t" <<< "$head_text"; then score=$((score + 2)); fi
    fi
  done
  if [ "$any" = "true" ]; then
    [ "$matched" -gt 0 ] || continue
  else
    [ "$matched" -eq "${#terms[@]}" ] || continue
  fi
  results+=("$score $f")
done

if [ "${#results[@]}" -eq 0 ]; then
  echo "No session summaries in $dir/ mention: ${terms[*]}"
  exit 0
fi

total=${#results[@]}
shown=0
while IFS= read -r row; do
  f=${row#* }
  if [ "$limit" -gt 0 ] && [ "$shown" -ge "$limit" ]; then break; fi
  shown=$((shown + 1))
  echo "$dir/$(basename "$f")"
  echo "    $(title_of "$f")"
  topics=$(topics_of "$f")
  [ -n "$topics" ] && echo "    Topics: $topics"
done < <(printf '%s\n' "${results[@]}" | sort -s -k1,1nr)

echo
if [ "$shown" -lt "$total" ]; then
  echo "Showing $shown of $total matching session summaries (--limit 0 for all)."
else
  echo "$total matching session summar$([ "$total" -eq 1 ] && echo y || echo ies)."
fi
exit 0
