import json, os
W = os.path.dirname(os.path.abspath(__file__))
EJ = r'D:\Command Center\knowledge\entries.jsonl'
BASE = 'bar/src/main/java/com/solegendary/reignofnether/'
raw = open(EJ, 'rb').read()
txt = raw.decode('utf-8-sig')
have = {json.loads(l)['id'] for l in txt.split('\n') if l.strip()}
n = max(int(i[1:]) for i in have if i[0] == 'C') + 1
ents = json.load(open(os.path.join(W, 'entries.json')))
lines = []
for area, pkgs, purpose in ents:
    paths = []
    for p in pkgs:
        if p == 'tools': paths += ['tools/', '.github/workflows/']
        elif p == '.github': continue
        elif p in ('mod', 'engine'): paths.append(p + '/')
        else: paths.append(BASE + p)
    eid = 'C%03d' % n; n += 1
    assert eid not in have
    e = {"id": eid, "type": "codemap", "tags": [area, "code"], "paths": paths,
         "text": purpose + ' - see knowledge\\codemap\\' + area + '.md',
         "source": "codemap bbbdac21", "status": "rule", "injected": 0, "helped": 0, "hurt": 0, "confirmations": 0, "last_used": None}
    lines.append(json.dumps(e, ensure_ascii=False))
data = txt if txt.endswith('\n') else txt + '\n'
data += '\n'.join(lines) + '\n'
bom = raw.startswith(b'\xef\xbb\xbf')
open(EJ, 'wb').write((b'\xef\xbb\xbf' if bom else b'') + data.encode('utf-8'))
print(len(lines), 'added; first', lines[0][:90], 'bom', bom)
