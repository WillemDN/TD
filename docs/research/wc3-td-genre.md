# Warcraft III tower defense: het genre en zijn varianten

> Referentiemateriaal voor gamedesign (onderzoek van 2026-10-22). Het is gebaseerd op webbronnen die vaak
> schaars of verouderd zijn. Wat niet gevonden is, staat expliciet onder "Niet gevonden". Verzin geen getallen
> bij die gaten: ontwerp ze zelf en leg ze vast in `docs/design/`.

## 1. Korte geschiedenis

- **StarCraft: Brood War (2000–2001):** de eerste custom-TD's (*Turret Defense*, *Sunken Defense*).
- **Warcraft III (2002):** de World Editor maakte het genre groot. *The Frozen Throne* (2003) had zelfs een geheim TD-scenario.
- **Wintermaul** (Duke-Wintermaul): coöperatief, een maze bouwen in een open veld. Daaruit groeide **Wintermaul Wars**
  (rond 2004), met *sends* en een tegenstander. De competitieve community koos **x14.2** (Aphotica) als standaard.
- **Element TD** en **Gem TD** verschenen in februari 2006. Element TD kwam later ook naar StarCraft 2 (2011), Dota 2 en
  mobiel (2016), en als standalone *Element TD 2* (early access 2020, release 2021).
- Daarna volgden tientallen afgeleiden: *Line Tower Wars*, *Green Circle TD*, *Wintermaul One*, *Wintermaul Redux* en meer.

## 2. De subgenres die voor Guardians relevant zijn

| Subgenre | Voorbeeld | Kern | Relevantie voor Guardians |
|---|---|---|---|
| **Coöperatieve maze-TD** | Wintermaul v13, Wintermaul X10 (72 torens, 30 levels) | Team bouwt samen een maze, gedeelde levens, vaste waves | **Modus Klassiek** (al uitgewerkt in `wintermaul-v13-data.md`) |
| **Maze-TD met upgrades en races** | Wintermaul One (49 races, 40 waves), Redux | Torens upgraden, per ras een stijl | **Modus Modern** |
| **Sending-TD (PvP)** | Wintermaul Wars, Line Tower Wars | Goud kopen of sends, creeps naar de tegenstander sturen, income | Latere variant 1 (**Wintermaul Wars**) |
| **Element/mix-TD** | Element TD | Elementen met een cirkel van sterk/zwak, gecombineerde torens | Inspiratie voor de element-vs-armor-matrix |
| **Willekeur-TD** | Gem TD | Willekeurige gems plaatsen, één houden, de rest wordt muur, combineren | Mogelijke latere variant |

## 3. Wintermaul Wars: wat we met zekerheid weten

Bron: [Maul Tactics-artikel](https://maultactics.gg/articles/wintermaul-wars-history) (geschreven door de maker van een
opvolger, dus met een promotionele toon) en [Hive Workshop](https://www.hiveworkshop.com/).

- **Sends:** met goud stuur je creeps naar de tegenstander. Sturen verhoogt ook **je eigen income** voor de rest van de
  match. De kernspanning is **income tegenover verdediging**.
- **Income:** komt op een timer. Spelers wegen "nu torens kopen" tegen "sparen voor het volgende income-niveau".
- **Anti-blocking:** het pad mag nooit volledig dichtgebouwd worden. Of de plaatsing wordt geweigerd, of er opent een
  override-route. Dit bevestigt onze keuze voor een anti-block-check bij het plaatsen.
- **Levens:** elke creep die doorkomt kost een leven. In teammodi gelden lekken voor het hele team.
- **Gold gate:** sommige versies hadden een verplicht waypoint waar sterke spelers als eerste om vochten.
- **Teamformaten:** 1v1, 2v2, 3v3. In 3v3 neemt één speler vaak de rol van "held" (call de sends, pool goud).
- **Strategie uit de WmW-gids** ([wmwl.weebly.com](http://wmwl.weebly.com/wmw-guide.html)), bruikbaar als balansidee:
  - Rassen zijn verdeeld in **grond-verdediging (AG)** en **lucht-verdediging (AA)**. Lucht negeert de maze, dus AA moet bij het schip staan.
  - Typische maze: een *half-box* of heen-en-weer-maze. Gif-torens achteraan vertragen luchtgroepen zodat splash raakt.
  - Een *shrine*-upgrade (Shrine 2) ontgrendelt sterkere creeps om te sturen, meestal bij een income rond 700 (1v1) of 1000–2000 (2v2).
  - Stuur eerst grond, dan lucht, en spreid luchtsends zodat ze niet stapelen. "Never fall behind on income" geldt in 1v1 als wet.
  - Goedkope rassen (Electric, Earth) zijn sterk in het begin, duurdere rassen schalen beter.
- **Varianten van de map:** x14.2 (competitief), PE, Evolution, Redux, Crystal, "The Next Generation" en meer.
  Ze verschillen vooral in rassen en balans, niet in het basisprincipe.

## 4. Wintermaul-varianten die ideeën opleveren

| Variant | Wat het toevoegt | Bron |
|---|---|---|
| **Wintermaul X10** | 72 torens, 30 levels, 9 spawnpunten, upgrade-bomen | [EpicWar](https://www.epicwar.com/maps/2824/) |
| **Wintermaul One Revolution** | 49 rassen met eigen moeilijkheid, 40 waves, 6 modi: *all random*, *all random double*, *all the same constructor*, *all pick*, *all pick double*, *infinite waves* | [wintermaul.one](https://wintermaul.one/) |
| **Arcanum-ras (One v1.5)** | Torens hebben **mana** nodig om te schieten. Een toren zonder mana vuurt niet | [wintermaul.one](https://wintermaul.one/) |
| **Wintermaul Redux 1.08g** | **Armortype wisselt elke 5 levels** (cyclus Fortified → Medium → Unarmored → Heavy → Light), dus de typering van je torens doet ertoe. Verspreide creeps starten onkwetsbaar en bewegingsloos en worden pas kwetsbaar als ze lopen. **Collectieve bounty**: als één speler een kill maakt, krijgen alle spelers goud. `-repick`. Repareerbare torens, Bank Tower voor goudbonus | [Hive Workshop](https://www.hiveworkshop.com/threads/wintermaul-redux-1-08g.121401/) |
| **WMW Evolution 1.03** | `-noair`: lucht-sends uitzetten. **Torenlimiet (200) via "food"** tegen lag. Creeps onkwetsbaar en sneller in het middengebied. Kritiek: income-intervallen te lang, geef kleinere en vaker uitbetaling | [Hive Workshop](https://www.hiveworkshop.com/threads/wmw-evolution-v1-03.277090/) |
| **X14 Balanced** | Dubbel startgeld, 7 spawnpunten, 30 levels, 60+ torens | [EpicWar](https://www.epicwar.com/maps/11846/) |

## 5. Element TD: de elementencirkel

Uit de [Basics of Element TD](https://forums.eletd.com/topic/945-basics-of-element-td) (community-gids van 2008).
Elk element doet **200%** schade aan het volgende en **50%** aan het vorige in de cirkel:

`Licht → Duisternis → Water → Vuur → Natuur → Aarde → Licht`

- **Torens zijn damage of support.** Support: AoE-slows, armor-reductie (AoE of single-target), schadeversterking, aanvalssnelheid- of schadebuff voor 4 torens, en een kloon-toren.
- **Creepsoorten** (handig voor onze eigen creep-eigenschappen): *Fast* (+25% snelheid), *Healing* (bij sterven 20% HP herstel aan creeps binnen een straal), *Mechanical* (3 s onkwetsbaar elke 12 s), *Undead* (staat 5 s na de dood op met 33% HP, één keer).
- **Gemengde torens:** schade wordt gewogen over de elementen van een creep. Een tweede element maakt een toren veelzijdiger maar minder extreem.
- **Clumping:** AoE-slows laten creeps samenklonteren, wat splash sterker maakt. Dat is dezelfde kern als de Ice-en-Fire-combinatie in Wintermaul.
- **Spelen met wisselende pas-lengtes:** korte, lange en meerdere passes bepalen waar je splash neerzet.

## 6. Line Tower Wars

Bron: [GIGA](https://www.giga.de/tipp/die-beliebtesten-tower-defense-maps-im-ueberblick-warcraft-3-reforged/) en een
Steam-remake. Elke speler verdedigt zijn eigen lane. **Verstuurde creeps slaan jouw lane over en lopen door de lanes van
de anderen.** Als jouw creep de verdediging van een ander doorbreekt, verliest die een leven en win jij er één. Goud gaat naar
torens óf sends. De games kunnen erg lang duren, dus een timer of bonusregel helpt.

## 7. Gem TD

Bron: remakes zoals [Gemaze TD](https://www.moddb.com/games/gemaze-td). Elke ronde plaats je meerdere willekeurige gems met
een kwaliteit. Je **houdt er één**, de rest wordt een **muur** (blokkade), dus het maze-bouwen en het kiezen zijn verweven.
Drie verschillende gems vormen samen een recept en worden één sterkere gem. Gelijke gems kunnen in kwaliteit stijgen.
Dit past bij "variant, later", niet bij Klassiek.

## 8. Wat dit betekent voor Guardians

1. **Armortype laten rouleren.** De Redux-regel (elke 5 levels een ander armortype) is een goedkope manier om van
   "bouw maar één element" naar "bouw een gemengd team" te gaan. Past in **Modern**, in Klassiek niet.
2. **Collectieve bounty** past bij co-op en voorkomt ruzie over wie de kill krijgt (Redux). Voorstel voor **Modern**.
3. **Torenlimiet** (Evolution: 200) is nuttig tegen performanceproblemen op een gsm. Ook de sim wint erbij.
4. **Lucht en hover** moeten apart gedekt worden (AA-rassen in WmW). Onze wave-tabel heeft dat al (levels 5/15/25/29).
5. **Creepeigenschappen** (Fast, Healing, Mechanical, Undead) uit Element TD geven goedkope variatie voor **Modern**,
   zonder nieuwe modellen. Klassiek houdt de originele waves.
6. **Sends en income** (Wintermaul Wars, Line Tower Wars) bewaren we voor variant 1. Het ontwerp-inzicht:
   *income opnieuw uitkeren op korte, vaste intervallen* (Evolution-kritiek) is prettiger op mobiel dan lange wachttijden.
7. **Teamrollen** (3v3-gids): één speler die sends "called" past bij onze 1–4 co-op, als simpele chatknop of ping.

## 9. Niet gevonden

De zoekopdrachten leverden **geen betrouwbare** gegevens op voor:

- exacte Wintermaul Wars x14.2-waarden: startgoud, levens, send-kosten, income-tabel, rassenlijst en wave-aantal;
- de volledige tower- en race-lijsten van Wintermaul One, Redux en Evolution;
- de originele Gem TD-receptentabel en kwaliteitskansen;
- de armor-vs-attack-tabel van Wintermaul Wars (alleen de Redux-armorcyclus is bekend).

Deze waarden hebben we niet nodig voor fase 1 (Klassiek is volledig gedekt door `wintermaul-v13-data.md`). Voor de
variant *Wintermaul Wars* moeten we later de x14.2-map zelf uitlezen met `tools/w3x-extract/` (de download staat op
[EpicWar](https://www.epicwar.com/maps/223952/)), zoals we eerder met v13 deden.

## Bronnen

- [Maul Tactics: Wintermaul Wars history](https://maultactics.gg/articles/wintermaul-wars-history)
- [WmW-gids (wmwl.weebly.com)](http://wmwl.weebly.com/wmw-guide.html)
- [Wintermaul One Revolution](https://wintermaul.one/)
- [Wintermaul Redux 1.08g (Hive)](https://www.hiveworkshop.com/threads/wintermaul-redux-1-08g.121401/)
- [WMW Evolution 1.03 (Hive)](https://www.hiveworkshop.com/threads/wmw-evolution-v1-03.277090/)
- [Wintermaul X10 (EpicWar)](https://www.epicwar.com/maps/2824/) en [X14 Balanced](https://www.epicwar.com/maps/11846/)
- [Basics of Element TD](https://forums.eletd.com/topic/945-basics-of-element-td)
- [GIGA: populaire TD-maps](https://www.giga.de/tipp/die-beliebtesten-tower-defense-maps-im-ueberblick-warcraft-3-reforged/)
- [Gemaze TD (ModDB)](https://www.moddb.com/games/gemaze-td)
- [Tower defense (Wikipedia)](https://en.wikipedia.org/wiki/Tower_defense)
