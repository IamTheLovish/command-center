#!/bin/bash
# automerge.sh - overnight merger for lovish's evidence rule (lovish Oct 29: "merge everything create a tool if you have to
# allow prs to be tested and merged while I sleep").
# usage: automerge.sh PLANFILE [minutes-between-passes] [max-passes]
# PLANFILE lines (# comments ok):  PR FULL_HEAD_SHA red=RUNID,RUNID|none green=RUNID,RUNID|none
# Per PR, every pass, in order; any failed check leaves the PR alone (WAIT) or reports it (FLAG):
#   1. PR open, base main, head == planned SHA (else FLAG: new head needs a review)
#   2. reviews\pr-N-modeA.md last VERDICT PASS with SHA == head (else FLAG)
#   3. PR checks all done and green; a red check is rerun (failed jobs only) up to attempt 3, then FLAG
#   4. every red run: completed, not INVALID, "[Stress] N runners; N with any failure" (all runners failed)
#      every green run: completed, checkout == head, not INVALID / NO SAMPLE, "0 with any failure"
#   5. overlap: no main commit since the newest CI run on the head shares a file with the PR (else FLAG)
#   6. coordinator evidence round appended + posted, gate done PASS, gh pr ready, main unchanged, merge --match-head-commit
# Exits after a pass that merged something or raised a new FLAG (so the coordinator wakes), or after max-passes.
R=IamTheLovish/Beyond-and-Tabs
PLAN=$1; MIN=${2:-10}; MAX=${3:-72}
CC="/d/Command Center"; REV="$CC/reviews"; LOG="$CC/logs/automerge.log"; DONE="$CC/logs/automerge.done"; SEEN="$CC/logs/automerge.flags"
mkdir -p "$CC/logs"; touch "$DONE" "$SEEN"
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

check_runs() {  # kind ids head -> prints evidence lines; returns 0 ok, 1 wait, 2 bad
  local kind=$1 ids=$2 head=$3 id st t hdr co
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
      [ "${head:0:7}" = "${co:0:7}" ] || { echo "BAD green $id checked out $co, head ${head:0:7}"; return 2; }
      echo "$hdr" | grep -q "; 0 with any failure" || { echo "BAD green $id: $hdr"; return 2; }
    fi
    echo "RUN $kind $id (checked out $co) $hdr"
    echo "$t" | grep -E ": failed [0-9]+, passed [0-9]+" | sed 's/^/    /'
  done
  return 0
}

flag() {  # pr msg : report once per (pr,msg)
  local key="$1 $2"
  grep -qxF "$key" "$SEEN" || { echo "$key" >> "$SEEN"; log "FLAG PR$1: $2"; NEWFLAG=1; }
}

for pass in $(seq 1 $MAX); do
  MERGED=""; NEWFLAG=""
  while read -r pr head red green; do
    [ -z "$pr" ] && continue; case "$pr" in \#*) continue;; esac
    grep -qx "$pr" "$DONE" && continue
    red=${red#red=}; green=${green#green=}
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
      if [ "${att:-9}" -lt 3 ]; then gh run rerun $run --failed -R $R >/dev/null 2>&1 && log "RERUN PR$pr run $run a$att ($bad)"
      else flag $pr "CI red after 3 attempts: $bad (run $run)"; fi
      continue
    fi
    # stress evidence
    ev_r=$(check_runs red "$red" "$head"); rc=$?
    [ $rc = 1 ] && { echo "$(date -u +%H:%MZ) WAIT PR$pr $(echo "$ev_r" | tail -1)" >> "$LOG"; continue; }
    [ $rc = 2 ] && { flag $pr "$(echo "$ev_r" | grep ^BAD)"; continue; }
    ev_g=$(check_runs green "$green" "$head"); rc=$?
    [ $rc = 1 ] && { echo "$(date -u +%H:%MZ) WAIT PR$pr $(echo "$ev_g" | tail -1)" >> "$LOG"; continue; }
    [ $rc = 2 ] && { flag $pr "$(echo "$ev_g" | grep ^BAD)"; continue; }
    # overlap since the newest CI run on the head
    b=$(gh pr view $pr -R $R --json headRefName --jq .headRefName)
    cit=$(gh run list -R $R --branch "$b" --event pull_request --limit 20 --json headSha,createdAt,workflowName --jq "[.[]|select(.headSha==\"$head\" and .workflowName==\"build\")][0].createdAt")
    [ -n "$cit" ] && [ "$cit" != null ] || { flag $pr "no build CI run found on the head"; continue; }
    mainsha=$(gh api repos/$R/commits/main --jq .sha)
    pf=$(gh api "repos/$R/pulls/$pr/files?per_page=100" --paginate --jq '.[].filename' | sort)
    shared=""
    for c in $(gh api "repos/$R/commits?sha=main&since=$cit&per_page=50" --jq '.[].sha'); do
      both=$(comm -12 <(echo "$pf") <(gh api repos/$R/commits/$c --jq '.files[].filename' | sort) | tr '\n' ' ')
      [ -n "$both" ] && shared="$shared ${c:0:8}:[$both]"
    done
    [ -z "$shared" ] || { flag $pr "overlap with main since CI ($cit):$shared -> merge main + merge-only check"; continue; }
    # gate FIRST (it needs only the reviewer's PASS on the head); a round is written only when the gate passes
    g=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\\Command Center\\tools\\cc.ps1" gate done -Pr $pr 2>&1 | tr -d '\r')
    echo "$g" | grep -q "GATE done #$pr: PASS" || { flag $pr "gate not PASS: $(echo "$g" | grep -E '^FAIL|GATE' | tr '\n' ' ')"; continue; }
    # evidence round (coordinator), post
    k=$(( $(grep -c "^## Round" "$f") + 1 ))
    { printf "\n## Round %s (coordinator evidence check, automerge, %s)\nVERDICT: PASS\nSHA: %s\nREVIEWER: Command Center Archon automerge.sh (coordinator, not the builder), %s\n\n" "$k" "${head:0:8}" "$head" "$(date -u +%b\ %d)"
      echo "Code unchanged since the last review round. CI on the head: all checks green. Overlap: no main commit since $cit shares a file. Per-test tally lines:"
      [ "$red" = none ] && echo "- red: none required for this head (proof on an earlier head or merge-only)"
      [ "$green" = none ] && echo "- green: none required (CI is the proof for this head)"
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
