import re, os, random, glob
P = r'D:\btr\bar\src\main\java\com\solegendary\reignofnether'
OUT = r'D:\Command Center\knowledge\codemap'
rows = []
for f in glob.glob(OUT + r'\*.md'):
    if f.endswith('INDEX.md') or 'tools-ci' in f or 'legacy' in f: continue
    for l in open(f, encoding='utf-8'):
        m = re.match(r'- `([\w/]+\.java)` \(~?(\d+)', l)
        if m: rows.append((os.path.basename(f), m.group(1), int(m.group(2))))
print('key class lines', len(rows))
bad = 0
for r in rows:
    fp = os.path.join(P, r[1].replace('/', os.sep))
    if not os.path.exists(fp): bad += 1; print('MISSING', r); continue
    n = len(open(fp, encoding='utf-8', errors='replace').read().split('\n'))
    if abs(n - r[2]) > max(2, 0.1 * n): bad += 1; print('OFF', r, n)
print('bad total', bad)
random.seed(27)
for r in random.sample(rows, 5):
    fp = os.path.join(P, r[1].replace('/', os.sep))
    n = len(open(fp, encoding='utf-8', errors='replace').read().split('\n'))
    print('SPOT', r[0], r[1], 'claimed', r[2], 'real', n, 'OK' if abs(n - r[2]) <= max(2, 0.1 * n) else 'BAD')
# INDEX class existence
idx = open(OUT + r'\INDEX.md', encoding='utf-8').read()
for m in set(re.findall(r'\| ([a-z]+/[A-Z]\w+)', idx)) | set(re.findall(r'(?:, |\| |\()([a-z]+/[A-Z]\w+)', idx)):
    if not os.path.exists(os.path.join(P, m.replace('/', os.sep) + '.java')): print('INDEX missing', m)
