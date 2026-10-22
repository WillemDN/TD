import re, json, sys
j = open(sys.argv[1], encoding='latin1').read()
u = json.load(open(sys.argv[2]))
units = {x['id']: x for t in ('original', 'custom') for x in u[t]}
body = re.search(r'function Trig_Set_Levels_Actions.*?endfunction', j, re.S).group(0)
rows = []; cur = None
for line in body.splitlines():
    m = re.search(r'"Level (\d+)', line)
    if m: cur = {'lvl': int(m.group(1))}; rows.append(cur)
    m = re.search(r"udg_Monster_Type = '(....)'", line)
    if m and cur: cur['type'] = m.group(1)
    m = re.search(r'udg_Monster_Amount = (\d+)', line)
    if m and cur: cur['n'] = int(m.group(1))
for r in rows:
    m = units.get(r.get('type'), {}).get('mods', {})
    print(r['lvl'], r.get('type'), m.get('unam'), r.get('n'), 'hp', m.get('uhpm'), 'arm', m.get('udef'), m.get('udty'), 'spd', m.get('umvs'), m.get('umvt'), 'bounty', m.get('ubba'), m.get('ubdi'), m.get('ubsi'))
