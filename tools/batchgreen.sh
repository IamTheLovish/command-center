#!/bin/bash
# batchgreen.sh - ONE shared 8-runner green (and one CI) for 2-4 PASSed PRs (lovish approved batch greens, Oct 30, Eris
# generation). Each PR keeps its own Mode A review and its own red; only the green and the CI are shared.
# usage: batchgreen.sh [--tests PR=test:a,test:b]... [--dry-run] PR PR [PR [PR]]   (merge order = arg order)
#        batchgreen.sh --resume logs/batchgreen-<name>.state
# Steps (state in logs/batchgreen-<name>.state, so --resume continues after a stop; nothing is ever cancelled):
#   1. per PR: open, base main, reviews/pr-N-modeA.md last VERDICT PASS with SHA == head, no red check on the head;
#      tests = its new @GameTest methods (from its diff) as test:<name>, or --tests PR=... (prefixes, test: required)
#   2. throwaway branch claude/batch-green-<prs>-<utc> off origin/main in a work clone (never D:\BeyondAndTabs-Repo):
#      each head merged with a normal --no-ff merge in order; a conflict stops the batch (drop that PR, run again)
#   3. push the branch (new, never forced), open a DRAFT batch PR (CI on GitHub's runners; body keeps "Do not merge...")
#   4. wait until the batch PR's `bar` job compiled ("dispatch only after the PR build compiles"), then dispatch ONE
#      flake-stress run: ref = the batch head (full SHA), tests = the union, runners = 8
#   5. wait for the stress run and the batch CI (a red CI job is rerun, failed jobs only, up to attempt 3); read every line:
#      checkout == batch head, no INVALID / NO SAMPLE, "[Stress] 8 runners; M with any failure", and per PR every
#      "<test>: failed F, passed P" its tests match: PASS = failed 0 and passed == runners, on every line
#   6. post an evidence comment on each member PR and on the batch PR (run ids, header, per-PR tally lines, verdict);
#      the marker line "[batch green] batch head <sha>" is what gate-lib.ps1 and automerge.sh look for
#   7. all PASS (CI green, 0 with any failure): print the automerge plan lines (in merge order, batch=<sha>).
#      A failure FLAGS every member and merges none: the comments say which members' own lines failed and suggest a
#      split, but splitting is the coordinator's decision (nothing is re-dispatched; exit 5).
# Why a batch green is evidence for each member (automerge.sh checks all of it again before each merge): the members
# merge back to back in this order, so main after the last merge holds exactly the tree the green tested; a member
# whose turn comes after a dropped member waits (its green included code that will not land) and needs a new green.
R=IamTheLovish/Beyond-and-Tabs
CC="/d/Command Center"; REV="$CC/reviews"; LOGD="$CC/logs"; PLANF="$CC/briefs/automerge-plan.txt"
WORK=${BATCH_CLONE:-/d/bt-batchgreen}
RUNNERS=8; POLL=${BATCH_POLL:-300}
ID_NAME=IamTheLovish; ID_MAIL=IamTheLovish@users.noreply.github.com   # the game repo's AGENTS.md commit identity
TRAILER="Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
mkdir -p "$LOGD"
say() { echo "$(date -u +%H:%MZ) $*" | tee -a "$LOGD/batchgreen.log"; }
die() { say "STOP: $*"; exit "${2:-1}"; }

declare -A TESTS HEAD
DRY=""; PRS=(); STATE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --tests) TESTS[${2%%=*}]=${2#*=}; shift 2;;
    --dry-run) DRY=1; shift;;
    --resume) STATE=$2; shift 2;;
    *) PRS+=("$1"); shift;;
  esac
done

st_get() { grep -E "^$1=" "$STATE" 2>/dev/null | tail -1 | cut -d= -f2-; }
st_set() { echo "$1=$2" >> "$STATE"; }

# --- the new @GameTest methods of a PR (same rule as gate-lib.ps1 Test-GateStress: an added @GameTest line followed
# directly, other annotations allowed, by an added method line)
new_tests() { gh pr diff "$1" -R $R 2>/dev/null | tests_from_diff; }
tests_from_diff() {
  awk '
    /^\+[ \t]*@GameTest/ { g=1; next }
    g && /^[+ ][ \t]*@/ { next }
    g && /^\+[ \t]*(public[ \t]+)?static[ \t]+void[ \t]+[A-Za-z0-9_]+[ \t]*\(/ { s=$0; sub(/^.*void[ \t]+/, "", s); sub(/[ \t]*\(.*/, "", s); print s }
    { g=0 }' | sort -u
}
# PASS (exit 0) when every given "<test>: failed F, passed P" line has F == 0 and P == the runner count
lines_pass() { [ -n "$1" ] && echo "$1" | awk -F'[ ,]+' -v r="$2" '{ if ($3+0 != 0 || $5+0 != r) bad=1 } END { exit bad }'; }

# --- tally of a flake-stress run (as automerge.sh reads it) plus the full checkout SHA of its first stress job
tally() {
  local id=$1 j s
  j=$(gh run view $id -R $R --json jobs --jq '.jobs[]|select(.name=="summary")|.databaseId' 2>/dev/null)
  s=$(gh run view $id -R $R --json jobs --jq '.jobs[]|select(.name|test("^stress"))|.databaseId' 2>/dev/null | head -1)
  echo "CHECKOUT $(gh run view $id -R $R --log --job $s 2>/dev/null | grep -oE 'git checkout --progress --force [0-9a-f]{40}' | head -1 | awk '{print $5}')"
  gh run view $id -R $R --log --job $j 2>/dev/null | sed -E 's/^[^\t]*\t[^\t]*\t[0-9TZ:.-]+ //' \
    | grep -E "\[Stress\]|INVALID|NO SAMPLE|: failed [0-9]+, passed [0-9]+|no test failed" | grep -v "##\[group\]" \
    | sed -E 's/^summary\tFail rate per test\t//; s/^##\[notice\]//; s/^##\[error\]//' | sort -u
}

# --- lines of a tally that a PR's test list matches (test:<prefix>, lower-case compare like GameTestShards; a bare
# entry is a batch name and cannot be matched to lines, so it is refused up front)
pr_lines() {  # tally tests
  local t=$1 list=$2 e
  for e in ${list//,/ }; do
    e=${e#test:}
    echo "$t" | grep -E ": failed [0-9]+, passed [0-9]+" | awk -v p="$(echo "$e" | tr A-Z a-z)" '{ n=$1; sub(/:$/, "", n); if (index(tolower(n), p) == 1) print }'
  done | sort -u
}

# --selftest: the parsing on fixtures (no gh, no git, no runs)
if [ "${PRS[0]}" = --selftest ]; then
  ok=0; bad=0
  ck() { if [ "$2" = "$3" ]; then ok=$((ok+1)); else bad=$((bad+1)); echo "FAIL $1: want [$2] got [$3]"; fi; }
  d=$'+    @GameTest(template = ARENA, timeoutTicks = 600)
+    public static void hero_marker_ring_is_outside_the_body(GameTestHelper h) {
'
  d+=$'+    @GameTest(template = ARENA)
+    @SuppressWarnings("x")
+    static void Blow_lands_on_the_strike(GameTestHelper h) {
'
  d+=$'-    @GameTest(template = ARENA, timeoutTicks = 600)
+    @GameTest(template = ARENA, timeoutTicks = LONG)
     public static void old_test_with_a_new_timeout(GameTestHelper h) {
'
  d+=$'+    @GameTest(template = ARENA)
+    // a comment line breaks the pair
+    public static void not_a_test_here(GameTestHelper h) {
'
  ck "new tests from a diff (annotation edits and broken pairs are not new)" "Blow_lands_on_the_strike hero_marker_ring_is_outside_the_body" "$(echo "$d" | tests_from_diff | paste -sd' ' -)"
  t=$'[Stress] 8 runners; 1 with any failure
hero_marker_ring_is_outside_the_body: failed 0, passed 8
hero_marker_scales: failed 1, passed 7
Blow_lands_on_the_strike: failed 0, passed 8
blow_timing_x: failed 0, passed 8'
  ck "a prefix matches every test it starts" "hero_marker_ring_is_outside_the_body: failed 0, passed 8|hero_marker_scales: failed 1, passed 7" "$(pr_lines "$t" test:hero_marker | paste -sd'|' -)"
  ck "names compare in lower case (GameTestShards)" "Blow_lands_on_the_strike: failed 0, passed 8" "$(pr_lines "$t" test:blow_lands | paste -sd'|' -)"
  ck "8 of 8 passes" 0 "$(lines_pass "$(pr_lines "$t" test:blow_lands)" 8; echo $?)"
  ck "1 failure of 8 fails" 1 "$(lines_pass "$(pr_lines "$t" test:hero_marker)" 8; echo $?)"
  ck "passed 6 of 8 runners is not 8-runner evidence" 1 "$(lines_pass 'a_test: failed 0, passed 6' 8; echo $?)"
  ck "no line is no pass" 1 "$(lines_pass "" 8; echo $?)"
  ck "a bare name matches no line" "" "$(pr_lines "$t" test:nothing_like_it)"
  echo "batchgreen selftest: $ok passed, $bad failed"; [ $bad = 0 ]; exit
fi

# ------------------------------------------------------------------ 1. start a new batch (or resume one)
if [ -z "$STATE" ]; then
  [ ${#PRS[@]} -ge 2 ] && [ ${#PRS[@]} -le 4 ] || die "give 2-4 PRs in merge order (got ${#PRS[@]})" 2
  [ "$(printf '%s\n' "${PRS[@]}" | sort -u | wc -l)" -eq ${#PRS[@]} ] || die "a PR is given twice: ${PRS[*]}" 2
  for pr in "${PRS[@]}"; do
    info=$(gh pr view $pr -R $R --json state,baseRefName,headRefOid --jq '"\(.state) \(.baseRefName) \(.headRefOid)"' 2>/dev/null) || die "gh pr view $pr failed"
    set -- $info
    [ "$1" = OPEN ] && [ "$2" = main ] || die "#$pr is $1 on base $2 (needs OPEN on main)"
    f="$REV/pr-$pr-modeA.md"
    v=$(grep -E "^VERDICT:" "$f" 2>/dev/null | tail -1 | awk '{print $2}'); s=$(grep -E "^SHA:" "$f" 2>/dev/null | tail -1 | awk '{print $2}')
    [ "$v" = PASS ] && [ "$s" = "$3" ] || die "#$pr has no Mode A PASS on its head ${3:0:8} (last: $v ${s:0:8})"
    red=$(gh pr checks $pr -R $R --json name,state --jq '[.[]|select(.state=="FAILURE" or .state=="ERROR")|.name]|join(",")' 2>/dev/null)
    [ -z "$red" ] || die "#$pr has red checks on its head: $red"
    HEAD[$pr]=$3
    if [ -z "${TESTS[$pr]}" ]; then
      TESTS[$pr]=$(new_tests $pr | sed 's/^/test:/' | paste -sd, -)
      [ -n "${TESTS[$pr]}" ] || die "#$pr adds no @GameTest: give --tests $pr=test:<prefix>,..."
    fi
    echo "${TESTS[$pr]}" | tr , '\n' | grep -qvE '^test:[A-Za-z0-9_]+$' && die "#$pr tests must all be test:<prefix> (got ${TESTS[$pr]})"
    say "member #$pr head ${3:0:8} tests ${TESTS[$pr]}"
  done
  name="$(IFS=-; echo "${PRS[*]}")-$(date -u +%m%d%H%M)"
  branch="claude/batch-green-$name"
  STATE="$LOGD/batchgreen-$name.state"
  [ -n "$DRY" ] && STATE="$LOGD/batchgreen-$name.dry.state"
  : > "$STATE"
  st_set prs "${PRS[*]}"; st_set branch "$branch"
  for pr in "${PRS[@]}"; do st_set "head_$pr" "${HEAD[$pr]}"; st_set "tests_$pr" "${TESTS[$pr]}"; done
else
  [ -f "$STATE" ] || die "no state file $STATE" 2
  read -ra PRS <<< "$(st_get prs)"; branch=$(st_get branch)
  for pr in "${PRS[@]}"; do HEAD[$pr]=$(st_get "head_$pr"); TESTS[$pr]=$(st_get "tests_$pr"); done
  [ -z "$(st_get result)" ] || die "batch $branch already finished: $(st_get result) (see logs/batchgreen.log)" 2
  say "resume $branch: ${PRS[*]}"
fi
union=$(for pr in "${PRS[@]}"; do echo "${TESTS[$pr]}" | tr , '\n'; done | sort -u | paste -sd, -)

# ------------------------------------------------------------------ 2-3. the batch branch and its draft PR
bsha=$(st_get bsha)
if [ -z "$(st_get bpr)" ] && [ -n "$bsha" ]; then die "batch $(st_get branch) has no PR: if 'git ls-remote origin $(st_get branch)' shows it pushed, open the PR by hand (draft, label ci-here) and add bpr=<n> to $STATE; if the push failed, delete $STATE and start again; then --resume" 2; fi
if [ -z "$bsha" ]; then
  case "$WORK $(cd "$WORK" 2>/dev/null && pwd -W 2>/dev/null)" in *[Bb]eyond[Aa]nd[Tt]abs-[Rr]epo*) die "work clone must not be D:\\BeyondAndTabs-Repo" 2;; esac
  [ -d "$WORK/.git" ] || git clone -q --filter=blob:none "https://github.com/$R.git" "$WORK" || die "clone failed"
  cd "$WORK" || die "no work clone"
  [ -z "$(git status --porcelain)" ] || die "work clone $WORK has local changes"
  git fetch -q origin main $(for pr in "${PRS[@]}"; do echo "pull/$pr/head"; done) || die "fetch failed"
  base=$(git rev-parse origin/main)
  # no stacked members: two members that share a commit outside main would squash into main differently from their
  # batch merge (the shared commit's later edits). The members' commits outside the base must be disjoint (not just
  # "the merge base is on main": a criss-cross history after both merged main has a second merge base off main)
  for a in "${PRS[@]}"; do for c in "${PRS[@]}"; do [ "$a" -lt "$c" ] || continue
    ra=$(git rev-list "^$base" "${HEAD[$a]}") && rc=$(git rev-list "^$base" "${HEAD[$c]}") || die "rev-list failed for #$a / #$c" 3
    [ -z "$(comm -12 <(echo "$ra" | sort) <(echo "$rc" | sort) | grep .)" ] \
      || die "#$a and #$c share commits outside main (stacked): batch them only after the lower one merged" 3
  done; done
  git checkout -q -B "$branch" "$base" || die "checkout failed"
  i=0
  for pr in "${PRS[@]}"; do
    i=$((i+1))
    git cat-file -e "${HEAD[$pr]}^{commit}" 2>/dev/null || git fetch -q origin "pull/$pr/head"
    if ! git -c user.name=$ID_NAME -c user.email=$ID_MAIL merge -q --no-ff "${HEAD[$pr]}" \
         -m "Batch green: merge #$pr (${HEAD[$pr]:0:8}), member $i of ${#PRS[@]}" -m "Throwaway batch branch: never merged into main." -m "$TRAILER"; then
      git merge --abort 2>/dev/null
      git checkout -q --detach "$base"; git branch -q -D "$branch"
      die "#$pr conflicts with the batch so far (${PRS[*]:0:$((i-1))}): drop it or change the order, then run again" 3
    fi
  done
  bsha=$(git rev-parse HEAD)
  say "batch $branch = main ${base:0:8} + ${PRS[*]} -> ${bsha:0:8}"
  if [ -n "$DRY" ]; then
    git checkout -q --detach "$base"; git branch -q -D "$branch"
    say "DRY RUN: merges clean; would push $branch, open a draft batch PR, then dispatch flake-stress ref=$bsha runners=$RUNNERS tests=$union"
    exit 0
  fi
  st_set base "$base"; st_set bsha "$bsha"
  git push -q origin "$branch" || die "push failed"
  body=$(printf '%s\n' "Do not merge without lovish's OK." "" "**Batch proof only - never merge.** Throwaway batch branch for ONE shared CI + green (tools/batchgreen.sh in the Command Center). Closed only with lovish's OK." "" \
    "Members in merge order (each keeps its own Mode A review and red):" \
    "$(for pr in "${PRS[@]}"; do echo "- #$pr ${HEAD[$pr]}"; done)" "" "Base: main $base" "Batch head: $bsha" "Tests: $union" "" \
    "🤖 Generated with [Claude Code](https://claude.com/claude-code)")
  # label ci-here: the batch's GameTests must run here (tools/ci_route.py would otherwise send them to the org mirror and
  # skip bar / bar-tests in this run)
  bpr=$(gh pr create -R $R --draft --label ci-here --base main --head "$branch" --title "Batch green: $(for pr in "${PRS[@]}"; do printf '#%s ' $pr; done)(throwaway, do not merge)" --body "$body" | grep -oE '[0-9]+$')
  [ -n "$bpr" ] || die "gh pr create failed (branch $branch is pushed: open the PR by hand, then add bpr= to $STATE)"
  st_set bpr "$bpr"
  say "batch PR #$bpr opened on $branch (${bsha:0:8})"
fi
base=$(st_get base); bpr=$(st_get bpr)

# ------------------------------------------------------------------ 4. compile, then ONE flake-stress dispatch
ci_run() { gh run list -R $R --workflow build.yml --event pull_request --commit "$bsha" --limit 5 --json databaseId --jq '.[0].databaseId // empty' 2>/dev/null; }
sid=$(st_get sid)
while [ -z "$sid" ]; do
  cid=$(ci_run)
  if [ -n "$cid" ]; then
    step=$(gh run view $cid -R $R --json jobs --jq '.jobs[]|select(.name=="bar")|.steps[]|select(.name=="Build the BAR-on-RoN mod")|"\(.status) \(.conclusion)"' 2>/dev/null)
    case "$step" in
      "completed success")
        t0=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        gh workflow run flake-stress.yml -R $R -f ref="$bsha" -f tests="$union" -f runners=$RUNNERS || die "dispatch failed"
        for k in 1 2 3 4 5 6 7 8 9 10 11 12; do
          sleep 10
          sid=$(gh run list -R $R --workflow flake-stress.yml --limit 30 --json databaseId,displayTitle,createdAt \
                --jq "[.[]|select(.displayTitle==\"flake-stress $bsha\" and .createdAt>=\"$t0\")][0].databaseId // empty" 2>/dev/null)
          [ -n "$sid" ] && break
        done
        [ -n "$sid" ] || die "dispatched but no flake-stress run titled for $bsha after 2 min: find it, add sid=<id> to $STATE, --resume"
        st_set cid "$cid"; st_set sid "$sid"
        say "batch #$bpr compiled (CI $cid); green dispatched: flake-stress $sid, $RUNNERS runners, $union";;
      "")  [ "$(gh run view $cid -R $R --json jobs --jq '.jobs[]|select(.name=="bar")|.conclusion')" = skipped ] && die "batch #$bpr CI $cid skipped job bar (routed to the mirror or no code): no compile, no GameTests here" 4
           sleep $POLL;;
      "completed "*) die "batch #$bpr does not compile (CI $cid, bar build: $step): the members break each other - the coordinator decides the split" 4;;
      *) sleep $POLL;;
    esac
  else sleep $POLL; fi
done
cid=$(st_get cid)

# ------------------------------------------------------------------ 5. wait for the green and the batch CI
while :; do
  ss=$(gh run view $sid -R $R --json status --jq .status 2>/dev/null)
  cid=$(ci_run); cs=$(gh run view $cid -R $R --json status,conclusion,attempt --jq '"\(.status) \(.conclusion) \(.attempt)"' 2>/dev/null)
  set -- $cs
  if [ "$1" = completed ] && [ "$2" != success ] && [ "${3:-9}" -lt 3 ]; then
    gh run rerun $cid --failed -R $R >/dev/null 2>&1 && say "batch CI $cid $2 on attempt $3: failed jobs rerun"
  elif [ "$ss" = completed ] && [ "$1" = completed ]; then break; fi
  sleep $POLL
done
cconc=$2

# ------------------------------------------------------------------ 6. read every line, post the evidence
t=$(tally $sid); hdr=$(echo "$t" | grep "\[Stress\]" | head -1); co=$(echo "$t" | grep '^CHECKOUT' | awk '{print $2}')
[ -n "$hdr" ] || die "stress $sid log not readable yet (empty [Stress] header): --resume $STATE later"
n=$(echo "$hdr" | sed -nE 's/.*\[Stress\] ([0-9]+) runners; ([0-9]+) with any failure.*/\1 \2/p')
broken=""
[ "$co" = "$bsha" ] || broken="checked out ${co:-nothing}, not the batch head $bsha"
echo "$t" | grep -qE "INVALID|NO SAMPLE" && broken="INVALID / NO SAMPLE: $hdr"
[ "${n% *}" = "$RUNNERS" ] || broken="${broken:-header is not $RUNNERS runners: $hdr}"
[ "$cconc" = success ] || broken="${broken:-batch CI $cid is $cconc after 3 attempts}"
gt=$(gh run view $cid -R $R --json jobs --jq '[.jobs[]|select(.name=="bar" or (.name|startswith("bar-tests")))] | "\(length) \([.[]|select(.conclusion!="success")]|length)"' 2>/dev/null)
[ -n "$gt" ] && [ "${gt% *}" -ge 2 ] && [ "${gt#* }" = 0 ] || broken="${broken:-batch CI $cid did not run and pass every GameTest job here ($gt)}"
declare -A VERD LINES
pass=(); fail=(); idx=0
for pr in "${PRS[@]}"; do
  l=$(pr_lines "$t" "${TESTS[$pr]}"); LINES[$pr]=$l
  miss=""; for e in ${TESTS[$pr]//,/ }; do [ -n "$(pr_lines "$t" "$e")" ] || miss="$miss $e"; done
  if [ -n "$miss" ]; then VERD[$pr]="NO LINES for$miss"; broken="${broken:-#$pr has no tally line for$miss}"
  elif lines_pass "$l" $RUNNERS; then VERD[$pr]=PASS; pass+=($pr)
  else VERD[$pr]=FAIL; fail+=($pr); fi
done
allok=""; [ -z "$broken" ] && [ ${#fail[@]} = 0 ] && [ "${n#* }" = 0 ] && allok=1
# a run with a failing line no member claims (a prefix that matched another test) is unattributable too
[ -z "$broken" ] && [ ${#fail[@]} = 0 ] && [ "${n#* }" != 0 ] && broken="$hdr, but no member's own line failed"

plan=""
for pr in "${PRS[@]}"; do
  idx=$((idx+1))
  red=$(grep -E "^$pr ${HEAD[$pr]} " "$PLANF" 2>/dev/null | tail -1 | grep -oE 'red=[^ ]+' | cut -d= -f2)
  line="$pr ${HEAD[$pr]} red=${red:-?} green=$sid batch=$bsha"
  if [ -n "$allok" ]; then verdict="PASS on the batch (merge order $idx of ${#PRS[@]}). automerge plan line:"$'\n'"$line"; plan="$plan$line"$'\n'
  elif [ -n "$broken" ]; then verdict="NO EVIDENCE: $broken"
  elif [ "${VERD[$pr]}" = FAIL ]; then verdict="FAIL: this PR's own tests failed in the batch (lines above). Back to its builder."
  else verdict="FLAG: no evidence from this batch (another member failed); the coordinator decides the split"; fi
  # the marker (what the gate accepts) only on a pass: a failed batch's comment names the head without it
  { if [ -n "$allok" ]; then echo "[batch green] batch head $bsha base $base members $(for p in "${PRS[@]}"; do echo ${HEAD[$p]}; done | paste -sd, -)"
    else echo "Batch green FAILED - batch head $bsha (not evidence for any member)"; fi
    echo "Batch PR #$bpr (branch $branch), base main $base; members in merge order: $(for p in "${PRS[@]}"; do printf '#%s %s  ' $p ${HEAD[$p]:0:8}; done)"
    echo "Batch CI (build, pull_request): run $cid $cconc"
    echo "Green: flake-stress run $sid, checked out ${co:-?}, $RUNNERS runners, tests $union"
    echo "$hdr"
    echo "This PR's tests (#$pr: ${TESTS[$pr]}):"; echo "${LINES[$pr]:-    (no line)}" | sed 's/^/    /'
    for p in "${PRS[@]}"; do [ "$p" = "$pr" ] || { echo "Member #$p:"; echo "${LINES[$p]:-(no line)}" | sed 's/^/    /'; }; done
    echo "Verdict for #$pr: $verdict"
    echo "Void if this PR's head moves, a member before it does not merge, or main gains a commit sharing its files (automerge.sh checks all three)."
  } > "$LOGD/batchgreen-post-$pr.md"
  gh pr comment $pr -R $R -F "$LOGD/batchgreen-post-$pr.md" >/dev/null 2>&1 || say "WARN comment on #$pr failed"
  say "#$pr: ${verdict%%$'\n'*}"
done
{ echo "Batch ${allok:+PASS}${allok:-FAIL}: batch head $bsha: $hdr; CI $cid $cconc; green $sid"
  for pr in "${PRS[@]}"; do echo "- #$pr ${VERD[$pr]}"; echo "${LINES[$pr]}" | sed 's/^/    /'; done; } > "$LOGD/batchgreen-post-batch.md"
gh pr comment $bpr -R $R -F "$LOGD/batchgreen-post-batch.md" >/dev/null 2>&1
st_set result "${allok:+PASS}${allok:-FLAG}"

if [ -n "$allok" ]; then
  say "BATCH PASS #$bpr: plan lines (merge order; fill red=? from each PR's own red):"
  printf '%s' "$plan" | tee -a "$LOGD/batchgreen.log"
  exit 0
fi

# ------------------------------------------------------------------ 7. a failing batch: flag every member, merge none
if [ -n "$broken" ]; then h=$(( (${#PRS[@]} + 1) / 2 )); sug="halves [${PRS[*]:0:$h}] [${PRS[*]:$h}] (unattributable: $broken)"
else sug="drop ${fail[*]} (own tests failed); ${pass[*]:-none} again (a new batch, or their own green if one is left)"; fi
for pr in "${PRS[@]}"; do say "FLAG #$pr: batch ${bsha:0:8} did not pass (${VERD[$pr]})"; done
say "BATCH FAIL #$bpr: no member merges on it. Suggested split (coordinator's call): $sug"
exit 5
