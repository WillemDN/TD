import sys
sys.path.insert(0, sys.argv[1])
import mpyq
a = mpyq.MPQArchive(sys.argv[2], listfile=False)
out = sys.argv[3]
names = ['war3map.j','war3map.w3u','war3map.w3t','war3map.w3a','war3map.w3q','war3map.wts','war3map.w3i','war3map.w3b','war3map.w3h','scripts\\war3map.j','(listfile)','war3map.w3e','war3map.wpm','war3mapUnits.doo']
for n in names:
    try:
        d = a.read_file(n)
        print(n, None if d is None else len(d))
        if d: open(out + '/' + n.replace('\\','_'), 'wb').write(d)
    except Exception as e:
        print(n, 'ERR', repr(e))
