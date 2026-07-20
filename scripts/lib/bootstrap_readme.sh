# shellcheck shell=bash
#
# README badge management for scripts/bootstrap.sh.
#
# Sourced, never executed. Reads the globals `constitution_url`,
# `constitution_repo_url`, and `project_path`, and appends to `modified_files`.
#
# Split from bootstrap.sh because it changes for its own reason: the badge
# markup and the URL it points at are a presentation decision, independent of
# which files bootstrap installs.

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
