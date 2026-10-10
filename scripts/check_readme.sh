#!/usr/bin/env bash
set -euo pipefail

# GitHub Actions annotations (a no-op everywhere else); see scripts/lib/ci_annotations.sh.
if [ -f "$(dirname -- "$0")/lib/ci_annotations.sh" ]; then
  # shellcheck source=lib/ci_annotations.sh
  . "$(dirname -- "$0")/lib/ci_annotations.sh"
else
  ci_annotate() { :; }
fi

# Verify the mechanical half of DOCUMENTATION.md's README standard ("Every
# Platform the Project Supports" and "Progressive Disclosure"). A README that
# hands the reader commands is written for the reader's machine, not the
# author's, and a README that collapses its long parts must do so in a way
# the renderer actually honors. Both have failed quietly before: a bash-only
# quick start that assumed Linux, and a <details> block whose content never
# rendered because the blank line after <summary> was missing.
#
# What is checked (tags inside fenced code and HTML comments are ignored):
#   platforms  The file has fenced command blocks (bash, sh, shell, zsh,
#              console) but never states which platforms are supported, or
#              never mentions Windows, or never mentions macOS. Naming a
#              platform as unsupported counts: silence is the problem.
#   details    No blank line after a <summary> line or before </details>
#              (the Markdown inside does not render); a <details> nested in
#              another; a <details> never closed.
#   summary    A <summary> that says "Click to expand" or "More" instead of
#              what is inside.
#   heading    A ##/### heading inside a <details> block: it disappears from
#              the rendered outline.
#   windows    A <details> block whose summary names Windows -- and not Git
#              Bash or WSL, whose syntax is bash syntax -- but whose body uses
#              a POSIX shell command (`export VAR=`, `source ...`,
#              `.../bin/activate`): a PowerShell or cmd block is written for
#              that shell.
#
# Whether each platform's commands are correct stays a review question.
#
# This is governance tooling: a silent bug here removes the guarantee it appears
# to provide (see constitution TESTING.md, "Governance Tooling Must Be Tested").
#
# Exit status:
#   0  no findings (or, without --strict, findings were warnings), or no file
#   1  at least one finding and --strict was passed
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_readme.sh [--strict] [--file <path>] [project-root]

Description:
  Check a README (default: <project-root>/README.md) against the mechanical
  half of DOCUMENTATION.md's README standard: fenced command blocks come
  with a supported-platforms statement and mention Windows and macOS (as
  supported or as unsupported); <details> blocks have the blank lines the
  renderer needs, are not nested or left open, carry a summary that says
  what is inside, and hold no ##/### headings; a PowerShell or cmd Windows
  block uses no POSIX shell commands. The same rule covers docs/SETUP.md and friends: point
  --file at them. A missing default README has nothing to verify.

Arguments:
  project-root   Repository root. Default: current directory.

Options:
  --file <path>  File to check, relative to the root (or absolute).
                 Default: README.md.
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
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
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

explicit=true
[ -n "$file" ] || { file="README.md"; explicit=false; }
case "$file" in /*) path=$file ;; *) path="$root/$file" ;; esac
if [ ! -f "$path" ]; then
  if [ "$explicit" = "true" ]; then
    echo "File not found: $file" >&2
    exit 2
  fi
  echo "No README.md at the repository root; nothing to verify."
  exit 0
fi

echo "README check: $file"
echo

# One awk pass prints "<kind>\t<detail>" findings. POSIX awk only (mawk,
# gawk, BSD awk), matching the rest of scripts/.
scan=$(awk '
  function norm(t) { t = tolower(t); gsub(/[ \t]+/, " ", t); gsub(/^ | $/, "", t); return t }
  # Judge a completed <summary> text (ended at line n).
  function summary_done(s, n) {
    s = norm(s); gsub(/[*_`]/, "", s)
    if (s == "" || s ~ /^(click to )?(expand|more|details|show more|see more|read more|open|here)( ?\.\.\.| ?\.)?$/)
      print "summary\tline " n ": <summary> says \"" s "\" -- name what is inside (\"Windows (PowerShell)\", \"Full project structure\")"
    # A Windows block is held to a Windows shell unless it names Git Bash or
    # WSL, whose syntax is bash syntax.
    if (s ~ /windows/ && s !~ /git bash|wsl|msys|cygwin/) win_block = 1
    summary_line = n
  }
  {
    sub(/\r$/, "")
    line = $0
    lc = tolower(line)

    # The line after <summary> must be blank, whatever it is -- a fence
    # opening there is exactly the case that fails to render.
    if (summary_line && NR == summary_line + 1 && line !~ /^[ \t]*$/)
      print "details\tline " summary_line ": no blank line after <summary> (the Markdown inside will not render)"

    # Mentions count wherever they appear, code included: a "Windows:
    # unsupported" note or a PowerShell block both answer the question.
    if (lc ~ /(^|[^a-z])windows([^a-z]|$)/) has_win = 1
    if (lc ~ /(^|[^a-z])(mac ?os|os x)([^a-z]|$)/) has_mac = 1
    # A platforms statement: the usual phrasings, or one line naming Windows,
    # macOS, and Linux together ("on Linux, macOS, or Windows:").
    if (lc ~ /supported platforms?|platforms? supported|platform support|^[ \t]*(\*\*|_)?platforms?(\*\*|_)?:|supports? (windows|macos|mac os|linux|ubuntu)/) has_stmt = 1
    else if (lc ~ /(^|[^a-z])windows([^a-z]|$)/ && lc ~ /(^|[^a-z])(mac ?os|os x)([^a-z]|$)/ && lc ~ /linux|ubuntu/) has_stmt = 1

    # Fenced code: the fence closes only on the same character, at least as
    # long. Command blocks are what make the platform rule apply.
    t = line; sub(/^[ \t]*/, "", t)
    if (fence == "") {
      if (match(t, /^(```+|~~~+)/)) {
        fence = substr(t, 1, RLENGTH)
        info = norm(substr(t, RLENGTH + 1)); sub(/[ {].*/, "", info)
        if (info ~ /^(bash|sh|shell|zsh|console)$/) cmd_blocks++
        prev = line; next
      }
    } else {
      if (t ~ /^(```+|~~~+)[ \t]*$/ && substr(t, 1, 1) == substr(fence, 1, 1) && length(t) >= length(fence)) fence = ""
      # A Windows block written in a POSIX shell: the one content check that
      # looks inside fences.
      else if (depth > 0 && win_block && !win_reported && (t ~ /^(export|source)[ \t]+[^ \t]/ || t ~ /\/bin\/activate/)) {
        print "windows\tline " NR ": the Windows block opened at line " open_line " uses a POSIX shell command (`export`/`source`); a PowerShell or cmd block uses that shell'"'"'s syntax (name Git Bash in the summary if that is the shell)"
        win_reported = 1
      }
      prev = line; next
    }
    # An indented code block (four spaces or a tab after a blank line) is
    # code too, until the first non-blank line with less indent.
    if (in_indented) {
      if (line ~ /^(    |\t)/ || line ~ /^[ \t]*$/) { prev = line; next }
      in_indented = 0
    }
    if (line ~ /^(    |\t)/ && prev ~ /^[ \t]*$/ && depth == 0) { in_indented = 1; prev = line; next }

    # HTML comments (a commented-out block is not a block).
    if (in_comment) {
      e = index(line, "-->"); if (e == 0) { prev = line; next }
      line = substr(line, e + 3); in_comment = 0
    }
    while ((c = index(line, "<!--")) > 0) {
      rest = substr(line, c + 4); e = index(rest, "-->")
      if (e == 0) { line = substr(line, 1, c - 1); in_comment = 1; break }
      line = substr(line, 1, c - 1) substr(rest, e + 3)
    }
    raw = line
    # Inline code is prose about a tag, not a tag ("use `<details>`").
    gsub(/`[^`]*`/, "", line)
    lc = tolower(line)

    # A <summary> that spans lines: collect until it closes.
    if (in_summary) {
      stext = stext " " raw
      if (lc ~ /<\/summary>/) { sub(/<\/[Ss][Uu][Mm][Mm][Aa][Rr][Yy]>.*/, "", stext); in_summary = 0; summary_done(stext, NR) }
      prev = line; next
    }
    if (lc ~ /<details([ \t>]|$)/) {
      depth++
      if (depth > 1) print "details\tline " NR ": <details> nested inside the one opened at line " open_line " (one level only)"
      else { open_line = NR; win_block = 0; win_reported = 0 }
    }
    if (match(lc, /<summary[^>]*>/)) {
      stext = substr(raw, RSTART + RLENGTH)
      if (lc ~ /<\/summary>/) { sub(/<\/[Ss][Uu][Mm][Mm][Aa][Rr][Yy]>.*/, "", stext); summary_done(stext, NR) }
      else in_summary = 1
      prev = line; next
    }
    if (lc ~ /<\/details>/) {
      if (prev !~ /^[ \t]*$/ && prev !~ /<summary/) print "details\tline " NR ": no blank line before </details> (the Markdown inside will not render)"
      if (depth > 0) depth--
      if (depth == 0) { win_block = 0; win_reported = 0 }
    }
    # ATX headings, up to three spaces of indent. (No interval expressions:
    # older mawk builds do not support them.)
    if (depth > 0 && line ~ /^ ? ? ?#(#|##|###|####|#####)?[ \t]/) {
      h = line; sub(/^ */, "", h); sub(/[ \t]+$/, "", h)
      print "heading\tline " NR ": \"" h "\" is inside the <details> opened at line " open_line "; headings stay outside collapsed blocks"
    }
    prev = line
  }
  END {
    if (in_summary) print "details\tline " open_line ": <summary> is never closed"
    if (depth > 0) print "details\tline " open_line ": <details> is never closed"
    if (cmd_blocks > 0) {
      what = cmd_blocks " fenced command block(s)"
      if (!has_stmt) print "platforms\tthe file hands the reader " what " but never states which platforms are supported (add a \"Supported platforms:\" line to the quick start)"
      if (!has_win) print "platforms\tthe file hands the reader " what " but never mentions Windows (give a Windows block, or name it as unsupported)"
      if (!has_mac) print "platforms\tthe file hands the reader " what " but never mentions macOS (give a macOS block, or name it as unsupported)"
    }
  }
' "$path")

findings=0
while IFS=$'\t' read -r kind detail; do
  [ -n "$kind" ] || continue
  echo "  PROBLEM  $kind: $detail"
  findings=$((findings + 1))
done <<< "$scan"

if [ "$findings" -eq 0 ]; then
  echo "  OK       platforms named, collapsed blocks render, headings visible"
  echo
  echo "$file meets the mechanical README checks."
  exit 0
fi

echo
echo "$findings finding(s) against DOCUMENTATION.md's README standard."
if [ "$strict" = "true" ]; then
  echo "FAIL: README problems (--strict)."
  ci_annotate error "check_readme.sh: $findings README finding(s) in $file"
  exit 1
fi
echo "WARN: README problems (pass --strict to enforce)."
ci_annotate warning "check_readme.sh: $findings README finding(s) in $file (pass --strict to enforce)"
exit 0
