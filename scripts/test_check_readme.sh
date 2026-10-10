#!/usr/bin/env bash
set -euo pipefail

# Negative-case tests for scripts/check_readme.sh.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
checker="$script_dir/check_readme.sh"
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

# make_readme <dir> <markdown>
make_readme() { mkdir -p "$1"; printf '%s\n' "$2" > "$1/README.md"; }

# expect_finding <dir> <fixed string> <description>: warn mode reports it and
# exits 0; --strict exits 1.
expect_finding() {
  local status=0 out
  out=$("$checker" "$1") || status=$?
  [ "$status" -eq 0 ] || { echo "$out"; fail "$3: warn mode exited $status"; }
  grep -qF -- "$2" <<< "$out" || { echo "$out"; fail "$3: expected '$2'"; }
  status=0; "$checker" --strict "$1" >/dev/null || status=$?
  [ "$status" -eq 1 ] || fail "$3: --strict exited $status, expected 1"
}
# expect_clean <dir> <description>
expect_clean() {
  local out
  out=$("$checker" --strict "$1") || { echo "$out"; fail "$2"; }
}

platforms='Supported platforms: Windows 11, macOS 14, Linux (Ubuntu 22.04).'

good="# Project

What it does, and for whom.

## Quick Start

$platforms

\`\`\`bash
make run
\`\`\`

<details>
<summary>Windows (PowerShell)</summary>

\`\`\`powershell
\$env:APP_ENV = \"dev\"
.\\.venv\\Scripts\\Activate.ps1
\`\`\`

</details>

<details>
<summary>macOS (zsh) and Linux (bash)</summary>

\`\`\`bash
export APP_ENV=dev
source .venv/bin/activate
\`\`\`

</details>

## Project Structure

<details>
<summary>Full project structure</summary>

- src/
- docs/

</details>"

echo "Test 1: the worked examples pass under --strict: templates/README.md, this repository's README.md, templates/docs/SETUP.md"
expect_clean "$repo_root" "this repository's README.md fails its own checker"
mkdir -p "$tmp/tpl"; cp "$repo_root/templates/README.md" "$tmp/tpl/README.md"
expect_clean "$tmp/tpl" "templates/README.md fails its own checker"
out=$("$checker" --strict --file templates/docs/SETUP.md "$repo_root") || { echo "$out"; fail "templates/docs/SETUP.md fails the checker via --file"; }
make_readme "$tmp/good" "$good"
expect_clean "$tmp/good" "a conforming README was reported"
echo "PASS"

echo "Test 2: command blocks without platforms are caught; naming a platform as unsupported counts; no command blocks, no rule"
make_readme "$tmp/linux-only" '# Tool

```bash
./configure && make
```'
expect_finding "$tmp/linux-only" 'platforms: the file hands the reader 1 fenced command block(s) but never states which platforms are supported' "missing statement"
expect_finding "$tmp/linux-only" 'but never mentions Windows' "missing Windows"
expect_finding "$tmp/linux-only" 'but never mentions macOS' "missing macOS"
make_readme "$tmp/unsupported" '# Tool

Supported platforms: Linux only. Windows and macOS are not supported.

```sh
./configure && make
```'
expect_clean "$tmp/unsupported" "naming Windows and macOS as unsupported should satisfy the rule"
make_readme "$tmp/one-line" '# Tool

Runs on Linux, macOS, or Windows (Git Bash); the commands are the same everywhere.

```bash
make
```'
expect_clean "$tmp/one-line" "one line naming Windows, macOS, and Linux together is a platforms statement"
make_readme "$tmp/no-commands" '# Library

A pure library with no commands to run. Add it as a dependency.

```json
{ "dependency": "lib" }
```'
expect_clean "$tmp/no-commands" "a README with no command blocks should not be held to the platform rule"
echo "PASS"

echo "Test 3: a <details> block needs its blank lines, one level, a close, and a real summary"
make_readme "$tmp/no-blank-after" '# P

<details>
<summary>Linux (bash)</summary>
```bash
make
```

</details>'
expect_finding "$tmp/no-blank-after" 'details: line 4: no blank line after <summary>' "missing blank after summary"
make_readme "$tmp/no-blank-before" '# P

<details>
<summary>Linux (bash)</summary>

- step
</details>'
expect_finding "$tmp/no-blank-before" 'details: line 7: no blank line before </details>' "missing blank before close"
make_readme "$tmp/nested" '# P

<details>
<summary>Install</summary>

<details>
<summary>Windows (PowerShell)</summary>

text

</details>

</details>'
expect_finding "$tmp/nested" 'details: line 6: <details> nested inside the one opened at line 3' "nested details"
make_readme "$tmp/unclosed" '# P

<details>
<summary>Full project structure</summary>

- src/'
expect_finding "$tmp/unclosed" 'details: line 3: <details> is never closed' "unclosed details"
for s in 'Click to expand' 'More' 'Expand...' '**Details**'; do
  make_readme "$tmp/vague" "# P

<details>
<summary>$s</summary>

text

</details>"
  expect_finding "$tmp/vague" 'summary: line 4: <summary> says' "vague summary: $s"
done
make_readme "$tmp/summary-attrs" '# P

<details open>
<summary id="s"><b>Windows (PowerShell)</b></summary>

text

</details>'
expect_clean "$tmp/summary-attrs" "attributes and inline tags in <details>/<summary> should not confuse the parser"
echo "PASS"

echo "Test 4: headings inside a collapsed block are caught; headings outside are fine"
make_readme "$tmp/heading-in" '# P

<details>
<summary>Manual installation</summary>

### Step one

text

</details>'
expect_finding "$tmp/heading-in" 'heading: line 6: "### Step one" is inside the <details> opened at line 3' "heading inside details"
echo "PASS"

echo "Test 5: a PowerShell/cmd Windows block written for a POSIX shell is caught; Git Bash and WSL blocks are bash blocks"
make_readme "$tmp/win-posix" "# P

$platforms

<details>
<summary>Windows (PowerShell)</summary>

\`\`\`powershell
export APP_ENV=dev
\`\`\`

</details>"
expect_finding "$tmp/win-posix" 'windows: line 9: the Windows block opened at line 5 uses a POSIX shell command' "export in a PowerShell block"
for shell in 'Windows (Git Bash)' 'Windows (WSL, Ubuntu)'; do
  make_readme "$tmp/win-bash" "# P

$platforms

<details>
<summary>$shell</summary>

\`\`\`bash
export APP_ENV=dev
source .venv/Scripts/activate
\`\`\`

</details>"
  expect_clean "$tmp/win-bash" "bash syntax in a '$shell' block was reported"
done
make_readme "$tmp/win-activate" "# P

$platforms

<details>
<summary>Windows (PowerShell)</summary>

\`\`\`powershell
source .venv/bin/activate
\`\`\`

</details>"
expect_finding "$tmp/win-activate" 'uses a POSIX shell command' "source .../bin/activate in a Windows block"
out=$("$checker" "$tmp/win-activate"); [ "$(grep -c 'windows:' <<< "$out")" -eq 1 ] || { echo "$out"; fail "one Windows block should produce one finding"; }
echo "PASS"

echo "Test 5b: regressions from the critique pass (multi-line summary, code spans in a summary, word boundaries, indented code and headings, no interval expressions)"
make_readme "$tmp/multiline-summary" "# P

$platforms

<details>
<summary>
  Windows (PowerShell)
</summary>

\`\`\`powershell
export X=1
\`\`\`

</details>"
out=$("$checker" "$tmp/multiline-summary")
if grep -q 'summary:' <<< "$out" || grep -q 'no blank line after' <<< "$out"; then echo "$out"; fail "a multi-line <summary> produced false findings"; fi
grep -q 'windows: line 11' <<< "$out" || { echo "$out"; fail "Windows detection lost on a multi-line <summary>"; }
make_readme "$tmp/code-summary" "# P

$platforms

<details>
<summary>\`docker compose\` details</summary>

text

</details>

<details>
<summary>\`Windows\` (PowerShell)</summary>

\`\`\`powershell
export X=1
\`\`\`

</details>"
out=$("$checker" "$tmp/code-summary")
if grep -q 'summary:' <<< "$out"; then echo "$out"; fail "a code span in a summary made it look vague"; fi
grep -q 'windows: line 16' <<< "$out" || { echo "$out"; fail "Windows detection lost when the summary has a code span"; }
make_readme "$tmp/xfail" '# Tool

Supported platforms: Linux and Windows. Demos xfail on the CI runner.

```bash
make
```'
expect_finding "$tmp/xfail" 'but never mentions macOS' "\"Demos xfail\" must not count as a macOS mention"
make_readme "$tmp/indented-code" "# P

$platforms

An example of the pattern, as an indented code block:

    <details>
    <summary>More</summary>

Back to prose.

\`\`\`bash
make
\`\`\`"
expect_clean "$tmp/indented-code" "an indented code block containing <details> was treated as a real block"
make_readme "$tmp/indented-heading" '# P

- item

  <details>
  <summary>Manual installation</summary>

  ### Step one

  text

  </details>'
expect_finding "$tmp/indented-heading" 'heading: line 8: "### Step one" is inside the <details> opened at line 5' "an indented heading inside a list-item details block"
if grep -nE '\{[0-9]+(,[0-9]*)?\}' "$checker" | grep -v '^[0-9]*:#' | grep -q .; then
  grep -nE '\{[0-9]+(,[0-9]*)?\}' "$checker"; fail "an interval expression ({n,m}) is in the checker; older mawk builds silently fail to match them"
fi
echo "PASS"

echo "Test 6: tags inside fenced code and HTML comments are ignored"
make_readme "$tmp/documented" "# P

$platforms

Use collapsible sections like this:

\`\`\`markdown
<details>
<summary>More</summary>
## Not a heading in a block
\`\`\`

<!--
<details>
<summary>Click to expand</summary>
-->

\`\`\`bash
make
\`\`\`"
expect_clean "$tmp/documented" "a fenced or commented-out <details> example was treated as a real block"
make_readme "$tmp/inline" "# P

$platforms

Collapse long parts with \`<details>\` and a \`<summary>\` line; keep \`##\` headings outside.

## Next

\`\`\`bash
make
\`\`\`"
expect_clean "$tmp/inline" "a <details> mentioned in inline code was treated as a real block"
echo "PASS"

echo "Test 7: --file checks another document; no README is not a failure; usage errors exit 2"
mkdir -p "$tmp/other/docs"
printf '# Setup\n\n```bash\nmake\n```\n' > "$tmp/other/docs/SETUP.md"
status=0; "$checker" --strict --file docs/SETUP.md "$tmp/other" >/dev/null || status=$?
[ "$status" -eq 1 ] || fail "--file docs/SETUP.md with a bash-only block should fail --strict, got $status"
mkdir -p "$tmp/none"
out=$("$checker" --strict "$tmp/none") || fail "no README should exit 0"
grep -q 'nothing to verify' <<< "$out" || { echo "$out"; fail "expected the nothing-to-verify note"; }
status=0; "$checker" --strict --file missing.md "$tmp/none" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "an explicit missing --file exited $status, expected 2"
status=0; "$checker" --bogus >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "unknown option exited $status, expected 2"
status=0; "$checker" "$tmp/nope" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "missing root exited $status, expected 2"
echo "PASS"

echo "ALL TESTS PASSED"
