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

# Resolve the URL the README badge should link to. Prefer the bootstrap source
# when it is a public Git URL; otherwise fall back to the canonical repository so
# local-path sources (used in tests) still produce a working link.
badge_link() {
  case "$constitution_url" in
    https://*|http://*)
      printf '%s' "${constitution_url%.git}"
      ;;
    *)
      printf '%s' "$constitution_repo_url"
      ;;
  esac
}

# The single source of truth for the badge markup. Kept in sync with
# templates/README.md so freshly generated and existing READMEs match.
readme_badge_line() {
  printf "[![Eric's Engineering Constitution](https://img.shields.io/badge/Eric's%%20Engineering%%20Constitution-Adopted-blue)](%s)" "$(badge_link)"
}

# Add or refresh the constitution badge in the project README. The badge lives
# between stable HTML comment markers so this is idempotent: re-running bootstrap
# never duplicates the badge, and the link is refreshed in place. When the README
# has no markers yet, the badge is inserted just after the first level-one
# heading, or prepended if the file has no heading.
ensure_readme_badge() {
  readme="$project_path/README.md"

  if [ ! -f "$readme" ]; then
    return 0
  fi

  badge=$(readme_badge_line)
  tmp=$(mktemp)

  if grep -q "CONSTITUTION_START" "$readme"; then
    awk -v badge="$badge" '
      /<!-- CONSTITUTION_START -->/ {
        print "<!-- CONSTITUTION_START -->"
        print badge
        print "<!-- CONSTITUTION_END -->"
        skip = 1
        next
      }
      /<!-- CONSTITUTION_END -->/ { skip = 0; next }
      skip != 1 { print }
    ' "$readme" > "$tmp"
    mv "$tmp" "$readme"
    modified_files+=("README.md")
    echo "Refreshed Eric's Engineering Constitution badge in README.md"
    return 0
  fi

  awk -v badge="$badge" '
    BEGIN { inserted = 0 }
    {
      print
      if (inserted == 0 && $0 ~ /^# /) {
        print ""
        print "<!-- CONSTITUTION_START -->"
        print badge
        print "<!-- CONSTITUTION_END -->"
        inserted = 1
      }
    }
  ' "$readme" > "$tmp"

  if ! grep -q "CONSTITUTION_START" "$tmp"; then
    {
      echo "<!-- CONSTITUTION_START -->"
      printf '%s\n' "$badge"
      echo "<!-- CONSTITUTION_END -->"
      echo
      cat "$readme"
    } > "$tmp"
  fi

  mv "$tmp" "$readme"
  modified_files+=("README.md")
  echo "Added Eric's Engineering Constitution badge to README.md"
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

status_line() {
  file=$1

  if [ -e "$project_path/$file" ]; then
    echo "- [x] $file exists"
  else
    echo "- [ ] $file is missing"
  fi
}

detect_file() {
  file=$1
  label=$2

  if [ -e "$project_path/$file" ]; then
    echo "- $label: \`$file\`"
  fi
}

detect_make_targets() {
  if [ ! -f "$project_path/Makefile" ]; then
    return
  fi

  targets=$(sed -n 's/^\([A-Za-z0-9_.-][A-Za-z0-9_.-]*\):.*/\1/p' "$project_path/Makefile" | head -n 12 | tr '\n' ' ')

  if [ -n "$targets" ]; then
    echo "- Make targets detected: $targets"
  fi
}

write_list() {
  if [ "$#" -eq 0 ]; then
    echo "- None"
    return
  fi

  for item in "$@"; do
    echo "- \`$item\`"
  done
}

write_generated_todo_from_backlog() {
  dest="$project_path/TODO.md"
  backlog="$project_path/COPILOT_TASK_BACKLOG.md"

  if [ ! -f "$backlog" ]; then
    return 1
  fi

  if [ -e "$dest" ] && [ "$force" != "true" ]; then
    return 1
  fi

  {
    echo "# TODO"
    echo
    echo "This file is the living roadmap for the project."
    echo
    echo "It was initialized from \`COPILOT_TASK_BACKLOG.md\` during Eric's Engineering Constitution adoption. Keep entries specific, actionable, and current."
    echo
    echo "## Features"
    echo
    sed -n 's/^### [0-9][0-9]*\. \(.*\)$/- [ ] \1./p' "$backlog"
    echo
    echo "## Technical Debt"
    echo
    echo "- [ ] Review existing project documentation for technical debt that should be tracked here."
    echo
    echo "## Refactoring"
    echo
    echo "- [ ] Move refactoring items from \`COPILOT_TASK_BACKLOG.md\` into this section as they are prioritized."
    echo
    echo "## Testing"
    echo
    echo "- [ ] Move test coverage items from \`COPILOT_TASK_BACKLOG.md\` into this section as they are prioritized."
    echo
    echo "## Documentation"
    echo
    echo "- [ ] Keep \`COPILOT_TASK_BACKLOG.md\` aligned with this TODO file or retire it after migration."
    echo
    echo "## Nice-to-Have"
    echo
    echo "- [ ] Move future enhancements from \`COPILOT_TASK_BACKLOG.md\` into this section as they are prioritized."
  } > "$dest"

  written_files+=("${dest#$project_path/}")
  echo "Generated TODO.md from COPILOT_TASK_BACKLOG.md"
  return 0
}

write_generated_changelog_from_release_notes() {
  dest="$project_path/CHANGELOG.md"
  notes=$(find "$project_path" -maxdepth 1 -type f -name 'RELEASE_NOTES*.md' | sort | head -n 1)

  if [ -z "$notes" ]; then
    return 1
  fi

  if [ -e "$dest" ] && [ "$force" != "true" ]; then
    return 1
  fi

  release_name=$(basename "$notes" .md)
  release_version=$(printf '%s\n' "$release_name" | sed 's/^RELEASE_NOTES_//; s/^v//')

  if [ -n "$release_version" ] && [ "$release_version" != "$release_name" ]; then
    release_heading="$release_version - Imported from ${notes#$project_path/}"
  else
    release_heading="Imported from ${notes#$project_path/}"
  fi

  {
    echo "# Changelog"
    echo
    echo "All notable user-facing changes to this project should be documented in this file."
    echo
    echo "This project follows semantic versioning."
    echo
    echo "## Unreleased"
    echo
    echo "### Added"
    echo
    echo "### Changed"
    echo
    echo "### Fixed"
    echo
    echo "### Removed"
    echo
    echo "### Security"
    echo
    echo "## $release_heading"
    echo
    sed '1d; 2{/^$/d;}' "$notes"
  } > "$dest"

  written_files+=("${dest#$project_path/}")
  echo "Generated CHANGELOG.md from ${notes#$project_path/}"
  return 0
}

generate_adoption_report() {
  report="$bootstrap_dir/adoption-report.md"

  if [ -e "$report" ] && [ "$force" != "true" ]; then
    report="$bootstrap_dir/adoption-report-$(date +%Y%m%d%H%M%S).md"
  fi

  project_name=$(first_heading "$project_path/README.md")

  {
    echo "# Eric's Engineering Constitution Adoption Report"
    echo
    echo "Project: $project_name"
    echo
    echo "Project path: \`$project_path\`"
    echo
    echo "Constitution source: \`$constitution_url\`"
    echo
    echo "## What Happened"
    echo
    echo "The bootstrap script installed Eric's Engineering Constitution in a non-destructive mode."
    echo
    echo "Existing project files were not overwritten. When a target file already existed, the matching constitution template was copied into \`.constitution-bootstrap/templates/\` so maintainers can compare and merge manually."
    echo
    echo "## Current Governance Files"
    echo
    status_line "README.md"
    status_line "AGENTS.md"
    if wants_agent claude; then
      status_line "CLAUDE.md"
      status_line ".claude/settings.json"
    fi
    if wants_agent cursor; then
      status_line ".cursorrules"
      status_line ".cursor/rules/project.mdc"
    fi
    if wants_agent copilot; then
      status_line ".github/copilot-instructions.md"
    fi
    if wants_agent goose; then
      status_line ".goosehints"
    fi
    if wants_agent openhands; then
      status_line ".openhands_instructions"
    fi
    if wants_agent antigravity; then
      status_line ".antigravity/instructions.md"
    fi
    if wants_agent continue; then
      status_line ".continue/config.json"
    fi
    if wants_agent aider; then
      status_line ".aider.conf.yml"
      status_line ".aiderignore"
    fi
    if wants_agent generic; then
      status_line ".agent-instructions.md"
      status_line ".project-rules.md"
      status_line "docs/SYSTEM_PROMPT.md"
    fi
    status_line ".github/CONTRIBUTING.md"
    status_line ".github/SECURITY.md"
    status_line "docs/HELP.md"
    status_line ".github/agents/solon.agent.md"
    status_line ".github/dependabot.yml"
    status_line ".github/workflows/constitution-version.yml"
    status_line ".github/workflows/constitution-compliance.yml"
    status_line ".github/workflows/constitution-tests.yml"
    status_line ".github/workflows/constitution-doc-freshness.yml"
    status_line ".github/workflows/constitution-secrets.yml"
    status_line ".github/workflows/constitution-ots.yml"
    status_line ".github/workflows/constitution-env.yml"
    status_line ".github/workflows/constitution-architecture.yml"
    status_line ".pre-commit-config.yaml"
    status_line ".devcontainer/devcontainer.json"
    status_line "TODO.md"
    status_line "CHANGELOG.md"
    status_line "VERSION"
    status_line "docs/adr"
    status_line "docs/SETUP.md"
    status_line "docs/COMMAND_REFERENCE.md"
    status_line "docs/TROUBLESHOOTING.md"
    status_line "docs/AGENT_PROMPTS.md"
    status_line "docs/AGENT_HANDOFF.md"
    status_line "docs/PRODUCT_REQUIREMENTS.md"
    status_line "docs/REQUIREMENTS_TRACEABILITY.md"
    status_line "docs/TEST_PLAN.md"
    status_line "docs/OTS_SOFTWARE.md"
    status_line "docs/ENV_VARS.md"
    status_line "docs/MVP_BACKLOG.md"
    status_line "docs/OPERATIONS.md"
    status_line "docs/SESSION_PLAN.md"
    status_line "docs/MEMORY.md"
    status_line "docs/ARCHITECTURE.md"
    echo
    echo "## Files Written"
    echo
    write_list " ${written_files[@]}"
    echo
    echo "## Existing Files Preserved"
    echo
    write_list " ${skipped_files[@]}"
    echo
    echo "## Files Updated In Place"
    echo
    if [ "${#modified_files[@]}" -eq 0 ]; then
      echo "- None"
    else
      for item in "${modified_files[@]}"; do
        echo "- \`$item\`"
      done
    fi
    echo
    echo "## Detected Project Signals"
    echo
    detect_file "package.json" "Node.js package metadata"
    detect_file "pyproject.toml" "Python project metadata"
    detect_file "requirements.txt" "Python requirements"
    detect_file "Cargo.toml" "Rust package metadata"
    detect_file "go.mod" "Go module metadata"
    detect_file "pom.xml" "Maven project metadata"
    detect_file "build.gradle" "Gradle build file"
    detect_file "Makefile" "Makefile"
    detect_file "Dockerfile" "Dockerfile"
    detect_file "docker-compose.yml" "Docker Compose configuration"
    detect_file ".github/workflows" "GitHub Actions workflows"
    detect_file "COPILOT_TASK_BACKLOG.md" "Existing backlog candidate for TODO.md"
    detect_file "RELEASE_NOTES_v0.1.0.md" "Existing release notes candidate for CHANGELOG.md"
    detect_make_targets
    echo
    echo "## Recommended Merge Steps"
    echo
    echo "1. Compare existing files with templates in \`.constitution-bootstrap/templates/\`."
    echo "2. Merge relevant Eric's Engineering Constitution sections into existing project files."
    echo "3. Customize generated placeholders in TODO.md, CHANGELOG.md, README.md, and ADRs."
    echo "4. Commit \`.gitmodules\`, the \`constitution\` submodule reference, generated files, and any merged documentation changes."
    echo "5. Keep or remove \`.constitution-bootstrap/\` depending on whether the adoption report is useful to the project."
    echo "6. In the hosting platform settings, enable \"Automatically delete head branches\" and branch protection on the default branch. See \`constitution/INTEGRATION.md\` (Repository Settings Checklist)."
    echo
    echo "## Recommended Tool Setup"
    echo
    echo "Run these once after completing the merge steps above:"
    echo
    echo "**In Claude Code:**"
    echo "- \`/setup-gbrain\` — Initialize the gstack project brain for persistent memory across sessions."
    echo "- \`/setup-deploy\` — Configure deployment targets if this project has a deployment pipeline."
    echo
    echo "**In your terminal:**"
    echo "- \`pip install pre-commit && pre-commit install && pre-commit install --hook-type pre-push\` — Activate the pre-commit hooks installed at \`.pre-commit-config.yaml\`, including the pre-push secrets sweep (\`constitution/scripts/check_secrets.sh\`)."
    echo "- \`npm install\` in \`constitution/mcp-server/\` — Prepare the constitution MCP server dependency if you plan to register it with Goose or Claude Code."
    echo
    echo "See \`constitution/INTEGRATION.md\` for full setup details: gstack skills, gbrain initialization, Continue.dev, Aider, devcontainer, and MCP server registration."
    echo
    echo "## Suggested Agent Context"
    echo
    echo "Add or verify these instructions in AGENTS.md:"
    echo
    echo "- Read \`constitution/CONSTITUTION.md\` before making changes."
    echo "- Read \`README.md\`, \`TODO.md\`, and \`CHANGELOG.md\` for project context."
    echo "- Update tests, docs, TODO.md, and CHANGELOG.md when relevant."
    echo "- Record major design decisions in \`docs/adr/\`."
    echo "- See \`constitution/INTEGRATION.md\` for override patterns and update instructions."
  } > "$report"

  written_files+=("${report#$project_path/}")
  echo "Wrote adoption report: $report"
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
