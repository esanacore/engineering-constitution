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
    return
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "Wrote: $dest"
}

cd "$project_path"

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
fi

echo "Bootstrap complete."
