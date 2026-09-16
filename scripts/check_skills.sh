#!/usr/bin/env bash
set -euo pipefail

# GitHub Actions annotations (a no-op everywhere else); see scripts/lib/ci_annotations.sh.
if [ -f "$(dirname -- "$0")/lib/ci_annotations.sh" ]; then
  # shellcheck source=lib/ci_annotations.sh
  . "$(dirname -- "$0")/lib/ci_annotations.sh"
else
  ci_annotate() { :; }
fi

# Verify that every agent skill under skills/ is well-formed: one SKILL.md per
# directory with a YAML front-matter block whose `name` matches the directory
# and whose `description` is non-empty, and whose body references only scripts
# that actually exist under scripts/.
#
# This is governance tooling: a silent bug here removes the guarantee it appears
# to provide (see constitution TESTING.md, "Governance Tooling Must Be Tested").
# Skills are loaded by tools that key on the front-matter name (Claude Code
# reads `<skills-dir>/<name>/SKILL.md`), so a name that disagrees with its
# directory is a skill that never triggers, and a skill that tells an agent to
# run a script that does not exist is worse than no skill.
#
# Exit status:
#   0  every skill is well-formed (or, without --strict, gaps were warnings)
#   1  at least one malformed skill and --strict was passed
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_skills.sh [--strict] [--skills-dir <dir>] [project-root]

Description:
  Validate every <skills-dir>/<name>/SKILL.md: front-matter present, `name`
  equals the directory name, `description` non-empty, an H1 body follows, and
  every `*.sh` the body mentions exists under <project-root>/scripts/ (or
  <project-root>/constitution/scripts/ in an adopting repository).

Arguments:
  project-root   Repository root. Default: current directory.

Options:
  --skills-dir <dir>  Skills directory relative to the root. Default: skills.
  --strict            Treat findings as failures instead of warnings.
  -h, --help          Show this help.
USAGE
}

strict=false
root=""
skills_dir="skills"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --strict) strict=true; shift ;;
    --skills-dir)
      if [ "$#" -lt 2 ]; then echo "--skills-dir requires a value" >&2; exit 2; fi
      skills_dir=$2; shift 2 ;;
    --skills-dir=*) skills_dir=${1#--skills-dir=}; shift ;;
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
skills_path="$root/$skills_dir"

if [ ! -d "$skills_path" ]; then
  echo "No skills directory at $skills_dir; nothing to verify."
  exit 0
fi

script_exists() {
  local name=$1
  [ -f "$root/scripts/$name" ] || [ -f "$root/constitution/scripts/$name" ]
}

echo "Skill validation under $skills_dir/"
echo

checked=0
findings=0
for skill_dir in "$skills_path"/*/; do
  [ -d "$skill_dir" ] || continue
  name=$(basename "$skill_dir")
  checked=$((checked + 1))
  file="$skill_dir/SKILL.md"
  problems=()

  if [ ! -f "$file" ]; then
    problems+=("no SKILL.md")
  else
    first=$(sed -n '1p' "$file")
    if [ "$first" != "---" ]; then
      problems+=("no front-matter block (first line must be ---)")
    else
      # Front matter is lines 2..N-1 where N is the second --- line.
      end=$(awk 'NR > 1 && $0 == "---" { print NR; exit }' "$file")
      if [ -z "$end" ]; then
        problems+=("front-matter block is never closed")
      else
        fm=$(sed -n "2,$((end - 1))p" "$file")
        fm_name=$(printf '%s\n' "$fm" | sed -n -E 's/^name:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/p' | head -n 1)
        fm_desc=$(printf '%s\n' "$fm" | sed -n -E 's/^description:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/p' | head -n 1)
        if [ -z "$fm_name" ]; then
          problems+=("front matter has no name")
        elif [ "$fm_name" != "$name" ]; then
          problems+=("front-matter name '$fm_name' does not match directory '$name'")
        fi
        if [ -z "$fm_desc" ]; then
          problems+=("front matter has no description")
        fi
        if ! sed -n "$((end + 1)),\$p" "$file" | grep -q '^# '; then
          problems+=("no H1 heading after the front matter")
        fi
      fi
    fi
    # Every script the body names must exist; otherwise the skill sends an
    # agent to run something that is not there.
    while IFS= read -r ref; do
      [ -z "$ref" ] && continue
      if ! script_exists "$ref"; then
        problems+=("references $ref, which does not exist under scripts/")
      fi
    done < <(grep -oE '[A-Za-z0-9_]+\.sh' "$file" | sort -u)
  fi

  if [ "${#problems[@]}" -eq 0 ]; then
    echo "  OK       $name"
  else
    for p in "${problems[@]}"; do
      echo "  PROBLEM  $name: $p"
    done
    findings=$((findings + 1))
  fi
done

echo
if [ "$checked" -eq 0 ]; then
  echo "No skills found under $skills_dir/; nothing to verify."
  exit 0
fi
echo "Checked $checked skill(s); $findings with problems."

if [ "$findings" -gt 0 ]; then
  if [ "$strict" = "true" ]; then
    echo "FAIL: malformed skills (--strict)."
    ci_annotate error "check_skills.sh: $findings malformed skill(s) under $skills_dir/"
    exit 1
  fi
  echo "WARN: malformed skills (pass --strict to enforce)."
  ci_annotate warning "check_skills.sh: $findings malformed skill(s) under $skills_dir/ (pass --strict to enforce)"
fi
exit 0
