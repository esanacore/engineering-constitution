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
# A bullet may scope the read, and the meter measures what is instructed,
# not the file. The two qualifiers the framework ships are recognized:
#   "open (`[ ]`/`[~]`) items"                       -> TODO.md: headings,
#       open items (`[ ]`, `[~]`) and their continuation lines; completed
#       (`[x]`) items and theirs are dropped.
#   "the `Unreleased` section and the most recent release" -> CHANGELOG.md:
#       the preamble, the `## Unreleased` section wherever it is, and the
#       first other `## ` section (a `## ` inside a code fence is not one).
# A scoped row shows the instructed figure and, for comparison, the whole
# file's; the report ends with both totals. Any other wording measures the
# whole file: an unrecognized scope falls back to the larger number, never
# to a wrong one.
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
  total. A bullet that scopes its read ("open (`[ ]`/`[~]`) items"; "the
  `Unreleased` section and the most recent release") is measured as
  instructed, with the whole-file figure alongside and both totals at the
  end. Documents over ~8,000 estimated tokens (as instructed) get an
  advisory HEAVY flag.
  A listed file that does not exist fails the run (broken reading order).

Arguments:
  project-root   Repository root to scan. Default: current directory.
  --files ...    Measure exactly the named files instead of scanning
                 instruction files.

Options:
  -h, --help     Show this help.
USAGE
}

# Print the portion of a file that a scoped bullet instructs the agent to
# read. Unknown scopes print the whole file.
scoped_content() {
  local path=$1 scope=$2
  case "$scope" in
    open)
      # List nesting is tracked by indent, so a line belongs to the innermost
      # item whose content column it reaches: an open child under a completed
      # parent is kept, the parent's own continuation lines are not. Each item
      # decides by its own checkbox; a plain bullet follows its parent; prose
      # under a heading and the preamble are kept; fenced code follows the
      # item it sits in.
      awk '
        BEGIN { keep = 1; depth = 0 }
        {
          sub(/\r$/, "")
          t = $0; sub(/^[ \t]*/, "", t)
          if (fence != "") {
            if (t ~ /^(```+|~~~+)[ \t]*$/ && substr(t, 1, 1) == substr(fence, 1, 1) && length(t) >= length(fence)) fence = ""
            if (keep) print
            next
          }
          if (match(t, /^(```+|~~~+)/)) { fence = substr(t, 1, RLENGTH); if (keep) print; next }
          ind = 0
          for (k = 1; k <= length($0); k++) {
            c = substr($0, k, 1)
            if (c == " ") ind++; else if (c == "\t") ind += 4; else break
          }
          if (t ~ /^[-*+] / || t ~ /^[0-9]+\. /) {
            while (depth > 0 && stack_ind[depth] >= ind) depth--
            if (t ~ /^[-*+] \[[xX]\]/) item = 0
            else if (t ~ /^[-*+] \[[ ~]\]/) item = 1
            else item = (depth > 0) ? stack_keep[depth] : 1
            depth++
            stack_ind[depth] = ind; stack_keep[depth] = item
            m = t; sub(/ .*/, "", m); stack_col[depth] = ind + length(m) + 1
            keep = item; if (keep) print
            next
          }
          if ($0 ~ /^#/) { depth = 0; keep = 1; print; next }
          if (t == "") { if (keep) print; next }
          keep = 1
          for (d = depth; d >= 1; d--) if (stack_col[d] <= ind) { keep = stack_keep[d]; break }
          if (keep) print
        }
      ' "$path" ;;
    recent)
      # The preamble, the Unreleased section wherever it is, and the first
      # other `## ` section; a `## ` line inside a code fence is not a heading.
      awk '
        BEGIN { keep = 1 }
        {
          sub(/\r$/, "")
          t = $0; sub(/^[ \t]*/, "", t)
          if (fence != "") {
            if (t ~ /^(```+|~~~+)[ \t]*$/ && substr(t, 1, 1) == substr(fence, 1, 1) && length(t) >= length(fence)) fence = ""
            if (keep) print
            next
          }
          if (match(t, /^(```+|~~~+)/)) { fence = substr(t, 1, RLENGTH); if (keep) print; next }
          if ($0 ~ /^## /) {
            low = tolower($0)
            if (low ~ /unreleased/ && !seen_unrel) { keep = 1; seen_unrel = 1 }
            else if (low !~ /unreleased/ && !seen_rel) { keep = 1; seen_rel = 1 }
            else keep = 0
            if (!keep && seen_unrel && seen_rel) exit
          }
          if (keep) print
        }
      ' "$path" ;;
    *) cat "$path" ;;
  esac
}

scope_label() {
  case "$1" in
    open) printf 'open items' ;;
    recent) printf 'Unreleased + latest release' ;;
    *) printf '%s' "$1" ;;
  esac
}

measure_one() {
  # Prints one report row; returns 1 if the file is missing.
  local root=$1 rel=$2 scope=${3:-}
  local path="$root/$rel"
  if [ ! -f "$path" ]; then
    printf '  MISSING  %s (listed but does not exist)\n' "$rel"
    return 1
  fi
  local whole_b whole_w bytes words tokens label note="" flag=""
  whole_b=$(wc -c < "$path")
  whole_w=$(wc -w < "$path")
  if [ -n "$scope" ]; then
    bytes=$(scoped_content "$path" "$scope" | wc -c)
    words=$(scoped_content "$path" "$scope" | wc -w)
    label="$rel [$(scope_label "$scope")]"
    note="  (of ~$((whole_b / 4)) tok whole file)"
    any_scoped=1
  else
    bytes=$whole_b; words=$whole_w; label=$rel
  fi
  tokens=$((bytes / 4))
  [ "$bytes" -gt "$HEAVY_BYTES" ] && flag="  HEAVY"
  printf '  %-45s %9s B %8s w  ~%7s tok%s%s\n' "$label" "$bytes" "$words" "$tokens" "$flag" "$note"
  total_bytes=$((total_bytes + bytes))
  total_words=$((total_words + words))
  whole_bytes=$((whole_bytes + whole_b))
  whole_words=$((whole_words + whole_w))
  return 0
}

print_total() {
  if [ "${any_scoped:-0}" -eq 1 ]; then
    printf '  %-45s %9s B %8s w  ~%7s tok\n' "TOTAL (as instructed)" "$total_bytes" "$total_words" "$((total_bytes / 4))"
    printf '  %-45s %9s B %8s w  ~%7s tok\n' "TOTAL (whole files)" "$whole_bytes" "$whole_words" "$((whole_bytes / 4))"
  else
    printf '  %-45s %9s B %8s w  ~%7s tok\n' "TOTAL" "$total_bytes" "$total_words" "$((total_bytes / 4))"
  fi
}

# Extract backticked *.md bullet entries (and their scope, if the bullet's
# text carries a recognized qualifier) from the reading sections of an
# instruction file, one "path<TAB>scope" line each. A reading section starts at a heading containing
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
      path = line
      sub(/`.*$/, "", path)
      rest = tolower(substr(line, length(path) + 2))
      scope = ""
      # Exactly the shipped phrasings: anything looser scoped "open items you
      # own" to its checkboxes and measured 0 bytes.
      if (rest ~ /open \(`\[ \]`\/`\[~\]`\) items/) scope = "open"
      else if (rest ~ /`unreleased` section.*(most recent|latest) release/) scope = "recent"
      print path "\t" scope
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
  total_bytes=0; total_words=0; whole_bytes=0; whole_words=0; any_scoped=0
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
    total_bytes=0; total_words=0; whole_bytes=0; whole_words=0; any_scoped=0
    # A file listed twice is measured once; a scope on either listing wins,
    # whichever came first.
    entries=$(printf '%s\n' "$entries" | awk -F'\t' '
      !($1 in scope) { order[++n] = $1; scope[$1] = "" }
      $2 != "" { scope[$1] = $2 }
      END { for (i = 1; i <= n; i++) print order[i] "\t" scope[order[i]] }')
    while IFS=$'\t' read -r rel scope; do
      measure_one "$root" "$rel" "$scope" || missing=$((missing + 1))
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
