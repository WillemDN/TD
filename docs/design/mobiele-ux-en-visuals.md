# Ontwerp: mobiele bediening, camera en visuele stijl

Hoort bij [`../research/mobile-td-ux.md`](../research/mobile-td-ux.md). Dit is de versie van 2026-10-22.

## Camera: nooit de hele kaart

- Isometrische orthogonale camera, **steil (69 graden)**: bij 55 graden beslaan hoge torens optisch ook de tegel erachter en lijken ze op elkaar gestapeld, en lijken monsters erdoorheen te lopen (de simulatie was correct, getest met duizenden willekeurige plaatsingen, verplaatsingen en verkopen tijdens golven) De kaart is 48 x 30 tegels. Standaard zie je **17 tegels** breed rond het gedeelde bouwveld voor het schip
- Uitzoomen kan tot **de helft van de kaartbreedte** (24 tegels), inzoomen tot 9 tegels. De speler ziet dus nooit de hele kaart
- Panning: één vinger of linkermuisknop slepen, pijltjestoetsen, of tikken en slepen op de **minimap**. Knop "doel" (cirkel met kruis) zet de camera terug
- Knijpen en scrollwiel zoomen rond het aanraakpunt
- **Minimap** (rechtsboven): terrein, torens (blauw), monsters (rood, lucht geel, bazen groter) en het zichtvenster. Tik of sleep om te springen

## Bediening (muis en vinger hetzelfde)

| Gebaar | Effect |
|---|---|
| Slepen op de kaart | Camera verschuiven |
| Tik op een kaart in de lade | Toren "wapenen", daarna tik op de kaart: ghost, bevestig met het vinkje (muis: klik bouwt meteen) |
| **Kaart uit de lade slepen** | Ghost zweeft boven de vinger, loslaten plaatst. Blijft gewapend voor de volgende |
| Tik op een toren | Selecteren: statistieken, **Verplaats**, **Verkoop** |
| **Toren ingedrukt houden (0,4 s) of een geselecteerde toren slepen** | Oppakken en verplaatsen. Loslaten zet hem neer. De toren moet daar eerst weer opgebouwd worden (35% van de bouwtijd, minimaal 1,5 s), dus verplaatsen tijdens een wave is een echte keuze |
| "Muur slepen" (bij een gewapende toren) | Sleep een lijn: er komt een rij torens, groene vakjes zijn geldig. Loslaten bouwt ze |
| Knijpen / scrollwiel | Zoomen |
| Rechtermuisknop of Esc | Annuleren |
| Q W E R T Y, S, M, spatie, P, 1-3, Home | Sneltoetsen: toren, verkopen, verplaatsen, start level, pauze, snelheid, camera terug |

Verplaatsen gebruikt dezelfde anti-block-controle als bouwen: een verplaatsing die het pad sluit wordt geweigerd. De simulatie heeft hiervoor `can_move` en `move_tower` (met tests).

## Indeling (ontworpen voor een telefoon in landscape)

Een logisch scherm van ongeveer 440 px hoog (de UI schaalt dus mee naar de echte schermhoogte, op touch x1,64, op desktop x1,2):

- **Linksboven:** goud en hout. **Midden boven:** level, status, het volgende monster met pantser en lucht/grond, en de groene startknop. **Rechtsboven:** levens en menu
- **Minimap** met drie ronde knoppen (camera terug, pauze, snelheid) rechtsonder de minimap
- **Onderaan de lade:** element-tabs (iconen) boven grote kaarten (icoon, prijs, sneltoets). De naam en alle statistieken staan in het paneel links zodra een kaart gewapend of een toren geselecteerd is. De lade klapt in met de pijl
- **Links:** het infopaneel met de knoppen Verplaats en Verkoop (groot, 50 px)
- Alle iconen zijn vectoren die in code getekend worden (`client/ui_kit.gd`), dus scherp op elk scherm en zonder assetbestanden

## Visuele stijl (versie 3: donker en ijzig, naar het voorbeeld van het echte spel)

Zie [`../research/wc3-visual-reference.md`](../research/wc3-visual-reference.md) voor de referentie.

- **Sfeer:** bijna zwarte marineblauwe void, koude belichting met tonemapping, zachte gloed en dynamische schaduwen (uit op touch). **Terrein-shader:** glanzend turkoois ijs met barsten op de paden, donkere leisteenplaten met een tegelraster waar je bouwt (het fijnere celraster licht op tijdens het bouwen), donkere bosgrond, een houten dok bij het schip
- **Torens:** KayKit Medieval Hexagon (CC0), vier kleurvarianten en een ander model per tier (basis, A, B, catapult). Elk element heeft een eigen tint en een gloeiend accent bovenop. Zwarte omlijning, bouwfases en een voetafdrukvlak van één tegel
- **Monsters:** echte modellen met animatie: KayKit-figuren (skeletten, ridders, barbaren, magiërs) en dieren van de Everything Library (rat, panter, bizon, neushoorn, gorilla/yeti, hagedis, spin, kever, vleermuis, gier, havik, kraai, wisp) en een golem. Kleurtint en schaal per monster, de looptekening volgt de snelheid. Onder elk monster staat een gekleurde ring voor het **pantsertype**; die wordt blauw bij vertragen, groen bij gif en wit bij vastgehouden
- **Omgeving:** gekantelde ijsblokken langs de rand, donkere sneeuwbomen, rotsen en kristallen (Kenney), een schip als doel, sneeuwval
- **Effecten:** inslagringen per element, bliksemlijnen, gouddeeltjes bij een kill (één getal per beeld), lopende routelijnen die oplichten tijdens het bouwen en het bereikscherm

## Prestaties

Geen echte schaduwen (blob-schaduwen), `CPUParticles3D` voor sneeuw en deeltjes, bos als `MultiMesh`, en alle modellen worden per type gedeeld. De webbuild is single-threaded (geen speciale headers nodig).

## Nog niet gedaan

Geluid, een echte tutorial, een upgrade-wiel, doelprioriteit per toren, haptische feedback, en uitgebreide modellen voor de laatste bazen. Zie `docs/STATUS.md`.
