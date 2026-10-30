#!/bin/bash
# usage (inside a clone, after `git merge origin/main` into a PR branch, BEFORE pushing):
#   removedsyms.sh OLDHEAD [MERGED=HEAD]
# Eris.3 (Oct 30): 394's main merge was clean text but did not compile (#364's new AngelCallerProd called
# getFormattedPopAndTime, which 394 deletes). This finds every method/field/class/enum name the PR side deletes
# (declared in a removed line, declared nowhere at OLDHEAD) that the merged tree still uses. Any hit = a compile break.
old=$1; new=${2:-HEAD}; base=$(git merge-base $old $new^2 2>/dev/null || git merge-base $old origin/main)
names=$(git diff $base $old -- '*.java' | grep -E '^-[^-]' \
  | grep -oE '(public|protected|private|static|final|abstract|enum|class|record|interface)[^=;(]*\b[A-Za-z_][A-Za-z0-9_]*\s*[(;={]' \
  | grep -oE '[A-Za-z_][A-Za-z0-9_]*\s*[(;={]$' | tr -d '(;={ ' | sort -u)
consts=$(git diff $base $old -- '*.java' | grep -E '^-\s+[A-Z][A-Z0-9_]+\s*[,;(]' | grep -oE '[A-Z][A-Z0-9_]+' | head -1000 | sort -u)
hits=0; n=0
for s in $names $consts; do
  [ ${#s} -lt 4 ] && continue; n=$((n+1))
  git grep -qwE "$s" $old -- '*.java' && continue          # still declared/used on the PR side: not removed
  r=$(git grep -nwE "$s" $new -- '*.java' | head -3)
  [ -n "$r" ] && { echo "REMOVED BUT USED: $s"; echo "$r" | sed 's/^/    /'; hits=$((hits+1)); }
done
echo "checked $n removed names (base ${base:0:8}, old ${old:0:8}, merged $(git rev-parse --short $new)): $hits still used"
[ $hits = 0 ]
