#!/usr/bin/env python3
"""Generates the data of the game mode "Elements" (fixed path, six elements, mixed towers).

Run from the repo root:  python3 tools/gen_elements.py
Writes game/data/elements/{towers,creeps,waves,matrix}.json, game/data/rules_elements.json,
game/data/maps/trail.json and merges the texts for this mode into game/data/i18n/{nl,en}.json.

Own design, inspired by the mechanics of the Warcraft III map family "Element TD" (a fixed path, six elements in a
circle that are strong or weak against each other, towers that mix elements). No names, numbers tables or assets of
that map are used: every tower, creep and number below is our own and is meant to be tuned in this file.
"""
import json
import os
from itertools import combinations

ROOT = os.environ.get('GEN_OUT') or os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'game', 'data')


def _tune(name, default):
    """Balance knobs can be overridden from the environment for the sweeps (GEN_<NAME>=value)."""
    return float(os.environ.get('GEN_' + name, default))


# ---------------------------------------------------------------- elements (the circle: each beats the next one)
ELEMENTS = ['light', 'dark', 'water', 'fire', 'nature', 'earth']
COLORS = {'light': '#ffe27a', 'dark': '#a56be8', 'water': '#4da3ff', 'fire': '#ff6a3c', 'nature': '#6bd45f', 'earth': '#b88a5a'}
EL_NAME = {
    'light': ('Licht', 'Light'), 'dark': ('Duisternis', 'Darkness'), 'water': ('Water', 'Water'),
    'fire': ('Vuur', 'Fire'), 'nature': ('Natuur', 'Nature'), 'earth': ('Aarde', 'Earth'),
}
STRONG, WEAK = 2.0, 0.5   # damage against the next element in the circle / the previous one


def beats(a):
    return ELEMENTS[(ELEMENTS.index(a) + 1) % 6]


def element_mult(att, defender):
    if defender == beats(att):
        return STRONG
    if att == beats(defender):
        return WEAK
    return 1.0


# ---------------------------------------------------------------- towers
# Single element towers: three tiers. dps is the damage per second against a neutral target.
TIERS = [  # tier, cost, dps, build time, unlock after n cleared levels
    (1, 10, 9.0, 4, 0),
    (2, 55, 55.0, 8, 8),
    (3, 240, 260.0, 14, 18),
]
DUAL = dict(cost=110, dps=100.0, build=9, unlock=4)
TRIPLE = dict(cost=420, dps=420.0, build=16, unlock=14)

# damage per second relative to the others: splash and slows are worth a lot on a crowded path, so those elements pay for it
EL_DPS = {'light': 1.15, 'dark': 1.15, 'water': 0.95, 'fire': 0.8, 'nature': 1.0, 'earth': 1.1}

# per element: attack character. range in tiles, cooldown in seconds, splash radii (full, half, quarter), effect names
SIGNATURE = {
    'light':  dict(range=6.8, cooldown=0.6, attack='pierce', proj=14.0),
    'dark':   dict(range=5.8, cooldown=1.0, attack='chaos', proj=10.0),
    'water':  dict(range=5.2, cooldown=0.9, attack='normal', proj=9.0),
    'fire':   dict(range=5.2, cooldown=1.0, attack='siege', proj=8.0),
    'nature': dict(range=5.6, cooldown=1.0, attack='normal', proj=9.0),
    'earth':  dict(range=5.0, cooldown=1.6, attack='siege', proj=7.0),
}

# tier names of the single towers (nl, en)
SINGLE_NAMES = {
    'light':  [('Lichtpunt', 'Light Spark'), ('Lichtstraal', 'Light Beam'), ('Zonnetoren', 'Sun Spire')],
    'dark':   [('Schaduwpunt', 'Shade Point'), ('Duisterspits', 'Dark Spike'), ('Leegtetoren', 'Void Spire')],
    'water':  [('Waterpunt', 'Water Point'), ('Stroomtoren', 'Current Tower'), ('Getijdetoren', 'Tide Tower')],
    'fire':   [('Vlampunt', 'Flame Point'), ('Vuurtoren', 'Fire Tower'), ('Vulkaantoren', 'Volcano Tower')],
    'nature': [('Wortelpunt', 'Root Point'), ('Bladtoren', 'Leaf Tower'), ('Levenstoren', 'Life Tower')],
    'earth':  [('Steenpunt', 'Stone Point'), ('Rotstoren', 'Rock Tower'), ('Bergtoren', 'Mountain Tower')],
}
DUAL_NAMES = {
    ('light', 'dark'): ('Schemering', 'Dusk'), ('light', 'water'): ('Regenboog', 'Rainbow'),
    ('light', 'fire'): ('Zonnevlam', 'Sunflare'), ('light', 'nature'): ('Bloesem', 'Bloom'),
    ('light', 'earth'): ('Kristalspits', 'Crystal Spike'), ('dark', 'water'): ('Moeras', 'Mire'),
    ('dark', 'fire'): ('Zwarte Vlam', 'Black Flame'), ('dark', 'nature'): ('Verval', 'Decay'),
    ('dark', 'earth'): ('Grafheuvel', 'Barrow'), ('water', 'fire'): ('Stoomketel', 'Steam Boiler'),
    ('water', 'nature'): ('Regenwoud', 'Rainforest'), ('water', 'earth'): ('Modderpoel', 'Mudpool'),
    ('fire', 'nature'): ('Bosbrand', 'Wildfire'), ('fire', 'earth'): ('Lavavloed', 'Lava Flow'),
    ('nature', 'earth'): ('Oerwoud', 'Elder Grove'),
}
TRIPLE_NAMES = {
    ('light', 'dark', 'water'): ('Maanvloed', 'Moontide'), ('light', 'dark', 'fire'): ('Zonsverduistering', 'Eclipse'),
    ('light', 'dark', 'nature'): ('Levensboom', 'Tree of Life'), ('light', 'dark', 'earth'): ('Obelisk', 'Obelisk'),
    ('light', 'water', 'fire'): ('Gloeiende Mist', 'Glowing Mist'), ('light', 'water', 'nature'): ('Dauwtoren', 'Dewspire'),
    ('light', 'water', 'earth'): ('Bergbron', 'Mountain Spring'), ('light', 'fire', 'nature'): ('Zomerzon', 'Midsummer'),
    ('light', 'fire', 'earth'): ('Smeltkroes', 'Crucible'), ('light', 'nature', 'earth'): ('Edelsteenwoud', 'Gemwood'),
    ('dark', 'water', 'fire'): ('Zwavelpoel', 'Sulphur Pit'), ('dark', 'water', 'nature'): ('Giftmoeras', 'Venom Bog'),
    ('dark', 'water', 'earth'): ('Dodenmoeras', 'Deadmarsh'), ('dark', 'fire', 'nature'): ('Aaskrater', 'Ashen Grove'),
    ('dark', 'fire', 'earth'): ('Onderwereld', 'Underworld'), ('dark', 'nature', 'earth'): ('Spookwoud', 'Hauntwood'),
    ('water', 'fire', 'nature'): ('Moessonketel', 'Monsoon Cauldron'), ('water', 'fire', 'earth'): ('Geiser', 'Geyser'),
    ('water', 'nature', 'earth'): ('Delta', 'Delta'), ('fire', 'nature', 'earth'): ('Vulkaanwoud', 'Volcanic Grove'),
}

# what each element adds as an effect, per power level (1 = tier 1 single). Strength grows with the tower's dps.
def effects_for(el, power, dps_avg):
    """Effects of one element on a tower. power is 1..3 (tier 1/2/3; mixes use the number of elements as a base)."""
    if el == 'light':
        return [{'kind': 'crit', 'chance': round(0.10 + 0.04 * power, 2), 'multiplier': 2.5}]
    if el == 'dark':
        return [{'kind': 'armor_reduce', 'amount': 1 + power, 'duration': 3.0}]
    if el == 'water':
        return [{'kind': 'slow', 'amount': round(0.18 + 0.06 * power, 2), 'duration': 2.0}]
    if el == 'nature':
        return [{'kind': 'poison', 'slow': 0.0, 'dpsFactor': round(0.35 + 0.1 * power, 2), 'duration': 4.0, 'bossImmune': False}]
    if el == 'earth':
        return [{'kind': 'root', 'chance': round(0.06 + 0.02 * power, 2), 'duration': 0.8, 'bossImmune': True}]
    return []   # fire: splash


def splash_for(power):
    s = 0.34 + 0.09 * power
    return [round(s, 2), round(s * 1.6, 2), round(s * 2.4, 2)]


def make_tower(tid, els, name, tier_label, cost, dps, build, unlock, tier_model, power):
    """One tower definition. els is the list of elements, dps the damage per second against a neutral target."""
    n = len(els)
    sig = [SIGNATURE[e] for e in els]
    cooldown = round(sum(s['cooldown'] for s in sig) / n, 2)
    rng = round(max(s['range'] for s in sig), 2)
    # a fast element in the mix shortens the cooldown, a heavy one lengthens it: the average is used
    dps *= sum(EL_DPS[e] for e in els) / n
    avg_dmg = dps * cooldown
    spread = 0.35
    attack_type = tid   # the matrix has a row per tower: the mix of the elements decides the damage per creep element
    eff = []
    for e in els:
        eff += effects_for(e, power, avg_dmg)
    # effects of several elements are weakened a little so that a mix is not simply the sum of its parts
    if n > 1:
        k = 0.85 if n == 2 else 0.75
        for f in eff:
            if f['kind'] == 'armor_reduce':
                f['amount'] = max(1, int(round(f['amount'] * (0.9 if n == 2 else 0.8))))
                continue
            for key in ('chance', 'amount', 'dpsFactor'):
                if key in f:
                    f[key] = round(float(f[key]) * k, 2)
    splash = splash_for(power) if 'fire' in els else None
    return {
        'id': tid,
        'element': els[0],
        'elements': els,
        'tier': tier_model,
        'name': {'nl': name[0], 'en': name[1]},
        'cost': {'gold': cost, 'lumber': 0},
        'buildTime': build,
        'unlockAfter': unlock,
        'footprint': [2, 2],
        'attack': {
            'damage': [max(1, int(round(avg_dmg * (1 - spread)))), max(2, int(round(avg_dmg * (1 + spread))))],
            'cooldown': cooldown,
            'range': rng,
            'type': attack_type,
            'targets': ['ground'],
            'projectileSpeed': round(sum(s['proj'] for s in sig) / n, 1),
            'splash': splash,
        },
        'effects': eff,
        'source': 'gen:elements',
    }


def build_towers():
    towers = {}
    groups = {'dual': [], 'triple': []}
    elements = []
    for e in ELEMENTS:
        ids = []
        for i, (tier, cost, dps, build, unlock) in enumerate(TIERS):
            tid = '%s_%d' % (e, tier)
            towers[tid] = make_tower(tid, [e], SINGLE_NAMES[e][i], tier, cost, dps, build, unlock, tier, tier)
            ids.append(tid)
        elements.append({'id': e, 'color': COLORS[e], 'name': {'nl': EL_NAME[e][0], 'en': EL_NAME[e][1]}, 'towers': ids})
    for combo in combinations(ELEMENTS, 2):
        tid = 'd_' + '_'.join(combo)
        towers[tid] = make_tower(tid, list(combo), DUAL_NAMES[combo], 0, DUAL['cost'], DUAL['dps'], DUAL['build'], DUAL['unlock'], 4, 2)
        groups['dual'].append(tid)
    for combo in combinations(ELEMENTS, 3):
        tid = 't_' + '_'.join(combo)
        towers[tid] = make_tower(tid, list(combo), TRIPLE_NAMES[combo], 0, TRIPLE['cost'], TRIPLE['dps'], TRIPLE['build'], TRIPLE['unlock'], 5, 3)
        groups['triple'].append(tid)
    return {'elements': elements, 'ultimate': '', 'groups': groups, 'towers': towers}


def build_matrix(towers):
    armor_types = list(ELEMENTS)
    rows = {}
    for tid, t in towers['towers'].items():
        els = t['elements']
        rows[tid] = {a: round(sum(element_mult(e, a) for e in els) / len(els), 4) for a in armor_types}
    return {'_comment': 'Generated by tools/gen_elements.py. A row per tower: the average over its elements of 2.0 against the next element in the circle and 0.5 against the previous one.',
            'attackTypes': list(rows.keys()), 'armorTypes': armor_types, 'multipliers': rows}


# ---------------------------------------------------------------- creeps and waves
LAST_LEVEL = 40
COUNT = 30
HP0 = _tune('HP0', 22.0)
HP_GROWTH = _tune('HP_GROWTH', 1.18)
HP_LINEAR = _tune('HP_LINEAR', 0.035)
BOUNTY0 = _tune('BOUNTY0', 2.0)
BOUNTY_GROWTH = _tune('BOUNTY_GROWTH', 1.095)
BOSS_EVERY = 5
BOSS_HP = _tune('BOSS_HP', 14.0)
BOSS_BOUNTY = 12.0
SPEED = _tune('SPEED', 2.5)

# the order of the elements per block of six levels (no element twice in a row, but not predictable either)
BLOCK_ORDERS = [
    [0, 3, 1, 4, 2, 5], [3, 5, 0, 2, 4, 1], [2, 4, 5, 1, 0, 3], [5, 1, 3, 0, 2, 4],
    [4, 0, 2, 5, 3, 1], [1, 2, 4, 3, 5, 0], [0, 4, 3, 1, 5, 2], [3, 1, 5, 2, 0, 4],
]

# models (existing creep ids of the classic mode are reused with the colour of the element)
MODELS = ['snow_scout', 'frost_tinker', 'tundra_brute', 'ice_stalker', 'rime_runner', 'glacier_troll', 'wolf_raider',
          'clockwork_brute', 'frost_lizard', 'shadow_imp', 'shard_golem', 'siege_sled', 'frozen_husk', 'cursed_rider']
BOSS_MODELS = ['glacier_lord', 'dire_bear', 'ice_king', 'frost_giant', 'elder_wyrm', 'blizzard_dragon', 'warlord', 'frost_marshal']

CREEP_NAMES = {   # per element: (nl, en) base name; prefixes are added for the traits
    'light': ('Lichtgeest', 'Light Wisp'), 'dark': ('Schaduwling', 'Shade'), 'water': ('Watergeest', 'Water Sprite'),
    'fire': ('Vuurling', 'Fire Imp'), 'nature': ('Bosgeest', 'Grove Spirit'), 'earth': ('Steenling', 'Rock Crawler'),
}
BOSS_NAMES = {
    'light': ('Lichtwachter', 'Light Guardian'), 'dark': ('Schaduwwachter', 'Shadow Guardian'), 'water': ('Waterwachter', 'Water Guardian'),
    'fire': ('Vuurwachter', 'Fire Guardian'), 'nature': ('Natuurwachter', 'Nature Guardian'), 'earth': ('Aardewachter', 'Earth Guardian'),
}
TRAIT_PREFIX = {'fast': ('Snelle', 'Swift'), 'healing': ('Helende', 'Healing'), 'undead': ('Onsterfelijke', 'Undying'),
                'mechanical': ('Gepantserde', 'Plated')}


# which special kind a level has (bosses, every 5th level, have none: they are simply big)
TRAIT_LEVELS = {
    'fast': [3, 7, 11, 14, 19, 23, 29],
    'healing': [8, 13, 17, 22, 28, 34, 38],
    'undead': [12, 16, 21, 27, 33, 37, 39],
    'mechanical': [18, 24, 26, 31, 32, 36],
}


def level_traits(level):
    return [t for t, levels in TRAIT_LEVELS.items() if level in levels]


GUARDIAN_ORDER = ['water', 'nature', 'light', 'earth', 'dark', 'fire', 'nature', 'water']   # level 5, 10, 15, ...


def level_element(level):
    if level % BOSS_EVERY == 0:
        return GUARDIAN_ORDER[(level // BOSS_EVERY - 1) % len(GUARDIAN_ORDER)]
    block, idx = divmod(level - 1, 6)
    return ELEMENTS[BLOCK_ORDERS[block % len(BLOCK_ORDERS)][idx]]


def build_waves():
    creeps = {}
    waves = []
    for level in range(1, LAST_LEVEL + 1):
        el = level_element(level)
        boss = level % BOSS_EVERY == 0
        traits = level_traits(level)
        hp = HP0 * (HP_GROWTH ** (level - 1)) * (1.0 + HP_LINEAR * (level - 1))
        bounty = BOUNTY0 * (BOUNTY_GROWTH ** (level - 1))
        armor = int(level * 0.5)
        speed = SPEED
        if boss:
            hp *= BOSS_HP
            bounty *= BOSS_BOUNTY
            armor = int(level * 0.8)
            speed = SPEED * 0.8
            nm = BOSS_NAMES[el]
            model = BOSS_MODELS[(level // BOSS_EVERY - 1) % len(BOSS_MODELS)]
        else:
            nm = CREEP_NAMES[el]
            model = MODELS[(level - 1) % len(MODELS)]
            for t in traits:
                nm = ('%s %s' % (TRAIT_PREFIX[t][0], nm[0].lower()), '%s %s' % (TRAIT_PREFIX[t][1], nm[1].lower()))
            if 'fast' in traits:
                speed = SPEED * 1.3
        cid = 'e%02d' % level
        creeps[cid] = {
            'id': cid,
            'name': {'nl': nm[0], 'en': nm[1]},
            'hp': int(round(hp)),
            'armor': armor,
            'armorType': el,
            'speed': round(speed, 3),
            'air': False,
            'boss': boss,
            'traits': traits,
            'model': model,
            'tint': COLORS[el],
            'bounty': {'base': int(round(bounty)), 'dice': 0, 'sides': 1},
            'source': 'gen:elements',
        }
        waves.append({'level': level, 'creep': cid, 'countPerSpawn': 1 if boss else COUNT, 'noLifeLoss': False, 'finalBoss': False})
    return creeps, waves


# ---------------------------------------------------------------- the map: a serpentine path with build plates
def build_map():
    W, H = 96, 52
    grid = [['#'] * W for _ in range(H)]
    band_h, lane_h = 8, 4
    top = 3
    lanes = []   # (y0, y1)
    y = top
    bands = []
    for i in range(4):
        bands.append((y, y + band_h - 1))
        y += band_h
        if i < 3:
            lanes.append((y, y + lane_h - 1))
            y += lane_h
    # lanes: 0 left to right (starts at the spawn), 1 right to left, 2 left to right (ends at the ship)
    x_lo, x_hi = 8, 87
    for i, (y0, y1) in enumerate(lanes):
        xs = range(2, 88) if i == 0 else (range(8, 88) if i == 1 else range(8, 94))
        for yy in range(y0, y1 + 1):
            for xx in xs:
                grid[yy][xx] = ','
    # connectors through the bands between lane i and lane i+1
    conn = {1: range(84, 88), 2: range(8, 12)}   # band index -> x range (right side after lane 0, left side after lane 1)
    for b, xs in conn.items():
        y0, y1 = bands[b]
        for yy in range(y0, y1 + 1):
            for xx in xs:
                grid[yy][xx] = ','
    # build plates everywhere else inside the frame
    for b, (y0, y1) in enumerate(bands):
        for yy in range(y0, y1 + 1):
            for xx in range(x_lo, x_hi + 1):
                if grid[yy][xx] == '#':
                    grid[yy][xx] = 'o'
    lane_rows = lanes
    goal = [90, lane_rows[2][0], 93, lane_rows[2][1]]
    spawn_y = lane_rows[0][0] + 1
    spawn_y2 = lane_rows[0][0] + 2
    rows = [''.join(r) for r in grid]
    mid = bands[1][0]
    return {
        'id': 'trail',
        'name': {'nl': 'Elementenpad', 'en': 'Elemental Trail'},
        'width': W, 'height': H, 'cellSize': 0.5,
        'rows': rows,
        'spawns': [{'cell': [3, spawn_y], 'lane': 0}],
        'goal': {'rect': goal},
        'lanes': [{'rows': [l[0], l[1]], 'fieldX': [x_lo, x_hi]} for l in lane_rows],
        'shared': {'rect': [2, bands[0][0], 40, bands[1][1]]},   # the opening view: the start of the path
        'note': 'Generated by tools/gen_elements.py. "o" = build plate (towers yes, creeps never), "," = the path.',
    }


# ---------------------------------------------------------------- rules and texts
def build_rules():
    return {
        'id': 'elements',
        'name': {'nl': 'Elementen', 'en': 'Elements'},
        'map': 'trail',
        'files': {
            'towers': 'elements/towers.json', 'creeps': 'elements/creeps.json',
            'waves': 'elements/waves.json', 'matrix': 'elements/matrix.json',
        },
        'tickRate': 20,
        'startGold': 70,
        'startLumber': 2,
        'lumberAtLevel': {str(l): 1 for l in range(BOSS_EVERY, LAST_LEVEL + 1, BOSS_EVERY)},
        'levelBonus': {'base': 6, 'perLevel': 2},
        'firstWaveDelay': 45.0,
        'waveDelay': 15.0,
        'spawnRoundInterval': 0.5,
        'spawnPoints': 1,
        'playerScaleBase': 1,
        'lastLevel': LAST_LEVEL,
        'difficulties': {'easy': 60, 'normal': 40, 'hard': 25, 'perfection': 1},
        'hpMultiplier': {'easy': 0.7, 'normal': 1.0, 'hard': 1.2, 'perfection': 1.2},   # on top of the number of lives
        'defaultDifficulty': 'normal',
        'sellRefund': {'idle': 1.0, 'wave': 0.8},
        'skipBonusPerSecond': 0.2,
        'armorStep': 0.06,
        'interest': {'rate': 0.02, 'interval': 15.0},
        'leakRespawn': True,
        'moveBuildShare': 0.35,
    }


TEXTS = {
    'nl': {
        'mode.classic': 'Wintermaul',
        'mode.elements': 'Elementen',
        'mode.classic.desc': 'Bouw een maze van torens in een open veld. Samenwerken met meer spelers, solo erg zwaar.',
        'mode.elements.desc': 'Een vast pad met bouwplaten. Zes elementen die elkaar versterken of verzwakken, torens die je mengt. Geschikt voor alleen spelen.',
        'menu.choose_mode': 'Kies een spel',
        'menu.hint.classic': '1 speler · 35 levels · bouw een maze van torens',
        'menu.hint.elements': '1 speler · 40 levels · vast pad, 6 elementen, gemengde torens',
        'menu.mode.classic': 'Modus: Wintermaul',
        'menu.mode.elements': 'Modus: Elementen',
        'group.dual': 'Dubbel',
        'group.triple': 'Drievoudig',
        'hud.choose_element_n': 'Kies een element ({0} hout)',
        'hud.locked_level': 'Lv {0}',
        'msg.locked_level': 'Nog niet beschikbaar: dit komt later in het spel',
        'msg.interest': 'Rente +{0}',
        'msg.revived': 'Een creep staat weer op!',
        'msg.new_element': 'Guardian verslagen! Kies een nieuw element (+ in de lade)',
        'stat.elements': 'Elementen',
        'stat.creep_element': 'Element',
        'trait.fast': 'Snel',
        'trait.healing': 'Helend',
        'trait.undead': 'Onsterfelijk',
        'trait.mechanical': 'Gepantserd',
        'trait.fast.desc': 'Loopt 30% sneller',
        'trait.healing.desc': 'Geneest 20% van de buren als hij sterft',
        'trait.undead.desc': 'Staat 5 s na de dood nog één keer op met 33% leven',
        'trait.mechanical.desc': 'Is 3 s onkwetsbaar in elke 12 s',
        'msg.boss_element': 'Wachter! Verslaan geeft je een nieuw element',
        'help.tip.classic': 'Tip: je kunt een toren plaatsen waar je wilt, zolang er een pad naar het schip overblijft. Maak het pad zo lang mogelijk!',
        'help.tip.elements': 'Tip: elk element is sterk tegen het volgende in de cirkel (Licht, Duisternis, Water, Vuur, Natuur, Aarde) en zwak tegen het vorige. Kijk welk element de volgende golf heeft!',
        'diff.easy': 'Makkelijk', 'diff.normal': 'Normaal', 'diff.hard': 'Moeilijk', 'diff.perfection': 'Perfectie',
        'menu.lives': '{0} levens', 'menu.life': '1 leven',
        'hud.interest': 'Rente: 2% per 15 s',
        'fx.poison_plain': 'Gif: {0} schade/s voor {1} s',
        'hud.elements_none': 'Leer eerst meer elementen om te mengen',
    },
    'en': {
        'mode.classic': 'Wintermaul',
        'mode.elements': 'Elements',
        'mode.classic.desc': 'Build a maze of towers in an open field. Co-op with more players, very hard solo.',
        'mode.elements.desc': 'A fixed path with build plates. Six elements that strengthen or weaken each other, towers you mix. Made for playing alone.',
        'menu.choose_mode': 'Choose a game',
        'menu.hint.classic': '1 player · 35 levels · build a maze of towers',
        'menu.hint.elements': '1 player · 40 levels · fixed path, 6 elements, mixed towers',
        'menu.mode.classic': 'Mode: Wintermaul',
        'menu.mode.elements': 'Mode: Elements',
        'group.dual': 'Dual',
        'group.triple': 'Triple',
        'hud.choose_element_n': 'Choose an element ({0} lumber)',
        'hud.locked_level': 'Lv {0}',
        'msg.locked_level': 'Not available yet: this comes later in the game',
        'msg.interest': 'Interest +{0}',
        'msg.revived': 'A creep stands up again!',
        'msg.new_element': 'Guardian beaten! Choose a new element (+ in the tray)',
        'stat.elements': 'Elements',
        'stat.creep_element': 'Element',
        'trait.fast': 'Swift',
        'trait.healing': 'Healing',
        'trait.undead': 'Undying',
        'trait.mechanical': 'Plated',
        'trait.fast.desc': 'Runs 30% faster',
        'trait.healing.desc': 'Heals 20% of its neighbours when it dies',
        'trait.undead.desc': 'Stands up once, 5 s after it died, with 33% life',
        'trait.mechanical.desc': 'Invulnerable for 3 s of every 12 s',
        'msg.boss_element': 'Guardian! Beating it gives you a new element',
        'help.tip.classic': 'Tip: place towers anywhere as long as a path to the ship remains. Make the path as long as you can!',
        'help.tip.elements': 'Tip: every element is strong against the next one in the circle (Light, Darkness, Water, Fire, Nature, Earth) and weak against the previous one. Check which element the next wave has!',
        'diff.easy': 'Easy', 'diff.normal': 'Normal', 'diff.hard': 'Hard', 'diff.perfection': 'Perfection',
        'menu.lives': '{0} lives', 'menu.life': '1 life',
        'hud.interest': 'Interest: 2% per 15 s',
        'fx.poison_plain': 'Poison: {0} damage/s for {1} s',
        'hud.elements_none': 'Learn more elements first to mix them',
    },
}
for e in ELEMENTS:
    TEXTS['nl']['armor.' + e] = EL_NAME[e][0]
    TEXTS['en']['armor.' + e] = EL_NAME[e][1]
    TEXTS['nl']['element.' + e] = EL_NAME[e][0]
    TEXTS['en']['element.' + e] = EL_NAME[e][1]


def write(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        json.dump(obj, f, indent=1, ensure_ascii=False)
        f.write('\n')


def main():
    towers = build_towers()
    creeps, waves = build_waves()
    write(os.path.join(ROOT, 'elements', 'towers.json'), towers)
    write(os.path.join(ROOT, 'elements', 'matrix.json'), build_matrix(towers))
    write(os.path.join(ROOT, 'elements', 'creeps.json'), {'creeps': creeps})
    write(os.path.join(ROOT, 'elements', 'waves.json'), {'waves': waves})
    write(os.path.join(ROOT, 'rules_elements.json'), build_rules())
    write(os.path.join(ROOT, 'maps', 'trail.json'), build_map())
    if os.environ.get('GEN_OUT'):
        print('towers %d, creeps %d, waves %d (sweep output, no texts)' % (len(towers['towers']), len(creeps), len(waves)))
        return
    for lang, texts in TEXTS.items():
        p = os.path.join(ROOT, 'i18n', lang + '.json')
        with open(p) as f:
            table = json.load(f)
        table.update(texts)
        write(p, table)
    print('towers %d, creeps %d, waves %d' % (len(towers['towers']), len(creeps), len(waves)))


if __name__ == '__main__':
    main()
