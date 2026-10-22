#!/usr/bin/env python3
"""Generate game/data/maps/frostline.json: three build lanes, a collector strip, a shared build field and the ship.

Grid cells are half a tile (a tower is 2x2 cells). Legend: '#' wall, '.' buildable, ',' walkable only.
Run: python3 -I tools/gen_map.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 96, 60
LANES = [(4, 17), (22, 35), (40, 53)]  # inclusive cell rows of each lane field
SPAWN_X0, SPAWN_X1 = 2, 7               # walkable spawn zone
FIELD_X0, FIELD_X1 = 8, 43              # buildable lane fields
STRIP_X0, STRIP_X1 = 44, 51             # collector strip where all lanes merge
SHARED = (52, 12, 81, 47)               # shared buildable field in front of the ship: x0, y0, x1, y1
EXIT_X1 = 87                            # walkable corridor from the shared field to the ship
GOAL = (88, 24, 93, 35)                 # ship: x0, y0, x1, y1 (inclusive)

grid = [['#'] * W for _ in range(H)]


def fill(x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            grid[y][x] = ch


for y0, y1 in LANES:
    fill(SPAWN_X0, y0, SPAWN_X1, y1, ',')
    fill(FIELD_X0, y0, FIELD_X1, y1, '.')
fill(STRIP_X0, LANES[0][0], STRIP_X1, LANES[-1][1], ',')
fill(SHARED[0], SHARED[1], SHARED[2], SHARED[3], '.')
fill(SHARED[2] + 1, GOAL[1], EXIT_X1, GOAL[3], ',')
fill(GOAL[0], GOAL[1], GOAL[2], GOAL[3], ',')

spawns = []
for i, (y0, y1) in enumerate(LANES):
    for y in (y0 + 3, y1 - 3):
        spawns.append({'cell': [SPAWN_X0 + 1, y], 'lane': i})

data = {
    'id': 'frostline',
    'name': {'nl': 'Vrieslijn', 'en': 'Frostline'},
    'width': W,
    'height': H,
    'cellSize': 0.5,
    'rows': [''.join(r) for r in grid],
    'spawns': spawns,
    'goal': {'rect': list(GOAL)},
    'lanes': [{'rows': [a, b], 'fieldX': [FIELD_X0, FIELD_X1]} for a, b in LANES],
    'shared': {'rect': list(SHARED)},
}
os.makedirs(os.path.join(ROOT, 'game/data/maps'), exist_ok=True)
with open(os.path.join(ROOT, 'game/data/maps/frostline.json'), 'w') as f:
    json.dump(data, f, indent=1)
    f.write('\n')
print('map written:', W, 'x', H, 'cells,', len(spawns), 'spawns')
