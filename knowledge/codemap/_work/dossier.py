import os, re, sys, collections
R = r'D:\btr'
P = R + r'\bar\src\main\java\com\solegendary\reignofnether'
AREAS = {
 'unit': ['unit'],
 'pathfinding': ['unit/pathfinding'],
 'tools-ci': [],
 'ability': ['ability', 'mana', 'enchantments'],
 'building': ['building', 'research'],
 'bot': ['bot', 'survival', 'scenario', 'sandbox'],
 'hero': ['hero'],
 'fogofwar': ['fogofwar', 'worldmemory'],
 'hud': ['hud', 'cursor', 'guiscreen', 'healthbars', 'keybinds', 'onboarding', 'tutorial', 'attackwarnings'],
 'minimap-orthoview': ['minimap', 'orthoview', 'maps', 'rtsmap'],
 'match': ['match', 'matchstart', 'startpos', 'worldborder', 'gamemode', 'gamerules'],
 'player-alliance-time': ['player', 'alliance', 'faction', 'time', 'tide', 'environment'],
 'network': ['network', 'registrars', 'commands', 'config'],
 'economy': ['resources', 'items'],
 'gametest': ['gametest'],
 'blocks-fx': ['blocks', 'postfx', 'particles', 'barfx', 'brass', 'nether', 'sounds'],
 'perf': ['perf', 'taskscheduler', 'debug', 'persistence'],
 'mixin-misc': ['mixin', 'compat', 'util', 'launcher', 'api', 'entities'],
}
out = sys.argv[1]
os.makedirs(out, exist_ok=True)
def lines_of(path):
    try:
        with open(path, encoding='utf-8', errors='replace') as f: return f.read().split('\n')
    except Exception: return []
allfiles = {}
for root, _, fs in os.walk(P):
    for fn in fs:
        if fn.endswith('.java'):
            fp = os.path.join(root, fn)
            rel = os.path.relpath(fp, P).replace('\\', '/')
            allfiles[rel] = lines_of(fp)
gt = {k: v for k, v in allfiles.items() if k.startswith('gametest/')}
for area, pkgs in AREAS.items():
    fl = {k: v for k, v in allfiles.items() if any(k.startswith(p+'/') for p in pkgs)}
    tot = sum(len(v) for v in fl.values())
    o = [f'AREA {area}  packages={pkgs}  files={len(fl)} lines={tot}']
    sub = collections.Counter()
    for k, v in fl.items():
        parts = k.split('/'); sub['/'.join(parts[:2]) if len(parts) > 2 else parts[0] + '/']+= len(v)
    o.append('SUBDIRS (lines): ' + ', '.join(f'{a}={b}' for a, b in sub.most_common(25)))
    top = sorted(fl.items(), key=lambda kv: -len(kv[1]))
    o.append('TOP FILES:')
    for k, v in top[:30]: o.append(f'  {len(v):5d} {k}')
    o.append('OVER1000: ' + ', '.join(f'{k}({len(v)})' for k, v in top if len(v) > 1000))
    ev = []; pk = []; fp = set(); cmd = []; xarea = collections.Counter()
    for k, v in fl.items():
        txt = '\n'.join(v)
        n = txt.count('@SubscribeEvent')
        if n: ev.append((n, k))
        if re.search(r'class \w*(Packet|Serverbound|Clientbound)\w*', txt) or 'FriendlyByteBuf' in txt and 'Packet' in k: pk.append(k)
        for m in re.findall(r'(?:FrameParts|Sys)\.(?:begin|end|section|time)?\(?([A-Z][A-Z_0-9]{3,})', txt): fp.add(m)
        for m in re.findall(r'Commands\.literal\("([^"]+)"', txt): cmd.append(m)
        for m in re.findall(r'import com\.solegendary\.reignofnether\.(\w+)\.', txt):
            if m not in pkgs: xarea[m] += 1
    ev.sort(reverse=True)
    o.append('SUBSCRIBEEVENT files: ' + ', '.join(f'{k}({n})' for n, k in ev[:14]))
    o.append('PACKET files: ' + ', '.join(pk[:30]))
    o.append('INSTRUMENTATION ids: ' + ', '.join(sorted(fp)))
    o.append('COMMANDS: ' + ', '.join(sorted(set(cmd))[:30]))
    o.append('IMPORTS FROM OTHER PKGS: ' + ', '.join(f'{a}={b}' for a, b in xarea.most_common(10)))
    # reverse deps: who imports this area
    rev = collections.Counter()
    for k, v in allfiles.items():
        if any(k.startswith(p+'/') for p in pkgs): continue
        txt = '\n'.join(v)
        for p in pkgs:
            if f'reignofnether.{p}.' in txt: rev[k.split('/')[0]] += 1; break
    o.append('IMPORTED BY: ' + ', '.join(f'{a}={b}' for a, b in rev.most_common(10)))
    # gametests touching area (not for gametest itself)
    if area != 'gametest':
        g = collections.Counter()
        for k, v in gt.items():
            txt = '\n'.join(v)
            c = sum(txt.count(f'reignofnether.{p}.') for p in pkgs)
            if c: g[os.path.basename(k)[:-5]] = c
        o.append('GAMETEST classes by import count: ' + ', '.join(f'{a}({b})' for a, b in g.most_common(8)))
    o.append('--- HEADS (non-import, first 40 lines) of top files ---')
    for k, v in top[:4]:
        body = [l for l in v if not l.startswith('import ') and not l.startswith('package ') and l.strip()]
        o.append(f'### {k} ({len(v)} lines)')
        o += [l[:150] for l in body[:40]]
    # method signatures of top 2 files
    for k, v in top[:3]:
        sigs = [l.strip()[:120] for l in v if re.match(r'\s{4}(public|protected|private)?\s*(static )?[\w<>\[\], ?]+ \w+\(.*\)\s*(throws \w+)?\s*\{', l)]
        o.append(f'### signatures {k}: ' + ' | '.join(sigs[:30]))
    with open(os.path.join(out, area + '.dossier.txt'), 'w', encoding='utf-8') as f: f.write('\n'.join(o))
    print(area, len(fl), tot)

