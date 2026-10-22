# Credits

## Externe assets

| Bestanden | Bron | Licentie |
|---|---|---|
| `assets/kaykit/towers/*`: de torens (4 kleurvarianten van Tower A, B, base en catapult) en de bouwfases | **KayKit Medieval Hexagon Pack 1.0** van Kay Lousberg, <https://kaylousberg.com> | **CC0** (`assets/kaykit/LICENSE-medieval-hexagon.txt`) |
| `assets/kaykit/chars/*.scn`: Barbarian, Knight, Mage, Rogue, Rogue Hooded, Skeleton Warrior, Mage, Minion, Rogue (met alleen de animaties die we gebruiken, zie `tools/kaykit/slim.gd`) | **KayKit Character Pack: Adventurers 1.0** en **Skeletons 1.0** | **CC0** (`assets/kaykit/LICENSE-adventurers.txt`, `LICENSE-skeletons.txt`) |
| `assets/creatures/*.glb` (rat, panter, bizon, neushoorn, gorilla/yeti, hagedis, spin, kever, vleermuis, wisp, gier, havik, kraai): de dieren | **Everything Library: Animals 0.2** door **David OReilly**, <http://davidoreilly.com/library>. Het skelet, de animaties en het geschilderde oppervlak zijn gemaakt in het project WDungeoN van dezelfde eigenaar | **CC BY 4.0**: vermelding verplicht, die staat in het titelmenu van het spel (`assets/creatures/LICENSE-EverythingLibrary-Animals.txt`) |
| `assets/creatures/scrap_golem.glb`: het gouden/rammelende golem-model | afgeleid van **KayKit Dungeon Remastered** in het project WDungeoN | **CC0** (`assets/creatures/LICENSE-KayKit-Dungeon-Remastered.txt`) |
| `assets/kenney_td/*`: bomen, rotsen en kristallen voor het bos, spawn- en selectiemarkers | **Tower Defense Kit 2.1** van **Kenney**, <https://kenney.nl/assets/tower-defense-kit> | **CC0** (`assets/kenney_td/License.txt`) |

**Bewust niet gebruikt** uit WDungeoN: de wolf, beer en everzwijn (de licentie van het CraftPix-pakket is niet bevestigd), de weerwolf en weerbeer (Meshy/Hunyuan3D-licenties) en de grote bazen (Diablo-thema).

## Zelf gemaakt

- Het schip, de gloeiende accenten op de torens, de effecten en alle UI-iconen worden in code opgebouwd uit Godot-primitieven en vectorvormen. Vier monsters uit eerdere versies zijn als terugvaloptie nog procedureel (`client/models.gd`, `make_creep_procedural`).
- Het terrein (ijs, bouwplaten, tegelraster) is een shader (`client/world_view.gd`).
- Het icoon (`icon.svg`) is zelf getekend.
- Lettertype: het standaardlettertype dat met de Godot-engine meekomt (zie de licentiegegevens van Godot 4: <https://godotengine.org/license/>).
- Speldata: getallen en mechanieken zijn afgeleid van een Warcraft III-map, met eigen namen en zonder teksten, modellen, iconen of geluiden uit die map (zie `docs/PLAN.md` §3).

Zodra we CC0/CC-BY-assets toevoegen (Kenney, Quaternius, KayKit), komt elk bestand hier met zijn licentie en bron.
