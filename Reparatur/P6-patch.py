"""P6: Hintergrund-Animationen (z. B. Dino im Kinderzimmer) wieder sichtbar machen - installierte Kopie von ADI4.EXE.
Skriptbefehl "VMD-Bild abspielen" (Funktion 0x42B6A0) prueft bei VA 0x42B6DF:
    cmp ax, di ; jge 0x42B6EB   -> sonst "fertig" ohne Zeichnen
ax = vom Skript gewuenschtes Endbild (10 Takte/s), di = aktuelles Bild der VMD. Der Ton-Mischer schaltet die VMD
unter Windows 11 im Tontakt (12 Bilder/s) weiter, das aktuelle Bild liegt daher vor dem Skriptzaehler und es wird
nie gezeichnet. Patch: jge (7D 07) -> jmp (EB 07) bei VA 0x42B6E2 / Dateioffset 0x2ACE2; die Pruefung di < 0 bleibt.
Legt ADI4.EXE.vorP6 an. usage: python -I P6-patch.py C:\\COKTEL\\ADDY4\\ADI4.EXE [--undo]"""
import sys, os, hashlib, shutil

OFF = 0x2ACDF
ORIG = bytes.fromhex('663bc77d07')   # cmp ax, di ; jge +7
NEW = bytes.fromhex('663bc7eb07')    # cmp ax, di ; jmp +7

path = sys.argv[1]
d = open(path, 'rb').read()
cur = d[OFF:OFF + len(ORIG)]
if '--undo' in sys.argv:
    if cur != NEW:
        sys.exit('P6 ist nicht angewendet (Bytes: %s)' % cur.hex(' '))
    with open(path, 'r+b') as f:
        f.seek(OFF); f.write(ORIG)
    print('P6 rueckgaengig gemacht, SHA1', hashlib.sha1(open(path, 'rb').read()).hexdigest())
    sys.exit()
if cur == NEW:
    sys.exit('P6 bereits angewendet - nichts zu tun.')
if cur != ORIG:
    sys.exit('Abbruch: unerwartete Bytes an %#x: %s' % (OFF, cur.hex(' ')))
bak = path + '.vorP6'
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
