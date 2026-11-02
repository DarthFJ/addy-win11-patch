@echo off
setlocal
set "ADDY_PATCH_DIR=%~dp0"
set "ADDY_SELF=%~f0"
set "ADDY_PS1=%TEMP%\ADDY_%RANDOM%%RANDOM%.ps1"
cd /d "%TEMP%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText($env:ADDY_SELF,[Text.Encoding]::ASCII); [IO.File]::WriteAllText($env:ADDY_PS1,$t.Substring($t.IndexOf('#'+'#PS')),[Text.Encoding]::ASCII)"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ADDY_PS1%" %*
set "ADDY_RC=%ERRORLEVEL%"
del "%ADDY_PS1%" >nul 2>&1
pause
exit /b %ADDY_RC%
##PS
# ADDY Deutsch Klasse 5+6 (Coktel) - Installation unter Windows 11 mit allen Korrekturen.
# Quelle: eingelegte CD oder Image (.iso, .bin, .cue). Die Originalmedien werden nie veraendert.
#
#   Installieren.cmd [-Cd1Image Pfad] [-Cd2Image Pfad] [-Dest C:\COKTEL\ADDY4]
#                    [-OtvdmPath Ordner] [-RestoreProfile Sicherungsordner] [-NoPrompt]
param(
    [string]$Cd1Image,
    [string]$Cd2Image,
    [string]$Dest = 'C:\COKTEL\ADDY4',
    [string]$OtvdmPath,
    [string]$RestoreProfile,
    [switch]$NoPrompt
)
$ErrorActionPreference = 'Stop'
$script:PatchDir = $env:ADDY_PATCH_DIR.TrimEnd('\')
$script:Log =New-Object Collections.Generic.List[string]
$script:Warn = New-Object Collections.Generic.List[string]
$script:Mounted = New-Object Collections.Generic.List[string]
$script:TempFiles = New-Object Collections.Generic.List[string]

function Say($m) { $l = '{0:HH:mm:ss} {1}' -f (Get-Date), $m; Write-Host $l; $script:Log.Add($l) }
function Warning2($m) { Say "WARNUNG: $m"; $script:Warn.Add($m) }
function Sha1($p) { (Get-FileHash -LiteralPath $p -Algorithm SHA1).Hash.ToLower() }

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.IO;

public static class AddyTools {
    // MODE1/2352-BIN nach ISO (2048 Byte Nutzdaten je Sektor), bricht bei fremden Sektoren ab.
    public static long BinToIso(string src, string dst) {
        using (var i = new FileStream(src, FileMode.Open, FileAccess.Read, FileShare.Read, 1 << 20))
        using (var o = new FileStream(dst, FileMode.CreateNew, FileAccess.Write, FileShare.None, 1 << 20)) {
            if (i.Length % 2352 != 0) throw new Exception("Groesse ist kein Vielfaches von 2352: " + src);
            var s = new byte[2352]; long n = 0;
            while (i.Read(s, 0, 2352) == 2352) {
                bool sync = s[0] == 0 && s[11] == 0;
                for (int k = 1; k < 11 && sync; k++) sync = s[k] == 0xFF;
                if (!sync || s[15] != 1) throw new Exception("Sektor " + n + " ist kein MODE1-Datensektor");
                o.Write(s, 16, 2048); n++;
            }
            return n;
        }
    }

    // Holt eine Datei aus den InstallShield-3-Archiven eines Selbstentpackers, ohne ihn auszufuehren.
    public static byte[] ExtractIs3(string exe, string name) {
        byte[] d = File.ReadAllBytes(exe);
        for (int b = 0; b + 51 < d.Length; b++) {
            if (d[b] != 0x13 || d[b + 1] != 0x5D || d[b + 2] != 0x65 || d[b + 3] != 0x8C) continue;
            int fc = BitConverter.ToUInt16(d, b + 12);
            int p = b + BitConverter.ToInt32(d, b + 41);
            int dc = BitConverter.ToUInt16(d, b + 49);
            for (int i = 0; i < dc; i++) p += BitConverter.ToUInt16(d, p + 2);
            for (int i = 0; i < fc; i++) {
                p += 3;
                int usz = BitConverter.ToInt32(d, p), csz = BitConverter.ToInt32(d, p + 4), off = BitConverter.ToInt32(d, p + 8);
                p += 26;
                int nl = d[p];
                string n = System.Text.Encoding.ASCII.GetString(d, p + 1, nl);
                p += 1 + nl + 13;
                if (string.Equals(n, name, StringComparison.OrdinalIgnoreCase)) {
                    byte[] r = Blast(d, b + off, csz);
                    if (r.Length != usz) throw new Exception("Groessenfehler bei " + n);
                    return r;
                }
            }
        }
        throw new Exception(name + " nicht in " + exe + " gefunden");
    }

    // PKWARE-DCL-Implode (Port von zlib contrib/blast.c)
    static readonly byte[] LitLen = { 11,124,8,7,28,7,188,13,76,4,10,8,12,10,12,10,8,23,8,9,7,6,7,8,7,6,55,8,23,24,12,11,7,9,11,12,6,7,22,5,7,24,6,11,9,6,7,22,7,11,38,7,9,8,25,11,8,11,9,12,8,12,5,38,5,38,5,11,7,5,6,21,6,10,53,8,7,24,10,27,44,253,253,253,252,252,252,13,12,45,12,45,12,61,12,45,44,173 };
    static readonly byte[] LenLen = { 2,35,36,53,38,23 };
    static readonly byte[] DistLen = { 2,20,53,230,247,151,248 };
    static readonly int[] Base = { 3,2,4,5,6,7,8,9,10,12,16,24,40,72,136,264 };
    static readonly int[] Extra = { 0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8 };

    class Huff { public int[] Count = new int[14]; public int[] Symbol; }
    static Huff Build(byte[] rep) {
        var len = new List<int>();
        foreach (byte b in rep) for (int k = 0; k <= (b >> 4); k++) len.Add(b & 15);
        var h = new Huff(); h.Symbol = new int[len.Count];
        foreach (int l in len) h.Count[l]++;
        var offs = new int[14];
        for (int i = 1; i < 13; i++) offs[i + 1] = offs[i] + h.Count[i];
        for (int s = 0; s < len.Count; s++) if (len[s] != 0) h.Symbol[offs[len[s]]++] = s;
        return h;
    }

    class Bits {
        public byte[] D; public int Pos, End, Buf, Cnt;
        public int Get(int n) {
            while (Cnt < n) {
                if (Pos >= End) throw new Exception("Eingabe zu kurz");
                Buf |= D[Pos++] << Cnt; Cnt += 8;
            }
            int v = Buf & ((1 << n) - 1); Buf >>= n; Cnt -= n; return v;
        }
        public int Decode(Huff h) {
            int code = 0, first = 0, index = 0;
            for (int l = 1; l < 14; l++) {
                code |= Get(1) ^ 1;
                int c = h.Count[l];
                if (code < first + c) return h.Symbol[index + code - first];
                index += c; first += c; first <<= 1; code <<= 1;
            }
            throw new Exception("Ungueltiger Code");
        }
    }

    public static byte[] Blast(byte[] d, int off, int len) {
        Huff lit = Build(LitLen), ln = Build(LenLen), di = Build(DistLen);
        var b = new Bits { D = d, Pos = off, End = off + len };
        var o = new List<byte>(len * 4);
        int hasLit = b.Get(8), dict = b.Get(8);
        if (hasLit > 1 || dict < 4 || dict > 6) throw new Exception("Kein DCL-Header");
        while (true) {
            if (b.Get(1) != 0) {
                int sym = b.Decode(ln);
                int l = Base[sym] + b.Get(Extra[sym]);
                if (l == 519) break;
                int sh = l == 2 ? 2 : dict;
                int dist = (b.Decode(di) << sh) + b.Get(sh) + 1;
                if (dist > o.Count) throw new Exception("Distanz zu gross");
                for (int k = 0; k < l; k++) o.Add(o[o.Count - dist]);
            } else {
                o.Add((byte)(hasLit != 0 ? b.Decode(lit) : b.Get(8)));
            }
        }
        return o.ToArray();
    }

    public static int ReplaceAll(string path, byte[] from, byte[] to) {
        byte[] d = File.ReadAllBytes(path); int n = 0;
        for (int i = 0; i + from.Length <= d.Length; i++) {
            int k = 0;
            while (k < from.Length && d[i + k] == from[k]) k++;
            if (k == from.Length) { Array.Copy(to, 0, d, i, to.Length); n++; i += from.Length - 1; }
        }
        if (n > 0) File.WriteAllBytes(path, d);
        return n;
    }
}
'@

function Hex([string]$s) { $s = $s -replace '\s', ''; $b = New-Object byte[] ($s.Length / 2); for ($i = 0; $i -lt $b.Length; $i++) { $b[$i] = [Convert]::ToByte($s.Substring(2 * $i, 2), 16) }; , $b }

function Find-Media([string]$marker) {
    foreach ($v in Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=5') {
        if ($v.DeviceID -and (Test-Path -LiteralPath "$($v.DeviceID)\$marker")) { return "$($v.DeviceID)\" }
    }
    return $null
}

function Mount-Image([string]$path, [string]$marker) {
    $path = (Resolve-Path -LiteralPath $path).Path
    $ext = [IO.Path]::GetExtension($path).ToLower()
    if ($ext -eq '.cue') {
        $line = Select-String -LiteralPath $path -Pattern 'FILE\s+"(.+)"' | Select-Object -First 1
        if (-not $line) { throw "CUE-Datei ohne FILE-Zeile: $path" }
        $path = Join-Path (Split-Path $path) $line.Matches[0].Groups[1].Value
        $ext = '.bin'
    }
    if ($ext -eq '.bin') {
        $iso = Join-Path $env:TEMP ('ADDY_{0}.iso' -f [Guid]::NewGuid().ToString('N'))
        Say "Wandle $(Split-Path $path -Leaf) in ein temporaeres ISO um"
        [void][AddyTools]::BinToIso($path, $iso)
        $script:TempFiles.Add($iso)
        $path = $iso
    } elseif ($ext -ne '.iso') { throw "Nicht unterstuetztes Image: $path" }
    $already = Get-DiskImage -ImagePath $path
    if (-not $already.Attached) { Mount-DiskImage -ImagePath $path | Out-Null; $script:Mounted.Add($path) }
    $letter = $null
    for ($i = 0; $i -lt 20 -and -not $letter; $i++) { $letter = (Get-DiskImage -ImagePath $path | Get-Volume).DriveLetter; if (-not $letter) { Start-Sleep -Milliseconds 300 } }
    if (-not $letter) { throw "Image bekam keinen Laufwerksbuchstaben: $path" }
    $root = "${letter}:\"
    if (-not (Test-Path -LiteralPath "$root$marker")) { throw "$path ist nicht die erwartete CD ($marker fehlt)" }
    Say "Image eingebunden: $(Split-Path $path -Leaf) auf $root"
    return $root
}

function Find-ImageBeside([string]$stem) {
    # Images duerfen im Ordner des Patches oder direkt darueber liegen.
    foreach ($dir in $script:PatchDir, (Split-Path -Parent $script:PatchDir)) {
        foreach ($ext in '.iso', '.cue') {
            $f = Join-Path $dir "$stem$ext"
            if (Test-Path -LiteralPath $f) { return $f }
        }
    }
    return $null
}

function Get-Source([string]$image, [string]$marker, [string]$label, [string]$stem) {
    if ($image) { return Mount-Image $image $marker }
    $r = Find-Media $marker
    if ($r) { Say "$label gefunden auf $r"; return $r }
    $near = Find-ImageBeside $stem
    if ($near) { return Mount-Image $near $marker }
    if ($NoPrompt) { return $null }
    while ($true) {
        $a = Read-Host "$label nicht gefunden. CD einlegen und Enter druecken, oder Pfad zu ISO/BIN/CUE eingeben (x = abbrechen)"
        if ($a -eq 'x') { return $null }
        $a = $a.Trim('"', ' ')
        if ($a) {
            if (Test-Path -LiteralPath $a) { return Mount-Image $a $marker }
            Write-Host "Datei nicht gefunden: $a"
        } else {
            $r = Find-Media $marker
            if ($r) { Say "$label gefunden auf $r"; return $r }
        }
    }
}

function Patch-Bytes([string]$path, [int]$offset, [byte[]]$old, [byte[]]$new, [string]$name) {
    $fs = [IO.File]::Open($path, 'Open', 'ReadWrite')
    try {
        $cur = New-Object byte[] $old.Length
        $fs.Position = $offset; [void]$fs.Read($cur, 0, $cur.Length)
        for ($i = 0; $i -lt $old.Length; $i++) { if ($cur[$i] -ne $old[$i]) { throw "$name`: unerwartete Bytes an Offset 0x$('{0:X}' -f $offset)" } }
        $fs.Position = $offset; $fs.Write($new, 0, $new.Length)
    } finally { $fs.Close() }
    Say "Korrektur $name angewendet"
}

try {
    if (Test-Path -LiteralPath $Dest) { throw "Zielordner $Dest existiert bereits. Bitte zuerst Deinstallieren.cmd ausfuehren; es wird nichts ueberschrieben." }

    $cd1 = Get-Source $Cd1Image 'AE63D401.CD1' 'CD1 (Addy_Coll1)' 'Addy_Coll1'
    if (-not $cd1) { throw 'CD1 ist fuer die Installation erforderlich.' }
    if ((Sha1 "${cd1}ADI4.EXE") -ne '74b9403f7912bdb19ebb38a02d78ab0cbda7fa14') { throw 'Unbekannte ADI4.EXE auf CD1. Der Patch passt nur zu dieser ADDY-Ausgabe.' }

    New-Item -ItemType Directory -Path $Dest -Force | Out-Null
    $lines = Get-Content -LiteralPath "${cd1}SETUP.INF" -Encoding Default | Where-Object { $_ -notmatch '^\s*;' }

    # 1. Ordner und Dateien genau nach SETUP.INF; Autostart, Proxy, WebViewer und Neustart entfallen.
    foreach ($l in $lines) { if ($l -match '^MKDIR\s+(\S+)\s+\*DESTDIR') { New-Item -ItemType Directory -Path (Join-Path $Dest $Matches[1]) -Force | Out-Null } }
    $n = 0
    foreach ($l in $lines) {
        if ($l -match '^COPY\s+(\S+)\s+\*DESTDIR') {
            $dst = Join-Path $Dest $Matches[1]; $src = Join-Path $cd1 $Matches[1]
            if (Test-Path -LiteralPath $dst) { continue }
            Copy-Item -LiteralPath $src -Destination $dst
            (Get-Item -LiteralPath $dst).IsReadOnly = $false
            if ((Sha1 $src) -ne (Sha1 $dst)) { throw "Kopierfehler bei $($Matches[1])" }
            $n++
        }
    }
    Say "$n Programmdateien von CD1 kopiert und geprueft"

    # 2. Kennungsdatei (ohne sie bleibt die Klassenwahl gesperrt)
    Copy-Item -LiteralPath "${cd1}AE63D401.CD1" -Destination $Dest
    (Get-Item -LiteralPath "$Dest\AE63D401.CD1").IsReadOnly = $false
    Say 'Kennungsdatei AE63D401.CD1 kopiert'

    # 3. WinG und Indeo aus den Installern der CD holen; die 16-Bit-Installer laufen unter Windows 11 nicht.
    $wing = "$Dest\WING32.DLL"
    & "$env:windir\System32\expand.exe" "${cd1}WING\WING32.DL_" $wing | Out-Null
    if (-not (Test-Path -LiteralPath $wing) -or (Sha1 $wing) -ne '195359216f589a94bcdadbe20c666d9f83d16703') { throw 'WING32.DLL konnte nicht korrekt entpackt werden.' }
    Say 'WING32.DLL entpackt und geprueft'
    $ir = "$Dest\IR32_32.DLL"
    [IO.File]::WriteAllBytes($ir, [AddyTools]::ExtractIs3("${cd1}VFW\IV32NT95.EXE", 'IR32_32.DLL'))
    if ((Sha1 $ir) -ne '53acb145ba6290517cb00e2234c926a0fff07b06') { throw 'IR32_32.DLL konnte nicht korrekt entpackt werden.' }
    Say 'IR32_32.DLL (Indeo 3.2) entpackt und geprueft'

    # 4. Korrekturen an ADI4.EXE (Original bleibt als ADI4.EXE.orig daneben)
    $exe = "$Dest\ADI4.EXE"
    Copy-Item -LiteralPath $exe -Destination "$exe.orig"
    $p1Old = Hex '8b45fc c1e00e c1e003 8d0480 8d0480 8d0480 99 f77df4 8bd8 b900040000 8bc3 99 f7f9 89c3'
    $p1New = (Hex 'bbb0040000') + [byte[]](,0x90 * 31)
    Patch-Bytes $exe 0x42DC2 $p1Old ([byte[]]$p1New) 'P1 (Division durch null bei der CD-Messung)'
    Patch-Bytes $exe 0x373E1 (Hex '75f5') (Hex '9090') 'P2 (Endlosschleife beim Start)'
    Patch-Bytes $exe 0x2ACE2 (Hex '7d') (Hex 'eb') 'P6 (eingefrorene Animationen)'
    Patch-Bytes $exe 0x6CA80 ([byte[]](,0 * 45)) (Hex '31C0 A3B00A4900 A3B80A4900 0FBF430A 48 A3B40A4900 0FBF430C 48 A3BC0A4900 6A00 8B15B80A4900 E90BE6FBFF') 'P7a (Bildreste, Code)'
    Patch-Bytes $exe 0x2B0B0 (Hex '6A008B15B80A4900') (Hex 'E9CB190400909090') 'P7b (Bildreste, Sprung)'
    Patch-Bytes $exe 0x36B16 (Hex 'E889EA0000 A3D8644800') (Hex '6A64 E8D3EA0000 59 9090') 'P10a (Lautstaerke beim Start)'
    Patch-Bytes $exe 0x3626B (Hex 'FF35D8644800') (Hex '6AFF90909090') 'P10b (Lautstaerke beim Beenden)'
    Patch-Bytes $exe 0x3763A (Hex 'FF35D8644800') (Hex '6AFF90909090') 'P10c (Lautstaerke beim Beenden)'
    if ((Sha1 $exe) -ne '38b82614df3db8bb02e5e668a3fa9ed6480b17ac') { throw 'ADI4.EXE hat nach den Korrekturen nicht die erwartete Pruefsumme.' }
    Say 'ADI4.EXE: Pruefsumme nach allen Korrekturen stimmt'

    # 5. Rocket Scrambler: korrigierte Kopie im Programmordner, die Spieleliste verweist darauf.
    $cd2 = Get-Source $Cd2Image 'AE63D401.CD2' 'CD2 (Addy4_coll2, fuer die Tempo-Korrektur von Rocket Scrambler)' 'Addy4_coll2'
    if ($cd2) {
        $game = "$Dest\GAMES\SCRAM"
        New-Item -ItemType Directory -Path "$Dest\GAMES" -Force | Out-Null
        Copy-Item -LiteralPath "${cd2}GAMES\SCRAM" -Destination $game -Recurse
        Get-ChildItem -LiteralPath $game -File | ForEach-Object { $_.IsReadOnly = $false }
        if ((Sha1 "$game\SCRAM.EXE") -ne 'f414af0e08aa745cd154232b7aeb60c8bec920f7') { throw 'Unbekannte SCRAM.EXE auf CD2.' }
        Patch-Bytes "$game\SCRAM.EXE" 0x3BC1 (Hex '7635') (Hex '9090') 'P9 (Tempo von Rocket Scrambler)'
        if ((Sha1 "$game\SCRAM.EXE") -ne '4d998c1e78b7830c152f0bc7e69888f855ede64e') { throw 'SCRAM.EXE hat nach P9 nicht die erwartete Pruefsumme.' }
        $enc = [Text.Encoding]::ASCII
        $c = [AddyTools]::ReplaceAll("$Dest\INTRO.STK", $enc.GetBytes('<CD>GAMES\SCRAM\SCRAM.EXE'), $enc.GetBytes('<ME>GAMES\SCRAM\SCRAM.EXE'))
        if ($c -lt 1) { throw 'Rocket Scrambler wurde in den Spielelisten von INTRO.STK nicht gefunden.' }
        Say "Spielelisten in INTRO.STK: $c Eintraege auf die korrigierte Kopie umgestellt"
    } else {
        Warning2 'CD2 fehlt: Rocket Scrambler laeuft von der CD ohne Tempo-Korrektur.'
    }

    # 6. Schriften, Verknuepfung und Bildschirmmodus nur fuer dieses Benutzerkonto
    Add-Type -AssemblyName System.Drawing
    $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
    foreach ($ttf in 'ADI_1.TTF', 'ADI1.TTF') {
        $f = Join-Path $fontDir $ttf
        if (-not (Test-Path -LiteralPath $f)) { Copy-Item -LiteralPath "$cd1$ttf" -Destination $f; (Get-Item -LiteralPath $f).IsReadOnly = $false }
        $pfc = New-Object Drawing.Text.PrivateFontCollection
        $pfc.AddFontFile($f)
        New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' -Name ($pfc.Families[0].Name + ' (TrueType)') -Value $f -PropertyType String -Force | Out-Null
        $pfc.Dispose()
    }
    Say 'Schriften installiert'
    $sm = Join-Path ([Environment]::GetFolderPath('Programs')) 'COKTEL'
    New-Item -ItemType Directory -Path $sm -Force | Out-Null
    foreach ($dir in $sm, [Environment]::GetFolderPath('Desktop')) {
        $lnk = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $dir 'ADDY 4.lnk'))
        $lnk.TargetPath = $exe; $lnk.WorkingDirectory = $Dest; $lnk.IconLocation = "$exe,0"; $lnk.Save()
    }
    Say 'Verknuepfungen auf dem Desktop und im Startmenue (COKTEL) angelegt'

    # Uninstall.exe: enthaelt das Skript aus Deinstallieren.cmd, startet es aus dem Temp-Ordner und beendet sich,
    # damit der Programmordner geloescht werden kann.
    $un = [IO.File]::ReadAllText((Join-Path $script:PatchDir 'Deinstallieren.cmd'), [Text.Encoding]::ASCII)
    $un = $un.Substring($un.IndexOf('#' + '#PS'))
    $b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($un))
    Add-Type -OutputAssembly "$Dest\Uninstall.exe" -OutputType WindowsApplication -TypeDefinition @"
using System; using System.Diagnostics; using System.IO; using System.Text;
static class AddyUninstall {
    static void Main(string[] args) {
        string dir = Path.GetDirectoryName(Process.GetCurrentProcess().MainModule.FileName);
        string tmp = Path.Combine(Path.GetTempPath(), "ADDY_Uninstall_" + Guid.NewGuid().ToString("N") + ".ps1");
        File.WriteAllBytes(tmp, Convert.FromBase64String("$b64"));
        string mode = args.Length > 0 && args[0] == "/silent" ? "-NoBackup" : "-Interactive";
        var p = new ProcessStartInfo("powershell.exe", "-NoProfile -ExecutionPolicy Bypass -File \"" + tmp + "\" -Dest \"" + dir + "\" " + mode);
        p.UseShellExecute = true; p.WorkingDirectory = Path.GetTempPath();
        Process.Start(p);
    }
}
"@
    Say 'Uninstall.exe im Programmordner angelegt'
    $layers = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
    if (-not (Test-Path $layers)) { New-Item -Path $layers -Force | Out-Null }
    New-ItemProperty -Path $layers -Name $exe -Value '~ 640X480' -PropertyType String -Force | Out-Null
    Say 'Kompatibilitaetsmodus 640x480 gesetzt'

    # 7. Systemweite Eintraege: Indeo-Codec und optional otvdm fuer die 16-Bit-Spiele (Windows-Abfrage noetig)
    if (-not $OtvdmPath) { $OtvdmPath = Get-ChildItem -Path (Split-Path $Dest) -Directory -Filter 'otvdm*' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName }
    $hasOtvdm = $OtvdmPath -and (Test-Path -LiteralPath (Join-Path $OtvdmPath 'otvdmw.exe'))
    $esc = { param($s) $s -replace '\\', '\\' }
    $regText = "Windows Registry Editor Version 5.00`r`n`r`n[HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\Drivers32]`r`n`"vidc.iv32`"=`"$(& $esc $ir)`"`r`n"
    if ($hasOtvdm) {
        $mapped = & $esc (Join-Path $OtvdmPath 'otvdmw.exe')
        foreach ($k in 'SOFTWARE\Microsoft', 'SOFTWARE\WOW6432Node\Microsoft') {
            $regText += "`r`n[HKEY_LOCAL_MACHINE\$k\Windows NT\CurrentVersion\NtVdm64\0OTVDM]`r`n`"CommandLine`"=`" --ntvdm64: \`"%m\`" --ntvdm64-args: %c`"`r`n`"InternalName`"=`"*`"`r`n`"ProductName`"=`"*`"`r`n`"ProductVersion`"=`"*`"`r`n`"MappedExeName`"=`"$mapped`"`r`n"
        }
    } else {
        Warning2 'otvdm nicht gefunden: 16-Bit-Spiele (u. a. Rocket Scrambler) starten nicht. Ordner mit -OtvdmPath angeben.'
    }
    $regFile = Join-Path $env:TEMP 'ADDY_Patch.reg'
    [IO.File]::WriteAllText($regFile, $regText, [Text.Encoding]::Unicode)
    $script:TempFiles.Add($regFile)
    Say 'Systemeintraege: bitte die Windows-Sicherheitsabfrage bestaetigen'
    try {
        $proc = Start-Process reg.exe -ArgumentList "import `"$regFile`"" -Verb RunAs -Wait -PassThru -WindowStyle Hidden
        if ($proc.ExitCode -ne 0) { throw "reg.exe meldete $($proc.ExitCode)" }
    } catch { Warning2 "Systemeintraege wurden nicht gesetzt ($($_.Exception.Message)). Videos und 16-Bit-Spiele funktionieren dann nicht." }
    $iv = (Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\Drivers32' -Name 'vidc.iv32' -ErrorAction SilentlyContinue).'vidc.iv32'
    if ($iv -eq $ir) { Say 'Indeo-Codec registriert' } else { Warning2 'Indeo-Codec ist nicht registriert.' }
    if ($hasOtvdm) {
        $m = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NtVdm64\0OTVDM' -ErrorAction SilentlyContinue).MappedExeName
        if ($m -eq (Join-Path $OtvdmPath 'otvdmw.exe')) { Say "otvdm-Umleitung gesetzt: $m" } else { Warning2 'otvdm-Umleitung ist nicht gesetzt.' }
    }

    # 8. Optional: gesicherten Spielstand zurueckholen
    if ($RestoreProfile) {
        foreach ($i in 'ADI.INF', 'ADI4.INI', 'ado4.inf', 'PERSO.DEP', 'PAROLE.DEP', 'PREMIER.DEP') {
            if (Test-Path -LiteralPath "$RestoreProfile\$i") { Copy-Item -LiteralPath "$RestoreProfile\$i" -Destination $Dest -Force }
        }
        foreach ($i in 'DATA', 'SAVEGAME', 'INFO') {
            if (Test-Path -LiteralPath "$RestoreProfile\$i") { Copy-Item -Path "$RestoreProfile\$i\*" -Destination "$Dest\$i" -Recurse -Force -ErrorAction Stop }
        }
        Say "Spielstand aus $RestoreProfile zurueckgeholt"
    }

    Say 'Installation abgeschlossen.'
    Say 'Zum Spielen CD1, CD2 und CD3 einlegen oder als Image einbinden.'
    $script:Ok = $true
} catch {
    Say "FEHLER: $($_.Exception.Message)"
    $script:Ok = $false
} finally {
    foreach ($m in $script:Mounted) { try { Dismount-DiskImage -ImagePath $m | Out-Null } catch {} }
    foreach ($t in $script:TempFiles) { Remove-Item -LiteralPath $t -Force -ErrorAction SilentlyContinue }
    if (Test-Path -LiteralPath $Dest) { $script:Log | Set-Content -LiteralPath "$Dest\ADDY-Patch.log" -Encoding UTF8 }
}
if ($script:Warn.Count) { Write-Host ''; Write-Host "$($script:Warn.Count) Warnung(en), siehe oben." }
if (-not $script:Ok) { exit 1 }
