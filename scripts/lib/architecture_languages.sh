# shellcheck shell=bash
#
# Language knowledge for scripts/check_architecture.sh.
#
# Sourced, never executed. Reads the global `root`; sets `go_module_prefix`,
# `ts_aliases`, and `module_roots` when `detect_module_roots` is called.
#
# Everything here answers one question: what repository-relative path does this
# import string refer to? That is entirely a matter of how each language spells
# imports and what it resolves them against -- Go prefixes internal imports with
# the module path from go.mod, TypeScript rewrites aliases through
# tsconfig.json, Python src-layouts address packages from a root that is not the
# repository root.
#
# Split from check_architecture.sh because it changes for its own reason:
# adding a language, or fixing how an existing one spells imports, touches this
# file and nothing else. The layer rules it feeds are indifferent to which
# languages exist.

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

# `compilerOptions.paths` aliases as `pattern|target` pairs.
ts_aliases=""

# Directory prefixes a bare module path may be relative to.
module_roots=""

# Populate the three globals above by reading the project's build files. Called
# once, after $root is resolved.
detect_module_roots() {
  local tsconfig base_url candidate_root

  if [ -f "$root/go.mod" ]; then
    go_module_prefix=$(sed -n 's/^[[:space:]]*module[[:space:]]\{1,\}\([^[:space:]]\{1,\}\).*/\1/p' "$root/go.mod" | head -n 1)
  fi

  # Comment lines are dropped first, since tsconfig is conventionally JSONC.
  for tsconfig in tsconfig.json jsconfig.json; do
    [ -f "$root/$tsconfig" ] || continue
    # `|| true` for the same reason as baseUrl below: a tsconfig declaring no
    # array-valued option at all makes this grep exit 1 and abort the checker.
    ts_aliases="$ts_aliases$(
      sed 's|//.*||' "$root/$tsconfig" |
        tr -d '\n' |
        grep -oE '"[^"]+"[[:space:]]*:[[:space:]]*\[[[:space:]]*"[^"]+"' |
        sed -E 's|"([^"]+)"[[:space:]]*:[[:space:]]*\[[[:space:]]*"([^"]+)"|\1\|\2|' |
        sed 's|/\*||g' || true
    )
"
  done

  ts_aliases=$(printf '%s' "$ts_aliases" | awk 'NF')

  # `baseUrl` covers TypeScript; a top-level `src/` covers the Python and Node
  # src-layout, where `from domain.models import X` addresses
  # `src/domain/models`.
  if [ -f "$root/tsconfig.json" ]; then
    # `|| true` because a tsconfig without baseUrl is the common case, not an
    # error -- Next.js ships `paths` with no `baseUrl`. Under `set -euo
    # pipefail` an unguarded grep that matches nothing exits 1, fails the
    # assignment, and aborts the whole checker after it has printed only its
    # header: no violation, no message, exit 1. Fixed in 1.41.1; kept here
    # because this file is where that code now lives.
    base_url=$(sed 's|//.*||' "$root/tsconfig.json" |
      grep -oE '"baseUrl"[[:space:]]*:[[:space:]]*"[^"]+"' |
      sed -E 's|.*"([^"]+)"$|\1|' | head -n 1 || true)
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
}

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
