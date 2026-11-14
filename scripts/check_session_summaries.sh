#!/usr/bin/env bash
set -euo pipefail

# GitHub Actions annotations (a no-op everywhere else); see scripts/lib/ci_annotations.sh.
if [ -f "$(dirname -- "$0")/lib/ci_annotations.sh" ]; then
  # shellcheck source=lib/ci_annotations.sh
  . "$(dirname -- "$0")/lib/ci_annotations.sh"
else
  ci_annotate() { :; }
fi

# Verify the session log under docs/sessions/, per DOCUMENTATION.md's "Session
# Summaries": one Markdown file per session named YYYY-MM-DD-<slug>.md, each
# carrying the fields and sections a later agent searches by, and every one of
# them listed in the index (docs/sessions/README.md).
#
# The log exists so that what a session knew — the request, the conversational
# context, the decisions and why, the relevant information it turned up —
# outlives the session and can be found again. A summary nobody can find is a
# summary nobody reads, so the mechanical half of the standard is findability:
# a predictable name, a Topics line, the same headings everywhere, and an
# index that lists every entry. Whether a summary is honest and complete
# stays a review question.
#
# With --base <ref> the checker is also a blunt tripwire, in the mould of
# check_doc_freshness.sh: a diff that changes files outside docs/sessions/ but
# adds or updates no session summary is flagged. Trivial changes may skip the
# summary (AI_WORKFLOW.md, "Proportionate Workflow"), so this is a prompt to
# look, not a verdict.
#
# This is governance tooling: a silent bug here removes the guarantee it appears
# to provide (see constitution TESTING.md, "Governance Tooling Must Be Tested").
#
# Exit status:
#   0  the session log is well-formed (or, without --strict, findings were
#      warnings), or there is no docs/sessions/ directory
#   1  at least one finding and --strict was passed
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_session_summaries.sh [--strict] [--dir <path>] [--base <ref> [--head <ref>]] [project-root]

Description:
  Check the session log against DOCUMENTATION.md's "Session Summaries":

    - every entry is named YYYY-MM-DD-<lowercase-slug>.md;
    - it starts with a "# " title and carries "**Date:**" (matching the file
      name) and a non-empty "**Topics:**" line;
    - it has non-empty "Request", "Context", "Decisions", "Discoveries",
      "Outcome", and "Open Questions" sections (write "None." where there
      is nothing to record);
    - no template prompt (an HTML comment or a <placeholder>) is left in it;
    - the index (README.md in the same directory) links every entry, and
      links no entry that does not exist.

  README.md and TEMPLATE.md are not entries. HTML comments and fenced code
  blocks are ignored when looking for fields and sections. A repository
  without the directory is skipped with a note.

Arguments:
  project-root   Repository root. Default: current directory.

Options:
  --dir <path>   Session log directory, relative to the root.
                 Default: docs/sessions.
  --base <ref>   Also flag a diff (<base>...<head>) that changes files outside
                 the session log without adding or updating an entry.
  --head <ref>   Head of that comparison. Default: HEAD.
  --strict       Treat findings as failures instead of warnings.
  -h, --help     Show this help.
USAGE
}

strict=false
root=""
dir="docs/sessions"
base=""
head="HEAD"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --strict) strict=true; shift ;;
    --dir|--base|--head)
      if [ "$#" -lt 2 ]; then echo "$1 requires a value" >&2; exit 2; fi
      case "$1" in
        --dir) dir=$2 ;;
        --base) base=$2 ;;
        --head) head=$2 ;;
      esac
      shift 2 ;;
    --dir=*) dir=${1#--dir=}; shift ;;
    --base=*) base=${1#--base=}; shift ;;
    --head=*) head=${1#--head=}; shift ;;
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
dir=${dir%/}
dir=${dir#./}
if [ -z "$dir" ]; then
  echo "--dir must not be empty" >&2
  exit 2
fi

log="$root/$dir"
if [ ! -d "$log" ]; then
  echo "No $dir/; nothing to verify."
  exit 0
fi

echo "Session log check: $dir"
echo

findings=0
problem() {
  echo "  PROBLEM  $1"
  findings=$((findings + 1))
}

name_pattern='^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])-[a-z0-9]+(-[a-z0-9]+)*\.md$'
index="$log/README.md"

entries=()
while IFS= read -r f; do
  entries+=("$f")
done < <(find "$log" -maxdepth 1 -type f -iname '*.md' ! -name 'README.md' ! -name 'TEMPLATE.md' | LC_ALL=C sort)

# The targets the index links, one per line: "./" and "#fragment" stripped,
# links inside an HTML comment or a fenced block ignored. Used in both directions below.
index_targets=""
if [ -f "$index" ]; then
  index_targets=$(awk '
      { sub(/\r$/, ""); line = $0 }
      in_fence { if (line ~ /^[ \t]*(```|~~~)/) in_fence = 0; next }
      line ~ /^[ \t]*(```|~~~)/ { in_fence = 1; next }
      {
        if (in_comment) { e = index(line, "-->"); if (e == 0) next; line = substr(line, e + 3); in_comment = 0 }
        while ((s = index(line, "<!--")) > 0) {
          rest = substr(line, s + 4); e = index(rest, "-->")
          if (e == 0) { line = substr(line, 1, s - 1); in_comment = 1; break }
          line = substr(line, 1, s - 1) substr(rest, e + 3)
        }
        print line
      }' "$index" \
    | grep -oE '\]\(([.]/)?[^)# ]+\.md(#[^) ]*)?\)' \
    | sed -E 's/^\]\(([.]\/)?//; s/(#[^)]*)?\)$//' | LC_ALL=C sort -u || true)
fi

# One awk pass per entry prints "<detail>" findings. HTML comments and fenced
# code blocks are skipped, so a documented example never counts as a field or
# a section; a comment is itself a finding, since the template's prompts are
# comments and a finished summary has answered them. POSIX awk only.
scan_entry() { # scan_entry <file> <date-from-name>
  awk -v want_date="$2" '
    function norm(t) {
      t = tolower(t)
      gsub(/\*\*|__|`/, "", t)
      sub(/^[ \t#]+/, "", t)
      sub(/[ \t#:]+$/, "", t)
      return t
    }
    function field(line, name,   t, p) {
      # "- **Name:** value" or "**Name:** value"; returns the trimmed value,
      # or "\001" when the line is not that field.
      t = line
      sub(/^[ \t]*[-*][ \t]+/, "", t)
      p = tolower(substr(t, 1, length(name) + 5))
      if (p != "**" tolower(name) ":**" && p != "**" tolower(name) "**:") return "\001"
      t = substr(t, length(name) + 6)
      gsub(/^[ \t]+|[ \t]+$/, "", t)
      return t
    }
    {
      sub(/\r$/, "")
      line = $0
      # A fence closes only on a run of the same character at least as long
      # as the one that opened it, so a longer fence can quote a shorter one.
      if (in_fence) {
        m = line; gsub(/^[ \t]+|[ \t]+$/, "", m)
        if (m ~ /^(```+|~~~+)$/ && substr(m, 1, 1) == fch && length(m) >= flen) { in_fence = 0; next }
        if (line ~ /[A-Za-z0-9]/ && section != "") filled[section] = 1
        next
      }
      if (line ~ /^[ \t]*(```|~~~)/) {
        m = line; sub(/^[ \t]+/, "", m)
        fch = substr(m, 1, 1); flen = 0
        while (substr(m, flen + 1, 1) == fch) flen++
        in_fence = 1; next
      }
      if (in_comment) {
        e = index(line, "-->"); if (e == 0) next
        line = substr(line, e + 3); in_comment = 0
      }
      # Inline code is prose about markup, not markup: `<!--` or `<slug>` in
      # backticks is neither a comment nor a placeholder.
      gsub(/`[^`]*`/, "CODE", line)
      while ((s = index(line, "<!--")) > 0) {
        comment = 1
        rest = substr(line, s + 4); e = index(rest, "-->")
        if (e == 0) { line = substr(line, 1, s - 1); in_comment = 1; break }
        line = substr(line, 1, s - 1) substr(rest, e + 3)
      }
      if (line ~ /<(add[ a-z]*|YYYY-MM-DD|title|topic[s]?|slug)>/) placeholder = 1

      if (line ~ /^#[ \t]/) { if (!seen_any) title = 1; seen_any = 1; section = ""; next }
      # Only a level-two heading opens a section; deeper headings are part
      # of the section they sit in.
      if (line ~ /^##[ \t]/) { seen_any = 1; section = norm(line); present[section] = 1; next }
      if (line ~ /[^ \t]/) {
        if (!seen_any) { seen_any = 1 }
        if (section != "") { if (line ~ /[A-Za-z0-9]/) filled[section] = 1 }
        else {
          # Fields live in the header, above the first section.
          v = field(line, "Date");   if (v != "\001") { has_date = 1; date = v }
          v = field(line, "Topics"); if (v != "\001") { has_topics = 1; topics = v }
        }
      }
    }
    END {
      if (!title) print "does not start with a \"# \" title"
      if (!has_date) print "has no **Date:** line above the first section"
      else if (substr(date, 1, 10) != want_date || (length(date) > 10 && substr(date, 11, 1) !~ /[ \t]/)) print "**Date:** \"" date "\" does not match the file name (" want_date ")"
      if (!has_topics) print "has no **Topics:** line above the first section (the keywords a later agent searches by)"
      else if (topics !~ /[A-Za-z0-9]/) print "**Topics:** is empty (the keywords a later agent searches by)"
      n = split("Request|Context|Decisions|Discoveries|Outcome|Open Questions", need, "|")
      for (i = 1; i <= n; i++) {
        label = need[i]; s = tolower(label)
        if (!(s in present)) print "has no \"" label "\" section (a heading reading exactly \"## " label "\")"
        else if (!(s in filled)) print "\"" label "\" section is empty (write \"None.\" if there is nothing to record)"
      }
      if (comment) print "still carries an HTML comment (a template prompt left unanswered)"
      if (placeholder) print "still carries a <placeholder>"
    }
  ' "$1"
}

checked=0
for f in ${entries[@]+"${entries[@]}"}; do
  name=$(basename "$f")
  checked=$((checked + 1))
  if ! [[ "$name" =~ $name_pattern ]]; then
    problem "$name: not named YYYY-MM-DD-<lowercase-slug>.md"
    continue
  fi
  before=$findings
  while IFS= read -r detail; do
    [ -n "$detail" ] && problem "$name: $detail"
  done < <(scan_entry "$f" "${name:0:10}")
  if [ -f "$index" ] && ! grep -qxF -- "$name" <<< "$index_targets"; then
    problem "$name: not linked from $dir/README.md (the index a later agent reads first)"
  fi
  [ "$findings" -eq "$before" ] && echo "  OK       $name"
done

if [ ! -f "$index" ]; then
  problem "$dir/README.md is missing (the index a later agent reads first)"
else
  # Index links of the entry shape must resolve; other links are the index's own business.
  while IFS= read -r target; do
    [ -n "$target" ] || continue
    [ -f "$log/$target" ] || problem "$dir/README.md links $target, which does not exist"
  done < <(grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}-[^/]*$' <<< "$index_targets" || true)
fi

# The log is one level deep: a summary filed in a subdirectory would be
# skipped by this checker and by find_sessions.sh, so it is reported.
while IFS= read -r stray; do
  [ -n "$stray" ] || continue
  problem "${stray#"$root"/}: summaries live directly in $dir/, not in a subdirectory (it is not checked or searched)"
done < <(find "$log" -mindepth 2 -type f -iname '*.md' | LC_ALL=C sort)

if [ -n "$base" ]; then
  if ! changed=$(git -C "$root" diff --name-only "$base...$head" 2>&1); then
    echo "Could not diff $base...$head: $changed" >&2
    exit 2
  fi
  outside=0
  summarized=0
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      "$dir"/*) ;;
      *) outside=1 ;;
    esac
  done <<< "$changed"
  # Only an added or modified entry counts: not the index, the template, a
  # stray file, or a deleted summary.
  while IFS= read -r path; do
    case "$path" in
      "$dir"/*) rest=${path#"$dir"/}; if [[ "$rest" =~ $name_pattern ]]; then summarized=1; fi ;;
    esac
  done < <(git -C "$root" diff --name-only --diff-filter=AMR "$base...$head" 2>/dev/null)
  if [ "$outside" -eq 1 ] && [ "$summarized" -eq 0 ]; then
    problem "$base...$head changes files but adds or updates no session summary in $dir/ (trivial changes may skip it)"
  fi
fi

echo
echo "Checked $checked session summar$([ "$checked" -eq 1 ] && echo y || echo ies); $findings finding(s)."

if [ "$findings" -gt 0 ]; then
  if [ "$strict" = "true" ]; then
    echo "FAIL: the session log has findings (--strict). See DOCUMENTATION.md, \"Session Summaries\"."
    ci_annotate error "check_session_summaries.sh: $findings finding(s) in $dir (--strict)"
    exit 1
  fi
  echo "WARN: the session log has findings (pass --strict to enforce)."
  ci_annotate warning "check_session_summaries.sh: $findings finding(s) in $dir (pass --strict to enforce)"
fi
exit 0
