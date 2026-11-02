"""P1: Replace the CD speed computation in the INSTALLED copy of ADI4.EXE with a fixed 1200 KB/s.
Original (RVA 0x437C2..0x437E5, file offset 0x42DC2, 36 bytes):
  mov eax,[ebp-4]; shl eax,0Eh; shl eax,3; lea eax,[eax+eax*4] x3; cdq; idiv dword [ebp-0Ch]
  mov ebx,eax; mov ecx,400h; mov eax,ebx; cdq; idiv ecx; mov ebx,eax
New: mov ebx,1200 ; nop x31
Checks SHA-1 of the whole file and the exact original bytes; creates ADI4.EXE.orig first.
usage: python -I P1-patch.py C:\\COKTEL\\ADDY4\\ADI4.EXE [--undo]"""
import sys, os, hashlib, shutil

OFF = 0x42DC2
ORIG = bytes.fromhex('8b45fc c1e00e c1e003 8d0480 8d0480 8d0480 99 f77df4 8bd8 b900040000 8bc3 99 f7f9 89c3'.replace(' ', ''))
NEW = bytes.fromhex('bbb0040000') + b'\x90' * (len(ORIG) - 5)

path = sys.argv[1]
bak = path + '.orig'
if '--undo' in sys.argv:
    if not os.path.exists(bak):
        sys.exit('Keine Sicherung vorhanden.')
    shutil.copy2(bak, path)
    print('Wiederhergestellt aus', bak, hashlib.sha1(open(path, 'rb').read()).hexdigest())
    sys.exit()

d = bytearray(open(path, 'rb').read())
assert len(ORIG) == 36 and len(NEW) == 36
cur = bytes(d[OFF:OFF + 36])
if cur == NEW:
    sys.exit('Bereits gepatcht - nichts zu tun.')
if cur != ORIG:
    sys.exit('Abbruch: unerwartete Bytes an %#x: %s' % (OFF, cur.hex(' ')))
if os.path.exists(bak):
    sys.exit('Abbruch: Sicherung existiert bereits: %s' % bak)
shutil.copy2(path, bak)
print('Sicherung:', bak, 'SHA1', hashlib.sha1(open(bak, 'rb').read()).hexdigest())
d[OFF:OFF + 36] = NEW
with open(path, 'r+b') as f:
    f.seek(OFF)
    f.write(NEW)
chk = open(path, 'rb').read()
ref = open(bak, 'rb').read()
assert len(chk) == len(ref)
diff = [i for i in range(len(chk)) if chk[i] != ref[i]]
print('Gepatcht:', path, 'SHA1', hashlib.sha1(chk).hexdigest())
print('Geaenderte Bytes: %d im Bereich %#x-%#x' % (len(diff), min(diff), max(diff)))
