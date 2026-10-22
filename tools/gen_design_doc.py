# -*- coding: utf-8 -*-
"""Generate docs/design/schade-namen-kaart.md from the game data, so the design doc never drifts from the JSON.

Run: python3 -I tools/gen_design_doc.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load(p):
    return json.load(open(os.path.join(ROOT, p), encoding='utf-8'))


t = load('game/data/towers.json')
c = load('game/data/creeps.json')['creeps']
w = load('game/data/waves_classic.json')['waves']
m = load('game/data/matrix.json')

AT = {'normal': ('Standaard', 'Standard'), 'pierce': ('Doordringend', 'Piercing'),
      'siege': ('Verpletterend', 'Crushing'), 'chaos': ('Chaos', 'Chaos')}
AR = {'small': ('Licht', 'Light'), 'medium': ('Middel', 'Medium'), 'large': ('Zwaar', 'Heavy'),
      'fort': ('Versterkt', 'Fortified'), 'divine': ('Goddelijk', 'Divine')}
ORIG_AR = {'small': 'light/small', 'medium': 'medium', 'large': 'heavy/large', 'fort': 'fortified', 'divine': 'divine'}

d = "# Ontwerp: schademodel, namen en kaart (eerste speelbare versie)\n\n"
d += ("Dit document beschrijft de keuzes van fase 1 voor de modus **Klassiek**. De getallen komen uit "
      "[`../research/wintermaul-v13-resolved.md`](../research/wintermaul-v13-resolved.md), de namen en effectwaarden zijn "
      "onze eigen keuzes. De data staat in `game/data/` en wordt gegenereerd door `tools/import_wintermaul.py` "
      "(met `tools/import_overlay.py`) en `tools/gen_map.py`. **Dit bestand wordt gegenereerd** door "
      "`tools/gen_design_doc.py`, pas de tools aan en niet dit bestand.\n\n")

d += "## 1. Schademodel\n\n"
d += ("`schade = worp × matrix[aanvalstype][armortype] × (1 − armorreductie)`, met `armorreductie = 0,06·A / (1 + 0,06·A)` "
      "(negatieve armor versterkt de schade). Gif- en percentage-schade negeren armor.\n\n")
d += ("**Eigen namen, WC3-waarden.** De creeps en torens zijn in het origineel afgestemd op de WC3-tabel (zie dataverslag §6). "
      "Daarom zijn de vermenigvuldigers overgenomen. Alleen de namen zijn nieuw:\n\n")
d += "| Aanvalstype \\ Armortype | " + " | ".join(f"{AR[a][0]} / {AR[a][1]}" for a in m['armorTypes']) + " |\n"
d += "|---|" + "---:|" * len(m['armorTypes']) + "\n"
for at in m['attackTypes']:
    d += f"| {AT[at][0]} / {AT[at][1]} | " + " | ".join(f"{int(round(m['multipliers'][at][a] * 100))}%" for a in m['armorTypes']) + " |\n"
d += ("\nHerkomst van de namen: " + ", ".join(f"{AT[a][1]} = WC3 *{a}*" for a in m['attackTypes']) + "; "
      + ", ".join(f"{AR[a][1]} = *{ORIG_AR[a]}*" for a in m['armorTypes'])
      + ". *Goddelijk* neemt van niet-chaos-aanvallen slechts 10%, dus alleen chaos-torens (Gif, Kristal, Poollichtkanon) "
        "kunnen bonuslevel 35 echt aan.\n\n")
d += ("Het armortype van de creeps staat in de HUD (\"Pantser Licht 0\") en de torenkaart toont de vermenigvuldiger tegen "
      "het huidige level.\n\n")

d += "## 2. Elementen en torens (eigen namen)\n\n"
d += ("Volgorde = tier (duurder is sterker). De kolom *Bron* verwijst naar de eenheid-id in de originele map; de originele "
      "namen staan in het dataverslag.\n\n")
for e in t['elements']:
    d += f"### {e['name']['nl']} / {e['name']['en']}\n\n| Tier | NL | EN | Goud | Aanvalstype | Effecten | Bron |\n|---:|---|---|---:|---|---|---|\n"
    for tid in e['towers']:
        x = t['towers'][tid]
        fx = ', '.join(f['kind'] for f in x['effects']) or '-'
        d += f"| {x['tier']} | {x['name']['nl']} | {x['name']['en']} | {x['cost']['gold']} | {AT[x['attack']['type']][1]} | {fx} | {x['source']} |\n"
    d += "\n"
u = t['towers'][t['ultimate']]
d += (f"### Ultiem\n\n**{u['name']['nl']} / {u['name']['en']}**: {u['cost']['gold']} goud + {u['cost']['lumber']} hout, "
      f"bouwtijd {u['buildTime']} s, {u['attack']['damage'][0]} schade, chaos, bereik over de hele kaart, effecten: crit, slow, poison.\n\n")
d += ("**Nog niet in de eerste versie:** het \"altaar\" van Schaduw (bron `nC87`) dat in het origineel een zware vliegende "
      "eenheid traint.\n\n")

d += "## 3. Effecten en hun waarden\n\n"
d += ("Het origineel bewaart de effectwaarden in abilities (`war3map.w3a`). Die zijn nog niet uitgelezen, dus de waarden "
      "hieronder zijn **eigen, voorlopige keuzes** (in `tools/import_overlay.py`). De balans-run volgt in fase 7.\n\n")
d += "| Effect | Werking | Waarden |\n|---|---|---|\n"
d += "| slow | vertraagt (sterkste wint, niet stapelend) | 25-40% voor 2-2,5 s |\n"
d += "| poison | slow + schade per seconde (pure schade) | 20-25% slow, 15% van de gemiddelde treffer per s, 3 s |\n"
d += "| crit | kans op een vermenigvuldigde treffer | 10-20%, 2x |\n"
d += "| chain | bliksemketen naar nabije creeps | 3-4 extra doelen, 80-85% per stap |\n"
d += "| bounce | kaatst | 3 doelen, 75% per stap |\n"
d += "| armor_reduce | verlaagt armor tijdelijk | -3 tot -5 voor 5 s |\n"
d += "| percent_hp | haalt een deel van het huidige leven af | 25%, niet op bosses |\n"
d += "| set_hp | zet het leven op een vast getal | 10, niet op bosses |\n"
d += "| root | houdt vast | Gletsjerspuit permanent, Noodlotswachter 10% kans 2 s, niet op bosses |\n"
d += "| bonus_damage | extra schade per treffer | Pulskanon +500 |\n\n"

d += "## 4. Creeps en waves (eigen namen)\n\n"
d += ("Getallen uit het origineel (HP, armor, snelheid, bounty). Aantallen per spawnpunt (×6 spawnpunten, geschaald naar het "
      "aantal spelers, zie §5).\n\n")
d += "| Level | NL | EN | HP | Armor | Armortype | Lucht | Per spawn | Opmerking |\n|---:|---|---|---:|---:|---|---|---:|---|\n"
for wv in w:
    x = c[wv['creep']]
    note = 'eindbaas' if x['boss'] else ('bonus, geen levensverlies' if wv['noLifeLoss'] else '')
    if wv['finalBoss']:
        note = '**laatste eindbaas: bereikt hij het schip, dan is het direct verloren**'
    d += (f"| {wv['level']} | {x['name']['nl']} | {x['name']['en']} | {int(x['hp'])} | {int(x['armor'])} | "
          f"{AR[x['armorType']][1]} | {'ja' if x['air'] else ''} | {wv['countPerSpawn']} | {note} |\n")

d += "\n## 5. Schaling naar het aantal spelers\n\n"
d += ("Het origineel is voor 9 spelers: 6 spawnpunten × 20 creeps = 120 creeps. Wij schalen het aantal lineair "
      "(`6 × n × spelers / 9`, minimaal 1): solo is dat 13 creeps, een eindbaas komt 1 keer.\n\n")
d += ("**Voorlopige spelersboost** (`playerBoost` in `rules_classic.json`): omdat een solospeler met 30 goud ruimtelijk te weinig "
      "kan mazen, krijgen kleine teams extra middelen:\n\n")
d += "| Spelers | Startgoud | Levelbonus | Bounty |\n|---:|---:|---:|---:|\n| 1 | ×3 | ×1,5 | ×1,5 |\n| 2 | ×2 | ×1,3 | ×1,3 |\n| 3 | ×1,5 | ×1,15 | ×1,15 |\n| 4 | ×1,25 | ×1 | ×1 |\n\n"
d += "Deze getallen zijn een gok en moeten met de balans-sims (en jouw speeltests) worden afgesteld.\n\n"

d += "## 6. Kaart \"Vrieslijn\" / \"Frostline\"\n\n"
d += ("Gegenereerd door `tools/gen_map.py` naar `game/data/maps/frostline.json`. Rooster van 96×60 cellen (48×30 tegels, een cel is "
      "een halve tegel, een toren is 2×2 cellen).\n\n")
d += """```
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

"""
d += ("- 6 spawnpunten (2 per lane) links, het schip rechts in het midden\n"
      "- alle lanes komen samen in een gedeeld bouwveld voor het schip, zodat één verdediging alle creeps raakt (belangrijk voor solo)\n"
      "- grond- en hover-creeps volgen een **flow field** (8 richtingen, geen hoeken afsnijden) naar het schip. Lucht vliegt in een rechte lijn van spawn naar schip\n"
      "- **anti-block:** een plaatsing wordt geweigerd als een spawn of een creep op de grond het schip niet meer kan bereiken, of als er een grond-creep in de footprint staat\n"
      "- niet-bebouwbaar: spawnzones, verzamelstrook, uitgang en schip\n")

os.makedirs(os.path.join(ROOT, 'docs/design'), exist_ok=True)
with open(os.path.join(ROOT, 'docs/design/schade-namen-kaart.md'), 'w', encoding='utf-8') as f:
    f.write(d)
print('docs/design/schade-namen-kaart.md written,', d.count('\n'), 'lines')
