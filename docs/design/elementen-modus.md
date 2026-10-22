# Modus Elementen: ontwerp, getallen en balans

> Tweede spelmodus naast Klassiek, bedoeld om **alleen** uit te kunnen spelen. Het idee komt uit de Warcraft III-map-familie *Element TD*
> (onderzoek: `docs/research/element-td.md`). Alle namen, getallen en teksten zijn **eigen ontwerp**; er is niets uit die map gehaald.
> De data wordt volledig gegenereerd door `tools/gen_elements.py`. Pas getallen daar aan, draai het script en meet opnieuw met de bot.

## Het spel in het kort

- Een **vast pad** (slinger van ~130 tegels, drie banen). Je kunt het niet verleggen of dichtbouwen: torens staan op **bouwplaten** naast het pad.
  Elke plaatstrook ligt tussen twee banen, dus een toren raakt de creeps **twee keer** (heen en terug).
- **Zes elementen in een cirkel:** Licht → Duisternis → Water → Vuur → Natuur → Aarde → Licht. Elk element doet **x2** schade aan het volgende element
  en **x0,5** aan het vorige. Elke golf heeft **één element**, dat je in de balk bovenin ziet (met een gekleurde schijf onder de monsters).
- Je begint met **2 hout = 2 elementen** om te leren. Elke **5e level is een Guardian** (eindbaas); als je hem verslaat krijg je **+1 hout** voor een nieuw element.
- **Torens:** enkelvoudige elementtorens (3 niveaus), **duo's** (2 elementen) en **trio's** (3 elementen). Een mengtoren doet het gemiddelde van de
  multipliers van zijn elementen: nooit zwak, nooit sterk tegen alles. Een toren mag pas gebouwd worden als je **al zijn elementen** kent.
- **Rente:** elke 15 s krijg je 2% over het goud dat je niet uitgeeft. Sparen loont, maar torens kopen ook.
- **Lekken:** een doorgelekte creep verschijnt opnieuw aan het begin en kost bij elke ronde opnieuw een leven. Een level eindigt pas als alle creeps dood zijn.
- **Verkopen is gratis** zolang er geen golf bezig is (volle terugbetaling), tijdens een golf 80%. Torens verplaatsen kan net als in Klassiek.
- 40 levels, 30 creeps per golf (Guardians komen alleen). Moeilijkheid: levens **en** de HP van de creeps.

## Torens (53)

Alle torens hebben een gegenereerde matrix-rij (`elements/matrix.json`): de schade tegen elk creep-element.

| Soort | Aantal | Prijs | Beschikbaar | Schade/s (neutraal) | Bijzonder |
|---|---|---|---|---|---|
| Enkel niveau 1 | 6 | 10 | meteen | ~9 | |
| Enkel niveau 2 | 6 | 55 | na level 8 | ~55 | |
| Enkel niveau 3 | 6 | 240 | na level 18 | ~260 | |
| Duo | 15 | 110 | na level 4 | ~100 | effecten van beide elementen (85%) |
| Trio | 20 | 420 | na level 14 | ~420 | effecten van drie elementen (75%) |

Karakter per element (schade-correctie op de basis in `EL_DPS`):

| Element | Aanval | Effect | Opmerking |
|---|---|---|---|
| Licht | doordringend, bereik 6,8, snel (0,6 s) | kritieke treffer (x2,5) | lange afstand |
| Duisternis | chaos, bereik 5,8 | pantser-reductie | helpt alle andere torens |
| Water | normaal, bereik 5,2 | **vertraagt** | meer tijd in het bereik van iedereen |
| Vuur | beleg, splash (klein) | splash | splash is sterk op een drukke baan, daarom lagere basisschade (x0,8) |
| Natuur | normaal | gif (schade over tijd) | |
| Aarde | beleg, langzaam (1,6 s), zware klappen | kans op vasthouden | |

## Creeps en golven

- **HP** per creep: `22 · 1,18^(level-1) · (1 + 0,035 · (level-1))`; een Guardian heeft x14. Bij Makkelijk x0,7, Moeilijk en Perfectie x1,2.
- **Pantser:** `0,5 · level` (Guardian `0,8 · level`). Duisternis-torens en andere pantser-reductie doen er iets aan.
- **Snelheid:** 2,5 tegels/s (Guardian 2,0). **Bounty:** `2 · 1,095^(level-1)`, Guardian x12. Levelbonus: `6 + 2 · level`.
- **Elementvolgorde:** per blok van 6 levels een andere volgorde zodat elk element vaak voorkomt maar niet voorspelbaar is. Guardians wisselen van element.
- **Eigenschappen** (sinds level 3; ook zichtbaar in de balk bovenin):
  | Eigenschap | Effect | Levels |
  |---|---|---|
  | Snel | 30% sneller | 3, 7, 11, 14, 19, 23, 29 |
  | Helend | bij de dood krijgen buren (binnen 2 tegels) 20% van hun maximum terug | 8, 13, 17, 22, 28, 34, 38 |
  | Onsterfelijk | gaat eerst "neer" (5 s onkwetsbaar en onzichtbaar voor torens), staat dan één keer op met 33% leven | 12, 16, 21, 27, 33, 37, 39 |
  | Gepantserd | 3 s onkwetsbaar in elke 12 s (marker wordt wit) | 18, 24, 26, 31, 32, 36 |

## Kaart "Elementenpad" (`maps/trail.json`)

96 x 52 cellen (48 x 26 tegels), gegenereerd. Het teken `o` is een **bouwplaat**: bouwbaar, maar nooit loopbaar (nieuwe vlag `PLATE` in `core/grid.gd`),
`,` is het pad, `#` is bos. Omdat platen niet loopbaar zijn, kan geen toren het pad veranderen en is de anti-block-regel hier overbodig.
De camera start bij het begin van het pad; de speler ziet nooit de hele kaart (de minimap wel).

## Balansknoppen

`tools/gen_elements.py` leest overrides uit de omgeving, zodat je varianten kunt meten zonder de echte data te overschrijven:

```sh
GEN_OUT=/tmp/v1 GEN_HP_GROWTH=1.20 GEN_SPEED=2.4 python3 tools/gen_elements.py      # schrijft naar /tmp/v1
EL_DATA=/tmp/v1 godot --headless --path game --script res://<runner>.gd -- fire,water normal
```

Knoppen: `HP0`, `HP_GROWTH`, `HP_LINEAR`, `BOUNTY0`, `BOUNTY_GROWTH`, `BOSS_HP`, `SPEED`. De bot is `game/tests/bot_elements.gd`
(leert zijn elementen, bouwt op platen met de meeste padbedekking, koopt telkens de toren die zijn zwakste element-dekking verbetert, en ruilt zwakke torens in voor sterke).

## Balansresultaten (bot, Normaal = 40 levens)

De bot is minder slim dan een mens: hij mengt weinig, plaatst niet op dubbele passages en verkoopt niet slim. Een speler hoort verder te komen.

| Gekozen elementen (bot) | Normaal (40 levens) | Opmerking |
|---|---|---|
| Water + Natuur | level 37 | vertraging en gif samen: de sterkste combinatie voor de bot |
| Licht + Natuur | level 34 | |
| Licht + Duisternis | level 33 | |
| Aarde + Natuur | level 32-33 | |
| Duisternis + Vuur + Aarde (3 elementen) | level 33 | |
| Vuur + Water | level 28 | splash is zwakker gemaakt, daarom lager |
| Vuur + Aarde | level 28 | |
| Vuur + Water, **Makkelijk** (60 levens, 70% HP) | level 34-36 | |
| Vuur + Water, **Moeilijk** (25 levens, 120% HP) | level 27 | (eerdere meting, zelfde regels) |

De bot haalt dus **28 tot 37 van de 40 levels** op Normaal, afhankelijk van zijn elementen. Dat is bewust: een mens die beter plaatst, mengt en
upgradet hoort level 40 te halen. Uitgangspunten van de meting: 2 seeds per rij, 20 Hz, spelduur 30 tot 43 minuten bij 1x snelheid.

## Bekend en nog te doen

- Balans is gemeten met de bot, **niet met kinderen of op een telefoon**. Voelt het te makkelijk of te moeilijk, draai dan aan `HP_GROWTH`.
- Geen luchtcreeps, geen support-torens (aparte pantser-aura's, tower-amplifiers) en geen *Image*-creeps zoals in het voorbeeld.
- Torens zijn **niet te upgraden op dezelfde plek**: je verkoopt (volledig terug tussen de golven) en bouwt de sterkere. Een echte upgrade-knop is een logische vervolgstap.
- Elke toren is hetzelfde model met een kleurtint en accenten per element; een mengtoren krijgt de accenten van zijn elementen. Eigen modellen per element zijn nog niet gemaakt.
- Multiplayer (1-4 spelers) schaalt het aantal creeps al (`wave_total`), maar er is nog geen eigen baan per speler zoals in het origineel.
