import json, sys

def get_cells(path):
    d = json.load(open(path))
    cells = {}
    for mname, m in d['modules'].items():
        if 'dollar' in mname:
            continue
        for cname, c in m.get('cells', {}).items():
            t = c['type']
            cells[t] = cells.get(t, 0) + 1
    return cells, sum(cells.values())

hier_cells, hier_total = get_cells('synth/sphere3_32_synth_hier_abc.json')
flat_cells, flat_total = get_cells('synth/sphere3_32_synth_flat_abc.json')

print(f'{"Cell Type":25s} {"Hier ABC":>10s} {"Flat ABC":>10s} {"Delta":>8s}')
print('-' * 55)
all_types = sorted(set(hier_cells) | set(flat_cells))
for t in all_types:
    h = hier_cells.get(t, 0)
    f = flat_cells.get(t, 0)
    if h != f:
        d = f - h
        print(f'{t:25s} {h:>10d} {f:>10d} {d:>+8d}')
print('-' * 55)
print(f'{"TOTAL":25s} {hier_total:>10d} {flat_total:>10d} {flat_total-hier_total:>+8d}')
