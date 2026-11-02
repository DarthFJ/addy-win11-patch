"""R3: Extract files from InstallShield-3 "Z" archives embedded in a self-extractor,
without executing it. Decompression = PKWARE DCL implode (port of zlib contrib/blast.c).
usage: python -I is3extract.py SETUPEXE OUTDIR [NAME ...]   (no NAME = list only)"""
import sys, os, struct, re

LITLEN = [11, 124, 8, 7, 28, 7, 188, 13, 76, 4, 10, 8, 12, 10, 12, 10, 8, 23, 8, 9, 7, 6, 7, 8, 7, 6, 55, 8, 23,
          24, 12, 11, 7, 9, 11, 12, 6, 7, 22, 5, 7, 24, 6, 11, 9, 6, 7, 22, 7, 11, 38, 7, 9, 8, 25, 11, 8, 11, 9,
          12, 8, 12, 5, 38, 5, 38, 5, 11, 7, 5, 6, 21, 6, 10, 53, 8, 7, 24, 10, 27, 44, 253, 253, 253, 252, 252,
          252, 13, 12, 45, 12, 45, 12, 61, 12, 45, 44, 173]
LENLEN = [2, 35, 36, 53, 38, 23]
DISTLEN = [2, 20, 53, 230, 247, 151, 248]
BASE = [3, 2, 4, 5, 6, 7, 8, 9, 10, 12, 16, 24, 40, 72, 136, 264]
EXTRA = [0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8]


def construct(rep):
    length = []
    for b in rep:
        length += [b & 15] * ((b >> 4) + 1)
    count = [0] * 14
    for l in length:
        count[l] += 1
    offs = [0] * 14
    for i in range(1, 13):
        offs[i + 1] = offs[i] + count[i]
    symbol = [0] * len(length)
    for s, l in enumerate(length):
        if l:
            symbol[offs[l]] = s
            offs[l] += 1
    return count, symbol


LIT, LEN, DIST = construct(LITLEN), construct(LENLEN), construct(DISTLEN)


def blast(data):
    pos = 0; bitbuf = 0; bitcnt = 0; out = bytearray()

    def bits(n):
        nonlocal pos, bitbuf, bitcnt
        while bitcnt < n:
            if pos >= len(data):
                raise ValueError('Eingabe zu kurz')
            bitbuf |= data[pos] << bitcnt; pos += 1; bitcnt += 8
        v = bitbuf & ((1 << n) - 1)
        bitbuf >>= n; bitcnt -= n
        return v

    def decode(h):
        count, symbol = h
        code = first = index = 0
        for l in range(1, 14):
            code |= bits(1) ^ 1
            c = count[l]
            if code < first + c:
                return symbol[index + code - first]
            index += c; first += c; first <<= 1; code <<= 1
        raise ValueError('ungueltiger Code')

    lit = bits(8); dic = bits(8)
    if lit > 1 or not 4 <= dic <= 6:
        raise ValueError('kein DCL-Header')
    while True:
        if bits(1):
            sym = decode(LEN)
            ln = BASE[sym] + bits(EXTRA[sym])
            if ln == 519:
                break
            sh = 2 if ln == 2 else dic
            dist = (decode(DIST) << sh) + bits(sh) + 1
            if dist > len(out):
                raise ValueError('Distanz zu weit')
            for _ in range(ln):
                out.append(out[-dist])
        else:
            out.append(decode(LIT) if lit else bits(8))
    return bytes(out)


def entries(d, base):
    fc = struct.unpack_from('<H', d, base + 12)[0]
    dto = struct.unpack_from('<I', d, base + 41)[0]
    dc = struct.unpack_from('<H', d, base + 49)[0]
    p = base + dto
    for _ in range(dc):
        p += struct.unpack_from('<H', d, p + 2)[0]
    for _ in range(fc):
        p += 3
        usz, csz, off = struct.unpack_from('<III', d, p); p += 12 + 14
        nl = d[p]; name = d[p + 1:p + 1 + nl].decode('latin-1'); p += 1 + nl + 13
        yield name, usz, csz, base + off


def main():
    exe, outdir, want = sys.argv[1], sys.argv[2], {n.upper() for n in sys.argv[3:]}
    d = open(exe, 'rb').read()
    for m in re.finditer(re.escape(b'\x13\x5d\x65\x8c'), d):
        for name, usz, csz, off in entries(d, m.start()):
            print('%-14s entpackt=%8d komprimiert=%8d @%#x' % (name, usz, csz, off))
            if name.upper() in want:
                raw = blast(d[off:off + csz])
                if len(raw) != usz:
                    sys.exit('Groessenfehler bei %s: %d != %d' % (name, len(raw), usz))
                dst = os.path.join(outdir, name)
                if os.path.exists(dst):
                    sys.exit('Ziel existiert bereits: %s' % dst)
                with open(dst, 'xb') as f:
                    f.write(raw)
                print('  -> %s geschrieben' % dst)


main()
