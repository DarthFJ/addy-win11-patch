"""P2: Fix the endless GlobalDeleteAtom loop in the INSTALLED copy of ADI4.EXE (Windows 10/11).
Original at VA 0x437DD8 (file offset 0x373D8):
  push ebx; call GlobalDeleteAtom; cmp bx,ax; jne 0x437DD8
Windows 95 returned the atom on failure (loop ends after the last reference); Windows 11 always
returns 0, so the loop never ends. Patch: replace the 'jne' (75 F5) at file offset 0x373E1 by two NOPs,
so the atom is deleted exactly once (the program created it exactly once a few lines earlier).
Creates ADI4.EXE.vorP2 before patching. usage: python -I P2-patch.py C:\\COKTEL\\ADDY4\\ADI4.EXE [--undo]"""
import sys, os, hashlib, shutil

OFF = 0x373D8
ORIG = bytes.fromhex('53 e8 df 50 03 00 66 3b d8 75 f5'.replace(' ', ''))
NEW = ORIG[:9] + b'\x90\x90'

path = sys.argv[1]
d = open(path, 'rb').read()
cur = d[OFF:OFF + len(ORIG)]
if '--undo' in sys.argv:
    if cur != NEW:
        sys.exit('P2 ist nicht angewendet (Bytes: %s)' % cur.hex(' '))
    with open(path, 'r+b') as f:
        f.seek(OFF); f.write(ORIG)
    print('P2 rueckgaengig gemacht, SHA1', hashlib.sha1(open(path, 'rb').read()).hexdigest())
    sys.exit()
if cur == NEW:
    sys.exit('P2 bereits angewendet - nichts zu tun.')
if cur != ORIG:
    sys.exit('Abbruch: unerwartete Bytes an %#x: %s' % (OFF, cur.hex(' ')))
bak = path + '.vorP2'
if os.path.exists(bak):
    sys.exit('Abbruch: Sicherung existiert bereits: %s' % bak)
shutil.copy2(path, bak)
print('Sicherung:', bak, 'SHA1', hashlib.sha1(d).hexdigest())
with open(path, 'r+b') as f:
    f.seek(OFF); f.write(NEW)
new = open(path, 'rb').read()
diff = [i for i in range(len(new)) if new[i] != d[i]]
print('Gepatcht:', path, 'SHA1', hashlib.sha1(new).hexdigest())
print('Geaenderte Bytes: %d an %s' % (len(diff), ', '.join('%#x' % i for i in diff)))
