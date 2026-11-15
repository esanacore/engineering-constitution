#!/usr/bin/env bash
set -euo pipefail

# Rebuild the session log's index table (docs/sessions/README.md, "## Index")
# from the summaries themselves, so the index cannot drift from the entries
# and two sessions that finish at the same time do not both hand-edit its top
# row (AI_WORKFLOW.md, "Session Summaries"; ADR-0007).
#
# Only the table under the "## Index" heading is rewritten. Everything else in
# README.md -- the introduction, the prose between the heading and the table,
# anything after the table -- is left as written.
#
# Each row is taken from one YYYY-MM-DD-<slug>.md entry: the date from the
# file name, the title from its first "# " heading (a leading "Session:" is
# dropped), and the topics from its **Topics:** line. Rows are newest first;
# sessions on the same day are in file-name order, so the result is the same
# no matter who builds it. Two branches that each add an entry can still
# conflict in git on this table; resolve it by taking either side and running
# this script again.
#
# Exit status:
#   0  index written, already current, or (--check) current
#   1  --check: the index differs from what the entries produce
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  build_session_index.sh [--check] [--dir <path>] [<root>]

Description:
  Rewrite the table under "## Index" in <root>/docs/sessions/README.md from
  the session summaries in that directory: one row per YYYY-MM-DD-<slug>.md
  file, newest first, with its title and Topics line. Run it after adding or
  editing a summary instead of editing the table by hand.

Options:
  --check        Write nothing; exit 1 if the index is not what the entries
                 produce. For CI.
  --dir <path>   Session log directory, relative to the root.
                 Default: docs/sessions.
  -h, --help     Show this help.

Arguments:
  <root>         Repository root. Default: current directory.
USAGE
}

check=false
dir="docs/sessions"
root=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --check) check=true; shift ;;
    --dir)
      if [ "$#" -lt 2 ]; then echo "--dir requires a value" >&2; exit 2; fi
      dir=$2; shift 2 ;;
    --dir=*) dir=${1#--dir=}; shift ;;
    -?*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      if [ -n "$root" ]; then echo "Only one root may be given." >&2; exit 2; fi
      root=$1; shift ;;
  esac
done
root=${root:-.}

if [ ! -d "$root" ]; then
  echo "Project root not found or not a directory: $root" >&2
  exit 2
fi
root=$(CDPATH= cd -- "$root" && pwd)
dir=${dir%/}
log="$root/$dir"
index="$log/README.md"

if [ ! -d "$log" ]; then
  echo "No $dir/; this repository keeps no session log yet." >&2
  exit 2
fi
if [ ! -f "$index" ]; then
  echo "$dir/README.md is missing; install it from the constitution's templates/docs/sessions/README.md." >&2
  exit 2
fi
if ! grep -qE '^##[[:space:]]+Index[[:space:]]*$' "$index"; then
  echo "$dir/README.md has no \"## Index\" heading to build the table under." >&2
  exit 2
fi

# Text of a table cell: no pipe may end the cell early, no CR, trimmed.
cell() { printf '%s' "$1" | tr -d '\r' | sed -e 's/[[:space:]]\{1,\}/ /g' -e 's/^ //' -e 's/ $//' -e 's/|/\\|/g'; }

title_of() { sed -n 's/^# \{1,\}//p' "$1" | head -n 1 | sed -E 's/^[Ss]ession:[[:space:]]*//'; }
topics_of() {
  grep -i -m 1 -E '^[[:space:]]*([-*][[:space:]]+)?\*\*Topics(:\*\*|\*\*:)' "$1" 2>/dev/null \
    | sed -E 's/^[[:space:]]*([-*][[:space:]]+)?\*\*[Tt][Oo][Pp][Ii][Cc][Ss](:\*\*|\*\*:)[[:space:]]*//' || true
}

# Newest date first, then file name ascending within a day.
rows=$(mktemp)
built=$(mktemp)
trap 'rm -f "$rows" "$built"' EXIT

# List the entries first, and stop if the directory cannot be read: an
# enumeration that failed quietly would rewrite the index as an empty table.
if ! listing=$(find "$log" -maxdepth 1 -type f -name '*.md' -exec basename {} \;); then
  echo "Could not list $dir/; the index was left as it is." >&2
  exit 2
fi
names=$(printf '%s\n' "$listing" \
  | { grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*\.md$' || true; } \
  | LC_ALL=C sort -t- -k1,1nr -k2,2nr -k3,3nr -k4)

count=0
while IFS= read -r name; do
  [ -n "$name" ] || continue
  f="$log/$name"
  title=$(cell "$(title_of "$f")")
  [ -n "$title" ] || title=${name%.md}
  printf '| %s | [%s](%s) | %s |\n' "${name:0:10}" "$title" "$name" "$(cell "$(topics_of "$f")")" >> "$rows"
  count=$((count + 1))
done <<< "$names"

# Copy README.md, replacing the first table after "## Index" (or, when there
# is none yet, inserting one before the next heading or at end of file).
awk -v rows="$rows" '
  function emit(   line) {
    print "| Date | Session | Topics |" eol
    print "| --- | --- | --- |" eol
    while ((getline line < rows) > 0) print line eol
    close(rows)
    done = 1
  }
  {
    # Match on a copy without the CR; print the line as it was, so a CRLF
    # README keeps its line endings outside the table and gets them inside.
    raw = $0; t = $0
    if (sub(/\r$/, "", t)) { if (NR == 1) eol = "\r" }
    if (!done && state == 1) {
      if (t ~ /^[ \t]*\|/) { state = 2; next }             # old table starts
      if (t ~ /^#{1,6}[ \t]/) { emit(); print eol; state = 3 }
    } else if (state == 2) {
      if (t ~ /^[ \t]*\|/) next                            # rest of old table
      emit(); state = 3
    }
    if (state == 0 && t ~ /^##[ \t]+Index[ \t]*$/) state = 1
    if (state == 1) blank = (t ~ /^[ \t]*$/)
    print raw
  }
  END {
    if (!done) { if (state == 1 && !blank) print eol; emit() }
  }
' "$index" > "$built"

if cmp -s "$built" "$index"; then
  echo "$dir/README.md index is current ($count session summar$([ "$count" -eq 1 ] && echo y || echo ies))."
  exit 0
fi

if [ "$check" = "true" ]; then
  echo "$dir/README.md index is out of date; run build_session_index.sh to rebuild it:" >&2
  diff "$index" "$built" >&2 || true
  exit 1
fi

cat "$built" > "$index"
echo "Rebuilt the $dir/README.md index ($count session summar$([ "$count" -eq 1 ] && echo y || echo ies))."
exit 0
