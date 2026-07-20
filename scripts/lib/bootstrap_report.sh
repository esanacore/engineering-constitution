# shellcheck shell=bash
#
# Adoption report generation and project detection for scripts/bootstrap.sh.
#
# Sourced, never executed. Reads the globals `project_path`, `bootstrap_dir`,
# `written_files`, `skipped_files`, and `modified_files`, calls `first_heading`
# from bootstrap.sh, and appends to `written_files`.
#
# The report is what a maintainer actually reads after adoption: what was
# written, what was skipped and why, what the repository looks like, and what
# to do next.
#
# Split from bootstrap.sh because it is the largest single concern in the
# original file and changes for its own reason -- improving what bootstrap
# detects or how it explains itself has nothing to do with which templates
# get copied.

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
