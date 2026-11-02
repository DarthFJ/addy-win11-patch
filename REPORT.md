# ADDY – Deutsch Klasse 5+6 (Coktel, 1998) unter Windows 11

Stand: 29.10.2026 · Analyse ausschließlich lesend (keine Originaldatei verändert, kein Programm von den CDs ausgeführt).

Kennzeichnung: **[F]** = durch Datei, Hash oder Header belegte Tatsache · **[V]** = Vermutung oder Schlussfolgerung, noch nicht getestet.

---

## 0. Kurzfazit

1. **[F]** Die Hauptprogramme `SETUP.EXE` und `ADI4.EXE` sind **32-Bit (PE32, i386)** und laufen unter Windows 11 x64 grundsätzlich.
2. **[F]** Zwei vom Setup aufgerufene Unterinstaller sind **16-Bit (NE)**: `WING\WSETUP.EXE` (WinG) und `VFW\IV32NT95.EXE` (Intel Indeo 3.2). Ein 64-Bit-Windows kann 16-Bit-Programme nicht ausführen (kein NTVDM). Beide Laufzeitbibliotheken fehlen auf diesem System.
3. **[F]** Das Hilfsprogramm `OLDAPPLI.EXE` ist ebenfalls 16-Bit. Ob das Deutsch-Modul darüber läuft, ist offen **[V]** (siehe 3.3).
4. **[F]** Der Sammelordner **„Addy Alles“ ist als CD-Quelle für CD3 fehlerhaft**: `ANIREW.ITK` gibt es auf CD2 und CD3 mit unterschiedlichem Inhalt. Im Ordner liegt nur die CD2-Version, dadurch fehlen 531 Videos der CD3.
5. Empfehlung: Zuerst einen nativen Versuch unter Win11 mit den eingebundenen CD-Abbildern machen und WinG/Indeo von Hand bereitstellen (Abschnitt 6). Läuft das Deutsch-Modul nicht vollständig, ist eine **VM mit Windows 98 SE oder Windows XP (32 Bit)** die verlässliche Alternative (Abschnitt 7).

---

## 1. Ausgangslage (Quelldaten)

| Quelle | Format | Volume-Label | Dateien | Rolle |
|---|---|---|---|---|
| `..\CD1 Install\Addy_Coll1.bin/.cue` | BIN/CUE, MODE1/2352, 1 Track | `Addy_Coll1` | 408 | Installations-CD und Basisprogramm |
| `..\CD2\Addy4_coll2.bin/.cue` | BIN/CUE, MODE1/2352, 1 Track | `Addy4_coll2` | 459 | Basisprogramm-Medien und Spiele |
| `..\CD3\CD3.ISO` | ISO 9660 | `ADDY4_DK5-6` | 12 | Lernmodul **Deutsch Kl. 5+6** |
| `Addy Alles\` | entpackter Sammelordner | – | 720 | Zusammenkopie aller drei CDs |

- **[F]** Zurzeit sind eingebunden: `D:` = `ADDY4_DK5-6` (CD3.ISO) und `E:` = `Addy4_coll2` (CD2).
- **[F]** Ein SHA-1-Vergleich aller Dateien aus den Abbildern mit „Addy Alles“ ergab: 878 identisch, **1 abweichend** (`ANIREW.ITK` gegenüber CD3), **1 Zusatzdatei** (`CMDLINE.CMD`, 51 Bytes, Inhalt = Pfad zu `ADI4.EXE`, Datum heute).
- **[F]** `ADI4.EXE` enthält die Zeichenkette `CMDLINE.CMD`. **[V]** Die Datei wurde wahrscheinlich bei einem früheren Startversuch von `ADI4.EXE` selbst angelegt.
- **[F]** Frühere Startversuche haben Spuren hinterlassen. In `HKCU\…\AppCompatFlags\Layers` stehen:
  - `…\Addy Alles\ADI4.EXE` → `WINXPSP3`
  - `SIGN.MEDIA=CD12FED9 SETUP.EXE` → `RUNASADMIN WINXPSP2`
- **[F]** Es gibt keine Installation unter `C:\COKTEL`, keine `C:\WMDO.CFG` / `C:\MDO.CFG` und keine Coktel-Registry-Schlüssel.

### 1.1 Kollision `ANIREW.ITK` (kritisch)

| Version | Größe | Datum | SHA-1 (Anfang) | Einträge |
|---|---|---|---|---|
| CD2 | 108 521 472 | 03.10.1997 | `dbe9e03963` | 604 VMD |
| CD3 | 85 800 960 | 19.11.1997 | `0b8f293342` | 590 VMD |

- **[F]** Nur 59 Einträge sind gleichnamig. 531 Videos gibt es nur auf CD3 (z. B. `ADIPZA11.VMD`, `ADIPZD14.VMD`), 545 nur auf CD2 (z. B. `GD3.VMD`, `PE3.VMD`).
- **[F]** Im Sammelordner liegt die CD2-Version.
- **Folge:** „Addy Alles“ darf nicht als Ersatz für CD3 dienen. Für CD3 werden das Abbild oder eine eigene, getrennte Kopie gebraucht.

---

## 2. Zuordnung: Basisprogramm und Lerninhalte

### 2.1 Basisprogramm (von `SETUP.INF` auf die Festplatte kopiert) [F]
`ADI4.EXE`, `ADI4UPDT.EXE`, `ADISCAPE.EXE`, `ADILOOK.EXE/.BMP`, `OLDAPPLI.EXE`, `CURSOR32.DLL`, `EDIT_DEV.DLL`, `SOUNDDLL.DLL`, `SOUNDLIB.DLL`, `INSTALL.ASK`, `MDO.DEF`, `MDO.INI`, `MDOGAMES.INI`, `CLASSE.INI`, `INTRO.INF`, `POSTE.INF`, `INTRO.STK/.ITK`, `ECHANGE.STK/.ITK`, `INTER1.ITK`, `VISAGE.STK`, `*.CMP`, `*.ANI`, `OFF*.TGA/RTF`, `ICO*.JPG`, Textdateien, `UNINST.*`, `SETPROXY.EXE`, `PROXY.INI`, `LIESMICH.DOC`, `PA\*` (Malprogramm „PAWIN“, 16 Bit) und die Schriften `ADI1.TTF` und `ADI_1.TTF`.

### 2.2 Bleiben auf der CD (Medien des Basisprogramms) [F: nicht in `SETUP.INF` enthalten]
- CD1 und CD2: `ADIANI.ITK`, `ADIBLA.ITK`, `ENVIR.STK` (auf beiden CDs identisch)
- nur CD1: `DOC.STK/.ITK`, `ATLAS.STK/.ITK`, `SIMULC.STK/.ITK`, `PALETTE.STK/.ITK`
- nur CD2: `INTER2.ITK`, `INTERNET.STK`, `ADINET.STK` (Online-Teil; die Server existieren nicht mehr) sowie `ANIREW.ITK` (CD2-Version)

### 2.3 Lernmodul Deutsch 5+6 (nur CD3) [F]
| Datei | Inhalt |
|---|---|
| `ADIF52.STK` / `ADIF62.STK` | Skripte (TOT/EXT/LET) für Klasse 5 und 6, z. B. `GED5_111.TOT` |
| `F52VMD.ITK` / `F62VMD.ITK` | 750 bzw. 811 Videos/Animationen der Aufgaben |
| `F52DOC.STK`, `F52RAN.STK`, `F62DOC.STK`, `F62RAN.STK` | Dokumentation und Zufallsübungen |
| `DESCF521.ADI`, `DESCF621.ADI` | Modulbeschreibungen. `ADI4.EXE` sucht sie unter dem Muster `<CD>DESC%s%c.ADI`. |
| `ANIREW.ITK` (CD3-Version) | Belohnungs- und Figurenanimationen |
| `AL65D400.CD1` | Kennungsdatei der CD **[V]** |

- **[F]** `CLASSE.INI` definiert die Fächer Mathe und Deutsch. Die Themen F5 und F6 (Wortbildung, Satzbau, Sprachgebrauch, Textanalyse, Rechtschreibung) passen zu CD3.
- **[F]** Mathe-Inhalte (`ADIM*`) gibt es auf keiner der drei CDs. Das ist korrekt, denn das Produkt ist „nur Deutsch“.

### 2.4 Zusatzspiele (`GAMES\`, CD2; teilweise auch CD1) [F]
- **32-Bit:** BrkTime, JetFight, Jupiter (`CNCS32.DLL` liegt bei), LasBlo (`VB40032.DLL` liegt bei), MrMatt1/2, Revolut, T4, Filler, PINBALL2 (`DSOUND`).
- **16-Bit, unter Win11 x64 nicht lauffähig:** Aztec, Backgammon, Beebop1/2, BillFra, Blaze, Cellul, Chess, Frustr, Gob1/2/3, Invade, LastAdi, Neuro1/2/3, Nucleo, PlaceB, QuadSt, Relix, Scram, ShihDao, Sokob, Solit, Volutare.
- Die Ordner `Paragge` und `Stripsge` sind auf der CD leer.

---

## 3. Installer und Architektur

### 3.1 Setup-Kette

| Datei | Typ | Rolle |
|---|---|---|
| `AUTORUN\AUTORUN.EXE` | PE32 i386, GUI | Startmenü der CD |
| `SETUP.EXE` | **PE32 i386** | Proprietärer Coktel-Skriptinstaller, liest `SETUP.INF` und `SETUP.INI` |
| `WING\WSETUP.EXE` (+ `_MSTEST`/MS-Setup-Toolkit) | **NE 16-Bit** | Microsoft WinG 1.0. Wird aufgerufen, wenn `WING32.DLL` < 1.0.0.37 im Systemordner ist. |
| `VFW\IV32NT95.EXE` | **NE 16-Bit**, InstallShield-Selbstentpacker | Intel Indeo 3.2 (`IR32_32.DLL`, `IYVU9_32.DLL`). Wird aufgerufen, wenn `IR32_32.DLL` < 3.24.15.03 ist. |
| `VCWEBVR\REGSVR32.EXE`, `VCWEB32.OCX` | PE32 | „INSTALL WEBVIEWER“, Browser-Steuerelement für den Online-Teil |
| `UNINST.EXE` | PE32 | Deinstallation |

### 3.2 Was `SETUP.INF` tut [F]
- Installiert die Schriften `ADI_1.TTF` und `ADI1.TTF`.
- Prüft und installiert WinG und Indeo (16-Bit-Unterinstaller, s. o.).
- Legt `*DESTDIR` an (Vorgabe aus `MDO.INI`: `\COKTEL\ADDY4`), dazu `PA`, `INFO` und `SAVEGAME\…` (41 Spielordner).
- Kopiert die Dateien aus 2.1.
- Führt `SETPROXY.EXE|InfonieFR` aus.
- Trägt `ADILOOK.EXE` in den Autostart ein. `ADI4.EXE` enthält ausserdem `…\CurrentVersion\RunOnce` / `\ADILOOK`.
- Legt die Startmenügruppe „COKTEL“ an.
- `TEST GRAPHCAPS 640 480 16` (mindestens 16 Bit Farbtiefe), danach `ALLDONE REBOOT`.

### 3.3 Hauptprogramme
- **[F]** `ADI4.EXE`: PE32 i386 mit den Sektionen CODE/DATA/.INIT, Importe KERNEL32, GDI32, USER32, ADVAPI32, WINMM, COMDLG32 und `edit_dev.dll`. Nachgeladen werden laut Zeichenketten `WING32.DLL`, `DDRAW.DLL`, `MSVFW32.DLL`, `CTL3D32.DLL`, `WSOCK32.DLL` und `RASAPI32.DLL`.
- **[F]** `OLDAPPLI.EXE`: **NE 16-Bit**. Importiert `SOUNDDLL`, `DISPDIB`, `MMSYSTEM` und `TOOLHELP` und lädt `WING.DLL` und `MSVIDEO.DLL`.
- **[F]** `ADI4.EXE` startet es mit `<ME>OLDAPPLI.EXE` und `appli20 DESC%s.ADI %d %s`. `OLDAPPLI.EXE` enthält die festen Namen `DESCA71.ADI`, `DESCA91.ADI`, `adi2.stk` und `adi3.stk`.
- **[V]** `OLDAPPLI.EXE` ist für ältere Lernmodule (Adi 2/3-Generation) gedacht. Das Deutsch-Modul von CD3 (`ADIF52.STK`, passend zum Muster `ADI%s.STK` in `ADI4.EXE`) läuft vermutlich direkt in `ADI4.EXE`. **Ungeprüft.** Falls es doch über `OLDAPPLI.EXE` läuft, ist es unter Win11 x64 nicht lauffähig, und nur die VM bleibt.

---

## 4. Abhängigkeiten

| Komponente | Beleg | Unter Win11 vorhanden? |
|---|---|---|
| **WinG 1.0** (`WING32.DLL`) | [F] `SETUP.INF`, `ADI4.EXE`: „WinG need to be installed“, `WinGCreateDC` … | **Nein** |
| **Intel Indeo 3.2** (`IR32_32.DLL`) | [F] `SETUP.INF`; `INDEO.MAP` in `ADI4.EXE` und `OLDAPPLI.EXE`, `_ICDecompress` in `OLDAPPLI.EXE` | **Nein** |
| Video for Windows (`MSVFW32.DLL`) | [F] Zeichenkette in `ADI4.EXE` | Ja (SysWOW64) |
| DirectDraw (`DDRAW.DLL`) | [F] Zeichenkette in `ADI4.EXE`, Schalter `_directx_=` in `INTRO.INF` | Ja |
| `CTL3D32.DLL` | [F] Zeichenkette in `ADI4.EXE` | Ja |
| WINMM / MCI | [F] Importe (`mciSendStringA`, AVI-Befehle) | Ja |
| Soundkarte | [F] „This program needs a SoundCard to run.“ | Ja (jede WinMM-Ausgabe) **[V]** |
| 16-Bit-Farbtiefe, 640×480 | [F] `MDO.INI` `MinBitsPerPel = 16`, `TEST GRAPHCAPS` | Ja (Win11 meldet 32 Bit) **[V]** |
| `WSOCK32` / `RASAPI32`, `VCWEB32.OCX` + MFC42 | [F] nur für den Internet-Teil | technisch ja, Server offline |

- **Nicht belegt, also keine Abhängigkeit:** QuickTime, ein DirectX-Installer, Datenbanktreiber und BDE wurden auf keiner CD gefunden. `INTRO.INF` kennt zwar den Schalter `_directx_=`, ein DirectX-Setup liegt aber nicht bei.
- **[F]** `WING32.DL_` (mit `expand.exe` in den Scratchpad entpackt) ist eine **reine 32-Bit-DLL** (PE32, Importe nur GDI32/KERNEL32/USER32, „WinG Version 1.0“, 12 800 Bytes). Sie kann also ohne den 16-Bit-Installer bereitgestellt werden.
- **[F]** `IV32NT95.EXE` ist ein InstallShield-Selbstentpacker mit 16-Bit-Stub und enthält `ir32_32.dll` und `iyvu9_32.dll`. **[V]** Die DLLs lassen sich mit einem Entpackwerkzeug herauslösen, ohne den Installer auszuführen.
- **[V]** Coktel-VMD-Videos können intern Indeo-3-Bilder enthalten. Ohne `IR32_32.DLL` bleiben Videos dann schwarz oder brechen ab.
- **Sicherheitshinweis:** Alte Indeo-Codecs hatten bekannte Schwachstellen (Microsoft Security Advisory 954157). Nur für diese Anwendung einsetzen und keine fremden Videos damit öffnen.

---

## 5. CD-Wechsel, Pfade, Profile und Speicherstände

### 5.1 CD-Verwaltung [F]
- `MDO.DEF`: `CDROM:YES`, `ROOT:\`. `INTRO.INF`: `_gestionCD_=1` (CD-Verwaltung an).
- `ADI4.EXE` kennt die Pfadpräfixe `<ME>` (Installationsordner), `<CD>`, `<REP:`, `<ALLCD>` sowie `MULTICD.INF`, `FINDMULTICD`, `%sVCDROM%d` und die `INTRO.INF`-Schlüssel `_vcdrom_=`, `_firstCD_=` und `_full_=`.
- Kennungsdateien: `AE63D401.CD1` (CD1), `AE63D401.CD2` (CD2), `AL65D400.CD1` (CD3).
- `ADI4.EXE` importiert `GetLogicalDrives`, `GetDriveTypeA` und `GetVolumeInformationA`.
- **[V]** Das Programm sucht Laufwerke vom Typ CD-ROM und erkennt die eingelegte CD an den `.CDx`-Dateien, eventuell auch am Volume-Label. Ein Ordner auf der Festplatte (Typ „Fixed“) wird daher wohl **nicht** als CD erkannt. Eingebundene ISO-Abbilder sind dagegen vom Typ „CD-ROM“.
- **[V]** `_vcdrom_` / `VCDROM%d` deuten auf eine eingebaute Funktion „virtuelle CD auf Festplatte“ (z. B. `…\VCDROM1`, `VCDROM2`, …). Format und Nutzung sind unbekannt, das ließe sich nur durch Tests klären. **Hinweis:** Das ist eine Funktion des Programms, keine Umgehung eines Kopierschutzes. Sie wird nur genutzt, wenn du sie freigibst.
- Ein Kopierschutz wurde nicht gefunden. Die CD-Prüfung bleibt unangetastet.

### 5.2 Konfigurations- und Schreibpfade
- **[F]** In `ADI4.EXE` stehen `C:\WMDO.CFG`, `C:\MDO.CFG`, `C:\DEBUG.ERR`, `TRACE.TXT`, `ADI4.LOG`, `SAUVE.$$$` und `$$$.VMD`.
- **[V]** Das Programm schreibt in die Wurzel von `C:\`. Als Standardbenutzer ist das unter Win11 verboten. Mögliche Folgen sind Fehler oder eine Umleitung in den VirtualStore, wenn das Programm als Legacy-Anwendung erkannt wird. Das muss beim Test geprüft werden. Ein dauerhaftes „Als Administrator ausführen“ wäre nur der letzte Ausweg und wird nicht ohne Test empfohlen.
- **Installationsziel:** `C:\COKTEL\ADDY4`, wie vom Setup vorgegeben, **nicht** unter `Program Files`. Ordner in `C:\` (nicht die Wurzel selbst) darf der Benutzer anlegen und beschreiben.

### 5.3 Profile und Speicherstände
- **[F]** `SAVEGAME\<Spiel>\` gilt für die Spiele (`MDOGAMES.INI`), `INFO\` wird angelegt.
- **[F]** `UNINST.INI` warnt, dass beim Deinstallieren alle erstellten Gesichter und Punkte verloren gehen.
- **[V]** Profile und Punkte liegen also im Installationsordner, wahrscheinlich in `INFO\` und in `*.INF`-Dateien wie `USERA.INF` und `ADI.INF`; letzteres steht in `UNINST.INF` als `DIALOG ADI.INF`.
- **Sicherung:** Nach der ersten Nutzung den ganzen Ordner `C:\COKTEL\ADDY4` sichern und zusätzlich, falls vorhanden, `C:\WMDO.CFG` und `C:\MDO.CFG`.

---

## 6. Anleitung für Windows 11 (Vorschlag, noch nicht ausgeführt)

> Keine dieser Aktionen ist bisher durchgeführt worden. Jeder Schritt mit **⏸ Freigabe** wartet auf deine Zustimmung und wird danach getestet und protokolliert.

**Vorbereitung**
1. **⏸ Freigabe R1 – Abbilder einbindbar machen.** Windows 11 bindet ISO-Dateien selbst ein, BIN/CUE aber nicht. Vorschlag: Aus `Addy_Coll1.bin` und `Addy4_coll2.bin` je eine verlustfreie `.iso` erzeugen. Dabei werden die 2048-Byte-Nutzdaten jedes 2352-Byte-Sektors übernommen. Ziel ist ein neuer Ordner, z. B. `..\ISO\`; die Originale bleiben unberührt. Test: Dateiliste und SHA-1 jeder Datei mit der bereits ermittelten Referenz vergleichen.
2. Den Sammelordner „Addy Alles“ **nicht** als CD-Ersatz verwenden (Abschnitt 1.1).

**Laufzeitbibliotheken (manuell statt 16-Bit-Installer)**

3. **⏸ Freigabe R2 – WinG.** `WING32.DLL` aus `WING\WING32.DL_` mit dem Windows-Bordmittel `expand.exe` entpacken. Ablage nur im Programmordner `C:\COKTEL\ADDY4`, **nicht** in `SysWOW64`. **[V]** Windows lädt DLLs zuerst aus dem Programmordner. Test: `ADI4.EXE` startet ohne die Meldung „WinG need to be installed“.
4. **⏸ Freigabe R3 – Indeo 3.2.** `ir32_32.dll` aus `IV32NT95.EXE` herauslösen, ohne den Installer auszuführen; die Herkunft bleibt so auf deine CD beschränkt. Damit Video for Windows den Codec findet, braucht es einen Registry-Eintrag (32-Bit-Zweig, `Drivers32` → `vidc.iv32`). Das ist eine Systemänderung und braucht Adminrechte. Test: Videos im Lernmodul laufen mit Bild.

**Installation**

5. **⏸ Freigabe R4 – Weg wählen.**
   - **a) Original-`SETUP.EXE`** vom eingebundenen CD1-Abbild. Erwartung **[V]**: Es bricht bei WinG oder Indeo mit einem Fehler über eine „16-Bit-Anwendung“ ab, wenn die DLLs vorher nicht im Systemordner liegen.
   - **b) Manuelle Kopie** genau nach der Dateiliste aus `SETUP.INF`: Ordner anlegen, Dateien aus 2.1 kopieren, die beiden Schriften installieren. **Bewusst weglassen:** Autostart-Eintrag für `ADILOOK`, `SETPROXY`, Registrierung des WebViewers (`VCWEBVR\` enthält veraltete System-DLLs wie `MSVCRT` und `OLEAUT32`, die nie ins System kopiert werden dürfen), Neustart. Dieser Weg ist nachvollziehbar und reversibel und wird **empfohlen**.
6. Verknüpfung auf `C:\COKTEL\ADDY4\ADI4.EXE` mit „Ausführen in“ = `C:\COKTEL\ADDY4`. Den vorhandenen Kompatibilitätseintrag `WINXPSP3` für die Kopie in „Addy Alles“ beim Test berücksichtigen. Startmodus zunächst im Fenster, wie in `LIESMICH.DOC` empfohlen (`INTRO.INF`: `_full_=0`).

**Nutzung**

7. CD3 (`ADDY4_DK5-6`) einbinden und `ADI4.EXE` starten. Wenn das Programm eine andere CD verlangt: Abbild über Explorer → „Auswerfen“ trennen und das gewünschte Abbild einbinden. **[V]** Der Laufwerksbuchstabe sollte dabei gleich bleiben; ob das Programm einen wechselnden Buchstaben toleriert, ist ungeprüft.

**Testprotokoll je Schritt:** Ausgangszustand, ausgeführte Aktion, erwartetes und tatsächliches Ergebnis, erzeugte oder geänderte Dateien und Registry-Schlüssel, Rückgängig-Anleitung.

---

## 7. Alternative: virtuelle Maschine

| Variante | Vorteile | Nachteile |
|---|---|---|
| **Windows 98 SE** (86Box/PCem, ersatzweise VirtualBox) | Zielsystem laut `LIESMICH.DOC` („ausschließlich Windows 95“), alle 16-Bit-Teile inkl. Spiele, PAWIN, `OLDAPPLI.EXE` | Grafik- und Soundtreiber mühsam. VirtualBox bietet für 98 keine offiziellen Gasterweiterungen, und auf diesem PC läuft Hyper-V (**[F]** „HypervisorPresent: True“), was VirtualBox ausbremst. |
| **Windows XP SP3 32-Bit** (VirtualBox, VMware Workstation, Hyper-V) | NTVDM vorhanden, die 16-Bit-Installer laufen, WinG und Indeo werden unterstützt, einfacher ISO-Wechsel, Gasterweiterungen | WinG unter NT-Systemen gilt als weniger stabil **[V]**. Eine XP-Lizenz ist nötig. |

Empfehlung: Wenn der native Weg scheitert, **XP SP3 32-Bit in VirtualBox oder VMware** als praktikabelste Lösung; Windows 98 SE in 86Box für maximale Originaltreue. In beiden Fällen die drei Abbilder (nach R1 als ISO) als virtuelle CD einbinden und das Original-`SETUP.EXE` normal ausführen. Eine eigene, lizenzierte Windows-Kopie ist Voraussetzung.

**ScummVM [V, Internetrecherche]:** Die Gob-Engine erkennt ADI 4 bzw. ADDY 4 (deutsche Variante seit 2024 in der Erkennung). Laut Wiki fehlen aber noch viele Opcodes, daher nur ein experimenteller Versuch und keine Lösung. Quellen: [ScummVM-Wiki Gob](https://wiki.scummvm.org/index.php?title=Gob), [Commit-Log 2024-07](https://lists.scummvm.org/pipermail/scummvm-git-logs/2024-July/106564.html).

---

## 8. Offene Punkte und Risiken
- Läuft das Deutsch-Modul in `ADI4.EXE` (32 Bit) oder in `OLDAPPLI.EXE` (16 Bit)? Davon hängt ab, ob Win11 nativ überhaupt in Frage kommt. Klärung durch Test nach R1 bis R4.
- Schreibzugriffe auf `C:\WMDO.CFG` und `C:\MDO.CFG` unter Win11.
- Erkennt das Programm eingebundene Abbilder als die richtige CD (Kennungsdatei, Volume-Label)?
- Der Internet-Teil (Club, virtuelles Klassenzimmer) ist dauerhaft funktionslos, weil die Server abgeschaltet sind.
- 16-Bit-Spiele, PAWIN und die Gobliiins-Spiele laufen nur in der VM.

---

## 9. Durchführung R1–R4 (freigegeben am 29.10.2026) und Testprotokoll

Alle Skripte, Protokolle und `.reg`-Dateien liegen in [`Reparatur\`](Reparatur/).

### R1: ISO-Abbilder – ✅ bestanden
- Skript `Reparatur\bin2iso.py`: Für jeden der 2352-Byte-Sektoren werden die 2048 Byte Nutzdaten übernommen. Vorher wird geprüft, ob es ein MODE1-Sektor ist; sonst bricht das Skript ab.
- Ergebnis:
  - `..\ISO\Addy_Coll1.iso`: 326 315 Sektoren, SHA-1 `510A6104…2319`
  - `..\ISO\Addy4_coll2.iso`: 318 966 Sektoren, SHA-1 `452BB353…175F`
- **Test:** 408 bzw. 459 Dateien sind per SHA-1 identisch mit der Referenz aus den BIN-Dateien, 0 Abweichungen. Beide Abbilder lassen sich einbinden: Typ „CD-ROM“, Label korrekt.
- Die SHA-1-Werte der Original-BIN-Dateien sind vor und nach der Umwandlung gleich, sie wurden also nicht verändert.

### R4: Manuelle Installation – ✅ bestanden
- Skript `Reparatur\R4-install.ps1` liest die `MKDIR`/`COPY`-Zeilen aus `SETUP.INF` des eingebundenen CD1-Abbilds. Protokoll: `Reparatur\R4-install.log`.
- Ergebnis:
  - `C:\COKTEL\ADDY4` mit 123 Dateien, jede per SHA-1 gegen die Quelle verifiziert.
  - 43 Ordner (`PA`, `INFO`, `SAVEGAME` mit 40 Unterordnern).
  - Schreibschutz der kopierten Dateien entfernt.
  - Schriften „adi_1 Sans MS“ und „adi1“ pro Benutzer installiert (`%LOCALAPPDATA%\Microsoft\Windows\Fonts`, HKCU).
  - Startmenü → COKTEL → „ADDY 4“.
- Bewusst weggelassen: Installer für WinG und Indeo, WebViewer, `SETPROXY`, Autostart von `ADILOOK`, Neustart.
- Rückgängig: `Reparatur\R4-uninstall.ps1`. Es sichert vorher `SAVEGAME`, `INFO`, `*.INF` und `*.CFG`.

### R2: WinG – ✅ bestanden
- `expand.exe F:\WING\WING32.DL_` → `C:\COKTEL\ADDY4\WING32.DLL`: 12 800 Bytes, PE32, „WinG Version 1.0“, SHA-1 `19535921…6703`.
- Nichts in `SysWOW64` abgelegt.

### R3: Indeo 3.2 – ✅ bestanden
- `IV32NT95.EXE` enthält zwei InstallShield-3-Archive, komprimiert mit PKWARE DCL. Skript `Reparatur\is3extract.py` entpackt sie, **ohne den Installer auszuführen**.
- `IR32_32.DLL`: 199 168 Bytes, genau die im Archiv angegebene Größe. Gültige PE32-DLL mit `DriverProc`, Version **3.24.15.3**, also exakt die von `SETUP.INF` verlangte. Abgelegt in `C:\COKTEL\ADDY4`.
- Registry: `HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\Drivers32` → `vidc.iv32 = C:\COKTEL\ADDY4\IR32_32.DLL`. Import per UAC aus `Reparatur\R3-indeo-register.reg`, ExitCode 0. Rückgängig: `R3-indeo-unregister.reg`.
- **Test** (`Reparatur\test-indeo.ps1` in 32-Bit-PowerShell): `ICOpen('vidc','iv32')` ist erfolgreich, der Codec meldet sich als „IR32 – Intel Indeo(R) Video R3.2“.
- Hinweis: Der Installer enthielt die Intel-Lizenz `Reparatur\LICENSE.TXT`; sie gilt auch für diese Bereitstellung.

### Starttest ADI4.EXE – ❌ Absturz (nicht durch R1–R4 verursacht)
- Testaufbau:
  - Eingebundene Laufwerke: D: = CD3, E: = CD2, F: = CD1 (ISO aus R1).
  - Start von `C:\COKTEL\ADDY4\ADI4.EXE` ohne Kompatibilitätsmodus.
  - Vorher/Nachher-Aufnahme des Systemzustands mit `Reparatur\snapshot.ps1`; Startskript `Reparatur\starttest.ps1`.
- **Ergebnis [F]:** Das Programm beendet sich nach etwa 1 s mit `0xC0000094` (Ganzzahl-Division durch null) an `ADI4.EXE+0x437D5`. Es erscheint kein Fenster.
- Einzige Änderung am System: `C:\COKTEL\ADDY4\CMDLINE.CMD` wurde angelegt. Damit ist bestätigt, dass `ADI4.EXE` diese Datei selbst schreibt (vgl. 1).
- **[F]** Laut Ereignisprotokoll stürzte `ADI4.EXE` schon bei deinen Versuchen am 28.10. (Start von `E:\`) **an genau derselben Stelle** ab. Dein damaliger `SETUP.EXE`-Lauf mit `RUNASADMIN WINXPSP2` stürzte im Kompatibilitätsmodul `AcGenral.DLL` ab (`0xC0000005`).
- **Ursache [F, statische Analyse]:** Die Funktion bei RVA `0x43678` misst die **Lesegeschwindigkeit des CD-Laufwerks**:
  1. Sie liest bis zu 40 × 16 KB von der CD und misst die Dauer in Millisekunden.
  2. Sie rechnet `KB/s = Blöcke × 16000 / Millisekunden`.
  3. Das Ergebnis landet als 16-Bit-Wert an `0x47F954`. Ab mehr als 270 KB/s setzt sie den Modus „schnell“ (`0x47F956 = 2`), ab mehr als 140 KB/s „mittel“ (1), sonst „langsam“ (0).
  
  Auf heutiger Hardware dauert das Lesen 0 ms, und daraus folgt die Division durch null. Die Messung wird nur übersprungen, wenn kein CD-Laufwerk erkannt wurde (`0x47FA99 = 0xFF`); dann findet das Programm aber die CD-Inhalte nicht. Einen Konfigurationsschalter, der nur die Messung abschaltet, gibt es nicht. Ein Kopierschutz ist das nicht.

### P1: Patch der installierten Kopie – ✅ wirkt (freigegeben am 29.10.2026)
- Skript `Reparatur\P1-patch.py`, rückgängig mit `--undo`.
- Die Sicherung `C:\COKTEL\ADDY4\ADI4.EXE.orig` (SHA-1 `74B9403F…FA14`) ist identisch mit `ADI4.EXE` auf CD1.
- Gepatcht: SHA-1 `EE2AE1BB…BAA8`, genau 36 geänderte Bytes in `0x42DC2–0x42DE5`.
- **Test:** Keine Division durch null mehr. Das Programm schreibt `WMDO.CFG = 00 00 03 00 02 B0 04`, also 1200 KB/s und Modus 2. Ab dem zweiten Start liest es diese Datei, statt erneut zu messen.

### Weitere Windows-11-Probleme (gefunden mit eigenem API-Tracer `Reparatur\apitrace.ps1`)
1. **Liegengebliebenes Atom [F].**
   - `ADI4.EXE` legt beim Start das globale Atom `MDOLoaderLaunched` an und beendet sich sofort ohne Meldung, wenn es bereits existiert (Doppelstart-Schutz).
   - Nach einem Absturz bleibt das Atom bis zur Abmeldung stehen. Daher kamen die „stillen“ Starts mit ExitCode 0.
   - Abhilfe ohne Dateiänderung: `Reparatur\clear-atom.ps1` oder ab- und wieder anmelden.
2. **Endlosschleife beim Beenden [F].**
   - Bei `0x437DBD` ruft das Programm `GlobalDeleteAtom` so lange auf, bis ein Fehler zurückkommt. Windows 95 lieferte beim zweiten Löschen einen Fehler, Windows 11 meldet immer 0 („Erfolg“). Das ist mit einem eigenen Test belegt.
   - Folge: schwarzes Vollbild, 100 % CPU auf einem Kern, nach einiger Zeit „reagiert nicht“ (Ereignis 1002 um 01:00:39).
   - Abhilfe wäre ein weiterer Mini-Patch (P2). Er ist noch nicht angelegt.
3. **Programm beendet sich nach etwa 1,1 s, Ursache noch offen [F/V].** Belegter Ablauf:
   - `MDO.DEF` gelesen, CD1 auf F: erkannt, `WMDO.CFG` geschrieben;
   - `INTRO.STK` geöffnet, Archivverzeichnis gelesen;
   - `INTRO.INF` gelesen, Hauptfenster „Loader Windows“ erzeugt, fünf Durchläufe der Nachrichtenschleife;
   - danach direkt die Beenden-Routine.
   
   Es wird **kein Skript** (`intro.tot`) aus dem Archiv geladen. Die engine-eigene Protokollierung (`_trace_=1`, nur vorübergehend gesetzt und wieder zurückgebaut) erzeugt eine leere `TRACE.TXT`.
   
   Ausgeschlossen sind:
   - Schreibrechte: `WMDO.CFG` landet im Programmordner.
   - Die leeren `.let`/`.crf`-Zugriffe: Das sind die Leerzeilen in `INTRO.INF`.
   - Startparameter: `ADDLNG_AND_DRIVE` ändert nur den Namen der Verknüpfung.
   
   Die Farbtiefe (Windows meldet 32 Bit, `MDO.DEF` erlaubt `8+16+24`) wird in der Funktion `0x40BCD0` geprüft. Der Windows-Modus „16-Bit-Farbe“, getestet nur für einen Prozess über `__COMPAT_LAYER`, änderte am Ergebnis nichts.
   
   Für die weitere Analyse fehlt ein Disassembler; bisher wurde nur von Hand aus Hex-Dumps gelesen.

### Disassembler-Analyse (capstone 5.0.9, freigegeben) – Punkt 3 aufgeklärt [F]
- Die Atom-Schleife bei `0x437DD8` gehört **nicht** zum Programmende. Sie bildet den **Abschluss der Initialisierung** in der Hauptroutine `0x43720E`. Danach geht es mit `ShowCursor`, der Nachrichtenschleife und dem Start der Skripte weiter.
- Punkt 2 (Hänger) und Punkt 3 („beendet sich nach 1,1 s“) sind also **derselbe Fehler**. Der Eindruck eines vorzeitigen Endes kam daher, dass der Tracer genau dort abbrach.
- **Test nur im Speicher** (`apitrace.ps1 -EmulateWin95Atom`, keine Dateiänderung): Ab dem zweiten Aufruf liefert der Tracer die Windows-95-Antwort von `GlobalDeleteAtom`. Ergebnis:
  - Das Programm läuft weiter, startet `ADILOOK.EXE` selbst, lädt `intro.tot`, erkennt CD1 über `AE63*.CD1`, spielt `INTRO.VMD` (Sternenhimmel sichtbar) und lädt die Figuren-Videos.
  - Nach 75 s lief es noch; der Tracer hat es dann beendet.
  - Beim ersten Lauf legte es im Programmordner an: `ADI4.INI`, `ado4.inf`, `PREMIER.DEP`, `DATA\MCURRENT.INF`. Damit ist **[F]** belegt, dass Profil- und Zustandsdaten im Installationsordner liegen.
- **Neue Beobachtung [V]:** Das Bild erschien verschoben in der rechten unteren Bildschirmecke. Vermutete Ursache: Windows-Skalierung (Monitor 3840×2160, das Programm sieht 1536×864). Das ist noch zu prüfen.
- Ohne `capstone` war `-I` nicht nutzbar: Das Paket liegt im Benutzer-`site-packages`. Das Disassembler-Skript lief daher ohne `-I`, aus dem Scratchpad.

### Vorschlag P2 (wartet auf Freigabe)
- Skript: `Reparatur\P2-patch.py`, rückgängig mit `--undo`. Vorher wird die Sicherung `ADI4.EXE.vorP2` angelegt.
- Änderung: **2 Bytes** bei Dateioffset `0x373E1` (VA `0x437DE1`). `75 F5` (`jne`) wird durch `90 90` (`nop nop`) ersetzt; das Atom wird damit genau einmal gelöscht. Das Programm hat es wenige Befehle vorher selbst genau einmal angelegt.
- Das Skript prüft vorher die 11 erwarteten Bytes `53 E8 DF 50 03 00 66 3B D8 75 F5` und bricht bei Abweichung ab; die Prüfung ist bereits erfolgt und stimmt.

### P2 angewendet (freigegeben am 29.10.2026) – ✅ ADDY startet
- `Reparatur\P2-patch.py` hat genau 2 Bytes geändert (`0x373E1`, `0x373E2`).
- Sicherung `ADI4.EXE.vorP2` (SHA-1 `EE2AE1BB…`, Stand nach P1); neuer SHA-1 `CCA3EC87…9117`.
- **Test (normaler Start, ohne Tracer):**
  - Das Fenster „ADDY“ erscheint; `ADILOOK.EXE` wird vom Programm selbst gestartet.
  - Der Startbildschirm mit Addy wird angezeigt, kein Hänger, etwa 60 % eines CPU-Kerns.
  - **Aber:** Das 640×480-Bild sitzt verschoben unten rechts und ist abgeschnitten.

### Bildposition – Ursache und Lösung gefunden [F]
- Getestet wurde pro Prozess über die Umgebungsvariable `__COMPAT_LAYER`, ohne Registry. Ergebnisse:
  - `640X480`: Windows schaltet während der Laufzeit auf 640×480. ADDY füllt den Bildschirm korrekt, Titelbild „ADDY“ mit Figur. ✅
  - `HIGHDPIAWARE`: schwarzes Bild. ❌
  - `640X480 HIGHDPIAWARE`: läuft ebenfalls (wie `640X480`).
- Nach dem Beenden stellt Windows die Auflösung auf 3840×2160 zurück, das ist geprüft.

### Vorschlag P3 (wartet auf Freigabe): Kompatibilitätsmodus dauerhaft setzen
- `HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers`
  - Wertname `C:\COKTEL\ADDY4\ADI4.EXE`, Inhalt `~ 640X480`
  - Das entspricht im Explorer: Eigenschaften → Kompatibilität → „In Bildschirmauflösung 640 × 480 ausführen“.
- Wirkt nur für deinen Benutzer und nur für diese Datei. Rückgängig: den Wert löschen.

### Klassenwahl ohne Wirkung – Ursache und Lösung (P4, freigegeben) ✅
- **Symptom:** Profilerstellung und Hover funktionierten, ein Klick auf eine Klassenstufe bewirkte nichts.
- **Mitschnitt 1 [F]:** Nach dem Klassen-Video `AICLAA0.VMD` gab es keinen einzigen Dateizugriff.
  - Vorher hatte das Skript `AE63*.CD?` gesucht, und zwar über `<CD>` (zu dem Zeitpunkt leer, daher `C:\COKTEL\ADDY4\`). Ergebnis: nicht gefunden.
  - Danach schrieb es `ADI4.INI [ChgtCD] envir=` leer.
  - Die Skripte prüfen zusätzlich `<ME>AE63*.CD1`, also eine Produktkennung im Installationsordner.
- **Ursache [F/V]:** Die Kennungsdatei `AE63D401.CD1` fehlte im Installationsordner. Das Original-`SETUP.EXE` behandelt `.CD1`-Dateien gesondert und kopiert sie vermutlich mit **[V]**; in der `COPY`-Liste von `SETUP.INF` steht sie nicht.
- **P4:** `F:\AE63D401.CD1` → `C:\COKTEL\ADDY4\AE63D401.CD1` (3 Bytes, hash-identisch). Rückgängig: die Datei löschen.
- **Mitschnitt 2 [F]:**
  - `AE63*.CD?` wird jetzt gefunden.
  - ADDY nutzt danach alle drei CD-Laufwerke: D:, E:, F: (u. a. `MULTICD.INF`, `ENVIR.STK`, `ADIANI.ITK`, `DOC.ITK`).
  - Die Klassenwahl funktioniert, `ADI4.INI` enthält `niveau=53`.
  - Neu angelegt wurden `ADI.INF` (Profil), `PERSO.DEP`, `PAROLE.DEP`, `DATA\CONFIG00.INF`, `DATA\STATEV00.INF`, `DATA\RESF6200.INF` (Ergebnisdatei zum Deutsch-Modul, Kennung F62).
  - Der Nutzer bestätigt: „Es hat alles super funktioniert.“
  - Ende nach etwa 10 Minuten, durch den Nutzer, mit ExitCode 0.

### Stand 29.10.2026: ADDY läuft unter Windows 11
Voraussetzungen, alle umgesetzt außer P3:
- R1–R4 und P4 (Installation, WinG, Indeo, Kennungsdatei).
- P1 (CD-Geschwindigkeitsmessung) und P2 (Atom-Schleife) als Patches an der installierten `ADI4.EXE`; Originale gesichert.
- Start mit dem Kompatibilitätsmodus **640×480**. Bisher nur pro Start gesetzt; dauerhaft wäre das P3, noch nicht umgesetzt.
- CD-Abbilder eingebunden: CD1 (`Addy_Coll1.iso`), CD2 (CloneDrive) und CD3 (`CD3.ISO`).
- Nach einem Absturz von ADDY: `Reparatur\clear-atom.ps1` ausführen oder sich ab- und wieder anmelden.

### P3 durch den Nutzer gesetzt
Der Nutzer hat in den Eigenschaften von `C:\COKTEL\ADDY4\ADI4.EXE` das Häkchen „In Bildschirmauflösung 640 x 480 ausführen“ selbst gesetzt. Geprüft in HKCU: `~ 640X480`.

### Offen: Animationen frieren ein, der Ton läuft weiter
Beispiel ist der Dinosaurier im Regal im Kinderzimmer: `XDYNOF.VMD` aus `ADIANI.ITK` (CD1), 102 Bilder, Position (0,181), 183×159 Pixel, 24-Bit-VMD, Version 13. Er bewegt sich kurz und steht dann rund 9 s still, während der Ton läuft.

**Belegt [F]:**
1. **Tritt auch ohne Tracer auf.** Der passive Rekorder (`Reparatur\recorder.ps1`) zeigt 10 s ohne jede Bildänderung, ADDY lastet dabei einen CPU-Kern voll aus.
2. **Die Tonuhr ist korrekt.** `waveOutGetPosition` läuft in Echtzeit, Format 22050 Hz, 16 Bit, mono, ein durchgehender Strom mit Ringpuffer.
3. **Bild und Ton sind synchron.** Die Abweichung liegt bei 0 bis 10 ms (Haltepunkt `0x460801`), der Wartemodus wird nicht aktiv.
4. **Die Bildfreigabe stimmt.** Bild 1 bis 107 im richtigen Takt (Haltepunkt `0x4608C6`; 1837 Samples pro Bild, 22050 Hz, also 12 Bilder/s).
5. **Gezeichnet wird.** `DrawDibDraw` (MSVFW32) gibt den Bereich (0,181) 183×159 etwa 20 Mal pro Sekunde über `SetDIBitsToDevice` aus. Der **Inhalt bleibt aber gleich**. Die Einzelbilder kommen also nicht im Ausgabepuffer an, oder DrawDib zeigt einen veralteten Puffer.

**Ausgeschlossen [F]:**
- Indeo bzw. ein externer Codec: In den ITK-Archiven gibt es keine durchgehenden FourCCs.
- 32-Bit-Farbtiefe: Auch mit `640X480 16BITCOLOR` bewegt sich der Dino nur kurz.
- Bild-Ton-Synchronisation und das Abspieltempo.

**DirectDraw-Modus:** `_directx_=1` in `INTRO.INF` (nur vorübergehend gesetzt, wieder zurückgebaut und per Hash geprüft) lässt ADDY in `DDRAW.DLL+0x4CBD8` abstürzen (`0xC0000005`, zweimal).

**Dekoder-Analyse (29.10.2026) [F]:**
1. **DrawDib ist nicht die Ursache.** Der Quellpuffer von `DrawDibDraw` (640×480, 24 Bit) behält von 7,96 s bis 16,95 s denselben Hash (`0xB2EEF498`).
2. **Die Datei ist intakt.** Alle 101 Folgebilder von `XDYNOF.VMD` enthalten Bilddaten (2–6 KB, Typ `0x81` = LZ77 + Teilbild mit Transparenz, Teil-Flag `0x40`). Bild 0 hat Typ `0x82` und Flag `0x00`.
3. **Die Bilder werden dekodiert.** `0x45978C` (LZ77 `0x40185C`, Teilbild-Renderer) schreibt jedes Bild in die eigene 16-Bit-Fläche der Animation (368 Bytes × 159 Zeilen).
4. **Der Kopierschritt in den Bildschirmpuffer fehlt.** Ein Hardware-Schreibhaltepunkt auf einen Dino-Pixel im Bildschirmpuffer zeigt Schreibzugriffe nur bei 8,58 s (Bild 0, über den Skript-Zeichenbefehl `0x41715D` → `0x44BDAC` → `0x43F418`). Danach gibt es keine mehr.
5. **Wer die Bilder in dieser Phase abspielt:** Der Skriptbefehl „VMD-Bild abspielen“ (`0x42B6A0`, der beim Intro zeichnet) läuft in der Dino-Phase nicht. Nur die Hintergrund-Animationssteuerung `0x45EE00` arbeitet (etwa 85.000 Aufrufe in 9 s, aus der Leerlauf-Rückruffunktion der Nachrichtenschleife).
6. **Warum sie nichts zeichnet:** `0x45EE00` nimmt einen Bildbereich nur dann ins Neuzeichnen auf, wenn `Ergebnis & 0x805335 == 0`. Gespielte Dino-Bilder liefern `0x4081` (→ `0x4001`), noch nicht fällige `0x1234`. Damit wird **nie** ein Bereich übernommen.

**Offen [V]:** Unter Windows 95 müssen Daten und Code denselben Weg genommen haben. Der Unterschied muss daher von einem Windows-Rückgabewert oder vom Zeitverhalten kommen. Vermutlich erledigt im Original ein anderer Programmteil das Neuzeichnen der Hintergrund-Animationen, etwa die Warteschleife des Skripts oder die Sprite-Verwaltung `0x45C858`/`0x45D340`, und der greift unter Windows 11 nicht. Das ist noch nicht belegt.

Ausgeschlossen sind außerdem die Leistungsstufen: Mit `MPC1`/`MPC2` als Startparameter gibt es ebenfalls keine Bewegung.

**Ursache gefunden [F]:**
- Der Dino wird vom Skript über den Befehl „VMD-Bild abspielen“ (`0x42B6A0`) gezeichnet. Das Skript läuft dabei mit 10 Takten/s (`0x420860`: `[0x484EC8] = 100 ms`, gemessen) und übergibt als Obergrenze einen eigenen Bildzähler (+1 pro Takt).
- Gleichzeitig hängt der Ton der VMD am Ton-Mischer (`0x45EE00`, Kanaltabelle `0x48C760`). Der dekodiert zur Tonversorgung laufend Bilder und schaltet das aktuelle Bild im Tontakt weiter: 12 Bilder/s, `waveOutGetPosition` in Echtzeit.
- Damit liegt das aktuelle Bild bald **vor** dem Skriptzähler (gemessen z. B. 37 gegenüber 32).
- Der Befehl prüft bei `0x42B6DF` `cmp ax, di` / `jge` und meldet in diesem Fall sofort „fertig“, **ohne zu zeichnen**.
- Der Mischer selbst zeichnet nicht, weil das Ergebnis `0x4081` die Maske `0x805335` trifft; das ist so gewollt.
- Ergebnis: Die Bilder werden dekodiert, erscheinen aber nie.
- **[V]** Unter Windows 95 lag das aktuelle Bild offenbar nicht dauerhaft vor dem Skriptzähler, weil Mischer und Ton anders getaktet waren. Warum genau, ist nicht abschließend geklärt.

**Test nur im Speicher [F]:** `apitrace.ps1 -MemPatch 0x42b6e2:7d07:eb07` (`jge` → `jmp`). Der Dino bewegt sich: In acht Bildschirmfotos über 8 s ist jedes Bild anders (Drehung, Lampe, Kiste, kleine Figur). ADDY lief 22 s stabil.

### P6 angewendet (freigegeben am 29.10.2026) – ✅ Animationen laufen
- Genau 1 Byte geändert (`0x2ACE2`). Sicherung `ADI4.EXE.vorP6` (SHA-1 `CCA3EC87…`, Stand nach P2); neuer SHA-1 `631F30A1…7E30`.
- **Test (normaler Start, ohne Tracer, 640×480):**
  - Die Dino-Szene spielt sichtbar ab: Lampe, Kiste und kleine Figur erscheinen, der Dino dreht sich (Bildschirmfotos bei 16,5 s, 18 s und 21 s unterscheiden sich).
  - Danach endet die Animation, und ADDY schaltet regulär zur nächsten Ansicht.
  - ADDY läuft nach 30 s stabil, kein Fehlereintrag im Ereignisprotokoll.
- Noch zu prüfen durch den Nutzer: weitere Animationen und Lernmodule im Spielbetrieb.

### Abgetrennte Bildreste nach P6 (z. B. Punk rechts) – Ursache [F]
- Nach P6 zeichnet der Skriptbefehl nur das Änderungsrechteck `[0x490AB0..0x490ABC]` des **zuletzt** gespielten Bildes (`0x42BAB0` → `0x44BDAC`).
- Der Player setzt dieses globale Rechteck bei jedem Bild zurück (`0x460B26`). Die Bilder, die der Ton-Mischer dazwischen abspielt, verlieren dadurch ihre Rechtecke. Ihre Änderungen erreichen den Bildschirm nie, und es bleiben Reste stehen.
- **Speichertest (A/B):** Bildschirmfotos zu denselben Zeitpunkten ohne und mit Patch.
  - Ohne Patch bleibt bei 18 s und 20 s ein kopfüber fliegender Punk als Rest oben stehen.
  - Mit Patch gibt es keine Reste.

### P7 angewendet (freigegeben am 29.10.2026) – ✅ keine Bildreste mehr
- Sicherung `ADI4.EXE.vorP7` (SHA-1 `631F30A1…`, Stand nach P6); neuer SHA-1 `D1D8EDE9…5EC0`.
- 47 Bytes geändert, in den Bereichen `0x2B0B0`–`0x2B0B7` und `0x6CA80`–`0x6CAAC`. Einige Bytes des Code-Stücks sind selbst `00` und gelten deshalb nicht als geändert.
- **Test (normaler Start, ohne Tracer):** 13 Ausschnitte der Punk-Ecke von 14 s bis 38 s.
  - Der Punk animiert (kniend, kopfüber am Teleskop) und steht ab 18 s wieder sauber an seinem Platz.
  - Es bleibt kein abgetrennter Rest zurück.
  - ADDY lief stabil, kein Fehlereintrag im Ereignisprotokoll.

### Vorschlag P7 (umgesetzt, s. o.)
- `Reparatur\P7-patch.py`, Sicherung `ADI4.EXE.vorP7`, rückgängig mit `--undo`.
- **Hook:** Dateioffset `0x2B0B0` (VA `0x42BAB0`), 8 Bytes: `push 0; mov edx,[0x490AB8]` wird zu `jmp 0x46D480; nop×3`.
- **Code-Stück:** 45 Bytes in einer ungenutzten Null-Lücke am Ende des Codebereichs (Datei `0x6CA80`, VA `0x46D480`; keine Verweise darauf, Sektion ausführbar, EXE ohne ASLR). Es setzt das Rechteck auf das volle Animationsbild (0,0)–(B−1,H−1) aus `[ebx+0xA]`/`[ebx+0xC]`, führt die zwei Originalbefehle aus und springt nach `0x42BAB8` zurück.
- Folge: Pro Bild wird die ganze (kleine) Animationsfläche kopiert statt nur des Teilrechtecks; die Mehrlast ist gering.

### Vorschlag P6 (umgesetzt, s. o.)
- `Reparatur\P6-patch.py`, **1 Byte**: Dateioffset `0x2ACE2` (VA `0x42B6E2`), `7D` → `EB`. Sicherung `ADI4.EXE.vorP6`, rückgängig mit `--undo`.
- Die erwarteten Bytes `66 3B C7 7D 07` sind bereits geprüft.
- Die Prüfung „Bildnummer < 0 → fertig“ bleibt unverändert.
- **Risiko [V]:** Der Befehl meldet nicht mehr „fertig“, wenn das aktuelle Bild vor dem Skriptzähler liegt. Das Ende einer Animation erkennt das Skript vermutlich über andere Bedingungen. Dass Animationen sauber enden bzw. in Schleife laufen, muss sich im Spiel zeigen.

### P5 Portable-Variante umgesetzt (freigegeben am 29.10.2026) – ✅ Start ohne CD-Abbilder
- Kopiert per robocopy: CD1 (aus `Addy_Coll1.iso`, F:) → `C:\COKTEL\ADDY4\CD1`, CD2 (E:) → `\CD2`, CD3 (`CD3.ISO`, D:) → `\CD3`.
- **Prüfung:** 879/879 Dateien per SHA-1 identisch mit der Referenz aus den Original-Abbildern (408 + 459 + 12). CD2 zählt 458 Dateien, weil ein Eintrag auf der CD doppelt geführt ist.
- **`INTRO.INF`:** Sicherung `INTRO.INF.vorP5`, neue Zeile `_vcdrom_=C:\COKTEL\ADDY4\CD3\;C:\COKTEL\ADDY4\CD2\;C:\COKTEL\ADDY4\CD1\`.
  - Die abschließenden Backslashes sind nötig, weil das Präfix `<CD>` den Dateinamen direkt an den gefundenen Wurzelpfad hängt (`0x431B57`).
  - Die Reihenfolge entspricht dem bisher funktionierenden Aufbau D:=CD3, E:=CD2, F:=CD1.
  - Länge 62 von 128 möglichen Zeichen.
- **Test (D: und F: ausgehängt; E: hängt noch in CloneDrive, Tracer):**
  - ADDY startet, das Kinderzimmer erscheint.
  - CD-Kennung und Archive kommen aus `C:\COKTEL\ADDY4\CD1..3` (`ADIANI.ITK`, `ADIBLA.ITK`, `BOUTON.TOT`).
  - Auf E: gibt es keinen Dateizugriff, nur die Laufwerkstyp-Abfrage.
  - 30 s stabil.
- **Bestätigt durch den Nutzer (29.10.2026):** E: (CloneDrive) ausgeworfen, also ohne jedes CD-Abbild, ADDY bis ins Deutsch-Modul gespielt: „Getestet, klappt“.
- **Rückgängig:** `INTRO.INF.vorP5` zurückkopieren und die Ordner `CD1..CD3` löschen.

### Minispiele: 16-Bit-Spiele starten nicht (Tracer, 29.10.2026) [F]
- Beim Klick auf „Rocket Scrambler“ ruft ADDY `CreateProcessA(NULL, "C:\COKTEL\ADDY4\CD2\GAMES\SCRAM\SCRAM.EXE 290869 C:\COKTEL\ADDY4\", …)` auf (von `0x42F73D`). Rückgabe **0**, also fehlgeschlagen; zweimal im Mitschnitt. ADDY wertet das als „Spiel beendet“ und spielt das Abschlussvideo.
- `SCRAM.EXE` ist ein NE-Programm (16-Bit-Windows). Ein 64-Bit-Windows kann es nicht ausführen, weil das NTVDM-Subsystem fehlt.
- Spieleliste:
  - **16 Bit, scheitern:** Rocket Scrambler, Blaze, Gobliiins III, Französisches Billard.
  - **32 Bit, sollten laufen [V]:** Revolution, Filler, Break Time.
- Lösungsweg [V]: **winevdm (otvdm)**, ein Open-Source-Emulator für 16-Bit-Windows auf x64. Die Installation trägt eine Umleitung ein (Registry `NtVdm64`), sodass `CreateProcess` 16-Bit-Programme an otvdm übergibt; ADDY bleibt unverändert. Dafür sind ein Download und Adminrechte nötig. Rocket Scrambler braucht zusätzlich die 16-Bit-WinG-Bibliothek; ob das mit winevdm läuft, ist offen.

### otvdm v0.9.0 (vom Nutzer installiert) – Test
- Der Ordner liegt in `C:\COKTEL\otvdm-v0.9.0`. Die Registry-Umleitung `HKLM\…\NtVdm64\0OTVDM` zeigt aber auf `MappedExeName = C:\Users\<Name>\Downloads\otvdm-v0.9.0\otvdm-v0.9.0\otvdmw.exe`, den es nicht mehr gibt: Der Ordner wurde nach der Installation verschoben. Die Umleitung greift daher nicht.
- `install.inf` trägt `MappedExeName` als `%01%\otvdmw.exe` ein, also als Ordner der INF. Ein erneutes „install“ aus dem neuen Ordner korrigiert den Eintrag.
- **Direkttest [F]:** `otvdmw.exe "…\CD2\GAMES\SCRAM\SCRAM.EXE" 290869 C:\COKTEL\ADDY4\` startet das Spiel: Fenster „Rocket Scrambler for Windows“, Titelbild und deutsches Menü. WinG kommt über otvdms `wing.dll16`. Der Test wurde danach beendet; es wurden keine Dateien geändert.

### P8: otvdm-Umleitung neu eingetragen (auf Wunsch des Nutzers übernommen) – ✅
- Ausgangslage: Ein erneutes „install“ meldete beim Nutzer einen Fehler. Danach fehlte der Schlüssel `NtVdm64\0OTVDM` in beiden Registry-Ansichten ganz.
- `Reparatur\P8-otvdm-register.reg` trägt dieselben Werte wie otvdms `install.inf` ein, mit festem Pfad `MappedExeName = C:\COKTEL\otvdm-v0.9.0\otvdmw.exe`. Ziel ist HKLM 64 Bit und `WOW6432Node`. Import per UAC, ExitCode 0. Rückgängig: `P8-otvdm-unregister.reg`.
- **Test [F]:** Ein 32-Bit-Prozess ruft `CreateProcess` auf `SCRAM.EXE 290869 C:\COKTEL\ADDY4\` auf (wie ADDY). Das gelingt: Windows startet `otvdmw.exe`, Fenster „Rocket Scrambler for Windows“.
- Wichtig: Der Ordner `C:\COKTEL\otvdm-v0.9.0` darf nicht mehr verschoben werden.
- Noch offen: Test aus ADDY heraus durch den Nutzer, inklusive der anderen 16-Bit-Spiele.

### P9: Rocket Scrambler viel zu schnell – behoben (freigegeben am 29.10.2026) ✅
- **Tempo-Logik [F]** (Segment 2 von `SCRAM.EXE`, 16-Bit-Code mit capstone gelesen):
  - Ein Spielschritt kommt alle `[0xE80] × Grundtakt` ms. Grundtakt laut Menü „Steuerung“: Langsam 25, Normal 15, Schnell 10, Sehr schnell 0 ms.
  - `[0xE80]` ermittelt eine Messschleife beim Start (`2:19BC`).
- **Ursache [F]:** Bei `2:08C1` (`jbe 0x8F8`) führt die Hauptschleife einen Spielschritt **sofort** aus, wenn `timeGetTime` seit dem letzten Schritt nicht weitergezählt hat. Heute passen viele Schritte in dieselbe Millisekunde, das Spiel läuft also nahezu ungebremst. Auch „Langsam“ war deshalb laut Nutzer „viel zu schnell“.
- **Patch:** Dateioffset `0x3BC1`: `76 35` → `90 90`. Damit geht auch dieser Fall durch die normale Abstandsprüfung.
  - Zuerst als Testkopie im Scratchpad geprüft; der Nutzer bestätigt: „Passt jetzt“.
  - Danach mit `Reparatur\P9-patch.py` auf `C:\COKTEL\ADDY4\CD2\GAMES\SCRAM\SCRAM.EXE` angewendet. Sicherung `SCRAM.EXE.vorP9`, rückgängig mit `--undo`. Neuer SHA-1 `4D998C1E…E64E`, identisch mit der Testkopie.
- Hinweis: Andere 16-Bit-Spiele (Blaze, Gobliiins III, Französisches Billard) können ähnliche Tempoprobleme haben; das ist nicht geprüft.

### Profil: Punkte erhöht, um die Minispiele testen zu können (auf Wunsch des Nutzers)
- **Sicherungen:**
  - `Documents\Addy\Sicherung_Profil_20261029_230214`: Stand mit 1 Lektion.
  - `…_235809_30Punkte`: Stand nach weiteren Lektionen, 30 Punkte.
  - Beide enthalten `ADI.INF`, `ADI4.INI`, `ado4.inf`, `PERSO.DEP`, `DATA\`, `SAVEGAME\`, `INFO\` und eine `INHALT.txt` mit SHA-1.
- **Vorher/Nachher-Vergleich [F]:** Die Punkte stehen in `ADI.INF` bei `0xCA9` und `0xCAA` (je 1 Byte, beide gleich). Sie stiegen von `02 02` auf `1E 1E` (30). Weitere Lektionsdaten: `0x25C`, `0x268`, `0x472`, `0xA12`, ab `0xE16`, dazu `DATA\STATEV00.INF` und `RESF5200/6200.INF`.
- **Änderung:** `0xCA9`/`0xCAA` von `1E 1E` auf `7F 7F` (127). Das ist der größte Wert, der auch bei vorzeichenbehafteter Auswertung sicher positiv bleibt.
- **[V]** Ob die Spiele über die Punkte freigeschaltet werden und ab welcher Schwelle, ist nicht belegt. Das zeigt erst der Test.
- **Rückgängig:** ADDY beenden und die Dateien einer der Sicherungen nach `C:\COKTEL\ADDY4` zurückkopieren.

### P5 zurückgenommen (30.10.2026, auf Wunsch des Nutzers) – ADDY braucht wieder eine CD
- `C:\COKTEL\ADDY4\INTRO.INF` wurde aus `INTRO.INF.vorP5` wiederhergestellt; sie ist per SHA-1 identisch mit der Fassung auf CD1. Die Zeile `_vcdrom_` gibt es nicht mehr. Die Fassung mit P5 liegt als Kopie im Scratchpad (`INTRO.INF.mitP5`).
- **Folgen:**
  - ADDY sucht seine Daten wieder auf CD-Laufwerken. CD1 und CD3 (und für die Spiele CD2) müssen eingebunden sein, z. B. `..\ISO\Addy_Coll1.iso`, `..\CD3\CD3.ISO` und CD2 per CloneDrive bzw. `..\ISO\Addy4_coll2.iso`.
  - **P9 (Tempo-Korrektur Rocket Scrambler) gilt nur für die Kopie in `C:\COKTEL\ADDY4\CD2`.** Von der CD bzw. dem Abbild startet das unveränderte `SCRAM.EXE`, das Tempoproblem kehrt also zurück.
  - Die Ordner `C:\COKTEL\ADDY4\CD1..CD3` (ca. 1,7 GB) sind noch vorhanden, werden aber nicht mehr benutzt.
- Unverändert bleiben P1, P2, P4, P6, P7, die 640×480-Einstellung, otvdm (P8) und der Profilstand (255 Punkte).

### ISO-Abbilder in `C:\COKTEL\Addi - Deutsch` (30.10.2026)
- Die BIN-Dateien dort sind per SHA-1 identisch mit den ursprünglich geprüften Originalen.
- Neu angelegt mit `Reparatur\bin2iso.py` (verlustfrei, MODE1-Prüfung jedes Sektors):
  - `CD1 Install\Addy_Coll1.iso` (SHA-1 `510A6104…2319`)
  - `CD2\Addy4_coll2.iso` (SHA-1 `452BB353…175F`)
- Beide sind identisch mit den bereits verifizierten ISOs in `Documents\Addy\ISO` und lassen sich einbinden (Typ CD-ROM, Labels `Addy_Coll1` / `Addy4_coll2`).
- BIN/CUE bleiben unverändert erhalten. CD3 lag dort schon als ISO vor.

### Stand 02.11.2026: Patch-Paket, Neuinstallation und P10
**Paket:** `ADDY-Win11-Patch\` mit `Installieren.cmd`, `Deinstallieren.cmd` (je eine Datei mit eingebettetem PowerShell-Skript) und `LIESMICH.txt`. Es braucht kein Python und enthält keine Spieldateien. Quellen: CD-Laufwerk, `.iso`, `.bin`, `.cue`. Die Installation legt zusätzlich eine Desktop-Verknüpfung mit dem ADDY-Icon und `Uninstall.exe` im Programmordner an.

**Letzter Testlauf [F]:** `Deinstallieren.cmd`, `Installieren.cmd` mit automatisch gefundenen ISOs, `Uninstall.exe /silent` und die Abfrage des Deinstallationsskripts (Antwort „n“ lässt alles stehen, „j“ deinstalliert) liefen ohne Fehler und ohne Reste. Danach Endinstallation und Start über die Desktop-Verknüpfung: 640×480, Regler 1,00, Pegel bis 1,000, sauberes Ende, keine Startmarkierung. Nicht geprüft: der Doppelklick auf `Uninstall.exe` mit Abfrage als Gesamtablauf und die Anzeige des Desktop-Icons (das Icon aus `ADI4.EXE` selbst ist geprüft). `ADILOOK.EXE` wird von ADDY selbst gestartet und lief nach dem Beenden weiter; die Deinstallation beendet es.

**Getestet [F]:**
- Deinstallation: Programmordner, Schriften, Startmenü, Kompatibilitätseintrag, `vidc.iv32` und `0OTVDM` entfernt. `Addi - Deutsch` und `otvdm-v0.9.0` blieben erhalten. Spielstand mit 255 Punkten gesichert in `Documents\Addy\Sicherung_Profil_20261102_080923_255Punkte` (nicht zurückgespielt).
- Installation: CD1 über Laufwerkserkennung (eingebundenes ISO), CD2 aus `.cue`/`.bin`. Alle Prüfsummen und Registry-Einträge stimmen.
- Der Nutzer bestätigt: Klassenwahl und Animationen funktionieren. Mein Klick-Test der Klassenwahl war falsch: Die Auswahl wird mit der Eingabetaste bestätigt, kein Programmfehler.
- Abschlusslauf mit P10, Paket in `C:\COKTEL\Addi - Deutsch\ADDY-Win11-Patch`: Deinstallation, dann Installation ohne Angaben mit automatisch gefundenen ISOs neben dem Paket. Alle Prüfsummen und Einträge stimmen, die Images wurden wieder ausgehängt, keine Temp-Reste, ein zweiter Lauf bricht bei vorhandenem Ordner ab.
- Start über den Startmenü-Eintrag: 640×480, Regler 1,00, Pegel am Ausgang bis 1,000; der Nutzer bestätigt den Ton. Danach meldet der Nutzer: „ich hab alles getestet - lief alles“.
- Die 255-Punkte-Sicherungen liegen auf Wunsch des Nutzers im Papierkorb.

**Nicht getestet:**
- Installation von einer echten physischen CD (nur eingebundene Images).
- Minispiele: laut Nutzer vorerst außerhalb des Umfangs. P8 und P9 bleiben unverändert im Paket. Rocket Scrambler aus ADDY heraus ist mit der geänderten `INTRO.STK` (14 Einträge `<CD>` → `<ME>`) von mir nicht geprüft.

### Ton fehlt: Ursache und Lösung (P10, freigegeben)
- **Symptom:** Kein Ton beim Start, später teils doch.
- **Messung [F]:** ADDY erzeugte Pegel bis 1,1, sein Mixer-Regler stand aber auf 0, am Ausgang kam 0,000 an. Windows speicherte für `ADI4.EXE` auf dem Marantz-Ausgang 0, auf dem USB-Gerät 0,999.
- **Code [F]:** `ADI4.EXE` liest beim Start die Lautstärke (`0x437516`) und schreibt sie beim Beenden zurück (`0x436C71`, `0x438040`); Skripte können sie ebenfalls setzen. Unter Windows 11 wirkt `waveOutSetVolume` auf den Regler des Programms, und Windows behält den Wert. Eine einmal gespeicherte 0 erhält sich dadurch selbst.
- **Offen [V]:** Woher die erste 0 stammt. Dass der Ton „später dazukam“, könnte an den Skripten liegen, ist aber nicht nachgewiesen.
- **P10:** Dateioffset `0x36B16` `E889EA0000A3D8644800` → `6A64E8D3EA0000599090` (Start: 100 % setzen); `0x3626B` und `0x3763A` `FF35D8644800` → `6AFF90909090` (Beenden: Wert −1, den die Funktion ignoriert). SHA-1 danach `38b82614df3db8bb02e5e668a3fa9ed6480b17ac`. Rückgängig: `ADI4.EXE.vorP10`.
- **Test [F]:** Ausgangszustand gespeichert 0. Nach Start 1 und Fensterschließen: 0,999. Start 2 bleibt bei 0,999. Start 3: Regler 1,00, Pegel am Marantz-Ausgang bis 1,000. ExitCode jeweils 0. Der Nutzer bestätigt: „Ton funktioniert normal über die exe“.

### ADDY läuft ohne Fenster weiter
- **Beobachtung [F]:** Prozess ohne Fenster, volle Last auf einem Kern, Schleife bei `0x42F778`–`0x42F7BA`. Sie wartet mit `PeekMessage` und `GetExitCodeProcess` (0x103) auf einen gestarteten Kindprozess.
- **Bezug [F/V]:** Um 08:29:23 meldete Windows einen Hänger von `otvdmw.exe`, vermutlich ein Minispiel-Start. Danach blieb ADDY in der Warteschleife. Der Zusammenhang ist nicht bewiesen. Solange der Prozess lebt, scheitert vermutlich auch ein neuer Start.
- Schließen des Hauptfensters ohne Minispiel beendet ADDY sauber (ExitCode 0, dreimal geprüft). Wegen des Minispiel-Bezugs vorerst nicht weiter verfolgt.

### Portable-Variante (P5, Plan)
- `INTRO.INF` kennt `_vcdrom_=`: eine Ordnerliste, die vor den CD-Laufwerken durchsucht wird. Getrennt werden Leerzeichen, `;` und Tabulatoren.
- Plan: die CDs in getrennte Ordner ohne Leerzeichen entpacken (`C:\COKTEL\ADDY4\CD1`, `\CD2`, `\CD3`) und `_vcdrom_` setzen. Dann mit ausgehängten Abbildern testen.

### Vorschlag P1 (umgesetzt, s. o.): Patch der installierten Kopie
- Datei: nur `C:\COKTEL\ADDY4\ADI4.EXE` (die Kopie). Das Original auf CD und ISO bleibt unverändert. Vorher wird eine Sicherung `ADI4.EXE.orig` angelegt.
- Änderung: 36 Bytes ab Dateioffset `0x42DC2` (RVA `0x437C2`). Die Rechnung „Blöcke × 16000 / ms“ wird durch den festen Wert `mov ebx, 1200` (1200 KB/s, entspricht 8-fach-CD, also Modus „schnell“) und `NOP`s ersetzt. Die Messung selbst und die CD-Erkennung bleiben unverändert.
- Sicherheit: Das Skript prüft vor dem Patch die erwarteten Originalbytes und bricht bei Abweichung ab. Ein neuer Starttest folgt nach demselben Protokoll.
- Unbekannt **[V]:** Ob danach weitere Probleme auftreten (16-Bit-Farbtiefe, Schreibzugriff auf `C:\WMDO.CFG`, CD-Erkennung bei mehreren eingebundenen ADDY-CDs). Das zeigt erst der nächste Test.

---

## Anhang: Methode
Alle Analysewerkzeuge (Python, nur lesend) liegen im Scratchpad der Sitzung, nicht im Projekt:
- `isols.py`: ISO-9660-Lister für ISO und MODE1/2352-BIN
- `cmp.py`: SHA-1-Abgleich der Abbilder mit dem Ordner
- `peinfo.py`: MZ/NE/PE-Header und Importe
- `strs.py`: Zeichenketten
- `stk.py`: Inhaltsverzeichnis der Coktel-STK/ITK-Archive

Nur zur Analyse wurden WinG-Dateien mit `expand.exe` und die CD3-Version von `ANIREW.ITK` in den Scratchpad entpackt. `ANIREW.ITK` ist wieder gelöscht. Es wurde kein Programm aus den CDs gestartet.
