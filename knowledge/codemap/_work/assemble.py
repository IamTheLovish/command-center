import os, re, json, sys
sys.path.insert(0, os.path.dirname(__file__))
from traps import T
W = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(W)
BASE = 'bar/src/main/java/com/solegendary/reignofnether/'
SHA = 'bbbdac21'
FULL = 'bbbdac211d7d355181c00da37dc416b82fa04ff9'
DATE = '2026-10-27'
def clean(txt):
    out = []
    for l in txt.replace('\r', '').split('\n'):
        l = l.rstrip()
        if l.strip().startswith('```'): continue
        l = re.sub(r'\s*\[OVER 1000\]\?\s*no\s*-\s*', ' - ', l)
        m = re.search(r'\(~?(\d[\d,]*)\s*(?:lines)?\)', l)
        if m:
            n = int(m.group(1).replace(',', ''))
            if n <= 1000: l = l.replace(' [OVER 1000]', '')
            elif 'OVER 1000' not in l: l += ' [OVER 1000]'
        out.append(l)
    while out and not out[0].strip(): out.pop(0)
    # collapse blank lines
    res = []
    for l in out:
        if not l.strip() and res and not res[-1].strip(): continue
        res.append(l)
    return res
def pathspec(pk):
    if pk in ('tools',): return 'tools .github/workflows'
    if pk == '.github': return ''
    if pk in ('mod', 'engine'): return pk
    return BASE + pk
entries = []
for area, (pkgs, purpose, traps) in T.items():
    specs = ' '.join(s for s in (pathspec(p) for p in pkgs) if s)
    if area == 'legacy-mod-engine':
        body = ['## Purpose', 'Older from-scratch prototype kept for reference (mod/ 37 java + engine/ 37 java + 8 tests, ~12.6k lines). The live game is bar/. Not shipped.', '## Key classes', 'See `git -C D:\\btr ls-files mod engine`; read only when porting an old idea. Nothing in bar/ imports it.', '## Entry points and events', 'none (prototype).', '## Server vs client', 'n/a. ## Data flow: none to bar/. ## Instrumentation and tests: engine/src/test/java (8 files, not part of the bar GameTest suite).']
    else:
        p = os.path.join(W, area + '.haiku.md')
        body = clean(open(p, encoding='utf-8').read())
        if area == 'tools-ci':
            kc = ['## Key classes',
             '- `.github/workflows/build.yml` (401) - CI: build/changes/bar/bar-tests (SHARD_n matrix)/bar-audit/bar-publish; SHARD_2..8 lists at top',
             '- `.github/workflows/eyes.yml` (554) - Xvfb client tour + stills/video to eyes branches; `eyes-approve.yml` (35) copies baselines',
             '- `.github/workflows/flake-stress.yml` (134) - N reruns of tests on main; read the [Stress] annotation, job is always green',
             '- `.github/workflows/ci-mirror.yml` (21), `ci-mirror-report.yml` - second runner pool, label-triggered',
             '- `tools/ci_plan.py` (91) - decides what a run must test (docs-only skips GameTests); `ci_route.py` (81), `ci_shard_env.py` (40)',
             '- `tools/ci_wait.py` (251) - one-shot CI waiter; reruns once if all failures are in known_flakes.txt',
             '- `tools/check_shards.py` (91), `check_guards.py` (101), `check_java.py` (57), `check_server_client_imports.py` (85) - prepush gates',
             '- `tools/prepush.sh` (36) - local mirror of fast CI checks (~35 s); `claim.py` (156) - lane claims on issue #91; `merge_pr.py` (135)',
             '- `tools/known_flakes.txt` (7) - 4 flakes at this sha: bots_play_each_other..., bots_reach_tier_2..., artillery_fires_over_a_wall..., attack_move_stops_to_fight...',
             '- `tools/gametest_audit.py` (102), `gametest_timing.py` (79), `eyes_diff.py` (120), `junit_summary.py` (51), `triage_log.py` (80)',
             '- Generators (gen_*.py, up to 4,110 lines: gen_lobby_art, gen_structures, gen_blocks, gen_hd_skins) are art tools, not CI; never hand-edit their outputs',
             '']
            i = body.index('## Key classes'); j = body.index('## Entry points and events')
            body = body[:i] + kc + body[j:]
    hdr = ['# Codemap: ' + area, f'sha: {SHA} ({FULL})   date: {DATE}   source: dossier of bar/ at that sha + traps from review/plans/lessons/AGENTS',
           f'drift: `git -C D:\\btr diff {SHA}..origin/main --stat -- {specs}`', '']
    tr = ['', '## TRAPS (source tag in brackets: REV overnight-review, LES lessons.md, AGM AGENTS.md, P0xx plans, RUL RULES.md)'] + ['- ' + t.replace('legacy-mod-engine', '') .replace(' and not built by CI as the game', '') for t in traps]
    lines = hdr + body + tr
    with open(os.path.join(OUT, area + '.md'), 'w', encoding='utf-8', newline='\n') as f: f.write('\n'.join(lines) + '\n')
    print(area, len(lines))
    entries.append((area, pkgs, purpose))
json.dump(entries, open(os.path.join(W, 'entries.json'), 'w'))

