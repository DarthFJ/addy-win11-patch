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
# ADDY deinstallieren: sichert den Spielstand, loescht den Programmordner und entfernt alle Eintraege des Patches.
#   Deinstallieren.cmd [-Dest C:\COKTEL\ADDY4] [-BackupRoot Ordner] [-NoBackup] [-KeepOtvdmMapping]
param(
    [string]$Dest = 'C:\COKTEL\ADDY4',
    [string]$BackupRoot = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Addy'),
    [switch]$NoBackup,
    [switch]$KeepOtvdmMapping,
    [switch]$Interactive
)
$ErrorActionPreference = 'Stop'
$script:bad = $false
try {
    $exe = Join-Path $Dest 'ADI4.EXE'
    if ($Interactive) {
        Write-Host "ADDY wird aus $Dest entfernt. Der Spielstand wird vorher unter $BackupRoot gesichert."
        if ((Read-Host 'Fortfahren? (j/n)') -ne 'j') { Write-Host 'Abgebrochen.'; Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue; return }
    }
    Get-Process ADI4, ADILOOK, ADISCAPE, OLDAPPLI -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 1000

    if (Test-Path -LiteralPath $Dest) {
        if (-not (Test-Path -LiteralPath $exe)) { throw "$Dest enthaelt keine ADDY-Installation. Abbruch, es wird nichts geloescht." }
        if (-not $NoBackup) {
            $bak = Join-Path $BackupRoot ('Sicherung_Profil_{0:yyyyMMdd_HHmmss}' -f (Get-Date))
            New-Item -ItemType Directory -Path $bak -Force | Out-Null
            foreach ($f in 'ADI.INF', 'ADI4.INI', 'ado4.inf', 'PERSO.DEP', 'PAROLE.DEP', 'PREMIER.DEP') {
                if (Test-Path -LiteralPath "$Dest\$f") { Copy-Item -LiteralPath "$Dest\$f" -Destination $bak }
            }
            foreach ($d in 'DATA', 'SAVEGAME', 'INFO') {
                if (Test-Path -LiteralPath "$Dest\$d") { Copy-Item -LiteralPath "$Dest\$d" -Destination "$bak\$d" -Recurse }
            }
            Write-Host "Spielstand gesichert: $bak"
        }
        # Uninstall.exe beendet sich gerade erst, daher notfalls kurz warten.
        for ($i = 0; ; $i++) {
            try { Remove-Item -LiteralPath $Dest -Recurse -Force; break }
            catch { if ($i -ge 10) { throw }; Start-Sleep -Milliseconds 500 }
        }
        Write-Host "Programmordner geloescht: $Dest"
    } else { Write-Host "Programmordner nicht vorhanden: $Dest" }

    $layers = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
    Remove-ItemProperty -Path $layers -Name $exe -ErrorAction SilentlyContinue

    $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    $fontKey = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    (Get-ItemProperty $fontKey).PSObject.Properties | Where-Object { $_.Value -in "$fontDir\ADI1.TTF", "$fontDir\ADI_1.TTF" } | ForEach-Object { Remove-ItemProperty $fontKey -Name $_.Name }
    foreach ($t in 'ADI1.TTF', 'ADI_1.TTF') { Remove-Item -LiteralPath "$fontDir\$t" -Force -ErrorAction SilentlyContinue }

    $sm = Join-Path ([Environment]::GetFolderPath('Programs')) 'COKTEL'
    if (Test-Path -LiteralPath $sm) { Remove-Item -LiteralPath $sm -Recurse -Force }
    Remove-Item -LiteralPath (Join-Path ([Environment]::GetFolderPath('Desktop')) 'ADDY 4.lnk') -Force -ErrorAction SilentlyContinue

    Add-Type -Namespace AddyUn -Name Atom -MemberDefinition '[DllImport("kernel32.dll", CharSet=CharSet.Ansi)] public static extern ushort GlobalFindAtomA(string s); [DllImport("kernel32.dll")] public static extern ushort GlobalDeleteAtom(ushort a);'
    $n = 0
    while (($a = [AddyUn.Atom]::GlobalFindAtomA('MDOLoaderLaunched')) -and $n -lt 1000) { [void][AddyUn.Atom]::GlobalDeleteAtom($a); $n++ }

    $reg = "Windows Registry Editor Version 5.00`r`n`r`n[HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\Drivers32]`r`n`"vidc.iv32`"=-`r`n"
    if (-not $KeepOtvdmMapping) {
        $reg += "`r`n[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NtVdm64\0OTVDM]`r`n`r`n[-HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\NtVdm64\0OTVDM]`r`n"
    }
    $regFile = Join-Path $env:TEMP ('ADDY_Patch_Uninstall_{0}.reg' -f [Guid]::NewGuid().ToString('N'))
    [IO.File]::WriteAllText($regFile, $reg, [Text.Encoding]::Unicode)
    Write-Host 'Systemeintraege: bitte die Windows-Sicherheitsabfrage bestaetigen'
    try {
        $p = Start-Process reg.exe -ArgumentList "import `"$regFile`"" -Verb RunAs -Wait -PassThru -WindowStyle Hidden
        if ($p.ExitCode -ne 0) { throw "reg.exe meldete $($p.ExitCode)" }
        Write-Host 'Systemeintraege entfernt'
    } catch { Write-Host "WARNUNG: Systemeintraege nicht entfernt: $($_.Exception.Message)"; $script:bad = $true }
    finally { Remove-Item -LiteralPath $regFile -Force -ErrorAction SilentlyContinue }
    Write-Host 'Deinstallation abgeschlossen.'
} catch {
    Write-Host "FEHLER: $($_.Exception.Message)"
    $script:bad = $true
}
if ($Interactive) { [void](Read-Host 'Enter zum Schliessen') }
Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
if ($script:bad) { exit 1 }
