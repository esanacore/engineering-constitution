#!/usr/bin/env bash
set -euo pipefail

# One-time, per-machine setup for the AI-agent toolchain this framework's
# templates point at: Bun, gstack, the goose CLI, and goosetown.
#
# NOT invoked by scripts/bootstrap.sh, and deliberately so: bootstrap.sh
# only ever writes files into an adopting repository -- it never runs an
# installer or makes a network call beyond `git submodule add` (see
# INTEGRATION.md "gstack and gbrain" / "Goose and Goosetown"). Repository
# bootstrapping and machine provisioning are different concerns with
# different blast radii, and conflating them would mean every future
# `bootstrap.sh` run -- on any repo, in any context, including ones that
# don't use Claude Code or goose at all -- silently tries to install global
# developer tooling as a side effect.
#
# This script is the explicit, human-run counterpart. Run it once per
# machine, not per repository: when setting up a new box, or to pick up a
# tool you skipped before. Idempotent -- safe to re-run; each tool is
# skipped if already present.
#
# Usage:
#   bash scripts/setup-machine.sh [options]
#
# Options:
#   --skip-bun        Skip Bun (gstack's runtime dependency).
#   --skip-gstack     Skip gstack.
#   --skip-goose      Skip the goose CLI.
#   --skip-goosetown  Skip cloning goosetown.
#   -h, --help        Show this help.
#
# Environment overrides:
#   GSTACK_DIR                    Install location for gstack.
#                                  Default: $HOME/.claude/skills/gstack
#   GOOSETOWN_DIR                 Clone location for goosetown.
#                                  Default: $HOME/Repos/goosetown
#   GSTACK_REPO_URL               Default: https://github.com/garrytan/gstack.git
#   GOOSE_INSTALLER_URL           Default: https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh
#   GOOSETOWN_REPO_URL            Default: https://github.com/aaif-goose/goosetown.git
#   BUN_INSTALLER_URL             Default: https://bun.sh/install
#   PLAYWRIGHT_FALLBACK_PLATFORM  Fallback platform for gstack's browser
#                                 install on a Linux distro newer than
#                                 Playwright's support matrix.
#                                 Default: ubuntu24.04-x64
#
# Exit status:
#   0  everything requested is installed or was already present
#   1  at least one requested tool failed to install
#   2  usage error

usage() {
  cat <<'USAGE'
Usage:
  setup-machine.sh [options]

Options:
  --skip-bun        Skip Bun (gstack's runtime dependency).
  --skip-gstack     Skip gstack.
  --skip-goose      Skip the goose CLI.
  --skip-goosetown  Skip cloning goosetown.
  -h, --help        Show this help.

Run once per machine (not per repository). Safe to re-run -- each tool is
skipped if already present. See the script header for environment
variable overrides (install locations, source URLs, Playwright fallback).
USAGE
}

skip_bun=false
skip_gstack=false
skip_goose=false
skip_goosetown=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --skip-bun) skip_bun=true; shift ;;
    --skip-gstack) skip_gstack=true; shift ;;
    --skip-goose) skip_goose=true; shift ;;
    --skip-goosetown) skip_goosetown=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

GSTACK_DIR="${GSTACK_DIR:-$HOME/.claude/skills/gstack}"
GOOSETOWN_DIR="${GOOSETOWN_DIR:-$HOME/Repos/goosetown}"
GSTACK_REPO_URL="${GSTACK_REPO_URL:-https://github.com/garrytan/gstack.git}"
GOOSE_INSTALLER_URL="${GOOSE_INSTALLER_URL:-https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh}"
GOOSETOWN_REPO_URL="${GOOSETOWN_REPO_URL:-https://github.com/aaif-goose/goosetown.git}"
BUN_INSTALLER_URL="${BUN_INSTALLER_URL:-https://bun.sh/install}"
PLAYWRIGHT_FALLBACK_PLATFORM="${PLAYWRIGHT_FALLBACK_PLATFORM:-ubuntu24.04-x64}"

log() { echo "==> $*"; }
warn() { echo "WARNING: $*" >&2; }

installed=()
skipped=()
failed=()

# ─── Bun ─────────────────────────────────────────────────────────────────

setup_bun() {
  if command -v bun >/dev/null 2>&1; then
    log "Bun already installed ($(bun --version 2>&1))"
    skipped+=("Bun")
    return 0
  fi
  if [ "$skip_bun" = true ]; then
    log "Bun missing, --skip-bun set -- skipping (gstack will fail without it)"
    skipped+=("Bun (--skip-bun)")
    return 0
  fi

  log "Installing Bun..."
  local tmp
  tmp=$(mktemp)
  if curl -fsSL "$BUN_INSTALLER_URL" -o "$tmp" && bash "$tmp"; then
    installed+=("Bun")
    export PATH="$HOME/.bun/bin:$PATH"
  else
    warn "Bun install failed"
    failed+=("Bun")
  fi
  rm -f "$tmp"
}

# ─── gstack ──────────────────────────────────────────────────────────────

setup_gstack() {
  if [ "$skip_gstack" = true ]; then
    log "Skipping gstack (--skip-gstack)"
    skipped+=("gstack (--skip-gstack)")
    return 0
  fi
  if [ -d "$GSTACK_DIR/bin" ]; then
    log "gstack already installed at $GSTACK_DIR"
    skipped+=("gstack")
    return 0
  fi
  if ! command -v bun >/dev/null 2>&1; then
    warn "gstack requires Bun, which isn't on PATH -- install it first"
    failed+=("gstack (no Bun)")
    return 0
  fi

  log "Cloning gstack to $GSTACK_DIR..."
  mkdir -p "$(dirname "$GSTACK_DIR")"
  if ! git clone --single-branch --depth 1 "$GSTACK_REPO_URL" "$GSTACK_DIR" 2>&1; then
    warn "gstack clone failed"
    failed+=("gstack")
    return 0
  fi

  log "Running gstack setup (this builds browser binaries and registers skills; can take a minute)..."
  local setup_output
  setup_output=$(mktemp)
  # Stream ./setup's output live (it's slow enough that silence looks
  # hung) while also capturing it, so the Playwright-distro check below
  # has something to grep -- and so a failure's output is still on
  # screen, not just referenced by a temp path that's about to be
  # deleted. `set -o pipefail` (from the script header) keeps ./setup's
  # own exit status from being masked by `tee`'s.
  if ( cd "$GSTACK_DIR" && ./setup ) 2>&1 | tee "$setup_output"; then
    installed+=("gstack")
  else
    warn "gstack ./setup exited non-zero"
    failed+=("gstack (./setup)")
  fi

  # ./setup can succeed overall while its Playwright browser download still
  # fails on a Linux distro newer than Playwright's own support matrix.
  # Verified workaround from this framework's own v1.31.0 development.
  if grep -q "does not support chromium on" "$setup_output" 2>/dev/null; then
    log "Playwright doesn't recognize this distro -- retrying browser install with fallback platform $PLAYWRIGHT_FALLBACK_PLATFORM"
    if ( cd "$GSTACK_DIR/browse" && PLAYWRIGHT_HOST_PLATFORM_OVERRIDE="$PLAYWRIGHT_FALLBACK_PLATFORM" bunx playwright install chromium chromium-headless-shell ); then
      log "Browser install succeeded with fallback platform $PLAYWRIGHT_FALLBACK_PLATFORM"
    else
      warn "Browser install still failed -- /browse and other browser-driving skills won't work until this is resolved manually (see INTEGRATION.md 'Known gap on very new Linux distros')"
      failed+=("gstack browser (Playwright)")
    fi
  fi
  rm -f "$setup_output"
}

# ─── goose CLI ───────────────────────────────────────────────────────────

setup_goose() {
  if [ "$skip_goose" = true ]; then
    log "Skipping goose CLI (--skip-goose)"
    skipped+=("goose (--skip-goose)")
    return 0
  fi
  if command -v goose >/dev/null 2>&1; then
    log "goose already installed ($(goose --version 2>&1 | head -1 | sed 's/^ *//;s/ *$//'))"
    skipped+=("goose")
    return 0
  fi

  log "Installing goose CLI..."
  local tmp
  tmp=$(mktemp)
  if curl -fsSL "$GOOSE_INSTALLER_URL" -o "$tmp" && CONFIGURE=false bash "$tmp"; then
    installed+=("goose")
  else
    warn "goose CLI install failed"
    failed+=("goose")
  fi
  rm -f "$tmp"
}

# ─── goosetown ───────────────────────────────────────────────────────────

setup_goosetown() {
  if [ "$skip_goosetown" = true ]; then
    log "Skipping goosetown (--skip-goosetown)"
    skipped+=("goosetown (--skip-goosetown)")
    return 0
  fi
  if [ -e "$GOOSETOWN_DIR/goose" ]; then
    log "goosetown already cloned at $GOOSETOWN_DIR"
    skipped+=("goosetown")
    return 0
  fi

  log "Cloning goosetown to $GOOSETOWN_DIR..."
  mkdir -p "$(dirname "$GOOSETOWN_DIR")"
  if git clone "$GOOSETOWN_REPO_URL" "$GOOSETOWN_DIR" 2>&1; then
    installed+=("goosetown")
  else
    warn "goosetown clone failed"
    failed+=("goosetown")
  fi
}

setup_bun
setup_gstack
setup_goose
setup_goosetown

echo
echo "======================================================="
echo " Machine setup summary"
echo "======================================================="
[ "${#installed[@]}" -gt 0 ] && printf 'Installed:              %s\n' "${installed[*]}"
[ "${#skipped[@]}" -gt 0 ] && printf 'Already present/skipped: %s\n' "${skipped[*]}"
[ "${#failed[@]}" -gt 0 ] && printf 'FAILED:                  %s\n' "${failed[*]}"

echo
echo "Remaining steps are interactive -- run these yourself when ready:"
echo "  goose configure                 # set up an LLM provider for goose"
echo "  cd $GOOSETOWN_DIR && ./goose    # first-run walks through the rest"

if [ "${#failed[@]}" -gt 0 ]; then
  exit 1
fi
exit 0
