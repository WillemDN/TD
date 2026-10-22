"""Hand-authored design layer on top of the extracted Wintermaul v13 numbers.

The numbers (cost, damage, range, hp, ...) come from docs/research/data/wintermaul-v13-resolved.json. This file adds what
the map does not hold as plain data: our own ids and names (NL + EN), element colours, and the parameters of the special
effects (the map stores those in abilities; we tune them ourselves). Nothing here is copied from the original map text.
"""


def n(nl, en):
    return {"nl": nl, "en": en}


ELEMENTS = [
    # id, builder unit in the map, colour, names
    ("fire", "nC03", "#e8622c", n("Vuur", "Fire")),
    ("ice", "oC25", "#6fd0ff", n("IJs", "Ice")),
    ("tech", "hC07", "#9aa7b4", n("Techniek", "Tech")),
    ("electric", "eC10", "#f2e13c", n("Bliksem", "Lightning")),
    ("stone", "uC13", "#a07a52", n("Steen", "Stone")),
    ("poison", "oC22", "#7ccf3a", n("Gif", "Poison")),
    ("nature", "efon", "#3f9a4f", n("Natuur", "Nature")),
    ("shadow", "uC81", "#8d5fc4", n("Schaduw", "Shadow")),
    ("crystal", "uC98", "#ff82d4", n("Kristal", "Crystal")),
]

# (map unit id, our id, element, tier, name, effects, overrides)
# Effect kinds: slow, poison, crit, chain, bounce, armor_reduce, percent_hp, set_hp, root, bonus_damage
SLOW = lambda amount, duration=2.0: {"kind": "slow", "amount": amount, "duration": duration}
CRIT = lambda chance=0.15, mult=2.0: {"kind": "crit", "chance": chance, "multiplier": mult}
POISON = lambda slow=0.2, dps_factor=0.15, duration=3.0: {
    "kind": "poison", "slow": slow, "dpsFactor": dps_factor, "duration": duration}

TOWERS = [
    ("hC02", "ember_post", "fire", 1, n("Gloedpost", "Ember Post"), [], {}),
    ("oC19", "cinder_spinner", "fire", 2, n("Sintelspinner", "Cinder Spinner"), [], {}),
    ("oC58", "comet_tower", "fire", 3, n("Komeettoren", "Comet Tower"), [], {}),
    ("oC64", "magma_forge", "fire", 4, n("Magmasmederij", "Magma Forge"), [], {}),
    ("oC65", "inferno_spire", "fire", 5, n("Hellevuurspits", "Inferno Spire"), [], {}),

    ("oC24", "frost_shard", "ice", 1, n("IJsscherf", "Frost Shard"), [SLOW(0.25)], {}),
    ("hC34", "snow_cannon", "ice", 2, n("Sneeuwkanon", "Snow Cannon"), [SLOW(0.30)], {}),
    ("oC37", "blizzard_spire", "ice", 3, n("Sneeuwstormtoren", "Blizzard Spire"), [SLOW(0.35)], {}),
    ("oC61", "glacier_sprayer", "ice", 4, n("Gletsjerspuit", "Glacier Sprayer"),
     [{"kind": "root", "duration": 9999.0, "bossImmune": True}], {}),
    ("oC62", "frost_nova_spire", "ice", 5, n("IJsnovatoren", "Frost Nova Spire"), [SLOW(0.40, 2.5)], {}),

    ("hC66", "crossbow_post", "tech", 1, n("Kruisboogpost", "Crossbow Post"), [], {}),
    ("hC08", "marksman_nest", "tech", 2, n("Scherpschuttersnest", "Marksman Nest"), [], {}),
    ("hC54", "rocket_rack", "tech", 3, n("Raketlanceerder", "Rocket Rack"), [], {"targets": ["ground"]}),
    ("hC55", "pulse_cannon", "tech", 4, n("Pulskanon", "Pulse Cannon"),
     [{"kind": "bonus_damage", "amount": 500}], {}),
    ("hC59", "warhead_silo", "tech", 5, n("Kernkopsilo", "Warhead Silo"), [], {}),

    ("hC11", "spark_post", "electric", 1, n("Vonkpaal", "Spark Post"), [], {}),
    ("oC18", "storm_coil", "electric", 2, n("Stormspoel", "Storm Coil"),
     [{"kind": "chain", "targets": 3, "falloff": 0.8, "range": 3.0}], {}),
    ("hC36", "arc_weaver", "electric", 3, n("Boogwever", "Arc Weaver"),
     [{"kind": "chain", "targets": 4, "falloff": 0.85, "range": 3.5, "damage": 90}], {}),
    ("oC60", "lightning_rod", "electric", 4, n("Bliksemafleider", "Lightning Rod"),
     [{"kind": "percent_hp", "percent": 0.25, "bossImmune": True}], {}),
    ("oC68", "dynamo", "electric", 5, n("Dynamo", "Dynamo"), [], {}),

    ("oC14", "pebble_slinger", "stone", 1, n("Keienslinger", "Pebble Slinger"), [CRIT(0.2)], {}),
    ("oC35", "boulder_thrower", "stone", 2, n("Rotsgooier", "Boulder Thrower"), [CRIT(0.2)], {}),
    ("hC53", "granite_ballista", "stone", 3, n("Granietballista", "Granite Ballista"), [CRIT(0.2)], {}),
    ("oC26", "rune_weaver", "stone", 4, n("Runenwever", "Rune Weaver"),
     [CRIT(0.2), {"kind": "armor_reduce", "amount": 5, "duration": 5.0}], {}),
    ("oC67", "petrifier", "stone", 5, n("Versteneraar", "Petrifier"),
     [{"kind": "set_hp", "hp": 10, "bossImmune": True}], {}),

    ("hC21", "venom_spike", "poison", 1, n("Gifpunt", "Venom Spike"), [POISON()], {}),
    ("hC27", "toxin_spire", "poison", 2, n("Toxinetoren", "Toxin Spire"), [POISON()], {}),
    ("oC56", "sludge_mortar", "poison", 3, n("Slijkmortier", "Sludge Mortar"), [POISON()],
     {"targets": ["ground"]}),
    ("oC73", "plague_totem", "poison", 4, n("Pesttotem", "Plague Totem"), [POISON()], {}),
    ("oC74", "miasma_vent", "poison", 5, n("Miasmaschacht", "Miasma Vent"), [POISON(0.25)], {}),

    ("emow", "thorn_pool", "nature", 1, n("Doornenpoel", "Thorn Pool"), [], {}),
    ("hC80", "grove_guardian", "nature", 2, n("Bosbeschermer", "Grove Guardian"), [], {}),
    ("hC82", "spore_pod", "nature", 3, n("Sporenpeul", "Spore Pod"), [], {}),
    ("hC84", "quake_root", "nature", 4, n("Aardbevingswortel", "Quake Root"), [], {}),
    ("eC83", "heartwood", "nature", 5, n("Hartboom", "Heartwood"), [], {}),

    ("hC86", "bone_spitter", "shadow", 1, n("Beenderspuwer", "Bone Spitter"), [], {}),
    ("hC90", "grave_watcher", "shadow", 2, n("Grafwachter", "Grave Watcher"), [], {}),
    ("hC88", "wyrm_skeleton", "shadow", 3, n("Draakskelet", "Wyrm Skeleton"),
     [{"kind": "armor_reduce", "amount": 4, "duration": 5.0}], {}),
    ("hC89", "doom_sentinel", "shadow", 4, n("Noodlotswachter", "Doom Sentinel"),
     [CRIT(0.15), {"kind": "root", "chance": 0.1, "duration": 2.0, "bossImmune": True},
      {"kind": "armor_reduce", "amount": 3, "duration": 5.0}], {}),

    ("hgtw", "crystal_shard", "crystal", 1, n("Kristalscherf", "Crystal Shard"), [], {}),
    ("hctw", "prism_blaster", "crystal", 2, n("Prismastraler", "Prism Blaster"), [], {}),
    ("nfrm", "mirror_prism", "crystal", 3, n("Spiegelprisma", "Mirror Prism"),
     [{"kind": "bounce", "targets": 3, "falloff": 0.75, "range": 4.0}], {}),
    ("hwtw", "shatterstorm", "crystal", 4, n("Scherfstorm", "Shatterstorm"), [CRIT(0.1)], {}),
    ("hhou", "frozen_lens", "crystal", 5, n("Vrieslens", "Frozen Lens"), [SLOW(0.35, 2.5)], {}),
    ("owtw", "dissolution_obelisk", "crystal", 6, n("Ontbindingsobelisk", "Dissolution Obelisk"), [], {}),
]

ULTIMATE = ("hC63", "aurora_cannon", "ultimate", 1, n("Poollichtkanon", "Aurora Cannon"),
            [CRIT(0.15), SLOW(0.30), POISON(0.2, 0.1)], {})

# level -> (map unit id, our id, name). Level numbers match the original wave order
CREEPS = [
    (1, "ushd", "snow_scout", n("Sneeuwverkenner", "Snow Scout")),
    (2, "hC04", "frost_tinker", n("IJsknutselaar", "Frost Tinker")),
    (3, "eC05", "dusk_archer", n("Schemerboogschutter", "Dusk Archer")),
    (4, "hC16", "tundra_brute", n("Toendrabrute", "Tundra Brute")),
    (5, "nC17", "frost_whelp", n("IJswelp", "Frost Whelp")),
    (6, "uC28", "ice_stalker", n("IJsspeurder", "Ice Stalker")),
    (7, "nC29", "rime_runner", n("Rijmloper", "Rime Runner")),
    (8, "nC30", "glacier_troll", n("Gletsjertrol", "Glacier Troll")),
    (9, "oC31", "wolf_raider", n("Wolvenrijder", "Wolf Raider")),
    (10, "uC32", "frost_marshal", n("IJsmaarschalk", "Frost Marshal")),
    (11, "nC33", "ice_skiff", n("IJsglijder", "Ice Skiff")),
    (12, "eC38", "clockwork_brute", n("Radertuigbrute", "Clockwork Brute")),
    (13, "nC39", "frost_lizard", n("IJshagedis", "Frost Lizard")),
    (14, "nC40", "shadow_imp", n("Schaduwduiveltje", "Shadow Imp")),
    (15, "nC41", "frost_drake", n("IJsdraak", "Frost Drake")),
    (16, "nC42", "shard_golem", n("Scherfgolem", "Shard Golem")),
    (17, "uC43", "winter_wisp", n("Winterspook", "Winter Wisp")),
    (18, "hC44", "siege_sled", n("Belegeringsslee", "Siege Sled")),
    (19, "uC45", "frozen_husk", n("Bevroren lijk", "Frozen Husk")),
    (20, "nC46", "glacier_lord", n("Gletsjerheer", "Glacier Lord")),
    (21, "oC47", "totem_bearer", n("Totemdrager", "Totem Bearer")),
    (22, "hC48", "cursed_rider", n("Vervloekte ruiter", "Cursed Rider")),
    (23, "nC49", "prism_mage", n("Prismamagiër", "Prism Mage")),
    (24, "nC50", "frost_infernal", n("IJsinferno", "Frost Infernal")),
    (25, "nC51", "blizzard_dragon", n("Sneeuwstormdraak", "Blizzard Dragon")),
    (26, "nC69", "dire_bear", n("Schrikbeer", "Dire Bear")),
    (27, "eC52", "haunted_hunter", n("Bezeten jager", "Haunted Hunter")),
    (28, "oC70", "warlord", n("Krijgsheer", "Warlord")),
    (29, "uC71", "elder_wyrm", n("Oerdraak", "Elder Wyrm")),
    (30, "uC72", "ice_king", n("De IJskoning", "The Ice King")),
    (31, "hC75", "yeti_scout", n("Yeti-verkenner", "Yeti Scout")),
    (32, "hC76", "snow_golem", n("Sneeuwgolem", "Snow Golem")),
    (33, "hC77", "ice_wraith", n("IJsschim", "Ice Wraith")),
    (34, "zC78", "frost_giant", n("IJsreus", "Frost Giant")),
    (35, "hC79", "aurora_sprite", n("Noorderlichtgeest", "Aurora Sprite")),
]
BOSS_LEVELS = (10, 20, 30)
BONUS_LEVELS = (31, 32, 33, 34, 35)
