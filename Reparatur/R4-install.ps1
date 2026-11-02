# R4: Manuelle Installation von ADDY 4 nach SETUP.INF (ohne Autostart, Proxy, WebViewer, Neustart).
# Aufruf: powershell -ExecutionPolicy Bypass -File R4-install.ps1 -Source F:\ [-Dest C:\COKTEL\ADDY4]
param(
    [Parameter(Mandatory)] [string]$Source,
    [string]$Dest = 'C:\COKTEL\ADDY4',
    [string]$Log
)
$ErrorActionPreference = 'Stop'
if (-not $Log) { $Log = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'R4-install.log' }
function W($m) { $l = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $m; $l; Add-Content -Path $Log -Value $l -Encoding UTF8 }

$inf = Join-Path $Source 'SETUP.INF'
if (-not (Test-Path (Join-Path $Source 'AE63D401.CD1'))) { throw "$Source ist nicht CD1 (AE63D401.CD1 fehlt)" }
if (Test-Path $Dest) { throw "Ziel $Dest existiert bereits - Abbruch, es wird nichts ueberschrieben." }

W "=== R4 Start: Quelle $Source  Ziel $Dest"
$lines = Get-Content $inf -Encoding Default | Where-Object { $_ -notmatch '^\s*;' }

# 1. Verzeichnisse (MKDIR <rel> *DESTDIR bzw. MKDIR *DESTDIR)
New-Item -ItemType Directory -Path $Dest | Out-Null; W "MKDIR $Dest"
foreach ($l in $lines) {
    if ($l -match '^MKDIR\s+(\S+)\s+\*DESTDIR') {
        $d = Join-Path $Dest $Matches[1]
        New-Item -ItemType Directory -Path $d -Force | Out-Null; W "MKDIR $d"
    }
}

# 2. Dateien (COPY <rel> *DESTDIR), relative Pfade bleiben erhalten (PA\...)
$n = 0
foreach ($l in $lines) {
    if ($l -match '^COPY\s+(\S+)\s+\*DESTDIR') {
        $rel = $Matches[1]
        $src = Join-Path $Source $rel
        $dst = Join-Path $Dest $rel
        if (Test-Path $dst) { continue }   # Doppelte COPY-Zeilen in SETUP.INF
        Copy-Item -LiteralPath $src -Destination $dst
        $f = Get-Item -LiteralPath $dst; $f.IsReadOnly = $false
        $h1 = (Get-FileHash -LiteralPath $src -Algorithm SHA1).Hash
        $h2 = (Get-FileHash -LiteralPath $dst -Algorithm SHA1).Hash
        if ($h1 -ne $h2) { throw "Hash-Fehler bei $rel" }
        W "COPY $rel ($($f.Length) B, SHA1 $h2)"; $n++
    }
}
W "$n Dateien kopiert und verifiziert"

# 3. Schriften pro Benutzer (kein Admin noetig)
Add-Type -AssemblyName System.Drawing
$fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
foreach ($ttf in 'ADI_1.TTF', 'ADI1.TTF') {
    $src = Join-Path $Source $ttf
    $dst = Join-Path $fontDir $ttf
    if (-not (Test-Path $dst)) { Copy-Item $src $dst; (Get-Item $dst).IsReadOnly = $false }
    $pfc = New-Object System.Drawing.Text.PrivateFontCollection
    $pfc.AddFontFile($dst)
    $name = $pfc.Families[0].Name + ' (TrueType)'
    New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' -Name $name -Value $dst -PropertyType String -Force | Out-Null
    W "FONT $ttf -> $dst als '$name' (HKCU)"
}

# 4. Startmenue-Verknuepfung (nur Benutzer)
$sm = Join-Path ([Environment]::GetFolderPath('Programs')) 'COKTEL'
New-Item -ItemType Directory -Path $sm -Force | Out-Null
$ws = New-Object -ComObject WScript.Shell
$lnk = $ws.CreateShortcut((Join-Path $sm 'ADDY 4.lnk'))
$lnk.TargetPath = Join-Path $Dest 'ADI4.EXE'
$lnk.WorkingDirectory = $Dest
$lnk.Save()
W "LINK $sm\ADDY 4.lnk"
W "Bewusst NICHT ausgefuehrt: WinG/Indeo-Installer, INSTALL WEBVIEWER, SETPROXY.EXE, ADDSTARTUP ADILOOK, ALLDONE REBOOT"
W "=== R4 Ende"
