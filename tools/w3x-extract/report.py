"""Print Markdown tables (waves and towers) from the output of resolve.py and the map script.

Usage: python3 -I report.py resolved.json war3map.j
"""
import json
import re
import sys

r = json.load(open(sys.argv[1]))
script = open(sys.argv[2], encoding='latin1').read()

# 128 WC3 units = 1 tile
TILE = 128


def tiles(v):
    return '' if v is None else f'{v / TILE:.1f}'


def fmt(v):
    return '' if v is None else v


body = re.search(r'function Trig_Set_Levels_Actions.*?endfunction', script, re.S).group(0)
rows, cur = [], None
for line in body.splitlines():
    m = re.search(r'"Level (\d+)', line)
    if m:
        cur = {'lvl': int(m.group(1))}
        rows.append(cur)
    m = re.search(r"udg_Monster_Type = '(....)'", line)
    if m and cur:
        cur['type'] = m.group(1)
    m = re.search(r'udg_Monster_Amount = (\d+)', line)
    if m and cur:
        cur['n'] = int(m.group(1))

print('| Lvl | Creep | n | HP | Armor | Armortype | Snelheid | Beweging | Bounty |')
print('|---:|---|---:|---:|---:|---|---:|---|---|')
for w in rows:
    c = r[w['type']]
    bounty = c['bountyBase'] + c['bountyDice'] * (c['bountySides'] + 1) / 2 if c['bountyBase'] is not None else None
    b = f"{c['bountyBase']}+{c['bountyDice']}d{c['bountySides']}"
    print(f"| {w['lvl']} | {c['name']} | {w['n']} | {c['hp']} | {c['armor']} | {c['armorType']} | {c['speed']} | {c['moveType']} | {b} |")

print()
elements = [('Fire', 'nC03'), ('Ice', 'oC25'), ('Tech', 'hC07'), ('Electric', 'eC10'), ('Stone', 'uC13'),
            ('Poison', 'oC22'), ('Nature', 'efon'), ('Undead', 'uC81'), ('Crystal', 'uC98')]
print('| Element | Toren | Goud | Hout | Bouwtijd | Schade | Cooldown | Range (tiles) | Aanvalstype | Splash (tiles, vol/half/kwart) | Doelen | Projectiel | Abilities |')
print('|---|---|---:|---:|---:|---|---:|---:|---|---|---|---:|---|')
towers = [(el, t) for el, b in elements for t in r[b]['trains']] + [('Alle', 'hC63')]
for el, tid in towers:
    t = r.get(tid)
    if not t:
        continue
    a = t.get('attack') or {}
    dmg = ''
    if a.get('damageMin') is not None:
        dmg = str(a['damageMin']) if a['damageMin'] == a['damageMax'] else f"{a['damageMin']}–{a['damageMax']}"
    splash = '/'.join(tiles(a.get(k)) for k in ('areaFull', 'areaMedium', 'areaSmall')) if a.get('areaFull') else ''
    fb = '*' if t['src'].get('attack.cooldown') == 'fallback-attack1' else ''
    print(f"| {el} | {t['name']} | {fmt(t['gold'])} | {t['lumber'] or ''} | {fmt(t['buildTime'])} | {dmg} | {fmt(a.get('cooldown'))}{fb} | {tiles(a.get('range'))} | {fmt(a.get('attackType'))} | {splash} | {','.join(a.get('targets') or [])} | {fmt(a.get('missileSpeed'))} | {','.join(sorted(set(t['abilities'])))} |")
