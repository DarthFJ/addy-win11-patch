# Passiver Rekorder: jede Sekunde ein verkleinertes Bildschirmfoto + CPU-Zeit von ADI4.EXE, bis ADI4 endet (max. $Minutes).
# Greift nicht in ADDY ein. Ergebnis: OutDir\log.csv und OutDir\f_XXXX.png
param([Parameter(Mandatory)][string]$OutDir, [int]$Minutes = 20)
Add-Type -AssemblyName System.Drawing, System.Windows.Forms
New-Item -ItemType Directory -Force $OutDir | Out-Null
$log = Join-Path $OutDir 'log.csv'
'zeit;sek;cpu_s;geaendert_prozent;bild' | Set-Content $log -Encoding UTF8
Start-Sleep 2
$sw = [Diagnostics.Stopwatch]::StartNew(); $prev = $null; $i = 0
while ($sw.Elapsed.TotalMinutes -lt $Minutes) {
    $p = Get-Process ADI4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $p) { break }
    $b = [Windows.Forms.SystemInformation]::VirtualScreen
    $bmp = New-Object Drawing.Bitmap $b.Width, $b.Height
    $g = [Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($b.Location, [Drawing.Point]::Empty, $b.Size); $g.Dispose()
    $small = New-Object Drawing.Bitmap $bmp, 320, 240
    $bmp.Dispose()
    $diff = 0
    if ($prev) { for ($x = 0; $x -lt 320; $x += 2) { for ($y = 0; $y -lt 240; $y += 2) { if ($small.GetPixel($x, $y).ToArgb() -ne $prev.GetPixel($x, $y).ToArgb()) { $diff++ } } } }
    $name = 'f_{0:D4}.png' -f $i
    $small.Save((Join-Path $OutDir $name))
    if ($prev) { $prev.Dispose() }
    '{0:HH:mm:ss};{1:N1};{2:N1};{3:N1};{4}' -f (Get-Date), $sw.Elapsed.TotalSeconds, $p.TotalProcessorTime.TotalSeconds, (100 * $diff / 19200), $name | Add-Content $log -Encoding UTF8
    $prev = $small; $i++
    Start-Sleep -Milliseconds 1000
}
