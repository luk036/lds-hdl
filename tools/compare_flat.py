import json, subprocess

def get_json(rev, path):
    if rev:
        raw = subprocess.check_output(['git', 'show', f'{rev}:{path}'])
        return json.loads(raw)
    return json.load(open(path))

for label, rev, path in [
    ('sphere_32  non-flat',  '5de1e31', 'synth/sphere_32_synth.json'),
    ('sphere_32  flat',      None,      'synth/sphere_32_synth.json'),
    ('sphere3_32 non-flat',  '5de1e31', 'synth/sphere3_32_synth.json'),
    ('sphere3_32 flat',      None,      'synth/sphere3_32_synth.json'),
]:
    d = get_json(rev, path)
    mods = d['modules']
    user = [m for m in mods if 'dollar' not in m]
    cell_counts = {}
    for mname in user:
        m = mods[mname]
        for cname, c in m.get('cells', {}).items():
            t = c['type']
            cell_counts[t] = cell_counts.get(t, 0) + 1
    total = sum(cell_counts.values())
    submods = {t: n for t, n in cell_counts.items() if not t.startswith('$_')}

    print(f'{label}:')
    print(f'  modules:           {len(user)}')
    print(f'  total cells:       {total}')
    print(f'  submodule refs:    {len(submods)} ({dict(list(submods.items())[:5])})' if submods else '  submodule refs:    none')
    top = sorted(cell_counts.items(), key=lambda x: -x[1])[:8]
    for t, n in top:
        print(f'    {t:20s} {n:>8d}')
    print()
