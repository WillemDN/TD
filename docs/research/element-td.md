# Element TD: onderzoek voor de modus Elementen

> Onderzocht op 2026-10-22. De pagina die de eigenaar noemde (<https://wc3maps.com/map/353102/Element_TD_4.3e>) gaf bij het ophalen
> **HTTP 403**, dus de kaart zelf is niet ingezien en er is **niets uit de map gehaald** (geen extractie, geen assets, geen tabellen).
> Alles hieronder komt uit publieke forum- en patchnotes van de community. De waarden in onze modus zijn **eigen ontwerp**
> (`docs/design/elementen-modus.md`); we kopiëren geen namen, getallen of teksten van de map (zie CLAUDE.md, juridisch).

## Wat Element TD is (volgens de bronnen)

- **Vast pad, geen maze.** De creeps volgen een vaste route van spawn naar einde. Je kunt ze niet omleiden, je mag alleen op
  aangewezen plekken bouwen. Dat is het grote verschil met Wintermaul en de reden dat het **solo speelbaar** is.
- **Zes elementen in een cirkel:** Licht → Duisternis → Water → Vuur → Natuur → Aarde → Licht. Een element doet **200%** schade aan het
  volgende en **50%** aan het vorige; de rest 100% ([Basics of Element TD](https://forums.eletd.com/topic/945-basics-of-element-td)).
- **Creeps hebben een element** (hun "pantser"), per level anders. Je moet je torens dus mengen of omschakelen.
- **Torens:** 6 enkelvoudige elementen (met 3 niveaus), 15 duo-torens, 20 trio-torens. Bij een mengtoren wordt de schade gewogen over
  de elementen. Daarnaast support-torens (AoE-slow, pantserreductie, schadeversterking).
- **Elementen krijg je door Guardians te verslaan** (elke 5 levels een eindbaas); daarmee ontgrendel je elementen en hogere niveaus
  ([Survivor 4.3b](https://www.hiveworkshop.com/threads/element-td-survivor-4-3b.125024/)).
- **Rente:** elke 15 s krijg je 2% over je ongebruikte goud ([Survivor 4.3b](https://www.hiveworkshop.com/threads/element-td-survivor-4-3b.125024/)).
- **Lekken:** een doorgelekte creep verschijnt opnieuw aan het begin van het pad.
- **Bounty:** `base^(level-1)`, met een basis die per moeilijkheid verschilt (1,0925 tot 1,1) ([4.3-changelog](https://forums.eletd.com/topic/2044-element-td-43/)).
- **Creepeigenschappen:** *Fast* (sneller), *Healing* (geneest buren bij de dood), *Mechanical* (periodiek onkwetsbaar), *Undead* (staat één keer
  op), *Image* (kopie bij schade). Zie [Basics](https://forums.eletd.com/topic/945-basics-of-element-td) en de 4.3-changelog.
- **60 levels** in de bronnen die we vonden; 30 creeps per wave; 40 levels in de versie die de eigenaar noemt is **niet bevestigd**.
- Niet gevonden: de tabel met HP en pantser per level, torenstatistieken en prijzen. Die zijn dus ook niet gebruikt.

## Wat we overnemen (de ideeën) en wat niet

| Idee | Onze versie |
|---|---|
| Vast pad met bouwplekken | Kaart "Elementenpad": een slingerpad van ~130 tegels met **bouwplaten** (`o`) ernaast. Platen zijn bouwbaar maar nooit loopbaar |
| 6 elementen, 200% / 50% | Zelfde cirkel, eigen namen (Licht, Duisternis, Water, Vuur, Natuur, Aarde) |
| Enkel-, duo- en trio-torens | 18 enkele (3 niveaus), 15 duo's, 20 trio's, allemaal door `tools/gen_elements.py` gegenereerd met eigen namen en waarden |
| Guardians geven elementen | Elke 5e level is een Guardian; daarna +1 hout = een nieuw element leren |
| Rente | 2% per 15 s |
| Creepeigenschappen | Snel, Helend, Onsterfelijk, Gepantserd (de vier uit de bronnen, met eigen waarden). *Image* laten we weg |
| Lekken komen terug | `leakRespawn`: de creep begint opnieuw en kost bij elke ronde een leven |
| Builder-wapens, multiplayer-income, Ronald | Niet overgenomen |

## Bronnen

- [Basics of Element TD](https://forums.eletd.com/topic/945-basics-of-element-td) (community-gids, 4.0-tijdperk)
- [Element TD 4.3 changelog](https://forums.eletd.com/topic/2044-element-td-43/) (14-05-2010)
- [Full data on creep waves](https://forums.eletd.com/topic/1532-full-data-on-creep-waves/) (alleen 30 creeps, snelheid 300 en de bounty-formule)
- [Element TD Survivor 4.3b](https://www.hiveworkshop.com/threads/element-td-survivor-4-3b.125024/) (Hive Workshop)
