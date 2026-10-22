import re


def read_slk(path):
    """Parse a SYLK file into {row_id: {column_name: value}}. Row 1 holds the column names, column 1 the row id."""
    cells = {}
    x = y = 0
    with open(path, encoding='latin1') as f:
        for line in f:
            line = line.rstrip('\r\n')
            if not line.startswith('C;'):
                continue
            val = None
            for part in re.split(r';(?=[XYK])', line[2:]):
                if part.startswith('X'):
                    x = int(part[1:])
                elif part.startswith('Y'):
                    y = int(part[1:])
                elif part.startswith('K'):
                    raw = part[1:]
                    if raw.startswith('"'):
                        val = raw[1:-1] if raw.endswith('"') else raw[1:]
                    else:
                        try:
                            val = float(raw) if '.' in raw or 'E' in raw else int(raw)
                        except ValueError:
                            val = raw
            if val is not None:
                cells[(x, y)] = val
    cols = {xx: v for (xx, yy), v in cells.items() if yy == 1}
    rows = {}
    for (xx, yy), v in cells.items():
        if yy == 1 or xx == 1:
            continue
        rid = cells.get((1, yy))
        if rid is not None:
            rows.setdefault(rid, {})[cols.get(xx, f'col{xx}')] = v
    return rows
