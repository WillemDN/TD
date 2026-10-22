import json, sys
u = json.load(open(sys.argv[1]))
units = {x['id']: x['mods'] for t in ('original', 'custom') for x in u[t]}
elements = [('Fire', 'nC03'), ('Ice', 'oC25'), ('Tech', 'hC07'), ('Electric', 'eC10'), ('Stone', 'uC13'),
            ('Poison', 'oC22'), ('Nature (Gaia)', 'efon'), ('Undead', 'uC81'), ('Crystal', 'uC98')]
special = {'Afrb': 'slow', 'Aspo': 'slow-poison', 'ACct': 'crit', 'Alit': 'chain-lightning', 'ACcl': 'chain-lightning',
           'Amgl': 'bounce', 'Afae': 'faerie-fire (armor-)', 'Aspi': 'spiked', 'ACff': 'faerie-fire', 'Aenr': 'entangle',
           'ACba': 'brilliance aura'}
print('| Element | Toren | Goud | Bouwtijd s | Schade (min–max) | Cooldown s | Range | Splash | Type | Specials |')
print('|---|---|---|---|---|---|---|---|---|---|')
for el, b in elements:
    for tid in units[b]['ubui'].split(','):
        m = units.get(tid, {})
        base = m.get('ua1b'); dice = m.get('ua1d', 1); sides = m.get('ua1s', 1)
        dmg = f"{base+dice}–{base+dice*sides}" if base is not None else '?'
        sp = ', '.join(sorted({special.get(a, a) for a in m.get('uabi', '').split(',') if a and a not in ('Abds', 'Avul')}))
        splash = m.get('ua1z', '')
        print(f"| {el} | {m.get('unam', tid)} | {m.get('ugol','?')}{' +1 hout' if m.get('ulum') else ''} | {m.get('ubld','')} | {dmg} | {round(m['ua1c'],2) if 'ua1c' in m else '~'} | {m.get('ua1r','~')} | {'' if splash in ('', 10000) else splash} | {m.get('ua1t','normal')} | {sp} |")
m = units['hC63']
print(f"| Ultiem (Element Chooser) | Laser Cannon | {m['ugol']} +1 hout | {m['ubld']} | 250 | 0.6 | 10000 | | chaos | crit, slow, slow-poison |")
