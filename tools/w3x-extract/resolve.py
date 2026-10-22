"""Merge the map's unit object data with the stock WC3 unit tables (SLK).

The map only stores fields it changes; every other field is inherited from the base unit. This script fills those
gaps and records, per value, whether it came from the map ('map') or from the stock tables ('default').

Usage: python3 -I resolve.py units.json <slk-dir> out.json
  <slk-dir> holds unitbalance.slk, unitdata.slk and unitweapons.slk (lowercase names, see README)
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from slk import read_slk

units_path, slk_dir, out_path = sys.argv[1:4]
u = json.load(open(units_path))
units = {x['id']: x for t in ('original', 'custom') for x in u[t]}
bal = read_slk(os.path.join(slk_dir, 'unitbalance.slk'))
dat = read_slk(os.path.join(slk_dir, 'unitdata.slk'))
wea = read_slk(os.path.join(slk_dir, 'unitweapons.slk'))

# field name -> (map field code, stock table, stock column)
FIELDS = {
    'hp': ('uhpm', bal, 'HP'),
    'armor': ('udef', bal, 'def'),
    'armorType': ('udty', bal, 'defType'),
    'speed': ('umvs', bal, 'spd'),
    'moveType': ('umvt', dat, 'movetp'),
    'gold': ('ugol', bal, 'goldcost'),
    'lumber': ('ulum', bal, 'lumbercost'),
    'buildTime': ('ubld', bal, 'bldtm'),
    'bountyBase': ('ubba', bal, 'bountyplus'),
    'bountyDice': ('ubdi', bal, 'bountydice'),
    'bountySides': ('ubsi', bal, 'bountysides'),
}
# attack n (1 or 2): field name -> (map field code, stock column). Columns and codes carry the attack number
WEAPON = {
    'baseDamage': ('ua{n}b', 'dmgplus{n}'),
    'dice': ('ua{n}d', 'dice{n}'),
    'sides': ('ua{n}s', 'sides{n}'),
    'cooldown': ('ua{n}c', 'cool{n}'),
    'range': ('ua{n}r', 'rangeN{n}'),
    'attackType': ('ua{n}t', 'atkType{n}'),
    'weaponType': ('ua{n}w', 'weapTp{n}'),
    'targets': ('ua{n}g', 'targs{n}'),
    'areaFull': ('ua{n}f', 'Farea{n}'),
    'areaMedium': ('ua{n}h', 'Harea{n}'),
    'areaSmall': ('ua{n}q', 'Qarea{n}'),
}


def num(v):
    return v if isinstance(v, (int, float)) else None


def pick(mods, code, table, col, base):
    if code in mods:
        return mods[code], 'map'
    v = table.get(base, {}).get(col)
    if v in (None, '-', ' - ', '_'):
        return None, 'missing'
    return v, 'default'


out = {}
for uid, x in units.items():
    mods, base = x['mods'], x['base']
    r = {'id': uid, 'base': base, 'name': mods.get('unam', bal.get(base, {}).get('comment(s)')), 'src': {}}
    for k, (code, table, col) in FIELDS.items():
        r[k], r['src'][k] = pick(mods, code, table, col, base)
    for n in (1, 2):
        w = {}
        for k, (code, col) in WEAPON.items():
            w[k], r['src'][f'attack{n}.{k}'] = pick(mods, code.format(n=n), wea, col.format(n=n), base)
        if isinstance(w['targets'], str):
            w['targets'] = sorted(set(w['targets'].split(',')) - {'enemies'})
        if isinstance(w['cooldown'], float):
            w['cooldown'] = round(w['cooldown'], 3)
        w['missileSpeed'] = mods.get(f'ua{n}z')  # only stored in the map; the stock value lives in the model data
        if num(w['baseDamage']) is not None and num(w['dice']) and num(w['sides']):
            w['damageMin'] = w['baseDamage'] + w['dice']
            w['damageMax'] = w['baseDamage'] + w['dice'] * w['sides']
        r[f'attack{n}'] = w
    # The attack that actually fires: the first one that has targets and damage (the map disables attack 1 on some
    # towers by inheriting 'none' as target). A missing cooldown on attack 2 falls back to the cooldown of attack 1
    for n in (1, 2):
        a = r[f'attack{n}']
        if a['targets'] and a['targets'] != ['none'] and a.get('damageMin') is not None:
            r['attack'] = dict(a, number=n)
            if n == 2 and a['cooldown'] is None:
                r['attack']['cooldown'] = r['attack1']['cooldown']
                r['src']['attack.cooldown'] = 'fallback-attack1'
            break
    r['abilities'] = [a for a in mods.get('uabi', '').split(',') if a]
    r['trains'] = [a for a in mods.get('ubui', '').split(',') if a]
    out[uid] = r

json.dump(out, open(out_path, 'w'), indent=1, sort_keys=True)
missing = {}
for r in out.values():
    for k, s in r['src'].items():
        if s == 'missing':
            missing[k] = missing.get(k, 0) + 1
print(len(out), 'units resolved; still missing:', missing)
