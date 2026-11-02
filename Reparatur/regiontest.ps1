# Startet ADI4.EXE mit einem Kompatibilitaets-Layer (nur fuer diesen Prozess, ueber __COMPAT_LAYER),
# misst von $From bis $To Sekunden alle 250 ms die Pixelaenderung im Bereich x,y,w,h (640x480-Koordinaten).
param([string]$Layer = '640X480', [int]$X = 0, [int]$Y = 181, [int]$W = 183, [int]$H = 159,
      [double]$From = 8.5, [double]$To = 17.5, [string]$Shot, [string]$Arg = '')
Add-Type -AssemblyName System.Drawing, System.Windows.Forms
$env:__COMPAT_LAYER = $Layer
$sp = @{ FilePath = 'C:\COKTEL\ADDY4\ADI4.EXE'; WorkingDirectory = 'C:\COKTEL\ADDY4'; PassThru = $true }
if ($Arg) { $sp.ArgumentList = $Arg }
$p = Start-Process @sp
Remove-Item Env:\__COMPAT_LAYER
$sw = [Diagnostics.Stopwatch]::StartNew()
while ($sw.Elapsed.TotalSeconds -lt $From) { Start-Sleep -Milliseconds 100 }
$prev = $null; $changes = 0; $n = 0; $total = 0.0
while ($sw.Elapsed.TotalSeconds -lt $To) {
    $vs = [Windows.Forms.SystemInformation]::VirtualScreen
    $sx = $vs.Width / 640.0; $sy = $vs.Height / 480.0
    $rect = New-Object Drawing.Rectangle ([int]($X * $sx)), ([int]($Y * $sy)), ([int]($W * $sx)), ([int]($H * $sy))
    $bmp = New-Object Drawing.Bitmap $rect.Width, $rect.Height
    [Drawing.Graphics]::FromImage($bmp).CopyFromScreen($rect.Location, [Drawing.Point]::Empty, $rect.Size)
    $sm = New-Object Drawing.Bitmap $bmp, 60, 52
    if ($prev) {
        $d = 0; for ($i = 0; $i -lt 60; $i++) { for ($j = 0; $j -lt 52; $j++) { if ($sm.GetPixel($i, $j).ToArgb() -ne $prev.GetPixel($i, $j).ToArgb()) { $d++ } } }
        $pct = 100.0 * $d / 3120; $total += $pct; $n++; if ($pct -gt 1) { $changes++ }
    }
    if ($Shot -and -not $prev) { $bmp.Save($Shot) }
    $prev = $sm
    Start-Sleep -Milliseconds 250
}
$vc = Get-CimInstance Win32_VideoController | Select-Object -First 1
"Arg '{7}' Layer '{0}': Messungen={1}, davon mit Bewegung (>1 %)={2}, mittlere Aenderung={3:N1} %, Modus waehrend Test={4}x{5}x{6}" -f $Layer, $n, $changes, ($total / [math]::Max($n, 1)), $vc.CurrentHorizontalResolution, $vc.CurrentVerticalResolution, $vc.CurrentBitsPerPixel, $Arg
Get-Process ADI4, ADILOOK -ErrorAction SilentlyContinue | Stop-Process -Force
