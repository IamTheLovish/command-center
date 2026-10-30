#!/bin/bash
# automerge-batch-selftest.sh - check_batch and check_runs of automerge.sh against a fake gh (no network, no merges).
# usage: bash tools/automerge-batch-selftest.sh      (exit 0 = every case caught)
D=$(cd "$(dirname "$0")" && pwd); T=$(mktemp -d)
sed -n '/^check_batch() {/,/^}/p; /^check_runs() {/,/^}/p' "$D/automerge.sh" > "$T/fns.sh"
R=x/y; source "$T/fns.sh"
B=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb; M1=1111111111111111111111111111111111111111; BASE=0000000000000000000000000000000000000000
HA=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa; HC=cccccccccccccccccccccccccccccccccccccccc; SQ=5555555555555555555555555555555555555555
FX=9999999999999999999999999999999999999999
PLAN=$T/plan.txt; DONE=$T/done.txt
P2="$M1 $HC"; P1="$BASE $HA"; MAINC=identical; CI="completed success 2026-10-30T05:00:00Z 777"; JOBS="9 0"; PR1="MERGED $HA"
gh() { case "$*" in
  "api repos/x/y/commits/$B "*) echo "$P2";;
  "api repos/x/y/commits/$M1 "*) echo "$P1";;
  "api repos/x/y/compare/"*main*) echo "$MAINC";;
  "run list"*) echo "$CI";;
  "run view 777 "*) echo "$JOBS";;
  "pr view 1 -R x/y --json state,headRefOid"*) echo "$PR1";;
  "pr view 1 "*) echo $SQ;;
esac; }
ok=0; bad=0
t() { local want=$1 name=$2; shift 2; out=$(check_batch "$@"); rc=$?
  if [ "$rc" = "$want" ]; then ok=$((ok+1)); else bad=$((bad+1)); echo "MISS $name: rc $rc want $want :: $(echo "$out" | tail -1)"; fi; }
plan2() { printf '# 1 x y\n1 %s red=1 green=9 batch=%s\n2 %s red=2 green=9 batch=%s\n' $HA $B $HC $B > $PLAN; }
plan2; green=9
: > $DONE;              t 0 "first member, main == base" 1 $HA $B
MAINC="ahead $SQ";      t 2 "first member, main moved" 1 $HA $B; MAINC=identical
                        t 1 "second waits for the first" 2 $HC $B
echo 1 > $DONE; MAINC="ahead $SQ"
out=$(check_batch 2 $HC $B); t 0 "second after the first merged, main == base + its squash" 2 $HC $B
echo "$out" | grep -q "^SKIP $SQ" && echo "$out" | grep -q "^BASE $BASE" && ok=$((ok+1)) || { bad=$((bad+1)); echo "MISS SKIP/BASE lines: $out"; }
MAINC="ahead $SQ $FX";  t 2 "a foreign commit after the first member = drift" 2 $HC $B
MAINC="ahead $FX $SQ";  t 2 "a foreign commit before the first member's squash = drift" 2 $HC $B
MAINC="ahead $SQ"
PR1="MERGED $FX";       t 2 "the first member merged at another head" 2 $HC $B
PR1="OPEN $HA";         t 2 "done lists a member that is not merged" 2 $HC $B; PR1="MERGED $HA"
P2="$M1 $HA";           t 2 "batch merges the wrong head" 2 $HC $B; P2="$M1 $HC"
P1="$BASE";             t 2 "not a merge at the bottom" 2 $HC $B; P1="$BASE $HA"
printf '2 %s red=2 green=9 batch=%s\n' $HC $B > $PLAN
                        t 2 "a member's line removed from the plan" 2 $HC $B; plan2
CI="completed failure x 777";   t 2 "batch CI red" 2 $HC $B
CI="in_progress null x 777";    t 1 "batch CI running" 2 $HC $B; CI="completed success 2026-10-30T05:00:00Z 777"
JOBS="1 0";             t 2 "batch CI green with bar-tests skipped (mirror route)" 2 $HC $B
JOBS="9 1";             t 2 "batch CI green with a GameTest job not success" 2 $HC $B; JOBS="9 0"
                        t 2 "short batch sha" 1 $HA bbbb
green=none;             t 2 "batch without a green" 1 $HA $B; green=9
printf '1 %s red=1 green=9 batch=%s\n' $HA $B > $PLAN; t 2 "one-member batch" 1 $HA $B
out=$(check_runs red "?" $HA); [ $? = 2 ] && ok=$((ok+1)) || { bad=$((bad+1)); echo "MISS red=? must be BAD: $out"; }
rm -rf "$T"
echo "automerge batch selftest: $ok caught, $bad missed"; [ $bad = 0 ]
