# Guardians

Een moderne multiplayer tower defense voor **Android en de browser**, geïnspireerd op **Wintermaul** en andere
Warcraft III-tower defenses. De server draait op een MacBook en spelers verbinden via **Tailscale**.

- 🚦 **Status, beslissingen en volgende stappen:** [`docs/STATUS.md`](docs/STATUS.md)
- 📋 **Analyse en stappenplan:** [`docs/PLAN.md`](docs/PLAN.md)
- 💻 **Mac-setup (fase 0):** [`docs/SETUP-MAC.md`](docs/SETUP-MAC.md)
- 🤖 **Context voor Claude Code:** [`CLAUDE.md`](CLAUDE.md)
- 📊 **Originele Wintermaul-data** (waves, torens, regels): [`docs/research/wintermaul-v13-data.md`](docs/research/wintermaul-v13-data.md)
- 🎮 **WC3-TD-genre en varianten:** [`docs/research/wc3-td-genre.md`](docs/research/wc3-td-genre.md)
- 🧭 **Varianten voor later** (NOOB Killer TD en andere): [`docs/research/noob-killer-td.md`](docs/research/noob-killer-td.md)
- 🛠️ **Data-extractie uit WC3-maps:** [`tools/w3x-extract/`](tools/w3x-extract/)

## Speel de eerste versie

Binnen je tailnet (HTTPS vereist): <https://willems-macbook-pro.tail868144.ts.net:8443/>. Zie [`docs/STATUS.md`](docs/STATUS.md)
voor hoe je het bouwt en serveert, en voor de bekende beperkingen.

```sh
tools/build_web.sh                              # tests + webexport naar game/build/web
python3 server-mac/serve_web.py                 # serveert op 127.0.0.1:8060 (tailscale serve doet de HTTPS)
godot --headless --path game --script res://tests/run_tests.gd   # alleen de tests
```

Status: speelbare browserversie van de modus Klassiek (1 speler) met mobiele bediening en 3D-modellen. Ontwerp: [`docs/design/schade-namen-kaart.md`](docs/design/schade-namen-kaart.md) en [`docs/design/mobiele-ux-en-visuals.md`](docs/design/mobiele-ux-en-visuals.md). Onderzoek naar mobiele TD-bediening: [`docs/research/mobile-td-ux.md`](docs/research/mobile-td-ux.md).
