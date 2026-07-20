# shellcheck shell=bash
#
# Structural signals for scripts/check_architecture.sh.
#
# Sourced, never executed. Reads the globals `root`, `all_source_files`,
# `max_file_lines`, and `max_dir_files`; sets `signal_count`.
#
# These are advisory and never affect exit status, not even under --strict.
# That is the whole point of keeping them in their own file: ARCHITECTURE.md's
# SRP guardrail says not to split a module merely because it is long, so a
# checker that failed a build on line count would contradict the principle it
# exists to serve. Length is a prompt to look, not a verdict.
#
# Split from check_architecture.sh because it changes for its own reason:
# adding a heuristic or retuning a threshold has nothing to do with layer
# boundaries, and this half deliberately cannot fail a build while that half
# can.

signal_count=0

report_structural_signals() {
  local file lines crowded count dir

  echo
  echo "Structural signals (advisory; never fail the build):"

  signal_count=0

  if [ -n "$all_source_files" ]; then
    while IFS= read -r file; do
      [ -n "$file" ] || continue
      lines=$(wc -l < "$root/$file" 2>/dev/null | tr -d ' ')
      [ -n "$lines" ] || continue
      if [ "$lines" -gt "$max_file_lines" ]; then
        echo "  SIGNAL   $file is $lines lines (over $max_file_lines)"
        signal_count=$((signal_count + 1))
      fi
    done <<EOF
$all_source_files
EOF

    crowded=$(printf '%s\n' "$all_source_files" |
      sed 's|/[^/]*$||' |
      sort |
      uniq -c |
      awk -v limit="$max_dir_files" '$1 > limit {print $1 "\t" $2}' || true)

    if [ -n "$crowded" ]; then
      while IFS=$'\t' read -r count dir; do
        [ -n "$dir" ] || continue
        echo "  SIGNAL   $dir/ holds $count source files (over $max_dir_files)"
        signal_count=$((signal_count + 1))
      done <<EOF
$crowded
EOF
    fi
  fi

  if [ "$signal_count" -eq 0 ]; then
    echo "  OK       no oversized files or crowded directories"
  fi
}
