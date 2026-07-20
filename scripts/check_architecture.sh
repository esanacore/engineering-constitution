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
#      Layer | Path | May Depend On. Two things are checked, and both warn by
#      default and fail under --strict:
#
#      a. The declared graph must be acyclic. "Dependencies point inward" is not
#         satisfiable if two layers may each depend on the other, and no
#         per-import check can see this: each edge of a cycle is individually
#         legal per its own allow-list. Only a graph pass finds it.
#
#         Checking the *declared* graph rather than the observed imports is
#         sufficient, not a shortcut: every actual import is either permitted --
#         and therefore an edge already in this graph -- or it is a violation,
#         reported by (b). So an acyclic declaration admits no cycle among the
#         imports that pass. It is also stricter in a useful way, catching an
#         unsound architecture before any code exercises it.
#
#      b. Every import from a declared layer must resolve to a layer that layer
#         is allowed to depend on.
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
#     `dbutils`. Attribution runs in two passes over every candidate form of
#     the reference: a layer's full declared path is matched across all layers
#     first, and only then the layer directory's own name. A full-path match is
#     strictly better evidence, so it must not lose to another layer's
#     directory name.
#   - Language module roots are read so an import can be expressed in the same
#     terms as a layer path: the `module` prefix from go.mod, `paths` aliases
#     and `baseUrl` from tsconfig.json/jsconfig.json, and a top-level src/ for
#     src-layout projects. Without them a Go import carries its module prefix
#     and a TypeScript alias names no directory at all.
#   - Layers whose directories share a name (src/a/core and src/b/core) cannot
#     be told apart from a bare module path. That is reported, and such names
#     are skipped in the second pass rather than guessed at: attributing a
#     dependency to the wrong layer is how a real violation disappears.
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

  The declared graph must be acyclic: if two layers may each depend on the
  other, dependencies cannot point inward, and every edge of that cycle still
  looks legal to a per-import check. A "May Depend On" name matching no declared
  layer is reported too, since a typo there permits nothing and silently makes a
  layer stricter than its author intended.

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

# Concerns that change for their own reasons live in scripts/lib/ and are
# sourced here. They contain definitions only -- nothing runs at source time --
# so they load through the absolute "$script_dir" before any of them is called,
# and the project being checked can never affect which files load.
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
lib_dir="$script_dir/lib"

for lib in architecture_languages.sh architecture_layers.sh architecture_signals.sh; do
  if [ ! -f "$lib_dir/$lib" ]; then
    echo "Missing required library: $lib_dir/$lib" >&2
    echo "The constitution checkout looks incomplete; re-clone or update the submodule." >&2
    exit 2
  fi
  # shellcheck source=/dev/null
  . "$lib_dir/$lib"
done

detect_module_roots

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

layer_records=$(parse_layer_table || true)
compute_ambiguous_tokens

layer_violations=0
cycle_violations=0
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
  # Report the module roots in play. Attribution depends on them, so a wrong or
  # missing root should be visible rather than inferred from odd results.
  if [ -n "$go_module_prefix" ]; then
    echo "  INFO     go.mod module prefix: $go_module_prefix"
  fi
  if [ -n "$ts_aliases" ]; then
    echo "  INFO     tsconfig path aliases: $(printf '%s' "$ts_aliases" | grep -c '' ) declared"
  fi

  # Layers sharing a directory name cannot be told apart from a bare module
  # path. Say so: the alternative is guessing, and silently attributing a
  # dependency to the wrong layer is how a real violation disappears.
  if [ -n "$ambiguous_tokens" ]; then
    while IFS= read -r token; do
      [ -n "$token" ] || continue
      sharing=$(printf '%s\n' "$layer_records" | awk -F'|' -v t="$token" '
        $1 != "" {
          path = $2
          gsub(/^[ \t]+|[ \t]+$/, "", path)
          sub(/\/+$/, "", path)
          n = split(path, seg, "/")
          if (seg[n] == t) printf "%s%s", (found++ ? ", " : ""), $1
        }' )
      echo "  WARN     layers $sharing share the directory name '$token'"
      echo "           imports that do not spell a full layer path cannot be attributed between them"
    done <<EOF
$ambiguous_tokens
EOF
  fi

  # A dependency name matching no declared layer never permits anything, so the
  # layer quietly enforces more than its author wrote. Surface it before the
  # per-file scan, since it changes what the results below mean.
  unknown_deps=$(find_unknown_dependencies || true)

  if [ -n "$unknown_deps" ]; then
    while IFS='|' read -r from dep; do
      [ -n "$from" ] || continue
      echo "  WARN     layer '$from' may depend on '$dep', which is not a declared layer"
    done <<EOF
$unknown_deps
EOF
  fi

  # The declared graph must be a directed acyclic graph. "Dependencies point
  # inward" is not satisfiable if two layers may each depend on the other.
  declared_cycles=$(find_declared_cycles || true)

  if [ -n "$declared_cycles" ]; then
    while IFS= read -r cycle; do
      [ -n "$cycle" ] || continue
      echo "  CYCLE     $cycle"
      echo "            the declared layer graph must be acyclic; these layers may each depend on the other"
      cycle_violations=$((cycle_violations + 1))
    done <<EOF
$declared_cycles
EOF
  fi

  # Attribute a normalized import to a declared layer, or nothing.
  # Attribute an import to a declared layer, in two passes over every candidate
  # form of the reference.
  #
  # Pass 1 matches a layer's full declared path; pass 2 falls back to the layer
  # directory's own name. The passes are separate, and pass 1 runs over ALL
  # layers before pass 2 runs over any, because a full-path match is strictly
  # better evidence than a directory-name match. Interleaving them -- testing
  # both for each layer in turn -- lets an earlier layer's directory name beat a
  # later layer's exact path, which silently misattributes the import and, when
  # the wrong answer is the importing layer itself, drops a real violation as a
  # self-import.
  #
  # Pass 2 skips directory names shared by several layers. Declining to answer
  # is correct there: any guess reassigns a genuine dependency.
  layer_for_ref() {
    local ref=$1 candidates name path token

    candidates=$(candidate_refs "$ref")

    while IFS= read -r candidate; do
      [ -n "$candidate" ] || continue
      while IFS='|' read -r name path _; do
        [ -n "$name" ] || continue
        path=$(normalize_ref "$path")
        case "/$candidate/" in
          */"$path"/*) printf '%s' "$name"; return 0 ;;
        esac
      done <<EOF
$layer_records
EOF
    done <<EOF
$candidates
EOF

    while IFS= read -r candidate; do
      [ -n "$candidate" ] || continue
      while IFS='|' read -r name path _; do
        [ -n "$name" ] || continue
        path=$(normalize_ref "$path")
        token=${path##*/}
        [ -n "$token" ] || continue

        if printf '%s\n' "$ambiguous_tokens" | grep -qxF "$token"; then
          continue
        fi

        case "/$candidate/" in
          */"$token"/*) printf '%s' "$name"; return 0 ;;
        esac
      done <<EOF
$layer_records
EOF
    done <<EOF
$candidates
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

  if [ "$layer_violations" -eq 0 ] && [ "$cycle_violations" -eq 0 ]; then
    echo "  OK       $layers_declared layer(s) declared; graph is acyclic and all dependencies point inward"
  fi
fi

# ---------------------------------------------------------------------------
# Structural signals. Advisory only -- these never change the exit status.
# ---------------------------------------------------------------------------

report_structural_signals

echo
echo "Layer violations: $layer_violations; declared cycles: $cycle_violations; structural signals: $signal_count."

if [ "$layer_violations" -gt 0 ] || [ "$cycle_violations" -gt 0 ]; then
  if [ "$cycle_violations" -gt 0 ] && [ "$layer_violations" -gt 0 ]; then
    summary="the declared layer graph is cyclic and dependencies point outward"
  elif [ "$cycle_violations" -gt 0 ]; then
    summary="the declared layer graph is cyclic"
  else
    summary="dependencies point outward"
  fi

  if [ "$strict" = "true" ]; then
    echo "FAIL: $summary (--strict)."
    exit 1
  fi
  echo "WARN: $summary (pass --strict to enforce)."
fi

exit 0
