# Starttest: ADI4.EXE starten, Fenster und Kindprozesse protokollieren, Bildschirmfoto, optional beenden.
param([Parameter(Mandatory)][string]$Shot, [int]$Wait = 20, [switch]$Keep, [string]$Dest = 'C:\COKTEL\ADDY4')
Add-Type -AssemblyName System.Drawing, System.Windows.Forms
Add-Type -Namespace U -Name W -MemberDefinition @'
public delegate bool EnumProc(IntPtr h, IntPtr l);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc f, IntPtr l);
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, System.Text.StringBuilder s, int n);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, System.Text.StringBuilder s, int n);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
'@
$p = Start-Process -FilePath (Join-Path $Dest 'ADI4.EXE') -WorkingDirectory $Dest -PassThru
"Gestartet: PID $($p.Id) um $(Get-Date -Format HH:mm:ss)"
Start-Sleep -Seconds $Wait
$p.Refresh()
"Laeuft noch: $(-not $p.HasExited)" + $(if ($p.HasExited) { " (ExitCode $($p.ExitCode))" } else { '' })
$pids = @($p.Id) + @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$($p.Id)" | ForEach-Object { "Kindprozess: $($_.Name) PID $($_.ProcessId)" | Out-Host; $_.ProcessId })
$cb = [U.W+EnumProc] {
    param($h, $l)
    $wp = 0; [void][U.W]::GetWindowThreadProcessId($h, [ref]$wp)
    if ($pids -contains $wp -and [U.W]::IsWindowVisible($h)) {
        $t = New-Object Text.StringBuilder 256; $c = New-Object Text.StringBuilder 256
        [void][U.W]::GetWindowText($h, $t, 256); [void][U.W]::GetClassName($h, $c, 256)
        "Fenster: PID $wp Klasse='$c' Titel='$t'" | Out-Host
    }
    $true
}
[void][U.W]::EnumWindows($cb, [IntPtr]::Zero)
$b = [Windows.Forms.SystemInformation]::VirtualScreen
$bmp = New-Object Drawing.Bitmap $b.Width, $b.Height
[Drawing.Graphics]::FromImage($bmp).CopyFromScreen($b.Location, [Drawing.Point]::Empty, $b.Size)
$bmp.Save($Shot, [Drawing.Imaging.ImageFormat]::Png); "Screenshot: $Shot"
if (-not $Keep) {
    foreach ($id in $pids) { Stop-Process -Id $id -Force -ErrorAction SilentlyContinue }
    "Beendet."
}
