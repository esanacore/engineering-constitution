#!/usr/bin/env bash
set -euo pipefail

# Bootstrap an existing Git repository with Eric's Engineering Constitution.
#
# The constitution itself is installed as a Git submodule so projects can update
# universal rules without copying framework files by hand. Local project files
# are generated from templates and are skipped by default when they already
# exist, which makes the script safe to run against established repositories.

usage() {
  cat <<'USAGE'
Usage:
  bootstrap.sh [--force] [--agents=<list>] <project-path> <constitution-repository-url>

Description:
  Initialize an existing Git repository with Eric's Engineering Constitution.

Creates or installs:
  - constitution Git submodule
  - AGENTS.md
  - .github/CONTRIBUTING.md
  - .github/SECURITY.md
  - docs/HELP.md
  - .github/agents/solon.agent.md
  - .github/dependabot.yml
  - .github/workflows/constitution-version.yml
  - .github/workflows/constitution-compliance.yml
  - .github/workflows/constitution-tests.yml
  - .github/workflows/constitution-doc-freshness.yml
  - .github/workflows/constitution-secrets.yml
  - .github/workflows/constitution-ots.yml
  - .github/workflows/constitution-env.yml
  - .github/workflows/constitution-architecture.yml
  - .pre-commit-config.yaml
  - .devcontainer/devcontainer.json
  - TODO.md
  - CHANGELOG.md
  - VERSION
  - Eric's Engineering Constitution badge in README.md
  - docs/adr/
  - docs/adr/0001-record-architecture-decisions.md
  - docs/SETUP.md
  - docs/COMMAND_REFERENCE.md
  - docs/TROUBLESHOOTING.md
  - docs/AGENT_PROMPTS.md
  - docs/AGENT_HANDOFF.md
  - docs/PRODUCT_REQUIREMENTS.md
  - docs/REQUIREMENTS_TRACEABILITY.md
  - docs/TEST_PLAN.md
  - docs/MVP_BACKLOG.md
  - docs/OPERATIONS.md
  - docs/SESSION_PLAN.md
  - docs/MEMORY.md
  - docs/ARCHITECTURE.md
  - .constitution-bootstrap/adoption-report.md
  - .constitution-bootstrap/templates/ for skipped existing files

Options:
  --force            Overwrite existing generated files.
  --agents=<list>    Comma-separated AI tools to generate vendor instruction
                     files for. Default: none -- only AGENTS.md is installed.

Agent vendor files:
  AGENTS.md is the cross-vendor standard and is always installed. Most modern
  tools read it directly, so a repository needs nothing else. Tools that
  hardcode their own filename get a vendor file only when named in --agents,
  which keeps the adopting repository's root listing small.

  Supported keys (--agents=claude,cursor):
    claude        CLAUDE.md, .claude/settings.json
    cursor        .cursorrules, .cursor/rules/project.mdc
    copilot       .github/copilot-instructions.md
    goose         .goosehints
    openhands     .openhands_instructions
    antigravity   .antigravity/instructions.md
    continue      .continue/config.json
    aider         .aider.conf.yml, .aiderignore
    generic       .agent-instructions.md, .project-rules.md,
                  docs/SYSTEM_PROMPT.md
    all           Every key above (the pre-1.38.0 behavior).
USAGE
}

force=false

# Vendor instruction files are opt-in. AGENTS.md is the cross-vendor standard and
# is always installed; everything else is generated only when the adopter names
# the tool, so a repository does not carry instruction files for tools nobody on
# the project uses. Empty means "AGENTS.md only".
agents=""

# All recognized --agents keys, used to expand `all` and to reject typos.
all_agent_keys="claude cursor copilot goose openhands antigravity continue aider generic"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      force=true
      shift
      ;;
    --agents=*)
      agents=${1#--agents=}
      shift
      ;;
    --agents)
      if [ "$#" -lt 2 ]; then
        echo "--agents requires a value (for example --agents=claude,cursor)" >&2
        exit 2
      fi
      agents=$2
      shift 2
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
      break
      ;;
  esac
done

if [ "$#" -ne 2 ]; then
  usage
  exit 1
fi

# Normalize the requested agent list into space-delimited keys so `wants_agent`
# can match on word boundaries. `all` expands to every supported key.
requested_agents=""

if [ -n "$agents" ]; then
  for key in $(printf '%s' "$agents" | tr ',' ' '); do
    case " $all_agent_keys " in
      *" $key "*)
        requested_agents="$requested_agents $key"
        ;;
      *)
        if [ "$key" = "all" ]; then
          requested_agents=" $all_agent_keys"
        else
          echo "Unknown --agents key: $key" >&2
          echo "Supported keys: $all_agent_keys all" >&2
          exit 2
        fi
        ;;
    esac
  done
fi

# True when the adopter asked for this vendor's instruction files.
wants_agent() {
  case " $requested_agents " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

project_path=$1
constitution_url=$2

# Resolve paths from the script location so the command works no matter where it
# is called from.
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
template_dir="$repo_root/templates"
bootstrap_dir=""
skipped_files=()
written_files=()
modified_files=()

# Canonical home of Eric's Engineering Constitution. Used for the README badge
# link when the bootstrap source is a local path rather than a public URL.
constitution_repo_url="https://github.com/esanacore/engineering-constitution"

if [ ! -d "$project_path" ]; then
  echo "Project path does not exist: $project_path" >&2
  exit 1
fi

if [ ! -d "$project_path/.git" ]; then
  echo "Project path is not a Git repository: $project_path" >&2
  exit 1
fi

# Normalize the target path before changing directories for git operations.
project_path=$(CDPATH= cd -- "$project_path" && pwd)

if [ ! -d "$template_dir" ]; then
  echo "Template directory not found: $template_dir" >&2
  exit 1
fi

# Concerns that change for their own reasons live in scripts/lib/ and are
# sourced here. They are sourced through the absolute "$script_dir" and before
# this script cd's into the target project, so the target's working directory
# can never affect which files load.
lib_dir="$script_dir/lib"

for lib in bootstrap_readme.sh bootstrap_migrate.sh bootstrap_report.sh; do
  if [ ! -f "$lib_dir/$lib" ]; then
    echo "Missing required library: $lib_dir/$lib" >&2
    echo "The constitution checkout looks incomplete; re-clone or update the submodule." >&2
    exit 1
  fi
  # shellcheck source=/dev/null
  . "$lib_dir/$lib"
done

copy_file() {
  src=$1
  dest=$2

  # Existing project files are treated as user-owned unless --force is provided.
  if [ -e "$dest" ] && [ "$force" != "true" ]; then
    echo "Skipped existing file: $dest"
    skipped_files+=("${dest#$project_path/}")

    mkdir -p "$bootstrap_dir/templates/$(dirname "${dest#$project_path/}")"
    cp "$src" "$bootstrap_dir/templates/${dest#$project_path/}"
    echo "Wrote merge template: $bootstrap_dir/templates/${dest#$project_path/}"
    return
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  written_files+=("${dest#$project_path/}")
  echo "Wrote: $dest"
}


first_heading() {
  file=$1

  if [ ! -f "$file" ]; then
    echo "Unknown project"
    return
  fi

  heading=$(sed -n 's/^# \{1,\}//p' "$file" | head -n 1)

  if [ -n "$heading" ]; then
    echo "$heading"
  else
    basename "$project_path"
  fi
}




cd "$project_path"
bootstrap_dir="$project_path/.constitution-bootstrap"
mkdir -p "$bootstrap_dir/templates"

# The submodule path is intentionally fixed to constitution/ so AGENTS.md and
# other templates can reference a stable location.
if [ -e constitution ]; then
  echo "Skipped submodule; path already exists: constitution"
else
  git -c protocol.file.allow=always submodule add "$constitution_url" constitution
  echo "Added constitution submodule: $constitution_url"
fi

# AGENTS.md is the cross-vendor standard: always installed, and the only agent
# instruction file most repositories need.
copy_file "$template_dir/AGENTS.md" "$project_path/AGENTS.md"

# Vendor files for tools that hardcode their own filename, opt-in via --agents.
if wants_agent claude; then
  copy_file "$template_dir/CLAUDE.md" "$project_path/CLAUDE.md"
  copy_file "$template_dir/.claude/settings.json" "$project_path/.claude/settings.json"
fi

if wants_agent cursor; then
  copy_file "$template_dir/.cursorrules" "$project_path/.cursorrules"
  copy_file "$template_dir/.cursor/rules/project.mdc" "$project_path/.cursor/rules/project.mdc"
fi

if wants_agent copilot; then
  copy_file "$template_dir/.github/copilot-instructions.md" "$project_path/.github/copilot-instructions.md"
fi

if wants_agent goose; then
  copy_file "$template_dir/.goosehints" "$project_path/.goosehints"
fi

if wants_agent openhands; then
  copy_file "$template_dir/.openhands_instructions" "$project_path/.openhands_instructions"
fi

if wants_agent antigravity; then
  mkdir -p "$project_path/.antigravity"
  copy_file "$template_dir/.antigravity/instructions.md" "$project_path/.antigravity/instructions.md"
fi

if wants_agent continue; then
  copy_file "$template_dir/.continue/config.json" "$project_path/.continue/config.json"
fi

if wants_agent aider; then
  copy_file "$template_dir/.aider.conf.yml" "$project_path/.aider.conf.yml"
  copy_file "$template_dir/.aiderignore" "$project_path/.aiderignore"
fi

if wants_agent generic; then
  copy_file "$template_dir/.agent-instructions.md" "$project_path/.agent-instructions.md"
  copy_file "$template_dir/.project-rules.md" "$project_path/.project-rules.md"
  copy_file "$template_dir/SYSTEM_PROMPT.md" "$project_path/docs/SYSTEM_PROMPT.md"
fi

# GitHub renders CONTRIBUTING.md and SECURITY.md from .github/ identically to the
# repository root, so they live there to keep the root file listing short.
copy_file "$template_dir/CONTRIBUTING.md" "$project_path/.github/CONTRIBUTING.md"
copy_file "$template_dir/SECURITY.md" "$project_path/.github/SECURITY.md"
copy_file "$template_dir/HELP.md" "$project_path/docs/HELP.md"
mkdir -p "$project_path/.github/agents"
copy_file "$template_dir/.github/agents/solon.agent.md" "$project_path/.github/agents/solon.agent.md"
copy_file "$template_dir/.github/dependabot.yml" "$project_path/.github/dependabot.yml"
copy_file "$template_dir/.github/workflows/constitution-version.yml" "$project_path/.github/workflows/constitution-version.yml"
copy_file "$template_dir/.github/workflows/constitution-compliance.yml" "$project_path/.github/workflows/constitution-compliance.yml"
copy_file "$template_dir/.github/workflows/constitution-tests.yml" "$project_path/.github/workflows/constitution-tests.yml"
copy_file "$template_dir/.github/workflows/constitution-doc-freshness.yml" "$project_path/.github/workflows/constitution-doc-freshness.yml"
copy_file "$template_dir/.github/workflows/constitution-secrets.yml" "$project_path/.github/workflows/constitution-secrets.yml"
copy_file "$template_dir/.github/workflows/constitution-ots.yml" "$project_path/.github/workflows/constitution-ots.yml"
copy_file "$template_dir/.github/workflows/constitution-env.yml" "$project_path/.github/workflows/constitution-env.yml"
copy_file "$template_dir/.github/workflows/constitution-architecture.yml" "$project_path/.github/workflows/constitution-architecture.yml"
copy_file "$template_dir/.pre-commit-config.yaml" "$project_path/.pre-commit-config.yaml"
mkdir -p "$project_path/.devcontainer"
copy_file "$template_dir/.devcontainer/devcontainer.json" "$project_path/.devcontainer/devcontainer.json"
if ! write_generated_todo_from_backlog; then
  copy_file "$template_dir/TODO.md" "$project_path/TODO.md"
fi

if ! write_generated_changelog_from_release_notes; then
  copy_file "$template_dir/CHANGELOG.md" "$project_path/CHANGELOG.md"
fi

copy_file "$template_dir/VERSION" "$project_path/VERSION"

mkdir -p "$project_path/docs/adr"
copy_file "$template_dir/ADR.md" "$project_path/docs/adr/0001-record-architecture-decisions.md"

copy_file "$template_dir/docs/SETUP.md" "$project_path/docs/SETUP.md"
copy_file "$template_dir/docs/COMMAND_REFERENCE.md" "$project_path/docs/COMMAND_REFERENCE.md"
copy_file "$template_dir/docs/TROUBLESHOOTING.md" "$project_path/docs/TROUBLESHOOTING.md"
copy_file "$template_dir/docs/AGENT_PROMPTS.md" "$project_path/docs/AGENT_PROMPTS.md"
copy_file "$template_dir/docs/AGENT_HANDOFF.md" "$project_path/docs/AGENT_HANDOFF.md"
copy_file "$template_dir/docs/PRODUCT_REQUIREMENTS.md" "$project_path/docs/PRODUCT_REQUIREMENTS.md"
copy_file "$template_dir/docs/REQUIREMENTS_TRACEABILITY.md" "$project_path/docs/REQUIREMENTS_TRACEABILITY.md"
copy_file "$template_dir/docs/TEST_PLAN.md" "$project_path/docs/TEST_PLAN.md"
copy_file "$template_dir/docs/OTS_SOFTWARE.md" "$project_path/docs/OTS_SOFTWARE.md"
copy_file "$template_dir/docs/ENV_VARS.md" "$project_path/docs/ENV_VARS.md"
copy_file "$template_dir/docs/MVP_BACKLOG.md" "$project_path/docs/MVP_BACKLOG.md"
copy_file "$template_dir/docs/OPERATIONS.md" "$project_path/docs/OPERATIONS.md"
copy_file "$template_dir/docs/SESSION_PLAN.md" "$project_path/docs/SESSION_PLAN.md"
copy_file "$template_dir/docs/MEMORY.md" "$project_path/docs/MEMORY.md"
copy_file "$template_dir/docs/ARCHITECTURE.md" "$project_path/docs/ARCHITECTURE.md"

if [ ! -e "$project_path/README.md" ]; then
  copy_file "$template_dir/README.md" "$project_path/README.md"
elif [ "$force" = "true" ]; then
  copy_file "$template_dir/README.md" "$project_path/README.md"
else
  echo "Skipped existing file: $project_path/README.md"
  skipped_files+=("README.md")
  cp "$template_dir/README.md" "$bootstrap_dir/templates/README.md"
  echo "Wrote merge template: $bootstrap_dir/templates/README.md"
fi

# Standardize the adoption badge across every repository, including existing
# READMEs that were preserved above.
ensure_readme_badge

generate_adoption_report

echo "Bootstrap complete."
