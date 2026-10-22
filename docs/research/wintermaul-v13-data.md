# Wintermaul TD v13.0 Final: geëxtraheerde speldata

> **Status:** referentiemateriaal voor gamedesign, **niet** om 1-op-1 te verspreiden.
> Getallen en spelregels zijn als basis voor balancing bruikbaar. Namen, teksten, modellen,
> iconen en geluiden van Blizzard of van de mapmaker nemen we **niet** over (zie `docs/PLAN.md` §3).

## 1. Bron en werkwijze

| | |
|---|---|
| Map | *Wintermaul TD (Final)*, intern "Wintermaul TD v13.0 Final" |
| Auteur | Duke-Wintermaul (USEast); balans-/bugfixes door Parker2234 |
| WC3-versie | Reign of Chaos 1.04–1.05 (2002–2003) |
| Download | <https://www.epicwar.com/maps/78651/> (`Wintermaul (Final).w3m`, 114 KB) |
| Spelers | 9 verdedigers (P1–P9) + computer "Forces of Northrend" (P12) |
| Kaart | 96×96 tiles (speelbaar 84×84), Northrend-tileset |

De data is op 2026-10-22 rechtstreeks uit het mapbestand gehaald met de scripts in
[`tools/w3x-extract/`](../../tools/w3x-extract/):

- `war3map.j`: het triggerscript met waves, timers, levens, goud en moeilijkheidsgraden
- `war3map.w3u`: de unit-objectdata van torens, creeps en builders, als ruwe dump in [`data/wintermaul-v13-objectdata.json`](data/wintermaul-v13-objectdata.json)
- `war3map.wts`: de strings met namen en tooltips
- `war3map.wpm`: de pathing-map, gerenderd als [`wintermaul-layout.png`](wintermaul-layout.png)

Velden die de map niet wijzigt, erft hij van de standaard WC3-unit. Die waarden staan hieronder als `~`
en moeten we zelf invullen tijdens het balancen.

## 2. Kernregels (uit `war3map.j`)

| Regel | Waarde in v13 |
|---|---|
| Startgoud | 30 per speler |
| Starthout (lumber) | 1, nodig voor je element-gebouw; **+1 hout na level 15** (voor een 2e element of de Laser Cannon) |
| Levens | Gedeeld door het hele team. Moeilijkheid kiest P1 (rood) binnen 30 s: **Easy 40 / Normal 20 / Hard 10 / Perfection 1** |
| Eerste wave | 60 s na de start |
| Volgende wave | De timer start pas als **alle** creeps dood of "aan boord" zijn, daarna **30 s** wachten |
| Creeps per wave | `Monster_Amount` × **6 spawnpunten** (2 links, 2 midden, 2 rechts), dus 120 creeps bij 20 per punt |
| Bounty per kill | Klein: 1–5 goud per creep, bosses 50 / 100, eindbaas 90 + 10d10 |
| Levelbonus | Iedere verdediger krijgt **12 + 2×L goud** na het halen van level *L*. P9 krijgt de helft extra ("last defender") |
| Lek | Een creep die het schip (onderaan) bereikt, kost 1 leven en verdwijnt |
| Verlies | Levens ≤ 0, **of** de eindbaas van level 30 bereikt het schip (direct verlies) |
| Bonuslevels | Levels 31–35 zijn gratis: lekken kost geen levens meer |
| Winst | Level 36 bereikt met levens > 0 |
| Verkopen | Via een "Sell"-knop op de toren (getraind als unit). Je krijgt de *point value* van de toren terug |
| Blokkeren | Mag niet. Een geblokkeerde creep valt torens aan en wordt na 1 s opnieuw naar het schip gestuurd. **Wij lossen dit modern op met een anti-block-check bij het plaatsen** |
| Zicht | Hele map zichtbaar (geen fog of war), sneeuw-weer, schemer |

## 3. Kaartlayout

![Wintermaul layout](wintermaul-layout.png)

*Wit = bebouwbaar, lichtblauw = beloopbaar maar niet bebouwbaar, donker = muur.
Rood = spawnpunten, oranje = checkpoints/waypoints, groen = het schip (eindpunt).*

Looproutes (waypoints in het script):

- **Links:** spawn L1/L2 → checkpoint linksonder → checkpoint centrum-onder → schip
- **Rechts:** gespiegeld
- **Midden:** spawn M1/M2 → checkpoint midden → doorgestuurd naar links of rechts → verder als hierboven

Spelers bouwen in de open witte velden en maken daar een **maze** (doolhof) om het pad te verlengen.
Dat is de kern van het spel.

## 4. Waves (35 levels)

`n` = aantal creeps **per spawnpunt** (×6 voor de hele wave). HP = maximum HP, Arm = armor.
"Lucht" geldt voor de draak-levels: de basisunits zijn vliegend en negeren de maze.

| Lvl | Creep (origineel) | n | HP | Arm | Snelheid | Bounty | Opmerking |
|---:|---|---:|---:|---:|---:|---:|---|
| 1 | Scout | 20 | 15 | ~ | 200 | 1 | |
| 2 | Engineer | 20 | 60 | ~ | 230 | 1 | |
| 3 | Night Ranger | 20 | 115 | 2 | 260 | 1 | |
| 4 | Barbarian | 20 | 150 | ~ | ~ | 1 | armor *large* |
| 5 | Baby Dragon | 15 | 135 | ~ | ~ | 2 | **lucht** |
| 6 | Stalker | 20 | 225 | 3 | 280 | 2 | armor *small* |
| 7 | Water Runner | 20 | 260 | 4 | 280 | ~ | |
| 8 | Ice Troll | 20 | 300 | 5 | 300 | ~ | |
| 9 | Wolf Rider | 20 | 345 | 7 | 320 | 2 | |
| 10 | **Ice General (BOSS)** | 1 | 15 000 | 10 | 350 | 50 | hover |
| 11 | Hovercraft | 20 | 375 | 7 | 315 | 2 | armor *fort*, hover |
| 12 | Goblin Machine | 20 | 500 | 8 | 300 | 2 | |
| 13 | Frosty Reptile | 20 | 625 | 10 | 375 | 2 | |
| 14 | Demonic Pet | 20 | 875 | 10 | ~ | 2 | armor *small* |
| 15 | Matured Dragon | 15 | 675 | 12 | 375 | 3 | **lucht**, +1 hout na dit level |
| 16 | Ice Shard Golem | 20 | 1 100 | 12 | 350 | 3 | |
| 17 | Eternal Spirit | 20 | 1 300 | 14 | 370 | 3 | |
| 18 | Supply Tank | 20 | 1 300 | 10 | 360 | 3 | |
| 19 | Walking Corpse | 20 | 1 700 | 10 | 360 | 3 | |
| 20 | **Frost Lieutenant (BOSS)** | 1 | 30 000 | 15 | 360 | 100 | |
| 21 | Totem Carrier | 20 | 2 000 | 15 | 380 | 4 | |
| 22 | Unholy Knight | 20 | 2 300 | 15 | 400 | 4 | |
| 23 | Crystal Mage | 20 | 2 500 | 16 | 350 | 4 | armor *small*, brilliance-aura |
| 24 | Frozen Infernal | 20 | 2 900 | 17 | 375 | 4 | |
| 25 | Adult Dragon | 15 | 2 250 | 20 | 400 | 4 | **lucht** |
| 26 | Polar Bear | 20 | 3 400 | 18 | 385 | ~ | |
| 27 | Possessed Hunter | 20 | 4 000 | 18 | 400 | 4 | |
| 28 | Corrupt Chieftain | 20 | 4 500 | 19 | 400 | 4 | |
| 29 | Ancient Dragon | 15 | 3 750 | 19 | 425 | 4 | **lucht** |
| 30 | **Eindbaas (BOSS)** | 1 | 85 000 | 20 | 600 | 90+10d10 | bereikt hij het schip, dan is het **game over** |
| 31–34 | Bonus-creeps¹ | 20 | 5 800 → 8 000 | 0 → 20 | 300–450 | 5 | geen levensverlies |
| 35 | Bonus "Demon Sheep" | 50 | 1 000 | 20 (*divine*) | 500 | 100 | geen levensverlies |

¹ Vernoemd naar echte personen en mapmakers. Die krijgen bij ons nieuwe namen en een nieuw thema.

**Ontwerppatroon:** elke 5e wave (5/15/25) is een luchtwave, elke 10e wave een boss en
29 is de laatste luchtwave. HP stijgt grofweg exponentieel (×1,2 tot ×1,3 per level) en armor
loopt lineair op van 0 naar 20.

## 5. Elementen (rassen) en torens

Elke speler krijgt een **Element Chooser** (vliegende, onkwetsbare builder) en kiest met 1 hout
een element-gebouw. Dat gebouw traint de element-builder, die 5 torens kan bouwen. In v13 is
er **geen upgrade-pad**: elke toren wordt los gebouwd en hoger in de lijst is sterker.
Moderne Wintermaul-versies (zoals Wintermaul One met 49 races) gebruiken wél upgrades. Dat is een ontwerpkeuze (zie PLAN §8).

| Element | Builder | Beschrijving uit de tooltip |
|---|---|---|
| Fire | Fire Minion | Matige schade + **splash**. Extra schade tegen heavy, minder tegen fortified/light |
| Ice | Ice Former | **Vertraagt**, snel vuren, korte range. Extra tegen light |
| Tech | Scientist | **Lange range**, matige schade, lange cooldown. Extra tegen heavy |
| Electric | Spark | Zeer snel vuren, lage schade, **chain lightning**. Extra tegen light |
| Stone | Stone Summoner | **Hoge schade**, korte range, kans op 2× crit. Extra tegen fortified |
| Poison | Alchemist | Matig, vertraagt (poison), **gelijke schade tegen alle armor** (chaos) |
| Nature (Gaia) | Gaia's Servant | Grote splash, "magische" schade |
| Undead | Undead Summoner | Gemengd: entangle, faerie fire en een held-achtige eenheid |
| Crystal | Crystal Molder | Duur maar sterk. Bounce, crit, slow, enorme range op de top-toren |
| *Alle* | Element Chooser | **Laser Cannon**: 750 goud + 1 hout, 120 s bouwtijd, geen zwaktes |

### Torentabel

Schade = min–max per aanval. Range en splash staan in WC3-units: 128 units = 1 terrain-tile en een
standaardtoren is 2×2 bouwcellen van 64 units. Een range van 700 is dus ongeveer 5,5 tiles.

| Element | Toren | Goud | Bouwtijd s | Schade | Cooldown s | Range | Splash | Aanvalstype | Specials |
|---|---|---:|---:|---|---:|---:|---:|---|---|
| Fire | Flare Tower | 10 | 5 | 3–8 | 1.0 | ~ | | normal | |
| Fire | Flame Dancer | 45 | 18 | 20–50 | 0.9 | ~ | 950 | normal | |
| Fire | Meteor Watcher | 95 | 32 | 75–100 | 1.2 | 900 | groot | normal | |
| Fire | Blast Furnace | 200 | 61 | 225–250 | 1.15 | ~ | groot | normal | |
| Fire | Flame Staff | 350 | 90 | 100–150² | snel² | ~ | klein | normal | |
| Ice | Icicle Tosser | 10 | 5 | 6 | 1.1 | 700 | 1250 | normal | slow |
| Ice | Snowball Launcher | 40 | 23 | 26 | 1.0 | ~ | 800 | normal | slow |
| Ice | Blizzard Master | 100 | 41 | 80–90 | 1.2 | ~ | | normal | slow |
| Ice | Water Sprayer | 200 | 63 | 50 | 5.0 | 750 | 1250 | normal | **immobiliseert** het doel (niet op bosses) |
| Ice | Nova Creator | 350 | 90 | 700 | 1.0 | 775 | | normal | slow, frost nova |
| Tech | Enhanced Arrow Tower | 7 | 5 | 3 | 1.8 | 1500 | | normal | |
| Tech | Sniper Post | 30 | 22 | 28–34 | 1.75 | 1600 | | pierce | |
| Tech | V2 Rocket Launcher | 80 | 46 | 100–130 | ~ | 1800 | 1000 | pierce | alleen grond |
| Tech | Ion Cannon Center | 170 | ~ | 300–375 | 3.0 | 3000 | | normal | +500 schade bij impact |
| Tech | Nuclear Missile Silo | 310 | 90 | 902–1000 | 6.0 | 7500 | | pierce | |
| Electric | Shock Tower | 10 | 5 | 7 | 0.6 | 900 | | normal | |
| Electric | Storm Caller | 40 | 23 | 30 | 0.8 | 500 | | normal | chain lightning |
| Electric | Chain Lightning Caster | 100 | 30 | 2 | 1.0 (2.0³) | 400 | | normal | cast chain lightning per aanval |
| Electric | Thunder Rod | 200 | 62 | 1 | 2.0 | 350 | | normal | **−25% huidige HP** (niet op bosses) |
| Electric | Battery | 350 | 50 | 150–200² | ~ | 999 | 2200 | normal | |
| Stone | Pebble Tower | 10 | 10 | 10–25 | 1.07 | 400 | | siege | crit |
| Stone | Rock Blaster | 40 | 21 | 55–105 | 1.1 | 450 | | siege | crit |
| Stone | Stone Projector | 100 | 42 | 190–250 | 1.2 | 400 | | siege | crit |
| Stone | Faerie Mage | 200 | 63 | 475–550 | 1.1 | 500 | | siege | crit, **armor −5** |
| Stone | Paralyzer | 350 | 90 | 1 | 5.0 | 500 | | siege | **zet HP op 10** (niet op bosses) |
| Poison | Envenomed Spike | 15 | 5 | 5–8 | 1.25 | 1000 | | chaos | poison-slow |
| Poison | Poison Spire | 60 | 22 | 20–35 | 1.0 | 1000 | | chaos | poison-slow |
| Poison | Sludge Flinger | 120 | ~ | 70–90 | 1.2 | 1100 | 800 | chaos | poison-slow, alleen grond |
| Poison | Grave Marker | 230 | 61 | 270–340 | 1.15 | 900 | | chaos | poison-slow |
| Poison | Gas Chamber | 390 | 90 | 500–590 | 0.9 | 1000 | 1000 | chaos | poison-slow |
| Nature | Nature Pool | 10 | 5 | 3–6 | 1.0 | 700 | 1800 | pierce | |
| Nature | Terran Protector | 40 | 23 | 31–38 | 1.0 | 700 | 1800 | normal | |
| Nature | Gaia's Box | 100 | 40 | 76–100 | 1.75 | 700 | 1800 | normal | grote splash |
| Nature | Land-quaker | ~ | 60 | 50–340 | 1.5 | 100 | 1800 | normal | |
| Nature | Gaia | 350 | 90 | 250–300 | 1.0 | 500 | 1800 | siege | |
| Undead | Skeleton-Face | 15 | 5 | 16 | 2.0 | 700 | 800 | normal | |
| Undead | Lisk | 25 | 22 | 26 | 1.0 | 800 | | normal | |
| Undead | Dragon of the Shire | 150 | 46 | 150 | 1.1 | ~ | 1200 | chaos | faerie fire |
| Undead | Doomguard | 200 | ~ | 76 | 0.6 | 1000 | 2500 | chaos | crit, entangle, faerie fire |
| Undead | (naamloos altaar) | 350 | ~ | 201 | 1.5 | 1000 | 1000 | normal | traint een sterke vliegende eenheid (id `Uear`, 100 000 HP, range 4000) |
| Crystal | Crystal Shooter | 15 | 8 | 10–13 | 0.8 | 750 | | chaos | |
| Crystal | Crystal Blaster | 65 | 25 | 41 | 1.0 | 700 | 1800 | chaos | |
| Crystal | Crystal Bouncer | 130 | 45 | 71–85 | 0.6 | 800 | 1800 | chaos | bounce (moon glaive) |
| Crystal | Crystal Fury | 240 | 50 | 111–130 | 0.3 | 700 | 1800 | chaos | crit |
| Crystal | Crystal Slower | 270 | 60 | 211–235 | 0.7 | 800 | 1800 | chaos | slow, splash |
| Crystal | Crystal Dissolver | 550 | 80 | 1001–1100 | 0.9 | 3000 | | chaos | |
| Alle | **Laser Cannon** | 750 + 1 hout | 120 | 250 | 0.6 | 10000 | | chaos | crit, slow, poison |

² Uit de tooltip, want de objectdata erft deze waarden. ³ Volgens de changelog in de map.
Een splashwaarde van 1800 is in WC3 meestal de *projectielsnelheid* en geen splash. Bij de omzetting controleren we per toren
welk veld wat betekent.

**Tower-specials die via triggers werken** (moeten we zelf als ability implementeren):
Ion Cannon (+500 schade), Thunder Rod (−25% HP), Water Sprayer (permanente stun), Paralyzer
(HP→10), Chain Lightning Caster (cast per aanval), Faerie Mage (armor-debuff). Thunder Rod, Water Sprayer
en Paralyzer werken **niet** op boss-levels (10, 20, 30).

## 6. Schade-model van WC3 (referentie)

Armor-reductie: `reductie = 0,06·A / (1 + 0,06·A)`, dus 10 armor geeft 37,5% en 20 armor 54,5%.

Aanvalstype × armortype, uit de TFT-referentietabel. RoC 1.04 week op een paar punten af. Zie dit als startpunt en niet als wet:

| Aanval \ Armor | Light/Small | Medium | Heavy/Large | Fortified | Hero | Unarmored |
|---|---:|---:|---:|---:|---:|---:|
| Normal | 100% | 150% | 100% | 70% | 100% | 100% |
| Pierce | 200% | 75% | 100% | 35% | 50% | 150% |
| Siege | 100% | 50% | 100% | 150% | 50% | 150% |
| Magic | 125% | 75% | 200% | 35% | 50% | 100% |
| Chaos | 100% | 100% | 100% | 100% | 100% | 100% |

*Divine* armor (de bonus-sheep) neemt in WC3 slechts een fractie van alle niet-chaos-schade.

**Advies voor onze game:** WC3-typen vervangen door een eigen, leesbare **element-vs-armor-matrix**
(bv. Vuur sterk tegen *Gepantserd*, IJs sterk tegen *Licht*, Steen sterk tegen *Versterkt*,
Gif neutraal). Dat sluit aan bij de elementbeschrijvingen hierboven en is op een gsm uit te leggen met
één icoon per creep.

## 7. Wat we niet kunnen of mogen overnemen

- 3D-modellen, iconen, geluiden en muziek van Warcraft III (© Blizzard)
- De naam "Wintermaul" en de originele teksten als productnaam. Gameplay-mechanieken en getallen zijn
  niet auteursrechtelijk beschermd, maar we geven alles eigen namen en eigen art
- De creepnamen die naar echte personen verwijzen (bonuslevels 31–34) en de eindbaas "Duke-Wintermaul"

## 8. Andere Wintermaul-versies (voor later)

| Versie | Link | Waarom interessant |
|---|---|---|
| Wintermaul TD v8.35 / Gold 1.3 (Duke-Wintermaul) | <https://www.epicwar.com/maps/323215/>, <https://www.epicwar.com/maps/322585/> | Andere rassen/nuke-spell, ter vergelijking |
| Wintermaul X10 Final (72 torens) | <https://www.epicwar.com/maps/2824/> | Meer torens, upgrade-bomen |
| Wintermaul One 10.0 | <https://www.epicwar.com/maps/214877/> | Moderne opvolger met races en upgrades |
| Wintermaul One Revolution (49 races, 40 waves, 6+ modi) | <https://wintermaul.one/> | Inspiratie voor modi (All Random, All Pick, Infinite) |
| Wintermaul Wars (x14.2) | <https://maultactics.gg/articles/wintermaul-wars-history>, <https://www.epicwar.com/maps/253710/> | PvP-variant met **creeps sturen** en income, ideaal als 2e modus |
| WmW-gids | <http://wmwl.weebly.com/wmw-guide.html> | Mazing (spiraal/hook) en strategie |

Met dezelfde scripts kunnen we elke versie uitlezen. Maps uit Warcraft III 1.31+ en Reforged gebruiken soms
`war3map.w3u`-versie 3 en Lua in plaats van JASS. Dan moeten we het script uitbreiden.
