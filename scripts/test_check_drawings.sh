#!/usr/bin/env bash
set -euo pipefail

# Negative-case tests for scripts/check_drawings.sh.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
checker="$script_dir/check_drawings.sh"
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

good_plate='<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 216 300">
<defs><pattern id="hatch" width="1" height="1"><line x1="0" y1="0" x2="0" y2="1"/></pattern></defs>
<rect width="216" height="300" fill="url(#hatch)"/>
<text x="10" y="10">10</text><text x="20" y="10"> 12 </text><text x="30" y="10">14</text>
<text x="108" y="288">A decorative plate. It is not a patent or a patent application.</text>
</svg>'

good_key='# Drawings

![Plate](plate.svg)

## Key

| No. | Part |
| --- | --- |
| 10 | The first part |
| 12 | The second part |
| 14 | The third part |'

make_repo() {
  # make_repo <dir> [plate] [key] [README]
  mkdir -p "$1/docs/drawings"
  printf '%s\n' "${2:-$good_plate}" > "$1/docs/drawings/plate.svg"
  printf '%s\n' "${3:-$good_key}" > "$1/docs/drawings/README.md"
  printf '%s\n' "${4:-# Project

See [the drawings](docs/drawings/README.md).}" > "$1/README.md"
}

# expect_finding <dir> <grep pattern> <description>: warn mode reports it and
# exits 0; --strict exits 1.
expect_finding() {
  local status=0 out
  out=$("$checker" "$1") || status=$?
  [ "$status" -eq 0 ] || { echo "$out"; fail "$3: warn mode exited $status"; }
  grep -qF -- "$2" <<< "$out" || { echo "$out"; fail "$3: expected '$2'"; }
  status=0; "$checker" --strict "$1" >/dev/null || status=$?
  [ "$status" -eq 1 ] || fail "$3: --strict exited $status, expected 1"
}

echo "Test 1: a filled-in plate with a matching key, linked from README.md, passes under --strict"
make_repo "$tmp/clean"
out=$("$checker" --strict "$tmp/clean") || { echo "$out"; fail "clean drawings failed --strict"; }
grep -q 'meets the mechanical Drawings checks' <<< "$out" || { echo "$out"; fail "expected the OK summary"; }
grep -q 'PROBLEM' <<< "$out" && { echo "$out"; fail "clean drawings reported a problem"; }
echo "PASS"

echo "Test 2: a repository without docs/drawings has nothing to verify"
mkdir -p "$tmp/none"
out=$("$checker" --strict "$tmp/none") || fail "no docs/drawings should exit 0"
grep -q 'nothing to verify' <<< "$out" || { echo "$out"; fail "expected the nothing-to-verify note"; }
echo "PASS"

echo "Test 3: a missing plate, and a plate that is not SVG"
make_repo "$tmp/noplate"; rm "$tmp/noplate/docs/drawings/plate.svg"
expect_finding "$tmp/noplate" "plate: docs/drawings/plate.svg is missing" "missing plate"
make_repo "$tmp/notsvg" "just some text that is not a patent drawing"
expect_finding "$tmp/notsvg" "plate: docs/drawings/plate.svg is not an SVG document" "non-SVG plate"
echo "PASS"

echo "Test 4: the shipped template copied but not filled in"
mkdir -p "$tmp/template/docs/drawings"
cp "$repo_root/templates/docs/drawings/plate.svg" "$tmp/template/docs/drawings/plate.svg"
cp "$repo_root/templates/docs/drawings/README.md" "$tmp/template/docs/drawings/README.md"
printf 'See docs/drawings/README.md\n' > "$tmp/template/README.md"
expect_finding "$tmp/template" "placeholder: the plate is still the shipped template" "unfilled template"
echo "PASS"

echo "Test 5: a plate that does not say it is not a patent"
make_repo "$tmp/nodisc" "${good_plate//It is not a patent or a patent application./}"
expect_finding "$tmp/nodisc" "disclaimer: the plate does not say it is not a patent" "missing disclaimer"
echo "PASS"

echo "Test 6: remote loads are findings; xmlns declarations and local references are not"
make_repo "$tmp/font" "${good_plate/<defs>/<defs><style>@font-face { font-family: X; src: url(https://fonts.example.com/x.woff2); }</style>}"
expect_finding "$tmp/font" "remote: the plate loads from the network" "remote font"
make_repo "$tmp/image" "${good_plate/<rect/<image href=\"https://example.com/photo.png\" width=\"10\" height=\"10\"/><rect}"
expect_finding "$tmp/image" "remote: the plate loads from the network" "remote image"
make_repo "$tmp/xlink" "${good_plate/<rect/<image xlink:href=\"//cdn.example.com/photo.png\" width=\"10\" height=\"10\"/><rect}"
expect_finding "$tmp/xlink" "remote: the plate loads from the network" "protocol-relative xlink:href"
out=$("$checker" --strict "$tmp/clean") || { echo "$out"; fail "xmlns and url(#id) must not count as remote loads"; }
echo "PASS"

echo "Test 7: the key must exist, list three numerals, and match the plate"
make_repo "$tmp/nokey"; rm "$tmp/nokey/docs/drawings/README.md"
expect_finding "$tmp/nokey" "key: docs/drawings/README.md is missing" "missing key"
make_repo "$tmp/shortkey" "" '# Drawings

## Key

| No. | Part |
| --- | --- |
| 10 | Only one |'
expect_finding "$tmp/shortkey" "lists 1 reference numeral(s)" "short key"
make_repo "$tmp/prose" "" '# Drawings

10 is the first part, 12 the second, 14 the third. No table.'
expect_finding "$tmp/prose" "lists 0 reference numeral(s)" "key written as prose"
make_repo "$tmp/nohead" "" "$(grep -v '^## Key$' <<< "$good_key")"
expect_finding "$tmp/nohead" "lists 0 reference numeral(s)" "numbered table with no Key heading"
make_repo "$tmp/extra" "" "$good_key
| 99 | A part the plate never shows |"
expect_finding "$tmp/extra" "key: the key lists 99 but the plate does not show it" "numeral missing from the plate"
out=$("$checker" "$tmp/extra")
grep -q 'the key lists 10 ' <<< "$out" && { echo "$out"; fail "a numeral the plate shows was reported missing"; }
# 1 must not be satisfied by 10, 12, or 14 on the plate.
make_repo "$tmp/prefix" "" "$good_key
| 1 | A part numbered with a prefix of the others |"
expect_finding "$tmp/prefix" "key: the key lists 1 but the plate does not show it" "numeral that is only a prefix"
echo "PASS"

echo "Test 8: README.md must point at docs/drawings/"
make_repo "$tmp/unlinked" "" "" "# Project

No pointer here."
expect_finding "$tmp/unlinked" "readme: README.md does not point at docs/drawings/" "unlinked drawings"
make_repo "$tmp/noreadme"; rm "$tmp/noreadme/README.md"
expect_finding "$tmp/noreadme" "readme: no README.md to point at docs/drawings/ from" "no README.md"
echo "PASS"

echo "Test 9: CAD in the repository calls for a drawing set"
make_repo "$tmp/cad"
mkdir -p "$tmp/cad/hardware"; : > "$tmp/cad/hardware/case.scad"
expect_finding "$tmp/cad" "physical: CAD found (hardware/case.scad)" "CAD without a drawing set"
# A section that links a file that does not exist is still a finding.
make_repo "$tmp/cadmissing" "" "$good_key

## Drawing set

- [Sheet 1](sheet1.svg)"
mkdir -p "$tmp/cadmissing/hardware"; : > "$tmp/cadmissing/hardware/case.STEP"
expect_finding "$tmp/cadmissing" "physical: CAD found (hardware/case.STEP)" "drawing set linking a missing file"
# A link outside the section does not count.
make_repo "$tmp/cadoutside" "" "$good_key

[A stray sheet](sheet1.svg)

## Drawing set

Coming soon.

## Something else

- [Sheet 1](sheet1.svg)"
: > "$tmp/cadoutside/docs/drawings/sheet1.svg"
mkdir -p "$tmp/cadoutside/hardware"; : > "$tmp/cadoutside/hardware/case.stl"
expect_finding "$tmp/cadoutside" "physical: CAD found (hardware/case.stl)" "link outside the Drawing set section"
# The real thing: a section linking a sheet that exists, in a subdirectory or elsewhere in the repository.
make_repo "$tmp/cadok" "" "$good_key

# Drawing Set

| Sheet | File |
| --- | --- |
| 1 | [Base](sheets/base.svg) |
| all | [PDF](../../hardware/cad/drawings/set.pdf \"the set\") |"
mkdir -p "$tmp/cadok/hardware/cad/drawings" "$tmp/cadok/docs/drawings/sheets"
: > "$tmp/cadok/hardware/case.scad"; : > "$tmp/cadok/docs/drawings/sheets/base.svg"
out=$("$checker" --strict "$tmp/cadok") || { echo "$out"; fail "a real drawing set failed --strict"; }
grep -q 'a drawing set for the physical component' <<< "$out" || { echo "$out"; fail "expected the drawing-set OK line"; }
# Only the PDF elsewhere in the repository exists.
rm "$tmp/cadok/docs/drawings/sheets/base.svg"; : > "$tmp/cadok/hardware/cad/drawings/set.pdf"
out=$("$checker" --strict "$tmp/cadok") || { echo "$out"; fail "a drawing set stored outside docs/drawings failed --strict"; }
echo "PASS"

echo "Test 10: CAD under vendored or generated trees is not the repository's own"
make_repo "$tmp/vendored"
mkdir -p "$tmp/vendored/constitution/x" "$tmp/vendored/node_modules/y" "$tmp/vendored/build"
: > "$tmp/vendored/constitution/x/a.scad"; : > "$tmp/vendored/node_modules/y/b.stl"; : > "$tmp/vendored/build/c.step"
out=$("$checker" --strict "$tmp/vendored") || { echo "$out"; fail "vendored CAD triggered the physical check"; }
echo "PASS"

echo "Test 11: several problems are all reported and counted"
make_repo "$tmp/many" "${good_plate//It is not a patent or a patent application./}" "" "# Project"
out=$("$checker" "$tmp/many")
grep -q '2 finding(s)' <<< "$out" || { echo "$out"; fail "expected 2 findings"; }
echo "PASS"

echo "Test 12: the framework's own plate and the sample project's pass under --strict"
out=$("$checker" --strict "$repo_root") || { echo "$out"; fail "the framework's own drawings fail its checker"; }
out=$("$checker" --strict "$repo_root/examples/sample-project") || { echo "$out"; fail "the sample project's drawings fail the checker"; }
echo "PASS"

echo "Test 13: usage errors exit 2"
status=0; "$checker" --bogus >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "unknown option exited $status, expected 2"
status=0; "$checker" "$tmp/nope" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "missing root exited $status, expected 2"
status=0; "$checker" "$tmp/none" "$tmp/none" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "extra argument exited $status, expected 2"
"$checker" --help | grep -q '^Usage:' || fail "--help printed no Usage: block"
echo "PASS"

echo "Test 14: findings are annotated under GitHub Actions"
out=$(GITHUB_ACTIONS=true "$checker" "$tmp/unlinked")
grep -q '^::warning::check_drawings.sh' <<< "$out" || { echo "$out"; fail "no ::warning:: annotation in warn mode"; }
status=0; out=$(GITHUB_ACTIONS=true "$checker" --strict "$tmp/unlinked") || status=$?
[ "$status" -eq 1 ] || fail "--strict exited $status"
grep -q '^::error::check_drawings.sh' <<< "$out" || { echo "$out"; fail "no ::error:: annotation under --strict"; }
echo "PASS"

echo "ALL TESTS PASSED"
