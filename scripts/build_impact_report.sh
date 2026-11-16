#!/usr/bin/env bash
set -euo pipefail

# Create or refresh an adopter's Constitution Impact Report
# (docs/CONSTITUTION_IMPACT.md): the document that shows, with evidence, what
# adopting the constitution has done for a project (DOCUMENTATION.md,
# "Constitution Impact Report").
#
# The report has two halves. The Adoption Snapshot is measured from the
# repository -- pinned version, adoption date, governance files, CI gates,
# ADRs, session summaries, traced requirements, inventoried dependencies,
# releases, the declared test command, TODO counts -- and this script writes
# it. The rest (what changed, what was caught, what it cost, what is not yet
# adopted) is written by a person or an agent and is never touched here.
#
# Only the lines between the two snapshot markers are rewritten:
#
#   <!-- impact:snapshot:start -->
#   <!-- impact:snapshot:end -->
#
# When the report does not exist yet it is created from the constitution's
# templates/docs/CONSTITUTION_IMPACT.md. A run that would change nothing but
# the "generated on" date leaves the file alone, so rerunning is free.
#
# This is a meter, not a gate: it reports what it finds and never fails
# because a number is low.
#
# Exit status:
#   0  report written, already current, or (--print) snapshot printed
#   2  usage or input error (no root, no template, missing or broken markers)

usage() {
  cat <<'USAGE'
Usage:
  build_impact_report.sh [--print] [--file <path>] [--date <YYYY-MM-DD>]
                         [--constitution-dir <path>] [<root>]

Description:
  Create <root>/docs/CONSTITUTION_IMPACT.md from the constitution's template
  when it is missing, then rewrite its Adoption Snapshot block (the lines
  between the impact:snapshot markers) from facts measured in the
  repository. Hand-written sections are left as they are.

Options:
  --print                    Write nothing; print the snapshot to standard
                             output.
  --file <path>              Report path, relative to the root.
                             Default: docs/CONSTITUTION_IMPACT.md.
  --date <YYYY-MM-DD>        Date to stamp on the snapshot. Default: today.
  --constitution-dir <path>  Where the constitution is checked out, relative
                             to the root. Default: constitution.
  -h, --help                 Show this help.

Arguments:
  <root>                     Repository root. Default: current directory.
USAGE
}

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

print_only=false
file="docs/CONSTITUTION_IMPACT.md"
stamp=""
cdir="constitution"
root=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --print) print_only=true; shift ;;
    --file|--date|--constitution-dir)
      if [ "$#" -lt 2 ]; then echo "$1 requires a value" >&2; exit 2; fi
      case "$1" in
        --file) file=$2 ;;
        --date) stamp=$2 ;;
        --constitution-dir) cdir=$2 ;;
      esac
      shift 2 ;;
    --file=*) file=${1#--file=}; shift ;;
    --date=*) stamp=${1#--date=}; shift ;;
    --constitution-dir=*) cdir=${1#--constitution-dir=}; shift ;;
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
cdir=${cdir%/}
if [ -z "$file" ] || [ -z "$cdir" ]; then
  echo "--file and --constitution-dir need a non-empty value." >&2
  exit 2
fi
# Both stay inside the root: this script writes one file and must not be
# talked into writing somewhere else.
for rel in "$file" "$cdir"; do
  case "/$rel/" in
    //*|*/../*)
      echo "--file and --constitution-dir must be relative paths inside the root: $rel" >&2
      exit 2 ;;
  esac
done

stamp=${stamp:-$(date +%Y-%m-%d)}
if ! printf '%s' "$stamp" | grep -qE '^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$'; then
  echo "--date must look like YYYY-MM-DD: $stamp" >&2
  exit 2
fi

report="$root/$file"
template="$script_dir/../templates/docs/CONSTITUTION_IMPACT.md"
start_marker='<!-- impact:snapshot:start -->'
end_marker='<!-- impact:snapshot:end -->'

# Text of a table cell: one line, trimmed, no pipe that would end it early.
cell() { printf '%s' "$1" | tr -d '\r' | tr '\n' ' ' | sed -e 's/[[:space:]]\{1,\}/ /g' -e 's/^ //' -e 's/ $//' -e 's/|/\\|/g'; }

# Number of files directly in <dir> whose name matches the extended regex.
count_files() {
  local d=$1 pattern=$2
  [ -d "$d" ] || { echo 0; return; }
  # The trailing slash makes find look inside a symlinked directory.
  find "$d/" -maxdepth 1 -type f -exec basename {} \; | { grep -cE "$pattern" || true; }
}

# A Markdown file without its fenced code blocks, so an example heading,
# table row, or checkbox inside a fence is not counted as a real one.
unfenced() {
  awk '/^[ \t]*(```|~~~)/ { fence = !fence; next } !fence' "$1"
}

# --- The measures. Each sets a value for one row of the snapshot. ----------

measure_version() {
  local v="$root/$cdir/VERSION"
  if [ -f "$v" ]; then
    head -n 1 "$v" | tr -d '[:space:]'
  else
    echo "not found"
  fi
}

# Date of the oldest commit that touches the constitution checkout. A shallow
# clone would report its own cut-off instead, so it keeps the date already in
# the report, or says "unknown" rather than a wrong date.
measure_adopted() {
  local first
  if ! git -C "$root" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "unknown (not a git repository)"; return
  fi
  if [ "$(git -C "$root" rev-parse --is-shallow-repository 2>/dev/null || echo false)" = "true" ]; then
    # Keep a date an earlier full-clone run recorded rather than erase it.
    if [ -f "$report" ]; then
      first=$(sed -nE 's/^\| Adopted since \| ([0-9]{4}-[0-9]{2}-[0-9]{2}) \|.*/\1/p' "$report" | head -n 1)
      if [ -n "$first" ]; then echo "$first"; return; fi
    fi
    echo "unknown (shallow clone; rerun on a full clone)"; return
  fi
  first=$(git -C "$root" log --reverse --date=short --format=%ad -- "$cdir" 2>/dev/null | head -n 1 || true)
  if [ -n "$first" ]; then echo "$first"; else echo "unknown (no commit touches \`$cdir/\`)"; fi
}

# "9 of 9 required, 12 of 15 recommended, 1 of 3 product-facing", counted
# from check_compliance.sh's own report so the two can never disagree.
measure_compliance() {
  local checker="$script_dir/check_compliance.sh" out
  [ -f "$checker" ] || { echo "not measured (\`check_compliance.sh\` not found)"; return; }
  out=$(bash "$checker" "$root" 2>/dev/null || true)
  printf '%s\n' "$out" | awk '
    /^Required:/ { tier = "required"; next }
    /^Recommended:/ { tier = "recommended"; next }
    /^Product-facing/ { tier = "product-facing"; next }
    /^[^ ]/ { tier = ""; next }
    tier != "" && /^  [A-Z]+ / { total[tier]++; if ($1 == "OK") ok[tier]++ }
    END {
      n = split("required recommended product-facing", order, " ")
      for (i = 1; i <= n; i++) {
        t = order[i]
        if (total[t] > 0) { printf "%s%d of %d %s", sep, ok[t] + 0, total[t], t; sep = ", " }
      }
      if (sep == "") printf "not measured (no compliance report)"
    }'
}

measure_workflows() {
  local d="$root/.github/workflows" names count
  [ -d "$d" ] || { echo "none"; return; }
  names=$(find "$d/" -maxdepth 1 -type f -exec basename {} \; \
    | { grep -E '^constitution-.+\.ya?ml$' || true; } \
    | sed -E -e 's/^constitution-//' -e 's/\.ya?ml$//' | LC_ALL=C sort)
  [ -n "$names" ] || { echo "none"; return; }
  count=$(printf '%s\n' "$names" | grep -c .)
  printf '%s: %s' "$count" "$(printf '%s\n' "$names" | paste -sd, - | sed 's/,/, /g')"
}

# Rows of a Markdown table whose first cell is an identifier matching <regex>,
# skipping template placeholder rows: a row where some whole cell is still
# `<...>`. A real cell that merely mentions `<form>` does not count as one.
id_rows() {
  local f=$1 regex=$2
  [ -f "$f" ] || return 0
  unfenced "$f" | awk -v re="$regex" -F'|' '
    /^[ \t]*\|/ {
      id = $2; gsub(/^[ \t`*]+|[ \t`*\r]+$/, "", id)
      if (id !~ ("^" re "$")) next
      for (i = 2; i <= NF; i++) {
        c = $i; gsub(/^[ \t]+|[ \t\r]+$/, "", c)
        if (c ~ /^`<[^`]*>`$/) next
      }
      print
    }'
}

measure_requirements() {
  local f="$root/docs/REQUIREMENTS_TRACEABILITY.md" rows total verified
  [ -f "$f" ] || { echo "not present"; return; }
  rows=$(id_rows "$f" '[A-Z][A-Z0-9]*(-[A-Z0-9]+)*-[0-9]+')
  total=$(printf '%s' "$rows" | grep -c . || true)
  # Verified = some cell that, with emphasis and symbols removed, is exactly
  # "Verified", wherever the Status column sits.
  verified=$(printf '%s\n' "$rows" | awk -F'|' '
    {
      for (i = 2; i <= NF; i++) {
        c = $i; gsub(/[^A-Za-z]/, "", c)
        if (c == "Verified") { n++; break }
      }
    }
    END { print n + 0 }')
  echo "$total traced, $verified verified"
}

measure_ots() {
  local f="$root/docs/OTS_SOFTWARE.md"
  [ -f "$f" ] || { echo "not present"; return; }
  id_rows "$f" 'OTS-[0-9]+' | grep -c . || true
}

measure_releases() {
  local f="$root/CHANGELOG.md"
  [ -f "$f" ] || { echo "not present"; return; }
  unfenced "$f" | grep -cE '^##[[:space:]]+\[?v?[0-9]+\.[0-9]+\.[0-9]+' || true
}

measure_tests() {
  local f="$root/docs/TEST_PLAN.md" line cmd
  [ -f "$f" ] || { echo "not present"; return; }
  line=$(grep -E '^-[[:space:]]*Full suite:' "$f" | head -n 1 || true)
  cmd=$(printf '%s' "$line" | sed -nE 's/^-[[:space:]]*Full suite:[[:space:]]*`([^`]*)`.*/\1/p')
  case "$cmd" in
    ""|"<"*">") echo "not declared" ;;   # empty, or the template placeholder
    *) printf '`%s`' "$cmd" ;;
  esac
}

measure_todo() {
  local f="$root/TODO.md" open done_count
  [ -f "$f" ] || { echo "not present"; return; }
  open=$(unfenced "$f" | grep -cE '^[[:space:]]*[-*][[:space:]]+\[[ ~]\]' || true)
  done_count=$(unfenced "$f" | grep -cE '^[[:space:]]*[-*][[:space:]]+\[[xX]\]' || true)
  echo "$open open, $done_count done"
}

count_or_absent() {
  local d=$1 pattern=$2
  if [ -d "$d" ]; then count_files "$d" "$pattern"; else echo "not present"; fi
}

# --- Build the snapshot block (markers excluded). ---------------------------

snapshot=$(mktemp)
built=$(mktemp)
trap 'rm -f "$snapshot" "$built"' EXIT

row() { printf '| %s | %s | %s |\n' "$1" "$(cell "$2")" "$3" >> "$snapshot"; }

{
  printf '_Generated by `build_impact_report.sh` on %s. Do not edit this block by hand; rerun the script._\n\n' "$stamp"
  printf '| Measure | Value | Source |\n| --- | --- | --- |\n'
} > "$snapshot"
row "Constitution version" "$(measure_version)" "\`$cdir/VERSION\`"
row "Adopted since" "$(measure_adopted)" "first commit touching \`$cdir/\`"
row "Governance files" "$(measure_compliance)" "\`check_compliance.sh\`"
row "Constitution CI workflows" "$(measure_workflows)" "\`.github/workflows/constitution-*.yml\`"
row "Declared test command" "$(measure_tests)" "\`docs/TEST_PLAN.md\`"
row "Requirements" "$(measure_requirements)" "\`docs/REQUIREMENTS_TRACEABILITY.md\`"
row "OTS components inventoried" "$(measure_ots)" "\`docs/OTS_SOFTWARE.md\`"
row "Architecture decision records" "$(count_or_absent "$root/docs/adr" '^[0-9]{4}-.+\.md$')" "\`docs/adr/\`"
row "Session summaries" "$(count_or_absent "$root/docs/sessions" '^[0-9]{4}-[0-9]{2}-[0-9]{2}-.+\.md$')" "\`docs/sessions/\`"
row "Releases recorded" "$(measure_releases)" "\`CHANGELOG.md\`"
row "TODO items" "$(measure_todo)" "\`TODO.md\`"

if [ "$print_only" = "true" ]; then
  cat "$snapshot"
  exit 0
fi

# --- Create the report when it is missing, then replace the block. ----------

created=false
if [ ! -f "$report" ]; then
  if [ ! -f "$template" ]; then
    echo "$file does not exist and the template is missing: $template" >&2
    exit 2
  fi
  mkdir -p "$(dirname "$report")"
  # The title's placeholder becomes the repository's directory name.
  name=$(basename "$root" | sed -e 's/[\\&|]/\\&/g')
  sed "1s|<project name>|$name|" "$template" > "$report"
  created=true
fi

starts=$(tr -d '\r' < "$report" | grep -cxF -- "$start_marker" || true)
ends=$(tr -d '\r' < "$report" | grep -cxF -- "$end_marker" || true)
if [ "$starts" != 1 ] || [ "$ends" != 1 ]; then
  echo "$file needs exactly one line \"$start_marker\" and one line \"$end_marker\" (found $starts and $ends)." >&2
  echo "Add both, on lines of their own, under the Adoption Snapshot heading; the snapshot is written between them." >&2
  exit 2
fi
if [ "$(tr -d '\r' < "$report" | grep -nxF -- "$start_marker" | cut -d: -f1)" -gt \
     "$(tr -d '\r' < "$report" | grep -nxF -- "$end_marker" | cut -d: -f1)" ]; then
  echo "$file has the snapshot end marker before the start marker." >&2
  exit 2
fi

# copy_with <snapshot file>: the report with its block replaced.
copy_with() {
  awk -v block="$1" -v s="$start_marker" -v e="$end_marker" '
    {
      t = $0; sub(/\r$/, "", t)
      if (t == s) {
        print
        while ((getline line < block) > 0) print line
        close(block)
        inside = 1; next
      }
      if (t == e) inside = 0
      if (!inside) print
    }' "$report"
}

copy_with "$snapshot" > "$built"

# Current when nothing but the "generated on" line would change.
strip_stamp() { grep -vE '^_Generated by `build_impact_report\.sh` on ' "$1" || true; }
if [ "$created" = "false" ] && [ "$(strip_stamp "$built")" = "$(strip_stamp "$report")" ]; then
  echo "$file snapshot is current."
  exit 0
fi

cat "$built" > "$report"
if [ "$created" = "true" ]; then
  echo "Created $file from the template and wrote its snapshot."
  echo "The Summary, What Changed, Catches, What It Cost, and Not Yet Adopted sections are still template text: fill them in, citing evidence for every claim."
else
  echo "Refreshed the snapshot in $file."
fi
exit 0
