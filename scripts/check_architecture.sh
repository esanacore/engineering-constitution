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

# --- Module roots -----------------------------------------------------------
#
# An import is only comparable to a layer path once it is expressed in the same
# terms. Languages disagree about what an import string is relative to: Go
# prefixes every internal import with the module path from go.mod, TypeScript
# rewrites aliases through tsconfig.json, and Python src-layouts address
# packages from a root that is not the repository root. Reading those roots
# turns an import into a repository-relative path, which can then be matched
# against a declared layer path exactly rather than by directory name.

# The `module` line in go.mod, e.g. `github.com/esanacore/app`.
go_module_prefix=""

if [ -f "$root/go.mod" ]; then
  go_module_prefix=$(sed -n 's/^[[:space:]]*module[[:space:]]\{1,\}\([^[:space:]]\{1,\}\).*/\1/p' "$root/go.mod" | head -n 1)
fi

# `compilerOptions.paths` aliases from tsconfig.json, as `pattern|target` pairs
# with the trailing `/*` stripped from both sides. Comment lines are dropped
# first, since tsconfig is conventionally JSONC.
ts_aliases=""

for tsconfig in tsconfig.json jsconfig.json; do
  [ -f "$root/$tsconfig" ] || continue
  ts_aliases="$ts_aliases$(
    sed 's|//.*||' "$root/$tsconfig" |
      tr -d '\n' |
      grep -oE '"[^"]+"[[:space:]]*:[[:space:]]*\[[[:space:]]*"[^"]+"' |
      sed -E 's|"([^"]+)"[[:space:]]*:[[:space:]]*\[[[:space:]]*"([^"]+)"|\1\|\2|' |
      sed 's|/\*||g'
  )
"
done

ts_aliases=$(printf '%s' "$ts_aliases" | awk 'NF')

# Directory prefixes a bare module path may be relative to. `baseUrl` covers
# TypeScript; a top-level `src/` covers the Python and Node src-layout, where
# `from domain.models import X` addresses `src/domain/models`.
module_roots=""

if [ -f "$root/tsconfig.json" ]; then
  base_url=$(sed 's|//.*||' "$root/tsconfig.json" |
    grep -oE '"baseUrl"[[:space:]]*:[[:space:]]*"[^"]+"' |
    sed -E 's|.*"([^"]+)"$|\1|' | head -n 1)
  case "$base_url" in
    ""|.|./) ;;
    *) module_roots="$module_roots $(normalize_ref "$base_url")" ;;
  esac
fi

for candidate_root in src lib app; do
  [ -d "$root/$candidate_root" ] || continue
  case " $module_roots " in
    *" $candidate_root "*) ;;
    *) module_roots="$module_roots $candidate_root" ;;
  esac
done

# Every repository-relative form an import might take. Emitting a candidate is
# free: a wrong one simply matches no declared layer path.
candidate_refs() {
  local ref=$1 rest pattern target mroot

  printf '%s\n' "$ref"

  if [ -n "$go_module_prefix" ]; then
    case "$ref" in
      "$go_module_prefix"/*)
        rest=${ref#"$go_module_prefix"/}
        printf '%s\n' "$(normalize_ref "$rest")"
        ;;
    esac
  fi

  if [ -n "$ts_aliases" ]; then
    while IFS='|' read -r pattern target; do
      [ -n "$pattern" ] || continue
      pattern=$(normalize_ref "$pattern")
      target=$(normalize_ref "$target")
      case "$ref" in
        "$pattern"/*) printf '%s\n' "$target/${ref#"$pattern"/}" ;;
        "$pattern")   printf '%s\n' "$target" ;;
      esac
    done <<EOF
$ts_aliases
EOF
  fi

  for mroot in $module_roots; do
    case "$ref" in
      "$mroot"/*) ;;
      *) printf '%s\n' "$mroot/$ref" ;;
    esac
  done
}

# Layer directory names shared by more than one layer. A bare module path that
# names only such a directory cannot be attributed to one layer, and guessing
# would be worse than declining: it silently reassigns a real dependency.
ambiguous_tokens=$(printf '%s\n' "$layer_records" | awk '
  BEGIN { FS = "|" }
  $1 != "" {
    path = $2
    gsub(/^[ \t]+|[ \t]+$/, "", path)
    sub(/\/+$/, "", path)
    n = split(path, seg, "/")
    token = seg[n]
    if (token == "") next
    if (!(token in count)) count[token] = 0
    count[token]++
  }
  END { for (t in count) if (count[t] > 1) print t }
' || true)

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

# Emit one line per cycle in the declared dependency graph, normalized so the
# same cycle found from different entry points is reported once.
#
# Checking the *declared* graph rather than the observed imports is deliberate,
# and it is sufficient: every actual import is either permitted -- and therefore
# an edge already present in this graph -- or it is a violation, which is
# reported separately below. So if this graph is acyclic, no cycle can exist
# among the imports that pass. A cyclic declaration is an unsound architecture
# regardless of how much of it the code currently exercises.
find_declared_cycles() {
  printf '%s\n' "$layer_records" | awk '
    BEGIN { FS = "|" }
    {
      name = $1
      if (name == "") next
      known[name] = 1
      order[++n] = name
      adj[name] = $3
    }
    END {
      for (i = 1; i <= n; i++) if (!(order[i] in state)) dfs(order[i])
      for (c in seen) print c
    }

    function dfs(node,   i, m, deps, dep, j, path, start) {
      state[node] = 1
      stack[++sp] = node

      m = split(adj[node], deps, ",")
      for (i = 1; i <= m; i++) {
        dep = deps[i]
        gsub(/^[ \t]+|[ \t]+$/, "", dep)
        gsub(/`/, "", dep)
        if (dep == "" || dep ~ /^(-+|—+|none|n\/a)$/) continue
        if (!(dep in known)) continue
        if (dep == node) continue

        if (state[dep] == 1) {
          start = 0
          for (j = 1; j <= sp; j++) if (stack[j] == dep) { start = j; break }
          if (start) {
            path = ""
            for (j = start; j <= sp; j++) path = path stack[j] " -> "
            seen[normalize(path dep)] = 1
          }
        } else if (state[dep] != 2) {
          dfs(dep)
        }
      }

      state[node] = 2
      sp--
    }

    # Rotate the cycle to begin at its lexicographically smallest member, so the
    # same cycle discovered from different entry points dedupes to one finding.
    function normalize(p,   parts, k, cnt, min, mi, out, idx) {
      cnt = split(p, parts, " -> ") - 1
      min = parts[1]; mi = 1
      for (k = 2; k <= cnt; k++) if (parts[k] < min) { min = parts[k]; mi = k }
      out = ""
      for (k = 0; k < cnt; k++) {
        idx = ((mi - 1 + k) % cnt) + 1
        out = out parts[idx] " -> "
      }
      return out min
    }
  '
}

# Names in a "May Depend On" cell that match no declared layer. A typo there is
# silent by construction: the intended dependency is never permitted, and no
# import can ever match it, so the layer simply behaves as if it declared less
# than the author believed.
find_unknown_dependencies() {
  printf '%s\n' "$layer_records" | awk '
    BEGIN { FS = "|" }
    { if ($1 != "") { known[$1] = 1; order[++n] = $1; adj[$1] = $3 } }
    END {
      for (i = 1; i <= n; i++) {
        name = order[i]
        m = split(adj[name], deps, ",")
        for (j = 1; j <= m; j++) {
          dep = deps[j]
          gsub(/^[ \t]+|[ \t]+$/, "", dep)
          gsub(/`/, "", dep)
          if (dep == "" || dep ~ /^(-+|—+|none|n\/a)$/) continue
          if (!(dep in known)) print name "|" dep
        }
      }
    }
  '
}

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
