# shellcheck shell=bash
#
# Layer declaration parsing and graph analysis for
# scripts/check_architecture.sh.
#
# Sourced, never executed. Reads the globals `architecture_doc` and
# `layer_records`; sets `ambiguous_tokens` when `compute_ambiguous_tokens` is
# called, and `layer_match_suffixes` when `compute_layer_match_suffixes` is.
#
# Everything here treats the declared layer table as a graph: parsing it,
# finding cycles in it, and finding names in it that refer to no layer. None of
# it reads a single source file -- a cyclic declaration is unsound regardless of
# what the code does, which is why it can be checked without scanning anything.
#
# Split from check_architecture.sh because it changes for its own reason: a new
# column in the table, or a new property to verify about the graph, is
# unrelated to which languages the project is written in.

# Extract the "Layer Boundaries" table as `layer|path|allowed` records. Header
# and separator rows are dropped; a row needs all three cells to count.
parse_layer_table() {
  [ -f "$architecture_doc" ] || return 0

  awk '
    tolower($0) ~ /^#+[[:space:]]*layer boundaries[[:space:]]*$/ { intable = 1; next }
    intable && /^#+[[:space:]]/ { intable = 0 }
    intable && /^[[:space:]]*\|/ {
      line = $0
      sub(/^[[:space:]]*\|/, "", line)
      sub(/\|[[:space:]]*$/, "", line)
      n = split(line, cell, "|")
      if (n < 3) next

      for (i = 1; i <= n; i++) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", cell[i])
        gsub(/`/, "", cell[i])
      }

      if (cell[1] ~ /^-+$/ || cell[2] ~ /^-+$/) next
      if (tolower(cell[1]) == "layer") next
      if (cell[1] == "" || cell[2] == "") next

      print cell[1] "|" cell[2] "|" cell[3]
    }
  ' "$architecture_doc"
}

# Layer directory names shared by more than one layer. A bare module path that
# names only such a directory cannot be attributed to one layer, and guessing
# would be worse than declining: it silently reassigns a real dependency.
ambiguous_tokens=""

compute_ambiguous_tokens() {
  ambiguous_tokens=$(printf '%s\n' "$layer_records" | awk '
    BEGIN { FS = "|" }
    $1 != "" {
      path = $2
      gsub(/^[ \t]+|[ \t]+$/, "", path)
      sub(/\/+$/, "", path)
      n = split(path, seg, "/")
      token = seg[n]
      if (token == "") next
      if (!(token in count)) count[token] = 0
      count[token]++
    }
    END { for (t in count) if (count[t] > 1) print t }
  ' || true)
}

# For each layer, the shortest tail of its path that no other layer's path ends
# with -- its most economical unambiguous name. For a layer whose directory name
# is already unique this is just that name (`domain`); for two layers sharing a
# basename it is the basename plus enough parent segments to separate them
# (`a/core` vs `b/core`). This is what lets attribution resolve a shared basename
# when an import spells the disambiguating parent, instead of skipping it and
# losing the violation. If a layer's whole path is a tail of another's -- so no
# suffix is ever unique -- the full path is used, and the longest-match rule at
# the call site prefers the more specific layer.
#
# Sets the global `layer_match_suffixes` as `name|suffix` records.
layer_match_suffixes=""

compute_layer_match_suffixes() {
  layer_match_suffixes=$(printf '%s\n' "$layer_records" | awk '
    BEGIN { FS = "|" }
    $1 != "" {
      nm[++n] = $1
      p = $2
      gsub(/^[ \t]+|[ \t]+$/, "", p)
      sub(/\/+$/, "", p)
      gsub(/\/\/+/, "/", p)
      sub(/^\.\//, "", p)
      pa[n] = p
    }
    # The last k segments of a path, or "" when it has fewer than k.
    function tail(path, k,   seg, m, j, t) {
      m = split(path, seg, "/")
      if (k > m) return ""
      t = ""
      for (j = m - k + 1; j <= m; j++) t = t (t == "" ? "" : "/") seg[j]
      return t
    }
    END {
      for (i = 1; i <= n; i++) {
        ns = split(pa[i], seg, "/")
        chosen = ""
        for (k = 1; k <= ns; k++) {
          t = tail(pa[i], k)
          uniq = 1
          for (m = 1; m <= n; m++) {
            if (m == i) continue
            if (tail(pa[m], k) == t) { uniq = 0; break }
          }
          if (uniq) { chosen = t; break }
        }
        if (chosen == "") chosen = pa[i]
        print nm[i] "|" chosen
      }
    }
  ' || true)
}

# Emit one line per cycle in the declared dependency graph, normalized so the
# same cycle found from different entry points is reported once.
#
# Checking the *declared* graph rather than the observed imports is deliberate,
# and it is sufficient: every actual import is either permitted -- and therefore
# an edge already present in this graph -- or it is a violation, which is
# reported separately below. So if this graph is acyclic, no cycle can exist
# among the imports that pass. A cyclic declaration is an unsound architecture
# regardless of how much of it the code currently exercises.
find_declared_cycles() {
  printf '%s\n' "$layer_records" | awk '
    BEGIN { FS = "|" }
    {
      name = $1
      if (name == "") next
      known[name] = 1
      order[++n] = name
      adj[name] = $3
    }
    END {
      for (i = 1; i <= n; i++) if (!(order[i] in state)) dfs(order[i])
      for (c in seen) print c
    }

    function dfs(node,   i, m, deps, dep, j, path, start) {
      state[node] = 1
      stack[++sp] = node

      m = split(adj[node], deps, ",")
      for (i = 1; i <= m; i++) {
        dep = deps[i]
        gsub(/^[ \t]+|[ \t]+$/, "", dep)
        gsub(/`/, "", dep)
        if (dep == "" || dep ~ /^(-+|—+|none|n\/a)$/) continue
        if (!(dep in known)) continue
        if (dep == node) continue

        if (state[dep] == 1) {
          start = 0
          for (j = 1; j <= sp; j++) if (stack[j] == dep) { start = j; break }
          if (start) {
            path = ""
            for (j = start; j <= sp; j++) path = path stack[j] " -> "
            seen[normalize(path dep)] = 1
          }
        } else if (state[dep] != 2) {
          dfs(dep)
        }
      }

      state[node] = 2
      sp--
    }

    # Rotate the cycle to begin at its lexicographically smallest member, so the
    # same cycle discovered from different entry points dedupes to one finding.
    function normalize(p,   parts, k, cnt, min, mi, out, idx) {
      cnt = split(p, parts, " -> ") - 1
      min = parts[1]; mi = 1
      for (k = 2; k <= cnt; k++) if (parts[k] < min) { min = parts[k]; mi = k }
      out = ""
      for (k = 0; k < cnt; k++) {
        idx = ((mi - 1 + k) % cnt) + 1
        out = out parts[idx] " -> "
      }
      return out min
    }
  '
}

# Names in a "May Depend On" cell that match no declared layer. A typo there is
# silent by construction: the intended dependency is never permitted, and no
# import can ever match it, so the layer simply behaves as if it declared less
# than the author believed.
find_unknown_dependencies() {
  printf '%s\n' "$layer_records" | awk '
    BEGIN { FS = "|" }
    { if ($1 != "") { known[$1] = 1; order[++n] = $1; adj[$1] = $3 } }
    END {
      for (i = 1; i <= n; i++) {
        name = order[i]
        m = split(adj[name], deps, ",")
        for (j = 1; j <= m; j++) {
          dep = deps[j]
          gsub(/^[ \t]+|[ \t]+$/, "", dep)
          gsub(/`/, "", dep)
          if (dep == "" || dep ~ /^(-+|—+|none|n\/a)$/) continue
          if (!(dep in known)) print name "|" dep
        }
      }
    }
  '
}
