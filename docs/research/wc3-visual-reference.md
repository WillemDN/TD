# Visuele referentie: hoe het echte Wintermaul eruitziet

> Bekeken op 2026-10-22: vier minimaps van de kaarten op EpicWar en drie schermafbeeldingen van *Wintermaul Wars Evolution* en de
> terreinweergave van een Wintermaul-variant op Hive Workshop. Echte spelscreenshots van de originele Wintermaul TD v13 waren niet te vinden.
> We nemen **geen** Warcraft III-assets over (zie `docs/PLAN.md` §3); dit document beschrijft alleen de visuele taal die we nabootsen.

## Wat opvalt in het origineel

- **Donkere, koude sfeer:** diepmarineblauw tot zwart rondom de kaart (de "void"), een koud blauw licht, weinig warme kleuren behalve bij torens en effecten
- **Vloer van geglazuurd ijs** in verzadigd turkoois/blauw met een zichtbare textuur (barsten, aderen). Dit zijn de looproutes en de open velden
- **Donkere bouwplaten:** de plekken waar je bouwt zijn donker leisteenblauw met een **tegelraster** in lichtere lijnen. Daardoor is bouwen precies en leesbaar
- **IJskliffen met gekartelde randen** langs de plaat, met witte sneeuwranden, en terrassen die de kaart een diepte geven
- **Gedetailleerde, schilderachtige modellen:** torens en eenheden zijn fantasy-gebouwen en -figuren met echte textuur en schaduw, geen kleurvlakken
- **Lichtpilaren en gloed** als markering (blauwe stralen bij spawnpunten) en een schip als doel

## Wat wij nu doen (versie 3)

| Origineel | Onze nabootsing |
|---|---|
| Donkere void | Schermachtergrond en buitenvlak bijna zwart-marineblauw, vignet en koude belichting met tonemapping en een zachte gloed |
| Glanzend ijs met barsten | Terrein-shader (`TERRAIN_SHADER` in `client/world_view.gd`): turkoois ijs met fbm-ruis, aderen, lage ruwheid zodat het glanst |
| Donkere bouwplaten met raster | Zelfde shader: leisteenblauwe platen met een tegelraster, en een fijner celraster dat oplicht tijdens het bouwen |
| IJskliffen | Gekantelde, blauwe ijsblokken langs de rand (MultiMesh) en donkere sneeuwbomen uit de Kenney-set |
| Gedetailleerde torens | KayKit Medieval Hexagon torens (steen, dakbedekking, hout) in vier kleurvarianten, met een eigen kleurtint en gloeiend accent per element, uitgebreid met het tier-model |
| Gedetailleerde eenheden | KayKit-figuren (skeletten, ridders, barbaren, magiërs) en de dieren van de Everything Library, met kleurtint, schaal en looptekening, en dynamische schaduwen |

## Wat we niet kunnen evenaren

Een eigen kunstenaar voor modellen met geschilderde texturen, normal maps en unieke animaties per eenheid. De assets die we mogen gebruiken (CC0 en CC BY) zijn stilistisch niet hetzelfde als die van Blizzard: de KayKit-figuren zijn "chibi" en de dieren zijn realistischer. De donkere belichting, tinten en gloed houden dat bij elkaar, maar een echte eigen artstijl (concept art en eigen modellen) is de volgende stap als we productiekwaliteit willen.
