#!/usr/bin/env bash
# Dependabot ecosystem generation for scripts/bootstrap.sh.
#
# Dependabot cannot discover manifests on its own: every ecosystem it should
# watch needs an `updates:` entry naming a directory. The shipped template
# covers the constitution submodule and the SHA-pinned actions; this adds one
# entry per dependency manifest found at the project root, so an adopter's
# npm, pip, Cargo, Go, Maven, Gradle, Swift, Bundler, Composer, or Docker
# dependencies get the same reviewable update pull requests. Root only:
# manifests in subdirectories are the adopter's to add (see
# constitution/INTEGRATION.md, "Keeping Adopters On the Latest Version").
#
# This file contains definitions only; it is sourced, never executed.

# Print "ecosystem<TAB>manifest" for every manifest at the root, in a fixed
# order; the first manifest listed for an ecosystem is the one reported. A
# pyproject.toml counts only when it declares dependencies ([project] or
# [tool.poetry]); one that only configures tools is skipped.
dependabot_ecosystems() {
  local root=$1
  local spec eco files f
  for spec in \
    "npm:package.json" \
    "pip:requirements.txt pyproject.toml Pipfile setup.py setup.cfg" \
    "cargo:Cargo.toml" \
    "gomod:go.mod" \
    "maven:pom.xml" \
    "gradle:build.gradle build.gradle.kts" \
    "swift:Package.swift" \
    "bundler:Gemfile" \
    "composer:composer.json" \
    "docker:Dockerfile"; do
    eco=${spec%%:*}
    files=${spec#*:}
    for f in $files; do   # $files is a literal, space-separated list
      [ -f "$root/$f" ] || continue
      # A pyproject.toml that only configures tools (black, ruff, pytest)
      # declares no dependencies; a pip job on it fails in Dependabot's
      # Insights tab. Only a [project] or [tool.poetry] table counts.
      if [ "$f" = "pyproject.toml" ] \
        && ! grep -qE '^\[(project|tool\.poetry)\]' "$root/$f"; then
        continue
      fi
      printf '%s\t%s\n' "$eco" "$f"
      break
    done
  done
}

# Append an `updates:` entry per detected manifest to a dependabot.yml and
# print the ecosystems added, space-separated (empty when none).
dependabot_append_ecosystems() {
  local file=$1 root=$2
  local added="" eco manifest
  while IFS=$'\t' read -r eco manifest; do
    [ -n "$eco" ] || continue
    cat >> "$file" <<ENTRY

  # Added by constitution/scripts/bootstrap.sh: $manifest found at the root.
  - package-ecosystem: "$eco"
    directory: "/"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "deps"
    labels:
      - "dependencies"
ENTRY
    added="$added${added:+ }$eco"
  done < <(dependabot_ecosystems "$root")
  printf '%s' "$added"
}
