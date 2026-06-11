#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/bootstrap.sh

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
bootstrap_script="$script_dir/bootstrap.sh"

# Use a temporary directory for testing
test_dir=$(mktemp -d)
echo "Running tests in: $test_dir"

cleanup() {
  rm -rf "$test_dir"
}
trap cleanup EXIT

# Setup a dummy constitution "remote" repository
# In reality, we use the current repo root as the source.
constitution_url="$repo_root"

test_new_project() {
  echo "Testing bootstrap on a new project..."
  project_path="$test_dir/new-project"
  mkdir -p "$project_path"
  cd "$project_path"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  git commit --allow-empty -m "Initial commit"

  "$bootstrap_script" "$project_path" "$constitution_url"

  # Verify files
  [ -d "constitution" ] || { echo "FAIL: constitution submodule missing"; exit 1; }
  [ -f "AGENTS.md" ] || { echo "FAIL: AGENTS.md missing"; exit 1; }
  [ -f "CLAUDE.md" ] || { echo "FAIL: CLAUDE.md missing"; exit 1; }
  [ -f ".agent-instructions.md" ] || { echo "FAIL: .agent-instructions.md missing"; exit 1; }
  [ -f ".cursorrules" ] || { echo "FAIL: .cursorrules missing"; exit 1; }
  [ -f "HELP.md" ] || { echo "FAIL: HELP.md missing"; exit 1; }
  [ -f "SECURITY.md" ] || { echo "FAIL: SECURITY.md missing"; exit 1; }
  [ -f ".github/copilot-instructions.md" ] || { echo "FAIL: copilot-instructions.md missing"; exit 1; }
  [ -f ".cursor/rules/project.mdc" ] || { echo "FAIL: project.mdc missing"; exit 1; }
  [ -f "TODO.md" ] || { echo "FAIL: TODO.md missing"; exit 1; }
  [ -f "CHANGELOG.md" ] || { echo "FAIL: CHANGELOG.md missing"; exit 1; }
  [ -f "docs/adr/0001-record-architecture-decisions.md" ] || { echo "FAIL: ADR missing"; exit 1; }
  [ -f "docs/SETUP.md" ] || { echo "FAIL: SETUP.md missing"; exit 1; }
  [ -f "docs/COMMAND_REFERENCE.md" ] || { echo "FAIL: COMMAND_REFERENCE.md missing"; exit 1; }
  [ -f "docs/TROUBLESHOOTING.md" ] || { echo "FAIL: TROUBLESHOOTING.md missing"; exit 1; }
  [ -f "docs/AGENT_PROMPTS.md" ] || { echo "FAIL: AGENT_PROMPTS.md missing"; exit 1; }
  [ -f "docs/AGENT_HANDOFF.md" ] || { echo "FAIL: AGENT_HANDOFF.md missing"; exit 1; }
  [ -f "docs/OPERATIONS.md" ] || { echo "FAIL: OPERATIONS.md missing"; exit 1; }
  [ -f "docs/ARCHITECTURE.md" ] || { echo "FAIL: ARCHITECTURE.md missing"; exit 1; }
  [ -f ".constitution-bootstrap/adoption-report.md" ] || { echo "FAIL: Adoption report missing"; exit 1; }

  echo "SUCCESS: New project bootstrap verified."
}

test_existing_files_preservation() {
  echo "Testing preservation of existing files..."
  project_path="$test_dir/existing-project"
  mkdir -p "$project_path"
  cd "$project_path"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  
  echo "# Original README" > README.md
  echo "# Original TODO" > TODO.md
  git add .
  git commit -m "Initial files"

  "$bootstrap_script" "$project_path" "$constitution_url"

  # Verify files were NOT overwritten
  grep -q "Original README" README.md || { echo "FAIL: README.md was overwritten"; exit 1; }
  grep -q "Original TODO" TODO.md || { echo "FAIL: TODO.md was overwritten"; exit 1; }

  # Verify merge templates were created
  [ -f ".constitution-bootstrap/templates/README.md" ] || { echo "FAIL: README.md merge template missing"; exit 1; }
  [ -f ".constitution-bootstrap/templates/TODO.md" ] || { echo "FAIL: TODO.md merge template missing"; exit 1; }

  echo "SUCCESS: Existing files preservation verified."
}

test_force_overwrite() {
  echo "Testing --force overwrite..."
  project_path="$test_dir/force-project"
  mkdir -p "$project_path"
  cd "$project_path"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  
  echo "# Original TODO" > TODO.md
  git add .
  git commit -m "Initial files"

  "$bootstrap_script" --force "$project_path" "$constitution_url"

  # Verify file WAS overwritten
  grep -q "Original TODO" TODO.md && { echo "FAIL: TODO.md was NOT overwritten with --force"; exit 1; }
  grep -q "# TODO" TODO.md || { echo "FAIL: TODO.md content is wrong after force"; exit 1; }

  echo "SUCCESS: --force overwrite verified."
}

test_migration_from_backlog() {
  echo "Testing migration from COPILOT_TASK_BACKLOG.md..."
  project_path="$test_dir/backlog-project"
  mkdir -p "$project_path"
  cd "$project_path"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  
  cat <<'EOF' > COPILOT_TASK_BACKLOG.md
### 1. Fix the flux capacitor
### 2. Update the flux pulse
EOF
  git add .
  git commit -m "Initial backlog"

  "$bootstrap_script" "$project_path" "$constitution_url"

  # Verify TODO.md was generated from backlog
  grep -q "Fix the flux capacitor" TODO.md || { echo "FAIL: TODO.md does not contain backlog items"; exit 1; }
  grep -q "Update the flux pulse" TODO.md || { echo "FAIL: TODO.md does not contain backlog items"; exit 1; }

  echo "SUCCESS: Backlog migration verified."
}

# Run tests
test_new_project
test_existing_files_preservation
test_force_overwrite
test_migration_from_backlog

echo "ALL TESTS PASSED"
