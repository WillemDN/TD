# Ontwerp: mobiele bediening, camera en visuele stijl

Hoort bij [`../research/mobile-td-ux.md`](../research/mobile-td-ux.md). Dit is de versie van 2026-10-22.

## Camera: nooit de hele kaart

- Isometrische orthogonale camera (55 graden). De kaart is 48 x 30 tegels. Standaard zie je **17 tegels** breed rond het gedeelde bouwveld voor het schip
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

## Visuele stijl

- Laag-poly 3D, wintertema, zachte kleuren. **Torens** zijn samengesteld uit de CC0-onderdelen van de Kenney Tower Defense Kit (rond/vierkant, onderstuk, middenstuk, top, wapen). Het element bepaalt het wapen, de kleurvariant en een gloeiend accent (vlam, ijskristallen, bol, rotsen, druppel, bladeren, kristallen). Hoger tier = meer lagen. De **bouwfases** van de kit tonen de opbouw. Het wapen draait naar zijn doel
- **Monsters** zijn zelf gebouwd uit primitieven (`client/models.gd`), 11 archetypes (imp, humanoïde, bruut, beest, ruiter, hagedis, golem, geest, slee, machine, yeti) en een draak voor de luchtlevels, met looptekening, vleugelslag en zweven. Bazen zijn groter en gekroond. Onder elk monster staat een gekleurde ring voor het **pantsertype** (groen licht, geel middel, oranje zwaar, blauw versterkt, wit goddelijk). Die wordt blauw bij vertragen, groen bij gif en wit bij vastgehouden
- **Omgeving:** sneeuwveld, sneeuwbos met bomen, rotsen en kristallen (Kenney), sneeuwbanken langs de rand, een zeilschip als doel, sneeuwval, zachte blob-schaduwen
- **Effecten:** inslagringen per element, bliksemlijnen, gouddeeltjes bij een kill, vlotte routelijnen (lopende streepjes) die oplichten tijdens het bouwen, een rasteroverlay en het bereikscherm

## Prestaties

Geen echte schaduwen (blob-schaduwen), `CPUParticles3D` voor sneeuw en deeltjes, bos als `MultiMesh`, en alle modellen worden per type gedeeld. De webbuild is single-threaded (geen speciale headers nodig).

## Nog niet gedaan

Geluid, een echte tutorial, een upgrade-wiel, doelprioriteit per toren, haptische feedback, en uitgebreide modellen voor de laatste bazen. Zie `docs/STATUS.md`.
