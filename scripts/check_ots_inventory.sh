#!/usr/bin/env bash
set -euo pipefail

# GitHub Actions annotations (a no-op everywhere else); see scripts/lib/ci_annotations.sh.
if [ -f "$(dirname -- "$0")/lib/ci_annotations.sh" ]; then
  # shellcheck source=lib/ci_annotations.sh
  . "$(dirname -- "$0")/lib/ci_annotations.sh"
else
  ci_annotate() { :; }
fi

# Verify that every third-party dependency declared in the project's dependency
# manifests has a corresponding entry in the OTS software inventory
# (docs/OTS_SOFTWARE.md).
#
# This is the enforcement half of the constitution's OTS software tracking
# (DOCUMENTATION.md, "OTS Software Inventory"): the inventory documents what
# each off-the-shelf component is for, how risky it is, and how it was verified
# — this checker catches the drift case where a dependency is added to a
# manifest without the inventory being updated in the same change.
#
# This is governance tooling: a silent bug here removes the guarantee it appears
# to provide (see constitution TESTING.md, "Governance Tooling Must Be Tested").
# Manifest entries are matched against the inventory's Name column by exact cell
# value (case-insensitive), never by substring, so a row for `dunder-proto` can
# never satisfy a check for `proto`.
#
# Scope, deliberately:
#   - Only manifests at the project root are read unless --manifest-dir names
#     more (monorepo packages are not walked automatically).
#   - Only runtime dependencies are read (package.json "dependencies", not
#     "devDependencies"; Cargo.toml [dependencies], not [dev-dependencies];
#     go.mod direct requires, not "// indirect"). Development-only tooling may
#     still be documented in the inventory voluntarily.
#   - System-level OTS (operating systems, databases, container base images)
#     cannot be discovered from manifests; the inventory's "System-Level OTS"
#     section covers those by hand, and rows there never fail this check.
#
# Follows the constitution's CI rollout contract: warn by default, --strict to
# fail (TESTING.md, "CI Enforcement").
#
# Exit status:
#   0  every declared dependency is documented (or nothing is declared;
#      or gaps exist but --strict was not given)
#   1  at least one undocumented dependency (or a missing inventory file while
#      dependencies are declared), under --strict
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_ots_inventory.sh [--strict] [--manifest-dir <dir>]... [project-root]

Description:
  Confirm that every third-party dependency declared in the project's
  dependency manifests has an entry in docs/OTS_SOFTWARE.md (the OTS software
  inventory).

Arguments:
  project-root   Path to the repository root to check. Default: current directory.

Options:
  --strict              Treat undocumented dependencies (and a missing
                        inventory file) as failures instead of warnings.
  --manifest-dir <dir>  Also read manifests in this directory, relative to
                        the project root (for a sub-package such as
                        mcp-server/). Repeatable. Dependencies found there are
                        labeled with the directory prefix in the report.
  -h, --help            Show this help.

Manifests read (project root plus any --manifest-dir, runtime dependencies only):
  package.json      "dependencies" block (not devDependencies)
  requirements.txt  requirement lines (options, URLs, and includes skipped)
  pyproject.toml    PEP 621 [project] dependencies array
  go.mod            direct require entries (not "// indirect")
  Cargo.toml        [dependencies] section (not [dev-dependencies])
  Gemfile           gem "name" declarations

A dependency is documented when the inventory has a table row whose Name cell
equals the manifest name exactly (case-insensitive; surrounding backticks are
ignored). Placeholder cells (containing <angle brackets>) never count.
Inventory rows that match no manifest entry are reported informationally and
never fail the check — they may be system-level OTS or removed dependencies.
USAGE
}

strict=false
root=""
manifest_dirs=()

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
    --manifest-dir)
      if [ "$#" -lt 2 ]; then
        echo "--manifest-dir requires a directory argument" >&2
        exit 2
      fi
      manifest_dirs+=("$2")
      shift 2
      ;;
    --manifest-dir=*)
      manifest_dirs+=("${1#--manifest-dir=}")
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
inventory="$root/docs/OTS_SOFTWARE.md"

# ---------------------------------------------------------------------------
# Collect declared runtime dependencies from root-level manifests.
# Each collector emits "name<TAB>manifest" lines.
# ---------------------------------------------------------------------------

deps=""

add_deps() {
  # Append newline-separated "name<TAB>manifest" lines, skipping empties.
  local lines=$1
  [ -z "$lines" ] && return 0
  if [ -z "$deps" ]; then
    deps=$lines
  else
    deps="$deps
$lines"
  fi
}

# collect_manifests <dir> <label-prefix>: read every supported manifest in
# <dir> and append its runtime dependencies to $deps, labeled
# "<label-prefix><manifest>" so a report line says where each one came from.
collect_manifests() {
  local dir=$1
  local prefix=$2

  if [ -f "$dir/package.json" ]; then
    add_deps "$(
      awk -v prefix="$prefix" '
        /"dependencies"[[:space:]]*:[[:space:]]*\{/ { ind = 1; if ($0 ~ /\}/) ind = 0; next }
        ind && /\}/ { ind = 0; next }
        ind {
          line = $0
          if (match(line, /"[^"]+"[[:space:]]*:/)) {
            key = substr(line, RSTART, RLENGTH)
            sub(/^"/, "", key)
            sub(/"[[:space:]]*:$/, "", key)
            if (key != "") print key "\t" prefix "package.json"
          }
        }
      ' "$dir/package.json"
    )"
  fi

  if [ -f "$dir/requirements.txt" ]; then
    add_deps "$(
      awk -v prefix="$prefix" '
        /^[[:space:]]*(#|$)/ { next }        # comments, blanks
        /^[[:space:]]*-/ { next }            # pip options, -r includes, -e installs
        /^[[:space:]]*(git\+|https?:|file:)/ { next }  # URL requirements
        /^[[:space:]]*\.\.?\// { next }      # local paths
        {
          line = $0
          sub(/^[[:space:]]+/, "", line)
          if (match(line, /^[A-Za-z0-9][A-Za-z0-9._-]*/)) {
            print substr(line, RSTART, RLENGTH) "\t" prefix "requirements.txt"
          }
        }
      ' "$dir/requirements.txt"
    )"
  fi

  if [ -f "$dir/pyproject.toml" ]; then
    add_deps "$(
      awk -v prefix="$prefix" '
        /^[[:space:]]*dependencies[[:space:]]*=[[:space:]]*\[/ {
          ind = 1
          if ($0 ~ /\]/) ind = 0   # single-line array handled below too
        }
        ind || /^[[:space:]]*dependencies[[:space:]]*=[[:space:]]*\[/ {
          line = $0
          while (match(line, /"[^"]+"/) || match(line, /'\''[^'\'']+'\''/)) {
            spec = substr(line, RSTART + 1, RLENGTH - 2)
            line = substr(line, RSTART + RLENGTH)
            if (match(spec, /^[A-Za-z0-9][A-Za-z0-9._-]*/)) {
              print substr(spec, RSTART, RLENGTH) "\t" prefix "pyproject.toml"
            }
          }
        }
        ind && /\]/ { ind = 0 }
      ' "$dir/pyproject.toml"
    )"
  fi

  if [ -f "$dir/go.mod" ]; then
    add_deps "$(
      awk -v prefix="$prefix" '
        /^require[[:space:]]*\(/ { ind = 1; next }
        ind && /^\)/ { ind = 0; next }
        ind {
          if ($0 ~ /\/\/[[:space:]]*indirect/) next
          if (NF >= 2) print $1 "\t" prefix "go.mod"
          next
        }
        /^require[[:space:]]+[^(]/ {
          if ($0 ~ /\/\/[[:space:]]*indirect/) next
          print $2 "\t" prefix "go.mod"
        }
      ' "$dir/go.mod"
    )"
  fi

  if [ -f "$dir/Cargo.toml" ]; then
    add_deps "$(
      awk -v prefix="$prefix" '
        /^\[dependencies\]/ { ind = 1; next }
        /^\[dependencies\./ {
          name = $0
          sub(/^\[dependencies\./, "", name)
          sub(/\].*$/, "", name)
          if (name != "") print name "\t" prefix "Cargo.toml"
          ind = 0
          next
        }
        /^\[/ { ind = 0; next }
        ind && /^[A-Za-z0-9_-]+[[:space:]]*=/ {
          name = $0
          sub(/[[:space:]]*=.*$/, "", name)
          if (name != "") print name "\t" prefix "Cargo.toml"
        }
      ' "$dir/Cargo.toml"
    )"
  fi

  if [ -f "$dir/Gemfile" ]; then
    add_deps "$(
      awk -v prefix="$prefix" '
        /^[[:space:]]*gem[[:space:]]+["'\'']/ {
          line = $0
          sub(/^[[:space:]]*gem[[:space:]]+["'\'']/, "", line)
          if (match(line, /^[^"'\'']+/)) {
            print substr(line, RSTART, RLENGTH) "\t" prefix "Gemfile"
          }
        }
      ' "$dir/Gemfile"
    )"
  fi
}

collect_manifests "$root" ""
for sub in "${manifest_dirs[@]+"${manifest_dirs[@]}"}"; do
  sub=${sub%/}
  if [ ! -d "$root/$sub" ]; then
    echo "Manifest directory not found under project root: $sub" >&2
    exit 2
  fi
  collect_manifests "$root/$sub" "$sub/"
done

# Deduplicate (a name can legitimately appear in two manifests; keep both
# labels but collapse exact duplicates).
if [ -n "$deps" ]; then
  deps=$(printf '%s\n' "$deps" | awk 'NF' | sort -u)
fi

if [ -z "$deps" ]; then
  echo "No declared third-party dependencies found in the scanned manifests; nothing to verify."
  exit 0
fi

dep_count=$(printf '%s\n' "$deps" | grep -c . || true)

# ---------------------------------------------------------------------------
# Missing inventory: dependencies exist but the inventory file does not.
# ---------------------------------------------------------------------------

if [ ! -f "$inventory" ]; then
  echo "Found $dep_count declared dependency(ies) but no OTS software inventory at docs/OTS_SOFTWARE.md."
  echo "Create it from constitution/templates/docs/OTS_SOFTWARE.md and document each dependency."
  if [ "$strict" = "true" ]; then
    echo "FAIL: missing inventory (--strict)."
    ci_annotate error "check_ots_inventory.sh: $dep_count dependency(ies) declared but docs/OTS_SOFTWARE.md is missing"
    exit 1
  fi
  echo "WARN: missing inventory (pass --strict to enforce)."
  ci_annotate warning "check_ots_inventory.sh: $dep_count dependency(ies) declared but docs/OTS_SOFTWARE.md is missing (pass --strict to enforce)"
  exit 0
fi

# ---------------------------------------------------------------------------
# Parse the inventory's Name cells from every table that has a Name column.
# Same header-located, exact-cell approach as check_traceability.sh.
# ---------------------------------------------------------------------------

inventory_names=$(
  awk '
    function trim(s) {
      gsub(/^[ \t]+|[ \t]+$/, "", s)
      gsub(/`/, "", s)
      return s
    }
    function flush() {
      if (havep && active && namecol > 0 && namecol <= prevn) {
        n = prev[namecol]
        if (n != "" && n !~ /<.*>/) print n
      }
    }
    {
      if ($0 ~ /^[ \t]*\|/) {
        nf = split($0, f, "|")
        curn = 0
        for (i = 2; i < nf; i++) { curn++; cur[curn] = trim(f[i]) }

        if (curn >= 1 && cur[1] ~ /^:?-+:?$/) {
          namecol = 0; active = 0
          if (havep) {
            for (i = 1; i <= prevn; i++) {
              if (prev[i] == "Name") { namecol = i; active = 1 }
            }
          }
          havep = 0
          next
        }

        flush()
        prevn = curn
        for (i = 1; i <= curn; i++) prev[i] = cur[i]
        havep = 1
        next
      }
      flush()
      havep = 0
    }
    END { flush() }
  ' "$inventory"
)

# Map of lowercased inventory name -> original name, for case-insensitive
# exact matching.
declare -A documented
while IFS= read -r name; do
  [ -z "$name" ] && continue
  lc=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')
  documented["$lc"]="$name"
done <<< "$inventory_names"

# ---------------------------------------------------------------------------
# Compare.
# ---------------------------------------------------------------------------

missing=0
covered=0
matched_lc=""
echo "OTS inventory coverage (root manifests -> docs/OTS_SOFTWARE.md):"
while IFS=$'\t' read -r name manifest; do
  [ -z "$name" ] && continue
  lc=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')
  if [ -n "${documented[$lc]+set}" ]; then
    echo "  OK       $name ($manifest)"
    covered=$((covered + 1))
    matched_lc="$matched_lc $lc"
  else
    echo "  MISSING  $name ($manifest) has no row in the OTS inventory"
    missing=$((missing + 1))
  fi
done <<< "$deps"

# Inventory rows that match no manifest dependency: informational only. These
# are expected for system-level OTS (databases, runtimes, base images) and for
# components whose Status is Removed.
extras=()
for lc in "${!documented[@]}"; do
  case " $matched_lc " in
    *" $lc "*) ;;
    *) extras+=("${documented[$lc]}") ;;
  esac
done
if [ "${#extras[@]}" -gt 0 ]; then
  echo
  echo "Note: inventory rows with no matching root-manifest dependency (system-level OTS, removed components, or dev tooling):"
  printf '%s\n' "${extras[@]}" | sort | sed 's/^/  - /'
fi

echo
echo "Checked $dep_count declared dependency(ies); $covered documented, $missing undocumented."

if [ "$missing" -gt 0 ]; then
  if [ "$strict" = "true" ]; then
    echo "FAIL: undocumented dependencies (--strict). Add rows to docs/OTS_SOFTWARE.md in the same change that adds the dependency."
    ci_annotate error "check_ots_inventory.sh: $missing undocumented dependency(ies) in docs/OTS_SOFTWARE.md"
    exit 1
  fi
  echo "WARN: undocumented dependencies (pass --strict to enforce)."
  ci_annotate warning "check_ots_inventory.sh: $missing undocumented dependency(ies) in docs/OTS_SOFTWARE.md (pass --strict to enforce)"
fi
exit 0
