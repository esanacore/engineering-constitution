# POSIX awk parser for the optional discovery review format. Invoked by
# check_product_discovery.sh with requirements first and review second.
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function bad(s) { print "Finding: " s }
# Ignore hidden Markdown comments, including multi-line comments.
function uncomment(s, out, start, stop) {
  out=""
  while (length(s)) {
    if (comment) {
      stop=index(s,"-->")
      if (!stop) return out
      s=substr(s,stop+3); comment=0
    } else {
      start=index(s,"<!--")
      if (!start) return out s
      out=out substr(s,1,start-1); s=substr(s,start+4); comment=1
    }
  }
  return out
}
function placeholder(s, t) {
  t=tolower(trim(s))
  return t == "" || t ~ /^(-|n\/a|na|none|pending|tbd|todo|unknown|placeholder|example|name|evidence)$/ || t ~ /^\[.*\]$/ || t ~ /^<.*>$/
}
function positive(s) { return s ~ /^[0-9]+$/ && s ~ /[1-9]/ }
function reqid(s) { return s ~ /^(FR|NFR)-[0-9]+$/ }
function fields(line, a, n,i) {
  line=trim(line); sub(/^\|/, "", line); sub(/\|$/, "", line)
  n=split(line,a,"|"); for (i=1;i<=n;i++) a[i]=trim(a[i]); return n
}
function separator(a,n,i) {
  for (i=1;i<=n;i++) if (a[i] !~ /^:?-+:?$/) return 0
  return 1
}
function decl(s, a,n,id) {
  s=trim(s)
  if (s ~ /^\*\*(FR|NFR)-[0-9]+\*\*/) {
    sub(/^\*\*/, "", s); id=s; sub(/\*\*.*/, "", id)
  } else if (s ~ /^#+[ \t]+(FR|NFR)-[0-9]+([^A-Za-z0-9-]|$)/) {
    sub(/^#+[ \t]+/, "", s); id=s; sub(/[^A-Za-z0-9-].*/, "", id)
  } else if (s ~ /^\|/) {
    n=fields(s,a); id=a[1]
  } else return
  if (reqid(id)) {
    if (++requirements[id] > 1) bad("duplicate requirement declaration " id)
    requirement_count++
  }
}
function revision_line(line, source, t) {
  t=trim(line); sub(/^-[ \t]+/, "", t)
  if (t ~ /^Intent revision[ \t]*:/) {
    sub(/^Intent revision[ \t]*:[ \t]*/, "", t)
    if (source == "requirements") { ++req_revision_count; req_revision=trim(t) }
    else { ++seen["Intent revision"]; value["Intent revision"]=trim(t) }
  }
}
function review_key(line, s,key,v) {
  s=trim(line); sub(/^-[ \t]+/, "", s)
  if (index(s,":") == 0) return
  key=trim(substr(s,1,index(s,":")-1)); v=trim(substr(s,index(s,":")+1))
  if (key in expected) { seen[key]++; value[key]=v }
}
BEGIN {
  expected["Intent revision"]=1; expected["Requirements hash"]=1; expected["Lifecycle"]=1
  expected["Product approval"]=1; expected["Product approval revision"]=1; expected["Product approval hash"]=1; expected["Product approval reviewer"]=1; expected["Product approval evidence"]=1
  expected["Engineering readiness"]=1; expected["Engineering readiness revision"]=1; expected["Engineering readiness hash"]=1; expected["Engineering readiness reviewer"]=1; expected["Engineering readiness evidence"]=1
}
{
  sub(/\r$/, ""); line=$0
  if (FNR == 1) { comment=0; fence=0 }
  if (!fence) line=uncomment(line)
  t=trim(line)
  # Ignore fenced code: examples must not become declarations or records.
  if (t ~ /^```/ || t ~ /^~~~/) {
    marker=substr(t,1,3)
    if (!fence) { fence=1; fence_marker=marker }
    else if (marker == fence_marker) fence=0
    next
  }
  if (fence) next
  if (FILENAME == ARGV[1]) {
    revision_line(line,"requirements"); decl(line); next
  }
  if (t ~ /^##[ \t]+/) {
    section=t; sub(/^##[ \t]+/,"",section); section=tolower(trim(section))
    table=0; need_separator=0
    if (section == "unknowns" || section == "changed requirement evidence") {
      section_count[section]++
    }
    next
  }
  review_key(line)
  if (section != "unknowns" && section != "changed requirement evidence") next
  if (t !~ /^\|/) {
    if (need_separator) { bad(section ": missing table separator"); need_separator=0 }
    if (table && t != "") table=0
    next
  }
  n=fields(t,c)
  if (!table) {
    if (section == "unknowns" && n == 6 && tolower(c[1]) == "id" && tolower(c[2]) == "kind" && tolower(c[3]) == "status" && tolower(c[4]) == "owner" && tolower(c[5]) == "review date" && tolower(c[6]) == "resolution") {
      table=1; need_separator=1; headers[section]++; next
    }
    if (section == "changed requirement evidence" && n == 3 && tolower(c[1]) == "requirement id" && tolower(c[2]) == "evidence status" && tolower(c[3]) == "evidence reference") {
      table=1; need_separator=1; headers[section]++; next
    }
    bad(section ": unexpected table row or invalid header"); next
  }
  if (need_separator) {
    if (!separator(c,n) || (section == "unknowns" && n != 6) || (section != "unknowns" && n != 3)) bad(section ": invalid table separator")
    need_separator=0; next
  }
  if (section == "unknowns") {
    if (n != 6) { bad("unknowns: expected six cells"); next }
    id=c[1]; kind=tolower(c[2]); status=tolower(c[3])
    if (placeholder(id)) bad("unknowns: missing ID")
    else if (++unknown[id] > 1) bad("duplicate unknown ID " id)
    if (kind != "blocker" && kind != "experiment" && kind != "metric") bad("unknown " id ": invalid kind")
    if (status != "open" && status != "resolved") bad("unknown " id ": invalid status")
    if (placeholder(c[4])) bad("unknown " id ": missing owner")
    if (c[5] !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) bad("unknown " id ": review date must be YYYY-MM-DD")
    if (status == "resolved" && placeholder(c[6])) bad("unknown " id ": resolved item needs a resolution")
    if (kind == "blocker" && status == "open") open_blockers++
  } else {
    if (n != 3) { bad("changed requirement evidence: expected three cells"); next }
    id=c[1]; status=tolower(c[2])
    if (!reqid(id)) bad("changed evidence: invalid requirement ID " id)
    else {
      if (++changed[id] > 1) bad("duplicate changed requirement ID " id)
      if (!(id in requirements)) bad("changed evidence: unknown requirement " id)
    }
    if (status != "pending" && status != "reassessed") bad("changed evidence " id ": invalid status")
    if (status == "reassessed" && placeholder(c[3])) bad("changed evidence " id ": reassessed needs an evidence reference")
    if (status == "pending") pending_evidence++
  }
}
END {
  if (req_revision_count != 1) bad("requirements must declare exactly one Intent revision")
  if (!positive(req_revision)) bad("requirements Intent revision must be a positive integer")
  if (!requirement_count) bad("requirements declare no FR or NFR IDs")
  for (key in expected) if (seen[key] != 1) bad("review must declare exactly one " key)
  if (!positive(value["Intent revision"])) bad("review Intent revision must be a positive integer")
  if (value["Intent revision"] != req_revision) bad("review Intent revision is stale")
  if (value["Requirements hash"] != digest) bad("review Requirements hash is stale or invalid")
  lifecycle=value["Lifecycle"]
  if (lifecycle != "Draft" && lifecycle != "In Review" && lifecycle != "Approved" && lifecycle != "Superseded") bad("invalid Lifecycle")
  if (value["Product approval"] != "Pending" && value["Product approval"] != "Approved") bad("invalid Product approval")
  if (value["Engineering readiness"] != "Pending" && value["Engineering readiness"] != "Ready") bad("invalid Engineering readiness")
  for (role_i=1;role_i<=2;role_i++) {
    role=(role_i == 1 ? "Product approval" : "Engineering readiness")
    if (!positive(value[role " revision"]) || value[role " revision"] != req_revision) bad(role " revision is stale or invalid")
    if (value[role " hash"] != digest) bad(role " hash is stale or invalid")
    is_ready=(value[role] == "Approved" || value[role] == "Ready")
    if (is_ready && placeholder(value[role " reviewer"])) bad(role " needs a named reviewer")
    if (is_ready && placeholder(value[role " evidence"])) bad(role " needs an evidence reference")
  }
  if (lifecycle == "Approved" && value["Product approval"] != "Approved") bad("Approved lifecycle requires Product approval")
  if ((lifecycle == "Approved" || value["Engineering readiness"] == "Ready") && open_blockers) bad("Approved or Ready review has open blockers")
  if ((lifecycle == "Approved" || value["Engineering readiness"] == "Ready") && pending_evidence) bad("Approved or Ready review has pending changed requirement evidence")
  if (need_separator) bad(section ": missing table separator")
  if (section_count["unknowns"] != 1 || headers["unknowns"] != 1) bad("review needs exactly one Unknowns section and table")
  if (section_count["changed requirement evidence"] != 1 || headers["changed requirement evidence"] != 1) bad("review needs exactly one Changed requirement evidence section and table")
}