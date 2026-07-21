#!/usr/bin/env bash
set -euo pipefail

# Verify that every environment variable declared in the project's configuration
# manifests (.env.example, .env.template, docker-compose.yml) has a corresponding
# entry in the Environment & Configuration Contract (docs/ENV_VARS.md).
#
# This enforces that deployments don't break due to undocumented configuration
# requirements.
#
# Follows the constitution's CI rollout contract: warn by default, --strict to
# fail (TESTING.md, "CI Enforcement").
#
# Exit status:
#   0  every declared env var is documented (or nothing is declared;
#      or gaps exist but --strict was not given)
#   1  at least one undocumented env var (or a missing env vars file while
#      vars are declared), under --strict
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_env_vars.sh [--strict] [project-root]

Description:
  Confirm that every environment variable declared in the project's
  configuration manifests has an entry in docs/ENV_VARS.md.

Arguments:
  project-root   Path to the repository root to check. Default: current directory.

Options:
  --strict    Treat undocumented variables (and a missing ENV_VARS.md file)
              as failures instead of warnings.
  -h, --help  Show this help.

Manifests read (project root only):
  .env.example          Variable assignments (KEY=value)
  .env.template         Variable assignments
  docker-compose.yml    environment: blocks (array and mapping syntax)
  docker-compose.yaml   environment: blocks

A variable is documented when docs/ENV_VARS.md has a table row whose first cell
equals the manifest key exactly (case-insensitive; surrounding backticks are
ignored). Placeholder cells (containing <angle brackets>) never count.
USAGE
}

strict=false
root=""

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
contract="$root/docs/ENV_VARS.md"

# ---------------------------------------------------------------------------
# Collect declared env vars from root-level manifests.
# Each collector emits "key<TAB>manifest" lines.
# ---------------------------------------------------------------------------

vars=""

add_vars() {
  local lines=$1
  [ -z "$lines" ] && return 0
  if [ -z "$vars" ]; then
    vars=$lines
  else
    vars="$vars
$lines"
  fi
}

for env_file in .env.example .env.template; do
  if [ -f "$root/$env_file" ]; then
    add_vars "$(
      awk -v fname="$env_file" '
        /^[A-Za-z_][A-Za-z0-9_]*[ \t]*=/ {
          line = $0
          sub(/^[ \t]*/, "", line)
          sub(/[ \t]*=.*$/, "", line)
          if (line != "") print line "\t" fname
        }
      ' "$root/$env_file"
    )"
  fi
done

for compose_file in docker-compose.yml docker-compose.yaml; do
  if [ -f "$root/$compose_file" ]; then
    add_vars "$(
      awk -v fname="$compose_file" '
        {
          curr_indent = match($0, /[^ \t]/)
          if (!curr_indent) next
        }
        /^[ \t]+environment:[ \t]*$/ { 
          env_block = 1
          indent = curr_indent
          next 
        }
        env_block {
          if (curr_indent <= indent) {
            env_block = 0
          } else {
            if ($0 ~ /^[ \t]+-[ \t]+[A-Za-z_][A-Za-z0-9_]*(=|$)/) {
              line = $0
              sub(/^[ \t]+-[ \t]+/, "", line)
              sub(/=.*$/, "", line)
              if (line != "") print line "\t" fname
            } else if ($0 ~ /^[ \t]+[A-Za-z_][A-Za-z0-9_]*[ \t]*:/) {
              line = $0
              sub(/^[ \t]+/, "", line)
              sub(/[ \t]*:.*$/, "", line)
              if (line != "") print line "\t" fname
            }
          }
        }
      ' "$root/$compose_file"
    )"
  fi
done

# Deduplicate
if [ -n "$vars" ]; then
  vars=$(printf '%s\n' "$vars" | awk 'NF' | sort -u)
fi

if [ -z "$vars" ]; then
  echo "No declared environment variables found in root-level manifests; nothing to verify."
  exit 0
fi

var_count=$(printf '%s\n' "$vars" | grep -c . || true)

# ---------------------------------------------------------------------------
# Missing contract: variables exist but the contract file does not.
# ---------------------------------------------------------------------------

if [ ! -f "$contract" ]; then
  echo "Found $var_count declared environment variable(s) but no contract at docs/ENV_VARS.md."
  echo "Create it from constitution/templates/docs/ENV_VARS.md and document each variable."
  if [ "$strict" = "true" ]; then
    echo "FAIL: missing ENV_VARS.md (--strict)."
    exit 1
  fi
  echo "WARN: missing ENV_VARS.md (pass --strict to enforce)."
  exit 0
fi

# ---------------------------------------------------------------------------
# Parse the contract's Variable cells from every markdown table.
# ---------------------------------------------------------------------------

contract_names=$(
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
              if (tolower(prev[i]) == "variable" || tolower(prev[i]) == "name" || tolower(prev[i]) == "key") { namecol = i; active = 1 }
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
  ' "$contract"
)

declare -A documented
while IFS= read -r name; do
  [ -z "$name" ] && continue
  lc=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')
  documented["$lc"]="$name"
done <<< "$contract_names"

# ---------------------------------------------------------------------------
# Compare.
# ---------------------------------------------------------------------------

missing=0
covered=0
echo "Environment variable coverage (root manifests -> docs/ENV_VARS.md):"
while IFS=$'\t' read -r name manifest; do
  [ -z "$name" ] && continue
  lc=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')
  if [ -n "${documented[$lc]+set}" ]; then
    echo "  OK       $name ($manifest)"
    covered=$((covered + 1))
  else
    echo "  MISSING  $name ($manifest) has no row in ENV_VARS.md"
    missing=$((missing + 1))
  fi
done <<< "$vars"

echo
echo "Checked $var_count declared variable(s); $covered documented, $missing undocumented."

if [ "$missing" -gt 0 ]; then
  if [ "$strict" = "true" ]; then
    echo "FAIL: undocumented environment variables (--strict)."
    exit 1
  fi
  echo "WARN: undocumented environment variables (pass --strict to enforce)."
fi
exit 0
