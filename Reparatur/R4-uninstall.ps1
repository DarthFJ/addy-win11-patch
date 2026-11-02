# Macht R4 (und R2) rueckgaengig. Sichert vorher SAVEGAME, INFO und *.INF/*.CFG nach Documents\Addy\Sicherung_<Datum>.
param([string]$Dest = 'C:\COKTEL\ADDY4')
$ErrorActionPreference = 'Stop'
$bak = Join-Path ([Environment]::GetFolderPath('MyDocuments')) ('Addy\Sicherung_{0:yyyyMMdd_HHmmss}' -f (Get-Date))
if (Test-Path $Dest) {
    New-Item -ItemType Directory -Path $bak | Out-Null
    Copy-Item (Join-Path $Dest '*') $bak -Recurse -Include 'SAVEGAME', 'INFO', '*.INF', '*.CFG', '*.LOG'
    foreach ($c in 'C:\WMDO.CFG', 'C:\MDO.CFG') { if (Test-Path $c) { Copy-Item $c $bak } }
    Remove-Item $Dest -Recurse -Force
    "Entfernt: $Dest (Sicherung: $bak)"
}
$fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
(Get-ItemProperty $key).PSObject.Properties | Where-Object { $_.Value -like "$fontDir\ADI*1.TTF" } | ForEach-Object { Remove-ItemProperty $key -Name $_.Name; "Schrift-Eintrag entfernt: $($_.Name)" }
foreach ($t in 'ADI_1.TTF', 'ADI1.TTF') { $p = Join-Path $fontDir $t; if (Test-Path $p) { Remove-Item $p -Force -ErrorAction SilentlyContinue } }
$sm = Join-Path ([Environment]::GetFolderPath('Programs')) 'COKTEL'
if (Test-Path $sm) { Remove-Item $sm -Recurse -Force; "Entfernt: $sm" }
