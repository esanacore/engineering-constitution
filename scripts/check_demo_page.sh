#!/usr/bin/env bash
set -euo pipefail

# GitHub Actions annotations (a no-op everywhere else); see scripts/lib/ci_annotations.sh.
if [ -f "$(dirname -- "$0")/lib/ci_annotations.sh" ]; then
  # shellcheck source=lib/ci_annotations.sh
  . "$(dirname -- "$0")/lib/ci_annotations.sh"
else
  ci_annotate() { :; }
fi

# Verify that a repository's demo.html meets the mechanical half of
# DOCUMENTATION.md's "Demo Page" standard. check_compliance.sh can only see
# that the file exists; a page that pulls its fonts from a CDN, loads a
# separate script file, points at a bundler's dist/ output, or calls an API on
# localhost passes that check and still fails the standard ("one file, no
# build, no backend, no network").
#
# What is checked (HTML comments are ignored):
#   remote    A resource load from the network: <script src>, <img src|srcset>,
#             <iframe>/<frame>/<embed src>, <object data>, <audio>/<video>/
#             <source>/<track src>, <video poster>, <input src>, SVG <use>/
#             <image href>, <link href> with a loading rel (stylesheet,
#             preload, preconnect, icon, ...), a remote <base href>, CSS
#             url(...) / @import, and JavaScript import/fetch/Worker/
#             WebSocket/EventSource calls with a literal URL. Navigation
#             links (<a href>) are not loads and may point anywhere.
#   external  A script or stylesheet in a separate local file (<script src>,
#             <link rel=stylesheet|modulepreload|manifest>, CSS @import, a
#             relative module import): styles and scripts must be inline.
#             Local images are allowed.
#   build     A reference into build output (dist/, build/, node_modules/,
#             .next/, .nuxt/ anywhere in a path; out/, target/ at its start):
#             the page must need no build.
#   private   A URL in a tag or script naming localhost or a private network
#             address (127/8, 10/8, 172.16/12, 192.168/16, 169.254/16,
#             0.0.0.0, [::1]): a published demo is world-readable and the
#             reader has no such backend running. Page text is not scanned,
#             so a labeled simulated transcript may show one.
#   readme    README.md does not link to demo.html.
#
# The judgement half of the standard — honest labeling of simulated output,
# currency with the product — stays with human review.
#
# This is governance tooling: a silent bug here removes the guarantee it appears
# to provide (see constitution TESTING.md, "Governance Tooling Must Be Tested").
#
# Exit status:
#   0  no findings (or, without --strict, findings were warnings), or no demo.html
#   1  at least one finding and --strict was passed
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_demo_page.sh [--strict] [project-root]

Description:
  Check <project-root>/demo.html against DOCUMENTATION.md's "Demo Page"
  standard: no remote resource loads, scripts and styles inline, no build
  output references, no localhost or private-network URLs, and a link to the
  page from README.md. A repository without demo.html has nothing to verify
  (whether it needs one is check_compliance.sh --product's question).

Arguments:
  project-root   Repository root. Default: current directory.

Options:
  --strict    Treat findings as failures instead of warnings.
  -h, --help  Show this help.
USAGE
}

strict=false
root=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --strict) strict=true; shift ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      if [ -n "$root" ]; then echo "Unexpected extra argument: $1" >&2; exit 2; fi
      root=$1; shift ;;
  esac
done

root=${root:-.}
if [ ! -d "$root" ]; then
  echo "Project root not found or not a directory: $root" >&2
  exit 2
fi
root=$(CDPATH= cd -- "$root" && pwd)
demo="$root/demo.html"

if [ ! -f "$demo" ]; then
  echo "No demo.html at the repository root; nothing to verify."
  exit 0
fi

echo "Demo page check: demo.html"
echo

# One awk pass: read the file as records split on "<", walk them with a small
# state machine (markup, comment, script body, style body), and print one
# "<kind>\t<detail>" line per finding. Comments are dropped; script and style
# bodies are collected so JavaScript and CSS are scanned as code while text
# in <pre>/<code> (a labeled simulated transcript, say) is not. Linear in the
# file size. POSIX awk only (mawk, gawk, BSD awk), matching the rest of scripts/.
scan=$(awk '
  function attr(tag_lc, tag, name,    re, v) {
    re = "[ \t/]" name "[ \t]*=[ \t]*(\"[^\"]*\"|\047[^\047]*\047|[^ \t>]+)"
    if (!match(tag_lc, re)) return ""
    v = substr(tag, RSTART, RLENGTH)
    sub(/^[^=]*=[ \t]*/, "", v)
    gsub(/^["\047]|["\047]$/, "", v)
    return v
  }
  # Index of the ">" that ends the tag at the start of piece p, skipping ">"
  # inside quoted attribute values (alt="a > b"); 0 if the piece has none.
  function tag_end(p,    i, c, q, last) {
    q = ""; last = ""
    for (i = 1; i <= length(p); i++) {
      c = substr(p, i, 1)
      if (q != "") { if (c == q) q = ""; continue }
      if ((c == "\"" || c == "\047") && last == "=") { q = c; continue }
      if (c == ">") return i
      if (c != " " && c != "\t") last = c
    }
    return 0
  }
  function is_remote(v) { return tolower(v) ~ /^[ \t]*((https?|wss?):)?\/\// }
  function is_inline(v) { return v == "" || tolower(v) ~ /^[ \t]*(data|blob|javascript):/ || v ~ /^[ \t]*#/ }
  function build_ref(v) {
    if (is_remote(v)) return 0
    return v ~ /(^|\/)(dist|build|node_modules|\.next|\.nuxt)\// || v ~ /^[ \t]*(\.\/)?(out|target)\//
  }
  function check_value(kind_tag, v, loads, external_ok) {
    if (v == "") return
    if (build_ref(v)) print "build\t" kind_tag " references " v
    if (!loads) return
    if (is_remote(v)) print "remote\t" kind_tag " loads " v
    else if (!external_ok && !is_inline(v)) print "external\t" kind_tag " loads the separate file " v
  }
  function check_tag(tag,    tag_lc, name, rel, href, srcset, st) {
    tag = " " tag
    tag_lc = tolower(tag)
    if (!match(tag_lc, /^ [a-z][a-z0-9-]*/)) return ""
    name = substr(tag_lc, 2, RLENGTH - 1)
    private_urls(tag)
    st = attr(tag_lc, tag, "style"); if (st != "") styles = styles " " st

    if (name == "a" || name == "area") {
      check_value("<" name " href>", attr(tag_lc, tag, "href"), 0, 1)
    } else if (name == "base") {
      href = attr(tag_lc, tag, "href")
      if (is_remote(href)) print "remote\t<base href> makes every relative URL load from " href
    } else if (name == "script") {
      check_value("<script src>", attr(tag_lc, tag, "src"), 1, 0)
    } else if (name == "link") {
      rel = tolower(attr(tag_lc, tag, "rel"))
      href = attr(tag_lc, tag, "href")
      if (rel ~ /(^| )(stylesheet|modulepreload|manifest)( |$)/)
        check_value("<link rel=\"" rel "\">", href, 1, 0)
      else if (rel ~ /(^| )(preload|prefetch|prerender|preconnect|dns-prefetch|icon|apple-touch-icon|mask-icon)( |$)/)
        check_value("<link rel=\"" rel "\">", href, 1, 1)
      else
        check_value("<link rel=\"" rel "\">", href, 0, 1)
    } else if (name ~ /^(img|iframe|frame|embed|audio|video|source|track|input)$/) {
      check_value("<" name " src>", attr(tag_lc, tag, "src"), 1, 1)
      srcset = attr(tag_lc, tag, "srcset")
      if (srcset ~ /(^|[ ,])((https?:)?\/\/)/) print "remote\t<" name " srcset> loads " srcset
      if (name == "video") check_value("<video poster>", attr(tag_lc, tag, "poster"), 1, 1)
    } else if (name == "object") {
      check_value("<object data>", attr(tag_lc, tag, "data"), 1, 1)
    } else if (name == "use" || name == "image") {
      check_value("<" name " href>", attr(tag_lc, tag, "href"), 1, 1)
      check_value("<" name " xlink:href>", attr(tag_lc, tag, "xlink:href"), 1, 1)
    }
    return name
  }
  # Private-network URLs in tags and scripts (not in page text, where a
  # labeled simulated transcript may legitimately show one).
  function private_urls(t,    v) {
    while (match(tolower(t), /((https?|wss?):)?\/\/(localhost|127\.[0-9]+\.[0-9]+\.[0-9]+|0\.0\.0\.0|10\.[0-9]+\.[0-9]+\.[0-9]+|192\.168\.[0-9]+\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+|169\.254\.[0-9]+\.[0-9]+|\[::1\])/)) {
      v = substr(t, RSTART, RLENGTH); t = substr(t, RSTART + RLENGTH)
      if (tolower(substr(t, 1, 1)) ~ /[a-z0-9.-]/) continue   # localhost.example.com
      if (match(t, /^[:\/?#][^"\047` \t<>)]*/)) { v = v substr(t, 1, RLENGTH); t = substr(t, RLENGTH + 1) }
      print "private\tURL targets a private network: " v
    }
  }
  BEGIN { RS = "<"; state = "markup" }   # markup | comment | script | style
  NR > 1 {
    p = $0
    gsub(/[\r\n]/, " ", p)
    if (state == "comment") {
      j = index(p, "-->"); if (j > 0) state = "markup"
      next
    }
    if (state == "script" || state == "style") {
      if (tolower(p) ~ ("^/" state)) { state = "markup"; next }
      if (state == "script") scripts = scripts "<" p; else styles = styles "<" p
      next
    }
    if (substr(p, 1, 3) == "!--") {
      if (index(substr(p, 4), "-->") == 0) state = "comment"
      next
    }
    e = tag_end(p)
    tag = (e > 0) ? substr(p, 1, e - 1) : p
    name = check_tag(tag)
    if ((name == "script" || name == "style") && tag !~ /\/[ \t]*$/) {
      state = name
      body = (e > 0) ? substr(p, e + 1) : ""
      if (name == "script") scripts = scripts " " body; else styles = styles " " body
    }
  }
  END {

    # CSS (style bodies and style attributes): @import is always a separate
    # file; url() is fine unless remote.
    t = styles
    while (match(tolower(t), /@import[ \t]+(url\()?[ \t]*["\047]?[^"\047); \t]+/)) {
      v = substr(t, RSTART, RLENGTH); t = substr(t, RSTART + RLENGTH)
      sub(/^@[Ii][Mm][Pp][Oo][Rr][Tt][ \t]+([Uu][Rr][Ll]\()?[ \t]*["\047]?/, "", v)
      if (is_remote(v)) print "remote\tCSS @import loads " v
      else print "external\tCSS @import loads the separate file " v
    }
    t = styles
    gsub(/@[Ii][Mm][Pp][Oo][Rr][Tt][^;]*;/, "", t)
    while (match(tolower(t), /url\([ \t]*["\047]?((https?:)?\/\/)[^"\047) \t]+/)) {
      v = substr(t, RSTART, RLENGTH); t = substr(t, RSTART + RLENGTH)
      sub(/^[Uu][Rr][Ll]\([ \t]*["\047]?/, "", v)
      print "remote\tCSS url() loads " v
    }

    # JavaScript: module imports, fetches, workers, and sockets with a literal
    # URL. A remote one is a network dependency; a relative module import is
    # a separate file.
    t = scripts
    while (match(tolower(t), /(^|[^a-z0-9_$.])(from|import|fetch|importscripts|worker|sharedworker|eventsource|websocket)[ \t]*\(?[ \t]*["\047`][^"\047`]+/)) {
      v = substr(t, RSTART, RLENGTH); t = substr(t, RSTART + RLENGTH)
      sub(/^[^"\047`]*["\047`]/, "", v)
      if (is_remote(v)) print "remote\tscript loads " v
      else if (v ~ /^(\.\.?)?\//) print "external\tscript imports the separate file " v
    }

    private_urls(scripts)
  }
' "$demo" | awk '!seen[$0]++')

readme_ok=false
if [ -f "$root/README.md" ] && grep -qE '\]\([^)]*demo\.html|href=["'"'"'][^"'"'"']*demo\.html|^\[[^]]+\]:[[:space:]]*[^[:space:]]*demo\.html' "$root/README.md"; then
  readme_ok=true
fi

findings=0
report() {
  echo "  PROBLEM  $1: $2"
  findings=$((findings + 1))
}

while IFS=$'\t' read -r kind detail; do
  [ -n "$kind" ] || continue
  report "$kind" "$detail"
done <<< "$scan"

if [ "$readme_ok" = "false" ]; then
  if [ -f "$root/README.md" ]; then
    report readme "README.md does not link to demo.html"
  else
    report readme "no README.md to link demo.html from"
  fi
fi

if [ "$findings" -eq 0 ]; then
  echo "  OK       single file, no network, no build output, linked from README.md"
  echo
  echo "demo.html meets the mechanical Demo Page checks."
  exit 0
fi

echo
echo "$findings finding(s) against DOCUMENTATION.md's \"Demo Page\" standard."
if [ "$strict" = "true" ]; then
  echo "FAIL: demo page problems (--strict)."
  ci_annotate error "check_demo_page.sh: $findings demo page finding(s) in demo.html"
  exit 1
fi
echo "WARN: demo page problems (pass --strict to enforce)."
ci_annotate warning "check_demo_page.sh: $findings demo page finding(s) in demo.html (pass --strict to enforce)"
exit 0
