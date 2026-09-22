#!/usr/bin/env bash
set -euo pipefail

# GitHub Actions annotations (a no-op everywhere else); see scripts/lib/ci_annotations.sh.
if [ -f "$(dirname -- "$0")/lib/ci_annotations.sh" ]; then
  # shellcheck source=lib/ci_annotations.sh
  . "$(dirname -- "$0")/lib/ci_annotations.sh"
else
  ci_annotate() { :; }
fi

# Verify that every agent instruction file in a directory carries the same
# guidance anchors, so a rule added to one vendor file is not silently missing
# from the others.
#
# This is governance tooling: a silent bug here removes the guarantee it appears
# to provide (see constitution TESTING.md, "Governance Tooling Must Be Tested").
#
# Why it exists: the constitution ships one instruction file per AI tool
# (AGENTS.md, CLAUDE.md, .cursorrules, .goosehints, ...) and they must all say
# the same thing about session planning, project memory, and the rest. Keeping
# them aligned was a manual grep — and the session-plan rollout missed half of
# them the first time. This checker makes the rule in AGENTS.md ("verify that
# docs/SESSION_PLAN.md and docs/MEMORY.md guidance stays consistent across all
# agent instruction templates") mechanical.
#
# Exit status:
#   0  every instruction file found carries every anchor (or, without
#      --strict, gaps were reported as warnings)
#   1  at least one gap and --strict was passed
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_instruction_templates.sh [--strict] [--anchor <text>]... [directory]

Description:
  Scan a directory for the agent instruction files the constitution knows
  about and confirm each one mentions every required anchor. Files that do
  not exist are skipped; the check is about consistency among the files that
  are present, not about which files a repository chooses to carry.

Arguments:
  directory   Directory to scan. Default: current directory. In the
              constitution source repository run it three times: against the
              root (this repository's own instruction files), `templates/`
              (what adopters receive), and `examples/sample-project/`.

Options:
  --anchor <text>  A string every instruction file must contain. Repeatable.
                   Default anchors: docs/SESSION_PLAN.md guidance
                   ("SESSION_PLAN") and project memory ("MEMORY.md").
  --strict         Treat a missing anchor as a failure instead of a warning.
  -h, --help       Show this help.

Instruction files scanned (when present):
  AGENTS.md, CLAUDE.md, COPILOT_INSTRUCTIONS.md, .cursorrules,
  .cursor/rules/project.mdc, .continue/config.json, .aider.conf.yml,
  .project-rules.md, .agent-instructions.md, .goosehints,
  .openhands_instructions, .antigravity/instructions.md,
  .github/copilot-instructions.md, .github/agents/solon.agent.md,
  SYSTEM_PROMPT.md, docs/SYSTEM_PROMPT.md, CONTRIBUTING.md,
  .github/CONTRIBUTING.md, HELP.md, docs/HELP.md.
USAGE
}

strict=false
dir=""
anchors=()

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
    --anchor)
      if [ "$#" -lt 2 ]; then
        echo "--anchor requires a value" >&2
        exit 2
      fi
      anchors+=("$2")
      shift 2
      ;;
    --anchor=*)
      anchors+=("${1#--anchor=}")
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
      if [ -n "$dir" ]; then
        echo "Unexpected extra argument: $1" >&2
        exit 2
      fi
      dir=$1
      shift
      ;;
  esac
done

dir=${dir:-.}
if [ ! -d "$dir" ]; then
  echo "Directory not found: $dir" >&2
  exit 2
fi
dir=$(CDPATH= cd -- "$dir" && pwd)

if [ "${#anchors[@]}" -eq 0 ]; then
  anchors=("SESSION_PLAN" "MEMORY.md")
fi

instruction_files=(
  AGENTS.md
  CLAUDE.md
  COPILOT_INSTRUCTIONS.md
  .cursorrules
  .cursor/rules/project.mdc
  .continue/config.json
  .aider.conf.yml
  .project-rules.md
  .agent-instructions.md
  .goosehints
  .openhands_instructions
  .antigravity/instructions.md
  .github/copilot-instructions.md
  .github/agents/solon.agent.md
  SYSTEM_PROMPT.md
  docs/SYSTEM_PROMPT.md
  CONTRIBUTING.md
  .github/CONTRIBUTING.md
  HELP.md
  docs/HELP.md
)

echo "Instruction-file consistency under $dir"
echo "Required anchors: ${anchors[*]}"
echo

checked=0
gaps=0
for rel in "${instruction_files[@]}"; do
  file="$dir/$rel"
  [ -f "$file" ] || continue
  checked=$((checked + 1))
  missing=()
  for anchor in "${anchors[@]}"; do
    if ! grep -qF -- "$anchor" "$file"; then
      missing+=("$anchor")
    fi
  done
  if [ "${#missing[@]}" -eq 0 ]; then
    echo "  OK       $rel"
  else
    echo "  MISSING  $rel lacks: ${missing[*]}"
    gaps=$((gaps + 1))
  fi
done

echo
if [ "$checked" -eq 0 ]; then
  echo "No instruction files found under $dir; nothing to verify."
  exit 0
fi

echo "Checked $checked instruction file(s); $gaps with missing anchors."

if [ "$gaps" -gt 0 ]; then
  if [ "$strict" = "true" ]; then
    echo "FAIL: instruction files disagree (--strict). Add the missing guidance so every file says the same thing."
    ci_annotate error "check_instruction_templates.sh: $gaps instruction file(s) under $dir lack required guidance"
    exit 1
  fi
  echo "WARN: instruction files disagree (pass --strict to enforce)."
  ci_annotate warning "check_instruction_templates.sh: $gaps instruction file(s) under $dir lack required guidance (pass --strict to enforce)"
fi
exit 0
