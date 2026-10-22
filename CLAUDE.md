# CLAUDE.md: Guardians

Projectcontext voor Claude Code. Lees dit eerst, daarna `docs/STATUS.md`.

## Wat is dit project?

**Guardians** is een moderne multiplayer tower defense voor **Android en de browser**, gebaseerd op de Warcraft III-map
**Wintermaul TD** (en later andere WC3-TD's zoals Wintermaul Wars en NOOB Killer TD). De server draait op de MacBook
van de eigenaar (altijd aan) en spelers verbinden via **Tailscale**. Het project is niet commercieel.

## Belangrijkste documenten

| Bestand | Inhoud |
|---|---|
| `docs/STATUS.md` | **Huidige fase, beslissingen, open vragen en volgende stappen.** Bijwerken aan het einde van elke sessie |
| `docs/PLAN.md` | Volledige analyse, architectuur, Tailscale, assets, UX en stappenplan (fasen 0–9) |
| `docs/SETUP-MAC.md` | Installatie en configuratie van de Mac (fase 0) |
| `docs/research/wintermaul-v13-data.md` | Waves, torens, elementen en regels uit de originele map (de bron voor de modus Klassiek) |
| `docs/research/noob-killer-td.md` | Verkenning van varianten |
| `docs/research/wc3-td-genre.md` | Overzicht van WC3-TD-varianten, mechanieken en ontwerp-inzichten |
| `docs/research/data/*.json` | Ruwe unit-objectdata uit de WC3-maps |
| `tools/w3x-extract/` | Python-scripts om WC3-maps uit te lezen |

## Vaste beslissingen (niet opnieuw ter discussie stellen zonder de eigenaar)

- **Godot 4** (laatste stabiele versie), **GDScript**, **Compatibility-renderer** (nodig voor de web-export)
- **3D low-poly**, isometrische camera, **winterthema**
- **Server-authoritative** simulatie op een vaste tick (20 Hz). Clients sturen alleen commando's
- Tailscale-naam van de server: **`willems-macbook-pro.tail868144.ts.net`** (niet hernoemen)
- Transport **WebSocket** (`WebSocketMultiplayerPeer`). Server op `127.0.0.1:7777`, en `tailscale serve` levert HTTPS/`wss://` op `/ws`
- **Accounts** met voortgang in **SQLite** (godot-sqlite), wachtwoorden met PBKDF2-HMAC-SHA256
- **1–4 spelers** co-op, modi **Klassiek** en **Modern**, talen **NL + EN**
- Android-distributie via een **APK-downloadlink**. De browserversie wordt door de Mac zelf gehost
- **Data-gedreven**: torens, creeps, waves, elementen, kaarten en modi in `game/data/*.json`

## Werkafspraken

- **Taal:** documentatie in het **Nederlands**. Code, identifiers, code-commentaar en commit-berichten in het **Engels**.
  Teksten die de speler ziet, gaan via vertaalbestanden (NL + EN), nooit hardcoded
- **Juridisch:** **nooit** Warcraft III-assets (modellen, iconen, geluiden), de naam "Wintermaul" of teksten uit de maps
  in het spel opnemen. Mechanieken en getallen mogen wel, met eigen namen. Commit geen `.w3m`/`.w3x`-bestanden
- **Assets:** alleen CC0 of CC-BY, met elk bestand en zijn licentie in `game/CREDITS.md`
- **Simulatie** (`game/core/`) is puur GDScript zonder rendering of nodes van de scene tree, zodat ze headless
  testbaar is. Deterministisch met een seeded RNG
- **Tests:** elke nieuwe simulatieregel krijgt een headless test. Draai de tests vóór elke commit
- **Geheimen:** keystores, wachtwoorden en `.env` horen nooit in git (zie `.gitignore`)
- **Git:** werk op een feature-branch en push regelmatig. Commit-berichten in het Engels, kort en beschrijvend
- **Status:** werk `docs/STATUS.md` bij aan het einde van een sessie (wat gedaan, wat volgt)

## Structuur (grotendeels aangemaakt)

```
game/            Godot-project (client + server in één codebase)
  core/          simulatie: sim, grid, pathing (flow fields + anti-block), combat, economy
  net/           protocol, server, client
  client/        scènes, UI, camera, input, VFX, audio
  server/        accounts, lobby, rooms, persistentie, migraties
  data/          JSON-speldata
  tests/         headless tests + balance-sims
server-mac/      launchd-plists, deploy/back-up/admin-scripts, tailscale serve-config
web/             landingspagina (speel in de browser + APK-download)
tools/           w3x-extract, import- en balance-tools
```

## Commando's

```sh
godot --headless --path game --script res://tests/run_tests.gd    # alle headless tests, vóór elke commit
tools/build_web.sh                                                # tests + webexport (game/build/web)
python3 server-mac/serve_web.py                                   # serveert de webbuild op 127.0.0.1:8060
python3 -I tools/import_wintermaul.py                             # JSON-data opnieuw genereren uit het dataverslag
python3 -I tools/gen_map.py && python3 -I tools/gen_design_doc.py # kaart en ontwerpdocument
```

- Godot-web start alleen in een **secure context**: via `tailscale serve --https=8443 http://127.0.0.1:8060` (poort 443 en 10000 zijn door andere services bezet, niet overschrijven)
- Gebruik in GDScript `preload("res://...")` in plaats van `class_name`. Enige uitzondering is `UiKit` (`client/ui_kit.gd`), omdat de inner classes het nodig hebben. Draai na het toevoegen van een `class_name` eenmalig `godot --headless --path game --import`
- **Assets:** alleen CC0/CC-BY, elk bestand in `game/CREDITS.md`. De torenonderdelen komen uit `game/assets/kenney_td` (Kenney, CC0). Monsters en UI-iconen zijn in code getekend (`client/models.gd`, `client/ui_kit.gd`). Bekijk modellen met `tests/model_gallery.gd`
- Een UI-wijziging controleer je met `tests/screenshot_runner.gd` (echt venster, optioneel `phone` voor 844x390 met touch-UI)

## Volgende stap

Zie `docs/STATUS.md` → "Volgende stappen": speltests van de eigenaar op de telefoon, balans, bouw-UX en de modus Modern.
