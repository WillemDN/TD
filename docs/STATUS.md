# Status en logboek

> Werk dit bestand bij aan het einde van elke sessie: wat is er gedaan, wat staat er klaar, wat is de volgende stap.

## Huidige fase

**Fase 0: setup van de Mac** is grotendeels klaar (zie "Mac-gegevens" en "Nog open in fase 0"). **Fase 1 (data en design)** is gestart.

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

### 2026-10-22: sessie op de Mac
- Fase 0 gecontroleerd en Mac-gegevens vastgelegd, `gh` geïnstalleerd
- Beslissingen: Tailscale-naam blijft `willems-macbook-pro`, telefoon niet koppelen (lokaal testen, de eigenaar test zelf op de telefoon)
- Genre-onderzoek naar WC3-TD's → `docs/research/wc3-td-genre.md` (met lijst van wat niet te vinden was)

## Volgende stappen

1. Fase 0 volgens `SETUP-MAC.md`, daarna deze status bijwerken met de Mac-gegevens
2. Fase 1: `tools/import_wintermaul.py` (v13-data → `game/data/*.json`), eigen namen, element-vs-armor-matrix en kaartontwerp
3. Fase 2: het Godot-project `game/` met een headless kernsimulatie en tests
