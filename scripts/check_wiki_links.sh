#!/usr/bin/env bash
set -euo pipefail

# Verify the integrity of a wiki directory's internal links (constitution
# DOCUMENTATION.md "Wiki", ADR-0001). Two kinds of rot are caught:
#
#   dangling links -- a [[WikiLink]] whose target has no matching page file.
#                     This is the most common wiki defect and, once the wiki
#                     is published, an outright broken link for readers.
#   orphan pages   -- a page that no other page links to, so it is reachable
#                     only by knowing its URL. Special pages (Home, _Sidebar,
#                     _Footer, _Header) are never orphans.
#
# Link resolution follows GitHub's wiki (Gollum) rules: [[Target]] and
# [[Display|Target]] both point at the segment that names the page; spaces in
# the target map to hyphens in the filename ([[Getting Started]] -> the file
# Getting-Started.md); an optional #anchor is ignored; external targets
# (containing "://") are skipped. Matching is case-insensitive, as GitHub's
# wiki treats page names.
#
# This is governance tooling: a silent bug here would advertise link integrity
# it does not deliver (see constitution TESTING.md, "Governance Tooling Must Be
# Tested"). It follows the standard rollout contract -- warn by default,
# --strict to fail -- so a newly bootstrapped wiki with a not-yet-written page
# does not instantly turn CI red.
#
# Exit status:
#   0  no wiki directory, or no findings, or (default mode) findings present
#   1  findings present under --strict
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_wiki_links.sh [--strict] [--wiki-dir <dir>] [project-root]

Description:
  Scan the wiki directory (default: wiki/) for dangling [[WikiLinks]] and
  orphan pages. Default mode warns and exits 0; --strict makes findings a
  failure. A repository with no wiki directory is never failed for lacking
  one.

Arguments:
  project-root   Path to the repository root to check. Default: current directory.

Options:
  --wiki-dir <dir>   Directory holding wiki pages, relative to the root.
                     Default: wiki
  --strict           Fail (exit 1) instead of warning when findings exist.
  -h, --help         Show this help.
USAGE
}

strict=false
root=""
wiki_dir="wiki"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --strict) strict=true; shift ;;
    --wiki-dir)
      [ "$#" -ge 2 ] || { echo "--wiki-dir requires a value" >&2; usage >&2; exit 2; }
      wiki_dir=${2%/}; shift 2 ;;
    --)
      shift; break ;;
    -*)
      echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      if [ -n "$root" ]; then echo "Unexpected extra argument: $1" >&2; exit 2; fi
      root=$1; shift ;;
  esac
done

root=${root:-.}
[ -n "$wiki_dir" ] || { echo "--wiki-dir must not be empty." >&2; exit 2; }
[ -d "$root" ] || { echo "Project root not found or not a directory: $root" >&2; exit 2; }
root=$(CDPATH= cd -- "$root" && pwd)
wiki_path="$root/$wiki_dir"

echo "Wiki link report for: $root (wiki: $wiki_dir/)"
echo

if [ ! -d "$wiki_path" ]; then
  echo "  OK  No $wiki_dir/ directory; nothing to check."
  exit 0
fi

# Normalize a page name to its lowercased, hyphenated filename stem, matching
# how GitHub's wiki maps [[A Page]] to A-Page.md. Used for both the page set
# and link targets so the two are compared in the same terms.
normalize() {
  local name=$1
  name=${name%%#*}                 # drop #anchor
  name="${name#"${name%%[![:space:]]*}"}"   # ltrim
  name="${name%"${name##*[![:space:]]}"}"   # rtrim
  name=${name// /-}                # spaces -> hyphens
  printf '%s' "$name" | tr '[:upper:]' '[:lower:]'
}

# Collect existing pages (basename without .md), keyed by normalized stem.
declare -A page_exists=()
pages=()
while IFS= read -r f; do
  [ -n "$f" ] || continue
  base=$(basename "$f" .md)
  pages+=("$base")
  page_exists[$(normalize "$base")]=1
done < <(find "$wiki_path" -maxdepth 1 -type f -name '*.md' | sort)

if [ "${#pages[@]}" -eq 0 ]; then
  echo "  OK  $wiki_dir/ contains no Markdown pages; nothing to check."
  exit 0
fi

# Special pages are navigation/chrome; they are never orphans and are not
# expected to be linked to.
is_special() {
  case "$1" in
    Home|_Sidebar|_Footer|_Header) return 0 ;;
  esac
  return 1
}

dangling=()          # "page.md -> [[raw]]" lines
declare -A referenced=()   # normalized target -> 1, for orphan detection

# Extract [[...]] link bodies from a file, one per line. Code is stripped first
# -- fenced blocks (``` ... ```) and inline code spans (`...`) -- because
# GitHub's wiki does not render a [[...]] inside code as a link, so a page that
# documents the [[Page]] syntax by example must not be read as linking to it.
extract_links() {
  awk '
    /^[[:space:]]*```/ { infence = !infence; next }
    !infence { print }
  ' "$1" \
    | sed -E 's/`[^`]*`//g' \
    | grep -oE '\[\[[^]]+\]\]' 2>/dev/null \
    | sed -E 's/^\[\[//; s/\]\]$//' || true
}

for f in "$wiki_path"/*.md; do
  page=$(basename "$f")
  while IFS= read -r raw; do
    [ -n "$raw" ] || continue
    # Gollum: [[Display|Target]] -- the target is the last pipe-delimited field.
    target=${raw##*|}
    case "$target" in
      *"://"*) continue ;;   # external link, not a page reference
    esac
    norm=$(normalize "$target")
    [ -n "$norm" ] || continue
    referenced[$norm]=1
    if [ -z "${page_exists[$norm]:-}" ]; then
      dangling+=("$page -> [[$raw]]")
    fi
  done < <(extract_links "$f")
done

orphans=()
for base in "${pages[@]}"; do
  is_special "$base" && continue
  norm=$(normalize "$base")
  [ -z "${referenced[$norm]:-}" ] && orphans+=("$base.md")
done

status=0

if [ "${#dangling[@]}" -eq 0 ]; then
  echo "  OK  All [[WikiLinks]] resolve to an existing page."
else
  echo "  WARN  Dangling wiki links (target page does not exist):"
  for d in "${dangling[@]}"; do echo "    - $d"; done
  status=1
fi
echo

if [ "${#orphans[@]}" -eq 0 ]; then
  echo "  OK  No orphan pages (every non-special page is linked at least once)."
else
  echo "  WARN  Orphan pages (no other page links to them):"
  for o in "${orphans[@]}"; do echo "    - $o"; done
  status=1
fi

echo
if [ "$status" -eq 0 ]; then
  echo "Wiki links OK: ${#pages[@]} pages, no dangling links, no orphans."
  exit 0
fi

echo "Findings: ${#dangling[@]} dangling link(s), ${#orphans[@]} orphan page(s)."
if [ "$strict" = "true" ]; then
  echo "Failing because --strict was passed."
  exit 1
fi
echo "Not failing (pass --strict to enforce this). Dangling links are the more serious of the two -- a published wiki renders them as broken links."
exit 0
