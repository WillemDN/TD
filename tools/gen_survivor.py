#!/usr/bin/env python3
"""Generates the data of the game mode "Last Tower" (a survivor-style game: one tower, endless waves, a shop).

Run from the repo root:  python3 tools/gen_survivor.py
Writes game/data/survivor/{weapons,upgrades,enemies}.json, game/data/rules_survivor.json and merges the texts for this
mode into game/data/i18n/{nl,en}.json.

Own design, inspired by the idea of the Warcraft III map "Tower Survivors" (a roguelike where the tower cannot move, you
only choose weapons and upgrades, and survive as long as possible). No names, tables, texts or assets of that map are
used. Every weapon, upgrade, enemy and number below is our own and meant to be tuned here.
"""
import json
import os

ROOT = os.environ.get('GEN_OUT') or os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'game', 'data')


def _tune(name, default):
    return float(os.environ.get('GEN_' + name, default))


RARITIES = ['common', 'uncommon', 'rare', 'epic']
COST = {0: 60, 1: 180, 2: 550, 3: 1500}          # weapon prices per rarity
UP_COST = {0: 50, 1: 160, 2: 500, 3: 1400}        # upgrade prices per rarity


def nm(nl, en):
    return {'nl': nl, 'en': en}


# ---------------------------------------------------------------- weapons
# kind: projectile | orbit | aura | artillery | chain | mine | glaive | strike
# dtype: phys (reduced by armor) or magic (ignores armor)
def weapon(id, nl, en, rarity, kind, dtype, damage, cooldown, range_=0.0, **extra):
    w = {'id': id, 'name': nm(nl, en), 'rarity': rarity, 'cost': COST[rarity], 'kind': kind, 'dtype': dtype,
         'damage': damage, 'cooldown': cooldown, 'range': range_}
    w.update(extra)
    return w


WEAPONS = [
    # common
    weapon('knives', 'Werpmessen', 'Throwing Knives', 0, 'projectile', 'phys', 9, 0.7, 7.0, speed=15.0, pierce=0),
    weapon('crossbow', 'Kruisboog', 'Crossbow', 0, 'projectile', 'phys', 13, 1.0, 9.0, speed=17.0, pierce=1),
    weapon('spikering', 'Stekelring', 'Spike Ring', 0, 'orbit', 'phys', 7, 0.45, 2.2, blades=2, spin=3.0, size=0.55),
    weapon('flask', 'Vuurflesje', 'Fire Flask', 0, 'artillery', 'magic', 16, 1.7, 8.0, splash=1.5, flight=0.7),
    weapon('bell', 'Vorstbel', 'Frost Bell', 0, 'aura', 'magic', 6, 1.6, 3.2, slow=0.35, slowTime=1.6),
    weapon('spark', 'Vonkensteen', 'Spark Stone', 0, 'chain', 'magic', 9, 1.1, 6.0, bounces=3, chainRange=3.0),
    # uncommon
    weapon('spikewheel', 'Stekelwiel', 'Spikewheel', 1, 'orbit', 'phys', 12, 0.4, 3.0, blades=3, spin=2.6, size=0.7),
    weapon('mines', 'Landmijnen', 'Land Mines', 1, 'mine', 'phys', 32, 1.3, 5.5, splash=1.5, maxMines=8, mineLife=25.0),
    weapon('glaive', 'Werpschijf', 'Throwing Disc', 1, 'glaive', 'phys', 20, 1.5, 8.0, speed=11.0, heal=0),
    weapon('darts', 'Gifpijltjes', 'Poison Darts', 1, 'projectile', 'phys', 7, 0.8, 8.0, speed=16.0, pierce=0, poison=9.0, poisonTime=4.0),
    weapon('catapult', 'Katapult', 'Catapult', 1, 'artillery', 'phys', 42, 2.4, 11.0, splash=2.2, flight=1.0),
    weapon('blight', 'Verderfaura', 'Blight Aura', 1, 'aura', 'magic', 9, 0.5, 3.6, slow=0.0, slowTime=0.0),
    # rare
    weapon('tesla', 'Teslakanon', 'Tesla Cannon', 2, 'chain', 'magic', 26, 0.85, 7.0, bounces=5, chainRange=3.4),
    weapon('storm', 'Stormgenerator', 'Storm Generator', 2, 'strike', 'magic', 38, 1.1, 7.0, count=3),
    weapon('impaler', 'Spietser', 'Impaler', 2, 'projectile', 'phys', 65, 1.5, 11.0, speed=18.0, pierce=6),
    weapon('gatling', 'Snelvuurkoker', 'Rapid Launcher', 2, 'projectile', 'phys', 6, 0.12, 7.5, speed=20.0, pierce=0, jitter=0.12),
    # epic
    weapon('scythe', 'Doodssikkel', 'Death Scythe', 3, 'glaive', 'phys', 110, 1.8, 7.0, speed=9.0, heal=4),
    weapon('inferno', 'Hellevuursteen', 'Inferno Stone', 3, 'aura', 'magic', 40, 0.5, 4.5, slow=0.0, slowTime=0.0, burn=80.0),
    weapon('meteors', 'Meteorenregen', 'Meteor Rain', 3, 'artillery', 'magic', 220, 3.0, 12.0, splash=2.5, flight=1.2, count=3),
    weapon('arcreactor', 'Boogreactor', 'Arc Reactor', 3, 'chain', 'magic', 70, 0.55, 8.0, bounces=8, chainRange=3.6),
]


# one knob for the damage of all weapons (balance sweeps: GEN_WEAPON_DMG=1.5)
WDMG = _tune('WEAPON_DMG', 2.0)
for _w in WEAPONS:
    _w['damage'] = round(_w['damage'] * WDMG, 1)
    for _k in ('poison', 'burn'):
        if _k in _w:
            _w[_k] = round(_w[_k] * WDMG, 1)


# ---------------------------------------------------------------- upgrades (passive, stack up to "max")
def upgrade(id, nl, en, rarity, stat, desc_nl, desc_en, max_=6):
    return {'id': id, 'name': nm(nl, en), 'rarity': rarity, 'cost': UP_COST[rarity], 'stat': stat, 'max': max_,
            'desc': nm(desc_nl, desc_en)}


UPGRADES = [
    upgrade('whetstone', 'Slijpsteen', 'Whetstone', 0, {'dmg': 0.10}, '+10% schade', '+10% damage'),
    upgrade('quickdraw', 'Snelle hand', 'Quick Hand', 0, {'aspd': 0.10}, '+10% aanvalssnelheid', '+10% attack speed'),
    upgrade('ironskin', 'IJzerhuid', 'Iron Skin', 0, {'armor': 2}, '+2 pantser', '+2 armor'),
    upgrade('heartymeal', 'Stevige maaltijd', 'Hearty Meal', 0, {'maxHp': 80, 'heal': 80}, '+80 leven, geneest 80', '+80 life, heals 80'),
    upgrade('bandage', 'Verband', 'Bandage', 0, {'regen': 1.0}, '+1 leven per seconde', '+1 life per second'),
    upgrade('purse', 'Geldbuidel', 'Coin Purse', 0, {'income': 1.0}, '+1 goud per seconde', '+1 gold per second'),
    upgrade('lucky', 'Geluksbrenger', 'Lucky Charm', 1, {'crit': 0.06}, '+6% kans op een kritieke treffer (x2,5)', '+6% chance for a critical hit (x2.5)'),
    upgrade('buckler', 'Rond schild', 'Buckler', 1, {'block': 3}, 'Elke klap doet 3 minder schade', 'Every hit does 3 less damage'),
    upgrade('thornsmail', 'Doornenpantser', 'Thorn Mail', 1, {'thorns': 8}, 'Aanvallers krijgen 8 schade terug', 'Attackers take 8 damage back'),
    upgrade('longsight', 'Verrekijker', 'Long Sight', 1, {'range': 0.12}, '+12% bereik', '+12% range'),
    upgrade('pact', 'Handelsverdrag', 'Trade Pact', 1, {'income': 2.5, 'roundGold': 40}, '+2,5 goud per seconde en +40 per ronde', '+2.5 gold per second and +40 per round'),
    upgrade('sigil', 'Buitzegel', 'Bounty Sigil', 1, {'bounty': 0.25}, '+25% goud per kill', '+25% gold per kill'),
    upgrade('plate', 'Onbreekbaar pantser', 'Unbreakable Plate', 2, {'armor': 7}, '+7 pantser', '+7 armor', 5),
    upgrade('decimation', 'Genadeslag', 'Decimation', 2, {'crit': 0.10, 'critMult': 0.5}, '+10% kritiek en +50% kritieke schade', '+10% crit and +50% crit damage', 4),
    upgrade('maw', 'Hongerige muil', 'Hungering Maw', 2, {'thorns': 18, 'thornsHeal': 3}, '+18 doornschade, geneest 3 per tegenslag', '+18 thorns damage, heals 3 per retaliation', 4),
    upgrade('medallion', 'Gouden medaillon', 'Golden Medallion', 2, {'bounty': 0.6}, '+60% goud per kill', '+60% gold per kill', 4),
    upgrade('phoenix', 'Feniksklauw', 'Phoenix Claw', 2, {'phoenix': 1}, 'Redt je van de dood en geneest je, daarna 90 s rust', 'Saves you from death and heals you, then rests for 90 s', 1),
    upgrade('energyshield', 'Energieschild', 'Energy Shield', 2, {'shield': 150}, '+150 schild dat terugkomt na 8 s zonder schade', '+150 shield that returns after 8 s without damage', 4),
    upgrade('banner', 'Krijgsbanier', 'War Banner', 3, {'dmg': 0.30, 'aspd': 0.12}, '+30% schade en +12% aanvalssnelheid', '+30% damage and +12% attack speed', 5),
    upgrade('urn', 'Urn van hebzucht', 'Urn of Greed', 3, {'income': 9.0}, '+9 goud per seconde', '+9 gold per second', 4),
    upgrade('timecrystal', 'Tijdkristal', 'Time Crystal', 3, {'aspd': 0.20, 'slowAll': 0.12}, '+20% aanvalssnelheid, vijanden 12% trager', '+20% attack speed, enemies 12% slower', 4),
    upgrade('ankh', 'Ankh van herrijzenis', 'Ankh of Rebirth', 3, {'ankh': 1}, 'Herrijst één keer met volledig leven', 'Rises once with full life', 1),
]


# ---------------------------------------------------------------- enemies
# cost = spawn points, from = minute they start to appear, weight = share when picking, pack = number per spawn
def enemy(id, nl, en, model, tint, hp, dmg, speed, bounty, cost, from_, weight, atk_cd=1.0, range_=0.35, radius=0.4,
          armor=0, pack=1, size=1.0, boss=False, wagon=False):
    return {'id': id, 'name': nm(nl, en), 'model': model, 'tint': tint, 'hp': hp, 'dmg': dmg, 'speed': speed,
            'bounty': bounty, 'cost': cost, 'from': from_, 'weight': weight, 'atkCd': atk_cd, 'range': range_,
            'radius': radius, 'armor': armor, 'pack': pack, 'size': size, 'boss': boss, 'wagon': wagon}


ENEMIES = [
    enemy('walker', 'Beenloper', 'Bone Walker', 'frozen_husk', '#9fc8e8', 14, 4, 1.7, 1, 1.0, 0.0, 10),
    enemy('archer', 'Beenboogschutter', 'Bone Archer', 'dusk_archer', '#b08ae8', 22, 6, 1.4, 3, 2.0, 1.0, 4, atk_cd=1.4, range_=5.0),
    enemy('crawler', 'Kruiper', 'Crawler', 'rime_runner', '#c8f0a0', 7, 2, 3.0, 1, 2.0, 1.5, 4, atk_cd=0.8, radius=0.3, pack=4),
    enemy('raider', 'Rover', 'Raider', 'tundra_brute', '#ffb080', 40, 9, 1.5, 3, 3.0, 2.0, 5, armor=1),
    enemy('cat', 'Schaduwkat', 'Shadow Cat', 'ice_stalker', '#8a7ad8', 25, 7, 2.8, 3, 2.5, 3.0, 3),
    enemy('golem', 'Schrootgolem', 'Scrap Golem', 'clockwork_brute', '#c0c8d8', 220, 25, 1.0, 15, 12.0, 5.0, 1.5, atk_cd=1.4, radius=0.6, armor=6, size=1.3),
    enemy('knight', 'Plunderaar', 'Marauder', 'frost_marshal', '#e06a6a', 400, 30, 1.3, 25, 18.0, 7.0, 1.0, atk_cd=1.2, radius=0.5, armor=10, size=1.2),
    enemy('wagon', 'Goudstier', 'Gold Bull', 'ice_skiff', '#ffd86a', 120, 0, 3.4, 80, 0.0, 99.0, 0, radius=0.5, armor=0, wagon=True),
    enemy('boss1', 'Vorstreus', 'Frost Giant', 'glacier_lord', '#7ab4ff', 1300, 40, 1.1, 400, 0.0, 99.0, 0, atk_cd=1.5, radius=0.9, armor=12, size=2.0, boss=True),
    enemy('boss2', 'Winterkoning', 'Winter King', 'ice_king', '#a8d8ff', 2200, 50, 1.1, 700, 0.0, 99.0, 0, atk_cd=1.5, radius=0.9, armor=18, size=2.2, boss=True),
    enemy('boss3', 'Oerbeer', 'Elder Bear', 'dire_bear', '#c8b8a8', 7000, 95, 1.0, 1100, 0.0, 99.0, 0, atk_cd=1.6, radius=1.0, armor=22, size=2.2, boss=True),
]

# bosses and gold bulls come on a timetable (seconds)
BOSS_TIMES = [(240, 'boss1'), (420, 'boss2'), (600, 'boss1'), (750, 'boss3'), (840, 'boss2')]
WAGON_FIRST = 60
WAGON_EVERY = 70


def build_rules():
    return {
        'id': 'survivor',
        'kind': 'survivor',
        'name': nm('Laatste toren', 'Last Tower'),
        'files': {'weapons': 'survivor/weapons.json', 'upgrades': 'survivor/upgrades.json', 'enemies': 'survivor/enemies.json'},
        'tickRate': 20,
        'winTime': int(_tune('WIN_TIME', 900)),
        'startGold': 120,
        'baseIncome': 3.0,
        'roundSeconds': 45,
        'shopSlots': 5,
        'rerollBase': 20,
        'rerollStep': 15,
        'maxWeapons': 6,
        'maxWeaponLevel': 5,
        'weaponLevelDamage': 0.4,      # per extra level
        'weaponLevelSpeed': 0.93,      # cooldown multiplier per extra level
        'starterWeapon': 'knives',
        'tower': {'hp': 500, 'armor': 2, 'regen': 1.0, 'radius': 0.9, 'critMult': 2.5, 'shieldDelay': 8.0, 'phoenixRest': 90.0},
        'arenaRadius': 13.0,
        'spawnRadius': 16.5,
        'maxEnemies': 120,
        'scale': {'hpPerMinute': _tune('HP_PER_MIN', 1.2), 'dmgPerMinute': _tune('DMG_PER_MIN', 1.08),
                  'bountyPerMinute': _tune('BOUNTY_PER_MIN', 1.05), 'lateHpAfter': 10, 'lateHpPerMinute': 1.05},
        'spawn': {'base': _tune('SPAWN_BASE', 0.8), 'perMinute': _tune('SPAWN_PER_MIN', 0.7)},
        'wagon': {'first': WAGON_FIRST, 'every': WAGON_EVERY},
        'bosses': [{'time': t, 'enemy': e} for t, e in BOSS_TIMES],
        'clear': {'cooldown': 120, 'startCooldown': 60, 'invuln': 1.0, 'heal': 0.25},
        # chance (percent) of common, uncommon, rare, epic in the shop, by minute
        'shopOdds': [
            {'from': 0, 'w': [70, 27, 3, 0]},
            {'from': 3, 'w': [50, 35, 14, 1]},
            {'from': 6, 'w': [35, 35, 24, 6]},
            {'from': 9, 'w': [25, 32, 30, 13]},
            {'from': 12, 'w': [15, 28, 36, 21]},
        ],
        'weaponShare': 0.5,
        'difficultyKind': 'strength',
        'difficulties': {'easy': 70, 'normal': 100, 'hard': 135, 'perfection': 180},
        'defaultDifficulty': 'normal',
    }


TEXTS = {
    'nl': {
        'mode.survivor': 'Laatste toren',
        'mode.survivor.desc': 'Eén toren die niet kan bewegen. Koop wapens en verbeteringen in de winkel en overleef 15 minuten tegen eindeloze hordes.',
        'menu.hint.survivor': '1 speler · 15 minuten · winkel met wapens en verbeteringen',
        'help.tip.survivor': 'Tip: de winkel ververst elke 45 s. Koop eerst een tweede wapen, daarna verbeteringen, en spaar niet te lang. Dubbele wapens worden sterker.',
        'menu.strength': '{0}%',
        'sv.round': 'Ronde {0}',
        'sv.time': '{0} / {1}',
        'sv.reroll': 'Ververs ({0})',
        'sv.clear': 'Wegvegen',
        'sv.clear_ready': 'Wegvegen!',
        'sv.owned': 'Je spullen',
        'sv.level': 'Niveau {0}',
        'sv.max': 'Max',
        'sv.free_slot': 'Wapenslots vol: je kunt alleen een wapen dat je al hebt verbeteren',
        'sv.sold_out': 'Gekocht',
        'sv.next_shop': 'Nieuwe winkel over {0} s',
        'sv.boss_warning': 'Eindbaas nadert!',
        'sv.wagon': 'Een goudstier! Pak hem voor extra goud',
        'sv.revived': 'Je toren staat weer op!',
        'sv.hp': 'Leven',
        'sv.shield': 'Schild',
        'msg.sv_gold': 'Te weinig goud',
        'msg.sv_buy': 'Koop ({0})',
        'msg.sv_full': 'Wapenslots vol',
        'msg.sv_maxed': 'Al op het hoogste niveau',
        'msg.sv_bought': 'Gekocht: {0}',
        'msg.sv_cleared': 'Alles weggeveegd!',
        'msg.sv_cooldown': 'Nog even wachten ({0} s)',
        'end.sv_won': 'Overleefd!',
        'end.sv_lost': 'Je toren is gevallen',
        'end.sv_stats': 'Overleefd: {0} · {1} kills · {2} wapens',
        'rarity.common': 'Gewoon',
        'rarity.uncommon': 'Ongewoon',
        'rarity.rare': 'Zeldzaam',
        'rarity.epic': 'Episch',
        'wk.shoot': 'Schiet op de dichtstbijzijnde vijand',
        'wk.projectile': 'Schiet op de dichtstbijzijnde vijand. Doorboort {0} extra vijanden',
        'wk.orbit': '{0} kling(en) draaien rond de toren en raken alles op hun pad',
        'wk.aura': 'Beschadigt alle vijanden binnen {0} tegels',
        'wk.artillery': 'Gooit een bom met {0} tegels bereik op een vijand: schade in een kring',
        'wk.chain': 'Bliksem springt over {0} vijanden',
        'wk.mine': 'Legt mijnen die ontploffen als een vijand ze raakt (max. {0})',
        'wk.glaive': 'Een werpschijf vliegt heen en terug en raakt alles onderweg',
        'wk.strike': 'Raakt {0} willekeurige vijanden binnen bereik',
        'wk.slow': 'Vertraagt {0}%',
        'wk.poison': 'Gif: {0} schade/s',
        'wk.burn': 'Brandt: {0} schade/s',
        'wk.heal': 'Geneest de toren {0} per treffer',
        'wk.phys': 'Fysiek (pantser telt)',
        'wk.magic': 'Magisch (negeert pantser)',
        'sv.dmg': 'Schade {0}',
        'sv.cd': 'Interval {0} s',
        'sv.rng': 'Bereik {0}',
    },
    'en': {
        'mode.survivor': 'Last Tower',
        'mode.survivor.desc': 'One tower that cannot move. Buy weapons and upgrades in the shop and survive 15 minutes against endless hordes.',
        'menu.hint.survivor': '1 player · 15 minutes · a shop with weapons and upgrades',
        'help.tip.survivor': 'Tip: the shop refreshes every 45 s. Buy a second weapon first, then upgrades, and do not save up for too long. Duplicate weapons get stronger.',
        'menu.strength': '{0}%',
        'sv.round': 'Round {0}',
        'sv.time': '{0} / {1}',
        'sv.reroll': 'Reroll ({0})',
        'sv.clear': 'Clear',
        'sv.clear_ready': 'Clear!',
        'sv.owned': 'Your gear',
        'sv.level': 'Level {0}',
        'sv.max': 'Max',
        'sv.free_slot': 'Weapon slots full: you can only upgrade a weapon you already have',
        'sv.sold_out': 'Bought',
        'sv.next_shop': 'New shop in {0} s',
        'sv.boss_warning': 'A boss is coming!',
        'sv.wagon': 'A gold bull! Catch it for extra gold',
        'sv.revived': 'Your tower rises again!',
        'sv.hp': 'Life',
        'sv.shield': 'Shield',
        'msg.sv_gold': 'Not enough gold',
        'msg.sv_buy': 'Buy ({0})',
        'msg.sv_full': 'Weapon slots full',
        'msg.sv_maxed': 'Already at the highest level',
        'msg.sv_bought': 'Bought: {0}',
        'msg.sv_cleared': 'Everything swept away!',
        'msg.sv_cooldown': 'Wait a moment ({0} s)',
        'end.sv_won': 'Survived!',
        'end.sv_lost': 'Your tower has fallen',
        'end.sv_stats': 'Survived: {0} · {1} kills · {2} weapons',
        'rarity.common': 'Common',
        'rarity.uncommon': 'Uncommon',
        'rarity.rare': 'Rare',
        'rarity.epic': 'Epic',
        'wk.shoot': 'Shoots the nearest enemy',
        'wk.projectile': 'Shoots the nearest enemy. Pierces {0} extra enemies',
        'wk.orbit': '{0} blade(s) circle the tower and hit everything in their way',
        'wk.aura': 'Damages every enemy within {0} tiles',
        'wk.artillery': 'Lobs a bomb up to {0} tiles at an enemy: damage in a circle',
        'wk.chain': 'Lightning jumps across {0} enemies',
        'wk.mine': 'Lays mines that explode when an enemy touches them (max. {0})',
        'wk.glaive': 'A disc flies out and back and hits everything on the way',
        'wk.strike': 'Hits {0} random enemies in range',
        'wk.slow': 'Slows {0}%',
        'wk.poison': 'Poison: {0} damage/s',
        'wk.burn': 'Burns: {0} damage/s',
        'wk.heal': 'Heals the tower {0} per hit',
        'wk.phys': 'Physical (armor counts)',
        'wk.magic': 'Magic (ignores armor)',
        'sv.dmg': 'Damage {0}',
        'sv.cd': 'Interval {0} s',
        'sv.rng': 'Range {0}',
    },
}


def write(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        json.dump(obj, f, indent=1, ensure_ascii=False)
        f.write('\n')


def main():
    write(os.path.join(ROOT, 'survivor', 'weapons.json'), {'rarities': RARITIES, 'weapons': {w['id']: w for w in WEAPONS}})
    write(os.path.join(ROOT, 'survivor', 'upgrades.json'), {'upgrades': {u['id']: u for u in UPGRADES}})
    write(os.path.join(ROOT, 'survivor', 'enemies.json'), {'enemies': {e['id']: e for e in ENEMIES}})
    write(os.path.join(ROOT, 'rules_survivor.json'), build_rules())
    if os.environ.get('GEN_OUT'):
        print('weapons %d, upgrades %d, enemies %d (sweep output, no texts)' % (len(WEAPONS), len(UPGRADES), len(ENEMIES)))
        return
    for lang, texts in TEXTS.items():
        p = os.path.join(ROOT, 'i18n', lang + '.json')
        with open(p) as f:
            table = json.load(f)
        table.update(texts)
        write(p, table)
    print('weapons %d, upgrades %d, enemies %d' % (len(WEAPONS), len(UPGRADES), len(ENEMIES)))


if __name__ == '__main__':
    main()
