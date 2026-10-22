import struct, sys
from PIL import Image, ImageDraw
d = open(sys.argv[1], 'rb').read()
magic, ver, w, h = d[:4], *struct.unpack_from('<iii', d, 4)
px = d[16:16 + w * h]
img = Image.new('RGB', (w, h))
for i, f in enumerate(px):
    x, y = i % w, h - 1 - i // w
    if f & 0x02: c = (40, 40, 48)          # niet beloopbaar
    elif f & 0x08: c = (120, 170, 220)     # beloopbaar, niet bebouwbaar (paden/ijs)
    else: c = (235, 240, 245)              # bebouwbaar
    img.putpixel((x, y), c)
# regio's uit war3map.j (wereldcoördinaten), kaart 96x96 tiles -> centrum 0,0, 128 units/tile, 4 px/tile
def rect(x1, y1, x2, y2, col, dr):
    f = lambda X, Y: ((X + 96 * 64) / 32, h - (Y + 96 * 64) / 32)
    a, b = f(x1, y2), f(x2, y1)
    dr.rectangle([a, b], outline=col, width=3)
dr = ImageDraw.Draw(img)
for r in [(-896, 4384, -256, 5088), (-256, 4384, 384, 5088), (3808, 4416, 4448, 5088), (-3872, 4512, -3232, 5088), (-4480, 4512, -3872, 5088), (3200, 4416, 3808, 5088)]:
    rect(*r, (220, 40, 40), dr)
rect(-480, -5216, 0, -4992, (40, 170, 60), dr)
for r in [(-4480, -3936, -3232, -3360), (-768, -864, 256, -320), (-4480, -640, -3904, 128), (3904, -640, 4480, 128), (3232, -3968, 4480, -3392), (-416, -1408, -192, -1184)]:
    rect(*r, (240, 170, 0), dr)
img = img.resize((w * 2, h * 2), Image.NEAREST)
img.save(sys.argv[2]); print(magic, ver, w, h)
