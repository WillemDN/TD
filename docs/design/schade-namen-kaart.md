# Ontwerp: schademodel, namen en kaart (eerste speelbare versie)

Dit document beschrijft de keuzes van fase 1 voor de modus **Klassiek**. De getallen komen uit [`../research/wintermaul-v13-resolved.md`](../research/wintermaul-v13-resolved.md), de namen en effectwaarden zijn onze eigen keuzes. De data staat in `game/data/` en wordt gegenereerd door `tools/import_wintermaul.py` (met `tools/import_overlay.py`) en `tools/gen_map.py`. **Dit bestand wordt gegenereerd** door `tools/gen_design_doc.py`, pas de tools aan en niet dit bestand.

## 1. Schademodel

`schade = worp × matrix[aanvalstype][armortype] × (1 − armorreductie)`, met `armorreductie = 0,06·A / (1 + 0,06·A)` (negatieve armor versterkt de schade). Gif- en percentage-schade negeren armor.

**Eigen namen, WC3-waarden.** De creeps en torens zijn in het origineel afgestemd op de WC3-tabel (zie dataverslag §6). Daarom zijn de vermenigvuldigers overgenomen. Alleen de namen zijn nieuw:

| Aanvalstype \ Armortype | Licht / Light | Middel / Medium | Zwaar / Heavy | Versterkt / Fortified | Goddelijk / Divine |
|---|---:|---:|---:|---:|---:|
| Standaard / Standard | 100% | 150% | 100% | 70% | 10% |
| Doordringend / Piercing | 200% | 75% | 100% | 35% | 10% |
| Verpletterend / Crushing | 100% | 50% | 100% | 150% | 10% |
| Chaos / Chaos | 100% | 100% | 100% | 100% | 100% |

Herkomst van de namen: Standard = WC3 *normal*, Piercing = WC3 *pierce*, Crushing = WC3 *siege*, Chaos = WC3 *chaos*; Light = *light/small*, Medium = *medium*, Heavy = *heavy/large*, Fortified = *fortified*, Divine = *divine*. *Goddelijk* neemt van niet-chaos-aanvallen slechts 10%, dus alleen chaos-torens (Gif, Kristal, Poollichtkanon) kunnen bonuslevel 35 echt aan.

Het armortype van de creeps staat in de HUD ("Pantser Licht 0") en de torenkaart toont de vermenigvuldiger tegen het huidige level.

## 2. Elementen en torens (eigen namen)

Volgorde = tier (duurder is sterker). De kolom *Bron* verwijst naar de eenheid-id in de originele map; de originele namen staan in het dataverslag.

### Vuur / Fire

| Tier | NL | EN | Goud | Aanvalstype | Effecten | Bron |
|---:|---|---|---:|---|---|---|
| 1 | Gloedpost | Ember Post | 10 | Piercing | - | v13:hC02 |
| 2 | Sintelspinner | Cinder Spinner | 45 | Piercing | - | v13:oC19 |
| 3 | Komeettoren | Comet Tower | 95 | Piercing | - | v13:oC58 |
| 4 | Magmasmederij | Magma Forge | 200 | Piercing | - | v13:oC64 |
| 5 | Hellevuurspits | Inferno Spire | 350 | Piercing | - | v13:oC65 |

### IJs / Ice

| Tier | NL | EN | Goud | Aanvalstype | Effecten | Bron |
|---:|---|---|---:|---|---|---|
| 1 | IJsscherf | Frost Shard | 10 | Standard | slow | v13:oC24 |
| 2 | Sneeuwkanon | Snow Cannon | 40 | Standard | slow | v13:hC34 |
| 3 | Sneeuwstormtoren | Blizzard Spire | 100 | Standard | slow | v13:oC37 |
| 4 | Gletsjerspuit | Glacier Sprayer | 200 | Standard | root | v13:oC61 |
| 5 | IJsnovatoren | Frost Nova Spire | 350 | Standard | slow | v13:oC62 |

### Techniek / Tech

| Tier | NL | EN | Goud | Aanvalstype | Effecten | Bron |
|---:|---|---|---:|---|---|---|
| 1 | Kruisboogpost | Crossbow Post | 7 | Piercing | - | v13:hC66 |
| 2 | Scherpschuttersnest | Marksman Nest | 30 | Piercing | - | v13:hC08 |
| 3 | Raketlanceerder | Rocket Rack | 80 | Piercing | - | v13:hC54 |
| 4 | Pulskanon | Pulse Cannon | 170 | Piercing | bonus_damage | v13:hC55 |
| 5 | Kernkopsilo | Warhead Silo | 310 | Piercing | - | v13:hC59 |

### Bliksem / Lightning

| Tier | NL | EN | Goud | Aanvalstype | Effecten | Bron |
|---:|---|---|---:|---|---|---|
| 1 | Vonkpaal | Spark Post | 10 | Standard | - | v13:hC11 |
| 2 | Stormspoel | Storm Coil | 40 | Standard | chain | v13:oC18 |
| 3 | Boogwever | Arc Weaver | 100 | Standard | chain | v13:hC36 |
| 4 | Bliksemafleider | Lightning Rod | 200 | Standard | percent_hp | v13:oC60 |
| 5 | Dynamo | Dynamo | 350 | Standard | - | v13:oC68 |

### Steen / Stone

| Tier | NL | EN | Goud | Aanvalstype | Effecten | Bron |
|---:|---|---|---:|---|---|---|
| 1 | Keienslinger | Pebble Slinger | 10 | Crushing | crit | v13:oC14 |
| 2 | Rotsgooier | Boulder Thrower | 40 | Crushing | crit | v13:oC35 |
| 3 | Granietballista | Granite Ballista | 100 | Crushing | crit | v13:hC53 |
| 4 | Runenwever | Rune Weaver | 200 | Crushing | crit, armor_reduce | v13:oC26 |
| 5 | Versteneraar | Petrifier | 350 | Crushing | set_hp | v13:oC67 |

### Gif / Poison

| Tier | NL | EN | Goud | Aanvalstype | Effecten | Bron |
|---:|---|---|---:|---|---|---|
| 1 | Gifpunt | Venom Spike | 15 | Chaos | poison | v13:hC21 |
| 2 | Toxinetoren | Toxin Spire | 60 | Chaos | poison | v13:hC27 |
| 3 | Slijkmortier | Sludge Mortar | 120 | Chaos | poison | v13:oC56 |
| 4 | Pesttotem | Plague Totem | 230 | Chaos | poison | v13:oC73 |
| 5 | Miasmaschacht | Miasma Vent | 390 | Chaos | poison | v13:oC74 |

### Natuur / Nature

| Tier | NL | EN | Goud | Aanvalstype | Effecten | Bron |
|---:|---|---|---:|---|---|---|
| 1 | Doornenpoel | Thorn Pool | 10 | Piercing | - | v13:emow |
| 2 | Bosbeschermer | Grove Guardian | 40 | Crushing | - | v13:hC80 |
| 3 | Sporenpeul | Spore Pod | 100 | Crushing | - | v13:hC82 |
| 4 | Aardbevingswortel | Quake Root | 200 | Crushing | - | v13:hC84 |
| 5 | Hartboom | Heartwood | 350 | Crushing | - | v13:eC83 |

### Schaduw / Shadow

| Tier | NL | EN | Goud | Aanvalstype | Effecten | Bron |
|---:|---|---|---:|---|---|---|
| 1 | Beenderspuwer | Bone Spitter | 15 | Standard | - | v13:hC86 |
| 2 | Grafwachter | Grave Watcher | 25 | Piercing | - | v13:hC90 |
| 3 | Draakskelet | Wyrm Skeleton | 150 | Chaos | armor_reduce | v13:hC88 |
| 4 | Noodlotswachter | Doom Sentinel | 200 | Chaos | crit, root, armor_reduce | v13:hC89 |

### Kristal / Crystal

| Tier | NL | EN | Goud | Aanvalstype | Effecten | Bron |
|---:|---|---|---:|---|---|---|
| 1 | Kristalscherf | Crystal Shard | 15 | Chaos | - | v13:hgtw |
| 2 | Prismastraler | Prism Blaster | 65 | Chaos | - | v13:hctw |
| 3 | Spiegelprisma | Mirror Prism | 130 | Chaos | bounce | v13:nfrm |
| 4 | Scherfstorm | Shatterstorm | 240 | Chaos | crit | v13:hwtw |
| 5 | Vrieslens | Frozen Lens | 270 | Chaos | slow | v13:hhou |
| 6 | Ontbindingsobelisk | Dissolution Obelisk | 550 | Chaos | - | v13:owtw |

### Ultiem

**Poollichtkanon / Aurora Cannon**: 750 goud + 1 hout, bouwtijd 120 s, 500 schade, chaos, bereik over de hele kaart, effecten: crit, slow, poison.

**Nog niet in de eerste versie:** het "altaar" van Schaduw (bron `nC87`) dat in het origineel een zware vliegende eenheid traint.

## 3. Effecten en hun waarden

Het origineel bewaart de effectwaarden in abilities (`war3map.w3a`). Die zijn nog niet uitgelezen, dus de waarden hieronder zijn **eigen, voorlopige keuzes** (in `tools/import_overlay.py`). De balans-run volgt in fase 7.

| Effect | Werking | Waarden |
|---|---|---|
| slow | vertraagt (sterkste wint, niet stapelend) | 25-40% voor 2-2,5 s |
| poison | slow + schade per seconde (pure schade) | 20-25% slow, 15% van de gemiddelde treffer per s, 3 s |
| crit | kans op een vermenigvuldigde treffer | 10-20%, 2x |
| chain | bliksemketen naar nabije creeps | 3-4 extra doelen, 80-85% per stap |
| bounce | kaatst | 3 doelen, 75% per stap |
| armor_reduce | verlaagt armor tijdelijk | -3 tot -5 voor 5 s |
| percent_hp | haalt een deel van het huidige leven af | 25%, niet op bosses |
| set_hp | zet het leven op een vast getal | 10, niet op bosses |
| root | houdt vast | Gletsjerspuit permanent, Noodlotswachter 10% kans 2 s, niet op bosses |
| bonus_damage | extra schade per treffer | Pulskanon +500 |

## 4. Creeps en waves (eigen namen)

Getallen uit het origineel (HP, armor, snelheid, bounty). Aantallen per spawnpunt (×6 spawnpunten, geschaald naar het aantal spelers, zie §5).

| Level | NL | EN | HP | Armor | Armortype | Lucht | Per spawn | Opmerking |
|---:|---|---|---:|---:|---|---|---:|---|
| 1 | Sneeuwverkenner | Snow Scout | 15 | 0 | Light |  | 20 |  |
| 2 | IJsknutselaar | Frost Tinker | 60 | 0 | Medium |  | 20 |  |
| 3 | Schemerboogschutter | Dusk Archer | 115 | 2 | Light |  | 20 |  |
| 4 | Toendrabrute | Tundra Brute | 150 | 2 | Heavy |  | 20 |  |
| 5 | IJsvleermuis | Frost Bat | 135 | 1 | Heavy | ja | 15 |  |
| 6 | IJsspeurder | Ice Stalker | 225 | 3 | Light |  | 20 |  |
| 7 | Rijmspin | Rime Spider | 260 | 4 | Medium |  | 20 |  |
| 8 | Gletsjertrol | Glacier Troll | 300 | 5 | Medium |  | 20 |  |
| 9 | Wolvenrijder | Wolf Raider | 345 | 7 | Heavy |  | 20 |  |
| 10 | IJsmaarschalk | Frost Marshal | 15000 | 10 | Medium |  | 1 | eindbaas |
| 11 | IJsbizon | Ice Bison | 375 | 7 | Fortified |  | 20 |  |
| 12 | Radertuigbrute | Clockwork Brute | 500 | 8 | Heavy |  | 20 |  |
| 13 | IJshagedis | Frost Lizard | 625 | 10 | Medium |  | 20 |  |
| 14 | Schaduwkever | Shadow Beetle | 875 | 10 | Light |  | 20 |  |
| 15 | IJsvalk | Ice Hawk | 675 | 12 | Heavy | ja | 15 |  |
| 16 | Scherfgolem | Shard Golem | 1100 | 12 | Heavy |  | 20 |  |
| 17 | Winterspook | Winter Wisp | 1300 | 14 | Light |  | 20 |  |
| 18 | Belegeringsneushoorn | Siege Rhino | 1300 | 10 | Fortified |  | 20 |  |
| 19 | Bevroren lijk | Frozen Husk | 1700 | 10 | Heavy |  | 20 |  |
| 20 | Gletsjerheer | Glacier Lord | 30000 | 15 | Medium |  | 1 | eindbaas |
| 21 | Totemdrager | Totem Bearer | 2000 | 15 | Heavy |  | 20 |  |
| 22 | Vervloekte ruiter | Cursed Rider | 2300 | 15 | Heavy |  | 20 |  |
| 23 | Prismamagiër | Prism Mage | 2500 | 16 | Light |  | 20 |  |
| 24 | IJsinferno | Frost Infernal | 2900 | 17 | Heavy |  | 20 |  |
| 25 | Sneeuwstormgier | Blizzard Vulture | 2250 | 20 | Heavy | ja | 15 |  |
| 26 | Schrikyeti | Dire Yeti | 3400 | 18 | Medium |  | 20 |  |
| 27 | Bezeten jager | Haunted Hunter | 4000 | 18 | Medium |  | 20 |  |
| 28 | Krijgsheer | Warlord | 4500 | 19 | Medium |  | 20 |  |
| 29 | Oerkraai | Elder Crow | 3750 | 19 | Heavy | ja | 15 |  |
| 30 | De IJskoning | The Ice King | 85000 | 20 | Medium |  | 1 | **laatste eindbaas: bereikt hij het schip, dan is het direct verloren** |
| 31 | Yeti-verkenner | Yeti Scout | 5800 | 0 | Medium |  | 20 | bonus, geen levensverlies |
| 32 | Sneeuwgolem | Snow Golem | 6500 | 5 | Medium |  | 20 | bonus, geen levensverlies |
| 33 | IJsschim | Ice Wraith | 7000 | 15 | Medium |  | 20 | bonus, geen levensverlies |
| 34 | IJsreus | Frost Giant | 8000 | 20 | Medium |  | 20 | bonus, geen levensverlies |
| 35 | Noorderlichtgeest | Aurora Sprite | 1000 | 20 | Divine |  | 50 | bonus, geen levensverlies |

## 5. Schaling naar het aantal spelers

Het origineel is voor 9 spelers: 6 spawnpunten × 20 creeps = 120 creeps. Wij schalen het aantal lineair (`6 × n × spelers / 9`, minimaal 1): solo is dat 13 creeps, een eindbaas komt 1 keer.

**Voorlopige spelersboost** (`playerBoost` in `rules_classic.json`): omdat een solospeler met 30 goud ruimtelijk te weinig kan mazen, krijgen kleine teams extra middelen:

| Spelers | Startgoud | Levelbonus | Bounty |
|---:|---:|---:|---:|
| 1 | ×3 | ×1,5 | ×1,5 |
| 2 | ×2 | ×1,3 | ×1,3 |
| 3 | ×1,5 | ×1,15 | ×1,15 |
| 4 | ×1,25 | ×1 | ×1 |

Deze getallen zijn een gok en moeten met de balans-sims (en jouw speeltests) worden afgesteld.

## 6. Kaart "Vrieslijn" / "Frostline"

Gegenereerd door `tools/gen_map.py` naar `game/data/maps/frostline.json`. Rooster van 96×60 cellen (48×30 tegels, een cel is een halve tegel, een toren is 2×2 cellen).

```
 spawns  3 bouwlanes (18 tegels)        strook   gedeeld bouwveld          schip
  ●●   ┌──────────────────────┐
       │ lane 1 (rijen 4-17)  │──┐
  ●●   └──────────────────────┘  │
  ●●   ┌──────────────────────┐  ├─▶ ░░ ─▶ ┌───────────────────┐ ─▶ ⛵
       │ lane 2 (rijen 22-35) │──┤         │ gedeeld veld      │
  ●●   └──────────────────────┘  │         │ 15 x 18 tegels    │
  ●●   ┌──────────────────────┐  │         └───────────────────┘
       │ lane 3 (rijen 40-53) │──┘
  ●●   └──────────────────────┘
```

- 6 spawnpunten (2 per lane) links, het schip rechts in het midden
- alle lanes komen samen in een gedeeld bouwveld voor het schip, zodat één verdediging alle creeps raakt (belangrijk voor solo)
- grond- en hover-creeps volgen een **flow field** (8 richtingen, geen hoeken afsnijden) naar het schip. Lucht vliegt in een rechte lijn van spawn naar schip
- **anti-block:** een plaatsing wordt geweigerd als een spawn of een creep op de grond het schip niet meer kan bereiken, of als er een grond-creep in de footprint staat
- niet-bebouwbaar: spawnzones, verzamelstrook, uitgang en schip
