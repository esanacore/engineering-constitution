#!/usr/bin/env bash
set -euo pipefail

# Negative-case tests for scripts/check_demo_page.sh.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
checker="$script_dir/check_demo_page.sh"
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

make_repo() {
  # make_repo <dir> <demo.html body> [README body]
  mkdir -p "$1"
  printf '%s\n' "$2" > "$1/demo.html"
  printf '%s\n' "${3:-# Project

Open [the demo](demo.html).}" > "$1/README.md"
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

clean_page='<!doctype html>
<html><head><meta charset="utf-8"><title>Demo</title>
<link rel="canonical" href="https://example.github.io/project/demo.html">
<link rel="icon" href="data:image/svg+xml,%3Csvg%3E%3C/svg%3E">
<style>body { font-family: system-ui, sans-serif; background: url("data:image/png;base64,AAAA"); }</style>
</head><body>
<!-- <link rel="stylesheet" href="https://cdn.example.com/commented-out.css"> -->
<img src="assets/screenshot.png" alt="Local images are allowed">
<a href="https://github.com/example/project">Source</a>
<a href="https://example.com/build/notes">A remote page whose path says build/</a>
<script>const simulated = true; if (1 < 2) { console.log("inline"); }</script>
</body></html>'

echo "Test 1: a self-contained page linked from README.md passes under --strict"
make_repo "$tmp/clean" "$clean_page"
out=$("$checker" --strict "$tmp/clean") || { echo "$out"; fail "clean page failed --strict"; }
grep -q 'meets the mechanical Demo Page checks' <<< "$out" || { echo "$out"; fail "expected the OK summary"; }
echo "PASS"

echo "Test 2: remote resource loads are caught, including multi-line and single-quoted tags"
make_repo "$tmp/cdn-font" '<html><head>
<link
  rel="stylesheet"
  href="https://fonts.googleapis.com/css2?family=Inter">
</head><body></body></html>'
expect_finding "$tmp/cdn-font" 'remote: <link rel="stylesheet"> loads https://fonts.googleapis.com/css2?family=Inter' "multi-line CDN stylesheet"
make_repo "$tmp/cdn-script" "<script src='//cdn.example.com/lib.js'></script>"
expect_finding "$tmp/cdn-script" "remote: <script src> loads //cdn.example.com/lib.js" "protocol-relative script"
make_repo "$tmp/preconnect" '<LINK REL="preconnect" HREF="https://fonts.gstatic.com">'
expect_finding "$tmp/preconnect" 'remote: <link rel="preconnect"> loads https://fonts.gstatic.com' "uppercase preconnect"
make_repo "$tmp/img" '<img alt="x" src="https://images.example.com/hero.png">'
expect_finding "$tmp/img" 'remote: <img src> loads https://images.example.com/hero.png' "remote image"
make_repo "$tmp/srcset" '<img src="a.png" srcset="a.png 1x, https://images.example.com/a@2x.png 2x">'
expect_finding "$tmp/srcset" 'remote: <img srcset>' "remote srcset candidate"
make_repo "$tmp/iframe" '<iframe src="https://www.youtube.com/embed/abc"></iframe>'
expect_finding "$tmp/iframe" 'remote: <iframe src> loads https://www.youtube.com/embed/abc' "remote iframe"
make_repo "$tmp/poster" '<video src="clip.mp4" poster="https://cdn.example.com/poster.jpg"></video>'
expect_finding "$tmp/poster" 'remote: <video poster> loads https://cdn.example.com/poster.jpg' "remote poster"
echo "PASS"

echo "Test 3: CSS url() and @import are caught; @import is reported once"
make_repo "$tmp/css-url" '<style>.hero { background: url( "https://cdn.example.com/bg.jpg" ); }</style>'
expect_finding "$tmp/css-url" 'remote: CSS url() loads https://cdn.example.com/bg.jpg' "remote CSS url()"
make_repo "$tmp/css-import" "<style>@import url('https://fonts.googleapis.com/css2?family=Inter');</style>"
expect_finding "$tmp/css-import" 'remote: CSS @import loads https://fonts.googleapis.com/css2?family=Inter' "remote @import"
out=$("$checker" "$tmp/css-import")
[ "$(grep -c 'PROBLEM' <<< "$out")" -eq 1 ] || { echo "$out"; fail "@import url(...) should be one finding, not two"; }
make_repo "$tmp/dup" '<script src="https://cdn.example.com/a.js"></script><script src="https://cdn.example.com/a.js"></script>'
out=$("$checker" "$tmp/dup")
[ "$(grep -c 'PROBLEM' <<< "$out")" -eq 1 ] || { echo "$out"; fail "the same load twice should be one finding"; }
make_repo "$tmp/css-local-import" '<style>@import "theme.css";</style>'
expect_finding "$tmp/css-local-import" 'external: CSS @import loads the separate file theme.css' "local @import"
echo "PASS"

echo "Test 4: separate local scripts and stylesheets are caught; local images are not"
make_repo "$tmp/local-script" '<script src="app.js"></script><img src="shot.png">'
expect_finding "$tmp/local-script" 'external: <script src> loads the separate file app.js' "local script"
out=$("$checker" "$tmp/local-script")
if grep -q 'shot.png' <<< "$out"; then echo "$out"; fail "a local image was reported"; fi
make_repo "$tmp/local-css" '<link href="styles/site.css" rel="stylesheet">'
expect_finding "$tmp/local-css" 'external: <link rel="stylesheet"> loads the separate file styles/site.css' "local stylesheet (attribute order reversed)"
echo "PASS"

echo "Test 5: build output references are caught, on links as well as loads"
make_repo "$tmp/build" '<script src="./dist/bundle.js"></script>'
expect_finding "$tmp/build" 'build: <script src> references ./dist/bundle.js' "dist/ bundle"
make_repo "$tmp/build-link" '<a href="build/index.html">Run the real app</a>'
expect_finding "$tmp/build-link" 'build: <a href> references build/index.html' "link into build/"
make_repo "$tmp/node-modules" '<script src="node_modules/chart.js/dist/chart.umd.js"></script>'
expect_finding "$tmp/node-modules" 'build: <script src> references node_modules/chart.js/dist/chart.umd.js' "node_modules/"
echo "PASS"

echo "Test 6: localhost and private-network URLs are caught, in scripts too"
make_repo "$tmp/localhost" '<script>fetch("http://localhost:3000/api/status").then(r => r.json());</script>'
expect_finding "$tmp/localhost" 'private: URL targets a private network: http://localhost:3000/api/status' "fetch to localhost"
make_repo "$tmp/lan" '<a href="http://192.168.1.20:8080/">Device console</a>'
expect_finding "$tmp/lan" 'private: URL targets a private network: http://192.168.1.20:8080/' "LAN address"
make_repo "$tmp/ws" '<script>new WebSocket("ws://10.0.0.5/feed")</script>'
expect_finding "$tmp/ws" 'private: URL targets a private network: ws://10.0.0.5/feed' "websocket to 10/8"
make_repo "$tmp/public-172" '<a href="https://172.217.0.1/">Not private (outside 172.16/12)</a>'
"$checker" --strict "$tmp/public-172" >/dev/null || fail "172.217.x.x is public and must not be reported"
echo "PASS"

echo "Test 7: README.md must link to demo.html"
make_repo "$tmp/no-link" '<p>demo</p>' '# Project

Mentions demo.html in prose but never links it.'
expect_finding "$tmp/no-link" 'readme: README.md does not link to demo.html' "unlinked README"
mkdir -p "$tmp/no-readme"; printf '<p>demo</p>\n' > "$tmp/no-readme/demo.html"
expect_finding "$tmp/no-readme" 'readme: no README.md to link demo.html from' "missing README"
make_repo "$tmp/pages-link" '<p>demo</p>' '[![Demo](assets/shot.png)](https://example.github.io/project/demo.html)'
"$checker" --strict "$tmp/pages-link" >/dev/null || fail "an absolute GitHub Pages link should satisfy the README check"
make_repo "$tmp/ref-link" '<p>demo</p>' 'See the [demo][d].

[d]: ./demo.html'
"$checker" --strict "$tmp/ref-link" >/dev/null || fail "a reference-style link should satisfy the README check"
make_repo "$tmp/html-link" '<p>demo</p>' '<a href="demo.html">Demo</a>'
"$checker" --strict "$tmp/html-link" >/dev/null || fail "an HTML anchor should satisfy the README check"
echo "PASS"

echo "Test 8: regressions from the critique pass (module imports, SVG, <base>, quoted '>', text vs code)"
make_repo "$tmp/esm" '<script type="module">import confetti from "https://esm.sh/canvas-confetti";</script>'
expect_finding "$tmp/esm" 'remote: script loads https://esm.sh/canvas-confetti' "static ES-module CDN import"
make_repo "$tmp/dyn" "<script>const m = await import('https://cdn.jsdelivr.net/npm/x/+esm'); fetch(\"https://api.github.com/repos/a/b\");</script>"
expect_finding "$tmp/dyn" 'remote: script loads https://cdn.jsdelivr.net/npm/x/+esm' "dynamic import"
expect_finding "$tmp/dyn" 'remote: script loads https://api.github.com/repos/a/b' "fetch to a public API"
make_repo "$tmp/local-module" '<script type="module">import { run } from "./app.js"; run();</script>'
expect_finding "$tmp/local-module" 'external: script imports the separate file ./app.js' "relative module import"
make_repo "$tmp/svg" '<svg><use href="https://cdn.example.com/sprite.svg#i"/><image xlink:href="https://cdn.example.com/p.png"/></svg>'
expect_finding "$tmp/svg" 'remote: <use href> loads https://cdn.example.com/sprite.svg#i' "SVG use"
expect_finding "$tmp/svg" 'remote: <image xlink:href> loads https://cdn.example.com/p.png' "SVG image xlink:href"
make_repo "$tmp/base" '<base href="https://cdn.example.com/"><img src="hero.png">'
expect_finding "$tmp/base" 'remote: <base href> makes every relative URL load from https://cdn.example.com/' "remote base"
make_repo "$tmp/gt" '<img alt="a > b" src="https://cdn.example.com/x.png">'
expect_finding "$tmp/gt" 'remote: <img src> loads https://cdn.example.com/x.png' "'>' inside a quoted attribute"
make_repo "$tmp/js-comment-marker" '<script>const s = "<!--";</script><script src="https://cdn.example.com/late.js"></script>'
expect_finding "$tmp/js-comment-marker" 'remote: <script src> loads https://cdn.example.com/late.js' "'<!--' inside a script string"
make_repo "$tmp/proto-rel-private" '<script>fetch("//localhost:3000/api")</script>'
expect_finding "$tmp/proto-rel-private" 'private: URL targets a private network: //localhost:3000/api' "protocol-relative localhost"
make_repo "$tmp/metadata" '<script>fetch("http://169.254.169.254/latest/meta-data/")</script>'
expect_finding "$tmp/metadata" 'private: URL targets a private network: http://169.254.169.254/latest/meta-data/' "link-local metadata address"
make_repo "$tmp/prose" '<p><strong>Simulated.</strong> The real service answers:</p>
<pre>$ curl http://localhost:8080/health
{"ok": true}</pre>
<code>@import "reset.css";</code>
<img src="images/out/logo.png" alt="out/ mid-path is not build output">
<a href="https://localhost.example.com/">A public host that starts with localhost</a>'
out=$("$checker" --strict "$tmp/prose") || { echo "$out"; fail "page text, mid-path out/, and localhost.example.com must not be reported"; }
echo "PASS"

echo "Test 9: the shipped template passes; no demo.html is not a failure; usage errors exit 2"
mkdir -p "$tmp/template"
cp "$repo_root/templates/demo.html" "$tmp/template/demo.html"
printf '[Demo](demo.html)\n' > "$tmp/template/README.md"
out=$("$checker" --strict "$tmp/template") || { echo "$out"; fail "templates/demo.html must pass its own checker"; }
mkdir -p "$tmp/none"
out=$("$checker" --strict "$tmp/none") || fail "no demo.html should exit 0"
grep -q 'nothing to verify' <<< "$out" || { echo "$out"; fail "expected the nothing-to-verify note"; }
status=0; "$checker" --bogus >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "unknown option exited $status, expected 2"
status=0; "$checker" "$tmp/nope" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "missing root exited $status, expected 2"
status=0; "$checker" "$tmp/none" "$tmp/none" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "extra argument exited $status, expected 2"
echo "PASS"

echo "ALL TESTS PASSED"
