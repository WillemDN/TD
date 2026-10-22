# Setup van de MacBook (fase 0)

Deze gids zet de MacBook klaar als **ontwikkelmachine** (Claude Code bouwt, test en exporteert hier) en als
**gameserver** (altijd aan, bereikbaar via Tailscale). Stappen met 👤 moet jij doen, omdat ze inloggen, een GUI of
toestemming vragen. Stappen met 🤖 kan Claude Code op de Mac uitvoeren, na jouw goedkeuring.

> Versies: kies telkens de **laatste stabiele** versie. Controleer bij Godot en Android in de officiële docs welke
> Android SDK-, build-tools- en JDK-versies de gekozen Godot-versie vraagt (links onderaan).

---

## Stap 1: Basis (👤, ±15 min)

1. **macOS bijwerken** (Systeeminstellingen → Algemeen → Software-update) en de Mac op netstroom zetten.
2. **Homebrew** installeren via <https://brew.sh/>:
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   Volg de instructies op het einde ("Next steps") om `brew` aan je `PATH` toe te voegen.
3. **Xcode Command Line Tools**: `xcode-select --install`. De volledige Xcode is niet nodig, want we bouwen niet voor iOS.
4. **Git en GitHub CLI**:
   ```sh
   brew install git gh
   gh auth login          # kies GitHub.com → HTTPS → inloggen via browser
   ```

## Stap 2: Claude Code (👤, ±5 min)

Installeer Claude Code volgens <https://code.claude.com/docs/en/setup>. Op het moment van schrijven gaat dat zo:

```sh
curl -fsSL https://claude.ai/install.sh | bash
```

Clone de repo en **check de werkbranch uit**:

```sh
mkdir -p ~/Developer && cd ~/Developer
gh repo clone WillemDN/TD
cd TD
git checkout claude/wintermaul-mobile-game-z9kc04   # tot deze branch in main is gemerged
claude                                              # start Claude Code in de repo
```

Claude Code leest dan automatisch [`CLAUDE.md`](../CLAUDE.md) in, met alle context en de volgende stappen.

## Stap 3: Ontwikkelsoftware (🤖 met jouw goedkeuring, ±30–60 min downloaden)

| Software | Commando | Controle |
|---|---|---|
| Godot 4 (editor + headless) | `brew install --cask godot` | `godot --version` (eventueel via `/Applications/Godot.app/Contents/MacOS/Godot`) |
| Godot export templates | In de editor: *Editor → Manage Export Templates → Download and Install*, of de `.tpz` van <https://godotengine.org/download/archive/> uitpakken naar `~/Library/Application Support/Godot/export_templates/<versie>/` | De map bestaat en heeft dezelfde versie als `godot --version` |
| JDK 17 | `brew install openjdk@17` | `/opt/homebrew/opt/openjdk@17/bin/java -version` |
| Android SDK | **Android Studio** (`brew install --cask android-studio`) → SDK Manager: *Platform-Tools*, *Build-Tools*, *Android Platform* en *Command-line Tools* (versies volgens de Godot-docs). Alternatief zonder Studio: `brew install --cask android-commandlinetools` + `sdkmanager` | `adb version` |
| Godot ↔ Android | Godot → *Editor Settings → Export → Android*: pad naar de Android SDK (meestal `~/Library/Android/sdk`) en de Java SDK (JDK 17) | Een lege test-export naar APK lukt |
| Python 3 + Pillow | `brew install python` en daarna `python3 -m pip install --user pillow` | `python3 -c "import PIL"` |
| mpyq (voor `tools/w3x-extract`) | Zie [`tools/w3x-extract/README.md`](../tools/w3x-extract/README.md) | |
| Blender (optioneel, assets) | `brew install --cask blender` | |
| SQLite CLI (back-ups) | Zit standaard in macOS (`sqlite3`) | `sqlite3 --version` |

**Mac-model:** Claude Code leest het model zelf uit met `sw_vers`, `uname -m` en `system_profiler SPHardwareDataType`, en
noteert het resultaat in `docs/STATUS.md`. Op Apple Silicon staat Homebrew in `/opt/homebrew`, op Intel in `/usr/local`.

## Stap 4: Android-telefoon koppelen (👤, ±5 min)

1. Telefoon: *Instellingen → Over de telefoon → Buildnummer* **7× tikken**. Dan verschijnen de "Ontwikkelaarsopties".
2. *Ontwikkelaarsopties* → **USB-foutopsporing** aan (of **Draadloze foutopsporing** en dan `adb pair <ip>:<poort>` op de Mac).
3. Telefoon met USB aan de Mac, "Deze computer vertrouwen" bevestigen.
4. Controle: `adb devices` toont het toestel als `device`.

## Stap 5: Tailscale (👤 inloggen, 🤖 configuratie)

1. Account aanmaken op <https://tailscale.com/> (gratis Personal-plan).
2. **Tailscale voor macOS**, de *standalone* versie omdat die de `tailscale`-CLI meelevert: <https://tailscale.com/download/mac>. Inloggen.
3. Admin-console <https://login.tailscale.com/admin>:
   - *DNS* → **MagicDNS** aan en **HTTPS Certificates** aan
   - *Machines* → de Mac **houdt zijn naam** `willems-macbook-pro` (beslissing 2026-10-22). Het adres is dus `willems-macbook-pro.tail868144.ts.net`
4. **Tailscale-app** op je Android-telefoon installeren en met hetzelfde account inloggen.
5. Controle op de Mac: `tailscale status` toont de Mac en je telefoon.
6. *Later, in fase 5:* de toegangsregels (PLAN §5.3), `tailscale serve`, en de deel-link (node sharing) voor vrienden.

## Stap 6: Mac "altijd aan" (🤖 met `sudo`, jij typt het wachtwoord)

```sh
sudo pmset -c sleep 0 disksleep 0      # nooit slapen op netstroom (het scherm mag wel uit)
sudo pmset -c displaysleep 10
sudo pmset -a autorestart 1            # herstarten na stroomuitval (als het model dat ondersteunt)
pmset -g                               # controle
```

👤 In Systeeminstellingen:
- *Batterij → Opties*: "Voorkom automatisch slapen op netstroom als het scherm uit is" **aan** en "Geoptimaliseerd opladen" **aan**
- *Gebruikers en groepen*: **automatisch inloggen** voor jouw gebruiker, zodat de server na een herstart weer opstart (launchd LaunchAgent)
- *Algemeen → Software-update → Automatische updates*: macOS-updates **niet** automatisch installeren
- **Klep open** laten, of een externe monitor aansluiten

## Stap 7: Controle-checklist (einde van fase 0)

```sh
sw_vers && uname -m
git --version && gh auth status
godot --version
java -version            # 17.x (of via het pad van openjdk@17)
adb devices              # telefoon zichtbaar
tailscale status         # Mac + telefoon zichtbaar
pmset -g | grep -E "sleep|autorestart"
```

Fase 0 is klaar als dit allemaal werkt. Claude Code werkt dan `docs/STATUS.md` bij en start fase 1 (zie `docs/PLAN.md` §9).

---

## Links

- Godot downloads: <https://godotengine.org/download/macos/>
- Godot export voor Android: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html>
- Godot export voor het web: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html>
- Godot dedicated server: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html>
- Android Studio: <https://developer.android.com/studio>
- Tailscale op macOS: <https://tailscale.com/download/mac>, `tailscale serve`: <https://tailscale.com/kb/1312/serve>, HTTPS: <https://tailscale.com/kb/1153/enabling-https>, node sharing: <https://tailscale.com/docs/features/sharing>
- Claude Code: <https://code.claude.com/docs>
