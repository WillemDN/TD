# NOOB Killer TD en andere Warcraft III-TD's (varianten voor later)

> Status: eerste verkenning (22-10-2026). Een volledige data-extractie zoals bij Wintermaul volgt pas als we aan
> deze variant beginnen (fase 9).

## 1. NOOB Killer TD

| | |
|---|---|
| Map | *NOOB Killer TD* v1.8 (bestand `Noob Killer TD v 1.8c.w3m`) |
| Auteur | Tower_Mazer |
| Jaar | 2006. Er bestaat ook een v1.8d van maart 2024 |
| Download | <https://www.epicwar.com/maps/1550/> |
| Spelers | 8, elk met een eigen gebied |
| Torens | 69 ("69 Towers By: Tower_Mazer") |

### Wat we uit het mapbestand haalden

Het bestand is gedownload en met [`tools/w3x-extract/`](../../tools/w3x-extract/) uitgepakt. Uit de mapteksten en de triggernamen:

- **Eigen lane per speler**: per speler een spawnpunt en eigen regio's (*Player 1–8 Regions*, *Creature Spawning 1–8*)
- **Runners**: de creeps heten "runners". Het spel begint na 30 s en *"It starts off hard and stays hard"*
- **Killquota per wave**: na de start moet je **een minimum aantal kills per wave** halen ("you must get 10 kills a wave").
  Het quotum stijgt (onder meer bij de miniboss). Wie eronder zakt, ligt eruit: torens worden opgeblazen en het goud gaat naar 0
- **Weinig marge**: "You are allowed 1 leak a wave"
- **Builder-tech tree**: je bouwt gebouwen die betere "peons" (builders) maken, en die bouwen sterkere torens. Basistorens
  worden geüpgraded (Guard of Cannon), er is een aparte anti-air-builder en een "strongest towers"-builder
- **Torens met control-effecten**: web, ijsblok (freeze), bash/stun, slow, poison, critical strike, ketens (shackles), torens die je
  **manueel** moet activeren
- **PvP-element**: met een speciaal gebouw koop je units die **andere spelers aanvallen** ("Wont attack runners!")
- **Winnen**: als laatste overblijven. Daarnaast is er een "NOOb King"-uitdaging (10 zeer sterke units, één doden = overwinning)
- Verkopen via het commando `-sell`, scorebord met levens, overname van torens bij een disconnect
- Ongeveer 31 waves (Monster Array), met minibosses

### Wat dat betekent voor Guardians

| Mechaniek | Nodig in onze engine | Al voorzien? |
|---|---|---|
| Eigen lane per speler | Kaart met n gescheiden lanes, spawn per speler | Ja, ook nodig voor Wintermaul Wars |
| Killquota en eliminatie | Regelmodule "quota" + spectator-modus na eliminatie | Nieuw (klein) |
| Builder-tech tree | Upgradebare builders die torenlijsten vrijgeven | Gedeeltelijk (upgrade-bomen uit Modern) |
| Units kopen die spelers aanvallen | "Sends" naar een andere lane, units die torens aanvallen | Sends uit Wars, torens met HP is nieuw |
| Manueel te activeren torenvaardigheden | Actieve ability-knop op een toren met cooldown | Nieuw (UI + simulatie) |
| Free-for-all | Lobby-modus FFA (2–8 spelers) | Lobby uitbreiden |

## 2. Andere bekende Warcraft III-TD's

| Map | Kenmerk | Bron |
|---|---|---|
| **Wintermaul Wars** | PvP, creeps sturen voor income, mazing | <https://maultactics.gg/articles/wintermaul-wars-history> |
| **Element TD** | Elementen combineren tot duo- en trio-torens, de bekendste TD rond 2005 | <https://www.mobygames.com/game/143036/element-td-2/> |
| **Legion TD** | Units in plaats van torens, teams per lane (een van de meest gespeelde WC3-mods) | <https://rankedboost.com/warcraft-3/custom-maps/> |
| **Gem TD** | Willekeurige edelstenen, de rest wordt een muur | <https://rankedboost.com/warcraft-3/custom-maps/> |
| **Green (Circle) TD** | Ronde lanes, veel races | <https://games.softpedia.com/get/Shareware-Games/Warcraft-3-Map-Green-Circle-TD.shtml> |
| **Line Tower Wars** | Lanes naast elkaar, sends naar je buur | <https://rankedboost.com/warcraft-3/custom-maps/> |
| Castle Fight, Tropical Tower Wars, Mafa TD, Zoator TD | Zie de overzichtslijsten | <https://www.giga.de/tipp/die-beliebtesten-tower-defense-maps-im-ueberblick-warcraft-3-reforged/> |

Zoals bij Wintermaul nemen we enkel **mechanieken en getallen** over, met eigen namen en eigen art (zie `docs/PLAN.md` §3).
