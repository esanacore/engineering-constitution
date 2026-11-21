#!/usr/bin/env bash
set -euo pipefail

# GitHub Actions annotations (a no-op everywhere else); see scripts/lib/ci_annotations.sh.
if [ -f "$(dirname -- "$0")/lib/ci_annotations.sh" ]; then
  # shellcheck source=lib/ci_annotations.sh
  . "$(dirname -- "$0")/lib/ci_annotations.sh"
else
  ci_annotate() { :; }
fi

# Verify the mechanical half of DOCUMENTATION.md's "Drawings" standard
# (ADR-0008). check_compliance.sh can only see that docs/drawings/ exists; a
# plate that is still the template, loads a font from the network, shows
# numbers nobody explains, or sits unlinked passes that check and still fails
# the standard.
#
# What is checked:
#   plate        docs/drawings/plate.svg is missing or is not an SVG document.
#   placeholder  The plate is still the shipped template.
#   disclaimer   The plate does not say it is not a patent. A drawing in the
#                style of a patent plate, carrying an inventor's name, must
#                not be mistakable for a filing.
#   remote       The plate loads something from the network (an http(s) or
#                protocol-relative URL in href, src, or url(...)). Namespace
#                declarations (xmlns) are not loads.
#   key          docs/drawings/README.md is missing, lists fewer than three
#                reference numerals in the table under its "Key" heading,
#                or lists a numeral the plate does not show.
#   readme       README.md does not point at docs/drawings/.
#   physical     The repository holds CAD (.scad, .step, .stp, .stl, .3mf,
#                .FCStd, .f3d, .sldprt, .sldasm, .ipt, .iam) but
#                docs/drawings/README.md has no "Drawing set" section linking
#                at least one drawing file (.svg or .pdf) that exists.
#   titleblock   A linked SVG sheet of the drawing set has no title-block
#                field for revision, scale, units, date, or sheet number.
#   detail       The linked SVG sheets, taken together, show no section view,
#                no parts list (a QTY column), no material note, no tolerance
#                note, or no projection convention. This is the floor on
#                detail; the plate and formal figure sheets are not inspected.
#
# The judgement half -- whether the figure shows the real system, whether a
# drawing set is complete enough to build from, whether both are current --
# stays with human review.
#
# This is governance tooling: a silent bug here removes the guarantee it appears
# to provide (see constitution TESTING.md, "Governance Tooling Must Be Tested").
#
# Exit status:
#   0  no findings (or, without --strict, findings were warnings), or no docs/drawings
#   1  at least one finding and --strict was passed
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_drawings.sh [--strict] [project-root]

Description:
  Check <project-root>/docs/drawings against DOCUMENTATION.md's "Drawings"
  standard: a patent-style plate (plate.svg) that is filled in, says it is
  not a patent, and loads nothing from the network; a numbered key in
  docs/drawings/README.md whose numerals all appear on the plate; a pointer
  from README.md; and, where the repository holds CAD, a "Drawing set"
  section linking drawing files that exist, each SVG sheet carrying a title
  block and the set carrying a section, a parts list, and material, tolerance
  and projection notes. A repository without
  docs/drawings has nothing to verify (whether it needs one is
  check_compliance.sh's question).

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
dir="$root/docs/drawings"
plate="$dir/plate.svg"
key="$dir/README.md"

if [ ! -d "$dir" ]; then
  echo "No docs/drawings at the repository root; nothing to verify."
  exit 0
fi

echo "Drawings check: docs/drawings"
echo

findings=0
report() {
  echo "  PROBLEM  $1: $2"
  findings=$((findings + 1))
}

plate_ok=false
if [ ! -f "$plate" ]; then
  report plate "docs/drawings/plate.svg is missing"
elif ! grep -q '<svg' "$plate"; then
  report plate "docs/drawings/plate.svg is not an SVG document"
else
  plate_ok=true
fi

if [ "$plate_ok" = "true" ]; then
  if grep -q 'constitution-plate-template-placeholder' "$plate"; then
    report placeholder "the plate is still the shipped template; draw the project and remove the marker comment"
  fi

  if ! grep -qi 'not a patent' "$plate"; then
    report disclaimer "the plate does not say it is not a patent"
  fi

  # Remote loads: an http(s) or protocol-relative URL inside href/src (with or
  # without the xlink: prefix) or a CSS url(...). xmlns declarations are
  # namespace names, not loads, and are dropped first.
  remote=$(sed -E 's/xmlns(:[A-Za-z]+)?="[^"]*"//g' "$plate" \
    | grep -oiE "((xlink:)?href|src)[[:space:]]*=[[:space:]]*[\"'](https?:)?//[^\"']*|url\([[:space:]]*[\"']?(https?:)?//[^)\"']*" \
    | head -n 5 || true)
  if [ -n "$remote" ]; then
    while IFS= read -r hit; do
      [ -n "$hit" ] || continue
      report remote "the plate loads from the network: $hit"
    done <<< "$remote"
  fi
fi

# The key: table rows whose first cell is a number.
numerals=""
if [ ! -f "$key" ]; then
  report key "docs/drawings/README.md is missing (it holds the plate's numbered key)"
else
  # Rows of the table under the "Key" heading (any level), up to the next
  # heading of the same or a higher level. Other tables in the file, such as
  # a numbered sheet list, are not reference numerals.
  numerals=$(awk '
    /^#+[ \t]/ {
      level = index($0, " ") - 1
      if (insec && level <= seclevel) insec = 0
      if (tolower($0) ~ /^#+[ \t]+key[ \t]*$/) { insec = 1; seclevel = level; next }
    }
    insec && /^\|[ \t]*[0-9]+[ \t]*\|/ {
      n = $0; sub(/^\|[ \t]*/, "", n); sub(/[ \t]*\|.*$/, "", n); print n
    }
  ' "$key" | sort -n -u || true)
  count=$(printf '%s\n' "$numerals" | grep -c . || true)
  if [ "$count" -lt 3 ]; then
    report key "docs/drawings/README.md lists $count reference numeral(s) under its \"Key\" heading; a plate needs at least 3"
  elif [ "$plate_ok" = "true" ]; then
    while IFS= read -r n; do
      [ -n "$n" ] || continue
      if ! grep -qE ">[[:space:]]*$n[[:space:]]*<" "$plate"; then
        report key "the key lists $n but the plate does not show it"
      fi
    done <<< "$numerals"
  fi
fi

if [ -f "$root/README.md" ]; then
  if ! grep -q 'docs/drawings/' "$root/README.md"; then
    report readme "README.md does not point at docs/drawings/"
  fi
else
  report readme "no README.md to point at docs/drawings/ from"
fi

# Physical component: any CAD file outside vendored and generated trees.
cad=$(find "$root" \
  \( -name .git -o -name constitution -o -name node_modules -o -name .venv -o -name vendor -o -name build -o -name dist \) -prune -o \
  -type f \( -iname '*.scad' -o -iname '*.step' -o -iname '*.stp' -o -iname '*.stl' -o -iname '*.3mf' \
    -o -iname '*.fcstd' -o -iname '*.f3d' -o -iname '*.sldprt' -o -iname '*.sldasm' -o -iname '*.ipt' -o -iname '*.iam' \) \
  -print 2>/dev/null | head -n 1 || true)

if [ -n "$cad" ]; then
  cad_rel=${cad#"$root"/}
  set_ok=false
  sheets=()
  if [ -f "$key" ]; then
    # Links inside the "Drawing set" section (any heading level), up to the
    # next heading of the same or a higher level.
    links=$(awk '
      /^#+[ \t]/ {
        level = index($0, " ") - 1
        if (insec && level <= seclevel) insec = 0
        if (tolower($0) ~ /drawing set/) { insec = 1; seclevel = level; next }
      }
      insec {
        line = $0
        while (match(line, /\]\([^)]*\)/)) {
          print substr(line, RSTART + 2, RLENGTH - 3)
          line = substr(line, RSTART + RLENGTH)
        }
      }
    ' "$key")
    while IFS= read -r target; do
      [ -n "$target" ] || continue
      target=${target%%#*}
      target=${target%% *}
      case "$target" in
        *.svg|*.SVG|*.pdf|*.PDF)
          case "$target" in
            http://*|https://*) continue ;;
          esac
          if [ -f "$dir/$target" ]; then
            set_ok=true
            case "$target" in
              *.svg|*.SVG) sheets+=("$target") ;;
            esac
          fi
          ;;
      esac
    done <<< "$links"
  fi
  if [ "$set_ok" = "false" ]; then
    report physical "CAD found ($cad_rel) but docs/drawings/README.md has no \"Drawing set\" section linking a drawing file (.svg or .pdf) that exists"
  fi

  # The floor on detail. SVG sheets are text, so the words a complete set must
  # carry can be looked for. Formal figure sheets and the plate are figures
  # only and are skipped. A set linked only as PDF cannot be inspected here.
  inspected=0
  all_text=""
  for sheet in ${sheets[@]+"${sheets[@]}"}; do
    case "$(basename "$sheet" | tr 'A-Z' 'a-z')" in
      *plate*|*formal*|*fig*) continue ;;
    esac
    inspected=$((inspected + 1))
    body=$(tr 'A-Z' 'a-z' < "$dir/$sheet")
    all_text="$all_text $body"
    missing=""
    for field in revision scale units date sheet; do
      case "$body" in
        *"$field"*) ;;
        *) missing="$missing $field" ;;
      esac
    done
    if [ -n "$missing" ]; then
      report titleblock "$sheet has no title-block field for:$missing"
    fi
  done
  if [ "$inspected" -gt 0 ]; then
    missing=""
    for need in "section:a section view" "qty:a parts list" "material:a material note" "tolerance:a tolerance note" "projection:the projection convention"; do
      word=${need%%:*}
      case "$all_text" in
        *"$word"*) ;;
        *) missing="$missing ${need#*:};" ;;
      esac
    done
    if [ -n "$missing" ]; then
      report detail "the drawing set is missing:${missing%;}"
    fi
  fi
fi

if [ "$findings" -eq 0 ]; then
  if [ -n "$cad" ]; then
    echo "  OK       plate, key, README pointer, and a drawing set for the physical component"
  else
    echo "  OK       plate, key, and README pointer"
  fi
  echo
  echo "docs/drawings meets the mechanical Drawings checks."
  exit 0
fi

echo
echo "$findings finding(s) against DOCUMENTATION.md's \"Drawings\" standard."
if [ "$strict" = "true" ]; then
  echo "FAIL: drawings problems (--strict)."
  ci_annotate error "check_drawings.sh: $findings drawings finding(s) in docs/drawings"
  exit 1
fi
echo "WARN: drawings problems (pass --strict to enforce)."
ci_annotate warning "check_drawings.sh: $findings drawings finding(s) in docs/drawings (pass --strict to enforce)"
exit 0
