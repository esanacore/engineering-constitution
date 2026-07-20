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
  [ -f ".github/CONTRIBUTING.md" ] || { echo "FAIL: .github/CONTRIBUTING.md missing"; exit 1; }
  [ -f "docs/HELP.md" ] || { echo "FAIL: docs/HELP.md missing"; exit 1; }
  [ -f ".github/SECURITY.md" ] || { echo "FAIL: .github/SECURITY.md missing"; exit 1; }
  [ -f ".github/agents/solon.agent.md" ] || { echo "FAIL: solon.agent.md missing"; exit 1; }

  # Vendor instruction files are opt-in: a default bootstrap installs AGENTS.md
  # only, so the adopting repository's root listing stays short.
  for vendor_file in CLAUDE.md .cursorrules .goosehints .openhands_instructions \
                     .project-rules.md .agent-instructions.md .aider.conf.yml \
                     .aiderignore SYSTEM_PROMPT.md docs/SYSTEM_PROMPT.md \
                     .github/copilot-instructions.md .antigravity/instructions.md \
                     .continue/config.json .claude/settings.json; do
    if [ -e "$vendor_file" ]; then
      echo "FAIL: $vendor_file installed without --agents"
      exit 1
    fi
  done
  [ -f ".github/dependabot.yml" ] || { echo "FAIL: dependabot.yml missing"; exit 1; }
  [ -f ".github/workflows/constitution-version.yml" ] || { echo "FAIL: constitution-version.yml workflow missing"; exit 1; }
  [ -f ".github/workflows/constitution-compliance.yml" ] || { echo "FAIL: constitution-compliance.yml workflow missing"; exit 1; }
  [ -f ".github/workflows/constitution-tests.yml" ] || { echo "FAIL: constitution-tests.yml workflow missing"; exit 1; }
  [ -f ".github/workflows/constitution-doc-freshness.yml" ] || { echo "FAIL: constitution-doc-freshness.yml workflow missing"; exit 1; }
  [ -f ".github/workflows/constitution-secrets.yml" ] || { echo "FAIL: constitution-secrets.yml workflow missing"; exit 1; }
  [ -f ".github/workflows/constitution-ots.yml" ] || { echo "FAIL: constitution-ots.yml workflow missing"; exit 1; }
  [ -f ".github/workflows/constitution-env.yml" ] || { echo "FAIL: constitution-env.yml workflow missing"; exit 1; }
  [ -f ".github/workflows/constitution-architecture.yml" ] || { echo "FAIL: constitution-architecture.yml workflow missing"; exit 1; }
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
  [ -f "docs/ENV_VARS.md" ] || { echo "FAIL: ENV_VARS.md missing"; exit 1; }
  [ -f "docs/MVP_BACKLOG.md" ] || { echo "FAIL: MVP_BACKLOG.md missing"; exit 1; }
  [ -f "docs/OPERATIONS.md" ] || { echo "FAIL: OPERATIONS.md missing"; exit 1; }
  [ -f "docs/SESSION_PLAN.md" ] || { echo "FAIL: SESSION_PLAN.md missing"; exit 1; }
  [ -f "docs/MEMORY.md" ] || { echo "FAIL: MEMORY.md missing"; exit 1; }
  [ -f "docs/ARCHITECTURE.md" ] || { echo "FAIL: ARCHITECTURE.md missing"; exit 1; }
  [ -f ".constitution-bootstrap/adoption-report.md" ] || { echo "FAIL: Adoption report missing"; exit 1; }
  # Verify requirement traceability wiring
  grep -q "FR-001" docs/PRODUCT_REQUIREMENTS.md || { echo "FAIL: PRODUCT_REQUIREMENTS.md missing requirement IDs"; exit 1; }
  grep -q "Requirements Traceability Matrix" docs/REQUIREMENTS_TRACEABILITY.md || { echo "FAIL: REQUIREMENTS_TRACEABILITY.md missing matrix heading"; exit 1; }
  grep -q "Coverage Gap Log" docs/TEST_PLAN.md || { echo "FAIL: TEST_PLAN.md missing coverage gap log"; exit 1; }
  grep -q "OTS Software Inventory" docs/OTS_SOFTWARE.md || { echo "FAIL: OTS_SOFTWARE.md missing inventory heading"; exit 1; }
  grep -q "Environment & Configuration Contract" docs/ENV_VARS.md || { echo "FAIL: ENV_VARS.md missing contract heading"; exit 1; }
  grep -q "Layer Boundaries" docs/ARCHITECTURE.md || { echo "FAIL: ARCHITECTURE.md missing Layer Boundaries section"; exit 1; }
  # The shipped layer table is commented out so a fresh adopter is not failed by
  # a template's example paths; check_architecture.sh must treat it as absent.
  bash "$repo_root/scripts/check_architecture.sh" --strict . >/dev/null 2>&1 || { echo "FAIL: fresh bootstrap does not pass check_architecture.sh --strict"; exit 1; }

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

# Create an empty committed Git repository for a bootstrap run.
make_repo() {
  path=$1
  mkdir -p "$path"
  cd "$path"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  git commit --allow-empty -qm "Initial commit"
}

test_agents_selection() {
  echo "Testing --agents vendor selection..."

  # A named subset installs that vendor's files and no others.
  project_path="$test_dir/agents-subset"
  make_repo "$project_path"
  "$bootstrap_script" --agents=claude,cursor "$project_path" "$constitution_url" >/dev/null

  [ -f "CLAUDE.md" ] || { echo "FAIL: --agents=claude did not install CLAUDE.md"; exit 1; }
  [ -f ".claude/settings.json" ] || { echo "FAIL: --agents=claude did not install .claude/settings.json"; exit 1; }
  grep -q "check_constitution_freshness.sh" ".claude/settings.json" || { echo "FAIL: .claude/settings.json missing SessionStart freshness hook"; exit 1; }
  [ -f ".cursorrules" ] || { echo "FAIL: --agents=cursor did not install .cursorrules"; exit 1; }
  [ -f ".cursor/rules/project.mdc" ] || { echo "FAIL: --agents=cursor did not install project.mdc"; exit 1; }

  for unwanted in .goosehints .openhands_instructions .aider.conf.yml \
                  .github/copilot-instructions.md .project-rules.md; do
    if [ -e "$unwanted" ]; then
      echo "FAIL: $unwanted installed for --agents=claude,cursor"
      exit 1
    fi
  done

  # --agents=all restores the pre-1.38.0 behavior.
  project_path="$test_dir/agents-all"
  make_repo "$project_path"
  "$bootstrap_script" --agents=all "$project_path" "$constitution_url" >/dev/null

  for expected in CLAUDE.md .cursorrules .goosehints .openhands_instructions \
                  .project-rules.md .agent-instructions.md .aider.conf.yml \
                  .aiderignore docs/SYSTEM_PROMPT.md .continue/config.json \
                  .github/copilot-instructions.md .antigravity/instructions.md; do
    [ -e "$expected" ] || { echo "FAIL: --agents=all did not install $expected"; exit 1; }
  done

  # An unrecognized key is a usage error rather than a silent no-op.
  project_path="$test_dir/agents-bogus"
  make_repo "$project_path"
  set +e
  "$bootstrap_script" --agents=bogus "$project_path" "$constitution_url" >/dev/null 2>&1
  status=$?
  set -e
  [ "$status" -eq 2 ] || { echo "FAIL: expected exit 2 for an unknown --agents key, got $status"; exit 1; }

  echo "SUCCESS: --agents vendor selection verified."
}

# Run tests
test_new_project
test_agents_selection
test_existing_files_preservation
test_badge_injection
test_badge_no_heading
test_force_overwrite
test_migration_from_backlog

echo "ALL TESTS PASSED"
