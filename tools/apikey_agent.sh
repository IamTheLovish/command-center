#!/usr/bin/env bash
# Run one headless Claude Code agent on lovish's API key (not the subscription), inside the shared $195 budget.
#   bash tools/apikey_agent.sh <slug> <model> <max_usd> <prompt_file> [workdir]
# --bare makes the CLI read only ANTHROPIC_API_KEY (OAuth/keychain never read), so every token bills the key.
# The run's real cost (total_cost_usd) is appended to itachi2-api/spend-ledger.jsonl, the same ledger
# tools/itachi2_api.py guards, so critic calls and agents share one budget. The key is never printed or saved.
set -u
slug=$1; model=$2; max=$3; prompt=$4; wd=${5:-"D:/Command Center"}
CC="/d/Command Center"; BUDGET=${APIKEY_BUDGET_USD:-195}
spent=$(cd "$CC" && python tools/itachi2_api.py --ledger 2>/dev/null | grep -oE '\$[0-9.]+' | head -1 | tr -d '$')
python -c "import sys; sys.exit(0 if float('${spent:-999}') + float('$max') <= float('$BUDGET') else 1)" \
  || { echo "REFUSED $slug: spent \$$spent + cap \$$max > \$$BUDGET"; exit 2; }
key=${ANTHROPIC_API_KEY:-$(powershell.exe -NoProfile -Command "[Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY','User')" | tr -d '\r\n')}
[ -n "$key" ] || { echo "REFUSED $slug: no ANTHROPIC_API_KEY"; exit 2; }
stamp=$(date -u +%Y%m%d-%H%M%S); out="$CC/itachi2-api/agents/$stamp-$slug"; mkdir -p "$out"; cp "$prompt" "$out/prompt.md"
# the desktop app's account/org/host-auth variables would bind the child to the subscription org: drop them all
unset_args=(); for v in $(env | grep -oE '^(CLAUDE_CODE_[A-Z0-9_]+|ANTHROPIC_[A-Z0-9_]+)='); do unset_args+=(-u "${v%=}"); done
cd "$wd" && env "${unset_args[@]}" ANTHROPIC_API_KEY="$key" claude -p --bare --model "$model" --max-budget-usd "$max" \
  --permission-mode auto --output-format json < "$prompt" > "$out/result.json" 2> "$out/stderr.txt"
rc=$?
python - "$out/result.json" "$CC/itachi2-api/spend-ledger.jsonl" "$stamp" "$stamp-$slug" "$model" <<'EOF'
import json, sys
res, ledger, at, run, model = sys.argv[1:]
try:
    r = json.load(open(res, encoding="utf-8"))
except Exception:
    r = {}
usd = float(r.get("total_cost_usd") or 0)
with open(ledger, "a", encoding="utf-8") as f:
    f.write(json.dumps({"at": at, "run": run, "model": model, "role": "agent", "usd": usd}) + "\n")
print(f"DONE {run}: ${usd:.4f}, is_error={r.get('is_error')}, turns={r.get('num_turns')}")
print((r.get("result") or "")[-1500:])
EOF
exit $rc
