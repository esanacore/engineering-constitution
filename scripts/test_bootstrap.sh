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
  [ -f ".antigravity/instructions.md" ] || { echo "FAIL: .antigravity/instructions.md missing"; exit 1; }
  [ -f ".openhands_instructions" ] || { echo "FAIL: .openhands_instructions missing"; exit 1; }
  [ -f ".goosehints" ] || { echo "FAIL: .goosehints missing"; exit 1; }
  [ -f ".project-rules.md" ] || { echo "FAIL: .project-rules.md missing"; exit 1; }
  [ -f "SYSTEM_PROMPT.md" ] || { echo "FAIL: SYSTEM_PROMPT.md missing"; exit 1; }
  [ -f "CONTRIBUTING.md" ] || { echo "FAIL: CONTRIBUTING.md missing"; exit 1; }
  [ -f "HELP.md" ] || { echo "FAIL: HELP.md missing"; exit 1; }
  [ -f "SECURITY.md" ] || { echo "FAIL: SECURITY.md missing"; exit 1; }
  [ -f ".github/copilot-instructions.md" ] || { echo "FAIL: copilot-instructions.md missing"; exit 1; }
  [ -f ".github/agents/solon.agent.md" ] || { echo "FAIL: solon.agent.md missing"; exit 1; }
  [ -f ".github/dependabot.yml" ] || { echo "FAIL: dependabot.yml missing"; exit 1; }
  [ -f ".github/workflows/constitution-version.yml" ] || { echo "FAIL: constitution-version.yml workflow missing"; exit 1; }
  [ -f ".github/workflows/constitution-compliance.yml" ] || { echo "FAIL: constitution-compliance.yml workflow missing"; exit 1; }
  [ -f ".github/workflows/constitution-tests.yml" ] || { echo "FAIL: constitution-tests.yml workflow missing"; exit 1; }
  [ -f ".github/workflows/constitution-doc-freshness.yml" ] || { echo "FAIL: constitution-doc-freshness.yml workflow missing"; exit 1; }
  [ -f ".github/workflows/constitution-secrets.yml" ] || { echo "FAIL: constitution-secrets.yml workflow missing"; exit 1; }
  [ -f ".github/workflows/constitution-ots.yml" ] || { echo "FAIL: constitution-ots.yml workflow missing"; exit 1; }
  [ -f ".cursor/rules/project.mdc" ] || { echo "FAIL: project.mdc missing"; exit 1; }
  [ -f "TODO.md" ] || { echo "FAIL: TODO.md missing"; exit 1; }
  [ -f "CHANGELOG.md" ] || { echo "FAIL: CHANGELOG.md missing"; exit 1; }
  [ -f "VERSION" ] || { echo "FAIL: VERSION missing"; exit 1; }
  [ -f "docs/adr/0001-record-architecture-decisions.md" ] || { echo "FAIL: ADR missing"; exit 1; }
  [ -f "docs/SETUP.md" ] || { echo "FAIL: SETUP.md missing"; exit 1; }
  [ -f "docs/COMMAND_REFERENCE.md" ] || { echo "FAIL: COMMAND_REFERENCE.md missing"; exit 1; }
  [ -f "docs/TROUBLESHOOTING.md" ] || { echo "FAIL: TROUBLESHOOTING.md missing"; exit 1; }
  [ -f "docs/AGENT_PROMPTS.md" ] || { echo "FAIL: AGENT_PROMPTS.md missing"; exit 1; }
  [ -f "docs/AGENT_HANDOFF.md" ] || { echo "FAIL: AGENT_HANDOFF.md missing"; exit 1; }
  [ -f "docs/PRODUCT_REQUIREMENTS.md" ] || { echo "FAIL: PRODUCT_REQUIREMENTS.md missing"; exit 1; }
  [ -f "docs/REQUIREMENTS_TRACEABILITY.md" ] || { echo "FAIL: REQUIREMENTS_TRACEABILITY.md missing"; exit 1; }
  [ -f "docs/TEST_PLAN.md" ] || { echo "FAIL: TEST_PLAN.md missing"; exit 1; }
  [ -f "docs/OTS_SOFTWARE.md" ] || { echo "FAIL: OTS_SOFTWARE.md missing"; exit 1; }
  [ -f "docs/MVP_BACKLOG.md" ] || { echo "FAIL: MVP_BACKLOG.md missing"; exit 1; }
  [ -f "docs/OPERATIONS.md" ] || { echo "FAIL: OPERATIONS.md missing"; exit 1; }
  [ -f "docs/SESSION_PLAN.md" ] || { echo "FAIL: SESSION_PLAN.md missing"; exit 1; }
  [ -f "docs/ARCHITECTURE.md" ] || { echo "FAIL: ARCHITECTURE.md missing"; exit 1; }
  [ -f ".claude/settings.json" ] || { echo "FAIL: .claude/settings.json missing"; exit 1; }
  grep -q "check_constitution_freshness.sh" ".claude/settings.json" || { echo "FAIL: .claude/settings.json missing SessionStart freshness hook"; exit 1; }
  [ -f ".constitution-bootstrap/adoption-report.md" ] || { echo "FAIL: Adoption report missing"; exit 1; }

  # Verify requirement traceability wiring
  grep -q "FR-001" docs/PRODUCT_REQUIREMENTS.md || { echo "FAIL: PRODUCT_REQUIREMENTS.md missing requirement IDs"; exit 1; }
  grep -q "Requirements Traceability Matrix" docs/REQUIREMENTS_TRACEABILITY.md || { echo "FAIL: REQUIREMENTS_TRACEABILITY.md missing matrix heading"; exit 1; }
  grep -q "Coverage Gap Log" docs/TEST_PLAN.md || { echo "FAIL: TEST_PLAN.md missing coverage gap log"; exit 1; }
  grep -q "OTS Software Inventory" docs/OTS_SOFTWARE.md || { echo "FAIL: OTS_SOFTWARE.md missing inventory heading"; exit 1; }

  # Verify the standardized constitution badge is present
  grep -q "CONSTITUTION_START" README.md || { echo "FAIL: README.md missing constitution badge markers"; exit 1; }
  grep -q "Eric's Engineering Constitution" README.md || { echo "FAIL: README.md missing constitution badge"; exit 1; }

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

  # The badge is added even though the README content was preserved
  grep -q "CONSTITUTION_START" README.md || { echo "FAIL: badge not injected into preserved README.md"; exit 1; }

  echo "SUCCESS: Existing files preservation verified."
}

test_badge_injection() {
  echo "Testing constitution badge injection..."
  project_path="$test_dir/badge-project"
  mkdir -p "$project_path"
  cd "$project_path"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  printf '# My Project\n\nSome description.\n' > README.md
  git add .
  git commit -m "Initial files"

  "$bootstrap_script" "$project_path" "$constitution_url"

  # Badge is inserted after the first heading, original content preserved
  grep -q "My Project" README.md || { echo "FAIL: original README content lost"; exit 1; }
  grep -q "Some description." README.md || { echo "FAIL: original README content lost"; exit 1; }
  grep -q "CONSTITUTION_START" README.md || { echo "FAIL: badge markers not added"; exit 1; }
  grep -q "Eric's Engineering Constitution" README.md || { echo "FAIL: badge not added"; exit 1; }

  # The badge appears directly under the heading
  head -n 3 README.md | grep -q "CONSTITUTION_START" || { echo "FAIL: badge not placed under heading"; exit 1; }

  # Re-running bootstrap must not duplicate the badge (idempotency)
  "$bootstrap_script" "$project_path" "$constitution_url"
  count=$(grep -c "CONSTITUTION_START" README.md)
  [ "$count" -eq 1 ] || { echo "FAIL: badge duplicated on re-run (found $count)"; exit 1; }

  echo "SUCCESS: Badge injection verified."
}

test_badge_no_heading() {
  echo "Testing badge injection with no heading..."
  project_path="$test_dir/badge-noheading-project"
  mkdir -p "$project_path"
  cd "$project_path"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  printf 'Just a plain description with no heading.\n' > README.md
  git add .
  git commit -m "Initial files"

  "$bootstrap_script" "$project_path" "$constitution_url"

  # Badge prepended when there is no heading, original content preserved
  head -n 1 README.md | grep -q "CONSTITUTION_START" || { echo "FAIL: badge not prepended when no heading"; exit 1; }
  grep -q "plain description" README.md || { echo "FAIL: original README content lost"; exit 1; }

  echo "SUCCESS: Badge injection without heading verified."
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

  cat <<'BACKLOG_EOF' > COPILOT_TASK_BACKLOG.md
### 1. Fix the flux capacitor
### 2. Update the flux pulse
BACKLOG_EOF
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
test_badge_injection
test_badge_no_heading
test_force_overwrite
test_migration_from_backlog

echo "ALL TESTS PASSED"
