# shellcheck shell=bash
#
# Migration of pre-existing project artifacts for scripts/bootstrap.sh.
#
# Sourced, never executed. Reads the global `project_path` and appends to
# `written_files`.
#
# A repository adopting the constitution often already tracks its work
# somewhere -- a COPILOT_TASK_BACKLOG.md, a RELEASE_NOTES_*.md. These
# generators seed TODO.md and CHANGELOG.md from that existing content instead
# of overwriting it with an empty template, so adoption preserves history.
#
# Split from bootstrap.sh because it changes for its own reason: supporting a
# new legacy format is unrelated to the install manifest.

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
