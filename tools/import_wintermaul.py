#!/usr/bin/env python3
"""Turn the resolved Wintermaul v13 numbers into the game's JSON data (game/data/).

Usage: python3 -I tools/import_wintermaul.py

Inputs : docs/research/data/wintermaul-v13-resolved.json   (numbers, see docs/research/wintermaul-v13-resolved.md)
         tools/import_overlay.py                           (our ids, names and effect parameters)
Outputs: game/data/towers.json, game/data/creeps.json, game/data/waves_classic.json

WC3 distances and speeds are converted to tiles (128 WC3 units = 1 tile).
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_overlay as ov  # noqa: E402

TILE = 128.0
INSTANT_SPEED = 5000  # WC3 projectile speeds at or above this are effectively instant
DEFAULT_PROJECTILE = 1200  # WC3 units/s, used when the map does not set a projectile speed

resolved = json.load(open(os.path.join(ROOT, 'docs/research/data/wintermaul-v13-resolved.json')))


def tiles(v):
    return None if v is None else round(v / TILE, 3)


def tower(src, tid, element, tier, name, effects, override):
    u = resolved[src]
    a = u['attack']
    speed = a['missileSpeed']
    if speed is None:
        speed = 0 if a['weaponType'] in ('normal', 'instant') else DEFAULT_PROJECTILE
    if speed >= INSTANT_SPEED:
        speed = 0
    splash = None
    if a.get('areaFull'):
        splash = [tiles(a['areaFull']), tiles(a['areaMedium']), tiles(a['areaSmall'])]
    return {
        'id': tid,
        'element': element,
        'tier': tier,
        'name': name,
        'cost': {'gold': u['gold'], 'lumber': u['lumber'] or 0},
        'buildTime': u['buildTime'],
        'footprint': [2, 2],
        'attack': {
            'damage': [a['damageMin'], a['damageMax']],
            'cooldown': a['cooldown'],
            'range': tiles(a['range']),
            'type': a['attackType'],
            'targets': override.get('targets', a['targets']),
            'projectileSpeed': round(speed / TILE, 3),
            'splash': splash,
        },
        'effects': effects,
        'source': 'v13:' + src,
    }


towers = {}
elements = []
for eid, builder, color, name in ov.ELEMENTS:
    ids = []
    for t in ov.TOWERS:
        if t[2] != eid:
            continue
        towers[t[1]] = tower(*t)
        ids.append(t[1])
    ids.sort(key=lambda i: towers[i]['tier'])
    elements.append({'id': eid, 'color': color, 'name': name, 'towers': ids})
ult = ov.ULTIMATE
towers[ult[1]] = tower(*ult)
ultimate = ult[1]

creeps = {}
waves = []
for level, src, cid, name in ov.CREEPS:
    u = resolved[src]
    air = u['moveType'] == 'fly'
    creeps[cid] = {
        'id': cid,
        'name': name,
        'hp': u['hp'],
        'armor': u['armor'],
        'armorType': u['armorType'],
        'speed': tiles(u['speed']),
        'air': air,
        'boss': level in ov.BOSS_LEVELS,
        'bounty': {'base': u['bountyBase'], 'dice': u['bountyDice'], 'sides': u['bountySides']},
        'source': 'v13:' + src,
    }
# creeps per spawn point and level, from the map script 'Set Levels' (docs/research/wintermaul-v13-data.md section 4)
COUNTS = {1: 20, 2: 20, 3: 20, 4: 20, 5: 15, 6: 20, 7: 20, 8: 20, 9: 20, 10: 1, 11: 20, 12: 20, 13: 20, 14: 20, 15: 15,
          16: 20, 17: 20, 18: 20, 19: 20, 20: 1, 21: 20, 22: 20, 23: 20, 24: 20, 25: 15, 26: 20, 27: 20, 28: 20,
          29: 15, 30: 1, 31: 20, 32: 20, 33: 20, 34: 20, 35: 50}
for level, src, cid, name in ov.CREEPS:
    waves.append({
        'level': level,
        'creep': cid,
        'countPerSpawn': COUNTS[level],
        'noLifeLoss': level in ov.BONUS_LEVELS,
        'finalBoss': level == 30,
    })

out = os.path.join(ROOT, 'game/data')
os.makedirs(out, exist_ok=True)


def dump(name, obj):
    with open(os.path.join(out, name), 'w', encoding='utf-8') as f:
        json.dump(obj, f, indent=1, ensure_ascii=False)
        f.write('\n')


dump('towers.json', {'elements': elements, 'ultimate': ultimate, 'towers': towers})
dump('creeps.json', {'creeps': creeps})
dump('waves_classic.json', {'waves': waves})
print(f'{len(towers)} towers, {len(creeps)} creeps, {len(waves)} waves written to game/data')
