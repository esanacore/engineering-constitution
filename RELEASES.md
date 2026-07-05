# Release Standards

Release discipline makes change understandable and recoverable.

## Semantic Versioning

Follow semantic versioning (SemVer) for all repositories:

- **MAJOR**: Incompatible changes (breaking changes)
- **MINOR**: Backward-compatible functionality (new features)
- **PATCH**: Backward-compatible fixes (bug fixes, maintenance)

## The VERSION File

Every repository must include a root-level `VERSION` file. This file:
- Contains only the version string (e.g., `1.2.3`).
- Is the single source of truth for the project's current state.
- Must be updated by agents/humans before any release.

## Version Analysis Tool

The framework includes a tool to help determine the correct version based on project history:

```bash
# Analyze a project directory
bash constitution/scripts/version_analyzer.sh .
```

This tool scans Git tags and commit messages for SemVer-aligned prefixes (e.g., `feat:`, `fix:`, `BREAKING CHANGE`) to suggest the next appropriate version bump.

## Git Tags

Every release of this framework must be tagged in Git as `vMAJOR.MINOR.PATCH`
(for example, `v1.15.0`) on the commit that updates `VERSION` and `CHANGELOG.md`.

Tags are the machine-comparable record of releases. Adopting repositories and
the `constitution-version-check` CI workflow compare a project's pinned
`constitution/` submodule against the **latest release tag**, so a release is
not considered shippable to adopters until it is tagged.

```bash
# After VERSION and CHANGELOG.md are updated and merged to main:
git tag -a "v$(cat VERSION)" -m "Release $(cat VERSION)"
git push origin "v$(cat VERSION)"
bash scripts/check_release_tag_alignment.sh .
```

## CHANGELOG Format

Use these categories:

```markdown
## Added

## Changed

## Fixed

## Removed

## Security
```

## User-Facing Changes

User-facing changes should be reflected in CHANGELOG.md.

Examples:

- New features
- Changed workflows
- Bug fixes visible to users
- Removed behavior
- Security fixes or hardening
- Configuration changes
- Migration requirements

## Agent Responsibilities

Agents should:

- Identify release notes when appropriate.
- Update CHANGELOG.md for user-facing changes.
- Note breaking changes clearly.
- Mention migration steps when required.
- Avoid adding noisy entries for purely internal changes unless useful.

## Publishing a GitHub Release

A Git tag and a GitHub Release are not the same thing. The tag is the
machine-comparable record (see above); a Release is the human-facing notes page
that GitHub surfaces as "Latest release" on the repository home and Releases tab.
A bare tag does **not** create a Release.

After the tag is pushed, publish a matching Release whose notes come from the
version's `CHANGELOG.md` section, and mark the newest version as latest:

```bash
# Extract this version's CHANGELOG section into notes, then publish:
gh release create "v$(cat VERSION)" \
  --title "v$(cat VERSION)" \
  --notes-file <changelog-section> \
  --latest
```

## Cutting a Release

Run these steps in order. Each one has been skipped in practice, so treat the
list as a gate, not a suggestion — a release is not done until every box is checked.

1. **Bump `VERSION`** to the new `MAJOR.MINOR.PATCH`. This is the source of truth.
2. **Update every in-repo version reference** so none lag behind `VERSION`.
   - The `README.md` "Current version" line.
   - Any embedded version string in the project's primary doc (for this
     framework, `CONSTITUTION.md`'s `Version:` header).
   - Grep for the previous version string to catch stragglers:
     `grep -rn "$(previous version)" --include='*.md' .`
3. **Update `CHANGELOG.md`** with a dated section for the new version under the
   correct categories.
4. **Update `TODO.md`** — mark shipped items done, record discovered follow-ups.
5. **Run tests** and confirm they pass.
6. **Commit** the version bump, changelog, and doc updates together.
7. **Tag** the commit `vMAJOR.MINOR.PATCH` and push the tag (see *Git Tags*), then run `bash scripts/check_release_tag_alignment.sh .` so `VERSION`, `HEAD`, and the newest release tag are all proven to agree.
8. **Publish the GitHub Release** from the changelog section, marked `--latest`
   (see *Publishing a GitHub Release*).

### Pre-release Review

Before cutting, confirm:

- CHANGELOG.md updated and accurate.
- Tests passing.
- Documentation updated.
- Security-sensitive changes reviewed.
- Migration notes included when required.
