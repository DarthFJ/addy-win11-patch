# Misst, ob sich das Bild von ADDY bewegt: startet ADI4.EXE (ohne Debugger), macht alle 0,5 s ein Bildschirmfoto
# und gibt den Anteil geaenderter Pixel gegenueber dem vorigen Bild aus. Beendet ADDY am Ende.
param([Parameter(Mandatory)][string]$OutDir, [int]$Seconds = 25, [int]$StartDelay = 3)
Add-Type -AssemblyName System.Drawing, System.Windows.Forms
New-Item -ItemType Directory -Force $OutDir | Out-Null
$p = Start-Process C:\COKTEL\ADDY4\ADI4.EXE -WorkingDirectory C:\COKTEL\ADDY4 -PassThru
Start-Sleep $StartDelay
$prev = $null; $i = 0
$sw = [Diagnostics.Stopwatch]::StartNew()
while ($sw.Elapsed.TotalSeconds -lt $Seconds -and -not $p.HasExited) {
    $b = [Windows.Forms.SystemInformation]::VirtualScreen
    $bmp = New-Object Drawing.Bitmap $b.Width, $b.Height
    [Drawing.Graphics]::FromImage($bmp).CopyFromScreen($b.Location, [Drawing.Point]::Empty, $b.Size)
    $small = New-Object Drawing.Bitmap $bmp, 160, 120
    if ($prev) {
        $diff = 0
        for ($x = 0; $x -lt 160; $x++) { for ($y = 0; $y -lt 120; $y++) { if ($small.GetPixel($x, $y).ToArgb() -ne $prev.GetPixel($x, $y).ToArgb()) { $diff++ } } }
        '{0,5:N1}s  geaendert: {1,5:N1} %' -f $sw.Elapsed.TotalSeconds, (100 * $diff / 19200)
    }
    if ($i % 4 -eq 0) { $bmp.Save((Join-Path $OutDir ('anim_{0:D3}.png' -f $i))) }
    $prev = $small; $i++
    Start-Sleep -Milliseconds 400
}
Get-Process ADI4, ADILOOK -ErrorAction SilentlyContinue | Stop-Process -Force
