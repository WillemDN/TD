# Mobiele tower defense: bediening en camera (onderzoek)

> Onderzoek van 2026-10-22. De webbronnen waren dun: er is bijna geen echte UX-analyse van mobiele tower defense te vinden.
> Wat hieronder staat als bron is wat er gevonden is. De ontwerpregels onderaan zijn onze eigen conclusies, aangevuld met
> algemene kennis over touch-ontwerp en bekende spellen. Ze zijn dus een uitgangspunt dat we met speltests bijstellen.

## Wat de bronnen zeggen

- **Slepen uit een kaartenlade is de basis.** Een gangbare set gebaren: *sleep uit het koopmenu om te plaatsen, knijp om te zoomen, sleep om de camera te scrollen* (sjabloon-beschrijving op [Fab](https://www.fab.com/listings/557576ae-86b7-48d0-81d9-fe7114534970)). Bloons TD 6 laat torens uit een zijpaneel op de kaart slepen en opent na een tik op een geplaatste toren het upgrade-menu ([Steam-discussie](https://steamcommunity.com/app/960090/discussions/0/1638661595056416109)).
- **Plaatsen in drie stappen** (tik om te plaatsen, sleep om te positioneren, tik om te bevestigen) en knijpzoom voor fijn plaatsen, volgens een review van [Tridefense](https://www.appspy.com/reviews/tridefense-review/).
- **Valkuil: plaatsen bij touch-down.** Een ontwikkelaar beschrijft dat een toren meteen geplaatst werd zodra je het scherm aanraakte, waardoor je hem niet kon verslepen. Oplossing: eerst beweging vereisen ([itch.io-post](https://itch.io/post/15343934)).
- **Kleine doelen frustreren.** Een review meldt dat torens selecteren en verplaatsen op kleine schermen bijna onmogelijk werd door te kleine tikdoelen ([Corn Quest-review](https://www.appspy.com/corn-quest/review/)).
- **Zoom en overzicht.** Eén reviewer merkt op dat spelers meestal ver uitgezoomd spelen voor het overzicht, en een speler van een indiespel vraagt om een minimap en een bredere standaardcamera omdat oriëntatie lastig was.
- **Snap-to-grid.** Bij Bloons TD 6 klagen spelers over het ontbreken van snappen, wat plaatsen na verkopen frustrerend maakt. Wij snappen altijd op het grid.
- **Mindustry op mobiel:** een forumcommenter vindt de touchbediening van bouwspellen vaak matig, terwijl Kingdom Rush "touch om te bouwen of te verplaatsen" goed doet.

**Niet gevonden:** onderbouwde cijfers over duimzones, minimale tikgroottes of camerabegrenzing, en een echte analyse van de UI van Kingdom Rush, Plants vs. Zombies of Rush Royale.

## Ontwerpregels die wij daaruit trekken

| # | Regel | Reden |
|---|---|---|
| 1 | Alle tikdoelen minimaal 44 CSS-px (Apple HIG) tot 48 dp (Material), bij voorkeur groter voor veelgebruikte knoppen | Fitts' wet, vingers zijn onnauwkeurig. Tweede bron: de Corn Quest-klacht |
| 2 | **Nooit plaatsen bij touch-down.** Een tik zet een ghost, bevestigen kan met het vinkje. Slepen uit de lade plaatst bij loslaten | Zo kun je corrigeren en verplaatst een sleepgebaar niet per ongeluk iets |
| 3 | De ghost zweeft boven de vinger tijdens slepen | De vinger bedekt anders precies de plek die je wilt zien |
| 4 | Een toren oppakken met lang indrukken of slepen van een geselecteerde toren, plus een "Verplaats"-knop | Verplaatsen is een kernhandeling in een maze-spel, niet verstoppen in een menu |
| 5 | Het grid en de padlijnen alleen tonen tijdens bouwen | Rustig beeld, maar toch precisie wanneer het nodig is |
| 6 | Altijd een minimap en nooit de hele kaart tegelijk in beeld | Oriëntatie én spanning. De minimap toont monsters, torens en het zichtvenster |
| 7 | Bedieningselementen aan de randen (duimen), het midden vrij voor de kaart | Landscape: duimen liggen links en rechts onderin |
| 8 | Lade inklapbaar | Op een korte telefoonschermhoogte wil je soms alles zien |
| 9 | Eén grote uitleg-ruimte (infopaneel) in plaats van tooltips op hover | Hover bestaat niet op touch |
