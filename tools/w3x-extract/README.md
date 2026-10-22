# w3x-extract

Kleine Python-scripts om speldata uit Warcraft III-maps (`.w3m`/`.w3x`) te halen. Ze zijn gebruikt
voor [`docs/research/wintermaul-v13-data.md`](../../docs/research/wintermaul-v13-data.md).

## Benodigdheden

- Python 3 en Pillow (alleen voor `wpm.py`)
- `mpyq.py` (MPQ-lezer van Blizzard, BSD-licentie). `pip install mpyq` faalt soms tijdens het bouwen,
  dus pak het bronbestand rechtstreeks uit:

```sh
pip download --no-deps --no-binary :all: mpyq -d /tmp/mpyq && tar xzf /tmp/mpyq/mpyq-*.tar.gz -C /tmp/mpyq
# → /tmp/mpyq/mpyq-0.2.5/mpyq.py
```

## Gebruik

```sh
# 1. De map heeft een HM3W-header van 512 bytes vóór het MPQ-archief, die eraf moet
python3 -c "d=open('map.w3m','rb').read(); open('map.mpq','wb').write(d[d.find(b'MPQ\x1a'):])"

# 2. Bestanden uit het archief halen (war3map.j, .w3u, .wts, .wpm, ...)
python3 -I extract.py /tmp/mpyq/mpyq-0.2.5 map.mpq out/

# 3. Unit-objectdata naar JSON (TRIGSTR-verwijzingen worden opgelost via .wts)
python3 -I w3u.py out/war3map.w3u out/war3map.wts out/units.json

# 4. Overzichten
python3 -I levels.py out/war3map.j out/units.json      # waves uit de trigger "Set Levels"
python3 -I towers.py out/units.json                     # torentabel per element (Markdown)
python3 -I wpm.py out/war3map.wpm layout.png            # pathing-kaart als PNG

# 5. Gaten vullen met de standaard WC3-tabellen en tabellen maken (zie hieronder)
python3 -I resolve.py out/units.json <slk-map> out/resolved.json
python3 -I report.py out/resolved.json out/war3map.j    # waves + torens als Markdown
```

### Standaard WC3-tabellen (SLK)

`resolve.py` vult de velden die de map niet wijzigt met de waarden van de basis-unit. Daarvoor zijn `unitbalance.slk`,
`unitdata.slk` en `unitweapons.slk` nodig (Blizzard-bestanden: **niet committen**). Ze staan in publieke GitHub-extracties, bijvoorbeeld
`MatthewMarinets/war3-ap-maps` onder `gamedata/1_30_4/custom_v0/units/`:

```sh
for f in unitbalance unitdata unitweapons; do
  gh api repos/MatthewMarinets/war3-ap-maps/contents/gamedata/1_30_4/custom_v0/units/$f.slk -H "Accept: application/vnd.github.raw" > slk/$f.slk
done
```

## Beperkingen

- `levels.py`, `towers.py` en `wpm.py` bevatten Wintermaul v13-specifieke id's en regio's. Pas ze aan voor andere maps
- Maps met encrypted listfiles worden gelezen via vaste bestandsnamen. PKWare-implode-compressie (sommige oude maps) en
  `.w3u` versie 3 (WC3 1.31+/Reforged) worden nog niet ondersteund
- Velden die de map niet wijzigt, erven hun waarde van de standaard WC3-unit (SLK-data) en ontbreken dus in de output
