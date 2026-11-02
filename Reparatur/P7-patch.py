"""P7: Keine abgetrennten Bildreste bei Animationen (z. B. Punk rechts im Kinderzimmer) - installierte ADI4.EXE.
Seit P6 zeichnet der Skriptbefehl "VMD-Bild abspielen" (0x42B6A0) nur das Aenderungsrechteck des zuletzt
gespielten Bildes ([0x490AB0..0x490ABC]). Bilder, die der Ton-Mischer zwischendurch abgespielt hat, verlieren
ihr Rechteck (der Player setzt es pro Bild zurueck) -> ihre Aenderungen bleiben als Reste stehen.
Patch: Vor dem Kopieren (VA 0x42BAB0) springt der Code in eine bisher ungenutzte Null-Luecke am Ende des
Codebereichs (VA 0x46D480, Datei 0x6CA80, 45 Bytes) und setzt das Rechteck auf das ganze Animationsbild
(0,0)-(Breite-1,Hoehe-1) aus dem VMD-Objekt (ebx+0xA / ebx+0xC). Danach werden die beiden ueberschriebenen
Originalbefehle ausgefuehrt und es geht bei 0x42BAB8 weiter.
Legt ADI4.EXE.vorP7 an. usage: python -I P7-patch.py C:\\COKTEL\\ADDY4\\ADI4.EXE [--undo]"""
import sys, os, hashlib, shutil

PATCHES = [
    # (Dateioffset, Original, Neu)
    (0x6CA80, bytes(45), bytes.fromhex(
        '31C0'            # xor eax,eax
        'A3B00A4900'      # mov [0x490AB0],eax   x1 = 0
        'A3B80A4900'      # mov [0x490AB8],eax   y1 = 0
        '0FBF430A' '48'   # movsx eax,word [ebx+0xA] ; dec eax
        'A3B40A4900'      # mov [0x490AB4],eax   x2 = Breite-1
        '0FBF430C' '48'   # movsx eax,word [ebx+0xC] ; dec eax
        'A3BC0A4900'      # mov [0x490ABC],eax   y2 = Hoehe-1
        '6A00'            # push 0                (Original)
        '8B15B80A4900'    # mov edx,[0x490AB8]    (Original)
        'E90BE6FBFF')),   # jmp 0x42BAB8
    (0x2B0B0, bytes.fromhex('6A008B15B80A4900'), bytes.fromhex('E9CB190400909090')),  # jmp 0x46D480 ; nop x3
]

path = sys.argv[1]
d = open(path, 'rb').read()
state = ['neu' if d[o:o + len(n)] == n else 'orig' if d[o:o + len(a)] == a else 'fremd' for o, a, n in PATCHES]
if '--undo' in sys.argv:
    if state != ['neu', 'neu']:
        sys.exit('P7 ist nicht (vollstaendig) angewendet: %s' % state)
    with open(path, 'r+b') as f:
        for o, a, n in PATCHES:
            f.seek(o); f.write(a)
    print('P7 rueckgaengig gemacht, SHA1', hashlib.sha1(open(path, 'rb').read()).hexdigest())
    sys.exit()
if state == ['neu', 'neu']:
    sys.exit('P7 bereits angewendet - nichts zu tun.')
if state != ['orig', 'orig']:
    sys.exit('Abbruch: unerwartete Bytes (%s)' % state)
bak = path + '.vorP7'
if os.path.exists(bak):
    sys.exit('Abbruch: Sicherung existiert bereits: %s' % bak)
shutil.copy2(path, bak)
print('Sicherung:', bak, 'SHA1', hashlib.sha1(d).hexdigest())
with open(path, 'r+b') as f:
    for o, a, n in PATCHES:
        f.seek(o); f.write(n)
new = open(path, 'rb').read()
diff = [i for i in range(len(new)) if new[i] != d[i]]
print('Gepatcht:', path, 'SHA1', hashlib.sha1(new).hexdigest())
print('Geaenderte Bytes: %d (Bereiche 0x2B0B0-0x2B0B7 und 0x6CA80-0x6CAAC)' % len(diff))
