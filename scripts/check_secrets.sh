#!/usr/bin/env bash
set -euo pipefail

# Sweep a project for secrets that should never reach a remote: credential-
# shaped filenames (.env, id_rsa, *.pem, credentials.json, ...) and
# high-confidence secret patterns in file content (AWS access keys, GitHub/
# Slack tokens, PEM private key blocks, Google/Stripe API keys). Adopters run
# it through the `constitution/` submodule, for example:
#
#   bash constitution/scripts/check_secrets.sh
#
# This is governance tooling: a silent bug here would let a real secret reach
# a remote unflagged (see constitution TESTING.md, "Governance Tooling Must Be
# Tested"). It is a zero-dependency baseline (bash + git only, no package
# install required) meant to run locally before every push and in CI. It is
# intentionally a curated, high-confidence pattern set, not exhaustive —
# projects that want deeper coverage should still consider a dedicated scanner
# such as gitleaks or trufflehog; this script exists so every adopting
# repository has *some* sweep with zero setup cost.
#
# Scope: both tracked files and untracked-but-not-gitignored files (via
# `git grep --untracked` / `git ls-files --others --exclude-standard`), so it
# catches a secret sitting in the working tree a moment before an accidental
# `git add -A`, not only secrets already committed.
#
# Two tiers:
#   - Real hits: a secret-shaped filename, or a content pattern match. ALWAYS
#     fails, with or without --strict (a real hit is never "just a warning").
#   - Recommended: whether .gitignore already covers the known secret-file
#     patterns below. Missing coverage warns by default; --strict fails.
#
# Exit status:
#   0  no secret-shaped files or content matches, and (unless --strict)
#      regardless of .gitignore coverage
#   1  a secret-shaped file or content match was found (always), or (--strict)
#      .gitignore is missing coverage for a known secret-file pattern
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_secrets.sh [--strict] [project-root]

Description:
  Sweep tracked and untracked-but-not-gitignored files for secrets that
  should never reach a remote:
    - Filenames shaped like credentials (.env, id_rsa, *.pem, *.p12, *.key,
      credentials.json, service-account JSON, .netrc, terraform.tfstate, ...).
    - High-confidence secret patterns in file content (AWS access keys,
      GitHub/Slack tokens, PEM private key blocks, Google/Stripe API keys).
  Also checks whether .gitignore already covers the known secret-file
  patterns above, so a gap can be closed before it becomes a real leak.

  A real hit (secret-shaped file or content match) ALWAYS fails, with or
  without --strict. --strict only governs the .gitignore-coverage
  recommendation: missing coverage warns by default, fails under --strict.

Arguments:
  project-root   Path to the repository root to check. Default: current directory.

Options:
  --strict    Fail when .gitignore does not cover a known secret-file pattern.
  -h, --help  Show this help.
USAGE
}

strict=false
root=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --strict)
      strict=true
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [ -n "$root" ]; then
        echo "Unexpected extra argument: $1" >&2
        exit 2
      fi
      root=$1
      shift
      ;;
  esac
done

root=${root:-.}

if [ ! -d "$root" ]; then
  echo "Project root not found or not a directory: $root" >&2
  exit 2
fi

root=$(CDPATH= cd -- "$root" && pwd)

if ! git -C "$root" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Not a Git repository: $root" >&2
  exit 2
fi

# Filenames shaped like credentials, matched case-insensitively against the
# basename only (a directory named "keys" must never widen "*.key" to match
# every file beneath it). Exclusions are checked before the generic ".env.*"
# catch-all so placeholder files like .env.example are never flagged.
is_secret_filename() {
  local base
  base=$(basename -- "$1")
  local base_lc=${base,,}
  case "$base_lc" in
    .env.example|.env.sample|.env.template|.env.dist) return 1 ;;
    .env|.env.*) return 0 ;;
    *.pem|*.p12|*.pfx|*.jks|*.keystore|*.ppk|*.key) return 0 ;;
    id_rsa|id_dsa|id_ecdsa|id_ed25519) return 0 ;;
    credentials.json|*serviceaccount*.json|*service-account*.json) return 0 ;;
    .netrc) return 0 ;;
    terraform.tfstate|terraform.tfstate.backup) return 0 ;;
  esac
  return 1
}

# High-confidence content signatures: "label:::extended-regex". Kept narrow
# and specific (real secret formats, not generic "key=value" heuristics) to
# avoid drowning real hits in false positives.
content_patterns=(
  "AWS access key ID:::AKIA[0-9A-Z]{16}"
  "AWS temporary/session key ID:::ASIA[0-9A-Z]{16}"
  "PEM private key block:::-----BEGIN (RSA |EC |OPENSSH |DSA |PGP |ENCRYPTED )?PRIVATE KEY-----"
  "GitHub token:::gh[pousr]_[A-Za-z0-9]{36}"
  "Slack token:::xox[baprs]-[0-9A-Za-z-]{10,48}"
  "Google API key:::AIza[0-9A-Za-z_-]{35}"
  "Stripe live secret key:::sk_live_[0-9a-zA-Z]{16,}"
)

# Representative .gitignore coverage families: "label:::grep -E pattern".
# This is a heuristic ("does .gitignore look like it covers this family"),
# not a full glob-subsumption check.
gitignore_recommendations=(
  ".env / .env.*:::(^|/)\\.env(\\*|\\.\\*)?($|/)"
  "*.pem / *.key / *.p12 / *.pfx:::(^|/)\\*\\.(pem|key|p12|pfx)$"
  "SSH private keys (id_rsa, etc.):::(id_rsa|id_dsa|id_ecdsa|id_ed25519|\\.ssh)"
  "credentials.json / service-account JSON:::(credentials\\.json|service.?account)"
  ".netrc:::(^|/)\\.netrc$"
  "terraform.tfstate:::tfstate"
)

echo "Secrets sweep for: $root"
echo

echo "Filenames shaped like credentials:"
filename_hits=0
while IFS= read -r -d '' path; do
  if is_secret_filename "$path"; then
    echo "  FOUND    $path"
    filename_hits=$((filename_hits + 1))
  fi
done < <(git -C "$root" ls-files -z --cached --others --exclude-standard)
if [ "$filename_hits" -eq 0 ]; then
  echo "  OK       No credential-shaped filenames found."
fi

echo
echo "Content patterns:"
content_hits=0
for entry in "${content_patterns[@]}"; do
  label=${entry%%:::*}
  pattern=${entry#*:::}
  matches=$(git -C "$root" grep -I -n -E --untracked --exclude-standard -e "$pattern" -- . 2>/dev/null || true)
  if [ -n "$matches" ]; then
    echo "  FOUND    $label:"
    while IFS= read -r line; do
      echo "    $line"
    done <<<"$matches"
    content_hits=$((content_hits + 1))
  fi
done
if [ "$content_hits" -eq 0 ]; then
  echo "  OK       No high-confidence secret patterns found."
fi

echo
if [ -f "$root/.gitignore" ]; then
  echo "Recommended .gitignore coverage:"
else
  echo "Recommended .gitignore coverage (no .gitignore found):"
fi
gitignore_missing=0
for entry in "${gitignore_recommendations[@]}"; do
  label=${entry%%:::*}
  pattern=${entry#*:::}
  if [ -f "$root/.gitignore" ] && grep -Eiq -- "$pattern" "$root/.gitignore"; then
    echo "  OK       $label"
  else
    if [ "$strict" = "true" ]; then
      echo "  MISSING  $label (recommended, --strict)"
    else
      echo "  WARN     $label (recommended)"
    fi
    gitignore_missing=$((gitignore_missing + 1))
  fi
done

echo
echo "Filename hits: $filename_hits; content-pattern hits: $content_hits; .gitignore coverage gaps: $gitignore_missing."

if [ "$filename_hits" -gt 0 ] || [ "$content_hits" -gt 0 ]; then
  echo
  echo "Real secret-shaped hits were found above. Remove the file(s) from Git" \
       "(git rm --cached), rotate any exposed credential, and add a matching" \
       "pattern to .gitignore before pushing."
  exit 1
fi

if [ "$strict" = "true" ] && [ "$gitignore_missing" -gt 0 ]; then
  exit 1
fi

exit 0
