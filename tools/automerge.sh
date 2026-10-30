#!/bin/bash
# automerge.sh - overnight merger for lovish's evidence rule (lovish Oct 29: "merge everything create a tool if you have to
# allow prs to be tested and merged while I sleep").
# usage: automerge.sh PLANFILE [minutes-between-passes] [max-passes]
# PLANFILE lines (# comments ok):  PR FULL_HEAD_SHA red=RUNID,RUNID|none green=RUNID,RUNID|none [batch=BATCH_HEAD_SHA]
#   batch= (tools/batchgreen.sh): the green ran on a throwaway batch branch = main + 2-4 PASSed heads merged in plan-line
#   order; the members merge back to back in that order. Checked instead of "green checkout == head" (4b below).
# Per PR, every pass, in order; any failed check leaves the PR alone (WAIT) or reports it (FLAG):
#   1. PR open, base main, head == planned SHA (else FLAG: new head needs a review)
#   2. reviews\pr-N-modeA.md last VERDICT PASS with SHA == head (else FLAG)
#   3. PR checks all done and green; a red check is rerun (failed jobs only) up to attempt 3, then FLAG
#   4. every red run: completed, not INVALID, "[Stress] N runners; N with any failure" (all runners failed)
#      every green run: completed, checkout == head (batch: == the batch head), not INVALID / NO SAMPLE, "0 with any failure"
#   4b. batch lines only: every member above it in the plan merged; the batch head is exactly base + the members merged in
#      plan order (parents); main is EXACTLY that base + the earlier members' squash commits (else FLAG: main drift);
#      the batch PR's build CI on the batch head completed green (the gate recomputes the batch tree itself)
#   5. overlap: no main commit since the newest CI run on the head shares a file with the PR (else FLAG); batch lines:
#      since the batch CI, not counting the squash commits of the batch's own members
#   6. coordinator evidence round appended + posted, gate done PASS, gh pr ready, main unchanged, merge --match-head-commit
# Exits after a pass that merged something or raised a new FLAG (so the coordinator wakes), or after max-passes.
R=IamTheLovish/Beyond-and-Tabs
PLAN=$1; MIN=${2:-10}; MAX=${3:-72}
# AUTOMERGE_DRY=1: every check runs, nothing is written to a PR (no gate, round, comment, ready or merge), and the logs
# go to AUTOMERGE_LOGS (default the scratch folder logs/automerge-dry) so the live merger's done/flags files are untouched
DRY=${AUTOMERGE_DRY:-}
CC="/d/Command Center"; REV="$CC/reviews"; LD="$CC/logs"; [ -n "$DRY" ] && LD=${AUTOMERGE_LOGS:-$CC/logs/automerge-dry}
LOG="$LD/automerge.log"; DONE="$LD/automerge.done"; SEEN="$LD/automerge.flags"
mkdir -p "$LD"; touch "$DONE" "$SEEN"
log() { echo "$(date -u +%H:%MZ) $*" | tee -a "$LOG"; }

# tally lines of a flake-stress run (summary job), plus the checkout of its first stress job
tally() {
  local id=$1 j s
  j=$(gh run view $id -R $R --json jobs --jq '.jobs[]|select(.name=="summary")|.databaseId' 2>/dev/null)
  s=$(gh run view $id -R $R --json jobs --jq '.jobs[]|select(.name|test("^stress"))|.databaseId' 2>/dev/null | head -1)
  echo "CHECKOUT $(gh run view $id -R $R --log --job $s 2>/dev/null | grep -oE 'HEAD is now at [0-9a-f]{7,}' | head -1 | awk '{print $5}')"
  gh run view $id -R $R --log --job $j 2>/dev/null | sed -E 's/^[^\t]*\t[^\t]*\t[0-9TZ:.-]+ //' \
    | grep -E "\[Stress\]|Fail rate per test|INVALID|NO SAMPLE|: failed [0-9]+, passed [0-9]+|no test failed" | grep -v "##\[group\]" \
    | sed -E 's/^summary\tFail rate per test\t//; s/^##\[notice\]//'
}

check_runs() {  # kind ids head [green checkout] -> prints evidence lines; returns 0 ok, 1 wait, 2 bad
  local kind=$1 ids=$2 head=$3 want=${4:-$3} id st t hdr co
  [ "$ids" = none ] && return 0
  for id in ${ids//,/ }; do
    st=$(gh run view $id -R $R --json status --jq .status 2>/dev/null)
    [ "$st" = completed ] || { echo "WAIT $kind $id $st"; return 1; }
    t=$(tally $id); hdr=$(echo "$t" | grep "\[Stress\]" | head -1); co=$(echo "$t" | grep '^CHECKOUT' | awk '{print $2}')
    [ -n "$hdr" ] || { echo "WAIT $kind $id log not readable yet (empty [Stress] header)"; return 1; }   # a failed log fetch is not evidence
    echo "$t" | grep -qE "INVALID|NO SAMPLE" && { echo "BAD $kind $id INVALID/NO SAMPLE: $hdr"; return 2; }
    if [ "$kind" = red ]; then
      n=$(echo "$hdr" | sed -nE 's/.*\[Stress\] ([0-9]+) runners; ([0-9]+) with any failure.*/\1 \2/p')
      [ -n "$n" ] && [ "${n% *}" = "${n#* }" ] && [ "${n% *}" != 0 ] || { echo "BAD red $id not all runners failed: $hdr"; return 2; }
    else
      [ "${want:0:7}" = "${co:0:7}" ] || { echo "BAD green $id checked out $co, wanted ${want:0:7}"; return 2; }
      echo "$hdr" | grep -q "; 0 with any failure" || { echo "BAD green $id: $hdr"; return 2; }
    fi
    echo "RUN $kind $id (checked out $co) $hdr"
    echo "$t" | grep -E ": failed [0-9]+, passed [0-9]+" | sed 's/^/    /'
  done
  return 0
}

# batch member checks (4b); prints "SINCE <batch CI createdAt>", "BATCHCI <id>", "BASE <sha>" and "SKIP <squash commit
# of an earlier member>" lines. The batch proof is for one exact tree, so main must be EXACTLY the batch base plus the
# squash commits of the members before this one, in order: any other commit on main (even one sharing no file) = FLAG.
check_batch() {  # pr head batch -> 0 ok, 1 wait, 2 bad (last line says why)
  local pr=$1 head=$2 b=$3 members m n k cur par i base sq got ci
  [ ${#b} = 40 ] || { echo "BAD batch= must be the full 40-character batch head"; return 2; }
  [ "$green" != none ] || { echo "BAD batch= needs green=<the batch's flake-stress run>"; return 2; }
  members=($(awk -v b="batch=$b" '$1 !~ /^#/ && $5 == b {print $1}' "$PLAN"))
  n=${#members[@]}
  [ $n -ge 2 ] || { echo "BAD batch ${b:0:8} has fewer than 2 plan lines"; return 2; }
  k=0; for m in "${members[@]}"; do k=$((k+1)); [ "$m" = "$pr" ] && break; done
  for m in "${members[@]:0:$((k-1))}"; do grep -qx "$m" "$DONE" || { echo "WAIT batch order: #$m merges before #$pr"; return 1; }; done
  # the batch head = base + member 1 .. n merged in plan order: walk its first parents, second parent = that member's head
  cur=$b
  for ((i=n-1; i>=0; i--)); do
    par=$(gh api "repos/$R/commits/$cur" --jq '[.parents[].sha]|join(" ")' 2>/dev/null)
    [ -n "$par" ] || { echo "WAIT commit ${cur:0:8} not readable"; return 1; }
    set -- $par
    m=$(awk -v p="${members[$i]}" '$1 == p {print $2}' "$PLAN" | tail -1)
    [ $# = 2 ] && [ "$2" = "$m" ] || { echo "BAD batch ${b:0:8}: ${cur:0:8} is not the merge of #${members[$i]} ${m:0:8} (parents: $par)"; return 2; }
    cur=$1
  done
  base=$cur
  sq=""; for m in "${members[@]:0:$((k-1))}"; do sq="$sq $(gh pr view $m -R $R --json mergeCommit --jq .mergeCommit.oid)"; done
  got=$(gh api "repos/$R/compare/$base...main" --jq '[.status] + [.commits[].sha] | join(" ")' 2>/dev/null)
  [ -n "$got" ] || { echo "WAIT compare ${base:0:8}...main failed"; return 1; }
  if [ $k = 1 ]; then [ "$got" = identical ] || { echo "BAD main drift: main is not the batch base ${base:0:8} ($got)"; return 2; }
  else [ "$got" = "ahead$sq" ] || { echo "BAD main drift: main is not batch base ${base:0:8} + members before #$pr (want ahead$sq, got $got)"; return 2; }; fi
  ci=$(gh run list -R $R --workflow build.yml --event pull_request --commit "$b" --limit 5 --json status,conclusion,createdAt,databaseId --jq '.[0]|"\(.status) \(.conclusion) \(.createdAt) \(.databaseId)"' 2>/dev/null)
  set -- $ci
  [ "$1" = completed ] || { echo "WAIT batch CI ${4:-none} ${1:-not found}"; return 1; }
  [ "$2" = success ] || { echo "BAD batch CI $4 is $2"; return 2; }
  echo "SINCE $3"; echo "BATCHCI $4"; echo "BASE $base"
  for m in $sq; do echo "SKIP $m"; done
  return 0
}

flag() {  # pr msg : report once per (pr,msg)
  local key="$1 $2"
  grep -qxF "$key" "$SEEN" || { echo "$key" >> "$SEEN"; log "FLAG PR$1: $2"; NEWFLAG=1; }
}

for pass in $(seq 1 $MAX); do
  MERGED=""; NEWFLAG=""
  while read -r pr head red green batch; do
    [ -z "$pr" ] && continue; case "$pr" in \#*) continue;; esac
    grep -qx "$pr" "$DONE" && continue
    red=${red#red=}; green=${green#green=}; batch=${batch#batch=}
    info=$(gh pr view $pr -R $R --json state,baseRefName,headRefOid --jq '"\(.state) \(.baseRefName) \(.headRefOid)"' 2>/dev/null) || { log "WAIT PR$pr: gh pr view failed"; continue; }
    set -- $info
    [ "$1" = MERGED ] && { echo "$pr" >> "$DONE"; log "PR$pr already merged"; continue; }
    [ "$1" = OPEN ] || { flag $pr "state $1"; continue; }
    [ "$2" = main ] || { flag $pr "base is $2, not main (retarget first)"; continue; }
    [ "$3" = "$head" ] || { flag $pr "head moved to ${3:0:8} (planned ${head:0:8}): needs a review"; continue; }
    f="$REV/pr-$pr-modeA.md"
    v=$(grep -E "^VERDICT:" "$f" 2>/dev/null | tail -1 | awk '{print $2}'); s=$(grep -E "^SHA:" "$f" 2>/dev/null | tail -1 | awk '{print $2}')
    [ "$v" = PASS ] && [ "$s" = "$head" ] || { flag $pr "no Mode A PASS on $head (last: $v ${s:0:8})"; continue; }
    # CI
    ck=$(gh pr checks $pr -R $R --json name,state,link --jq '"pend=" + ([.[]|select(.state=="PENDING" or .state=="QUEUED" or .state=="IN_PROGRESS")]|length|tostring) + " bad=" + ([.[]|select(.state=="FAILURE" or .state=="CANCELLED" or .state=="ERROR")|.name|gsub(" ";"_")]|join(",")) + " link=" + ([.[]|select(.state=="FAILURE" or .state=="CANCELLED")|.link][0] // "")' 2>/dev/null)
    [ -n "$ck" ] || { echo "$(date -u +%H:%MZ) WAIT PR$pr gh pr checks failed" >> "$LOG"; continue; }
    pend=$(echo "$ck" | sed -E 's/^pend=([0-9]+) .*/\1/')
    [ "$pend" = 0 ] || { echo "$(date -u +%H:%MZ) WAIT PR$pr CI pending $pend" >> "$LOG"; continue; }
    bad=$(echo "$ck" | sed -E 's/.* bad=([^ ]*) .*/\1/')
    if [ -n "$bad" ]; then
      run=$(echo "$ck" | grep -oE 'runs/[0-9]+' | head -1 | cut -d/ -f2)
      att=$(gh run view $run -R $R --json attempt --jq .attempt 2>/dev/null)
      if [ -n "$DRY" ]; then log "DRY PR$pr: CI red ($bad), would rerun run $run (attempt $att)"
      elif [ "${att:-9}" -lt 3 ]; then gh run rerun $run --failed -R $R >/dev/null 2>&1 && log "RERUN PR$pr run $run a$att ($bad)"
      else flag $pr "CI red after 3 attempts: $bad (run $run)"; fi
      continue
    fi
    # stress evidence
    ev_r=$(check_runs red "$red" "$head"); rc=$?
    [ $rc = 1 ] && { echo "$(date -u +%H:%MZ) WAIT PR$pr $(echo "$ev_r" | tail -1)" >> "$LOG"; continue; }
    [ $rc = 2 ] && { flag $pr "$(echo "$ev_r" | grep ^BAD)"; continue; }
    ev_b=""; skip=""
    if [ -n "$batch" ]; then
      ev_b=$(check_batch $pr "$head" "$batch"); rc=$?
      [ $rc = 1 ] && { echo "$(date -u +%H:%MZ) WAIT PR$pr $(echo "$ev_b" | tail -1)" >> "$LOG"; continue; }
      [ $rc = 2 ] && { flag $pr "$(echo "$ev_b" | tail -1)"; continue; }
      skip=$(echo "$ev_b" | sed -n 's/^SKIP //p')
    fi
    ev_g=$(check_runs green "$green" "$head" "$batch"); rc=$?
    [ $rc = 1 ] && { echo "$(date -u +%H:%MZ) WAIT PR$pr $(echo "$ev_g" | tail -1)" >> "$LOG"; continue; }
    [ $rc = 2 ] && { flag $pr "$(echo "$ev_g" | grep ^BAD)"; continue; }
    # overlap since the newest CI run on the head
    b=$(gh pr view $pr -R $R --json headRefName --jq .headRefName)
    cit=$(gh run list -R $R --branch "$b" --event pull_request --limit 20 --json headSha,createdAt,workflowName --jq "[.[]|select(.headSha==\"$head\" and .workflowName==\"build\")][0].createdAt")
    [ -n "$batch" ] && cit=$(echo "$ev_b" | sed -n 's/^SINCE //p')   # the batch CI tested main + every member at its start
    [ -n "$cit" ] && [ "$cit" != null ] || { flag $pr "no build CI run found on the head"; continue; }
    mainsha=$(gh api repos/$R/commits/main --jq .sha)
    pf=$(gh api "repos/$R/pulls/$pr/files?per_page=100" --paginate --jq '.[].filename' | sort)
    shared=""
    for c in $(gh api "repos/$R/commits?sha=main&since=$cit&per_page=50" --jq '.[].sha'); do
      echo "$skip" | grep -qx "$c" && continue   # a batch member merged before this one: in the tested batch tree
      both=$(comm -12 <(echo "$pf") <(gh api repos/$R/commits/$c --jq '.files[].filename' | sort) | tr '\n' ' ')
      [ -n "$both" ] && shared="$shared ${c:0:8}:[$both]"
    done
    [ -z "$shared" ] || { flag $pr "overlap with main since CI ($cit):$shared -> merge main + merge-only check"; continue; }
    [ -n "$DRY" ] && { log "DRY PR$pr: every check passed; would run gate done, write the round, ready and merge"; NEWFLAG=1; continue; }
    # gate FIRST (it needs only the reviewer's PASS on the head); a round is written only when the gate passes
    g=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\\Command Center\\tools\\cc.ps1" gate done -Pr $pr 2>&1 | tr -d '\r')
    echo "$g" | grep -q "GATE done #$pr: PASS" || { flag $pr "gate not PASS: $(echo "$g" | grep -E '^FAIL|GATE' | tr '\n' ' ')"; continue; }
    # evidence round (coordinator), post
    k=$(( $(grep -c "^## Round" "$f") + 1 ))
    { printf "\n## Round %s (coordinator evidence check, automerge, %s)\nVERDICT: PASS\nSHA: %s\nREVIEWER: Command Center Eris.1 automerge.sh (coordinator, not the builder), %s\n\n" "$k" "${head:0:8}" "$head" "$(date -u +%b\ %d)"
      echo "Code unchanged since the last review round. CI on the head: all checks green. Overlap: no main commit since $cit shares a file. Per-test tally lines:"
      [ "$red" = none ] && echo "- red: none required for this head (proof on an earlier head or merge-only)"
      [ "$green" = none ] && echo "- green: none required (CI is the proof for this head)"
      [ -n "$batch" ] && echo "- batch green: batch head $batch (members in plan order merged before this one; batch CI $(echo "$ev_b" | sed -n 's/^BATCHCI //p') green; overlap counted since that CI, without the members' own merges)"
      echo "$ev_r$ev_g" | grep -E "^RUN|^    " | sed -E 's/^RUN /- /'; } >> "$f"
    { printf "[Mode A review, round %s]\n\n" "$k"; awk -v k="$k" '/^## Round/{n++} n==k' "$f"; } > "$CC/logs/automerge-post-$pr.md"
    gh pr comment $pr -R $R -F "$CC/logs/automerge-post-$pr.md" >/dev/null 2>&1 || log "WARN PR$pr comment failed"
    gh pr ready $pr -R $R >/dev/null 2>&1
    now=$(gh api repos/$R/commits/main --jq .sha)
    [ "$now" = "$mainsha" ] || { log "WAIT PR$pr main moved during checks"; continue; }
    if gh pr merge $pr -R $R --squash --match-head-commit "$head" >/dev/null 2>&1; then
      mc=$(gh pr view $pr -R $R --json mergeCommit --jq .mergeCommit.oid)
      echo "$pr" >> "$DONE"; log "MERGED PR$pr ${mc:0:8} (head ${head:0:8})"; MERGED="$MERGED $pr"
      break   # main moved: re-check every other PR's overlap from scratch next pass
    else flag $pr "merge command failed"; fi
  done < "$PLAN"
  [ -n "$MERGED$NEWFLAG" ] && { log "pass $pass: merged:${MERGED:- none}; new flags: ${NEWFLAG:-no}"; exit 0; }
  sleep $((MIN*60))
done
log "max passes reached"
