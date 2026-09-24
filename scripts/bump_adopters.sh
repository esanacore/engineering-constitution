#!/usr/bin/env bash
set -euo pipefail

# Re-pin every adopting repository's `constitution/` submodule to a release
# commit, one branch and one pull request per repository, and move the
# adopter's own constitution version references along with the pin.
#
# Cutting a constitution release strands the whole adopter fleet one tag
# behind: each adopter's constitution-version.yml gate compares its pinned
# submodule against the latest tag, and where that gate is a required status
# check, every pull request in that repository blocks until the submodule is
# bumped (see RELEASES.md, "Versioning the Framework Itself"). This script is
# step 9 of "Cutting a Release": it turns the fleet bump from a remembered
# chore into a command.
#
# It is idempotent by design, so it can be re-run after a partial failure:
#   - a repository whose gitlink already equals the target commit is skipped;
#   - a repository whose bump branch already exists on the remote is skipped;
#   - a repository that does not carry a `constitution` submodule is reported
#     and skipped, never modified.
# It never touches a default branch directly and never force-pushes.
#
# Exit status:
#   0  every repository was bumped or skipped for a reported reason
#   1  at least one repository failed (clone, commit, or push error)
#   2  usage error, or the target commit is not in the constitution history

usage() {
  cat <<'USAGE'
Usage:
  bump_adopters.sh --sha <commit> --repos <file> [options]

Description:
  For each repository URL listed in <file> (one per line; blank lines and
  lines starting with # are ignored): clone it, create a branch that re-pins
  the `constitution/` submodule gitlink to <commit>, rewrite any adopter-side
  constitution version reference to the new version, push the branch, and
  open a pull request (with `gh`, when available). The release version is
  read from VERSION at <commit> in the constitution repository, so the branch
  name and commit message name the release.

Version references:
  A repository that names the constitution version in prose -- "Engineering
  Constitution v1.48.0" in CLAUDE.md, a CONSTITUTION_VERSION file, a README
  line -- fails check_version_alignment.sh the moment the pin moves past it.
  Moving the gitlink alone therefore leaves the adopter's compliance gate red
  until someone hand-edits that line, which is what happened on two
  consecutive releases before this existed.

  The rewrite scans exactly what check_version_alignment.sh scans (README.md,
  AGENTS.md, CLAUDE.md, CONTRIBUTING.md, SYSTEM_PROMPT.md, docs/SETUP.md,
  docs/INDEX.md, docs/AGENT_HANDOFF.md, docs/AGENT_PROMPTS.md, demo.html,
  docs/governance/*.md, and CONSTITUTION_VERSION), applies the same
  "constitution ... X.Y.Z" line rule, and replaces only the first semantic
  version on a matching line. Rewrites are listed under the repository in the
  run output and again in the commit body. A repository with no such
  reference is committed exactly as before.

Required:
  --sha <commit>          The constitution commit to pin (the release commit
                          or the tag name). Must exist in the constitution
                          checkout named by --constitution.
  --repos <file>          File listing adopter clone URLs.

Options:
  --constitution <path>   Constitution checkout used to resolve the commit
                          and its VERSION. Default: the repository this
                          script lives in.
  --workdir <dir>         Where clones are made. Default: a temporary
                          directory, removed on exit.
  --branch <name>         Branch to create in each adopter.
                          Default: constitution/bump-v<version>.
  --no-pr                 Push the branch but do not open a pull request;
                          print the compare URL instead.
  --dry-run               Do everything except push and open pull requests.
  -h, --help              Show this help.

Per-repository outcomes:
  BUMPED           branch pushed (and pull request opened unless --no-pr)
  ALREADY_PINNED   gitlink already equals the target commit
  BRANCH_EXISTS    the bump branch is already on the remote
  NOT_ADOPTER      no `constitution` submodule in .gitmodules
  FAILED           clone, commit, or push error (details above the summary)
USAGE
}

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
constitution=$(CDPATH= cd -- "$script_dir/.." && pwd)
sha=""
repos_file=""
workdir=""
branch=""
no_pr=false
dry_run=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --sha) [ "$#" -ge 2 ] || { echo "--sha requires a value" >&2; exit 2; }; sha=$2; shift 2 ;;
    --sha=*) sha=${1#--sha=}; shift ;;
    --repos) [ "$#" -ge 2 ] || { echo "--repos requires a value" >&2; exit 2; }; repos_file=$2; shift 2 ;;
    --repos=*) repos_file=${1#--repos=}; shift ;;
    --constitution) [ "$#" -ge 2 ] || { echo "--constitution requires a value" >&2; exit 2; }; constitution=$2; shift 2 ;;
    --constitution=*) constitution=${1#--constitution=}; shift ;;
    --workdir) [ "$#" -ge 2 ] || { echo "--workdir requires a value" >&2; exit 2; }; workdir=$2; shift 2 ;;
    --workdir=*) workdir=${1#--workdir=}; shift ;;
    --branch) [ "$#" -ge 2 ] || { echo "--branch requires a value" >&2; exit 2; }; branch=$2; shift 2 ;;
    --branch=*) branch=${1#--branch=}; shift ;;
    --no-pr) no_pr=true; shift ;;
    --dry-run) dry_run=true; shift ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) echo "Unexpected argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[ -n "$sha" ] || { echo "--sha is required" >&2; usage >&2; exit 2; }
[ -n "$repos_file" ] || { echo "--repos is required" >&2; usage >&2; exit 2; }
[ -f "$repos_file" ] || { echo "Repos file not found: $repos_file" >&2; exit 2; }
[ -d "$constitution/.git" ] || [ -f "$constitution/.git" ] || { echo "Not a constitution checkout: $constitution" >&2; exit 2; }

if ! full_sha=$(git -C "$constitution" rev-parse --verify --quiet "${sha}^{commit}"); then
  echo "Commit not found in $constitution: $sha (fetch tags first?)" >&2
  exit 2
fi
if ! version=$(git -C "$constitution" show "${full_sha}:VERSION" 2>/dev/null); then
  echo "No VERSION file at commit $full_sha" >&2
  exit 2
fi
version=$(printf '%s' "$version" | tr -d '[:space:]')
[ -n "$version" ] || { echo "VERSION is empty at commit $full_sha" >&2; exit 2; }
branch=${branch:-constitution/bump-v$version}

if [ -z "$workdir" ]; then
  workdir=$(mktemp -d)
  trap 'rm -rf "$workdir"' EXIT
else
  mkdir -p "$workdir"
fi
workdir=$(CDPATH= cd -- "$workdir" && pwd)

have_gh=false
if [ "$no_pr" = "false" ] && command -v gh >/dev/null 2>&1; then
  have_gh=true
fi

echo "Bumping adopters to constitution v$version ($full_sha)"
echo "Branch: $branch"
[ "$dry_run" = "true" ] && echo "DRY RUN: nothing will be pushed."
echo

bumped=0; skipped=0; failed=0

record() { echo "  $1  $2"; }

# Rewrite adopter-side constitution version references to $version.
#
# check_version_alignment.sh fails a repository whose governance files name a
# constitution version other than the pinned one, so a bump that moves only the
# gitlink leaves the adopter's compliance gate red until someone hand-edits a
# line. AI-Process-Engineer needed exactly that edit on two consecutive
# releases before this existed.
#
# The scanned set and the match rule are deliberately identical to
# check_version_alignment.sh: the same candidate files, the same
# "constitution ... X.Y.Z" line grep, and the same "first semantic version on
# the line" rule. Only that first version on a matching line is rewritten, so
# an unrelated version elsewhere on the line is left alone.
#
# Usage: rewrite_version_references <repo-root> <new-version>
# Echoes one "path:line old -> new" per rewrite; returns 0 always.
rewrite_version_references() {
  vr_root=$1
  vr_new=$2

  if [ -f "$vr_root/CONSTITUTION_VERSION" ]; then
    vr_declared=$(tr -d '[:space:]' < "$vr_root/CONSTITUTION_VERSION")
    if [ -n "$vr_declared" ] && [ "$vr_declared" != "$vr_new" ]; then
      printf '%s\n' "$vr_new" > "$vr_root/CONSTITUTION_VERSION"
      echo "CONSTITUTION_VERSION $vr_declared -> $vr_new"
    fi
  fi

  vr_files="README.md AGENTS.md CLAUDE.md CONTRIBUTING.md SYSTEM_PROMPT.md docs/SETUP.md docs/INDEX.md docs/AGENT_HANDOFF.md docs/AGENT_PROMPTS.md demo.html"
  for vr_gov in "$vr_root"/docs/governance/*.md; do
    [ -f "$vr_gov" ] && vr_files="$vr_files ${vr_gov#"$vr_root"/}"
  done

  for vr_rel in $vr_files; do
    vr_full="$vr_root/$vr_rel"
    [ -f "$vr_full" ] || continue

    while IFS= read -r vr_match; do
      [ -n "$vr_match" ] || continue
      vr_lineno=${vr_match%%:*}
      vr_text=${vr_match#*:}
      vr_found=$(printf '%s\n' "$vr_text" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)
      [ -n "$vr_found" ] || continue
      [ "$vr_found" = "$vr_new" ] && continue

      # Replace only the first occurrence, only on this line.
      vr_tmp="$vr_full.bumptmp"
      awk -v ln="$vr_lineno" -v old="$vr_found" -v new="$vr_new" '
        NR == ln {
          i = index($0, old)
          if (i > 0) $0 = substr($0, 1, i - 1) new substr($0, i + length(old))
        }
        { print }
      ' "$vr_full" > "$vr_tmp" && mv "$vr_tmp" "$vr_full"
      echo "$vr_rel:$vr_lineno $vr_found -> $vr_new"
    done < <(
      grep -nEi '.*constitution.*([0-9]+\.[0-9]+\.[0-9]+).*|.*([0-9]+\.[0-9]+\.[0-9]+).*constitution.*' "$vr_full" || true
    )
  done

  return 0
}

while IFS= read -r url || [ -n "$url" ]; do
  url=$(printf '%s' "$url" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
  case "$url" in ''|'#'*) continue ;; esac
  name=$(basename "${url%/}")
  name=${name%.git}
  dest="$workdir/$name"
  echo "== $name ($url)"

  rm -rf "$dest"
  if ! git clone -q "$url" "$dest" </dev/null 2>"$workdir/$name.clone.log"; then
    sed 's/^/     /' "$workdir/$name.clone.log"
    record FAILED "$name: clone failed"; failed=$((failed + 1)); continue
  fi

  if [ ! -f "$dest/.gitmodules" ] || \
     [ "$(git -C "$dest" config -f .gitmodules --get submodule.constitution.path 2>/dev/null || true)" != "constitution" ]; then
    record NOT_ADOPTER "$name: no constitution submodule in .gitmodules"; skipped=$((skipped + 1)); continue
  fi

  current=$(git -C "$dest" ls-tree HEAD constitution | awk '$2 == "commit" {print $3}')
  if [ "$current" = "$full_sha" ]; then
    record ALREADY_PINNED "$name: already at $full_sha"; skipped=$((skipped + 1)); continue
  fi

  if [ -n "$(git -C "$dest" ls-remote --heads origin "$branch" 2>/dev/null)" ]; then
    record BRANCH_EXISTS "$name: $branch already on the remote (merge or delete it, then re-run)"; skipped=$((skipped + 1)); continue
  fi

  default_branch=$(git -C "$dest" rev-parse --abbrev-ref HEAD)
  if ! git -C "$dest" checkout -q -b "$branch" \
     || ! git -C "$dest" update-index --cacheinfo "160000,$full_sha,constitution"; then
    record FAILED "$name: could not create the bump commit"; failed=$((failed + 1)); continue
  fi

  # Move the adopter's own version references with the pin, so the bump does
  # not leave check_version_alignment.sh failing on a stale mention.
  rewrites=$(rewrite_version_references "$dest" "$version" || true)
  rewrite_note=""
  if [ -n "$rewrites" ]; then
    rewrite_count=$(printf '%s\n' "$rewrites" | grep -c . || true)
    while IFS= read -r line; do [ -n "$line" ] && echo "     ref  $line"; done <<< "$rewrites"
    rewrite_note=" (+$rewrite_count version reference(s))"
    if ! git -C "$dest" add -A; then
      record FAILED "$name: could not stage the rewritten version references"; failed=$((failed + 1)); continue
    fi
  fi

  commit_body="Pin constitution/ to $full_sha (v$version). Previously $current."
  if [ -n "$rewrites" ]; then
    commit_body="$commit_body

Adopter-side version references updated to match the new pin, so
check_version_alignment.sh does not fail on a stale mention:

$(printf '%s\n' "$rewrites" | sed 's/^/  /')"
  fi

  if ! git -C "$dest" -c user.name="${GIT_AUTHOR_NAME:-constitution-bump}" -c user.email="${GIT_AUTHOR_EMAIL:-constitution-bump@users.noreply.github.com}" \
          commit -q -m "constitution: bump to v$version" \
          -m "$commit_body" \
          -m "Generated by constitution/scripts/bump_adopters.sh as step 9 of RELEASES.md \"Cutting a Release\"."; then
    record FAILED "$name: could not create the bump commit"; failed=$((failed + 1)); continue
  fi

  if [ "$dry_run" = "true" ]; then
    record BUMPED "$name: commit created on $branch$rewrite_note (dry run, not pushed; base $default_branch)"; bumped=$((bumped + 1)); continue
  fi

  if ! git -C "$dest" push -q -u origin "$branch" </dev/null 2>"$workdir/$name.push.log"; then
    sed 's/^/     /' "$workdir/$name.push.log"
    record FAILED "$name: push failed"; failed=$((failed + 1)); continue
  fi

  pr_note="pushed $branch (base $default_branch)"
  if [ "$have_gh" = "true" ]; then
    if pr_url=$(cd "$dest" && gh pr create --base "$default_branch" --head "$branch" \
        --title "constitution: bump to v$version" \
        --body "Re-pins \`constitution/\` to $full_sha (v$version). See the constitution's CHANGELOG for what changed." </dev/null 2>&1); then
      pr_note="pull request: $pr_url"
    else
      pr_note="pushed $branch; gh pr create failed: $pr_url"
    fi
  else
    case "$url" in
      *github.com*)
        path=${url#*github.com[:/]}; path=${path%.git}
        pr_note="pushed $branch; open https://github.com/$path/compare/$default_branch...$branch?expand=1" ;;
    esac
  fi
  record BUMPED "$name: $pr_note$rewrite_note"; bumped=$((bumped + 1))
done < "$repos_file"

echo
echo "Summary: $bumped bumped, $skipped skipped, $failed failed."

[ "$failed" -eq 0 ] || exit 1
exit 0
