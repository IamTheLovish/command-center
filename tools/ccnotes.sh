#!/bin/bash
# ccnotes.sh - git clean/smudge filter that stores briefs/ and plans/ encrypted in both remotes (lovish Oct 30: "encrypt the notes").
# usage (git runs it): ccnotes.sh clean|smudge  < content > content
# Key: one line of 64 hex chars in $CCNOTES_KEY or ~/.cc-notes-key (never in the repo). Lose the key = lose the notes in git.
# Format: "CCENC1 <iv hex>\n" + base64 of AES-256-CTR(plaintext). The IV is an HMAC of the plaintext, so the same file
# always encrypts the same way (git sees no spurious changes; only identical files are recognisable as identical).
# smudge passes non-CCENC1 input through (old plaintext commits); clean passes CCENC1 input through (no double encryption).
set -e
kf=${CCNOTES_KEY:-$HOME/.cc-notes-key}
[ -s "$kf" ] || { echo "ccnotes: key file $kf missing" >&2; exit 1; }
master=$(tr -d ' \r\n' < "$kf")
kenc=$(printf 'enc%s' "$master" | openssl dgst -sha256 -r | cut -c1-64)
kmac=$(printf 'mac%s' "$master" | openssl dgst -sha256 -r | cut -c1-64)
t=$(mktemp); trap 'rm -f "$t" "$t.b"' EXIT
cat > "$t"
case "$1" in
  clean)
    if head -c 7 "$t" | grep -q '^CCENC1 '; then cat "$t"; exit 0; fi
    iv=$(openssl dgst -sha256 -mac HMAC -macopt hexkey:$kmac -r < "$t" | cut -c1-32)
    printf 'CCENC1 %s\n' "$iv"
    openssl enc -aes-256-ctr -K "$kenc" -iv "$iv" -nosalt -in "$t" | openssl base64 -e
    ;;
  smudge)
    if ! head -c 7 "$t" | grep -q '^CCENC1 '; then cat "$t"; exit 0; fi
    iv=$(head -n 1 "$t" | cut -d' ' -f2)
    tail -n +2 "$t" > "$t.b"
    openssl base64 -d -in "$t.b" | openssl enc -d -aes-256-ctr -K "$kenc" -iv "$iv" -nosalt
    ;;
  *) echo "usage: ccnotes.sh clean|smudge" >&2; exit 2 ;;
esac
