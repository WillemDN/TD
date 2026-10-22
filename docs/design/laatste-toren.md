# Modus Laatste toren: ontwerp, getallen en balans

> Derde spelmodus, een **survivor**-spel voor één speler. Het idee komt uit de Warcraft III-map *Tower Survivors* (onderzoek:
> `docs/research/tower-survivors.md`). Alle namen, getallen en teksten zijn **eigen ontwerp**. De data wordt gegenereerd door
> `tools/gen_survivor.py`; pas getallen daar aan en meet opnieuw met de bot.

## Het spel in het kort

- **Eén toren** in het midden van een ronde arena. Hij beweegt niet en schiet zelf. Jij kiest alleen **wat hij krijgt**.
- **Vijanden** komen uit de duisternis aanlopen en slaan de toren. Boogschutters blijven op afstand staan. Ze worden elke minuut sterker.
- **Winkel** met 5 kaarten (wapens en verbeteringen), elke **45 s** (een "ronde") vers. **Herladen** kost 20 goud, daarna steeds 15 meer, en begint elke ronde opnieuw.
  Tik een kaart om hem te lezen, tik de **Koop**-knop (of dezelfde kaart nog eens) om te kopen.
- **Wapens (max. 6):** een tweede exemplaar van een wapen dat je al hebt maakt het **sterker** (+40% schade, sneller, soms een extra kling of doel; max. niveau 5)
  en kost meer (+50% per niveau).
- **Verbeteringen** stapelen op: schade, aanvalssnelheid, pantser, leven, herstel, inkomen, kritieke treffers, blokkeren, doornen, bereik, goud per kill, een schild,
  herrijzenis (Feniksklauw: herhaalbaar met 90 s rust; Ankh: één keer).
- **Goud:** 3 per seconde plus wat je verdient met kills (groeit 5% per minuut) en met inkomen-verbeteringen.
- **Goudstieren** komen elke 70 s: snel, lopen langs de toren, 80 goud als je ze raakt. **Eindbazen** op 4:00, 7:00, 10:00, 12:30 en 14:00.
- **Wegvegen** (de paniekknop): alle vijanden behalve bazen verdwijnen zonder goud, de toren herstelt 25% en is 1 s veilig. 2 minuten rust (de eerste keer na 1 minuut).
- **Winst:** 15 minuten overleven. **Verlies:** de toren valt. Moeilijkheid = sterkte van de vijanden (70%, 100%, 135%, 180%).

## Wapens (20) en verbeteringen (22)

Schade is **fysiek** (het pantser van de vijand telt) of **magisch** (negeert pantser). Prijzen: 60, 180, 550 en 1500 goud (gewoon tot episch).

| Soort | Wapens |
|---|---|
| Projectiel | Werpmessen (start), Kruisboog (doorboort), Gifpijltjes (gif), Spietser (doorboort 6), Snelvuurkoker (heel snel) |
| Kling-ring | Stekelring, Stekelwiel (draaien rond de toren) |
| Aura | Vorstbel (vertraagt), Verderfaura, Hellevuursteen (brandt) |
| Bom | Vuurflesje, Katapult, Meteorenregen (3 tegelijk) |
| Bliksem | Vonkensteen, Teslakanon, Boogreactor (springt over 3, 5 of 8 vijanden) |
| Mijnen | Landmijnen |
| Werpschijf | Werpschijf, Doodssikkel (geneest de toren) |
| Inslag | Stormgenerator (raakt willekeurige vijanden) |

De winkelkansen verschuiven met de tijd: in minuut 0 tot 3 zijn 70% van de kaarten gewoon en 0% episch; vanaf minuut 12 is 21% episch en 36% zeldzaam.

## Vijanden

| Vijand | Eigenschappen | Vanaf |
|---|---|---|
| Beenloper | zwak, veel | 0:00 |
| Beenboogschutter | blijft op 5 tegels | 1:00 |
| Kruiper | pak van 4, snel | 1:30 |
| Rover | pantser 1 | 2:00 |
| Schaduwkat | heel snel | 3:00 |
| Schrootgolem | 220 leven, pantser 6 | 5:00 |
| Plunderaar | 400 leven, pantser 10 | 7:00 |
| Goudstier | geen aanval, 80 goud | elke 70 s |
| Eindbazen (Vorstreus, Winterkoning, Oerbeer) | grote klappen, veel pantser | 4:00 tot 14:00 |

Leven groeit 20% per minuut (extra +5% per minuut na 10 minuten), schade 8%, pantser +0,4 per minuut. De spawnsnelheid (punten per seconde) is `0,8 + 0,7 · minuut`;
duurdere vijanden kosten meer punten. Hoogstens 120 vijanden tegelijk (de webversie moet ze allemaal tekenen).

## Balansresultaten (bot, 3 seeds per rij)

De bot (`tests/bot_survivor.gd`) koopt wat het meeste oplevert per goud, spaart voor een veel betere kaart die bijna betaalbaar is, herlaadt als er niets bruikbaars ligt en
gebruikt Wegvegen onder 30% leven. Hij speelt veel slechter dan een mens: hij combineert niets slim en kiest zijn wapens vooral op prijs.

| Moeilijkheid | Uitkomst |
|---|---|
| Makkelijk (70%) | wint alle 3 (15 min) |
| Normaal (100%) | verliest op 7,6 / 7,8 / 13,5 min |
| Moeilijk (135%) | wint 1 van 3, verliest op 4,3 en 8,4 min |
| Perfectie (180%) | verliest na 3,0 / 4,3 / 5,9 min |

Er zit een duidelijke muur bij de tweede baas (7:00): wie die haalt, heeft daarna meer goud dan hij kan uitgeven (25.000 tot 55.000 goud op Normaal), dus de late
fase wordt dan snel te makkelijk. Dat is een bekende zwakte, zie hieronder.

## Balansknoppen

```sh
GEN_OUT=/tmp/sv GEN_WEAPON_DMG=2.2 GEN_HP_PER_MIN=1.18 python3 tools/gen_survivor.py     # schrijft naar /tmp/sv
SV_DATA=/tmp/sv godot --headless --path game --script res://<runner>.gd -- normal
```

Knoppen: `WEAPON_DMG`, `HP_PER_MIN`, `DMG_PER_MIN`, `BOUNTY_PER_MIN`, `SPAWN_BASE`, `SPAWN_PER_MIN`, `WIN_TIME`.

## Bekend en nog te doen

- **Balans met de bot, niet met een mens.** Het goud-sneeuwbaleffect na minuut 7 is te sterk; een goudafvoer (duurdere duplicaten, een prijs die meegroeit met de tijd) of
  sterkere late golven zijn de logische volgende stap.
- Geen eigen modellen per wapen: de toren is het kasteelmodel met een kleurtint, wapens zijn eenvoudige vormen (klingen, bollen, schijven, ringen).
- Geen geluid, geen opslag van resultaten, geen multiplayer (het origineel heeft tot 8 spelers).
- Zoomen kan met scrollen of knijpen. Kijken en tikken is getest met screenshots op 1280x720 en 844x390, **niet op een echte telefoon**.
