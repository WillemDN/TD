# Wintermaul v13: volledig ingevulde data (zonder gaten)

> Dit document vervangt de tabellen in [`wintermaul-v13-data.md`](wintermaul-v13-data.md) §4 en §5 waar ze afwijken.
> Alleen voor gamedesign. Namen, teksten en art nemen we niet over (zie `docs/PLAN.md` §3).

## Hoe dit is gemaakt

De map slaat alleen velden op die hij **wijzigt**. De rest erft hij van de standaard WC3-unit (het `base`-veld). Het eerste
dataverslag liet die velden leeg (`~`) of vulde ze met een gok. Nu zijn ze ingevuld:

1. Map opnieuw gedownload van [EpicWar](https://www.epicwar.com/maps/78651/) en uitgepakt met `tools/w3x-extract/`, nu **inclusief `war3map.j`**
   (het wave-script).
2. De standaard WC3-tabellen (`UnitBalance.slk`, `UnitData.slk`, `UnitWeapons.slk`) zijn opgehaald uit publieke GitHub-extracties
   van de spelbestanden (`MatthewMarinets/war3-ap-maps`, map `gamedata/1_30_4/custom_v0`). Die bestanden zijn van Blizzard
   en staan **niet** in deze repo. Alleen de getallen zijn gebruikt.
3. `tools/w3x-extract/resolve.py` voegt beide samen en bewaart per waarde of ze uit de **map** of uit de **standaardtabel** komt
   (`src` in [`data/wintermaul-v13-resolved.json`](data/wintermaul-v13-resolved.json)). `report.py` maakt de tabellen hieronder.

**Voorbehoud:** de standaardtabellen zijn van WC3 1.30.4 en de map is gemaakt voor 1.04–1.05. Kleine verschillen in stock-waarden
(vooral bij waarden die de map erft, zoals de aanvalssnelheid van torens zonder eigen cooldown) zijn mogelijk. Controleer die
bij de balans-simulatie in fase 2.

## Waves (uit het script `Set Levels`)

`n` is het aantal creeps **per spawnpunt** (x6 voor de hele wave). Snelheid in WC3-units per seconde (128 = 1 tile).
Armortypes: `small` = licht, `medium`, `large` = zwaar, `fort` = versterkt, `divine`. Bounty is `basis + dobbelstenen d zijden`,
dus `0+2d1` = 2 goud en `90+10d10` = 100 tot 190 goud. Beweging: `fly` = lucht, `foot`/`horse` = grond, `hover` = grond die ook over
water kan (op deze kaart is er geen water, dus gelijk aan grond).

| Lvl | Creep | n | HP | Armor | Armortype | Snelheid | Beweging | Bounty |
|---:|---|---:|---:|---:|---|---:|---|---|
| 1 | Scout | 20 | 15 | 0 | small | 200 | hover | 0+1d1 |
| 2 | Engineer | 20 | 60 | 0 | medium | 230 | foot | 0+1d1 |
| 3 | Night Ranger | 20 | 115 | 2 | small | 260 | foot | 0+1d1 |
| 4 | Barbarian | 20 | 150 | 2 | large | 270 | foot | 0+1d1 |
| 5 | Baby Dragon | 15 | 135 | 1 | large | 350 | fly | 0+2d1 |
| 6 | Stalker | 20 | 225 | 3 | small | 280 | foot | 0+2d1 |
| 7 | Water Runner | 20 | 260 | 4 | medium | 280 | foot | 0+2d1 |
| 8 | Ice Troll | 20 | 300 | 5 | medium | 300 | foot | 0+2d1 |
| 9 | Wolf Rider | 20 | 345 | 7 | large | 320 | horse | 0+2d1 |
| 10 | Ice General | 1 | 15000 | 10 | medium | 350 | hover | 0+50d1 |
| 11 | Hovercraft | 20 | 375 | 7 | fort | 315 | hover | 0+2d1 |
| 12 | Goblin Machine | 20 | 500 | 8 | large | 300 | foot | 0+2d1 |
| 13 | Frosty Reptile | 20 | 625 | 10 | medium | 375 | foot | 0+2d1 |
| 14 | Demonic Pet | 20 | 875 | 10 | small | 350 | foot | 0+2d1 |
| 15 | Matured Dragon | 15 | 675 | 12 | large | 375 | fly | 0+3d1 |
| 16 | Ice Shard Golem | 20 | 1100 | 12 | large | 350 | foot | 0+3d1 |
| 17 | Eternal Spirit | 20 | 1300 | 14 | small | 370 | hover | 0+3d1 |
| 18 | Supply Tank | 20 | 1300 | 10 | fort | 360 | foot | 0+3d1 |
| 19 | Walking Corpse | 20 | 1700 | 10 | large | 360 | foot | 0+3d1 |
| 20 | Frost Lieutenant | 1 | 30000 | 15 | medium | 360 | foot | 0+100d1 |
| 21 | Totem Carrier | 20 | 2000 | 15 | large | 380 | foot | 0+4d1 |
| 22 | Unholy Knight | 20 | 2300 | 15 | large | 400 | horse | 0+4d1 |
| 23 | Crystal Mage | 20 | 2500 | 16 | small | 350 | foot | 0+4d1 |
| 24 | Frozen Infernal | 20 | 2900 | 17 | large | 375 | foot | 0+4d1 |
| 25 | Adult Dragon | 15 | 2250 | 20 | large | 400 | fly | 0+4d1 |
| 26 | Polar Bear | 20 | 3400 | 18 | medium | 385 | foot | 0+4d1 |
| 27 | Possessed Hunter | 20 | 4000 | 18 | medium | 400 | foot | 0+4d1 |
| 28 | Corrupt Cheiftain | 20 | 4500 | 19 | medium | 400 | foot | 0+4d1 |
| 29 | Ancient Dragon | 15 | 3750 | 19 | large | 425 | fly | 0+4d1 |
| 30 | Duke-Wintermaul | 1 | 85000 | 20 | medium | 600 | foot | 90+10d10 |
| 31 | Osama Bin Ladin Lookalike | 20 | 5800 | 0 | medium | 270 | foot | 0+5d1 |
| 32 | Saddam Hussein Decoy | 20 | 6500 | 5 | medium | 300 | foot | 0+5d1 |
| 33 | Jon Cowan | 20 | 7000 | 15 | medium | 400 | foot | 0+5d1 |
| 34 | Sparta606 | 20 | 8000 | 20 | medium | 450 | foot | 0+5d1 |
| 35 | DEMON SHEEP | 50 | 1000 | 20 | divine | 500 | foot | 0+100d1 |

## Torens

Eenheden: bouwtijd in seconden, range en splash in **tiles** (WC3-units / 128), cooldown in seconden, projectielsnelheid in WC3-units/s.
Een `*` bij de cooldown betekent dat de map hem niet instelt voor het tweede aanvalsprofiel en dat we de cooldown van
profiel 1 hebben genomen. Splash is `volle / halve / kwart` schade op oplopende afstand.

| Element | Toren | Goud | Hout | Bouwtijd | Schade | Cooldown | Range (tiles) | Aanvalstype | Splash (tiles, vol/half/kwart) | Doelen | Projectiel | Abilities |
|---|---|---:|---:|---:|---|---:|---:|---|---|---|---:|---|
| Fire | Flare Tower | 10 |  | 5 | 3–8 | 1.0 | 5.5 | pierce | 0.0/0.1/0.2 | air,ground |  |  |
| Fire | Flame Dancer | 45 |  | 18 | 20–50 | 0.9 | 6.2 | pierce | 0.1/0.2/0.4 | air,ground | 950 | Abds |
| Fire | Meteor Watcher | 95 |  | 32 | 75–100 | 1.2 | 7.0 | pierce | 0.4/0.8/1.6 | air,ground | 5000 |  |
| Fire | Blast Furnace | 200 |  | 61 | 225–250 | 1.15 | 6.2 | pierce | 0.7/1.6/3.1 | air,ground | 10000 |  |
| Fire | Flame Staff | 350 |  | 90 | 100–150 | 0.6* | 5.5 | pierce | 0.4/0.8/1.2 | air,ground | 1100 |  |
| Ice | Icicle Tosser | 10 |  | 5 | 6 | 1.1 | 5.5 | normal | 0.0/0.1/0.1 | air,ground | 1250 | Abds,Afrb |
| Ice | Snowball Launcher | 40 |  | 23 | 26 | 1.0 | 6.2 | normal | 0.3/0.4/0.6 | air,ground | 800 | Afrb |
| Ice | Blizzard Master | 100 |  | 41 | 80–90 | 1.2 | 6.2 | normal | 0.2/0.4/0.5 | air,ground | 10000 | Afrb |
| Ice | Water Sprayer | 200 |  | 63 | 50 | 5.0 | 5.9 | normal |  | air,ground | 1250 |  |
| Ice | Nova Creator | 350 |  | 90 | 700 | 1.0 | 6.1 | normal | 0.1/0.2/0.3 | air,ground | 10000 | Abds,Afrb,Aspi |
| Tech | Nuclear Missile Silo | 310 |  | 90 | 902–1000 | 6.0 | 58.6 | pierce | 2.3/4.7/7.0 | air,ground | 10000 |  |
| Tech | Sniper Post | 30 |  | 22 | 28–34 | 1.75 | 12.5 | pierce |  | air,ground | 1600 |  |
| Tech | Enhanced Arrow Tower | 7 |  | 5 | 3–7 | 1.8 | 11.7 | pierce |  | air,ground |  |  |
| Tech | V2 Rocket Launcher | 80 |  | 46 | 100–130 | 2.5 | 14.1 | pierce | 0.4/0.8/1.0 | air,ground | 1000 |  |
| Tech | Ion Cannon Center | 170 |  | 60 | 300–375 | 3.0 | 23.4 | pierce |  | air,ground | 10000 |  |
| Electric | Shock Tower | 10 |  | 5 | 7 | 0.6 | 7.0 | normal |  | air,ground | 10000 |  |
| Electric | Storm Caller | 40 |  | 23 | 30 | 0.8 | 3.9 | normal |  | air,ground | 10000 | Abds,Alit |
| Electric | Chain Lightning Caster | 100 |  | 30 | 2 | 1.0 | 3.1 | normal |  | air,ground | 10000 | ACcl |
| Electric | Thunder Rod | 200 |  | 62 | 1 | 2.0 | 2.7 | normal |  | air,ground | 10000 |  |
| Electric | Battery | 350 |  | 50 | 401 | 0.6* | 7.8 | normal |  | air,ground | 1600 |  |
| Stone | Pebble Tower | 10 |  | 10 | 10–25 | 1.07 | 3.1 | siege |  | air,ground |  | ACct,Abds |
| Stone | Rock Blaster | 40 |  | 21 | 55–105 | 1.1 | 3.5 | siege |  | air,ground | 1600 | ACct,Abds |
| Stone | Stone Projector | 100 |  | 42 | 190–250 | 1.2 | 3.1 | siege |  | air,ground | 1000 | ACct |
| Stone | Faerie Mage | 200 |  | 63 | 475–550 | 1.1 | 3.9 | siege |  | air,ground | 1440 | ACct,Abds,Afae,Aspi |
| Stone | Paralyzer | 350 |  | 90 | 1 | 5.0 | 3.9 | siege |  | air,ground | 800 |  |
| Poison | Envenomed Spike | 15 |  | 5 | 5–8 | 1.25 | 7.8 | chaos |  | air,ground | 1400 | Aspo |
| Poison | Poison Spire | 60 |  | 22 | 20–35 | 1.0 | 7.8 | chaos |  | air,ground | 10000 | Aspo |
| Poison | Sludge Flinger | 120 |  | 55 | 70–90 | 1.2 | 8.6 | chaos |  | air,ground | 800 | Abds,Aspo |
| Poison | Grave Marker | 230 |  | 61 | 270–340 | 1.15 | 7.0 | chaos |  | air,ground | 10000 | Abds,Aspi,Aspo |
| Poison | Gas Chamber | 390 |  | 90 | 500–590 | 0.9 | 7.8 | chaos |  | air,ground | 1000 | Abds,Aspi,Aspo |
| Nature | Nature Pool | 10 |  | 5 | 3–6 | 1.0 | 5.5 | pierce | 0.3/0.5/0.8 | air,ground | 1800 | Abds |
| Nature | Terran Protector | 40 |  | 23 | 31–38 | 1.0 | 5.5 | siege | 0.3/0.5/0.8 | air,ground | 1800 | Abds |
| Nature | Gaia's Box | 100 |  | 40 | 76–100 | 1.75 | 5.5 | siege | 0.6/1.0/1.4 | air,ground | 1800 | Abds |
| Nature | Land-quaker | 200 |  | 60 | 50–340 | 1.5 | 0.8 | siege | 0.8/2.0/3.5 | air,ground | 1800 | Abds |
| Nature | Gaia | 350 |  | 90 | 250–300 | 1.0 | 3.9 | siege | 0.8/2.0/3.5 | air,ground | 1800 | Abds |
| Undead | Lisk | 25 |  | 22 | 26 | 1.0 | 6.2 | pierce |  | air,ground |  |  |
| Undead | Doomguard | 200 |  | 60 | 76 | 0.6 | 7.8 | chaos |  | air,ground | 2500 | ACct,ACff,Aenr |
| Undead | Dragon of the Shire | 150 |  | 46 | 150 | 1.1 | 6.2 | chaos |  | air,ground | 1200 | Afae |
| Undead | frostmourne pedestal | 350 |  | 3 |  |  |  |  |  |  |  |  |
| Undead | Skeleton-Face | 15 |  | 5 | 16 | 2.0 | 5.5 | normal |  | air,ground | 800 |  |
| Crystal | Crystal Bouncer | 130 |  | 45 | 71–85 | 0.6 | 6.2 | chaos | 3.1// | air,ground | 1800 | Abds,Amgl |
| Crystal | Crystal Shooter | 15 |  | 8 | 10–13 | 0.8 | 5.9 | chaos |  | air,ground |  | Abds |
| Crystal | Crystal Fury | 240 |  | 50 | 111–130 | 0.3 | 5.5 | chaos |  | air,ground | 1800 | ACct,Abds |
| Crystal | Crystal Blaster | 65 |  | 25 | 41–62 | 1.0 | 5.5 | chaos | 0.4/0.8/1.0 | air,ground | 1800 | Abds |
| Crystal | Crystal Slower | 270 |  | 60 | 211–235 | 0.7 | 6.2 | chaos | 0.4/0.6/0.8 | air,ground | 1800 | Abds,Afrb |
| Crystal | Crystal Dissolver | 550 |  | 80 | 1001–1100 | 0.9 | 23.4 | chaos |  | air,ground |  | Abds |
| Alle | Laser Cannon | 750 | 1 | 120 | 500 | 0.6* | 78.1 | chaos |  | air,ground | 1400 | ACct,Afrb,Aspo |

## Wat er in het eerste dataverslag niet klopte

- **Aanvalstype:** veel torens staan niet op `normal`. Vuur, Techniek, Lisk en Nature Pool zijn `pierce`, Nature
  (op één na) en Stone zijn `siege`. Dat heeft grote gevolgen voor de element-vs-armor-matrix.
- **"Splash"-kolom:** de waarden 800–2500 waren de **projectielsnelheid**. De echte splash is veel kleiner (zie de tabel). Voor
  torens zonder splash-velden is er geen splash.
- **Ranges** die als `~` stonden zijn nu ingevuld. De grote ranges van Ion Cannon (23 tiles), Nuclear Silo (59 tiles), Crystal
  Dissolver (23 tiles) en Laser Cannon (78 tiles) betekenen praktisch "dekt de hele kaart" (de kaart is 84 tiles breed).
- **Creeps:** Barbarian heeft armor 2 en snelheid 270, Wolf Rider en Unholy Knight zijn `horse`, niveau 17 is `hover`, en de
  armortypes per level staan nu vast (o.a. 14 Demonic Pet `small`, 17 Eternal Spirit `small`, 18 Supply Tank `fort`).
- **Bossen** (10, 20, 30) hebben armortype `medium`.
- **Tooltip tegenover data:** de tooltips lopen achter op de data bij **Laser Cannon** (tooltip 250, data 500), **Battery**
  (tooltip 150–200, data 401), **Shock Tower** (tooltip 4, data 7) en **Envenomed Spike** (tooltip 4–8, data 5–8). We gebruiken de data.
- **Tweede aanvalsprofiel:** Flame Staff, Battery en Laser Cannon vuren met aanvalsprofiel 2 (profiel 1 erft doel `none` en staat dus uit). `resolve.py` kiest het profiel dat echt vuurt (`attack`).
- **Skeleton-Face en de Undead-"altaar"** (Frostmourne pedestal) staan nu in de lijst. Het altaar traint de vliegende eenheid
  "evil arthas" (100 000 HP, range 31 tiles, 501 schade, splash).

## Nog niet uit de data te halen

- **Abilities** (`Afrb`, `Aspo`, `ACct`, `Alit`, `ACcl`, `Amgl`, `Afae`, `Aenr`, `ACff`, `Aspi`, `Abds`) staan hier alleen als code. Hun
  waarden (slow-percentage en -duur, crit-kans en -factor, chain-aantal, enzovoort) zitten in `war3map.w3a` en in de standaard `AbilityData.slk`.
  Dat is de volgende uitbreiding van `resolve.py`.
- **Trigger-specials** (Ion Cannon +500, Thunder Rod -25% HP, Water Sprayer, Paralyzer, Faerie Mage) staan in `war3map.j` en zijn nog
  niet gekoppeld aan torens.
- **Projectielsnelheid** van torens die de map niet instelt (leeg in de tabel) zit in de modeldata. Een vaste waarde volstaat voor onze 3D-projectielen.
