import struct, sys, re, json
data = open(sys.argv[1], 'rb').read()
wts = open(sys.argv[2], encoding='utf-8-sig', errors='replace').read()
strings = {int(m.group(1)): m.group(2).strip() for m in re.finditer(r'STRING (\d+)\s*\{\r?\n(.*?)\r?\n\}', wts, re.S)}
p = 0
def i32():
    global p; v = struct.unpack_from('<i', data, p)[0]; p += 4; return v
def f32():
    global p; v = struct.unpack_from('<f', data, p)[0]; p += 4; return v
def raw4():
    global p; v = data[p:p+4]; p += 4; return v.decode('latin1')
def cstr():
    global p; e = data.index(b'\0', p); v = data[p:e].decode('utf-8', 'replace'); p = e + 1; return v
ver = i32()
out = {'original': [], 'custom': []}
for table in ('original', 'custom'):
    n = i32()
    for _ in range(n):
        base = raw4(); new = raw4()
        mods = {}
        for _ in range(i32()):
            mid = raw4(); t = i32()
            v = i32() if t == 0 else f32() if t in (1, 2) else cstr()
            if isinstance(v, str) and v.startswith('TRIGSTR_'):
                v = strings.get(int(v[8:]), v)
            p += 4  # end marker
            mods[mid] = v
        out[table].append({'base': base, 'id': new if new != '\0\0\0\0' else base, 'mods': mods})
json.dump(out, open(sys.argv[3], 'w'), indent=1)
print(ver, len(out['original']), len(out['custom']))
