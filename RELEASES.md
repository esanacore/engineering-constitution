# Release Standards

Release discipline makes change understandable and recoverable.

## Semantic Versioning

Follow semantic versioning (SemVer) for all repositories:

- **MAJOR**: Incompatible changes (breaking changes)
- **MINOR**: Backward-compatible functionality (new features)
- **PATCH**: Backward-compatible fixes (bug fixes, maintenance)

## Versioning the Framework Itself

SemVer is defined in terms of an API. A governance framework's API is the
contract its adopters' CI depends on, so for *this* repository the terms mean
(ADR-0002):

- **MAJOR** — an adopter's CI can turn red, or a documented invocation can
  stop working, without any change on the adopter's side: a new **required**
  file or required tier entry in `check_compliance.sh`; a checker whose
  default flips from warn to fail; a removed or renamed script, template, or
  workflow that adopters invoke; a changed exit-code meaning or option in a
  script that a shipped workflow template or a documented CI invocation
  depends on. (An on-demand tool such as `version_analyzer.sh` or
  `measure_instruction_weight.sh` is not on that path; changing its usage
  exit code is PATCH-shaped.)
- **MINOR** — a new standard, checker, template, workflow, or skill that
  warns by default; a new recommended file; a new Required Workflow step;
  new advisory guidance.
- **PATCH** — a fix that changes no contract.

**The deprecation window.** A MAJOR-shaped change may still ship as MINOR
when adopters were warned first: the requirement ships warn-by-default in one
release with a `Deprecation` notice in `CHANGELOG.md` naming the release that
will enforce it, and the enforcing change lands no sooner than the next MINOR
release. A change that skips the window is MAJOR, however small it looks —
making the wiki required in 1.44.0 turned every adopter's compliance gate
red the moment they bumped, and this section exists so that does not happen
again by accident.

**Fleet effect.** Cutting any release strands every adopter one tag behind:
their `constitution-version.yml` gate compares the pinned submodule against
the latest tag, and where that gate is a required status check, every pull
request in that repository blocks until the submodule is bumped. The fleet
bump is therefore a release step, not an afterthought (see "Cutting a
Release", step 9).

## Commit Messages

Commit messages follow the [Conventional Commits](https://www.conventionalcommits.org/)
form, `type(scope)?: summary`, with `!` after the type or a `BREAKING CHANGE:`
footer for an incompatible change:

- `feat:` new behavior (MINOR), `fix:` a bug fix (PATCH), `docs:`, `test:`,
  `ci:`, `refactor:`, `chore:` for changes that do not alter shipped
  behavior; `chore(release): cut X.Y.Z` for the release commit.
- The summary line states what changed in the imperative; the body says why.

`scripts/version_analyzer.sh` reads exactly these prefixes to suggest the
next version, and the analyzer is only as good as the history it reads.
`CHANGELOG.md` remains the human-facing record; commit messages are its raw
material, not a replacement for it.

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

This repository's own `.github/workflows/release-tag-alignment.yml` workflow
also runs `scripts/check_release_tag_alignment.sh` automatically on every pushed
`v*` tag. Treat it as the hosted backstop for the same check; it does not
replace running the script locally before you push the tag.

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
   - The interactive `demo.html` badge text.
   - `wiki/Home.md`'s current-version line.
   - `mcp-server/package.json` and `mcp-server/package-lock.json` (the two
     root `version` fields); `scripts/test_release_docs.sh` and
     `scripts/test_mcp_resources.sh` enforce all of these.
   - Grep for the previous version string to catch stragglers:
     `grep -rn "$(previous version)" --include='*.md' --include='*.html' --include='*.json' .`
3. **Update `CHANGELOG.md`** with a dated section for the new version under the
   correct categories.
4. **Update `TODO.md`** — mark shipped items done, record discovered follow-ups.
5. **Run tests** and confirm they pass.
6. **Commit** the version bump, changelog, and doc updates together.
7. **Tag** the commit `vMAJOR.MINOR.PATCH` and push the tag (see *Git Tags*), then run `bash scripts/check_release_tag_alignment.sh .` so `VERSION`, `HEAD`, and the newest release tag are all proven to agree. The source-repo `release-tag-alignment` GitHub Actions workflow will rerun this automatically once the tag lands on GitHub.
8. **Publish the GitHub Release** from the changelog section, marked `--latest`
   (see *Publishing a GitHub Release*).
9. **Bump the adopter fleet.** Every adopter is now one tag behind, and any
   with a required version gate is blocked. Run
   `bash scripts/bump_adopters.sh --sha <release-commit> --repos <list>` to
   open one branch and one pull request per adopter that re-pins
   `constitution/` to the release commit (idempotent: already-pinned
   repositories and existing bump branches are skipped), then merge them.
   A pin *ahead* of the tag is acceptable when `VERSION` at the pinned commit
   equals the tag's version (see `docs/MEMORY.md`); never re-pin backwards.

### Pre-release Review

Before cutting, confirm:

- CHANGELOG.md updated and accurate.
- Tests passing.
- Documentation updated.
- Security-sensitive changes reviewed.
- Migration notes included when required.
- Anything MAJOR-shaped (see *Versioning the Framework Itself*) either bumps
  MAJOR or has served its deprecation window.
- `docs/OTS_SOFTWARE.md`'s Anomaly Review column re-reviewed.
