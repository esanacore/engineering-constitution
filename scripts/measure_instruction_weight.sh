#!/usr/bin/env bash
set -euo pipefail

# Measure the token weight of a repository's agent required-reading order.
#
# Motivated by sources/summaries/articles/the-harness-is-the-thing.md:
# instruction weight has a per-session cost, and this framework's answer is
# to measure it rather than trim by taste. The script reports what an agent
# is told to read at session start — per document and in total — so a growth
# trend is visible before it becomes a problem.
#
# This is a meter, not a gate: heavy documents get an advisory flag and
# never affect the exit status. The one hard failure is a reading list that
# names a file which does not exist, because that is a broken reading order.
#
# Token estimates use bytes/4 (the standard English-prose approximation),
# with a word count printed alongside so the estimate can be sanity-checked.
# No tokenizer dependency is required or used.
#
# Usage:
#   measure_instruction_weight.sh [project-root]
#   measure_instruction_weight.sh --files <file> [<file> ...]
#
# Default mode scans the project root's agent instruction files (CLAUDE.md,
# AGENTS.md) and measures every backticked *.md path listed as a bullet
# inside their reading sections (a heading containing "Required Reading" or
# "Before Beginning Work"). Bullets elsewhere in those files (completion
# checklists, work standards) are deliberately not counted.
#
# Exit status:
#   0  measured successfully (advisory flags do not fail)
#   1  at least one listed file does not exist
#   2  usage error

HEAVY_BYTES=32000  # ~8,000 estimated tokens

usage() {
  cat <<'USAGE'
Usage:
  measure_instruction_weight.sh [project-root]
  measure_instruction_weight.sh --files <file> [<file> ...]

Description:
  Report bytes, words, and estimated tokens (bytes/4) for every document in
  the repository's agent required-reading order, per instruction file and in
  total. Documents over ~8,000 estimated tokens get an advisory HEAVY flag.
  A listed file that does not exist fails the run (broken reading order).

Arguments:
  project-root   Repository root to scan. Default: current directory.
  --files ...    Measure exactly the named files instead of scanning
                 instruction files.

Options:
  -h, --help     Show this help.
USAGE
}

measure_one() {
  # Prints one report row; returns 1 if the file is missing.
  local root=$1 rel=$2
  local path="$root/$rel"
  if [ ! -f "$path" ]; then
    printf '  MISSING  %s (listed but does not exist)\n' "$rel"
    return 1
  fi
  local bytes words tokens flag=""
  bytes=$(wc -c < "$path")
  words=$(wc -w < "$path")
  tokens=$((bytes / 4))
  [ "$bytes" -gt "$HEAVY_BYTES" ] && flag="  HEAVY"
  printf '  %-45s %9s B %8s w  ~%7s tok%s\n' "$rel" "$bytes" "$words" "$tokens" "$flag"
  total_bytes=$((total_bytes + bytes))
  total_words=$((total_words + words))
  return 0
}

print_total() {
  printf '  %-45s %9s B %8s w  ~%7s tok\n' "TOTAL" "$total_bytes" "$total_words" "$((total_bytes / 4))"
}

# Extract backticked *.md bullet entries from the reading sections of an
# instruction file. A reading section starts at a heading containing
# "Required Reading" or "Before Beginning Work", or at a prose line of the
# same intent ("Before beginning work, read:" / "Read:"), and ends at the
# next heading or at a "Before completing" prose line — the two shapes the
# framework's own files and templates actually use.
reading_list() {
  local file=$1
  awk '
    {
      low = tolower($0)
    }
    /^#/ {
      in_section = (low ~ /required reading|before beginning work/) ? 1 : 0
      next
    }
    low ~ /^before beginning work/ || low ~ /^read:/ { in_section = 1; next }
    low ~ /^before completing/ { in_section = 0; next }
    in_section && /^- `[^`]+\.md`/ {
      line = $0
      sub(/^- `/, "", line)
      sub(/`.*$/, "", line)
      print line
    }
  ' "$file"
}

files_mode=0
root="."
explicit_files=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --files) files_mode=1; shift; explicit_files=("$@"); break ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) root=$1; shift ;;
  esac
done

if [ "$files_mode" -eq 1 ] && [ "${#explicit_files[@]}" -eq 0 ]; then
  echo "--files requires at least one file" >&2
  usage >&2
  exit 2
fi

if [ ! -d "$root" ]; then
  echo "No such directory: $root" >&2
  exit 2
fi

echo "Instruction weight report for: $root"
echo "(tokens estimated as bytes/4; HEAVY flag above $((HEAVY_BYTES / 4)) estimated tokens)"

missing=0

if [ "$files_mode" -eq 1 ]; then
  echo
  echo "Explicit file list:"
  total_bytes=0; total_words=0
  for f in "${explicit_files[@]}"; do
    measure_one "." "$f" || missing=$((missing + 1))
  done
  print_total
else
  found_any=0
  for instr in CLAUDE.md AGENTS.md; do
    [ -f "$root/$instr" ] || continue
    entries=$(reading_list "$root/$instr")
    [ -n "$entries" ] || continue
    found_any=1
    echo
    echo "$instr reading order:"
    total_bytes=0; total_words=0
    seen=$'\n'
    while IFS= read -r rel; do
      case "$seen" in *$'\n'"$rel"$'\n'*) continue ;; esac
      seen="$seen$rel"$'\n'
      measure_one "$root" "$rel" || missing=$((missing + 1))
    done <<< "$entries"
    print_total
  done
  if [ "$found_any" -eq 0 ]; then
    echo
    echo "No reading sections found in CLAUDE.md/AGENTS.md; nothing to measure."
  fi
fi

echo
if [ "$missing" -gt 0 ]; then
  echo "FAIL: $missing listed file(s) do not exist — the reading order is broken."
  exit 1
fi
echo "Reading order measured; all listed files exist."
exit 0
