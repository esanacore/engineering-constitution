#!/usr/bin/env bash
set -euo pipefail

# Bootstrap an existing Git repository with the Engineering Constitution.
#
# The constitution itself is installed as a Git submodule so projects can update
# universal rules without copying framework files by hand. Local project files
# are generated from templates and are skipped by default when they already
# exist, which makes the script safe to run against established repositories.

usage() {
  cat <<'USAGE'
Usage:
  bootstrap.sh [--force] <project-path> <constitution-repository-url>

Description:
  Initialize an existing Git repository with the Engineering Constitution.

Creates or installs:
  - constitution Git submodule
  - AGENTS.md
  - CLAUDE.md
  - COPILOT_INSTRUCTIONS.md
  - TODO.md
  - CHANGELOG.md
  - docs/adr/
  - docs/adr/0001-record-architecture-decisions.md
  - .constitution-bootstrap/adoption-report.md
  - .constitution-bootstrap/templates/ for skipped existing files

Options:
  --force   Overwrite existing generated files.
USAGE
}

force=false

if [ "${1:-}" = "--force" ]; then
  force=true
  shift
fi

if [ "$#" -ne 2 ]; then
  usage
  exit 1
fi

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

generate_adoption_report() {
  report="$bootstrap_dir/adoption-report.md"

  if [ -e "$report" ] && [ "$force" != "true" ]; then
    report="$bootstrap_dir/adoption-report-$(date +%Y%m%d%H%M%S).md"
  fi

  project_name=$(first_heading "$project_path/README.md")

  {
    echo "# Engineering Constitution Adoption Report"
    echo
    echo "Project: $project_name"
    echo
    echo "Project path: \`$project_path\`"
    echo
    echo "Constitution source: \`$constitution_url\`"
    echo
    echo "## What Happened"
    echo
    echo "The bootstrap script installed the Engineering Constitution in a non-destructive mode."
    echo
    echo "Existing project files were not overwritten. When a target file already existed, the matching constitution template was copied into \`.constitution-bootstrap/templates/\` so maintainers can compare and merge manually."
    echo
    echo "## Current Governance Files"
    echo
    status_line "README.md"
    status_line "AGENTS.md"
    status_line "CLAUDE.md"
    status_line "COPILOT_INSTRUCTIONS.md"
    status_line "TODO.md"
    status_line "CHANGELOG.md"
    status_line "docs/adr"
    echo
    echo "## Files Written"
    echo
    write_list "${written_files[@]}"
    echo
    echo "## Existing Files Preserved"
    echo
    write_list "${skipped_files[@]}"
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
    detect_make_targets
    echo
    echo "## Recommended Merge Steps"
    echo
    echo "1. Compare existing files with templates in \`.constitution-bootstrap/templates/\`."
    echo "2. Merge relevant Engineering Constitution sections into existing project files."
    echo "3. Customize generated placeholders in TODO.md, CHANGELOG.md, README.md, and ADRs."
    echo "4. Commit \`.gitmodules\`, the \`constitution\` submodule reference, generated files, and any merged documentation changes."
    echo "5. Keep or remove \`.constitution-bootstrap/\` depending on whether the adoption report is useful to the project."
    echo
    echo "## Suggested Agent Context"
    echo
    echo "Add or verify these instructions in AGENTS.md:"
    echo
    echo "- Read \`constitution/CONSTITUTION.md\` before making changes."
    echo "- Read \`README.md\`, \`TODO.md\`, and \`CHANGELOG.md\` for project context."
    echo "- Update tests, docs, TODO.md, and CHANGELOG.md when relevant."
    echo "- Record major design decisions in \`docs/adr/\`."
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
  git submodule add "$constitution_url" constitution
  echo "Added constitution submodule: $constitution_url"
fi

copy_file "$template_dir/AGENTS.md" "$project_path/AGENTS.md"
copy_file "$template_dir/CLAUDE.md" "$project_path/CLAUDE.md"
copy_file "$template_dir/COPILOT_INSTRUCTIONS.md" "$project_path/COPILOT_INSTRUCTIONS.md"
copy_file "$template_dir/TODO.md" "$project_path/TODO.md"
copy_file "$template_dir/CHANGELOG.md" "$project_path/CHANGELOG.md"

mkdir -p "$project_path/docs/adr"
copy_file "$template_dir/ADR.md" "$project_path/docs/adr/0001-record-architecture-decisions.md"

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

generate_adoption_report

echo "Bootstrap complete."
