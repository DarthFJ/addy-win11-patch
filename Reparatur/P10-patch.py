# P10: ADDY startet mit 100 % und schreibt beim Beenden keine gemerkte Lautstaerke mehr zurueck.
# Prueft die Originalbytes, legt ADI4.EXE.vorP10 an. Rueckgaengig: Sicherung zurueckkopieren.
import hashlib, os, shutil, struct, sys

EXE = r"C:\COKTEL\ADDY4\ADI4.EXE"
VA = lambda off: off - 0x600 + 0x401000
START = 0x36B16
rel = 0x445FF0 - (VA(START) + 2 + 5)
PATCHES = [
    (START, bytes.fromhex("E889EA0000A3D8644800"), b"\x6A\x64\xE8" + struct.pack("<i", rel) + b"\x59\x90\x90"),
    (0x3626B, bytes.fromhex("FF35D8644800"), bytes.fromhex("6AFF90909090")),
    (0x3763A, bytes.fromhex("FF35D8644800"), bytes.fromhex("6AFF90909090")),
]
d = bytearray(open(EXE, "rb").read())
for off, old, new in PATCHES:
    if d[off:off + len(old)] != old:
        sys.exit("Unerwartete Bytes an 0x%X: %s" % (off, d[off:off + len(old)].hex()))
bak = EXE + ".vorP10"
if not os.path.exists(bak):
    shutil.copy2(EXE, bak)
for off, old, new in PATCHES:
    d[off:off + len(new)] = new
    print("0x%X: %s -> %s" % (off, old.hex(), new.hex()))
open(EXE, "wb").write(d)
print("SHA1", hashlib.sha1(d).hexdigest())
