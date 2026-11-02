"""P9: Rocket Scrambler (SCRAM.EXE, 16-Bit) - Tempo auf schnellen Rechnern begrenzen. Nur die Kopie in C:\\COKTEL\\ADDY4\\CD2.
Hauptschleife Segment 2 ab 0x08A2: timeGetTime -> jetzt; ist jetzt <= letzter Schritt, wurde der naechste Spielschritt
bisher sofort ausgefuehrt (jbe 0x8F8 bei 2:08C1). Heute passen viele Schritte in dieselbe Millisekunde -> rasendes Tempo.
Patch: jbe (76 35) -> nop nop (Dateioffset 0x3BC1), sodass auch dieser Fall durch die normale Abstandspruefung
([0xE80] x Grundtakt) laeuft. Legt SCRAM.EXE.vorP9 an. usage: python -I P9-patch.py PFAD\\SCRAM.EXE [--undo]"""
import sys, os, hashlib, shutil, stat

OFF, ORIG, NEW = 0x3BC1, bytes.fromhex('7635'), bytes.fromhex('9090')
path = sys.argv[1]
d = open(path, 'rb').read()
cur = d[OFF:OFF + 2]
os.chmod(path, stat.S_IWRITE | stat.S_IREAD)
if '--undo' in sys.argv:
    if cur != NEW:
        sys.exit('P9 ist nicht angewendet (Bytes: %s)' % cur.hex(' '))
    with open(path, 'r+b') as f:
        f.seek(OFF); f.write(ORIG)
    print('P9 rueckgaengig gemacht, SHA1', hashlib.sha1(open(path, 'rb').read()).hexdigest())
    sys.exit()
if cur == NEW:
    sys.exit('P9 bereits angewendet - nichts zu tun.')
if cur != ORIG or d[OFF - 4:OFF] != bytes.fromhex('39067c0e'):
    sys.exit('Abbruch: unerwartete Bytes an %#x: %s' % (OFF, d[OFF - 4:OFF + 2].hex(' ')))
bak = path + '.vorP9'
if os.path.exists(bak):
    sys.exit('Abbruch: Sicherung existiert bereits: %s' % bak)
shutil.copy2(path, bak)
print('Sicherung:', bak, 'SHA1', hashlib.sha1(d).hexdigest())
with open(path, 'r+b') as f:
    f.seek(OFF); f.write(NEW)
new = open(path, 'rb').read()
print('Gepatcht:', path, 'SHA1', hashlib.sha1(new).hexdigest())
print('Geaenderte Bytes:', sum(1 for i in range(len(new)) if new[i] != d[i]))
