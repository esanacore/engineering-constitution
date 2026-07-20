#!/usr/bin/env bash
set -euo pipefail

# Verify that a project's source-code dependencies point inward, per the
# constitution's Dependency Rule (ARCHITECTURE.md, "The Dependency Rule").
#
# Every other checker in this framework verifies that a *file* exists. This one
# verifies that the code's *structure* matches what the project says its
# structure is: a repository can carry every governance document and still have
# its domain layer importing its web framework.
#
# Two independent halves, with deliberately different severities:
#
#   1. Layer boundaries (a real violation). The project declares its layers in
#      docs/ARCHITECTURE.md under a "Layer Boundaries" heading, as a table of
#      Layer | Path | May Depend On. Every source file under a layer's path is
#      scanned for imports; an import that resolves to a layer absent from that
#      layer's "May Depend On" list is a violation. Warn by default, fail under
#      --strict.
#
#   2. Structural signals (never a violation). Oversized files and crowded
#      directories are reported as review prompts only, and never affect exit
#      status -- not even under --strict. This is deliberate: ARCHITECTURE.md's
#      SRP guardrail says "Do not split merely because a file is long," so
#      failing a build on line count would contradict the constitution it is
#      supposed to enforce. Length is a prompt to look, not a verdict.
#
# This is governance tooling: a silent bug here removes the guarantee it appears
# to provide (see constitution TESTING.md, "Governance Tooling Must Be Tested").
#
# Scope, deliberately:
#   - A project with no "Layer Boundaries" table is not failed. Layer
#     enforcement is opt-in per project because only the project knows its own
#     layering; the structural signals still run.
#   - Imports are matched to layers by path/module *component*, never by
#     substring, so a layer named `db` is not matched by an import of
#     `dbutils`. An import is attributed to a layer when it contains the
#     layer's full declared path, or a component exactly equal to the layer
#     directory's own name.
#   - Imports that resolve to no declared layer are ignored. Third-party and
#     standard-library imports are not the Dependency Rule's concern here.
#   - Relative imports (`../`) are resolved against the importing file's
#     directory before matching, so `from '../domain/user'` is attributed
#     correctly.
#   - Files outside every declared layer path are skipped. Declaring a layer
#     opts its subtree in; nothing else is assumed.
#
# Follows the constitution's CI rollout contract: warn by default, --strict to
# fail (TESTING.md, "CI Enforcement").
#
# Exit status:
#   0  no layer violations (or violations exist but --strict was not given)
#   1  at least one layer violation, under --strict
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_architecture.sh [--strict] [--max-file-lines N] [--max-dir-files N] [project-root]

Description:
  Check that source-code dependencies point inward, per the constitution's
  Dependency Rule, and report structural signals worth a second look.

Arguments:
  project-root       Path to the repository root to check. Default: current directory.

Options:
  --strict           Treat layer violations as failures rather than warnings.
  --max-file-lines N Line count above which a source file is reported as a
                     structural signal. Default: 600.
  --max-dir-files N  Source-file count above which a directory is reported as a
                     structural signal. Default: 30.
  -h, --help         Show this help.

Declaring layers:
  Add a "Layer Boundaries" heading to docs/ARCHITECTURE.md followed by a table.
  List each layer inner-first; "May Depend On" names the layers it is allowed to
  import, or an em dash for none:

    ## Layer Boundaries

    | Layer          | Path               | May Depend On        |
    | -------------- | ------------------ | -------------------- |
    | domain         | src/domain         | --                   |
    | application    | src/application    | domain               |
    | infrastructure | src/infrastructure | domain, application  |

  A layer may always import itself. With no such table, layer enforcement is
  skipped and only structural signals are reported.

Severity:
  Layer violations are real findings: warned by default, failing under --strict.
  Structural signals never affect exit status, by design -- ARCHITECTURE.md's
  SRP guardrail warns against splitting a module merely because it is long.
USAGE
}

strict=false
max_file_lines=600
max_dir_files=30
root=""

require_positive_int() {
  case "$1" in
    ''|*[!0-9]*)
      echo "$2 requires a positive integer, got: $1" >&2
      exit 2
      ;;
  esac
  if [ "$1" -lt 1 ]; then
    echo "$2 requires a positive integer, got: $1" >&2
    exit 2
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --strict)
      strict=true
      shift
      ;;
    --max-file-lines)
      if [ "$#" -lt 2 ]; then
        echo "--max-file-lines requires a value" >&2
        exit 2
      fi
      require_positive_int "$2" "--max-file-lines"
      max_file_lines=$2
      shift 2
      ;;
    --max-file-lines=*)
      require_positive_int "${1#--max-file-lines=}" "--max-file-lines"
      max_file_lines=${1#--max-file-lines=}
      shift
      ;;
    --max-dir-files)
      if [ "$#" -lt 2 ]; then
        echo "--max-dir-files requires a value" >&2
        exit 2
      fi
      require_positive_int "$2" "--max-dir-files"
      max_dir_files=$2
      shift 2
      ;;
    --max-dir-files=*)
      require_positive_int "${1#--max-dir-files=}" "--max-dir-files"
      max_dir_files=${1#--max-dir-files=}
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [ -n "$root" ]; then
        echo "Unexpected extra argument: $1" >&2
        exit 2
      fi
      root=$1
      shift
      ;;
  esac
done

root=${root:-.}

if [ ! -d "$root" ]; then
  echo "Project root not found or not a directory: $root" >&2
  exit 2
fi

root=$(CDPATH= cd -- "$root" && pwd)

# Directories that hold code the project did not write. Scanning them produces
# noise at best and false layer violations at worst.
excluded_dirs='.git node_modules vendor dist build out target coverage .venv venv __pycache__ .mypy_cache .pytest_cache .next .nuxt .gradle Pods DerivedData .constitution-bootstrap constitution'

# Extensions treated as source. Kept to languages the constitution's style
# registry covers (sources/STYLE_GUIDES.md), plus common companions.
source_ext='py|js|jsx|mjs|cjs|ts|tsx|go|java|kt|kts|swift|rs|cs|rb|php|scala|c|cc|cpp|cxx|h|hpp|m|mm|sh|bash'

# Emit every source file under $root, repo-relative, honoring the exclusions.
list_source_files() {
  local prune=""
  local d
  for d in $excluded_dirs; do
    prune="$prune -name $d -o"
  done
  prune=${prune% -o}

  # shellcheck disable=SC2086
  find "$root" \( $prune \) -prune -o -type f -print 2>/dev/null |
    grep -E "\.($source_ext)$" |
    sed "s|^$root/||" |
    sort
}

all_source_files=$(list_source_files || true)

echo "Architecture report for: $root"
echo

# ---------------------------------------------------------------------------
# Layer boundaries.
# ---------------------------------------------------------------------------

architecture_doc="$root/docs/ARCHITECTURE.md"

# Extract the "Layer Boundaries" table as `layer|path|allowed` records. Header
# and separator rows are dropped; a row needs all three cells to count.
parse_layer_table() {
  [ -f "$architecture_doc" ] || return 0

  awk '
    tolower($0) ~ /^#+[[:space:]]*layer boundaries[[:space:]]*$/ { intable = 1; next }
    intable && /^#+[[:space:]]/ { intable = 0 }
    intable && /^[[:space:]]*\|/ {
      line = $0
      sub(/^[[:space:]]*\|/, "", line)
      sub(/\|[[:space:]]*$/, "", line)
      n = split(line, cell, "|")
      if (n < 3) next

      for (i = 1; i <= n; i++) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", cell[i])
        gsub(/`/, "", cell[i])
      }

      if (cell[1] ~ /^-+$/ || cell[2] ~ /^-+$/) next
      if (tolower(cell[1]) == "layer") next
      if (cell[1] == "" || cell[2] == "") next

      print cell[1] "|" cell[2] "|" cell[3]
    }
  ' "$architecture_doc"
}

layer_records=$(parse_layer_table || true)

# Normalize a module/import string to slash-delimited components so Python
# dotted paths and filesystem paths compare the same way.
normalize_ref() {
  printf '%s' "$1" | tr '.' '/' | sed 's|^\./||; s|//*|/|g; s|^/||; s|/$||'
}

# Resolve a relative import against the importing file's directory, so
# `../domain/user` imported from `src/app/x.ts` becomes `src/domain/user`.
resolve_relative() {
  local ref=$1 base=$2 combined

  case "$ref" in
    ./*|../*) ;;
    *) printf '%s' "$ref"; return 0 ;;
  esac

  combined="$base/$ref"

  printf '%s' "$combined" | awk -F/ '{
    n = 0
    for (i = 1; i <= NF; i++) {
      if ($i == "" || $i == ".") continue
      if ($i == "..") { if (n > 0) n--; continue }
      stack[++n] = $i
    }
    out = ""
    for (i = 1; i <= n; i++) out = out (i > 1 ? "/" : "") stack[i]
    print out
  }'
}

# Extract raw import targets from a file, one per line, by language.
extract_imports() {
  local file=$1 abs="$root/$1"

  case "$file" in
    *.py)
      sed -nE 's/^[[:space:]]*from[[:space:]]+([A-Za-z0-9_.]+)[[:space:]]+import.*/\1/p; s/^[[:space:]]*import[[:space:]]+([A-Za-z0-9_.]+).*/\1/p' "$abs"
      ;;
    *.js|*.jsx|*.mjs|*.cjs|*.ts|*.tsx)
      grep -oE "(from|import|require\()[[:space:]]*['\"][^'\"]+['\"]" "$abs" 2>/dev/null |
        sed -E "s/.*['\"]([^'\"]+)['\"].*/\1/"
      ;;
    *.go)
      grep -oE '"[^"]+"' "$abs" 2>/dev/null | tr -d '"'
      ;;
    *.java|*.kt|*.kts|*.scala)
      sed -nE 's/^[[:space:]]*import[[:space:]]+(static[[:space:]]+)?([A-Za-z0-9_.]+).*/\2/p' "$abs"
      ;;
    *.swift)
      sed -nE 's/^[[:space:]]*import[[:space:]]+([A-Za-z0-9_.]+).*/\1/p' "$abs"
      ;;
    *.rs)
      # `a::b::c` -> `a/b/c`; collapse the doubled slash `::` would otherwise
      # leave, so the path reads correctly when echoed back in a finding.
      sed -nE 's/^[[:space:]]*(pub[[:space:]]+)?use[[:space:]]+([A-Za-z0-9_:]+).*/\2/p' "$abs" |
        sed 's|::|/|g'
      ;;
    *.cs)
      sed -nE 's/^[[:space:]]*using[[:space:]]+(static[[:space:]]+)?([A-Za-z0-9_.]+).*/\2/p' "$abs"
      ;;
    *.rb)
      sed -nE "s/^[[:space:]]*require(_relative)?[[:space:]]+['\"]([^'\"]+)['\"].*/\2/p" "$abs"
      ;;
    *.php)
      sed -nE 's/^[[:space:]]*use[[:space:]]+([A-Za-z0-9_\\]+).*/\1/p' "$abs" | tr '\\' '/'
      ;;
    *)
      : # Other extensions contribute structural signals only.
      ;;
  esac
}

layer_violations=0
layers_declared=0

if [ -n "$layer_records" ]; then
  layers_declared=$(printf '%s\n' "$layer_records" | grep -c '' || true)
fi

echo "Layer boundaries:"

if [ "$layers_declared" -eq 0 ]; then
  if [ -f "$architecture_doc" ]; then
    echo "  SKIP     no \"Layer Boundaries\" table in docs/ARCHITECTURE.md; layer enforcement is opt-in"
  else
    echo "  SKIP     docs/ARCHITECTURE.md not found; layer enforcement is opt-in"
  fi
else
  # Attribute a normalized import to a declared layer, or nothing.
  layer_for_ref() {
    local ref=$1 rec name path token

    while IFS='|' read -r name path _; do
      [ -n "$name" ] || continue
      path=$(normalize_ref "$path")
      token=${path##*/}

      case "/$ref/" in
        */"$path"/*) printf '%s' "$name"; return 0 ;;
      esac

      case "/$ref/" in
        */"$token"/*) printf '%s' "$name"; return 0 ;;
      esac
    done <<EOF
$layer_records
EOF

    return 1
  }

  while IFS='|' read -r layer_name layer_path allowed; do
    [ -n "$layer_name" ] || continue

    layer_path=$(normalize_ref "$layer_path")

    if [ ! -d "$root/$layer_path" ]; then
      echo "  WARN     layer '$layer_name' declares path '$layer_path', which does not exist"
      continue
    fi

    # A layer may always import itself; "--", "-", "none", "" mean nothing else.
    allowed_norm=$(printf '%s' "$allowed" |
      tr ',' '\n' |
      sed 's/^[[:space:]]*//; s/[[:space:]]*$//' |
      grep -vE '^(|-+|—+|none|n\/a)$' || true)

    layer_files=$(printf '%s\n' "$all_source_files" |
      grep -E "^$layer_path/" || true)

    [ -n "$layer_files" ] || continue

    while IFS= read -r file; do
      [ -n "$file" ] || continue
      file_dir=${file%/*}

      while IFS= read -r raw_ref; do
        [ -n "$raw_ref" ] || continue

        resolved=$(resolve_relative "$raw_ref" "$file_dir")
        ref=$(normalize_ref "$resolved")
        [ -n "$ref" ] || continue

        target_layer=$(layer_for_ref "$ref" || true)
        [ -n "$target_layer" ] || continue
        [ "$target_layer" != "$layer_name" ] || continue

        if ! printf '%s\n' "$allowed_norm" | grep -qxF "$target_layer"; then
          echo "  VIOLATION $file"
          echo "            '$layer_name' imports '$target_layer' via \"$raw_ref\""
          layer_violations=$((layer_violations + 1))
        fi
      done <<EOF
$(extract_imports "$file" 2>/dev/null || true)
EOF
    done <<EOF
$layer_files
EOF
  done <<EOF
$layer_records
EOF

  if [ "$layer_violations" -eq 0 ]; then
    echo "  OK       $layers_declared layer(s) declared; all dependencies point inward"
  fi
fi

# ---------------------------------------------------------------------------
# Structural signals. Advisory only -- these never change the exit status.
# ---------------------------------------------------------------------------

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

echo
echo "Layer violations: $layer_violations; structural signals: $signal_count."

if [ "$layer_violations" -gt 0 ]; then
  if [ "$strict" = "true" ]; then
    echo "FAIL: dependencies point outward (--strict)."
    exit 1
  fi
  echo "WARN: dependencies point outward (pass --strict to enforce)."
fi

exit 0
