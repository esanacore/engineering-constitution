#!/usr/bin/env bash
set -euo pipefail

# Detect drift between dropped book/reference sources and their generated
# summaries. See KNOWLEDGE_SOURCES.md for the full workflow this supports.
#
# This is governance tooling: a silent bug here would let a source go
# unsummarized without anyone noticing (see constitution TESTING.md,
# "Governance Tooling Must Be Tested").
#
# Layout (relative to sources-root, default "sources"):
#   raw/            gitignored — dropped PDF/EPUB/DOCX/MD/TXT files, any depth
#   summaries/       tracked — one .md per raw file, mirrored relative path
#   manifest.tsv      tracked — path<TAB>sha256<TAB>summary<TAB>processed_at
#
# Exit status (scan):
#   0  nothing pending (no NEW/CHANGED/SUMMARY_MISSING entries)
#   1  at least one NEW/CHANGED/SUMMARY_MISSING entry
#   2  usage or input error
#
# Exit status (record):
#   0  manifest row created/updated
#   1  the raw file or its summary does not exist yet
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_source_summaries.sh scan [sources-root]
  check_source_summaries.sh record <relative-path> [sources-root]

Description:
  scan    Report which files under <sources-root>/raw are new, changed since
          last recorded, missing their summary, or fully up to date. Also
          warns about summaries whose raw file was removed.
  record  After writing/updating <sources-root>/summaries/<relative-path
          with .md extension>, mark the raw file as processed by recording
          its current hash in the manifest. Fails if the summary does not
          exist yet.

Arguments:
  sources-root   Path to the sources directory. Default: sources
  relative-path  Path to the raw file, relative to <sources-root>/raw.

Options:
  -h, --help  Show this help.
USAGE
}

extensions=(pdf epub docx md markdown txt)

is_recognized_extension() {
  local ext=${1##*.}
  ext=$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')
  local e
  for e in "${extensions[@]}"; do
    [ "$ext" = "$e" ] && return 0
  done
  return 1
}

sha256_of() {
  sha256sum "$1" | awk '{print $1}'
}

# Print the manifest row (tab-separated) whose first field exactly matches
# the given path, or nothing if there is no match. Comment lines are skipped.
manifest_row() {
  local manifest=$1 path=$2
  [ -f "$manifest" ] || return 0
  awk -F'\t' -v p="$path" '!/^#/ && $1 == p { print; found=1 } END { exit(found ? 0 : 1) }' "$manifest" 2>/dev/null || true
}

# Upsert a manifest row for the given path.
manifest_upsert() {
  local manifest=$1 path=$2 hash=$3 summary=$4 processed_at=$5
  local tmp
  tmp=$(mktemp)
  if [ -f "$manifest" ]; then
    awk -F'\t' -v p="$path" '/^#/ || $1 != p' "$manifest" > "$tmp"
  fi
  printf '%s\t%s\t%s\t%s\n' "$path" "$hash" "$summary" "$processed_at" >> "$tmp"
  mv "$tmp" "$manifest"
}

cmd_scan() {
  local root=$1
  local raw_dir="$root/raw"
  local summaries_dir="$root/summaries"
  local manifest="$root/manifest.tsv"

  echo "Source summary report for: $root"
  echo

  if [ ! -d "$raw_dir" ]; then
    echo "No $raw_dir directory found; nothing to scan."
    return 0
  fi

  local new_count=0 changed_count=0 missing_count=0 orphaned_count=0 ok_count=0
  local files=()
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(find "$raw_dir" -type f -print0 | sort -z)

  for file in "${files[@]}"; do
    is_recognized_extension "$file" || continue
    local relpath=${file#"$raw_dir"/}
    local hash row summary_rel summary_path
    hash=$(sha256_of "$file")
    row=$(manifest_row "$manifest" "$relpath")
    summary_rel="${relpath%.*}.md"
    summary_path="$summaries_dir/$summary_rel"

    if [ -z "$row" ]; then
      echo "  NEW              $relpath"
      new_count=$((new_count + 1))
      continue
    fi

    local manifest_hash
    manifest_hash=$(printf '%s' "$row" | cut -f2)
    if [ "$manifest_hash" != "$hash" ]; then
      echo "  CHANGED          $relpath"
      changed_count=$((changed_count + 1))
      continue
    fi

    if [ ! -f "$summary_path" ]; then
      echo "  SUMMARY_MISSING  $relpath"
      missing_count=$((missing_count + 1))
      continue
    fi

    echo "  OK               $relpath"
    ok_count=$((ok_count + 1))
  done

  if [ -f "$manifest" ]; then
    while IFS=$'\t' read -r m_path _ m_summary _; do
      [ "$m_path" = "" ] && continue
      case "$m_path" in \#*) continue ;; esac
      if [ ! -f "$raw_dir/$m_path" ]; then
        echo "  ORPHANED SUMMARY $m_summary (raw file removed: $m_path)"
        orphaned_count=$((orphaned_count + 1))
      fi
    done < "$manifest"
  fi

  echo
  echo "Pending: $((new_count + changed_count + missing_count)) (new: $new_count, changed: $changed_count, summary-missing: $missing_count); ok: $ok_count; orphaned summaries: $orphaned_count."

  [ $((new_count + changed_count + missing_count)) -gt 0 ] && return 1
  return 0
}

cmd_record() {
  local relpath=$1 root=$2
  local raw_dir="$root/raw"
  local summaries_dir="$root/summaries"
  local manifest="$root/manifest.tsv"
  local raw_path="$raw_dir/$relpath"
  local summary_rel="${relpath%.*}.md"
  local summary_path="$summaries_dir/$summary_rel"

  if [ ! -f "$raw_path" ]; then
    echo "No such raw file: $raw_path" >&2
    return 1
  fi

  if [ ! -f "$summary_path" ]; then
    echo "No summary found at $summary_path — write the summary before recording." >&2
    return 1
  fi

  local hash processed_at
  hash=$(sha256_of "$raw_path")
  processed_at=$(date -u +%Y-%m-%d)
  manifest_upsert "$manifest" "$relpath" "$hash" "$summary_rel" "$processed_at"
  echo "Recorded $relpath -> $summary_rel ($processed_at)"
  return 0
}

if [ "$#" -eq 0 ]; then
  usage >&2
  exit 2
fi

case "$1" in
  -h|--help)
    usage
    exit 0
    ;;
  scan)
    shift
    root=${1:-sources}
    if ! cmd_scan "$root"; then
      exit 1
    fi
    exit 0
    ;;
  record)
    shift
    if [ "$#" -lt 1 ]; then
      echo "record requires a relative path" >&2
      usage >&2
      exit 2
    fi
    relpath=$1
    root=${2:-sources}
    if ! cmd_record "$relpath" "$root"; then
      exit 1
    fi
    exit 0
    ;;
  *)
    echo "Unknown command: $1" >&2
    usage >&2
    exit 2
    ;;
esac
