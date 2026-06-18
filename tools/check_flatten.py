import json, sys

for name in sys.argv[1:]:
    d = json.load(open(name))
    mods = d['modules']
    # Identify top module (one with cells, not a library blackbox)
    for mname, m in mods.items():
        if mname.startswith('_dollar_'):
            continue
        cells = m.get('cells', {})
        instances = {k: v for k, v in cells.items() if v.get('type', '').startswith('\\')}
        if instances:
            print(f'{name}: module={mname}, submodule_instances={len(instances)}')
            for k, v in list(instances.items())[:3]:
                print(f'  instance: {k} -> type={v["type"]}')
            print(f'  total cells in module: {len(cells)}')
