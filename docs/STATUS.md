# Status en logboek

> Werk dit bestand bij aan het einde van elke sessie: wat is er gedaan, wat staat er klaar, wat is de volgende stap.

## Huidige fase

**Fase 0: setup van de Mac**. Nog niet gestart. Volg [`SETUP-MAC.md`](SETUP-MAC.md).

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

_In te vullen in fase 0 (model, chip, macOS-versie, RAM, versies van Godot, JDK en Android SDK)._

| | |
|---|---|
| Model / chip | |
| macOS | |
| Godot | |
| JDK | |
| Android SDK / build-tools | |
| Tailscale-naam | `guardians.<tailnet>.ts.net` |

## Logboek

### 2026-10-22: analyse en plan (cloud-sessie)
- Wintermaul TD v13.0 Final gedownload en uitgepakt: waves, torens, elementen, regels en kaartlayout → `docs/research/wintermaul-v13-data.md`
- NOOB Killer TD v1.8c verkend → `docs/research/noob-killer-td.md`
- Plan en architectuur → `docs/PLAN.md`, Mac-setup → `docs/SETUP-MAC.md`, context voor Claude Code → `CLAUDE.md`
- Extractiescripts → `tools/w3x-extract/`

## Volgende stappen

1. Fase 0 volgens `SETUP-MAC.md`, daarna deze status bijwerken met de Mac-gegevens
2. Fase 1: `tools/import_wintermaul.py` (v13-data → `game/data/*.json`), eigen namen, element-vs-armor-matrix en kaartontwerp
3. Fase 2: het Godot-project `game/` met een headless kernsimulatie en tests
