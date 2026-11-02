# A/B-Test: startet ADI4.EXE unter dem Tracer (optional mit Speicherpatch) und macht zu festen Zeiten Vollbild-Fotos.
param([Parameter(Mandatory)][string]$OutPrefix, [string]$MemPatch = '', [double[]]$Times = @(6, 8, 10, 12, 14, 16, 18, 20), [int]$Seconds = 24)
Add-Type -AssemblyName System.Drawing, System.Windows.Forms
$tracer = Join-Path $PSScriptRoot 'apitrace.ps1'
$args2 = "-NoProfile -ExecutionPolicy Bypass -File `"$tracer`" -Seconds $Seconds -EmulateWin95Atom -Light"
if ($MemPatch) { $args2 += " -MemPatch $MemPatch" }
$tp = Start-Process "$env:windir\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $args2 -RedirectStandardOutput "$OutPrefix.log" -WindowStyle Hidden -PassThru
$sw = [Diagnostics.Stopwatch]::StartNew()
$i = 0
foreach ($t in $Times) {
    while ($sw.Elapsed.TotalSeconds -lt $t) { Start-Sleep -Milliseconds 50 }
    $bmp = New-Object Drawing.Bitmap 640, 480
    [Drawing.Graphics]::FromImage($bmp).CopyFromScreen([Drawing.Point]::Empty, [Drawing.Point]::Empty, (New-Object Drawing.Size 640, 480))
    $bmp.Save(('{0}_{1:D2}.png' -f $OutPrefix, $i)); $i++
}
$tp.WaitForExit()
Get-Process ADILOOK -ErrorAction SilentlyContinue | Stop-Process -Force
