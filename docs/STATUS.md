# Status en logboek

> Werk dit bestand bij aan het einde van elke sessie: wat is er gedaan, wat staat er klaar, wat is de volgende stap.

## Huidige fase

**Eerste speelbare versie (browser) staat.** Fase 0 is afgerond (op `sudo pmset -a autorestart 1` na), fase 1 (data en design) is gedaan voor de modus Klassiek en fase 2 (headless simulatie + tests) en een greybox-client (fase 3, browser) zijn er in een eerste vorm.

### Speel het nu

- **Op de Mac / telefoon (Tailscale):** <https://willems-macbook-pro.tail868144.ts.net:8443/> (alleen binnen je tailnet, vraagt HTTPS: Godot-web start niet via gewone `http://` op een niet-lokaal adres)
- De server is `python3 server-mac/serve_web.py` op `127.0.0.1:8060`, gepubliceerd met `tailscale serve --bg --https=8443 http://127.0.0.1:8060`. Poort 443 en 10000 worden al door andere services gebruikt, laat die staan. Uitzetten: `tailscale serve --https=8443 off`
- **Opnieuw bouwen:** `tools/build_web.sh` (draait eerst alle tests, exporteert daarna naar `game/build/web`). Herladen in de browser volstaat (geen cache)
- **Tests:** `godot --headless --path game --script res://tests/run_tests.gd` (355 checks)
- **Screenshots van het echte venster:** `godot --path game --rendering-driver opengl3 --script res://tests/screenshot_runner.gd -- <map> [phone]`

### Wat erin zit

- Modus **Klassiek**, 1 speler, 35 levels met eindbazen op 10/20/30 en luchtlevels, moeilijkheid Makkelijk/Normaal/Moeilijk/Perfectie
- 9 elementen (46 torens) + de ultieme toren, eigen NL/EN-namen, effecten: slow, poison, crit, chain, bounce, armor-debuff, %-HP, zet-HP, vasthouden, bonusschade
- Kaart "Vrieslijn" met 3 lanes en een gedeeld bouwveld, flow-field-pathing, **anti-block** (plaatsingen die het pad sluiten worden geweigerd) en pad-preview met padlengte
- Bouwen met muis of aanraking (twee stappen: tik om de ghost te zetten, tik nogmaals of "Bouw hier"), pannen, zoomen (wiel of knijpen), sneltoetsen Q-Y, S, spatie, P, 1-3
- NL/EN, snelheid x1/x2/x4, pauze, "Start nu" met kleine goudbonus, verkopen (100% buiten de wave, 75% tijdens)
- Alles data-gedreven uit `game/data/*.json`, simulatie in `game/core/` zonder nodes, deterministisch met een seeded RNG

### Bekende beperkingen (eerlijk)

- **Balans is voorlopig.** De solo-boost (3x startgoud, 1,5x bonus en bounty) en alle effectwaarden zijn gokken (zie `docs/design/schade-namen-kaart.md`). Een simpele bot zonder maze haalt level 3-11, afhankelijk van het element
- Geen drag-to-wall, geen upgrade-bomen (modus Modern), geen multiplayer, geen accounts, geen geluid, geen echte art (alleen vormen en kleuren)
- Het Schaduw-altaar (zware vliegende eenheid) uit het origineel is nog niet gemaakt
- Alleen getest in Chrome (headless en venster). De telefoon is door de eigenaar zelf te testen

## Beslissingen (22-10-2026)

| Onderwerp | Beslissing |
|---|---|
| Naam | **Guardians** |
| Thema | **Winter/ijs**: de Guardians verdedigen het schip tegen de noordelijke horden. Latere varianten krijgen een eigen thema |
| Platformen | **Android** (APK via een downloadlink) + **browser** (Godot web-build, gehost op de Mac) |
| Engine | **Godot 4** (laatste stabiele versie) + **GDScript**, Compatibility-renderer op alle platformen |
| Stijl | **3D low-poly**, isometrische camera, CC0-assets (Kenney, Quaternius, KayKit) |
| Spelers | **1–4 co-op** per match |
| Modi | **Klassiek** (exact Wintermaul v13) + **Modern** (upgrade-bomen, gebruiksgemak) |
| Taal | **NL + EN** (i18n vanaf het begin) |
| Netwerk | Server-authoritative, **WebSocket over TLS** via `tailscale serve`, server op de MacBook |
| Accounts | **Accounts met voortgang** (SQLite op de Mac), hervatbare matches |
| Server | MacBook **altijd aan** op netstroom |
| Commercieel | **Nee**. Het Tailscale Personal-plan volstaat |
| Varianten | 1. **Wintermaul Wars**, 2. **NOOB Killer TD**, daarna andere WC3-TD's |

## Open vragen (blokkeren de start niet)

- [ ] Welke versie van NOOB Killer TD speelde je? Geanalyseerd is v1.8c, er bestaat ook een v1.8d (2024)
- [ ] Welke andere WC3-TD's wil je terugzien, en in welke volgorde?
- [ ] Toegang voor vrienden: voorstel is **node sharing** (alleen de Mac delen). Nog bevestigen in fase 5

## Mac-gegevens

Uitgelezen op 2026-10-22.

| | |
|---|---|
| Model / chip | MacBook Pro (MacBookPro17,1), Apple M1, 16 GB, arm64 |
| macOS | 14.8.3 (23J220) |
| Godot | 4.7.2.stable (`/opt/homebrew/bin/godot`), export templates 4.7.2.stable aanwezig |
| JDK | Temurin 17.0.20.1 (`~/Library/Java/JavaVirtualMachines/temurin-17.jdk`, `JAVA_HOME` staat goed) |
| Android SDK / build-tools | `~/Library/Android/sdk`: build-tools 35.0.1 en 36.1.0, platforms android-35 en android-36, cmdline-tools, platform-tools (adb), NDK |
| Tailscale | Mac `willems-macbook-pro` (100.66.207.18), tailnet `tail868144.ts.net`, volledige naam **`willems-macbook-pro.tail868144.ts.net`**, HTTPS-certificaten beschikbaar. Telefoon `pixel-9-pro` staat in het tailnet |
| Python | 3.9.12, zonder Pillow en mpyq (alleen nodig voor `tools/w3x-extract`) |

### Nog open in fase 0

- [ ] `gh` 2.103.0 is geïnstalleerd (Homebrew). Inloggen met `gh auth login` moet nog: de device-code invoeren op <https://github.com/login/device>
- [x] Tailscale-naam blijft `willems-macbook-pro` (beslist 2026-10-22), docs zijn aangepast
- [ ] `sudo pmset -a autorestart 1` (staat nu niet aan). Claude Code kan dit niet zelf, want `sudo` vraagt een wachtwoord. Slapen staat al op 0 voor netstroom
- [x] Telefoon wordt niet gekoppeld (beslist 2026-10-22): Claude Code test alles lokaal, jij test zelf op de telefoon
- [ ] Een lege test-export naar APK om Godot ↔ Android te bevestigen (komt in fase 2/3 vanzelf mee)
- [ ] Optioneel: `pip install pillow` en `mpyq` als we de extractiescripts opnieuw willen draaien

## Logboek

### 2026-10-22: analyse en plan (cloud-sessie)
- Wintermaul TD v13.0 Final gedownload en uitgepakt: waves, torens, elementen, regels en kaartlayout → `docs/research/wintermaul-v13-data.md`
- NOOB Killer TD v1.8c verkend → `docs/research/noob-killer-td.md`
- Plan en architectuur → `docs/PLAN.md`, Mac-setup → `docs/SETUP-MAC.md`, context voor Claude Code → `CLAUDE.md`
- Extractiescripts → `tools/w3x-extract/`

### 2026-10-22: eerste speelbare versie
- Data-pipeline: `tools/import_wintermaul.py` + `tools/import_overlay.py` (eigen namen NL/EN, effectparameters) → `game/data/{towers,creeps,waves_classic}.json`, matrix, regels en kaart (`tools/gen_map.py`). Ontwerpdocument wordt gegenereerd (`tools/gen_design_doc.py` → `docs/design/schade-namen-kaart.md`)
- Godot-project `game/`: `core/` (grid met flow field en anti-block, simulatie, data), `client/` (3D-weergave, HUD, overlay, main), `tests/` (355 headless checks, bot, screenshot-runner)
- Kaartontwerp aangepast tijdens het testen: een bot liet zien dat drie losse lanes voor een solospeler te veel werk zijn, daarom komen alle lanes samen in een gedeeld bouwveld
- Webexport (`game/export_presets.cfg`, single-threaded) en `tailscale serve` op poort 8443. Getest in Chrome via het DevTools-protocol: laden, spelen, bouwen en een wave

### 2026-10-22: sessie op de Mac
- Fase 0 gecontroleerd en Mac-gegevens vastgelegd, `gh` geïnstalleerd
- Beslissingen: Tailscale-naam blijft `willems-macbook-pro`, telefoon niet koppelen (lokaal testen, de eigenaar test zelf op de telefoon)
- v13-map opnieuw gedownload (inclusief wave-script) en de standaard WC3-tabellen opgehaald: alle gaten (`~`) in torens en creeps zijn ingevuld → `docs/research/wintermaul-v13-resolved.md` en `data/wintermaul-v13-resolved.json`. Nieuwe tools: `slk.py`, `resolve.py`, `report.py`. Het eerste dataverslag bleek enkele fouten te hebben (aanvalstypes, splash), die zijn gecorrigeerd
- Wintermaul Wars x14.2 gedownload ([EpicWar](https://www.epicwar.com/maps/223952/)): de map is beschermd (versleutelde scripts en geen leesbare `.w3u`), dus nog niet uitgelezen. Dat vraagt een uitgebreidere MPQ-lezer
- Genre-onderzoek naar WC3-TD's → `docs/research/wc3-td-genre.md` (met lijst van wat niet te vinden was)

## Volgende stappen

1. **Jij:** speel het op de telefoon en geef feedback: voelt het bouwen goed, is de balans te zwaar of te makkelijk, wat ontbreekt?
2. **Jij:** `sudo pmset -a autorestart 1` en zet de webserver desgewenst als LaunchAgent aan (Claude Code kan dat op verzoek maken)
3. **Balans:** abilities uit `war3map.w3a` lezen (echte slow/crit/chain-waarden), een betere bot met maze, balans-sims per element en de solo-boost bijstellen
4. **Bouw-UX:** drag-to-wall, doelprioriteit per toren, undo, tutorial-tips
5. **Modern-modus:** upgrade-bomen, collectieve bounty, wisselend armortype (zie `docs/research/wc3-td-genre.md`)
6. **Multiplayer (fase 4/5):** server-authoritative over WebSocket, accounts en lobby
7. **Art en audio (fase 6):** CC0-modellen en geluiden, VFX
