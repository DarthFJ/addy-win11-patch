"""R1: Lossless conversion of a single-track MODE1/2352 BIN image to a 2048-byte ISO.
Reads the BIN read-only; writes only OUT. Aborts on any sector that is not MODE1.
usage: python -I bin2iso.py IN.bin OUT.iso"""
import sys, os

SYNC = b'\x00' + b'\xff' * 10 + b'\x00'
src, dst = sys.argv[1], sys.argv[2]
size = os.path.getsize(src)
if size % 2352:
    sys.exit('Abbruch: Groesse %d ist kein Vielfaches von 2352' % size)
if os.path.exists(dst):
    sys.exit('Abbruch: Ziel existiert bereits: %s' % dst)
n = size // 2352
with open(src, 'rb') as fi, open(dst, 'xb') as fo:
    for i in range(n):
        s = fi.read(2352)
        if s[:12] != SYNC or s[15] != 1:
            fo.close(); os.remove(dst)
            sys.exit('Abbruch: Sektor %d ist kein MODE1-Datensektor (mode=%d)' % (i, s[15]))
        fo.write(s[16:2064])
print('%s -> %s: %d Sektoren, %d Bytes' % (src, dst, n, n * 2048))
